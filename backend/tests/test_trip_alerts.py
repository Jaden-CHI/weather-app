import copy
import asyncio
import json
import os
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path
from unittest.mock import AsyncMock, patch
from uuid import uuid4

import httpx
from fastapi import FastAPI, Header
from pydantic import ValidationError
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker

from api.routers.trip_plans import router, Plan, Snapshot
from models.database import get_db
from services.fishing_push import require_fishing_user, deliver
from services.trip_conditions import assess, should_notify
from workers.trip_alert_worker import evaluate_device, dispatch

NOW = datetime.now(timezone.utc).replace(minute=0, second=0, microsecond=0)


def plan(**changes):
    return {'id': 'trip_1', 'portId': 'FS_001', 'startsAt': (NOW+timedelta(hours=2)).isoformat(),
            'endsAt': (NOW+timedelta(hours=4)).isoformat(), 'maxWind': 6., 'maxWave': 1., **changes}


def forecast(wind=0, wave=0):
    return {'status': 'available', 'issued_at': NOW.isoformat(), 'fetched_at': NOW.isoformat(),
            'hourly': [{'time': (NOW+timedelta(hours=h)).isoformat(), 'wind_speed': wind, 'wave_height': wave} for h in range(6)]}


class ConditionsTests(unittest.TestCase):
    def test_zero_missing_breach_and_gaps(self):
        self.assertEqual(assess(plan(), forecast(), NOW), 'within')
        self.assertEqual(assess(plan(), forecast(wave=None), NOW), 'unavailable')
        self.assertEqual(assess(plan(), forecast(wind=7, wave=None), NOW), 'exceeded')
        data = forecast(); data['hourly'].pop(2)
        self.assertEqual(assess(plan(), data, NOW), 'unavailable')

    def test_invalid_numbers_and_boundaries(self):
        for v in (float('nan'), float('inf'), -1, True, '0'):
            self.assertEqual(assess(plan(), forecast(wave=v), NOW), 'unavailable')
        self.assertEqual(assess(plan(), forecast(6, 1), NOW), 'within')
        self.assertEqual(assess(plan(maxWave=None), forecast(wave=None), NOW), 'within')

    def test_age_and_state(self):
        for change in ({'status': 'stale'}, {'fetched_at': (NOW-timedelta(hours=4)).isoformat()},
                       {'issued_at': (NOW-timedelta(hours=13)).isoformat()},
                       {'fetched_at': (NOW+timedelta(minutes=6)).isoformat()}):
            self.assertEqual(assess(plan(), {**forecast(), **change}, NOW), 'unavailable')
        self.assertEqual(assess(plan(), None, NOW+timedelta(days=1)), 'finished')
        self.assertEqual(assess(plan(), None, NOW-timedelta(days=3)), 'waiting')
        self.assertFalse(should_notify(None, 'unavailable'))
        self.assertFalse(should_notify('exceeded', 'exceeded'))
        self.assertTrue(should_notify('within', 'unavailable'))
        self.assertTrue(should_notify('exceeded', 'within'))

    def test_input_validation(self):
        for change in ({'portId': 'unknown'}, {'maxWind': None, 'maxWave': None},
                       {'maxWind': float('nan')}, {'maxWave': -1}, {'id': '../bad'},
                       {'startsAt': '2026-11-27T01:00:00'}, {'endsAt': plan()['startsAt']}):
            with self.assertRaises(ValidationError): Plan(**plan(**change))
        with self.assertRaises(ValidationError):
            Snapshot(revision=1, token='x'*30, platform='ios', plans=[plan(), plan()])


