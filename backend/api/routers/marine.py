"""배낚시 해양 날씨 + 출항 권고 API"""

import json
import os

import redis.asyncio as aioredis
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from models.database import get_db, get_fishing_spot, search_fishing_spots
from services.ai_advisor import get_marine_recommendation

router = APIRouter(prefix="/api/v1/marine", tags=["marine"])


def _get_redis() -> aioredis.Redis:
    return aioredis.from_url(os.getenv("REDIS_URL", "redis://redis:6379/0"), decode_responses=True)


@router.get("/spots/search")
async def search(
    q: str = Query(..., min_length=1),
    db: AsyncSession = Depends(get_db),
):
    spots = await search_fishing_spots(db, q)
    if not spots:
        raise HTTPException(404, f"'{q}' 검색 결과 없음")
    return {"results": spots, "count": len(spots)}


@router.get("/spots/{spot_id}")
async def get_spot_info(spot_id: str, db: AsyncSession = Depends(get_db)):
    spot = await get_fishing_spot(db, spot_id)
    if not spot:
        raise HTTPException(404, "출항지를 찾을 수 없습니다")
    return spot


@router.get("/spots/{spot_id}/weather")
async def get_spot_weather(spot_id: str, db: AsyncSession = Depends(get_db)):
    spot = await get_fishing_spot(db, spot_id)
    if not spot:
        raise HTTPException(404, "출항지를 찾을 수 없습니다")

    r = _get_redis()
    cache_key = f"marine:{spot_id}"
    cached = await r.get(cache_key)
    await r.aclose()

    if not cached:
        raise HTTPException(
            503,
            detail={
                "message": "해양 기상 데이터 수집 중입니다.",
                "hint": "docker-compose logs worker",
            },
        )

    data = json.loads(cached)
    marine = data.get("marine", {})
    tides = data.get("tides", [])
    golden_time = data.get("golden_time", "정보 없음")

    use_mock = os.getenv("USE_MOCK_DATA", "true").lower() == "true"
    recommendation = await get_marine_recommendation(
        spot["name"], marine, tides, golden_time, use_mock
    )

    return {
        "spot_id": spot_id,
        "spot_name": spot["name"],
        "region": spot["region"],
        "sea_type": spot["sea_type"],
        "main_fish": spot.get("main_fish", []),
        "last_updated": data.get("updated_at"),
        "source": data.get("source"),
        # 해양 기상
        "current_weather": marine.get("current", {}),
        "hourly_forecast": marine.get("hourly_forecast", [])[:24],
        "warning": marine.get("warning", {}),
        # 조석
        "tides": tides,
        "golden_time": golden_time,
        # AI 권고
        "ai_recommendation": recommendation,
        # 안전 안내 (고정 콘텐츠)
        "safety_guide": {
            "boarding_report": {
                "required": True,
                "title": "승선신고 (법적 의무)",
                "steps": [
                    "국가안전포털(안전Dream) 앱 → 승선신고",
                    "출항지 낚시어선 관리선착장에 신고",
                    "선장에게 직접 탑승자 명부 제출",
                ],
                "warning": "미신고 시 사고 발생 때 보험처리 불이익 발생",
            },
            "departure_blocked_message": "풍랑주의보 발효 시 해양경찰 출항통제가 자동 적용됩니다",
        },
    }
