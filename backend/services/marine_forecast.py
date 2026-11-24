"""KMA port-grid forecasts. Missing sea-grid values must remain missing."""

import math
import json
from datetime import datetime, timedelta, timezone

from services.kma_api import KmaApiError, fetch_items
from workers.weather_collector import _latest_base_time, wgs84_to_grid

KST = timezone(timedelta(hours=9))
FIELDS = {
    "WSD": ("wind_speed", 0, 100),
    "VEC": ("wind_direction", 0, 360),
    "WAV": ("wave_height", 0, 50),
    "TMP": ("temperature", -80, 60),
    "POP": ("rain_probability", 0, 100),
}


def parse_forecast(items: list[dict], now: datetime) -> list[dict]:
    start = now.astimezone(KST).replace(minute=0, second=0, microsecond=0)
    end = start + timedelta(hours=24)
    rows = {}
    for item in items:
        field = FIELDS.get(item.get("category"))
        if not field:
            continue
        try:
            at = datetime.strptime(item["fcstDate"] + item["fcstTime"], "%Y%m%d%H%M").replace(tzinfo=KST)
            value = float(item["fcstValue"])
        except (KeyError, ValueError, TypeError):
            continue
        name, lower, upper = field
        if not start <= at < end or not math.isfinite(value) or not lower <= value <= upper:
            continue
        rows.setdefault(at, {"datetime": at.isoformat()})[name] = value
    return [rows[at] for at in sorted(rows)]


async def fetch_port_forecast(spot: dict, api_key: str, client, *, now=None, cache=None) -> dict:
    now = now or datetime.now(KST)
    nx, ny = wgs84_to_grid(float(spot["lat"]), float(spot["lon"]))
    # Use an issuance at least an hour old to avoid requesting unpublished data.
    base_date, base_time = _latest_base_time(now.astimezone(KST) - timedelta(minutes=50))
    cache_key = f"marine:kma-grid:v1:{nx}:{ny}:{base_date}:{base_time}"
    quota_key = "marine:kma-grid:quota-cooldown"
    cached = await cache.get(cache_key) if cache is not None else None
    items = None
    if isinstance(cached, (str, bytes)):
        try:
            items = json.loads(cached)
        except (ValueError, TypeError):
            pass
    if not isinstance(items, list) or not items:
        if cache is not None and await cache.get(quota_key) in ("limited", b"limited"):
            raise KmaApiError("Port forecast quota cooldown is active")
        try:
            items = await fetch_items(client, "VilageFcstInfoService_2.0/getVilageFcst", api_key, {
                "pageNo": 1, "numOfRows": 1000, "dataType": "JSON",
                "base_date": base_date, "base_time": base_time, "nx": nx, "ny": ny,
            })
        except KmaApiError as exc:
            if cache is not None and ("429" in str(exc) or "LIMITED_NUMBER_OF_SERVICE_REQUESTS" in str(exc)):
                local = now.astimezone(KST)
                midnight = (local + timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)
                cooldown = int((midnight - local).total_seconds()) if "LIMITED_NUMBER_OF_SERVICE_REQUESTS" in str(exc) else 900
                await cache.setex(quota_key, max(1, cooldown), "limited")
            raise
        if items and cache is not None:
            await cache.setex(cache_key, 21600, json.dumps(items, ensure_ascii=False))
    rows = parse_forecast(items, now)
    if not rows:
        raise KmaApiError("No usable port-grid forecast values")
    hour = now.astimezone(KST).replace(minute=0, second=0, microsecond=0).isoformat()
    return {
        "current": next((r for r in rows if r["datetime"] == hour), {}),
        "hourly_forecast": rows,
        "forecast_status": "available",
        "forecast_reference": {
            "provider": "KMA", "kind": "forecast", "relation": "port_grid",
            "grid_x": nx, "grid_y": ny,
            "issued_at": datetime.strptime(base_date + base_time, "%Y%m%d%H%M").replace(tzinfo=KST).isoformat(),
            "collected_at": now.isoformat(),
        },
    }
