"""
날씨 변화 감지 → 푸시 알림 발송 워커

실행 주기: 스케줄러가 1시간마다 호출
로직:
  1. 오늘 + 7일 이내의 활성 구독 목록 조회
  2. 각 구독의 날씨 캐시 읽기
  3. 직전 상태(last_status)와 비교 → 변화 있으면 알림
  4. 발송 이력 저장 + last_status 업데이트
"""

import asyncio
import json
import os
from datetime import date, timedelta

import redis.asyncio as aioredis
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from models.database import AsyncSessionLocal
from services.ai_advisor import _rule_based_golf, _rule_based_marine
from services.push_notifier import NotificationPayload, send_push


# ── 날씨 상태 판단 (캐시 데이터 기반) ─────────────────────────────
def _assess_golf_status(cache_data: dict, event_date: date) -> tuple[str, str, str]:
    """(status, title, body) 반환"""
    forecasts = cache_data.get("kma_forecast", [])
    target = event_date.strftime("%Y%m%d")
    day_fc = [f for f in forecasts if f.get("date") == target] or forecasts[:8]

    rec = _rule_based_golf(day_fc, (event_date - date.today()).days)
    return rec["status"], rec["message"], rec["detail"]


def _assess_marine_status(cache_data: dict) -> tuple[str, str, str]:
    marine = cache_data.get("marine", {})
    warning = marine.get("warning", {})
    rec = _rule_based_marine(marine, warning)
    return rec["status"], rec["message"], rec["detail"]


# ── 알림 발송 필요 여부 판단 ────────────────────────────────────
def _should_notify(old_status: str | None, new_status: str) -> bool:
    """
    상태가 악화됐거나, D-1(전날) 오후 6시 기준 정기 알림이면 발송
    GREEN→GREEN 유지: 발송 안 함
    GREEN→YELLOW, YELLOW→RED, GREEN→RED: 발송
    RED→GREEN: 호전 알림도 발송 (취소 철회 가능성)
    """
    if old_status == new_status and new_status == "GREEN":
        return False
    return old_status != new_status


# ── 구독별 알림 처리 ────────────────────────────────────────────
async def process_subscription(
    sub: dict,
    r: aioredis.Redis,
    session: AsyncSession,
) -> None:
    activity = sub["activity_type"]
    target_id = sub["target_id"]
    event_date = sub["event_date"]
    user_token = sub["user_token"]
    sub_id = sub["sub_id"]

    # 캐시 키 결정
    if activity == "GOLF":
        # 골프장 격자 좌표 조회
        row = (await session.execute(
            text("SELECT grid_x, grid_y, name FROM golf_courses WHERE course_id = :id"),
            {"id": target_id},
        )).mappings().first()
        if not row:
            return
        cache_key = f"weather:grid:{row['grid_x']}:{row['grid_y']}"
        location_name = row["name"]
    else:
        row = (await session.execute(
            text("SELECT name FROM fishing_spots WHERE spot_id = :id"),
            {"id": target_id},
        )).mappings().first()
        cache_key = f"marine:{target_id}"
        location_name = row["name"] if row else target_id

    cached = await r.get(cache_key)
    if not cached:
        return

    cache_data = json.loads(cached)
    dday = (event_date - date.today()).days

    # 상태 판단
    if activity == "GOLF":
        new_status, msg, detail = _assess_golf_status(cache_data, event_date)
    else:
        new_status, msg, detail = _assess_marine_status(cache_data)

    old_status = sub.get("last_status")

    if not _should_notify(old_status, new_status):
        return

    # FCM 토큰 조회
    device = (await session.execute(
        text("SELECT fcm_token FROM user_devices WHERE user_token = :t LIMIT 1"),
        {"t": user_token},
    )).mappings().first()
    if not device:
        return

    # 알림 제목/본문 구성
    dday_label = "D-Day" if dday == 0 else f"D-{dday}"
    title = f"{dday_label} | {location_name}"

    # 상태 변화 방향에 따른 본문
    if old_status in (None, "GREEN") and new_status == "RED":
        body = f"⚠️ 취소 권고 — {detail}"
    elif new_status == "GREEN" and old_status in ("YELLOW", "RED"):
        body = f"✅ 날씨 호전 — {msg}"
    else:
        body = detail

    payload = NotificationPayload(
        title=title,
        body=body,
        status=new_status,
        course_id=target_id if activity == "GOLF" else None,
        spot_id=target_id if activity == "MARINE" else None,
        dday=dday,
    )

    fcm_result = await send_push(device["fcm_token"], payload)

    # 이력 저장 + 상태 업데이트
    await session.execute(
        text("""
            INSERT INTO notification_log (user_token, sub_id, title, body, status, fcm_result)
            VALUES (:user_token, :sub_id, :title, :body, :status, :fcm_result)
        """),
        {
            "user_token": user_token, "sub_id": sub_id,
            "title": title, "body": body,
            "status": new_status, "fcm_result": fcm_result,
        },
    )
    await session.execute(
        text("""
            UPDATE user_subscriptions
            SET last_status = :status, last_notified = NOW()
            WHERE sub_id = :sub_id
        """),
        {"status": new_status, "sub_id": sub_id},
    )
    await session.commit()

    print(f"[알림] {user_token[:8]}… | {title} | {new_status} → FCM: {fcm_result}")


# ── 전체 구독 처리 실행 ─────────────────────────────────────────
async def run_notification_check() -> dict[str, int]:
    redis_url = os.getenv("REDIS_URL", "redis://localhost:6379/0")
    today = date.today()
    until = today + timedelta(days=7)

    r = aioredis.from_url(redis_url, decode_responses=True)
    processed = skipped = 0

    async with AsyncSessionLocal() as session:
        rows = (await session.execute(
            text("""
                SELECT s.*, d.fcm_token
                FROM user_subscriptions s
                JOIN user_devices d ON s.user_token = d.user_token
                WHERE s.active = TRUE
                  AND s.event_date BETWEEN :today AND :until
                ORDER BY s.event_date
            """),
            {"today": today, "until": until},
        )).mappings().all()

        for row in rows:
            try:
                await process_subscription(dict(row), r, session)
                processed += 1
            except Exception as e:
                print(f"[알림 워커] 구독 {row['sub_id']} 오류: {e}")
                skipped += 1

    await r.aclose()
    print(f"[알림 완료] 처리: {processed}, 건너뜀: {skipped}")
    return {"processed": processed, "skipped": skipped}


if __name__ == "__main__":
    asyncio.run(run_notification_check())
