"""골프장 취소 정책 + 페널티 안내 서비스"""

from datetime import datetime, timedelta
from typing import Any


def get_penalty_advice(policy: dict, round_datetime: datetime) -> dict:
    """현재 시각 기준으로 무료 취소 가능 여부 + 카운트다운 반환"""
    if not policy:
        return {"available": False, "message": "취소 정책 정보 없음"}

    now = datetime.now()
    free_hours = policy.get("free_cancel_hours")

    if free_hours is None:
        return {
            "can_cancel_free": None,
            "policy_summary": policy.get("free_cancel_desc", "정책 정보를 확인하세요"),
            "same_day_penalty": policy.get("same_day_penalty", ""),
            "noshow_penalty": policy.get("noshow_penalty", ""),
            "rain_cancel": {
                "available": policy.get("rain_cancel_available", False),
                "condition": policy.get("rain_cancel_condition", ""),
                "refund_rule": policy.get("rain_refund_rule", ""),
            },
        }

    deadline = round_datetime - timedelta(hours=free_hours)
    time_left = deadline - now

    if time_left.total_seconds() > 0:
        hours_left = int(time_left.total_seconds() // 3600)
        mins_left = int((time_left.total_seconds() % 3600) // 60)
        urgency = "HIGH" if time_left.total_seconds() < 7200 else "NORMAL"
        result = {
            "can_cancel_free": True,
            "countdown": f"{hours_left}시간 {mins_left}분",
            "urgency": urgency,
            "message": f"무료 취소 가능 — {hours_left}시간 {mins_left}분 남음",
            "deadline_str": deadline.strftime("%m/%d %H:%M"),
        }
    else:
        result = {
            "can_cancel_free": False,
            "countdown": None,
            "urgency": "CRITICAL",
            "message": f"취소 마감 경과 — {policy.get('same_day_penalty', '위약금 발생')}",
            "deadline_str": deadline.strftime("%m/%d %H:%M"),
        }

    result.update({
        "same_day_penalty": policy.get("same_day_penalty", ""),
        "noshow_penalty": policy.get("noshow_penalty", ""),
        "rain_cancel": {
            "available": policy.get("rain_cancel_available", False),
            "condition": policy.get("rain_cancel_condition", ""),
            "refund_rule": policy.get("rain_refund_rule", ""),
        },
        "source_url": policy.get("source_url", ""),
    })
    return result


# ── 샘플 취소 정책 (DB에 실데이터 없을 때 폴백) ───────────────────
SAMPLE_POLICIES: dict[str, dict] = {
    "CC_001": {
        "free_cancel_hours": 24,
        "free_cancel_desc": "라운딩 전날 18:00까지 무료 취소",
        "same_day_penalty": "그린피 100% 청구",
        "noshow_penalty": "3개월 예약 정지",
        "rain_cancel_available": True,
        "rain_cancel_condition": "당일 오전 6시 기상청 강수 확인 후 취소 가능",
        "rain_refund_rule": "9홀 미만 완료 시 50% 환불, 이후 환불 없음",
        "source_url": "",
    },
    "DEFAULT": {
        "free_cancel_hours": 24,
        "free_cancel_desc": "라운딩 전날까지 무료 취소 (CC별 상이)",
        "same_day_penalty": "그린피 일부 또는 전액 청구 (CC별 상이)",
        "noshow_penalty": "예약 정지 또는 위약금 (CC별 상이)",
        "rain_cancel_available": False,
        "rain_cancel_condition": "",
        "rain_refund_rule": "",
        "source_url": "",
    },
}


def get_sample_policy(course_id: str) -> dict:
    return SAMPLE_POLICIES.get(course_id, SAMPLE_POLICIES["DEFAULT"])
