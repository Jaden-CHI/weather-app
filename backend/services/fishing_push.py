"""Fishing-only Firebase identity and delivery. Never reuse the Golf Firebase app."""
import asyncio
import json
import os
from datetime import timedelta
from functools import lru_cache

import firebase_admin
from firebase_admin import auth, credentials, messaging
from fastapi import Header, HTTPException


@lru_cache(maxsize=1)
def fishing_app():
    project = os.getenv('FISHING_FIREBASE_PROJECT_ID', 'fishing-windy-moonyth')
    raw = os.getenv('FISHING_FIREBASE_SERVICE_ACCOUNT_JSON', '')
    if not raw:
        raise RuntimeError('Fishing push credentials not configured')
    info = json.loads(raw)
    if info.get('project_id') != project:
        raise RuntimeError('Fishing Firebase project mismatch')
    return firebase_admin.initialize_app(
        credentials.Certificate(info), {'projectId': project, 'httpTimeout': 10},
        name='fishing-trip-push',
    )


def enabled():
    return os.getenv('FISHING_TRIP_PUSH_ENABLED', '').lower() == 'true'


async def require_fishing_user(authorization: str = Header(default='')) -> str:
    if not authorization.startswith('Bearer ') or len(authorization) > 8192:
        raise HTTPException(401, '로그인이 필요합니다.')
    try:
        app = fishing_app()
    except Exception:
        raise HTTPException(503, '서버 알림 연결 준비 중입니다.') from None
    try:
        claims = await asyncio.to_thread(
            auth.verify_id_token, authorization[7:], app=app, check_revoked=True,
        )
        return claims['uid']
    except Exception:
        # Never expose JWTs, service credentials, or upstream exception text.
        raise HTTPException(401, '다시 로그인해 주세요.') from None


async def user_active(uid):
    try:
        user = await asyncio.to_thread(auth.get_user, uid, app=fishing_app())
        return not user.disabled
    except auth.UserNotFoundError:
        return False
    # A Firebase outage must retry, not remove a valid user's subscriptions.


async def deliver(token, event, ttl):
    message = messaging.Message(
        token=token,
        notification=messaging.Notification(title=event['title'], body=event['body']),
        data={'screen': 'trip_plans', 'event_id': str(event['event_id']),
              'plan_id': event['plan_id'], 'state': event['state']},
        android=messaging.AndroidConfig(
            priority='high', ttl=timedelta(seconds=ttl),
            notification=messaging.AndroidNotification(
                channel_id='trip_conditions_v1', icon='ic_trip_notification',
                tag=event['collapse_id'], sound='default',
            ),
        ),
        apns=messaging.APNSConfig(
            headers={'apns-push-type': 'alert', 'apns-priority': '10',
                     'apns-collapse-id': event['collapse_id'],
                     'apns-expiration': str(event['expires_epoch'])},
            payload=messaging.APNSPayload(messaging.Aps(sound='default')),
        ),
    )
    try:
        await asyncio.to_thread(messaging.send, message, app=fishing_app())
        return 'sent'
    except messaging.UnregisteredError:
        return 'invalid_token'
    except Exception:
        return 'retry'
