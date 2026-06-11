"""켜자마자 날씨 — FastAPI 메인 앱"""

import os
import json
from contextlib import asynccontextmanager

from fastapi import FastAPI, Query
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware

from api.routers import golf, marine, devices, admin
from models.database import AsyncSessionLocal, init_schema, seed_data

# CORS_ORIGINS 가 설정되면 그 목록만 허용, 없으면 개발용 와일드카드
_cors_raw = os.getenv("CORS_ORIGINS", "")
_cors_origins = [o.strip() for o in _cors_raw.split(",") if o.strip()] or ["*"]


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with AsyncSessionLocal() as session:
        await init_schema(session)
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


@app.get("/map/windy", response_class=HTMLResponse)
async def windy_map(
    lat: float = Query(...),
    lng: float = Query(...),
    zoom: int = Query(13, ge=3, le=18),
    label: str = Query("골프장 위치"),
):
    """Windy 지도 WebView용 HTML.

    모바일 앱 내부에서 Windy 키를 직접 쓰면 도메인 제한과 충돌할 수 있어,
    Railway 도메인에서 HTML을 제공하도록 둔다.
    """
    api_key = os.getenv("WINDY_API_KEY", "").strip()
    marker_label = (label or "골프장 위치")[:80]
    safe_label = json.dumps(marker_label)


    if not api_key:
        return HTMLResponse(_leaflet_map_html(lat, lng, zoom, safe_label))

    safe_key = json.dumps(api_key)
    return HTMLResponse(f"""
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes">
  <script src="https://unpkg.com/leaflet@1.4.0/dist/leaflet.js"></script>
  <script src="https://api.windy.com/assets/map-forecast/libBoot.js"></script>
  <style>
    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
    html, body, #windy {{ width: 100%; height: 100%; background: #0E2A24; }}
    .course-pin {{
      width: 28px;
      height: 28px;
      border-radius: 50% 50% 50% 0;
      transform: rotate(-45deg);
      background: #F7C948;
      border: 3px solid #0B2D26;
      box-shadow: 0 8px 18px rgba(0, 0, 0, 0.35);
    }}
    .course-pin::after {{
      content: '';
      position: absolute;
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #0B2D26;
      top: 7px;
      left: 7px;
    }}
    .course-label {{
      min-width: max-content;
      padding: 7px 10px;
      border-radius: 14px;
      background: rgba(11, 45, 38, 0.92);
      color: #F4FBF8;
      border: 1px solid rgba(247, 201, 72, 0.75);
      font: 700 13px -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      box-shadow: 0 8px 18px rgba(0, 0, 0, 0.25);
      white-space: nowrap;
    }}
    .course-target {{
      position: absolute;
      left: 50%;
      top: 50%;
      z-index: 1200;
      transform: translate(-50%, -100%);
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 8px;
      pointer-events: none;
    }}
    .course-target .course-label {{
      max-width: 220px;
      overflow: hidden;
      text-overflow: ellipsis;
    }}
    .leaflet-popup-content-wrapper, .leaflet-popup-tip {{
      background: #143630;
      color: #F4FBF8;
      border: 1px solid rgba(244, 251, 248, 0.16);
    }}
  </style>
</head>
<body>
  <div id="windy"></div>
  <div class="course-target" aria-label="selected golf course">
    <div class="course-label"></div>
    <div class="course-pin"></div>
  </div>
  <script>
    const options = {{
      key: {safe_key},
      lat: {lat},
      lon: {lng},
      zoom: {zoom},
      overlay: 'wind',
      level: 'surface',
      product: 'ecmwf',
      particlesAnim: 'on'
    }};
    windyInit(options, function(windyAPI) {{
      const map = windyAPI.map;
      const label = {safe_label};
      document.querySelector('.course-target .course-label').textContent = label;
      map.setView([{lat}, {lng}], {zoom});
    }});
  </script>
</body>
</html>
""")


def _leaflet_map_html(
    lat: float,
    lng: float,
    zoom: int,
    safe_label: str,
) -> str:
    return f"""
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes">
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <style>
    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
    html, body, #map {{ width: 100%; height: 100%; }}
    .course-pin {{
      width: 28px;
      height: 28px;
      border-radius: 50% 50% 50% 0;
      transform: rotate(-45deg);
      background: #F7C948;
      border: 3px solid #0B2D26;
      box-shadow: 0 8px 18px rgba(0, 0, 0, 0.35);
    }}
    .course-pin::after {{
      content: '';
      position: absolute;
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #0B2D26;
      top: 7px;
      left: 7px;
    }}
    .course-label {{
      min-width: max-content;
      padding: 7px 10px;
      border-radius: 14px;
      background: rgba(11, 45, 38, 0.92);
      color: #F4FBF8;
      border: 1px solid rgba(247, 201, 72, 0.75);
      font: 700 13px -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      box-shadow: 0 8px 18px rgba(0, 0, 0, 0.25);
      white-space: nowrap;
    }}
    .course-target {{
      position: absolute;
      left: 50%;
      top: 50%;
      z-index: 1200;
      transform: translate(-50%, -100%);
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 8px;
      pointer-events: none;
    }}
    .course-target .course-label {{
      max-width: 220px;
      overflow: hidden;
      text-overflow: ellipsis;
    }}
    .leaflet-popup-content-wrapper, .leaflet-popup-tip {{
      background: #143630;
      color: #F4FBF8;
      border: 1px solid rgba(244, 251, 248, 0.16);
    }}
  </style>
</head>
<body>
  <div id="map"></div>
  <div class="course-target" aria-label="selected golf course">
    <div class="course-label"></div>
    <div class="course-pin"></div>
  </div>
  <script>
    const map = L.map('map').setView([{lat}, {lng}], {zoom});
    L.tileLayer('https://tile.openstreetmap.org/{{z}}/{{x}}/{{y}}.png', {{
      maxZoom: 19,
      attribution: '&copy; OpenStreetMap'
    }}).addTo(map);
    const label = {safe_label};
    document.querySelector('.course-target .course-label').textContent = label;
  </script>
</body>
</html>
"""
