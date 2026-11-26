"""Same-location forecasts, without substituting another agency or mock values."""
import asyncio
import json
import math
import os
from datetime import datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

import httpx

from workers.weather_collector import _latest_base_time, wgs84_to_grid
from services.kma_api import build_request, resolve_provider

KST = ZoneInfo('Asia/Seoul')
PORTS = json.loads((Path(__file__).parents[1] / 'data/fishing_spots.json').read_text())
FIELDS = {'TMP': 'temperature', 'WSD': 'wind_speed', 'VEC': 'wind_direction', 'REH': 'humidity', 'POP': 'rain_probability', 'WAV': 'wave_height'}
JMA_FIELDS = {'temperature_2m': 'temperature', 'wind_speed_10m': 'wind_speed', 'wind_direction_10m': 'wind_direction', 'relative_humidity_2m': 'humidity', 'precipitation': 'precipitation'}
SOURCES = {
    'kma': {'name': '한국 기상청', 'model': '동네예보 · 단기예보', 'via': '공공데이터포털', 'url': 'https://www.data.go.kr/data/15084084/openapi.do'},
    'jma': {'name': '일본 기상청', 'model': 'JMA MSM / GSM', 'via': 'Open-Meteo', 'url': 'https://open-meteo.com/en/docs/jma-api'},
}


def numeric(value):
    try:
        n = float(value)
        return n if math.isfinite(n) and n > -900 else None
    except (ValueError, TypeError):
        return None


def measurement(value, field):
    number = numeric(value)
    if number is None:
        return None
    if field in ('wind_speed', 'precipitation', 'wave_height') and number < 0:
        return None
    if field in ('humidity', 'rain_probability') and not 0 <= number <= 100:
        return None
    if field == 'wind_direction' and not 0 <= number <= 360:
        return None
    return number


def jma_configuration():
    key = os.getenv('OPEN_METEO_API_KEY', '').strip()
    if key.startswith('YOUR_'):
        key = ''
    evaluation = os.getenv('OPEN_METEO_ALLOW_PUBLIC_EVALUATION', '').lower() == 'true'
    return key, evaluation


def timestamp(value):
    dt = datetime.fromisoformat(value)
    return (dt.replace(tzinfo=KST) if dt.tzinfo is None else dt.astimezone(KST)).isoformat()


async def fetch_kma(spot, client, now):
    key = os.getenv('KMA_API_KEY', '').strip()
    if not key or key.startswith('YOUR_'):
        return {'status': 'unavailable', 'message': '한국 기상청 연결 준비 중입니다.', 'reason': 'missing_api_key', 'hourly': []}
    # Use Korean local issue times even when the server runs in UTC.
    base_date, base_time = _latest_base_time(now - timedelta(minutes=30))
    nx, ny = wgs84_to_grid(float(spot['lat']), float(spot['lon']))
    url, params = build_request('VilageFcstInfoService_2.0/getVilageFcst', key,
        {'pageNo': 1, 'numOfRows': 3000, 'dataType': 'JSON', 'base_date': base_date, 'base_time': base_time, 'nx': nx, 'ny': ny})
    response = await client.get(url.replace('http://', 'https://', 1), params=params, timeout=8)
    response.raise_for_status()
    body = response.json()['response']
    if body.get('header', {}).get('resultCode') != '00':
        raise ValueError('KMA returned no usable forecast')
    items = body['body']['items']['item']
    if isinstance(items, dict):
        items = [items]
    rows = {}
    for item in items:
        field = FIELDS.get(item.get('category'))
        if not field:
            continue
        dt = datetime.strptime(item['fcstDate'] + item['fcstTime'], '%Y%m%d%H%M').replace(tzinfo=KST).isoformat()
        rows.setdefault(dt, {'time': dt})[field] = measurement(item['fcstValue'], field)
    issued = datetime.strptime(base_date + base_time, '%Y%m%d%H%M').replace(tzinfo=KST)
    return {'status': 'available', 'issued_at': issued.isoformat(), 'grid': {'x': nx, 'y': ny}, 'hourly': sorted(rows.values(), key=lambda r: r['time'])}


async def fetch_jma(spot, client, now):
    key, evaluation = jma_configuration()
    if not key and not evaluation:
        return {'status': 'unavailable', 'message': '일본 예보 서비스 연결 준비 중입니다.', 'reason': 'commercial_api_not_configured', 'hourly': []}
    host = 'customer-api.open-meteo.com' if key else 'api.open-meteo.com'
    params = {'latitude': float(spot['lat']), 'longitude': float(spot['lon']), 'hourly': ','.join(JMA_FIELDS), 'timezone': 'Asia/Seoul', 'forecast_days': 3, 'wind_speed_unit': 'ms', 'temperature_unit': 'celsius', 'precipitation_unit': 'mm', 'cell_selection': 'nearest'}
    if key:
        params['apikey'] = key
    response = await client.get(f'https://{host}/v1/jma', params=params, timeout=8)
    response.raise_for_status()
    data = response.json()
    units = data['hourly_units']
    expected_units = {'wind_speed_10m': 'm/s', 'temperature_2m': '°C', 'wind_direction_10m': '°', 'relative_humidity_2m': '%', 'precipitation': 'mm'}
    if any(units.get(field) != unit for field, unit in expected_units.items()) or data.get('utc_offset_seconds') != 32400:
        raise ValueError('Unexpected JMA units or timezone')
    hourly = data['hourly']
    rows = []
    for i, time in enumerate(hourly['time']):
        row = {'time': timestamp(time)}
        for source, field in JMA_FIELDS.items():
            values = hourly.get(source, [])
            row[field] = measurement(values[i], field) if i < len(values) else None
        rows.append(row)
    # generationtime_ms is server processing time, not model publication time.
    return {'status': 'available', 'issued_at': None, 'grid': {'latitude': data.get('latitude'), 'longitude': data.get('longitude')}, 'hourly': rows}


