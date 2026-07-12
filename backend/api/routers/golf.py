"""골프 날씨 + 취소 권고 API"""

import json
import os
from datetime import datetime, timedelta

import httpx
import redis.asyncio as aioredis
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from models.database import (
    get_cancellation_policy,
    get_course,
    get_db,
    search_courses,
)
from services.ai_advisor import get_golf_recommendation
from services.penalty_advisor import get_penalty_advice, get_sample_policy
from services.golfzon_adapter import get_golfzon_adapter

router = APIRouter(prefix="/api/v1/golf", tags=["golf"])


def _get_redis() -> aioredis.Redis:
    return aioredis.from_url(
        os.getenv("REDIS_URL", "redis://redis:6379/0"),
        decode_responses=True,
    )


def _filter_by_dday(forecasts: list[dict], dday: int) -> list[dict]:
    """D+dday 날짜 예보만 필터링"""
    target_date = (datetime.now() + timedelta(days=dday)).strftime("%Y%m%d")
    filtered = [f for f in forecasts if f.get("date") == target_date]
    return sorted(filtered, key=lambda f: f.get("time", "")) or forecasts[:24]


def _filter_by_round_window(
    forecasts: list[dict],
    start_hour: int | None,
    *,
    hours_before: int = 1,
    hours_after: int = 5,
) -> list[dict]:
    """라운드 시작 시간 전후 예보만 추천 판단에 사용한다."""
    if start_hour is None:
        return forecasts

    window_start = max(0, start_hour - hours_before)
    window_end = min(23, start_hour + hours_after)
    filtered = []
    for forecast in forecasts:
        time_value = str(forecast.get("time", ""))
        if len(time_value) < 2:
            continue
        try:
            hour = int(time_value[:2])
        except ValueError:
            continue
        if window_start <= hour <= window_end:
            filtered.append(forecast)

    return sorted(filtered, key=lambda f: f.get("time", "")) or forecasts


def _open_meteo_hourly_to_forecast(hourly_items: list[dict]) -> list[dict]:
    forecasts: list[dict] = []
    for item in hourly_items:
        try:
            dt = datetime.fromisoformat(str(item.get("datetime", "")))
        except ValueError:
            continue

        code = int(item.get("weather_code") or 1)
        rain_prob = int(item.get("rain_prob") or 0)
        forecasts.append(
            {
                "date": dt.strftime("%Y%m%d"),
                "time": dt.strftime("%H%M"),
                "temp": float(item.get("temp") or 0),
                "wind_speed": float(item.get("wind_speed") or 0),
                "rain_prob": rain_prob,
                "rain_type": 1 if rain_prob >= 50 else 0,
                "sky": _sky_from_weather_code(code),
                "lightning": 1 if code in {95, 96, 99} else 0,
                "weather_code": code,
            }
        )
    return forecasts


def _filter_open_meteo_hourly_by_dday(
    hourly_items: list[dict], dday: int
) -> list[dict]:
    return _filter_by_dday(_open_meteo_hourly_to_forecast(hourly_items), dday)


def _filter_raw_open_meteo_hourly_by_dday(
    hourly_items: list[dict], dday: int
) -> list[dict]:
    target_date = (datetime.now() + timedelta(days=dday)).date()
    filtered: list[dict] = []
    for item in hourly_items:
        try:
            dt = datetime.fromisoformat(str(item.get("datetime", "")))
        except ValueError:
            continue
        if dt.date() == target_date:
            filtered.append(item)
    return filtered or hourly_items[:24]


def _sky_from_weather_code(code: int) -> int:
    if code in {0, 1}:
        return 1
    if code in {2, 3, 45, 48}:
        return 3
    return 4


def _open_meteo_to_forecast(hourly: dict) -> list[dict]:
    times = hourly.get("time", [])
    temps = hourly.get("temperature_2m", [])
    rains = hourly.get("precipitation_probability", [])
    winds = hourly.get("windspeed_10m", [])
    codes = hourly.get("weathercode", [])

    forecasts: list[dict] = []
    for i, value in enumerate(times):
        try:
            dt = datetime.fromisoformat(value)
        except ValueError:
            continue
        code = int(codes[i] if i < len(codes) and codes[i] is not None else 1)
        rain_prob = int(rains[i] if i < len(rains) and rains[i] is not None else 0)
        forecasts.append(
            {
                "date": dt.strftime("%Y%m%d"),
                "time": dt.strftime("%H%M"),
                "temp": float(
                    temps[i] if i < len(temps) and temps[i] is not None else 0
                ),
                "wind_speed": float(
                    winds[i] if i < len(winds) and winds[i] is not None else 0
                ),
                "rain_prob": rain_prob,
                "rain_type": 1 if rain_prob >= 50 else 0,
                "sky": _sky_from_weather_code(code),
                "lightning": 1 if code in {95, 96, 99} else 0,
                "weather_code": code,
            }
        )
    return forecasts


