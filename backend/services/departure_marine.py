"""Independent Korean tides and explicitly Japanese regional reference forecasts.

Tides are station predictions, not port observations. Japanese daily prose is
never resampled, translated into numeric waves, or used in a departure score.
"""
import asyncio
import copy
import hashlib
import json
import math
import os
from collections import OrderedDict
from datetime import datetime, timedelta
from urllib.parse import unquote

import httpx

from services.port_forecasts import KST, compare_port, numeric, timestamp
from services.jma_korean import localize_reference

TIDE_URL = 'https://apis.data.go.kr/1192136/tideFcstHghLw/GetTideFcstHghLwApiService'
TIDE_SOURCE = 'https://www.data.go.kr/data/15156018/openapi.do'
# Codes/names verified against KHOA's 2026-11-06 guide. Returned coordinates
# are checked independently; these are named reference stations, not port IDs.
TIDE_STATIONS = {
    'FS_001': ('DT_0014', '통영'), 'FS_002': ('SO_0552', '고현항'),
    'FS_003': ('DT_0016', '여수'), 'FS_004': ('DT_0005', '부산'),
    'FS_005': ('DT_0065', '덕적도'), 'FS_006': ('SO_0699', '천리포항'),
    'FS_007': ('DT_0027', '완도'), 'FS_008': ('DT_0022', '성산포'),
    'FS_009': ('DT_0023', '모슬포'), 'FS_010': ('DT_0013', '울릉도'),
    'FS_011': ('DT_0012', '속초'), 'FS_012': ('SO_0732', '남애항'),
    'FS_013': ('SO_1267', '구룡포항'), 'FS_014': ('DT_0007', '목포'),
    'FS_015': ('DT_0018', '군산'),
}
JAPAN_AREAS = (
    ('420000', '420030', '이키·쓰시마', '壱岐・対馬'),
    ('400000', '400010', '후쿠오카 지방', '福岡地方'),
)
_memory = OrderedDict()


class SourceFailure(Exception):
    def __init__(self, reason):
        self.reason = reason


def unavailable(reason):
    messages = {
        'missing_api_key': '조석 서비스 인증키가 설정되지 않았습니다.',
        'unauthorized': '조석 API 활용 승인 또는 인증키를 확인해 주세요.',
        'rate_limited': '제공기관의 호출 한도를 초과했습니다.',
        'station_mismatch': '조석 기준 지점 검증이 필요해 자료를 표시하지 않습니다.',
        'station_unmapped': '연결된 조석 기준 지점이 없습니다.',
        'no_data': '해당 날짜에 제공된 자료가 없습니다.',
        'fetch_failed': '자료를 가져오지 못했습니다. 잠시 후 다시 시도해 주세요.',
    }
    return {'status': 'unavailable', 'reason': reason, 'message': messages.get(reason, messages['fetch_failed']), 'fetched_at': None, 'issued_at': None}


async def cached(key, fetch, cache, now, fresh_seconds):
    """Bounded fallback if Redis is down; never extend old observation age."""
    old = None
    try:
        raw = await cache.get(key) if cache is not None else None
        old = json.loads(raw) if raw else None
    except Exception:
        pass
    old = old or copy.deepcopy(_memory.get(key))
    try:
        age = (now - datetime.fromisoformat(old['_cached_at'])).total_seconds() if old else float('inf')
        ttl = fresh_seconds if old and old['status'] == 'available' else 60
        if 0 <= age < ttl:
            return {k: v for k, v in old.items() if k != '_cached_at'}
    except (KeyError, ValueError, TypeError):
        old, age = None, float('inf')
    try:
        result = await fetch()
        result.update(status='available', fetched_at=now.isoformat())
    except Exception as error:
        reason = error.reason if isinstance(error, SourceFailure) else 'fetch_failed'
        if isinstance(error, httpx.HTTPStatusError):
            reason = {401: 'unauthorized', 403: 'unauthorized', 429: 'rate_limited'}.get(error.response.status_code, reason)
        # Wrong source/station data must not be masked by an old successful cache.
        if old and old['status'] == 'available' and 0 <= age < 21600 and reason != 'station_mismatch':
            return {**{k: v for k, v in old.items() if k != '_cached_at'}, 'status': 'stale', 'message': '갱신 지연 · 이전 수신 자료', 'reason': reason}
        result = unavailable(reason)
    stored = {**result, '_cached_at': now.isoformat()}
    _memory[key] = copy.deepcopy(stored)
    _memory.move_to_end(key)
    while len(_memory) > 128:
        _memory.popitem(last=False)
    if cache is not None:
        try:
            await cache.setex(key, 21600 if result['status'] == 'available' else 60, json.dumps(stored, ensure_ascii=False))
        except Exception:
            pass
    return result


def distance_km(lat1, lon1, lat2, lon2):
    a, b = math.radians(lat1), math.radians(lat2)
    h = math.sin((b-a)/2)**2 + math.cos(a)*math.cos(b)*math.sin(math.radians(lon2-lon1)/2)**2
    return 6371 * 2 * math.asin(min(1, math.sqrt(h)))


