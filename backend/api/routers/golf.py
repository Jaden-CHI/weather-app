"""골프 날씨 + 취소 권고 API"""

import json
import os
from datetime import datetime, timedelta

import redis.asyncio as aioredis
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from models.database import get_db, get_course, get_cancellation_policy, search_courses
from services.ai_advisor import get_golf_recommendation
from services.penalty_advisor import get_penalty_advice, get_sample_policy
from services.golfzon_adapter import get_golfzon_adapter

router = APIRouter(prefix="/api/v1/golf", tags=["golf"])


def _get_redis() -> aioredis.Redis:
    return aioredis.from_url(os.getenv("REDIS_URL", "redis://redis:6379/0"), decode_responses=True)


def _filter_by_dday(forecasts: list[dict], dday: int) -> list[dict]:
    """D+dday 날짜 예보만 필터링"""
    target_date = (datetime.now() + timedelta(days=dday)).strftime("%Y%m%d")
    filtered = [f for f in forecasts if f.get("date") == target_date]
    return filtered or forecasts[:8]  # 없으면 처음 8개


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


@router.get("/courses/{course_id}/weather")
async def get_course_weather(
    course_id: str,
    dday: int = Query(0, ge=0, le=7, description="D+n일 예보 (0=오늘)"),
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
    forecasts = _filter_by_dday(data.get("kma_forecast", []), dday)

    use_mock = os.getenv("USE_MOCK_DATA", "true").lower() == "true"
    recommendation = await get_golf_recommendation(
        course["name"], forecasts, dday, use_mock
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
        "forecast_date": (datetime.now() + timedelta(days=dday)).strftime("%Y-%m-%d"),
        "last_updated": data.get("updated_at"),
        "source": data.get("source"),
        "forecast": forecasts,
        "open_meteo_hourly": data.get("open_meteo_hourly", [])[:24],
        "ai_recommendation": recommendation,
        "cancellation_policy": penalty_advice,
        "screen_golf_nearby": screen_golf_suggestions,
    }
