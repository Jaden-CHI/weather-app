"""켜자마자 날씨 — FastAPI 메인 앱"""

import html
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


@app.get("/map/course", response_class=HTMLResponse)
@app.get("/map/windy", response_class=HTMLResponse)
async def course_map(
    lat: float = Query(...),
    lng: float = Query(...),
    zoom: int = Query(15, ge=3, le=18),
    label: str = Query("골프장 위치"),
    restaurants: str | None = Query(None),
):
    """골프장 지도 WebView용 HTML.

    기본은 네이버 지도를 사용하고, 키가 없는 환경에서는 OSM 지도로 안전하게 대체한다.
    `/map/windy` 는 기존 앱과의 호환을 위해 유지한다.
    """
    client_id = os.getenv("NAVER_MAP_CLIENT_ID", "").strip()
    marker_label = (label or "골프장 위치")[:80]
    safe_label = json.dumps(marker_label)
    safe_label_html = json.dumps(html.escape(marker_label))
    restaurant_markers = _parse_restaurant_markers(restaurants)

    if not client_id:
        return HTMLResponse(_leaflet_map_html(lat, lng, zoom, safe_label))

    return HTMLResponse(_naver_map_html(
        lat=lat,
        lng=lng,
        zoom=zoom,
        client_id_attr=html.escape(client_id, quote=True),
        safe_label=safe_label,
        safe_label_html=safe_label_html,
        restaurant_markers_json=json.dumps(restaurant_markers, ensure_ascii=False),
    ))


def _parse_restaurant_markers(raw: str | None) -> list[dict[str, object]]:
    if not raw:
        return []
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError:
        return []

    if not isinstance(payload, list):
        return []

    markers: list[dict[str, object]] = []
    for item in payload[:6]:
        if not isinstance(item, dict):
            continue
        name = str(item.get("name") or "").strip()
        category = str(item.get("category") or "").strip()
        distance_km = item.get("distance_km")
        lat = item.get("lat")
        lng = item.get("lng")

        try:
            lat_value = float(lat)
            lng_value = float(lng)
        except (TypeError, ValueError):
            continue

        try:
            distance_value = round(float(distance_km), 1)
        except (TypeError, ValueError):
            distance_value = None

        if not name:
            continue

        markers.append({
            "name": name[:40],
            "category": category[:24],
            "distance_km": distance_value,
            "lat": lat_value,
            "lng": lng_value,
        })
    return markers


