"""
기상청 단기예보 + Open-Meteo 수집 워커
USE_MOCK_DATA=true 환경에서는 실제 API 호출 없이 더미 데이터 반환
"""

import asyncio
import json
import math
import os
import random
from datetime import datetime, timedelta
from typing import Any

import httpx
import redis.asyncio as aioredis


# ── 기상청 LCC 격자 변환 ────────────────────────────────────────
def wgs84_to_grid(lat: float, lon: float) -> tuple[int, int]:
    RE, GRID = 6371.00877, 5.0
    SLAT1, SLAT2 = 30.0, 60.0
    OLON, OLAT = 126.0, 38.0
    XO, YO = 43, 136
    DEGRAD = math.pi / 180.0

    re = RE / GRID
    slat1, slat2 = SLAT1 * DEGRAD, SLAT2 * DEGRAD
    olon_r, olat_r = OLON * DEGRAD, OLAT * DEGRAD

    sn = math.log(math.cos(slat1) / math.cos(slat2)) / math.log(
        math.tan(math.pi * 0.25 + slat2 * 0.5) / math.tan(math.pi * 0.25 + slat1 * 0.5)
    )
    sf = (math.tan(math.pi * 0.25 + slat1 * 0.5) ** sn) * math.cos(slat1) / sn
    ro = re * sf / (math.tan(math.pi * 0.25 + olat_r * 0.5) ** sn)

    ra = re * sf / (math.tan(math.pi * 0.25 + lat * DEGRAD * 0.5) ** sn)
    theta = lon * DEGRAD - olon_r
    theta = max(min(theta, math.pi), -math.pi) * sn

    x = int(ra * math.sin(theta) + XO + 0.5)
    y = int(ro - ra * math.cos(theta) + YO + 0.5)
    return x, y


# ── 기상청 발표 시각 계산 ─────────────────────────────────────────
def _latest_base_time(now: datetime) -> tuple[str, str]:
    """현재 시각 기준 가장 최근 기상청 발표 시각 반환"""
    base_hours = [2, 5, 8, 11, 14, 17, 20, 23]
    current_hour = now.hour
    # 발표 후 10분 여유
    valid_hours = [h for h in base_hours if h * 60 + 10 <= current_hour * 60 + now.minute]
    if valid_hours:
        base_hour = valid_hours[-1]
        base_date = now.strftime("%Y%m%d")
    else:
        # 전날 23시 발표
        base_hour = 23
        base_date = (now - timedelta(days=1)).strftime("%Y%m%d")
    return base_date, f"{base_hour:02d}00"


# ── Mock 데이터 생성 ──────────────────────────────────────────────
def _make_mock_forecast(base_date: str, hours: int = 72) -> list[dict]:
    """더미 시간대별 예보 데이터 생성"""
    now = datetime.strptime(base_date, "%Y%m%d")
    forecasts = []
    for h in range(0, hours, 3):
        dt = now + timedelta(hours=h)
        rain_prob = random.choice([0, 10, 20, 30, 40, 60, 80])
        forecasts.append({
            "date": dt.strftime("%Y%m%d"),
            "time": dt.strftime("%H%M"),
            "temp": round(random.uniform(10, 28), 1),
            "wind_speed": round(random.uniform(0.5, 14), 1),
            "wind_dir": random.randint(0, 359),
            "rain_prob": rain_prob,
            "rain_type": 1 if rain_prob >= 60 else 0,  # 0=없음, 1=비
            "sky": random.choice([1, 3, 4]),             # 1=맑음, 3=구름많음, 4=흐림
            "lightning": 1 if rain_prob >= 70 and random.random() > 0.7 else 0,
            "humidity": random.randint(40, 90),
        })
    return forecasts


# ── 기상청 단기예보 실제 호출 ─────────────────────────────────────
async def _fetch_kma_forecast(
    nx: int, ny: int, api_key: str, client: httpx.AsyncClient
) -> list[dict]:
    now = datetime.now()
    base_date, base_time = _latest_base_time(now)

    url = "http://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst"
    params = {
        "serviceKey": api_key,
        "pageNo": 1, "numOfRows": 1000,
        "dataType": "JSON",
        "base_date": base_date,
        "base_time": base_time,
        "nx": nx, "ny": ny,
    }
    resp = await client.get(url, params=params, timeout=10.0)
    resp.raise_for_status()
    items = resp.json()["response"]["body"]["items"]["item"]

    timeline: dict[str, dict] = {}
    cat_map = {
        "TMP": "temp", "WSD": "wind_speed", "VEC": "wind_dir",
        "POP": "rain_prob", "PTY": "rain_type", "SKY": "sky",
        "LGT": "lightning", "REH": "humidity",
    }
    for item in items:
        key = f"{item['fcstDate']}_{item['fcstTime']}"
        if key not in timeline:
            timeline[key] = {"date": item["fcstDate"], "time": item["fcstTime"]}
        if item["category"] in cat_map:
            try:
                timeline[key][cat_map[item["category"]]] = float(item["fcstValue"])
            except ValueError:
                timeline[key][cat_map[item["category"]]] = item["fcstValue"]

    return sorted(timeline.values(), key=lambda x: x["date"] + x["time"])