class AuthTests(unittest.IsolatedAsyncioTestCase):
    async def test_auth_rejects_missing_invalid_revoked_and_no_config(self):
        from fastapi import HTTPException
        with self.assertRaises(HTTPException) as e: await require_fishing_user('')
        self.assertEqual(e.exception.status_code, 401)
        with patch('services.fishing_push.fishing_app', side_effect=RuntimeError()):
            with self.assertRaises(HTTPException) as e: await require_fishing_user('Bearer something')
            self.assertEqual(e.exception.status_code, 503)
        with patch('services.fishing_push.fishing_app', return_value=object()), patch('services.fishing_push.auth.verify_id_token', side_effect=ValueError()):
            with self.assertRaises(HTTPException) as e: await require_fishing_user('Bearer revoked-or-other-project')
            self.assertEqual(e.exception.status_code, 401)

    async def test_token_validation_checks_revocation(self):
        with patch('services.fishing_push.fishing_app', return_value='fishing') as app, patch('services.fishing_push.auth.verify_id_token', return_value={'uid': 'user-a'}) as verify:
            self.assertEqual(await require_fishing_user('Bearer valid'), 'user-a')
            verify.assert_called_once_with('valid', app='fishing', check_revoked=True)

    async def test_fcm_contains_background_notification_and_route(self):
        from services.fishing_push import messaging
        event = {'title': '기준 초과', 'body': '확인', 'event_id': 'e', 'plan_id': 'p',
                 'state': 'exceeded', 'collapse_id': 'c', 'expires_epoch': 12345}
        with patch('services.fishing_push.fishing_app', return_value='fishing'), patch('services.fishing_push.messaging.send', return_value='id') as send:
            self.assertEqual(await deliver('token', event, 600), 'sent')
            message = send.call_args.args[0]
            self.assertEqual(message.data['screen'], 'trip_plans')
            self.assertIsNotNone(message.notification)
            self.assertEqual(message.apns.headers['apns-push-type'], 'alert')
            self.assertEqual(message.android.notification.channel_id, 'trip_conditions_v1')
        with patch('services.fishing_push.fishing_app', return_value='fishing'), patch('services.fishing_push.messaging.send', side_effect=messaging.UnregisteredError('gone')):
            self.assertEqual(await deliver('token', event, 600), 'invalid_token')


