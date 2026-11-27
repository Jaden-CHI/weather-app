"""Independent 30-minute Fishing check and durable, retryable FCM outbox."""
import asyncio
import hashlib
import os
from datetime import datetime, timedelta, timezone
from uuid import uuid4

import httpx
import redis.asyncio as aioredis
from sqlalchemy import text

from models.database import AsyncSessionLocal, engine
from services.fishing_push import enabled, user_active, deliver
from services.port_forecasts import PORTS, KST, provider_forecast
from services.trip_conditions import assess, should_notify, body_for, LABELS, instant

PORT_BY_ID = {p['spot_id']: p for p in PORTS}
LOCK_ID = 745830192


async def evaluate_device(session, device, forecasts, now):
    args = {'uid': device['uid'], 'install': device['installation_id']}
    # API mutations and delivery lock devices first as well. A disabled/deleted
    # plan cannot be delivered after its successful cancellation response.
    locked = (await session.execute(text('''SELECT * FROM fishing_push_devices
        WHERE uid=:uid AND installation_id=:install AND active AND expires_at>NOW() FOR UPDATE'''), args)).mappings().first()
    if not locked:
        return
    plans = (await session.execute(text('''SELECT * FROM fishing_trip_plans
        WHERE uid=:uid AND installation_id=:install FOR UPDATE'''), args)).mappings().all()
    for plan in plans:
        state = assess(plan['payload'], forecasts.get(plan['payload']['portId']), now)
        params = {**args, 'id': plan['plan_id'], 'state': state, 'now': now}
        await session.execute(text('''UPDATE fishing_trip_plans SET last_state=:state, checked_at=:now
            WHERE uid=:uid AND installation_id=:install AND plan_id=:id'''), params)
        if state == plan['last_state']:
            continue
        # Supersede pending messages if conditions changed before retry.
        await session.execute(text('''UPDATE fishing_trip_events SET delivery='superseded'
            WHERE uid=:uid AND installation_id=:install AND plan_id=:id AND delivery='pending' '''), params)
        if not should_notify(plan['last_state'], state):
            continue
        port = PORT_BY_ID[plan['payload']['portId']]
        await session.execute(text('''INSERT INTO fishing_trip_events
            (event_id,uid,installation_id,plan_id,revision,state,title,body,created_at)
            VALUES (:event,:uid,:install,:id,:revision,:state,:title,:body,:now)'''),
            {**params, 'event': str(uuid4()), 'revision': plan['revision'],
             'title': f"{port['name']} · {LABELS[state]}", 'body': body_for(state)})


async def dispatch(session, candidate, now):
    args = {'uid': candidate['uid'], 'install': candidate['installation_id'], 'event': candidate['event_id']}
    device = (await session.execute(text('''SELECT * FROM fishing_push_devices
        WHERE uid=:uid AND installation_id=:install FOR UPDATE'''), args)).mappings().first()
    if not device:
        return
    event = (await session.execute(text('''SELECT e.*, p.payload, p.revision AS current_revision,
        p.last_state, p.checked_at FROM fishing_trip_events e JOIN fishing_trip_plans p
        USING (uid,installation_id,plan_id) WHERE e.event_id=:event
        AND e.delivery='pending' AND e.next_attempt<=NOW() FOR UPDATE OF e,p'''), args)).mappings().first()
    if not event:
        return
    end = instant(event['payload']['endsAt'])
    if (not device['active'] or device['expires_at'] <= now or end <= now
            or event['revision'] != event['current_revision'] or event['state'] != event['last_state']
            or event['checked_at'] is None or now-event['checked_at'] > timedelta(minutes=45)):
        await session.execute(text("UPDATE fishing_trip_events SET delivery='superseded' WHERE event_id=:event"), args)
        return
    ttl = max(1, min(1800, int((end-now).total_seconds())))
    collapse_id = hashlib.sha256(f"{event['uid']}:{event['installation_id']}:{event['plan_id']}".encode()).hexdigest()
    result = await deliver(device['fcm_token'], {**event, 'collapse_id': collapse_id,
                           'expires_epoch': int(now.timestamp())+ttl}, ttl)
    if result == 'invalid_token':
        await session.execute(text('''UPDATE fishing_push_devices SET active=FALSE
            WHERE uid=:uid AND installation_id=:install'''), args)
    attempts = event['attempts'] + 1
    await session.execute(text('''UPDATE fishing_trip_events SET delivery=:delivery,
        attempts=:attempts, next_attempt=:next WHERE event_id=:event'''),
        {**args, 'delivery': 'pending' if result == 'retry' else result,
         'attempts': attempts, 'next': now+timedelta(minutes=min(30, 2 ** min(attempts, 5)))})


