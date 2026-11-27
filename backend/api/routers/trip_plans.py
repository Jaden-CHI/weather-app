"""Authenticated, per-installation snapshots. Fishing plans never enter Golf tables."""
import hashlib
import json
from datetime import datetime, timedelta, timezone
from typing import Literal
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field, model_validator
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from models.database import get_db
from services.fishing_push import require_fishing_user, enabled
from services.port_forecasts import PORTS

router = APIRouter(prefix='/api/v1/fishing/trip-alerts', tags=['fishing-trip-alerts'])
PORT_NAMES = {p['spot_id']: p['name'] for p in PORTS}


class Plan(BaseModel):
    model_config = ConfigDict(extra='forbid', allow_inf_nan=False)
    id: str = Field(pattern=r'^[a-zA-Z0-9_-]{1,80}$')
    portId: str
    startsAt: datetime
    endsAt: datetime
    maxWind: float | None = Field(default=None, ge=0, le=50)
    maxWave: float | None = Field(default=None, ge=0, le=20)

    @model_validator(mode='after')
    def valid_plan(self):
        if self.portId not in PORT_NAMES:
            raise ValueError('Unknown Korean port')
        for dt in (self.startsAt, self.endsAt):
            if dt.tzinfo is None or dt.astimezone(timezone.utc).minute or dt.second or dt.microsecond:
                raise ValueError('Timezone-aware whole hours required')
        if not timedelta(0) < self.endsAt - self.startsAt <= timedelta(hours=24):
            raise ValueError('Trip duration must be 1..24 hours')
        if self.maxWind is None and self.maxWave is None:
            raise ValueError('A personal limit is required')
        if self.endsAt > datetime.now(timezone.utc) + timedelta(days=367):
            raise ValueError('Trip is too far in the future')
        return self


class Snapshot(BaseModel):
    model_config = ConfigDict(extra='forbid')
    revision: int = Field(ge=1, le=9007199254740991)
    token: str = Field(min_length=20, max_length=4096)
    platform: Literal['ios', 'android']
    plans: list[Plan] = Field(max_length=30)

    @model_validator(mode='after')
    def unique_ids(self):
        if len({p.id for p in self.plans}) != len(self.plans):
            raise ValueError('Duplicate plan IDs')
        return self


async def lock_owner(db, uid):
    # Serializes account quota checks and competing device snapshots.
    await db.execute(text('SELECT pg_advisory_xact_lock(hashtextextended(:uid, 917))'), {'uid': uid})


