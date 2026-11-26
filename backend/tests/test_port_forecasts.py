import copy
import json
import unittest
from datetime import datetime, timedelta, timezone
from unittest.mock import patch

import httpx
from fastapi import FastAPI
from services import port_forecasts as pf
from api.routers.port_forecasts import router

NOW = datetime(2026, 11, 24, 9, 20, tzinfo=pf.KST)
SPOT = pf.PORTS[3]

def kma_body():
    items = []
    for hour, wind in [('0900', '2.5'), ('1000', '0')]:
        for cat, val in [('TMP', '11'), ('WSD', wind), ('VEC', '90'), ('REH', '70'), ('POP', '30')]:
            items.append({'fcstDate': '20261124', 'fcstTime': hour, 'category': cat, 'fcstValue': val})
    return {'response': {'header': {'resultCode': '00'}, 'body': {'items': {'item': items}}}}

def jma_body():
    return {'utc_offset_seconds': 32400, 'latitude': 35.1, 'longitude': 129,
      'hourly_units': {'wind_speed_10m': 'm/s', 'temperature_2m': '°C', 'wind_direction_10m': '°', 'relative_humidity_2m': '%', 'precipitation': 'mm'},
      'hourly': {'time': ['2026-11-24T08:00', '2026-11-24T09:00', '2026-11-24T10:00', '2026-11-24T11:00'],
      'temperature_2m': [10, 12, None, 14], 'wind_speed_10m': [1, 5, 0, None],
      'wind_direction_10m': [0, 180, 90, 90], 'relative_humidity_2m': [60]*4, 'precipitation': [0, 1.2, 0, None]}}

class Cache:
    def __init__(self): self.data = {}; self.writes = 0
    async def get(self, key): return self.data.get(key)
    async def setex(self, key, ttl, value): self.data[key] = value; self.writes += 1
    async def aclose(self): pass

class PortForecastTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        self.env = patch.dict('os.environ', {'KMA_API_KEY': 'test-only', 'KMA_API_PROVIDER': 'datagokr', 'OPEN_METEO_API_KEY': '', 'OPEN_METEO_ALLOW_PUBLIC_EVALUATION': 'true'})
        self.env.start(); self.addCleanup(self.env.stop)
        self.requests = []
    def handler(self, request):
        self.requests.append(request)
        return httpx.Response(200, json=kma_body() if 'data.go.kr' in request.url.host else jma_body())
    def client(self, handler=None): return httpx.AsyncClient(transport=httpx.MockTransport(handler or self.handler))
    async def test_same_port_coordinates_and_units(self):
        async with self.client() as c: data = await pf.compare_port(SPOT, c, now=NOW)
        jma = next(r for r in self.requests if 'open-meteo' in r.url.host)
        kma = next(r for r in self.requests if 'data.go.kr' in r.url.host)
        self.assertEqual(float(jma.url.params['latitude']), SPOT['lat'])
        self.assertEqual(jma.url.params['wind_speed_unit'], 'ms')
        self.assertEqual(jma.url.path, '/v1/jma')
        self.assertEqual((int(kma.url.params['nx']), int(kma.url.params['ny'])), pf.wgs84_to_grid(SPOT['lat'], SPOT['lon']))
        self.assertEqual(data['hours'][0]['wind_difference'], 2.5)
        self.assertEqual(data['providers']['jma']['via'], 'Open-Meteo')

    async def test_kma_api_hub_key_uses_configured_provider(self):
        with patch.dict('os.environ', {'KMA_API_PROVIDER': 'apihub'}):
            async with self.client(lambda r: (self.requests.append(r) or httpx.Response(200, json=kma_body()))) as client:
                data = await pf.fetch_kma(SPOT, client, NOW)
        request = self.requests[0]
        self.assertEqual(request.url.host, 'apihub.kma.go.kr')
        self.assertEqual(request.url.params['authKey'], 'test-only')
        self.assertNotIn('serviceKey', request.url.params)
        self.assertEqual(data['status'], 'available')
    async def test_alignment_null_zero_and_forecast_horizon(self):
        async with self.client() as c: data = await pf.compare_port(SPOT, c, now=NOW)
        self.assertEqual(len(data['hours']), 3)
        self.assertTrue(data['hours'][0]['time'].endswith('09:00:00+09:00'))
        self.assertEqual(data['hours'][1]['wind_difference'], 0)
        self.assertIsNone(data['hours'][1]['jma']['temperature'])
        self.assertIsNone(data['hours'][2]['kma'])
        self.assertIsNone(data['hours'][2]['wind_difference'])
        self.assertNotIn('rain_probability', data['hours'][0]['jma'])
        self.assertNotIn('wave_height', data['hours'][0]['jma'])
    async def test_server_utc_uses_kst_issue_time(self):
        async with self.client() as c: data = await pf.compare_port(SPOT, c, now=NOW.astimezone(timezone.utc))
        req = next(r for r in self.requests if 'data.go.kr' in r.url.host)
        self.assertEqual(req.url.params['base_date'], '20261124')
        self.assertEqual(req.url.params['base_time'], '0800')
        self.assertEqual(data['providers']['kma']['issued_at'], '2026-11-24T08:00:00+09:00')
        self.assertIsNone(data['providers']['jma']['issued_at'])
    async def test_missing_kma_key_keeps_real_jma(self):
        with patch.dict('os.environ', {'KMA_API_KEY': ''}):
            async with self.client() as c: data = await pf.compare_port(SPOT, c, now=NOW)
        self.assertEqual(len(self.requests), 1)
        self.assertEqual(data['providers']['kma']['reason'], 'missing_api_key')
        self.assertEqual(data['providers']['jma']['status'], 'available')
    async def test_each_provider_failure_is_independent(self):
        for failed in ['kma', 'jma']:
            def handler(req):
                provider = 'kma' if 'data.go.kr' in req.url.host else 'jma'
                return httpx.Response(503) if provider == failed else self.handler(req)
            async with self.client(handler) as c: data = await pf.compare_port(SPOT, c, now=NOW)
            self.assertEqual(data['providers'][failed]['status'], 'unavailable')
            self.assertEqual(data['providers']['jma' if failed == 'kma' else 'kma']['status'], 'available')
    async def test_empty_and_logical_error_not_success(self):
        for body in [{'response': {'header': {'resultCode': '30'}}}, {'response': {'header': {'resultCode': '00'}, 'body': {'items': {'item': []}}}}]:
            def handler(req): return httpx.Response(200, json=body) if 'data.go.kr' in req.url.host else self.handler(req)
            async with self.client(handler) as c: data = await pf.compare_port(SPOT, c, now=NOW)
            self.assertEqual(data['providers']['kma']['status'], 'unavailable')
    async def test_rate_limit_has_clear_reason_and_keeps_other_provider(self):
        def handler(req):
            return httpx.Response(429) if 'data.go.kr' in req.url.host else self.handler(req)
        async with self.client(handler) as c:
            data = await pf.compare_port(SPOT, c, now=NOW)
        self.assertEqual(data['providers']['kma']['reason'], 'rate_limited')
        self.assertIn('호출 한도', data['providers']['kma']['message'])
        self.assertEqual(data['providers']['jma']['status'], 'available')
        self.assertNotIn('test-only', json.dumps(data))

    async def test_rate_limit_preserves_cached_forecast_and_original_timestamp(self):
        cache = Cache()
        async with self.client() as c:
            first = await pf.provider_forecast('kma', SPOT, c, cache, NOW)
        async with self.client(lambda req: httpx.Response(429)) as c:
            stale = await pf.provider_forecast('kma', SPOT, c, cache, NOW + timedelta(minutes=25))
        self.assertEqual(stale['status'], 'stale')
        self.assertEqual(stale['reason'], 'rate_limited')
        self.assertEqual(stale['fetched_at'], first['fetched_at'])
        self.assertTrue(stale['hourly'])
        self.assertEqual(cache.writes, 1)
    async def test_jma_wrong_units_rejected(self):
        body = jma_body(); body['hourly_units']['wind_speed_10m'] = 'km/h'
        async with self.client(lambda req: httpx.Response(200, json=body)) as c:
            result = await pf.provider_forecast('jma', SPOT, c, None, NOW)
        self.assertEqual(result['status'], 'unavailable')
    async def test_cache_fresh_stale_and_expired(self):
        cache = Cache()
        async with self.client() as c:
            first = await pf.compare_port(SPOT, c, cache, NOW)
            await pf.compare_port(SPOT, c, cache, NOW + timedelta(minutes=10))
        self.assertEqual(len(self.requests), 2)
        self.assertEqual(cache.writes, 2)
        async with self.client(lambda req: httpx.Response(503)) as c:
            stale = await pf.compare_port(SPOT, c, cache, NOW + timedelta(minutes=25))
            expired = await pf.compare_port(SPOT, c, cache, NOW + timedelta(hours=7))
        self.assertEqual(stale['providers']['jma']['status'], 'stale')
        self.assertEqual(stale['providers']['jma']['fetched_at'], first['providers']['jma']['fetched_at'])
        self.assertEqual(expired['providers']['jma']['status'], 'unavailable')
        self.assertEqual(expired['hours'], [])
    async def test_cache_outage_does_not_hide_forecast(self):
        class Broken(Cache):
            async def get(self, key): raise ConnectionError()
            async def setex(self, *args): raise ConnectionError()
        async with self.client() as c: data = await pf.compare_port(SPOT, c, Broken(), NOW)
        self.assertEqual(data['providers']['kma']['status'], 'available')
    async def test_cache_isolated_by_port(self):
        cache = Cache()
        async with self.client() as c:
            await pf.compare_port(SPOT, c, cache, NOW)
            await pf.compare_port(pf.PORTS[0], c, cache, NOW)
        self.assertEqual(len(cache.data), 4)
    async def test_customer_key_only_goes_to_customer_endpoint(self):
        with patch.dict('os.environ', {'OPEN_METEO_API_KEY': 'test-customer'}):
            async with self.client() as c: await pf.fetch_jma(SPOT, c, NOW)
        self.assertEqual(self.requests[0].url.host, 'customer-api.open-meteo.com')
        self.assertEqual(self.requests[0].url.params['apikey'], 'test-customer')

    async def test_public_api_requires_explicit_evaluation_opt_in_even_with_cache(self):
        cache = Cache()
        async with self.client() as client:
            await pf.compare_port(SPOT, client, cache, NOW)
            self.requests.clear()
            with patch.dict('os.environ', {'OPEN_METEO_ALLOW_PUBLIC_EVALUATION': 'false'}):
                result = await pf.compare_port(SPOT, client, cache, NOW)
                direct = await pf.fetch_jma(SPOT, client, NOW)
        self.assertEqual(result['providers']['jma']['reason'], 'commercial_api_not_configured')
        self.assertEqual(direct['status'], 'unavailable')
        self.assertEqual(self.requests, [])

    async def test_customer_mode_does_not_reuse_evaluation_cache(self):
        cache = Cache()
        async with self.client() as client:
            await pf.provider_forecast('jma', SPOT, client, cache, NOW)
            with patch.dict('os.environ', {'OPEN_METEO_API_KEY': 'customer-test'}):
                await pf.provider_forecast('jma', SPOT, client, cache, NOW)
        self.assertEqual(len(self.requests), 2)
        self.assertEqual(self.requests[-1].url.host, 'customer-api.open-meteo.com')

    async def test_invalid_values_become_missing_without_discarding_valid_zero(self):
        body = copy.deepcopy(jma_body())
        body['hourly']['wind_speed_10m'][1] = -1
        body['hourly']['relative_humidity_2m'][1] = 110
        body['hourly']['wind_direction_10m'][1] = 999
        body['hourly']['precipitation'][1] = -1
        async with self.client(lambda req: httpx.Response(200, json=body)) as client:
            result = await pf.fetch_jma(SPOT, client, NOW)
        for field in ('wind_speed', 'humidity', 'wind_direction', 'precipitation'):
            self.assertIsNone(result['hourly'][1][field])
        self.assertEqual(result['hourly'][2]['wind_speed'], 0)

    async def test_cache_corruption_does_not_break_live_comparison(self):
        class Corrupt(Cache):
            async def get(self, key): return json.dumps({'fetched_at': 'broken'})
        async with self.client() as client:
            data = await pf.compare_port(SPOT, client, Corrupt(), NOW)
        self.assertEqual(data['providers']['kma']['status'], 'available')
        self.assertEqual(data['providers']['jma']['status'], 'available')

    async def test_kma_measurement_ranges(self):
        body = kma_body()
        for item in body['response']['body']['items']['item']:
            if item['category'] in ('WSD', 'POP', 'REH', 'VEC'):
                item['fcstValue'] = '-1'
        async with self.client(lambda req: httpx.Response(200, json=body)) as client:
            data = await pf.fetch_kma(SPOT, client, NOW)
        self.assertIsNone(data['hourly'][0]['wind_speed'])
        self.assertIsNone(data['hourly'][0]['humidity'])
        self.assertEqual(data['hourly'][0]['temperature'], 11)
    async def test_api_catalog_search_404_and_contract(self):
        app = FastAPI(); app.include_router(router)
        upstream = self.client()
        async def compare(spot, client, cache): return await pf.compare_port(spot, upstream, None, NOW)
        with patch('api.routers.port_forecasts.compare_port', compare), patch('api.routers.port_forecasts.aioredis.from_url', return_value=Cache()):
            async with httpx.AsyncClient(transport=httpx.ASGITransport(app), base_url='http://test') as c:
                catalog = await c.get('/api/v1/marine/forecast-spots?q=부산')
                self.assertEqual(catalog.json()['results'][0]['spot_id'], SPOT['spot_id'])
                self.assertEqual(len((await c.get('/api/v1/marine/forecast-spots')).json()['results']), 15)
                self.assertEqual((await c.get('/api/v1/marine/spots/missing/forecast-comparison')).status_code, 404)
                response = await c.get(f"/api/v1/marine/spots/{SPOT['spot_id']}/forecast-comparison")
                self.assertEqual(response.status_code, 200)
                self.assertEqual(response.json()['spot']['name'], SPOT['name'])
                self.assertEqual(response.json()['hours'][0]['wind_difference'], 2.5)
        await upstream.aclose()

if __name__ == '__main__': unittest.main()
