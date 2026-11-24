import asyncio
import json
from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock

import pytest

from services import marine_forecast as mf
from services.ai_advisor import get_marine_recommendation, _rule_based_marine
from services.kma_api import KmaApiError
from workers import marine_collector as mc

NOW = datetime(2026, 11, 24, 10, 30, tzinfo=mf.KST)
SPOT = {"spot_id": "FS_001", "lat": 34.854, "lon": 128.433,
        "grid_x": 74, "grid_y": 71, "khoa_obs_code": "DT_0014", "khoa_obs_name": "통영"}


def item(category, value, time="1000", date="20261124"):
    return {"category": category, "fcstValue": value, "fcstDate": date, "fcstTime": time}


def test_missing_sentinels_and_stale_forecasts_are_not_zero():
    rows = mf.parse_forecast([
        item("WSD", "3.1"), item("WAV", "-999"), item("VEC", "180"),
        item("TMP", "-2"), item("POP", "NaN"), item("WSD", "5", "0900"),
        item("WAV", "1.2", "1100"), item("WSD", "강함", "1100"),
        item("WSD", "9", "1000", "20261125"),
    ], NOW)
    assert len(rows) == 2
    assert rows[0]["wind_speed"] == 3.1
    assert rows[0]["temperature"] == -2
    assert "wave_height" not in rows[0]
    assert "rain_probability" not in rows[0]
    assert rows[1]["wave_height"] == 1.2
    assert "wind_speed" not in rows[1]
    assert rows[0]["datetime"].endswith("+09:00")


def test_grid_comes_from_coordinates_and_timestamp_is_explicit(monkeypatch):
    fetch = AsyncMock(return_value=[item("WSD", 2), item("WAV", 0)])
    monkeypatch.setattr(mf, "fetch_items", fetch)
    result = asyncio.run(mf.fetch_port_forecast(SPOT, "secret", object(), now=NOW))
    params = fetch.await_args.args[3]
    assert (params["nx"], params["ny"]) == (87, 68)
    assert params["base_time"] == "0800"
    assert result["current"]["wave_height"] == 0
    assert result["forecast_reference"]["relation"] == "port_grid"


def test_future_hour_is_not_misrepresented_as_current(monkeypatch):
    monkeypatch.setattr(mf, "fetch_items", AsyncMock(return_value=[item("WSD", 2, "1100")]))
    result = asyncio.run(mf.fetch_port_forecast(SPOT, "key", object(), now=NOW))
    assert result["current"] == {}
    assert len(result["hourly_forecast"]) == 1


def test_same_grid_issuance_reuses_cache_but_reselects_current_hour(monkeypatch):
    fetch = AsyncMock()
    monkeypatch.setattr(mf, "fetch_items", fetch)
    cache = AsyncMock()
    cache.get.return_value = json.dumps([item("WSD", 2), item("WSD", 3, "1100")])
    later = NOW.replace(hour=11)
    result = asyncio.run(mf.fetch_port_forecast(SPOT, "key", object(), now=later, cache=cache))
    fetch.assert_not_awaited()
    assert result["current"]["wind_speed"] == 3
    assert cache.get.await_args.args[0] == "marine:kma-grid:v1:87:68:20261124:0800"


def test_daily_quota_stops_other_port_requests_until_midnight(monkeypatch):
    fetch = AsyncMock(side_effect=KmaApiError("HTTP 429 LIMITED_NUMBER_OF_SERVICE_REQUESTS_EXCEEDS_ERROR"))
    monkeypatch.setattr(mf, "fetch_items", fetch)
    cache = AsyncMock()
    cache.get.return_value = None
    with pytest.raises(KmaApiError):
        asyncio.run(mf.fetch_port_forecast(SPOT, "key", object(), now=NOW, cache=cache))
    cache.setex.assert_awaited_once_with("marine:kma-grid:quota-cooldown", 48600, "limited")
    cache.get.return_value = "limited"
    with pytest.raises(KmaApiError, match="cooldown"):
        asyncio.run(mf.fetch_port_forecast(SPOT, "key", object(), now=NOW, cache=cache))
    assert fetch.await_count == 1


@pytest.mark.parametrize("failed", ["forecast", "tides", "warning"])
def test_sources_fail_independently_without_leaking_keys(monkeypatch, capsys, failed):
    forecast = AsyncMock(return_value={"current": {"wind_speed": 2}, "forecast_status": "available"})
    tides = AsyncMock(return_value=[{"time": "12:00", "height": 1, "type": "만조"}])
    warning = AsyncMock(return_value={"status": "unverified"})
    {"forecast": forecast, "tides": tides, "warning": warning}[failed].side_effect = KmaApiError("secret-key")
    monkeypatch.setattr(mc, "fetch_port_forecast", forecast)
    monkeypatch.setattr(mc, "_fetch_tide_forecast", tides)
    monkeypatch.setattr(mc, "_fetch_weather_warning", warning)
    cache = AsyncMock()
    assert asyncio.run(mc.collect_spot_marine(SPOT, cache, object(), "secret-key", "secret-key", False, 10800))
    payload = json.loads(cache.setex.await_args.args[2])
    assert bool(payload["tides"]) == (failed != "tides")
    assert bool(payload["marine"]["current"]) == (failed != "forecast")
    assert "secret-key" not in capsys.readouterr().out


def test_total_failure_overwrites_old_data_with_explicit_unavailable_state(monkeypatch):
    for name in ["fetch_port_forecast", "_fetch_tide_forecast", "_fetch_weather_warning"]:
        monkeypatch.setattr(mc, name, AsyncMock(side_effect=TimeoutError()))
    cache = AsyncMock()
    assert not asyncio.run(mc.collect_spot_marine(SPOT, cache, object(), "", "", False, 10800))
    payload = json.loads(cache.setex.await_args.args[2])
    assert payload["source"] == "NONE"
    assert payload["tide_status"] == "unavailable"
    assert payload["marine"]["current"] == {}


def test_bulletin_api_never_claims_no_active_port_warnings(monkeypatch):
    monkeypatch.setattr(mc, "fetch_items", AsyncMock(return_value=[{"t1": "풍랑주의보 발표"}]))
    result = asyncio.run(mc._fetch_weather_warning("108", "key", object()))
    assert result["status"] == "unverified"
    assert result["has_warning"] is None
    assert result["departure_blocked"] is None


@pytest.mark.parametrize("current", [{}, {"wind_speed": 0}, {"wave_height": None, "wind_speed": 0},
                                      {"wave_height": float("nan"), "wind_speed": -999}])
def test_missing_values_never_grant_departure(current, monkeypatch):
    monkeypatch.setenv("ANTHROPIC_API_KEY", "unused")
    result = asyncio.run(get_marine_recommendation("port", {"current": current}, [], ""))
    assert result["status"] == "UNKNOWN"
    assert result["departure_ok"] is False


def test_known_danger_takes_precedence_over_missing_warning():
    current = {"datetime": datetime.now(timezone.utc).replace(minute=0).isoformat(), "wind_speed": 16}
    assert _rule_based_marine({"current": current}, {})["status"] == "RED"
    current["datetime"] = (datetime.now(timezone.utc) - timedelta(hours=4)).isoformat()
    assert _rule_based_marine({"current": current}, {})["status"] == "UNKNOWN"