def _naver_map_html(
    *,
    lat: float,
    lng: float,
    zoom: int,
    client_id_attr: str,
    safe_label: str,
    safe_label_html: str,
    restaurant_markers_json: str,
) -> str:
    return f"""
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes">
  <script src="https://oapi.map.naver.com/openapi/v3/maps.js?ncpKeyId={client_id_attr}"></script>
  <style>
    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
    html, body, #map {{ width: 100%; height: 100%; background: #0E2A24; }}
    body {{ overflow: hidden; }}
    .map-panel {{
      position: absolute;
      left: 14px;
      top: 14px;
      z-index: 1400;
      display: flex;
      flex-direction: column;
      gap: 10px;
      pointer-events: none;
    }}
    .map-card {{
      display: inline-flex;
      gap: 4px;
      padding: 4px;
      border-radius: 16px;
      background: rgba(11, 45, 38, 0.92);
      border: 1px solid rgba(244, 251, 248, 0.14);
      box-shadow: 0 10px 20px rgba(0, 0, 0, 0.22);
      pointer-events: auto;
    }}
    .map-card--single {{
      padding: 0;
      overflow: hidden;
    }}
    .map-button {{
      appearance: none;
      border: 0;
      background: transparent;
      color: rgba(244, 251, 248, 0.78);
      padding: 9px 12px;
      border-radius: 12px;
      font: 700 12px -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      letter-spacing: 0;
      cursor: pointer;
      transition: background 120ms ease, color 120ms ease;
    }}
    .map-button--ghost {{
      border-radius: 0;
      width: 100%;
      text-align: left;
    }}
    .map-button.is-active {{
      background: #F7C948;
      color: #0B2D26;
    }}
    .map-button:not(.is-active):active {{
      background: rgba(244, 251, 248, 0.12);
    }}
    .course-marker {{
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 6px;
      transform: translate(-50%, -100%);
    }}
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
      padding: 6px 10px;
      border-radius: 14px;
      background: rgba(11, 45, 38, 0.92);
      color: #F4FBF8;
      border: 1px solid rgba(247, 201, 72, 0.75);
      font: 700 12px -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      box-shadow: 0 8px 18px rgba(0, 0, 0, 0.25);
      white-space: nowrap;
    }}
    .course-label {{
      max-width: 220px;
      overflow: hidden;
      text-overflow: ellipsis;
    }}
    .course-subtext {{
      margin-top: 3px;
      color: rgba(244, 251, 248, 0.62);
      font-size: 11px;
      font-weight: 600;
    }}
    .naver-control {{
      border-radius: 14px !important;
      overflow: hidden;
    }}
    .restaurant-pin {{
      width: 18px;
      height: 18px;
      border-radius: 50%;
      background: #2E7D6B;
      border: 3px solid #F4FBF8;
      box-shadow: 0 6px 14px rgba(0, 0, 0, 0.25);
    }}
    .restaurant-info {{
      min-width: 148px;
      max-width: 220px;
      padding: 10px 12px;
      border-radius: 14px;
      background: rgba(11, 45, 38, 0.96);
      color: #F4FBF8;
      border: 1px solid rgba(46, 125, 107, 0.75);
      font: 600 12px -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      line-height: 1.35;
    }}
    .restaurant-info strong {{
      display: block;
      font-size: 13px;
      font-weight: 800;
      margin-bottom: 3px;
    }}
    .restaurant-info span {{
      color: rgba(244, 251, 248, 0.72);
    }}
  </style>
</head>
<body>
  <div id="map"></div>
  <div class="map-panel" aria-label="map controls">
    <div class="map-card" role="tablist" aria-label="지도 유형">
      <button class="map-button is-active" data-map-type="NORMAL" type="button">일반</button>
      <button class="map-button" data-map-type="SATELLITE" type="button">위성</button>
      <button class="map-button" data-map-type="HYBRID" type="button">혼합</button>
    </div>
    <div class="map-card map-card--single">
      <button class="map-button map-button--ghost" id="recenterButton" type="button">
        골프장 다시 보기
      </button>
    </div>
  </div>
  <script>
    const position = new naver.maps.LatLng({lat}, {lng});
    const label = {safe_label};
    const labelHtml = {safe_label_html};
    const restaurants = {restaurant_markers_json};
    const map = new naver.maps.Map('map', {{
      center: position,
      zoom: {zoom},
      mapTypeControl: false,
      scaleControl: false,
      zoomControl: true,
      zoomControlOptions: {{
        position: naver.maps.Position.TOP_RIGHT
      }}
    }});

    new naver.maps.Circle({{
      map: map,
      center: position,
      radius: 240,
      strokeColor: '#F7C948',
      strokeOpacity: 0.65,
      strokeWeight: 2,
      fillColor: '#F7C948',
      fillOpacity: 0.12
    }});

    new naver.maps.Marker({{
      position: position,
      map: map,
      title: label,
      icon: {{
        content: `
          <div class="course-marker" aria-label="${{labelHtml}}">
            <div class="course-label">${{labelHtml}}</div>
            <div class="course-pin"></div>
          </div>
        `,
        anchor: new naver.maps.Point(14, 48)
      }}
    }});

    let openInfoWindow = null;

    function escapeHtml(value) {{
      return String(value ?? '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
    }}

    restaurants.forEach((item) => {{
      const markerPosition = new naver.maps.LatLng(item.lat, item.lng);
      const marker = new naver.maps.Marker({{
        position: markerPosition,
        map: map,
        title: item.name,
        icon: {{
          content: '<div class="restaurant-pin" aria-label="추천 맛집"></div>',
          anchor: new naver.maps.Point(9, 9)
        }}
      }});

      const categoryText = item.category ? escapeHtml(item.category) : '추천 맛집';
      const distanceText = typeof item.distance_km === 'number'
        ? ` · ${{
            item.distance_km.toFixed(1)
          }}km`
        : '';
      const infoWindow = new naver.maps.InfoWindow({{
        content: `
          <div class="restaurant-info">
            <strong>${{escapeHtml(item.name)}}</strong>
            <span>${{categoryText}}${{distanceText}}</span>
          </div>
        `,
        borderWidth: 0,
        backgroundColor: 'transparent',
        disableAnchor: true,
        pixelOffset: new naver.maps.Point(0, -6)
      }});

      naver.maps.Event.addListener(marker, 'click', () => {{
        if (openInfoWindow) {{
          openInfoWindow.close();
        }}
        infoWindow.open(map, marker);
        openInfoWindow = infoWindow;
      }});
    }});

    const buttons = Array.from(document.querySelectorAll('[data-map-type]'));
    const typeIds = naver.maps.MapTypeId;

    function setActiveType(typeName) {{
      const nextType = typeIds[typeName];
      if (!nextType) return;
      map.setMapTypeId(nextType);
      buttons.forEach((button) => {{
        button.classList.toggle(
          'is-active',
          button.dataset.mapType === typeName
        );
      }});
    }}

    buttons.forEach((button) => {{
      button.addEventListener('click', () => {{
        setActiveType(button.dataset.mapType || 'NORMAL');
      }});
    }});

    document
      .getElementById('recenterButton')
      .addEventListener('click', () => {{
        map.morph(position, {zoom});
      }});
  </script>
</body>
</html>
"""


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