def _mock_custom_forecast(dday: int) -> list[dict]:
    target = datetime.now() + timedelta(days=dday)
    forecasts = []
    for hour in range(6, 22, 3):
        dt = target.replace(hour=hour, minute=0, second=0, microsecond=0)
        rain_prob = 20 if hour < 15 else 30
        forecasts.append(
            {
                "date": dt.strftime("%Y%m%d"),
                "time": dt.strftime("%H%M"),
                "temp": 18 + (hour - 6) * 0.6,
                "wind_speed": 3.5 + (hour % 4),
                "rain_prob": rain_prob,
                "rain_type": 0,
                "sky": 3,
                "lightning": 0,
            }
        )
    return forecasts


async def _fetch_custom_open_meteo(
    lat: float,
    lon: float,
) -> tuple[list[dict], list[dict], str]:
    url = "https://api.open-meteo.com/v1/forecast"
    params = {
        "latitude": lat,
        "longitude": lon,
        "hourly": "temperature_2m,precipitation_probability,windspeed_10m,weathercode",
        "timezone": "Asia/Seoul",
        "forecast_days": 7,
    }
    async with httpx.AsyncClient() as client:
        resp = await client.get(url, params=params, timeout=10.0)
        resp.raise_for_status()
        hourly = resp.json().get("hourly", {})
    return (
        _open_meteo_to_forecast(hourly),
        [
            {
                "datetime": hourly.get("time", [])[i],
                "temp": hourly.get("temperature_2m", [])[i],
                "wind_speed": hourly.get("windspeed_10m", [])[i],
                "rain_prob": hourly.get("precipitation_probability", [])[i],
                "weather_code": hourly.get("weathercode", [])[i],
            }
            for i in range(len(hourly.get("time", [])))
        ],
        "OPEN_METEO",
    )


@router.get("/custom/weather")
async def get_custom_course_weather(
    lat: float = Query(..., ge=-90, le=90),
    lon: float = Query(..., ge=-180, le=180),
    name: str = Query("커스텀 골프장", min_length=1),
    dday: int = Query(0, ge=0, le=7, description="D+n일 예보 (0=오늘)"),
    start_hour: int | None = Query(
        None,
        ge=0,
        le=23,
        description="라운드 시작 시각 (0~23). 추천 판단 기준 시간",
    ),
):
    """DB에 없는 골프장도 좌표만 있으면 날씨 예보를 반환한다."""
    try:
        all_forecasts, open_meteo_hourly, source = await _fetch_custom_open_meteo(
            lat,
            lon,
        )
        forecasts = _filter_by_dday(all_forecasts, dday)
        open_meteo_hourly = _filter_raw_open_meteo_hourly_by_dday(
            open_meteo_hourly, dday
        )
    except Exception:
        forecasts = _mock_custom_forecast(dday)
        open_meteo_hourly = []
        source = "MOCK_CUSTOM"

    use_mock = os.getenv("USE_MOCK_DATA", "true").lower() == "true"
    recommendation_forecasts = _filter_by_round_window(forecasts, start_hour)
    recommendation = await get_golf_recommendation(
        name,
        recommendation_forecasts,
        dday,
        use_mock,
    )

    policy = get_sample_policy("DEFAULT")
    round_datetime = datetime.now() + timedelta(days=dday)
    penalty_advice = get_penalty_advice(policy, round_datetime)
    penalty_advice["policy_source"] = "CUSTOM"

    return {
        "course_id": "CUSTOM",
        "course_name": name,
        "region": "커스텀 위치",
        "golfzon_linked": False,
        "golfzon_booking_url": None,
        "dday": dday,
        "forecast_date": (datetime.now() + timedelta(days=dday)).strftime(
            "%Y-%m-%d"
        ),
        "last_updated": datetime.now().isoformat(),
        "source": source,
        "forecast": forecasts,
        "open_meteo_hourly": open_meteo_hourly[:24],
        "ai_recommendation": recommendation,
        "cancellation_policy": penalty_advice,
        "screen_golf_nearby": [],
    }


@router.get("/courses/search")
async def search(
    q: str = Query(..., min_length=1),
    db: AsyncSession = Depends(get_db),
):
    courses = await search_courses(db, q)
    if not courses:
        raise HTTPException(404, f"'{q}' 검색 결과 없음")
    return {"results": courses, "count": len(courses)}


@router.get("/courses/{course_id}")
async def get_course_info(course_id: str, db: AsyncSession = Depends(get_db)):
    course = await get_course(db, course_id)
    if not course:
        raise HTTPException(404, "골프장을 찾을 수 없습니다")
    return course


@router.get("/courses/{course_id}/weather/status")
async def get_course_weather_status(
    course_id: str,
    db: AsyncSession = Depends(get_db),
):
    """코스별 날씨 캐시 상태를 확인한다.

    앱/운영 QA에서 "DB에는 있는데 날씨가 안 뜨는" 상황을 빠르게 구분하기 위한
    가벼운 진단 엔드포인트다.
    """
    course = await get_course(db, course_id)
    if not course:
        raise HTTPException(404, "골프장을 찾을 수 없습니다")

    cache_key = f"weather:grid:{course['grid_x']}:{course['grid_y']}"
    cached = None
    redis_error = None
    r = _get_redis()
    try:
        cached = await r.get(cache_key)
    except Exception as exc:
        redis_error = str(exc)
    finally:
        await r.aclose()

    payload = {}
    if cached:
        try:
            payload = json.loads(cached)
        except json.JSONDecodeError:
            payload = {}

    return {
        "course_id": course_id,
        "course_name": course["name"],
        "grid_x": course["grid_x"],
        "grid_y": course["grid_y"],
        "cache_key": cache_key,
        "cached": bool(cached),
        "source": payload.get("source"),
        "last_updated": payload.get("updated_at"),
        "redis_error": redis_error,
    }


