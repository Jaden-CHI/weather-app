"""
FCM HTTP v1 API 기반 푸시 알림 발송 서비스

Firebase 프로젝트 서비스 계정 JSON을 GCP Secret Manager 또는
GOOGLE_APPLICATION_CREDENTIALS 환경변수로 주입
"""

import json
import os
from dataclasses import dataclass
from datetime import datetime

import httpx
from google.auth.transport.requests import Request
from google.oauth2 import service_account


_FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging"
_credentials: service_account.Credentials | None = None


def _get_access_token() -> str:
    global _credentials
    cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "")
    cred_json = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON", "")

    if _credentials is None:
        if cred_json:
            info = json.loads(cred_json)
        elif cred_path and os.path.exists(cred_path):
            with open(cred_path) as f:
                info = json.load(f)
        else:
            raise RuntimeError("Firebase 서비스 계정 정보가 없습니다. FIREBASE_SERVICE_ACCOUNT_JSON 환경변수를 설정하세요.")

        _credentials = service_account.Credentials.from_service_account_info(
            info, scopes=[_FCM_SCOPE]
        )

    if not _credentials.valid:
        _credentials.refresh(Request())

    return _credentials.token


@dataclass
class NotificationPayload:
    title: str
    body: str
    status: str           # GREEN / YELLOW / RED
    course_id: str | None = None
    spot_id: str | None = None
    dday: int | None = None
    deep_link: str | None = None  # 앱 내 특정 화면으로 이동


async def send_push(fcm_token: str, payload: NotificationPayload) -> str:
    """
    단일 디바이스에 FCM 푸시 발송
    반환: "SUCCESS" | "FAILED" | "INVALID_TOKEN"
    """
    project_id = os.getenv("FIREBASE_PROJECT_ID", "")
    if not project_id:
        print("[FCM] FIREBASE_PROJECT_ID 미설정 — 발송 건너뜀")
        return "SKIPPED"

    url = f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"

    # 상태별 알림 색상 (Android)
    color_map = {"GREEN": "#4CAF50", "YELLOW": "#FFC107", "RED": "#F44336"}
    color = color_map.get(payload.status, "#9E9E9E")

    message = {
        "token": fcm_token,
        "notification": {
            "title": payload.title,
            "body": payload.body,
        },
        "android": {
            "notification": {
                "color": color,
                "sound": "default",
                "channel_id": "weather_alert",
                "priority": "HIGH" if payload.status == "RED" else "DEFAULT",
            },
            "data": _build_data(payload),
        },
        "apns": {
            "payload": {
                "aps": {
                    "alert": {"title": payload.title, "body": payload.body},
                    "sound": "default",
                    "badge": 1,
                }
            },
            "fcm_options": {"analytics_label": f"weather_{payload.status.lower()}"},
        },
        "data": _build_data(payload),
    }

    try:
        token = _get_access_token()
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post(
                url,
                json={"message": message},
                headers={
                    "Authorization": f"Bearer {token}",
                    "Content-Type": "application/json",
                },
            )

        if resp.status_code == 200:
            return "SUCCESS"
        elif resp.status_code == 404:
            return "INVALID_TOKEN"
        else:
            print(f"[FCM] 발송 실패 {resp.status_code}: {resp.text[:200]}")
            return "FAILED"

    except Exception as e:
        print(f"[FCM] 예외 발생: {e}")
        return "FAILED"


async def send_bulk(tokens: list[str], payload: NotificationPayload) -> dict[str, int]:
    """복수 디바이스 발송 (최대 500개 병렬)"""
    import asyncio

    results = await asyncio.gather(
        *[send_push(t, payload) for t in tokens], return_exceptions=True
    )
    summary = {"SUCCESS": 0, "FAILED": 0, "INVALID_TOKEN": 0, "SKIPPED": 0}
    for r in results:
        key = r if isinstance(r, str) else "FAILED"
        summary[key] = summary.get(key, 0) + 1
    return summary


def _build_data(payload: NotificationPayload) -> dict[str, str]:
    data: dict[str, str] = {"status": payload.status}
    if payload.course_id:
        data["course_id"] = payload.course_id
        data["screen"] = "golf_detail"
    if payload.spot_id:
        data["spot_id"] = payload.spot_id
        data["screen"] = "marine_detail"
    if payload.dday is not None:
        data["dday"] = str(payload.dday)
    if payload.deep_link:
        data["deep_link"] = payload.deep_link
    return data