async def check_once():
    now = datetime.now(timezone.utc)
    cache = aioredis.from_url(os.getenv('REDIS_URL', 'redis://localhost:6379/0'),
                              decode_responses=True, socket_connect_timeout=1, socket_timeout=1)
    checked = sent = 0
    try:
        async with AsyncSessionLocal() as session:
            # Retain only 30 days of ended plans/events. Expired installations
            # cascade-delete their tokens, plans and history.
            await session.execute(text('DELETE FROM fishing_push_devices WHERE expires_at<NOW()'))
            await session.execute(text("DELETE FROM fishing_trip_plans WHERE (payload->>'endsAt')::timestamptz<NOW()-INTERVAL '30 days'"))
            await session.execute(text("DELETE FROM fishing_trip_events WHERE created_at<NOW()-INTERVAL '30 days'"))
            await session.commit()
            devices = (await session.execute(text('SELECT * FROM fishing_push_devices WHERE active AND expires_at>NOW()'))).mappings().all()
            rows = (await session.execute(text('''SELECT p.payload FROM fishing_trip_plans p
                JOIN fishing_push_devices d USING(uid,installation_id)
                WHERE d.active AND d.expires_at>NOW()
                AND (p.payload->>'endsAt')::timestamptz>NOW()
                AND (p.payload->>'startsAt')::timestamptz<=NOW()+INTERVAL '48 hours' '''))).mappings().all()
        port_ids = {r['payload']['portId'] for r in rows}
        forecasts = {}
        async with httpx.AsyncClient() as client:
            for port_id in port_ids:
                # Only KMA. No JMA paid calls, marine/tide calls or per-user duplicate fetches.
                try:
                    forecasts[port_id] = await provider_forecast('kma', PORT_BY_ID[port_id], client, cache, now.astimezone(KST))
                except Exception:
                    forecasts[port_id] = None
        active_users = {}
        for device in devices:
            try:
                uid = device['uid']
                if uid not in active_users:
                    active_users[uid] = await user_active(uid)
                async with AsyncSessionLocal() as session:
                    if not active_users[uid]:
                        await session.execute(text('DELETE FROM fishing_push_devices WHERE uid=:uid'), {'uid': uid})
                    else:
                        await evaluate_device(session, device, forecasts, now)
                        checked += 1
                    await session.commit()
            except Exception:
                print('[Fishing push] account/check deferred')
        async with AsyncSessionLocal() as session:
            candidates = (await session.execute(text("SELECT event_id,uid,installation_id FROM fishing_trip_events WHERE delivery='pending' AND next_attempt<=NOW() ORDER BY created_at LIMIT 1000"))).mappings().all()
        for candidate in candidates:
            if not active_users.get(candidate['uid']):
                continue
            try:
                async with AsyncSessionLocal() as session:
                    await dispatch(session, candidate, datetime.now(timezone.utc))
                    await session.commit()
                    sent += 1
            except Exception:
                print('[Fishing push] delivery deferred')
    finally:
        await cache.aclose()
    return {'checked_devices': checked, 'delivery_attempts': sent}


async def run_trip_alert_check():
    if not enabled():
        return {'enabled': False}
    # Dedicated session-level lock across replicas. PostgreSQL releases it on
    # disconnect/crash; do not use an expiring Redis lease for notification dedupe.
    async with engine.connect() as connection:
        acquired = (await connection.execute(text('SELECT pg_try_advisory_lock(:id)'), {'id': LOCK_ID})).scalar()
        if not acquired:
            return {'busy': True}
        try:
            return await check_once()
        finally:
            await connection.execute(text('SELECT pg_advisory_unlock(:id)'), {'id': LOCK_ID})


async def trip_alert_loop():
    while True:
        try:
            result = await run_trip_alert_check()
            if enabled():
                print(f'[Fishing push] {result}')
        except Exception:
            print('[Fishing push] check failed; next cycle will retry')
        await asyncio.sleep(1800)