@unittest.skipUnless(os.getenv('TEST_TRIP_DATABASE_URL'), 'dedicated test PostgreSQL required')
class DatabaseTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        url = os.environ['TEST_TRIP_DATABASE_URL']
        assert url.rsplit('/', 1)[-1] == 'fishing_trip_test', 'Never use a production database'
        self.engine = create_async_engine(url)
        self.sessions = async_sessionmaker(self.engine, expire_on_commit=False)
        async with self.engine.begin() as connection:
            schema = (Path(__file__).parents[1]/'schema.sql').read_text()
            for statement in schema.split(';'):
                if statement.strip(): await connection.execute(text(statement))
            await connection.execute(text('DELETE FROM fishing_push_devices'))
        app = FastAPI(); app.include_router(router)
        async def db():
            async with self.sessions() as session: yield session
        async def uid(x_test_user: str = Header(default='a')): return x_test_user
        app.dependency_overrides[get_db] = db
        app.dependency_overrides[require_fishing_user] = uid
        self.client = httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url='http://test')
        self.enabled = patch('api.routers.trip_plans.enabled', return_value=True); self.enabled.start()
        self.install = str(uuid4())
        self.url = f'/api/v1/fishing/trip-alerts/installations/{self.install}'
        self.payload = {'revision': 1, 'platform': 'ios', 'token': 'test-token-'+'x'*50, 'plans': [plan()]}

    async def asyncTearDown(self):
        self.enabled.stop()
        await self.client.aclose(); await self.engine.dispose()

    async def sync(self, payload=None, user='a'):
        return await self.client.put(self.url, json=payload or self.payload, headers={'x-test-user': user})

    async def evaluate(self, data=None):
        async with self.sessions() as session:
            await evaluate_device(session, {'uid': 'a', 'installation_id': self.install}, {'FS_001': data or forecast()}, NOW)
            await session.commit()

    async def events(self):
        async with self.sessions() as session:
            return [dict(r) for r in (await session.execute(text('SELECT * FROM fishing_trip_events ORDER BY created_at'))).mappings().all()]

    async def test_isolation_idempotency_revision_delete(self):
        self.assertEqual((await self.sync()).status_code, 200)
        self.assertEqual((await self.sync()).status_code, 200)
        other = await self.client.get(self.url, headers={'x-test-user': 'b'})
        self.assertIsNone(other.json()['device'])
        await self.client.delete(self.url, headers={'x-test-user': 'b'})
        self.assertIsNotNone((await self.client.get(self.url)).json()['device'])
        self.assertEqual((await self.sync({**self.payload, 'revision': 2})).status_code, 200)
        self.assertEqual((await self.sync()).status_code, 409)
        self.assertEqual((await self.sync({**self.payload, 'revision': 2, 'plans': []})).status_code, 409)
        await self.evaluate()
        self.assertEqual(len(await self.events()), 1)
        await self.client.delete(self.url)
        self.assertEqual(await self.events(), [])

    async def test_dedupe_retry_and_success(self):
        await self.sync(); await self.evaluate(); await self.evaluate()
        events = await self.events(); self.assertEqual(len(events), 1)
        with patch('workers.trip_alert_worker.deliver', new=AsyncMock(return_value='retry')):
            async with self.sessions() as session:
                await dispatch(session, events[0], NOW+timedelta(minutes=30)); await session.commit()
        event = (await self.events())[0]
        self.assertEqual(event['delivery'], 'pending'); self.assertEqual(event['attempts'], 1)
        # Time travel the retry schedule in the isolated fixture only.
        async with self.sessions() as session:
            await session.execute(text("UPDATE fishing_trip_events SET next_attempt=NOW()-INTERVAL '1 second'")); await session.commit()
        with patch('workers.trip_alert_worker.deliver', new=AsyncMock(return_value='sent')) as send:
            async with self.sessions() as session:
                await dispatch(session, event, NOW+timedelta(minutes=31)); await session.commit()
                self.assertEqual(send.await_count, 1)
        await self.evaluate()
        self.assertEqual(len(await self.events()), 1)
        self.assertEqual((await self.events())[0]['delivery'], 'sent')

    async def test_edit_removes_pending_and_disable_stops(self):
        await self.sync(); await self.evaluate()
        edited = {**self.payload, 'revision': 2, 'plans': [plan(maxWind=1)]}
        self.assertEqual((await self.sync(edited)).status_code, 200)
        self.assertEqual(await self.events(), [])
        await self.evaluate(forecast(7, .5))
        event = (await self.events())[0]
        await self.client.delete(self.url)
        with patch('workers.trip_alert_worker.deliver', new=AsyncMock()) as send:
            async with self.sessions() as session:
                await dispatch(session, event, NOW); await session.commit()
                send.assert_not_awaited()

    async def test_superseded_invalid_token_and_account_purge(self):
        await self.sync(); await self.evaluate(forecast(7, .5)); await self.evaluate(forecast())
        events = await self.events()
        self.assertEqual(len(events), 2)
        self.assertEqual(events[0]['delivery'], 'superseded')
        with patch('workers.trip_alert_worker.deliver', new=AsyncMock(return_value='invalid_token')):
            async with self.sessions() as session:
                await dispatch(session, events[1], NOW); await session.commit()
        status = (await self.client.get(self.url)).json()
        self.assertFalse(status['device']['active'])
        await self.client.delete('/api/v1/fishing/trip-alerts/account')
        self.assertIsNone((await self.client.get(self.url)).json()['device'])

    async def test_same_snapshot_does_not_reset_state_and_empty_removes(self):
        await self.sync(); await self.evaluate()
        await self.sync({**self.payload, 'revision': 2})
        await self.evaluate(); self.assertEqual(len(await self.events()), 1)
        await self.sync({**self.payload, 'revision': 3, 'plans': []})
        self.assertEqual(await self.events(), [])

    async def test_shared_token_rejected_and_stale_not_favorable(self):
        await self.sync()
        self.assertEqual((await self.sync(user='b')).status_code, 409)
        await self.evaluate({**forecast(), 'status': 'stale'})
        self.assertEqual(await self.events(), [])
        state = (await self.client.get(self.url)).json()['plans'][0]['last_state']
        self.assertEqual(state, 'unavailable')

    async def test_concurrent_delivery_only_sends_once(self):
        await self.sync(); await self.evaluate()
        event = (await self.events())[0]
        async def deliver_once():
            async with self.sessions() as session:
                await dispatch(session, event, NOW)
                await session.commit()
        with patch('workers.trip_alert_worker.deliver', new=AsyncMock(return_value='sent')) as send:
            await asyncio.gather(deliver_once(), deliver_once())
            send.assert_awaited_once()

    async def test_ended_or_unchecked_events_never_deliver(self):
        await self.sync(); await self.evaluate()
        event = (await self.events())[0]
        with patch('workers.trip_alert_worker.deliver', new=AsyncMock()) as send:
            async with self.sessions() as session:
                await dispatch(session, event, NOW+timedelta(hours=1))
                await session.commit()
            send.assert_not_awaited()
        self.assertEqual((await self.events())[0]['delivery'], 'superseded')
