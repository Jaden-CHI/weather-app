"""
해양 데이터 수집 워커
- 기상청 기상특보 (풍랑주의보/경보)
- 기상청 해양 예보 (파고, 풍속)
- KHOA 조석 예보 (물때)
USE_MOCK_DATA=true 에서는 더미 데이터 반환
"""

import asyncio
import json
import os
import random
from datetime import datetime, timedelta
from typing import Any

import httpx
import redis.asyncio as aioredis


# ── Mock: 해양 기상 ───────────────────────────────────────────────
def _mock_marine_weather(spot_id: str) -> dict:
    wave_h = round(random.uniform(0.3, 4.0), 1)
    wind_spd = round(random.uniform(1.0, 20.0), 1)
    has_warning = wind_spd >= 14.0 or wave_h >= 3.0

    hourly = []
    now = datetime.now().replace(minute=0, second=0, microsecond=0)
    for h in range(48):
        dt = now + timedelta(hours=h)
        w = round(random.uniform(0.3, 4.5), 1)
        hourly.append({
            "datetime": dt.isoformat(),
            "wave_height": w,
            "wind_speed": round(random.uniform(1.0, 22.0), 1),
            "visibility": random.choice([5, 10, 20]),
            "sea_temp": round(random.uniform(14.0, 26.0), 1),
        })

    return {
        "spot_id": spot_id,
        "current": {
            "wave_height": wave_h,
            "wind_speed": wind_spd,
            "sea_temp": round(random.uniform(14.0, 26.0), 1),
            "visibility": random.choice([5, 10, 20]),
        },
        "hourly_forecast": hourly,
        "warning": {
            "has_warning": has_warning,
            "departure_blocked": has_warning,
            "level": "경보" if wind_spd >= 21 else ("주의보" if has_warning else "없음"),
            "message": "풍랑주의보 발효 중 — 출항통제" if has_warning else "출항 가능",
        },
    }


# ── Mock: 조석 예보 ───────────────────────────────────────────────
def _mock_tide_forecast() -> list[dict]:
    now = datetime.now()
    base_hour = 4
    tides = []
    for i in range(4):
        dt = now.replace(hour=base_hour + i * 6, minute=random.randint(10, 55), second=0)
        tides.append({
            "time": dt.strftime("%H:%M"),
            "height": round(random.uniform(0.3, 3.5), 2),
            "type": "만조" if i % 2 == 0 else "간조",
        })
    return tides


# ── 기상청 기상특보 실제 호출 ─────────────────────────────────────
async def _fetch_weather_warning(
    region_code: str, api_key: str, client: httpx.AsyncClient
) -> dict:
    url = "http://apis.data.go.kr/1360000/WthrWrnInfoService/getWthrWrnMsg"
    params = {
        "serviceKey": api_key,
        "pageNo": 1, "numOfRows": 20,
        "dataType": "JSON",
        "stnId": region_code,
    }
    resp = await client.get(url, params=params, timeout=10.0)
    resp.raise_for_status()

    items = (
        resp.json()
        .get("response", {})
        .get("body", {})
        .get("items", {})
        .get("item", [])
    )
    if isinstance(items, dict):
        items = [items]

    active = [
        i for i in items
        if i.get("warnVar") in ["풍랑", "태풍", "안개"]
        and i.get("warnStress") in ["경보", "주의보"]
    ]
    departure_blocked = any(
        i["warnVar"] == "풍랑" and i["warnStress"] in ["경보", "주의보"]
        for i in active
    )
    return {
        "has_warning": bool(active),
        "departure_blocked": departure_blocked,
        "warnings": active,
        "level": active[0]["warnStress"] if active else "없음",
        "message": f"{active[0]['warnVar']}{active[0]['warnStress']} 발효" if active else "출항 가능",
    }


