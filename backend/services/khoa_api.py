"""KHOA high/low tide forecasts via data.go.kr (dataset 15156018)."""

import math
from datetime import datetime

import httpx


TIDE_URL = "https://apis.data.go.kr/1192136/tideFcstHghLw/GetTideFcstHghLwApiService"


class KhoaApiError(RuntimeError):
    """Safe to log: never contains request URLs or upstream response text."""


async def fetch_tides(
    client: httpx.AsyncClient, obs_code: str, api_key: str, date: str
) -> list[dict]:
    if not api_key.strip():
        raise KhoaApiError("KHOA_API_KEY is missing")
    try:
        response = await client.get(
            TIDE_URL,
            params={
                "serviceKey": api_key.strip(),
                "obsCode": obs_code,
                "reqDate": date,
                "type": "json",
                "pageNo": 1,
                "numOfRows": 300,
            },
            timeout=15.0,
            follow_redirects=False,
        )
    except httpx.HTTPError as exc:
        raise KhoaApiError(f"KHOA connection failed: {type(exc).__name__}") from None
    if response.status_code != 200:
        raise KhoaApiError(f"KHOA HTTP {response.status_code}")
    try:
        payload = response.json()
    except ValueError:
        raise KhoaApiError("KHOA returned non-JSON data") from None
    return parse_tides(payload, date)


def parse_tides(payload: object, date: str) -> list[dict]:
    # The portal schema describes header/body; some serializers wrap in response.
    if not isinstance(payload, dict):
        raise KhoaApiError("KHOA invalid response schema")
    response = payload.get("response", payload)
    if not isinstance(response, dict) or not isinstance(response.get("header"), dict):
        raise KhoaApiError("KHOA missing response header")
    code = str(response["header"].get("resultCode", ""))
    if code not in ("00", "0"):
        # Only emit numeric codes, never provider messages that may echo a key.
        safe_code = code if code.isascii() and code.isdigit() and len(code) <= 3 else "unknown"
        raise KhoaApiError(f"KHOA result code {safe_code}")
    body = response.get("body")
    items = body.get("items") if isinstance(body, dict) else None
    rows = items.get("item") if isinstance(items, dict) else None
    if isinstance(rows, dict):
        rows = [rows]
    if not isinstance(rows, list) or not rows:
        raise KhoaApiError("KHOA forecast unavailable")

    tides = []
    for row in rows:
        try:
            predicted = datetime.fromisoformat(row["predcDt"])
            kind = str(row["extrSe"])
            height_cm = float(row["predcTdlvVl"])
            if (predicted.strftime("%Y%m%d") != date
                    or kind not in ("1", "2", "3", "4")
                    or not math.isfinite(height_cm)):
                raise ValueError
        except (KeyError, TypeError, ValueError, OverflowError):
            raise KhoaApiError("KHOA invalid tide record") from None
        tides.append({
            "time": predicted.strftime("%H:%M"),
            # The upstream unit is cm; the app's tide height is in metres.
            "height": height_cm / 100,
            "type": "만조" if kind in ("1", "3") else "간조",
        })
    return sorted(tides, key=lambda tide: tide["time"])
