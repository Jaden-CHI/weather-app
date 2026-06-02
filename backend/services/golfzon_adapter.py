"""
골프존 API 연동 어댑터 (향후 제휴 대비 인터페이스 설계)

현재 상태: golfzon_linked=False 코스는 폴백 처리
제휴 후:   골프존에서 발급한 API 키를 GOLFZON_API_KEY 환경변수에 설정

골프존 측에 제안할 API 기능:
  1. GET  /courses/{golfzon_id}/policy     — 코스별 취소 정책 (실시간)
  2. POST /bookings/{booking_id}/cancel    — 날씨 취소 처리
  3. GET  /courses/{golfzon_id}/available  — 특정 날짜 잔여 티타임
  4. GET  /screen-golf/nearby              — 인근 스크린골프 추천
"""

import os
from dataclasses import dataclass
from typing import Any


@dataclass
class GolfzonPolicy:
    golfzon_id: str
    course_name: str
    free_cancel_hours: int
    same_day_penalty: str
    noshow_penalty: str
    rain_cancel_available: bool
    rain_cancel_condition: str
    rain_refund_rule: str
    source: str  # "GOLFZON_API" | "FALLBACK"


@dataclass
class GolfzonCancelResult:
    success: bool
    booking_id: str
    refund_amount: int
    message: str


class GolfzonAdapter:
    """
    골프존 API 클라이언트.
    API 키가 없거나 golfzon_linked=False면 폴백 데이터 반환.
    """

    def __init__(self):
        self._api_key = os.getenv("GOLFZON_API_KEY", "")
        self._base_url = os.getenv("GOLFZON_API_BASE_URL", "https://api.golfzon.com/v1")
        self._enabled = bool(self._api_key)

    @property
    def enabled(self) -> bool:
        return self._enabled

    async def get_cancellation_policy(
        self, golfzon_id: str, course_name: str
    ) -> GolfzonPolicy:
        """코스별 취소 정책 조회. API 미연동 시 기본 정책 반환."""
        if not self._enabled or not golfzon_id:
            return self._fallback_policy(golfzon_id, course_name)

        try:
            import httpx
            async with httpx.AsyncClient(timeout=5.0) as client:
                resp = await client.get(
                    f"{self._base_url}/courses/{golfzon_id}/policy",
                    headers={"Authorization": f"Bearer {self._api_key}"},
                )
                resp.raise_for_status()
                data = resp.json()
                return GolfzonPolicy(
                    golfzon_id=golfzon_id,
                    course_name=course_name,
                    free_cancel_hours=data["freeCancelHours"],
                    same_day_penalty=data["sameDayPenalty"],
                    noshow_penalty=data["noshowPenalty"],
                    rain_cancel_available=data.get("rainCancelAvailable", False),
                    rain_cancel_condition=data.get("rainCancelCondition", ""),
                    rain_refund_rule=data.get("rainRefundRule", ""),
                    source="GOLFZON_API",
                )
        except Exception as e:
            print(f"[GolfzonAdapter] 정책 조회 실패 ({golfzon_id}): {e}")
            return self._fallback_policy(golfzon_id, course_name)

    async def cancel_booking(
        self, booking_id: str, reason: str = "WEATHER"
    ) -> GolfzonCancelResult:
        """예약 취소 요청. API 미연동 시 수동 취소 안내 반환."""
        if not self._enabled:
            return GolfzonCancelResult(
                success=False,
                booking_id=booking_id,
                refund_amount=0,
                message="골프존 직접 취소 필요: golfzon.com → 예약 내역 → 취소",
            )

        try:
            import httpx
            async with httpx.AsyncClient(timeout=5.0) as client:
                resp = await client.post(
                    f"{self._base_url}/bookings/{booking_id}/cancel",
                    headers={"Authorization": f"Bearer {self._api_key}"},
                    json={"reason": reason, "requestedBy": "WEATHER_APP"},
                )
                resp.raise_for_status()
                data = resp.json()
                return GolfzonCancelResult(
                    success=True,
                    booking_id=booking_id,
                    refund_amount=data.get("refundAmount", 0),
                    message=data.get("message", "취소 완료"),
                )
        except Exception as e:
            return GolfzonCancelResult(
                success=False,
                booking_id=booking_id,
                refund_amount=0,
                message=f"취소 요청 실패 — 골프존 앱에서 직접 취소하세요: {e}",
            )

    async def get_nearby_screen_golf(
        self, lat: float, lon: float, radius_km: int = 10
    ) -> list[dict]:
        """날씨 취소 시 인근 스크린골프 추천 (제휴 후 활성화)"""
        if not self._enabled:
            return [
                {
                    "name": "가까운 골프존 파크",
                    "message": "골프존 제휴 후 인근 스크린골프 자동 추천이 활성화됩니다",
                    "search_url": "https://www.golfzon.com/park",
                }
            ]

        try:
            import httpx
            async with httpx.AsyncClient(timeout=5.0) as client:
                resp = await client.get(
                    f"{self._base_url}/screen-golf/nearby",
                    headers={"Authorization": f"Bearer {self._api_key}"},
                    params={"lat": lat, "lon": lon, "radius": radius_km},
                )
                resp.raise_for_status()
                return resp.json().get("results", [])
        except Exception:
            return []

    @staticmethod
    def _fallback_policy(golfzon_id: str, course_name: str) -> GolfzonPolicy:
        return GolfzonPolicy(
            golfzon_id=golfzon_id or "",
            course_name=course_name,
            free_cancel_hours=24,
            same_day_penalty="그린피 일부 또는 전액 청구 (CC별 상이 — 직접 확인 필요)",
            noshow_penalty="예약 제한 또는 위약금 (CC별 상이)",
            rain_cancel_available=False,
            rain_cancel_condition="골프장에 직접 문의하세요",
            rain_refund_rule="",
            source="FALLBACK",
        )


# 싱글턴
_adapter: GolfzonAdapter | None = None


def get_golfzon_adapter() -> GolfzonAdapter:
    global _adapter
    if _adapter is None:
        _adapter = GolfzonAdapter()
    return _adapter
