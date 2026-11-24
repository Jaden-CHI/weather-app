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
from datetime import datetime, timedelta, timezone
from typing import Any
from urllib.parse import quote, unquote

import httpx
import redis.asyncio as aioredis

from services.kma_api import KmaApiError, fetch_items
from services.khoa_api import KhoaApiError, TIDE_MAPPING_VERSION, fetch_tides
from services.marine_forecast import fetch_port_forecast


KST = timezone(timedelta(hours=9))


def _now_kst() -> datetime:
    """서버 시간대(UTC)와 무관한 한국 현재 시각 (기존 포맷 유지를 위해 naive)."""
    return datetime.now(KST).replace(tzinfo=None)


# ── Mock: 해양 기상 ───────────────────────────────────────────────
def _mock_marine_weather(spot_id: str) -> dict:
    wave_h = round(random.uniform(0.3, 4.0), 1)
    wind_spd = round(random.uniform(1.0, 20.0), 1)
    has_warning = wind_spd >= 14.0 or wave_h >= 3.0

    hourly = []
    now = _now_kst().replace(minute=0, second=0, microsecond=0)
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
    now = _now_kst()
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
    items = await fetch_items(
        client,
        "WthrWrnInfoService/getWthrWrnMsg",
        api_key,
        {
            "pageNo": 1, "numOfRows": 20,
            "dataType": "JSON",
            "stnId": region_code,
        },
        allow_empty=True,  # 발효 중인 특보가 없으면 NO_DATA
    )

    # Message bulletins (t1...t6) are not an active-warning list for this port.
    # Empty bulletins also cannot establish that the local sea area is safe.
    return {
        "status": "unverified", "has_warning": None, "departure_blocked": None,
        "warnings": [], "bulletin_count": len(items), "level": "확인 필요",
        "message": "해당 해역의 기상특보와 출항 통제를 공식 안내에서 확인하세요.",
    }


# ── KHOA 조석 예보 실제 호출 ─────────────────────────────────────
async def _fetch_tide_forecast(
    obs_code: str, api_key: str, client: httpx.AsyncClient,
    expected_station: str | None = None,
) -> list[dict]:
    return await fetch_tides(
        client, obs_code, api_key, _now_kst().strftime("%Y%m%d"), expected_station
    )


# ── 입질 골든타임 계산 ────────────────────────────────────────────
def _calc_golden_time(tides: list[dict]) -> str:
    """만조 전후 1시간 = 최적 입질 타임"""
    for tide in tides:
        if tide["type"] == "만조":
            try:
                h, m = map(int, tide["time"].split(":"))
                dt = _now_kst().replace(hour=h, minute=m)
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
        failures = []
        tide_status = "mock" if use_mock else "mapping_unverified"
        if use_mock:
            marine = _mock_marine_weather(spot["spot_id"])
            tides = _mock_tide_forecast()
            source = "MOCK"
        else:
            region_code = spot.get("kma_region_code", "108")
            marine = {"spot_id": spot["spot_id"], "current": {}, "hourly_forecast": [],
                      "forecast_status": "unavailable", "warning": {
                          "status": "unavailable", "has_warning": None,
                          "departure_blocked": None, "level": "확인 필요",
                          "message": "기상특보를 수신하지 못했습니다. 공식 안내를 확인하세요.",
                      }}
            providers = []
            try:
                marine.update(await fetch_port_forecast(spot, kma_key, client, cache=r))
                providers.append("KMA")
            except Exception as exc:
                failures.append(("forecast", exc))
            try:
                marine["warning"] = await _fetch_weather_warning(region_code, kma_key, client)
            except Exception as exc:
                failures.append(("warning", exc))
            tides = []
            if spot.get("khoa_obs_code"):
                tide_status = "unavailable"
                try:
                    if not spot.get("khoa_obs_name"):
                        raise KhoaApiError("KHOA station mapping is unverified")
                    tides = await _fetch_tide_forecast(
                        spot["khoa_obs_code"], khoa_key, client, spot["khoa_obs_name"]
                    )
                    if tides:
                        providers.append("KHOA")
                        tide_status = "available"
                except Exception as exc:
                    failures.append(("tides", exc))
            source = "+".join(providers) or "NONE"
            for component, exc in failures:
                # Only type names: upstream exceptions may contain credentials.
                print(f"[WARN] {spot['spot_id']} {component} 수집 실패: {type(exc).__name__}")

        golden_time = _calc_golden_time(tides)
        payload = {
            "updated_at": datetime.now(KST).isoformat(),
            "source": source,
            "marine": marine,
            "tides": tides,
            "tide_mapping_version": TIDE_MAPPING_VERSION,
            "tide_status": tide_status,
            "tide_station": {
                "code": spot["khoa_obs_code"], "name": spot["khoa_obs_name"],
                "relation": "regional_reference",
            } if not use_mock and tides else None,
            "golden_time": golden_time,
            "main_fish": spot.get("main_fish", []),
        }
        await r.setex(cache_key, ttl, json.dumps(payload, ensure_ascii=False))
        return use_mock or source != "NONE"

    except Exception as e:
        existing = await r.get(cache_key)
        if existing:
            await r.expire(cache_key, 3600)
        # Raw HTTP exception strings contain query credentials; only log safe types.
        detail = str(e) if isinstance(e, (KmaApiError, KhoaApiError)) else type(e).__name__
        for key in (kma_key, khoa_key):
            if key.strip():
                for value in (key.strip(), quote(key.strip(), safe=""), unquote(key.strip())):
                    detail = detail.replace(value, "[REDACTED]")
        print(f"[WARN] {spot['spot_id']} 해양 수집 실패: {detail}")
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
