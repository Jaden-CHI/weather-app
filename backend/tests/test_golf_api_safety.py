"""Exercise the actual FastAPI router; only external services are mocked."""
import json
import sys
import unittest
from contextlib import ExitStack
from pathlib import Path
from unittest.mock import AsyncMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from fastapi import FastAPI
from fastapi.testclient import TestClient
from api.routers import golf
from services.forecast_safety import target_date
from workers.notification_worker import _assess_golf_status, _should_notify


class GolfApiSafetyTests(unittest.TestCase):
    def setUp(self):
        self.stack = ExitStack()
        self.addCleanup(self.stack.close)
        app = FastAPI()
        app.include_router(golf.router)

        async def db():
            yield object()
        app.dependency_overrides[golf.get_db] = db
        self.client = self.stack.enter_context(TestClient(app))
        self.forecast = [{
            'date': target_date(0).strftime('%Y%m%d'), 'time': '1200',
            'temp': 20, 'wind_speed': 3, 'rain_prob': 10, 'sky': 1, 'lightning': 0,
        }]
        self.cache = {'source': 'KMA', 'kma_forecast': self.forecast}
        self.redis = AsyncMock()
        self.redis.get.return_value = json.dumps(self.cache)
        self.stack.enter_context(patch.object(golf, '_get_redis', return_value=self.redis))
        self.course = {'course_id': 'CC_TEST', 'name': '테스트 코스', 'region': '테스트',
                       'grid_x': 1, 'grid_y': 2, 'lat': 37, 'lon': 127, 'golfzon_linked': False}
        self.stack.enter_context(patch.object(golf, 'get_course', AsyncMock(return_value=self.course)))
        self.policy = self.stack.enter_context(patch.object(golf, 'get_cancellation_policy', AsyncMock(return_value=None)))
        self.live = self.stack.enter_context(patch.object(golf, '_fetch_custom_open_meteo', AsyncMock(
            return_value=(self.forecast, [], 'OPEN_METEO'))))
        self.advisor = self.stack.enter_context(patch.object(golf, 'get_golf_recommendation', AsyncMock(
            return_value={'status': 'GREEN', 'message': '양호', 'detail': ''})))
        self.custom = '/api/v1/golf/custom/weather?lat=37&lon=127&name=test&dday=0'
        self.registered = '/api/v1/golf/courses/CC_TEST/weather?dday=0'

    def test_custom_outage_is_503_not_fabricated_weather(self):
        self.live.side_effect = RuntimeError('upstream unavailable')
        response = self.client.get(self.custom)
        self.assertEqual(response.status_code, 503)
        self.assertNotIn('forecast', response.json())
        self.advisor.assert_not_awaited()

    def test_custom_missing_requested_day_is_503(self):
        self.live.return_value = ([dict(self.forecast[0], date='20000101')], [], 'OPEN_METEO')
        self.assertEqual(self.client.get(self.custom).status_code, 503)

    def test_registered_missing_requested_day_is_503(self):
        self.cache['kma_forecast'] = [dict(self.forecast[0], date='20000101')]
        self.redis.get.return_value = json.dumps(self.cache)
        self.assertEqual(self.client.get(self.registered).status_code, 503)

    def test_sample_cache_with_upstream_outage_is_503(self):
        self.cache['source'] = 'MOCK'
        self.redis.get.return_value = json.dumps(self.cache)
        self.live.side_effect = RuntimeError('upstream unavailable')
        self.assertEqual(self.client.get(self.registered).status_code, 503)
        self.advisor.assert_not_awaited()

    def test_sample_cache_without_coordinates_is_503(self):
        self.course['lat'] = None
        self.cache['source'] = 'MOCK_CUSTOM'
        self.redis.get.return_value = json.dumps(self.cache)
        self.assertEqual(self.client.get(self.registered).status_code, 503)

    def test_sample_cache_is_replaced_only_by_live_forecast(self):
        self.cache['source'] = 'MOCK'
        self.redis.get.return_value = json.dumps(self.cache)
        response = self.client.get(self.registered)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()['source'], 'OPEN_METEO')
        self.assertEqual(response.json()['forecast'], self.forecast)

    def test_unverified_policy_is_not_a_free_cancellation_promise(self):
        self.policy.return_value = {'free_cancel_hours': 24, 'source_url': 'https://example.com'}
        response = self.client.get(self.registered + '&start_hour=12&start_minute=37')
        self.assertEqual(response.status_code, 200)
        policy = response.json()['cancellation_policy']
        self.assertFalse(policy['verified'])
        self.assertIsNone(policy['can_cancel_free'])
        self.assertIsNone(policy['deadline_str'])

    def test_verified_policy_uses_teeoff_minutes(self):
        self.policy.return_value = {'free_cancel_hours': 24, 'source_url': 'https://example.com',
                                   'verified_at': '2026-10-14'}
        response = self.client.get(self.registered + '&start_hour=12&start_minute=37')
        self.assertEqual(response.status_code, 200)
        policy = response.json()['cancellation_policy']
        self.assertTrue(policy['verified'])
        self.assertTrue(policy['deadline_str'].endswith('12:37'))

    def test_legacy_client_without_minutes_does_not_get_deadline(self):
        self.policy.return_value = {'free_cancel_hours': 24, 'source_url': 'https://example.com',
                                   'verified_at': '2026-10-14'}
        response = self.client.get(self.registered + '&start_hour=12')
        self.assertEqual(response.status_code, 200)
        self.assertIsNone(response.json()['cancellation_policy']['deadline_str'])

    def test_outside_forecast_horizon_is_rejected(self):
        for path in (self.custom, self.registered):
            for day in (-1, 8):
                self.assertEqual(self.client.get(path.replace('dday=0', f'dday={day}')).status_code, 422)

    def test_outside_round_window_is_not_replaced_by_other_hours(self):
        self.assertEqual(golf._filter_by_round_window(self.forecast, 20), [])

    def test_sample_or_wrong_date_cannot_trigger_weather_push(self):
        for cache in ({'source': 'MOCK', 'kma_forecast': self.forecast},
                      {'source': 'KMA', 'kma_forecast': [dict(self.forecast[0], date='20000101')]}):
            status, _, _ = _assess_golf_status(cache, target_date(0))
            self.assertEqual(status, 'UNKNOWN')
            self.assertFalse(_should_notify('GREEN', status))


if __name__ == '__main__':
    unittest.main()
