"""SQLAlchemy async 설정 + 리포지토리"""

import json
import math
import os
from typing import Any

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

def _normalize_database_url(url: str) -> str:
    """Railway/Render commonly expose postgresql:// URLs; SQLAlchemy async needs asyncpg."""
    if url.startswith("postgres://"):
        return url.replace("postgres://", "postgresql+asyncpg://", 1)
    if url.startswith("postgresql://"):
        return url.replace("postgresql://", "postgresql+asyncpg://", 1)
    return url


DATABASE_URL = _normalize_database_url(
    os.getenv("DATABASE_URL", "postgresql+asyncpg://weather:changeme@db:5432/weatherapp")
)

engine = create_async_engine(DATABASE_URL, echo=False, pool_pre_ping=True)
AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


async def get_db() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        yield session


async def init_schema(session: AsyncSession) -> None:
    schema_path = os.path.join(os.path.dirname(__file__), "..", "schema.sql")
    with open(schema_path, encoding="utf-8") as f:
        statements = [s.strip() for s in f.read().split(";") if s.strip()]
    for statement in statements:
        await session.execute(text(statement))
    await session.commit()


# ── 골프장 조회 ───────────────────────────────────────────────────
async def get_course(session: AsyncSession, course_id: str) -> dict | None:
    result = await session.execute(
        text("SELECT * FROM golf_courses WHERE course_id = :id"),
        {"id": course_id},
    )
    row = result.mappings().first()
    return dict(row) if row else None


async def search_courses(session: AsyncSession, keyword: str) -> list[dict]:
    result = await session.execute(
        text("""
            SELECT * FROM golf_courses
            WHERE name ILIKE :kw OR name_short ILIKE :kw OR address ILIKE :kw
            LIMIT 10
        """),
        {"kw": f"%{keyword}%"},
    )
    return [dict(r) for r in result.mappings().all()]


# ── 낚시 출항지 조회 ──────────────────────────────────────────────
async def get_fishing_spot(session: AsyncSession, spot_id: str) -> dict | None:
    result = await session.execute(
        text("SELECT * FROM fishing_spots WHERE spot_id = :id"),
        {"id": spot_id},
    )
    row = result.mappings().first()
    return dict(row) if row else None


async def search_fishing_spots(session: AsyncSession, keyword: str) -> list[dict]:
    result = await session.execute(
        text("""
            SELECT * FROM fishing_spots
            WHERE name ILIKE :kw OR region ILIKE :kw OR address ILIKE :kw
            LIMIT 10
        """),
        {"kw": f"%{keyword}%"},
    )
    return [dict(r) for r in result.mappings().all()]


# ── 취소 정책 조회 ────────────────────────────────────────────────
async def get_cancellation_policy(session: AsyncSession, course_id: str) -> dict | None:
    result = await session.execute(
        text("""
            SELECT * FROM course_cancellation_policies
            WHERE course_id = :id
            ORDER BY updated_at DESC
            LIMIT 1
        """),
        {"id": course_id},
    )
    row = result.mappings().first()
    return dict(row) if row else None


# ── DB 시드 적재 (앱 시작 시 1회) ────────────────────────────────
def _wgs84_to_grid(lat: float, lon: float) -> tuple[int, int]:
    """기상청 LCC 격자 변환 — seed 시 자동 계산"""
    RE, GRID = 6371.00877, 5.0
    SLAT1, SLAT2, OLON, OLAT = 30.0, 60.0, 126.0, 38.0
    XO, YO = 43, 136
    DEGRAD = math.pi / 180.0
    re = RE / GRID
    slat1, slat2 = SLAT1 * DEGRAD, SLAT2 * DEGRAD
    olon_r, olat_r = OLON * DEGRAD, OLAT * DEGRAD
    sn = math.log(math.cos(slat1) / math.cos(slat2)) / math.log(
        math.tan(math.pi * 0.25 + slat2 * 0.5) / math.tan(math.pi * 0.25 + slat1 * 0.5)
    )
    sf = (math.tan(math.pi * 0.25 + slat1 * 0.5) ** sn) * math.cos(slat1) / sn
    ro = re * sf / (math.tan(math.pi * 0.25 + olat_r * 0.5) ** sn)
    ra = re * sf / (math.tan(math.pi * 0.25 + lat * DEGRAD * 0.5) ** sn)
    theta = lon * DEGRAD - olon_r
    theta = max(min(theta, math.pi), -math.pi) * sn
    return int(ra * math.sin(theta) + XO + 0.5), int(ro - ra * math.cos(theta) + YO + 0.5)


async def seed_data(session: AsyncSession) -> None:
    base = os.path.join(os.path.dirname(__file__), "..", "data")

    # 골프장
    count = (await session.execute(text("SELECT COUNT(*) FROM golf_courses"))).scalar()
    if count == 0:
        with open(f"{base}/golf_courses.json", encoding="utf-8") as f:
            courses = json.load(f)
        for c in courses:
            # 위경도 기반 격자 좌표 자동 계산
            c["grid_x"], c["grid_y"] = _wgs84_to_grid(c["lat"], c["lon"])
            await session.execute(
                text("""
                    INSERT INTO golf_courses
                    (course_id, name, name_short, region, address, lat, lon, grid_x, grid_y, holes, phone, website)
                    VALUES (:course_id,:name,:name_short,:region,:address,:lat,:lon,:grid_x,:grid_y,:holes,:phone,:website)
                    ON CONFLICT (course_id) DO NOTHING
                """),
                {k: c.get(k) for k in ["course_id","name","name_short","region","address","lat","lon","grid_x","grid_y","holes","phone","website"]},
            )
        await session.commit()
        print(f"[DB] 골프장 {len(courses)}개 시드 완료")

    # 낚시 출항지
    count = (await session.execute(text("SELECT COUNT(*) FROM fishing_spots"))).scalar()
    if count == 0:
        with open(f"{base}/fishing_spots.json", encoding="utf-8") as f:
            spots = json.load(f)
        for s in spots:
            s["grid_x"], s["grid_y"] = _wgs84_to_grid(s["lat"], s["lon"])
            await session.execute(
                text("""
                    INSERT INTO fishing_spots
                    (spot_id, name, name_short, region, sea_type, address, lat, lon, grid_x, grid_y, khoa_obs_code, buoy_id, main_fish)
                    VALUES (:spot_id,:name,:name_short,:region,:sea_type,:address,:lat,:lon,:grid_x,:grid_y,:khoa_obs_code,:buoy_id,:main_fish)
                    ON CONFLICT (spot_id) DO NOTHING
                """),
                {**{k: s.get(k) for k in ["spot_id","name","name_short","region","sea_type","address","lat","lon","grid_x","grid_y","khoa_obs_code","buoy_id"]},
                 "main_fish": s.get("main_fish", [])},
            )
        await session.commit()
        print(f"[DB] 낚시 출항지 {len(spots)}개 시드 완료")
