import copy
import unittest
from datetime import timedelta
from unittest.mock import AsyncMock, patch

import httpx
from fastapi import FastAPI

from services import departure_marine as dm
from services import port_forecasts as pf
from api.routers.port_forecasts import router
from test_port_forecasts import Cache, NOW, SPOT, kma_body, jma_body


def tide_body(day='2026-11-24', height=0):
    return {'header': {'resultCode': '00'}, 'body': {'items': {'item': [
        {'obsvtrNm': '부산', 'lat': 35.09638, 'lot': 129.03527,
         'predcDt': f'{day} 07:54', 'predcTdlvVl': height, 'extrSe': '1'},
        {'obsvtrNm': '부산', 'lat': 35.09638, 'lot': 129.03527,
         'predcDt': f'{day} 13:48', 'predcTdlvVl': -10, 'extrSe': '4'},
    ]}}}


def japan_body(code='420030'):
    return [{'reportDatetime': '2026-11-24T05:00:00+09:00', 'timeSeries': [{
        'timeDefines': ['2026-11-24T05:00:00+09:00', '2026-11-25T00:00:00+09:00'],
        'areas': [{'area': {'code': code, 'name': '壱岐・対馬'},
                   'waves': ['２．５メートル', '２．５メートル 後 １．５メートル'],
                   'weathers': ['くもり', '晴れ'], 'winds': ['北の風', '南の風']}],
    }]}]


class DepartureTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        dm._memory.clear()
        self.addCleanup(dm._memory.clear)
        env = patch.dict('os.environ', {'KMA_API_KEY': 'test-only', 'KMA_API_PROVIDER': 'datagokr', 'KHOA_API_KEY': '', 'KHOA_TIDE_API_KEY': '',
            'OPEN_METEO_API_KEY': '', 'OPEN_METEO_ALLOW_PUBLIC_EVALUATION': 'false'})
        env.start()
        self.addCleanup(env.stop)

    def handler(self, req):
        if 'tideFcst' in req.url.path:
            d = req.url.params['reqDate']
            return httpx.Response(200, json=tide_body(f'{d[:4]}-{d[4:6]}-{d[6:]}'))
        if 'jma.go.jp' in req.url.host:
            return httpx.Response(200, json=japan_body('400010' if '400000' in req.url.path else '420030'))
        return httpx.Response(200, json=kma_body())

    async def test_combined_reference_without_open_meteo_key(self):
        async with httpx.AsyncClient(transport=httpx.MockTransport(self.handler)) as c:
            data = await dm.departure_info(SPOT, c, now=NOW)
        self.assertEqual(data['providers']['jma']['status'], 'unavailable')
        marine = data['marine']
        self.assertEqual(marine['japan_reference'][0]['status'], 'available')
        self.assertEqual(marine['japan_reference'][0]['country'], 'JP')
        self.assertEqual(marine['tides']['days'][0]['station']['code'], 'DT_0005')
        self.assertEqual(marine['tides']['days'][1]['date'], '2026-11-25')
        self.assertEqual(marine['tides']['days'][0]['events'][0]['height_m'], 0)
        self.assertEqual(marine['tides']['days'][0]['events'][1]['height_m'], -0.1)
        self.assertIn('한국 항구의 예보가 아니', marine['reference_note'])
        self.assertIsNone(data['hours'][0]['wind_difference'])
        self.assertNotIn('test-only', str(data))

    def test_station_name_position_date_and_units_are_checked(self):
        parsed = dm.parse_tides(tide_body(height=129), ('DT_0005', '부산'), SPOT, NOW.date())
        self.assertEqual(parsed['events'][0]['height_m'], 1.29)
        self.assertLess(parsed['station']['distance_km'], 3)
        for field, value in [('obsvtrNm', '완도'), ('lat', 34.3156), ('lot', None), ('predcDt', '2026-11-23 07:54')]:
            data = tide_body()
            data['body']['items']['item'][0][field] = value
            with self.assertRaises(dm.SourceFailure):
                dm.parse_tides(data, ('DT_0005', '부산'), SPOT, NOW.date())

    def test_tide_sentinels_and_missing_events_not_zero(self):
        data = tide_body(height=-9999)
        data['body']['items']['item'] = data['body']['items']['item'][:1]
        with self.assertRaises(dm.SourceFailure):
            dm.parse_tides(data, ('DT_0005', '부산'), SPOT, NOW.date())

    def test_japanese_prose_kept_daily_not_numeric_or_korean_port(self):
        data = dm.parse_japan(japan_body(), '420030', NOW)
        self.assertEqual(data['days'][1]['waves'], '２．５メートル 後 １．５メートル')
        self.assertNotIn('wave_height', data['days'][0])
        self.assertNotIn('swell_height', data['days'][0])
        with self.assertRaises(dm.SourceFailure):
            dm.parse_japan(japan_body(), 'wrong-area', NOW)
        with self.assertRaises(dm.SourceFailure):
            dm.parse_japan(japan_body(), '420030', NOW+timedelta(days=2))

    async def test_provider_failures_are_independent(self):
        def handler(req):
            if 'tideFcst' in req.url.path:
                return httpx.Response(403)
            if req.url.host == 'apis.data.go.kr':
                return httpx.Response(429)
            return self.handler(req)
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as c:
            data = await dm.departure_info(SPOT, c, now=NOW)
        self.assertEqual(data['providers']['kma']['reason'], 'rate_limited')
        self.assertEqual(data['marine']['tides']['days'][0]['reason'], 'unauthorized')
        self.assertEqual(data['marine']['japan_reference'][0]['status'], 'available')

    async def test_today_failure_keeps_tomorrow(self):
        def handler(req):
            if req.url.params.get('reqDate') == '20261124':
                return httpx.Response(503)
            return self.handler(req)
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as c:
            data = await dm.departure_info(SPOT, c, now=NOW)
        days = data['marine']['tides']['days']
        self.assertEqual([d['status'] for d in days], ['unavailable', 'available'])

    async def test_reference_cache_shared_between_ports_and_no_key(self):
        requests = []
        def handler(req):
            requests.append(req)
            return self.handler(req)
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as c:
            for _ in range(2):
                await dm.japan_reference(dm.JAPAN_AREAS[0], c, None, NOW)
        self.assertEqual(len(requests), 1)
        self.assertFalse(requests[0].url.query)

    async def test_cache_stale_expiry_no_timestamp_or_ttl_extension(self):
        cache = Cache()
        fetch = AsyncMock(return_value={'events': [], 'issued_at': None})
        first = await dm.cached('key', fetch, cache, NOW, 1800)
        fetch.side_effect = RuntimeError('untrusted upstream error containing secret')
        stale = await dm.cached('key', fetch, cache, NOW+timedelta(hours=1), 1800)
        self.assertEqual(stale['status'], 'stale')
        self.assertEqual(stale['fetched_at'], first['fetched_at'])
        self.assertEqual(cache.writes, 1)
        expired = await dm.cached('key', fetch, cache, NOW+timedelta(hours=7), 1800)
        self.assertEqual(expired['status'], 'unavailable')
        self.assertNotIn('secret', str(expired))

    async def test_cache_failure_does_not_prevent_fetch_and_errors_backoff(self):
        cache = Cache()
        cache.get = AsyncMock(side_effect=RuntimeError())
        cache.setex = AsyncMock(side_effect=RuntimeError())
        fetch = AsyncMock(side_effect=dm.SourceFailure('rate_limited'))
        for _ in range(2):
            result = await dm.cached('key', fetch, cache, NOW, 1800)
        self.assertEqual(result['reason'], 'rate_limited')
        self.assertEqual(fetch.await_count, 1)

    async def test_reuses_worker_key_for_modern_khoa_endpoint(self):
        requests = []
        def handler(request):
            requests.append(request)
            return self.handler(request)
        with patch.dict('os.environ', {'KMA_API_KEY': '', 'KHOA_TIDE_API_KEY': '', 'KHOA_API_KEY': 'worker-key'}):
            async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as c:
                data = await dm.tide_day(SPOT, c, Cache(), NOW, NOW.date())
        self.assertEqual(data['status'], 'available')
        self.assertEqual(str(requests[0].url).split('?')[0], dm.TIDE_URL)
        self.assertEqual(requests[0].url.params['serviceKey'], 'worker-key')

    async def test_api_hub_key_is_not_sent_to_khoa(self):
        with patch.dict('os.environ', {'KMA_API_PROVIDER': 'apihub', 'KHOA_TIDE_API_KEY': '', 'KHOA_API_KEY': ''}):
            async with httpx.AsyncClient(transport=httpx.MockTransport(self.handler)) as c:
                data = await dm.tide_day(SPOT, c, Cache(), NOW, NOW.date())
        self.assertEqual(data['reason'], 'missing_api_key')

    async def test_kma_wav_zero_and_missing_without_invented_swell(self):
        data = kma_body()
        data['response']['body']['items']['item'].append(
            {'fcstDate': '20261124', 'fcstTime': '0900', 'category': 'WAV', 'fcstValue': '0'})
        async with httpx.AsyncClient(transport=httpx.MockTransport(lambda r: httpx.Response(200, json=data))) as c:
            result = await pf.fetch_kma(SPOT, c, NOW)
        self.assertEqual(result['hourly'][0]['wave_height'], 0)
        self.assertNotIn('wave_height', result['hourly'][1])
        self.assertNotIn('swell_height', result['hourly'][0])
        self.assertIsNone(pf.measurement(-1, 'wave_height'))

    async def test_combined_api_contract_and_404(self):
        app = FastAPI()
        app.include_router(router)
        with patch('api.routers.port_forecasts.departure_info', AsyncMock(return_value={'marine': {}})) as loader:
            async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url='http://test') as c:
                self.assertEqual((await c.get('/api/v1/marine/spots/unknown/departure-info')).status_code, 404)
                result = await c.get('/api/v1/marine/spots/FS_004/departure-info')
                self.assertEqual(result.status_code, 200)
                self.assertIn('marine', result.json())
                self.assertEqual(loader.await_count, 1)
