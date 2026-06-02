"""켜자마자 날씨 — FastAPI 메인 앱"""

import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.routers import golf, marine, devices, admin
from models.database import AsyncSessionLocal, seed_data

# CORS_ORIGINS 가 설정되면 그 목록만 허용, 없으면 개발용 와일드카드
_cors_raw = os.getenv("CORS_ORIGINS", "")
_cors_origins = [o.strip() for o in _cors_raw.split(",") if o.strip()] or ["*"]


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with AsyncSessionLocal() as session:
        await seed_data(session)
    yield


app = FastAPI(
    title="켜자마자 날씨 API",
    description="골프·낚시 특화 날씨 + 취소 권고 서비스",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins,
    allow_methods=["GET", "POST", "DELETE"],
    allow_headers=["Content-Type", "X-Admin-Token"],
)

app.include_router(golf.router)
app.include_router(marine.router)
app.include_router(devices.router)
app.include_router(admin.router)


@app.get("/health")
async def health():
    return {"status": "ok", "service": "weather-api"}


@app.get("/")
async def root():
    return {
        "message": "켜자마자 날씨 API",
        "docs": "/docs",
        "endpoints": {
            "golf_search": "/api/v1/golf/courses/search?q=용인",
            "golf_weather": "/api/v1/golf/courses/CC_001/weather?dday=1",
            "marine_search": "/api/v1/marine/spots/search?q=통영",
            "marine_weather": "/api/v1/marine/spots/FS_001/weather",
        },
    }