# ── Open-Meteo 보조 예보 (1시간 단위) ────────────────────────────
async def _fetch_open_meteo(
    lat: float, lon: float, client: httpx.AsyncClient
) -> list[dict]:
    url = "https://api.open-meteo.com/v1/forecast"
    params = {
        "latitude": lat, "longitude": lon,
        "hourly": "temperature_2m,precipitation_probability,windspeed_10m,weathercode",
        "timezone": "Asia/Seoul",
        "forecast_days": 7,
    }
    resp = await client.get(url, params=params, timeout=10.0)
    resp.raise_for_status()
    data = resp.json()["hourly"]

    return [
        {
            "datetime": data["time"][i],
            "temp": data["temperature_2m"][i],
            "wind_speed": data["windspeed_10m"][i],
            "rain_prob": data["precipitation_probability"][i],
            "weather_code": data["weathercode"][i],
        }
        for i in range(len(data["time"]))
    ]


# ── Redis 캐시 적재 ───────────────────────────────────────────────
async def _cache_weather(
    r: aioredis.Redis,
    grid_x: int,
    grid_y: int,
    kma_data: list[dict],
    open_meteo_data: list[dict],
    source: str,
    ttl: int,
) -> None:
    cache_key = f"weather:grid:{grid_x}:{grid_y}"
    payload = {
        "updated_at": datetime.now().isoformat(),
        "source": source,
        "kma_forecast": kma_data,
        "open_meteo_hourly": open_meteo_data,
    }
    await r.setex(cache_key, ttl, json.dumps(payload, ensure_ascii=False))


# ── 단일 코스 수집 ────────────────────────────────────────────────
async def collect_course_weather(
    course: dict[str, Any],
    r: aioredis.Redis,
    client: httpx.AsyncClient,
    api_key: str,
    use_mock: bool,
    ttl: int,
) -> bool:
    grid_x, grid_y = course["grid_x"], course["grid_y"]
    cache_key = f"weather:grid:{grid_x}:{grid_y}"

    try:
        if use_mock:
            kma_data = _make_mock_forecast(datetime.now().strftime("%Y%m%d"))
            open_meteo_data = []
            source = "MOCK"
        else:
            kma_data = await _fetch_kma_forecast(grid_x, grid_y, api_key, client)
            open_meteo_data = await _fetch_open_meteo(course["lat"], course["lon"], client)
            source = "KMA+OPEN_METEO"

        await _cache_weather(r, grid_x, grid_y, kma_data, open_meteo_data, source, ttl)
        return True

    except Exception as e:
        # Fall-back: 기존 캐시 TTL 1시간 연장
        existing = await r.get(cache_key)
        if existing:
            await r.expire(cache_key, 3600)
        print(f"[WARN] {course['course_id']} 수집 실패 (기존 캐시 유지): {e}")
        return False


# ── 전체 골프장 수집 실행 ─────────────────────────────────────────
async def run_golf_collection() -> dict[str, int]:
    use_mock = os.getenv("USE_MOCK_DATA", "true").lower() == "true"
    api_key = os.getenv("KMA_API_KEY", "")
    redis_url = os.getenv("REDIS_URL", "redis://localhost:6379/0")
    ttl = int(os.getenv("WEATHER_CACHE_TTL", "10800"))

    data_path = os.path.join(os.path.dirname(__file__), "..", "data", "golf_courses.json")
    with open(data_path, encoding="utf-8") as f:
        courses = json.load(f)

    r = aioredis.from_url(redis_url, decode_responses=True)

    success, fail = 0, 0
    async with httpx.AsyncClient() as client:
        # 격자 중복 제거 (같은 격자 코스는 1번만 호출)
        seen_grids: set[tuple[int, int]] = set()
        for course in courses:
            grid_key = (course["grid_x"], course["grid_y"])
            if grid_key in seen_grids:
                success += 1
                continue
            seen_grids.add(grid_key)

            ok = await collect_course_weather(course, r, client, api_key, use_mock, ttl)
            if ok:
                success += 1
            else:
                fail += 1
            # API Rate Limit 방지
            if not use_mock:
                await asyncio.sleep(0.3)

    await r.aclose()
    print(f"[골프 수집 완료] 성공: {success}, 실패: {fail}, 총: {len(courses)}")
    return {"success": success, "fail": fail, "total": len(courses)}


if __name__ == "__main__":
    asyncio.run(run_golf_collection())