@router.get("/courses/{course_id}/weather")
async def get_course_weather(
    course_id: str,
    dday: int = Query(0, ge=0, le=7, description="D+n일 예보 (0=오늘)"),
    start_hour: int | None = Query(
        None,
        ge=0,
        le=23,
        description="라운드 시작 시각 (0~23). 추천 판단 기준 시간",
    ),
    db: AsyncSession = Depends(get_db),
):
    course = await get_course(db, course_id)
    if not course:
        raise HTTPException(404, "골프장을 찾을 수 없습니다")

    r = _get_redis()
    cache_key = f"weather:grid:{course['grid_x']}:{course['grid_y']}"
    cached = await r.get(cache_key)
    await r.aclose()

    if not cached:
        raise HTTPException(
            503,
            detail={
                "message": "기상 데이터 수집 중입니다. 잠시 후 다시 시도해주세요.",
                "hint": "워커가 실행 중인지 확인하세요: docker-compose logs worker",
            },
        )

    data = json.loads(cached)
    source = data.get("source")
    if (
        source == "MOCK"
        and course.get("lat") is not None
        and course.get("lon") is not None
    ):
        try:
            all_forecasts, live_open_meteo_hourly, live_source = (
                await _fetch_custom_open_meteo(course["lat"], course["lon"])
            )
            data["kma_forecast"] = []
            data["open_meteo_hourly"] = live_open_meteo_hourly
            source = live_source
            kma_forecasts = []
            hourly_forecasts = _filter_by_dday(all_forecasts, dday)
        except Exception:
            kma_forecasts = _filter_by_dday(data.get("kma_forecast", []), dday)
            hourly_forecasts = _filter_open_meteo_hourly_by_dday(
                data.get("open_meteo_hourly", []), dday
            )
    else:
        kma_forecasts = _filter_by_dday(data.get("kma_forecast", []), dday)
        hourly_forecasts = _filter_open_meteo_hourly_by_dday(
            data.get("open_meteo_hourly", []), dday
        )
    forecasts = hourly_forecasts or kma_forecasts

    use_mock = os.getenv("USE_MOCK_DATA", "true").lower() == "true"
    recommendation_forecasts = _filter_by_round_window(forecasts, start_hour)
    recommendation = await get_golf_recommendation(
        course["name"], recommendation_forecasts, dday, use_mock
    )

    # 취소 정책 — 골프존 제휴 코스는 실시간 조회, 아닌 코스는 DB/폴백
    golfzon = get_golfzon_adapter()
    golfzon_id = course.get("golfzon_id")
    golfzon_linked = course.get("golfzon_linked", False)

    if golfzon_linked and golfzon_id:
        gz_policy = await golfzon.get_cancellation_policy(golfzon_id, course["name"])
        policy = {
            "free_cancel_hours": gz_policy.free_cancel_hours,
            "same_day_penalty": gz_policy.same_day_penalty,
            "noshow_penalty": gz_policy.noshow_penalty,
            "rain_cancel_available": gz_policy.rain_cancel_available,
            "rain_cancel_condition": gz_policy.rain_cancel_condition,
            "rain_refund_rule": gz_policy.rain_refund_rule,
        }
        policy_source = gz_policy.source
    else:
        policy = await get_cancellation_policy(db, course_id) or get_sample_policy(course_id)
        policy_source = "DB" if await get_cancellation_policy(db, course_id) else "FALLBACK"

    round_datetime = datetime.now() + timedelta(days=dday)
    penalty_advice = get_penalty_advice(policy, round_datetime)
    penalty_advice["policy_source"] = policy_source

    # 날씨 취소 권고 시 스크린골프 추천
    screen_golf_suggestions = []
    if recommendation.get("status") == "RED" and golfzon_linked:
        screen_golf_suggestions = await golfzon.get_nearby_screen_golf(
            course["lat"], course["lon"]
        )

    return {
        "course_id": course_id,
        "course_name": course["name"],
        "region": course["region"],
        "golfzon_linked": golfzon_linked,
        "golfzon_booking_url": course.get("golfzon_url"),
        "dday": dday,
        "forecast_date": (datetime.now() + timedelta(days=dday)).strftime(
            "%Y-%m-%d"
        ),
        "last_updated": data.get("updated_at"),
        "source": source,
        "forecast": forecasts,
        "open_meteo_hourly": _filter_raw_open_meteo_hourly_by_dday(
            data.get("open_meteo_hourly", []), dday
        )[:24],
        "ai_recommendation": recommendation,
        "cancellation_policy": penalty_advice,
        "screen_golf_nearby": screen_golf_suggestions,
    }