@router.put('/installations/{installation_id}')
async def sync(installation_id: UUID, req: Snapshot,
               uid: str = Depends(require_fishing_user), db: AsyncSession = Depends(get_db)):
    if not enabled():
        raise HTTPException(503, '서버 알림 연결 준비 중입니다.')
    install = str(installation_id)
    await lock_owner(db, uid)
    existing = (await db.execute(text('''SELECT * FROM fishing_push_devices
        WHERE uid=:uid AND installation_id=:install FOR UPDATE'''), {'uid': uid, 'install': install})).mappings().first()
    digest = hashlib.sha256(json.dumps(req.model_dump(mode='json'), sort_keys=True).encode()).hexdigest()
    if existing and req.revision <= existing['revision']:
        if req.revision != existing['revision'] or digest != existing['payload_hash']:
            raise HTTPException(409, '이전 변경 요청입니다. 다시 동기화하세요.')
        return {'synced': True, 'revision': req.revision}
    if not existing:
        count = (await db.execute(text('SELECT COUNT(*) FROM fishing_push_devices WHERE uid=:uid'), {'uid': uid})).scalar()
        if count >= 5:
            raise HTTPException(409, '계정당 서버 알림 기기는 최대 5대입니다.')
    other = (await db.execute(text('''SELECT 1 FROM fishing_push_devices WHERE fcm_token=:token
        AND NOT (uid=:uid AND installation_id=:install)'''), {'token': req.token, 'uid': uid, 'install': install})).first()
    if other:
        raise HTTPException(409, '기기 알림 토큰을 갱신한 뒤 다시 연결하세요.')
    await db.execute(text('''INSERT INTO fishing_push_devices
        (uid, installation_id, fcm_token, platform, revision, payload_hash, active, expires_at)
        VALUES (:uid, :install, :token, :platform, :revision, :digest, TRUE, NOW()+INTERVAL '32 days')
        ON CONFLICT (uid, installation_id) DO UPDATE SET fcm_token=EXCLUDED.fcm_token,
        platform=EXCLUDED.platform, revision=EXCLUDED.revision, payload_hash=EXCLUDED.payload_hash,
        active=TRUE, expires_at=EXCLUDED.expires_at, updated_at=NOW()'''),
        {'uid': uid, 'install': install, 'token': req.token, 'platform': req.platform,
         'revision': req.revision, 'digest': digest})
    old = (await db.execute(text('SELECT plan_id, payload FROM fishing_trip_plans WHERE uid=:uid AND installation_id=:install'),
                           {'uid': uid, 'install': install})).mappings().all()
    previous = {r['plan_id']: r['payload'] for r in old}
    plans = {p.id: p.model_dump(mode='json') for p in req.plans if p.endsAt > datetime.now(timezone.utc)}
    for plan_id in previous.keys() - plans.keys():
        await db.execute(text('DELETE FROM fishing_trip_plans WHERE uid=:uid AND installation_id=:install AND plan_id=:id'),
                         {'uid': uid, 'install': install, 'id': plan_id})
    for plan_id, payload in plans.items():
        if previous.get(plan_id) == payload:
            continue
        args = {'uid': uid, 'install': install, 'id': plan_id, 'payload': json.dumps(payload), 'revision': req.revision}
        await db.execute(text('''INSERT INTO fishing_trip_plans (uid, installation_id, plan_id, payload, revision)
            VALUES (:uid,:install,:id,CAST(:payload AS jsonb),:revision)
            ON CONFLICT (uid,installation_id,plan_id) DO UPDATE SET payload=EXCLUDED.payload,
            revision=EXCLUDED.revision, last_state=NULL, checked_at=NULL'''), args)
        await db.execute(text('''DELETE FROM fishing_trip_events WHERE uid=:uid AND installation_id=:install
            AND plan_id=:id AND delivery!='sent' '''), args)
    await db.commit()
    return {'synced': True, 'revision': req.revision}


@router.get('/installations/{installation_id}')
async def status(installation_id: UUID, uid: str = Depends(require_fishing_user), db: AsyncSession = Depends(get_db)):
    args = {'uid': uid, 'install': str(installation_id)}
    device = (await db.execute(text('''SELECT active, revision, expires_at, updated_at
        FROM fishing_push_devices WHERE uid=:uid AND installation_id=:install'''), args)).mappings().first()
    plans = (await db.execute(text('''SELECT plan_id, last_state, checked_at FROM fishing_trip_plans
        WHERE uid=:uid AND installation_id=:install'''), args)).mappings().all()
    events = (await db.execute(text('''SELECT event_id, plan_id, title, body, state, created_at, delivery
        FROM fishing_trip_events WHERE uid=:uid AND installation_id=:install
        ORDER BY created_at DESC LIMIT 50'''), args)).mappings().all()
    return {'enabled': enabled(), 'device': dict(device) if device else None, 'plans': [dict(p) for p in plans], 'events': [dict(e) for e in events]}


@router.delete('/installations/{installation_id}')
async def disable(installation_id: UUID, uid: str = Depends(require_fishing_user), db: AsyncSession = Depends(get_db)):
    await lock_owner(db, uid)
    await db.execute(text('DELETE FROM fishing_push_devices WHERE uid=:uid AND installation_id=:install'),
                     {'uid': uid, 'install': str(installation_id)})
    await db.commit()
    return {'disabled': True}


@router.delete('/account')
async def delete_account(uid: str = Depends(require_fishing_user), db: AsyncSession = Depends(get_db)):
    await lock_owner(db, uid)
    await db.execute(text('DELETE FROM fishing_push_devices WHERE uid=:uid'), {'uid': uid})
    await db.commit()
    return {'deleted': True}
