"""디바이스 FCM 토큰 등록 + 구독 관리 API"""

from datetime import date, timedelta
import re

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field, field_validator
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from models.database import get_db

router = APIRouter(prefix="/api/v1/devices", tags=["devices"])

_UUID_RE = re.compile(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')


# ── 요청 모델 ──────────────────────────────────────────────────
class DeviceRegisterRequest(BaseModel):
    user_token: str = Field(min_length=36, max_length=36)
    fcm_token: str = Field(min_length=10, max_length=512)
    platform: str = Field(max_length=10)
    app_version: str | None = Field(default=None, max_length=20)

    @field_validator("user_token")
    @classmethod
    def validate_user_token(cls, v: str) -> str:
        if not _UUID_RE.match(v.lower()):
            raise ValueError("user_token은 UUID v4 형식이어야 합니다")
        return v.lower()

    @field_validator("platform")
    @classmethod
    def validate_platform(cls, v: str) -> str:
        if v.upper() not in ("IOS", "ANDROID"):
            raise ValueError("platform은 IOS 또는 ANDROID여야 합니다")
        return v.upper()


class SubscribeRequest(BaseModel):
    user_token: str = Field(min_length=36, max_length=36)
    activity_type: str = Field(max_length=10)
    target_id: str = Field(min_length=1, max_length=50)
    event_date: date
    event_title: str | None = Field(default=None, max_length=100)
    rain_threshold: int = Field(default=60, ge=10, le=100)
    wind_threshold: float = Field(default=10.0, ge=1.0, le=50.0)

    @field_validator("activity_type")
    @classmethod
    def validate_activity(cls, v: str) -> str:
        if v.upper() not in ("GOLF", "MARINE"):
            raise ValueError("activity_type은 GOLF 또는 MARINE이어야 합니다")
        return v.upper()

    @field_validator("event_date")
    @classmethod
    def validate_date(cls, v: date) -> date:
        if v < date.today():
            raise ValueError("과거 날짜로는 구독할 수 없습니다")
        if v > date.today() + timedelta(days=30):
            raise ValueError("30일 이후 날짜는 구독할 수 없습니다")
        return v


# ── 디바이스 등록/갱신 ─────────────────────────────────────────
@router.post("/register")
async def register_device(
    req: DeviceRegisterRequest,
    db: AsyncSession = Depends(get_db),
):
    await db.execute(
        text("""
            INSERT INTO user_devices (user_token, fcm_token, platform, app_version, updated_at)
            VALUES (:user_token, :fcm_token, :platform, :app_version, NOW())
            ON CONFLICT (user_token)
            DO UPDATE SET
                fcm_token   = EXCLUDED.fcm_token,
                platform    = EXCLUDED.platform,
                app_version = EXCLUDED.app_version,
                updated_at  = NOW()
        """),
        {
            "user_token": req.user_token,
            "fcm_token": req.fcm_token,
            "platform": req.platform,
            "app_version": req.app_version,
        },
    )
    await db.commit()
    return {"success": True, "message": "디바이스 등록 완료"}


# ── 일정 구독 등록 ─────────────────────────────────────────────
@router.post("/subscribe")
async def subscribe(
    req: SubscribeRequest,
    db: AsyncSession = Depends(get_db),
):
    # 디바이스 존재 확인
    device = (await db.execute(
        text("SELECT device_id FROM user_devices WHERE user_token = :t"),
        {"t": req.user_token},
    )).first()
    if not device:
        raise HTTPException(404, "먼저 /devices/register로 디바이스를 등록하세요")

    # 동일 구독 중복 방지 (같은 유저 + 같은 타겟 + 같은 날짜)
    existing = (await db.execute(
        text("""
            SELECT sub_id FROM user_subscriptions
            WHERE user_token = :t AND target_id = :tid AND event_date = :dt AND active = TRUE
        """),
        {"t": req.user_token, "tid": req.target_id, "dt": req.event_date},
    )).first()

    if existing:
        return {"success": True, "sub_id": existing[0], "message": "이미 구독 중인 일정입니다"}

    result = await db.execute(
        text("""
            INSERT INTO user_subscriptions
            (user_token, activity_type, target_id, event_date, event_title,
             rain_threshold, wind_threshold)
            VALUES (:user_token, :activity_type, :target_id, :event_date, :event_title,
                    :rain_threshold, :wind_threshold)
            RETURNING sub_id
        """),
        {
            "user_token": req.user_token,
            "activity_type": req.activity_type,
            "target_id": req.target_id,
            "event_date": req.event_date,
            "event_title": req.event_title,
            "rain_threshold": req.rain_threshold,
            "wind_threshold": req.wind_threshold,
        },
    )
    sub_id = result.scalar()
    await db.commit()
    return {"success": True, "sub_id": sub_id, "message": "날씨 알림 구독 완료"}


# ── 구독 취소 ──────────────────────────────────────────────────
@router.delete("/subscribe/{sub_id}")
async def unsubscribe(
    sub_id: int,
    user_token: str,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        text("""
            UPDATE user_subscriptions SET active = FALSE
            WHERE sub_id = :sub_id AND user_token = :t
        """),
        {"sub_id": sub_id, "t": user_token},
    )
    await db.commit()
    if result.rowcount == 0:
        raise HTTPException(404, "구독을 찾을 수 없습니다")
    return {"success": True, "message": "구독이 취소됐습니다"}


# ── 내 구독 목록 ───────────────────────────────────────────────
@router.get("/subscriptions/{user_token}")
async def list_subscriptions(
    user_token: str,
    db: AsyncSession = Depends(get_db),
):
    rows = (await db.execute(
        text("""
            SELECT sub_id, activity_type, target_id, event_date,
                   event_title, last_status, last_notified
            FROM user_subscriptions
            WHERE user_token = :t AND active = TRUE AND event_date >= CURRENT_DATE
            ORDER BY event_date
        """),
        {"t": user_token},
    )).mappings().all()
    return {"subscriptions": [dict(r) for r in rows]}