# ── KHOA 조석 예보 실제 호출 ─────────────────────────────────────
async def _fetch_tide_forecast(
    obs_code: str, api_key: str, client: httpx.AsyncClient
) -> list[dict]:
    url = "http://www.khoa.go.kr/api/oceangrid/tideObsPreTab/search.do"
    params = {
        "ServiceKey": api_key,
        "ObsCode": obs_code,
        "Date": datetime.now().strftime("%Y%m%d"),
        "ResultType": "json",
    }
    resp = await client.get(url, params=params, timeout=10.0)
    resp.raise_for_status()
    data = resp.json()["result"]["data"]

    tides = []
    for item in data:
        tides.append({
            "time": item["tph_time"][:5],
            "height": float(item["tph_level"]),
            "type": "만조" if item["hl_code"] == "H" else "간조",
        })
    return tides


# ── 입질 골든타임 계산 ────────────────────────────────────────────
def _calc_golden_time(tides: list[dict]) -> str:
    """만조 전후 1시간 = 최적 입질 타임"""
    for tide in tides:
        if tide["type"] == "만조":
            try:
                h, m = map(int, tide["time"].split(":"))
                dt = datetime.now().replace(hour=h, minute=m)
                start = (dt - timedelta(hours=1)).strftime("%H:%M")
                end = (dt + timedelta(hours=1)).strftime("%H:%M")
                return f"{start}~{end}"
            except Exception:
                pass
    return "정보 없음"


# ── 단일 출항지 수집 ──────────────────────────────────────────────
async def collect_spot_marine(
    spot: dict[str, Any],
    r: aioredis.Redis,
    client: httpx.AsyncClient,
    kma_key: str,
    khoa_key: str,
    use_mock: bool,
    ttl: int,
) -> bool:
    cache_key = f"marine:{spot['spot_id']}"
    try:
        if use_mock:
            marine = _mock_marine_weather(spot["spot_id"])
            tides = _mock_tide_forecast()
            source = "MOCK"
        else:
            # 기상특보 (지역 코드는 spot 데이터에 추가 예정)
            region_code = spot.get("kma_region_code", "108")
            marine_warning = await _fetch_weather_warning(region_code, kma_key, client)
            marine = {"spot_id": spot["spot_id"], "warning": marine_warning}

            # KHOA 조석
            tides = []
            if spot.get("khoa_obs_code"):
                tides = await _fetch_tide_forecast(spot["khoa_obs_code"], khoa_key, client)
            source = "KMA+KHOA"

        golden_time = _calc_golden_time(tides)
        payload = {
            "updated_at": datetime.now().isoformat(),
            "source": source,
            "marine": marine,
            "tides": tides,
            "golden_time": golden_time,
            "main_fish": spot.get("main_fish", []),
        }
        await r.setex(cache_key, ttl, json.dumps(payload, ensure_ascii=False))
        return True

    except Exception as e:
        existing = await r.get(cache_key)
        if existing:
            await r.expire(cache_key, 3600)
        print(f"[WARN] {spot['spot_id']} 해양 수집 실패: {e}")
        return False


# ── 전체 출항지 수집 실행 ─────────────────────────────────────────
async def run_marine_collection() -> dict[str, int]:
    use_mock = os.getenv("USE_MOCK_DATA", "true").lower() == "true"
    kma_key = os.getenv("KMA_API_KEY", "")
    khoa_key = os.getenv("KHOA_API_KEY", "")
    redis_url = os.getenv("REDIS_URL", "redis://localhost:6379/0")
    ttl = int(os.getenv("WEATHER_CACHE_TTL", "10800"))

    data_path = os.path.join(os.path.dirname(__file__), "..", "data", "fishing_spots.json")
    with open(data_path, encoding="utf-8") as f:
        spots = json.load(f)

    r = aioredis.from_url(redis_url, decode_responses=True)

    success, fail = 0, 0
    async with httpx.AsyncClient() as client:
        for spot in spots:
            ok = await collect_spot_marine(spot, r, client, kma_key, khoa_key, use_mock, ttl)
            if ok:
                success += 1
            else:
                fail += 1
            if not use_mock:
                await asyncio.sleep(0.3)

    await r.aclose()
    print(f"[해양 수집 완료] 성공: {success}, 실패: {fail}, 총: {len(spots)}")
    return {"success": success, "fail": fail, "total": len(spots)}


if __name__ == "__main__":
    asyncio.run(run_marine_collection())