def parse_tides(data, station, spot, day):
    data = data.get('response', data)
    code = str(data.get('header', {}).get('resultCode', ''))
    if code not in ('00', '0'):
        raise SourceFailure({'22': 'rate_limited', '30': 'unauthorized', '31': 'unauthorized'}.get(code, 'fetch_failed'))
    items = data.get('body', {}).get('items') or {}
    items = items.get('item', [])
    if isinstance(items, dict):
        items = [items]
    events, position = [], None
    for item in items:
        lat, lon = numeric(item.get('lat')), numeric(item.get('lot'))
        if item.get('obsvtrNm') != station[1] or lat is None or lon is None or not (-90 <= lat <= 90 and -180 <= lon <= 180):
            raise SourceFailure('station_mismatch')
        distance = distance_km(float(spot['lat']), float(spot['lon']), lat, lon)
        if distance > 40 or (position is not None and position != (lat, lon)):
            raise SourceFailure('station_mismatch')
        position = (lat, lon)
        time = timestamp(item['predcDt'])
        if datetime.fromisoformat(time).date() != day:
            raise SourceFailure('no_data')
        height = numeric(item.get('predcTdlvVl'))
        kind = str(item.get('extrSe'))
        if height is None or kind not in ('1', '2', '3', '4'):
            continue
        events.append({'time': time, 'kind': 'high' if kind in ('1', '3') else 'low', 'height_m': height / 100})
    if not events:
        raise SourceFailure('no_data')
    return {'events': sorted(events, key=lambda e: e['time']), 'issued_at': None,
            'station': {'code': station[0], 'name': station[1], 'lat': position[0], 'lon': position[1], 'distance_km': round(distance, 1)}}


async def tide_day(spot, client, cache, now, day):
    station = TIDE_STATIONS.get(spot['spot_id'])
    base = {'date': day.isoformat(), 'events': [], 'station': None}
    if station is None:
        return {**base, **unavailable('station_unmapped')}
    # The production worker uses KHOA_API_KEY for this same modern data.go.kr API.
    # Never send a KMA API Hub key to KHOA.
    from services.kma_api import resolve_provider
    kma_key = os.getenv('KMA_API_KEY', '').strip()
    key = (os.getenv('KHOA_TIDE_API_KEY', '').strip()
           or os.getenv('KHOA_API_KEY', '').strip()
           or (kma_key if resolve_provider(kma_key) == 'datagokr' else ''))
    if not key or key.startswith(('YOUR_', 'replace-')):
        return {**base, **unavailable('missing_api_key')}
    key = unquote(key)
    async def fetch():
        response = await client.get(TIDE_URL, params={'serviceKey': key, 'obsCode': station[0], 'reqDate': day.strftime('%Y%m%d'), 'type': 'json', 'pageNo': 1, 'numOfRows': 300}, timeout=8)
        response.raise_for_status()
        return parse_tides(response.json(), station, spot, day)
    fingerprint = hashlib.sha256(key.encode()).hexdigest()[:12]
    cache_key = f"departure:tide:v1:{fingerprint}:{spot['spot_id']}:{spot['lat']}:{spot['lon']}:{station[0]}:{day}"
    return {**base, **await cached(cache_key, fetch, cache, now, 10800)}


def parse_japan(data, area_code, now):
    for forecast in data:
        issued = datetime.fromisoformat(forecast['reportDatetime'])
        if issued.tzinfo is None or not 0 <= (now-issued).total_seconds() < 86400:
            continue
        for series in forecast.get('timeSeries', []):
            for area in series.get('areas', []):
                if area['area']['code'] != area_code or 'waves' not in area:
                    continue
                days = []
                for i, time in enumerate(series['timeDefines']):
                    if datetime.fromisoformat(time).astimezone(KST).date() < now.date():
                        continue
                    row = {'time': timestamp(time)}
                    for field in ('waves', 'winds', 'weathers'):
                        values = area.get(field, [])
                        row[field] = values[i] if i < len(values) and isinstance(values[i], str) else None
                    days.append(row)
                if days:
                    return {'issued_at': issued.isoformat(), 'days': days, 'original_name': area['area']['name']}
    raise SourceFailure('no_data')


async def japan_reference(area, client, cache, now):
    office, code, name, original = area
    async def fetch():
        response = await client.get(f'https://www.jma.go.jp/bosai/forecast/data/forecast/{office}.json', timeout=8)
        response.raise_for_status()
        return parse_japan(response.json(), code, now)
    result = await cached(f'departure:japan:v1:{code}:{now.date()}', fetch, cache, now, 1800)
    return localize_reference({'area_code': code, 'name': name, 'original_name': original, 'country': 'JP', 'days': [],
            'url': f'https://www.jma.go.jp/bosai/forecast/#area_type=offices&area_code={office}', **result})


async def departure_info(spot, client, cache=None, now=None):
    now = (now or datetime.now(KST)).astimezone(KST)
    weather, today, tomorrow, *references = await asyncio.gather(
        compare_port(spot, client, cache, now),
        *(tide_day(spot, client, cache, now, now.date()+timedelta(days=d)) for d in (0, 1)),
        *(japan_reference(a, client, cache, now) for a in JAPAN_AREAS),
    )
    weather['precipitation_note'] = '한국은 강수확률(%), 일본은 직전 1시간 강수량(mm)입니다. 서로 다른 항목입니다.'
    weather['marine'] = {
        'tides': {'name': '국립해양조사원', 'url': TIDE_SOURCE, 'days': [today, tomorrow],
                  'note': '기준 지점의 예측 조위입니다. 항구 현장 관측값·수심·조류 속도가 아니며, 높이는 제공기관 기준면 기준입니다.'},
        'japan_reference': references,
        'wave_note': '한국 파고는 기상청 단기예보의 WAV 값입니다. 격자에 파고가 없으면 미제공으로 표시합니다. 너울 높이·주기·방향은 별도 자료가 연결되지 않았습니다.',
        'reference_note': '일본 지역의 일별 광역 예보입니다. 선택한 한국 항구의 예보가 아니며, 한국 파고와 수치 비교하거나 출조 판단에 적용하지 않습니다.',
    }
    return weather