def future_rows(rows, now):
    start = now.replace(minute=0, second=0, microsecond=0)
    end = start + timedelta(hours=48)
    return [r for r in rows if start <= datetime.fromisoformat(r['time']) < end and any(r.get(k) is not None for k in ('temperature', 'wind_speed', 'humidity', 'wave_height'))]


async def provider_forecast(provider, spot, client, cache, now):
    # Evaluation data must not leak into a production response through a cache.
    mode = 'standard'
    if provider == 'kma':
        mode = resolve_provider(os.getenv('KMA_API_KEY', ''))
    if provider == 'jma':
        key, evaluation = jma_configuration()
        if not key and not evaluation:
            return {**SOURCES[provider], 'status': 'unavailable', 'reason': 'commercial_api_not_configured', 'message': '일본 예보 서비스 연결 준비 중입니다.', 'fetched_at': None, 'issued_at': None, 'hourly': []}
        mode = 'customer' if key else 'evaluation'
    cache_key = f"port-forecast:v3:{provider}:{mode}:{spot['spot_id']}:{spot['lat']}:{spot['lon']}"
    old = None
    if cache is not None:
        try:
            raw = await cache.get(cache_key)
            old = json.loads(raw) if raw else None
            if old:
                age = (now - datetime.fromisoformat(old['fetched_at'])).total_seconds()
                if 0 <= age < 1200 and future_rows(old['hourly'], now):
                    return {**old, 'hourly': future_rows(old['hourly'], now)}
        except (Exception,):
            old = None  # A cache outage must not prevent a live fetch.
    try:
        result = await (fetch_kma if provider == 'kma' else fetch_jma)(spot, client, now)
        if result['status'] == 'available' and not future_rows(result['hourly'], now):
            raise ValueError('No current forecast')
        result.update(SOURCES[provider])
        result['fetched_at'] = now.isoformat() if result['status'] == 'available' else None
        if result['status'] == 'available' and cache is not None:
            try:
                await cache.setex(cache_key, 21600, json.dumps(result, ensure_ascii=False))
            except Exception:
                pass
    except Exception as error:
        # Never log upstream URLs: KMA and customer API keys are query parameters.
        rate_limited = isinstance(error, httpx.HTTPStatusError) and error.response.status_code == 429
        if old and 0 <= (now - datetime.fromisoformat(old['fetched_at'])).total_seconds() < 21600 and future_rows(old['hourly'], now):
            result = {**old, 'status': 'stale', 'message': '갱신 지연 · 이전에 받은 예보입니다.'}
            if rate_limited:
                result.update(reason='rate_limited', message='API 호출 한도 초과 · 이전에 받은 예보입니다.')
        else:
            result = {**SOURCES[provider], 'status': 'unavailable', 'message': '예보를 가져오지 못했습니다. 잠시 후 다시 시도해 주세요.', 'fetched_at': None, 'issued_at': None, 'hourly': []}
            if rate_limited:
                result.update(reason='rate_limited', message='제공기관의 API 호출 한도를 초과했습니다. 한도 복구 후 다시 확인해 주세요.')
    result['hourly'] = future_rows(result['hourly'], now)
    return result


async def compare_port(spot, client, cache=None, now=None):
    now = (now or datetime.now(KST)).astimezone(KST)
    kma, jma = await asyncio.gather(*(provider_forecast(p, spot, client, cache, now) for p in ('kma', 'jma')))
    by_kma = {r['time']: r for r in kma.pop('hourly')}
    by_jma = {r['time']: r for r in jma.pop('hourly')}
    rows = []
    for time in sorted(by_kma.keys() | by_jma.keys()):
        left, right = by_kma.get(time), by_jma.get(time)
        delta = None
        if left and right and left.get('wind_speed') is not None and right.get('wind_speed') is not None:
            delta = round(right['wind_speed'] - left['wind_speed'], 1)
        rows.append({'time': time, 'kma': left, 'jma': right, 'wind_difference': delta})
    return {'spot': {k: spot[k] for k in ('spot_id', 'name', 'region', 'lat', 'lon')}, 'timezone': 'Asia/Seoul', 'providers': {'kma': kma, 'jma': jma}, 'hours': rows,
            'note': '항구 좌표 주변의 예보 격자를 비교합니다. 바다 위 출조 지점의 관측값이나 출항 허가 정보가 아닙니다.',
            'precipitation_note': '한국은 강수확률(%), 일본은 직전 1시간 강수량(mm)입니다. 서로 다른 항목이며 파고는 이 비교에 포함되지 않습니다.'}
