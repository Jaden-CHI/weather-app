import asyncio
import json
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock

import pytest

from services.khoa_api import KhoaApiError, TIDE_MAPPING_VERSION, cached_tide_view, parse_tides
from workers import marine_collector as mc


SPOTS = json.loads((Path(__file__).parents[1] / "data/fishing_spots.json").read_text())
EXPECTED = {
    "FS_001": ("DT_0014", "통영"), "FS_002": ("SO_0552", "고현항"),
    "FS_003": ("DT_0016", "여수"), "FS_004": ("DT_0005", "부산"),
    "FS_005": ("DT_0065", "덕적도"), "FS_007": ("DT_0027", "완도"),
    "FS_008": ("DT_0022", "성산포"), "FS_009": ("DT_0023", "모슬포"),
    "FS_010": ("DT_0013", "울릉도"), "FS_011": ("DT_0012", "속초"),
    "FS_013": ("SO_1267", "구룡포항"), "FS_014": ("DT_0007", "목포"),
}


@pytest.fixture(autouse=True)
def stub_port_forecast(monkeypatch):
    monkeypatch.setattr(mc, "fetch_port_forecast", AsyncMock(return_value={
        "current": {"wind_speed": 2.1}, "hourly_forecast": [],
        "forecast_status": "available",
    }))


def test_seed_uses_audited_station_names_and_codes():
    assert len(SPOTS) == 15
    for spot in SPOTS:
        assert (spot["khoa_obs_code"], spot["khoa_obs_name"]) == EXPECTED.get(
            spot["spot_id"], (None, None))
    assert {s["spot_id"] for s in SPOTS if not s["khoa_obs_code"]} == {
        "FS_006", "FS_012", "FS_015"}


@pytest.mark.parametrize("name", ["제주", "", None])
def test_wrong_station_response_is_rejected(name):
    payload = {"header": {"resultCode": "00"}, "body": {"items": {"item": [{
        "predcDt": "2026-11-23 01:00", "predcTdlvVl": 120, "extrSe": 1,
        "obsvtrNm": name,
    }]}}}
    with pytest.raises(KhoaApiError, match="invalid tide record"):
        parse_tides(payload, "20261123", "통영")


def test_old_cache_cannot_leak_tides_or_golden_time():
    result = cached_tide_view({"tides": [{"time": "01:00"}], "golden_time": "00:00~02:00"})
    assert result == {"tides": [], "golden_time": "정보 없음",
                      "tide_status": "unverified", "tide_station": None}


def test_unmapped_spot_is_explicit_and_never_calls_tide_api(monkeypatch):
    monkeypatch.setattr(mc, "_fetch_weather_warning", AsyncMock(return_value={}))
    tide_fetch = AsyncMock()
    monkeypatch.setattr(mc, "_fetch_tide_forecast", tide_fetch)
    cache = AsyncMock()
    spot = next(s for s in SPOTS if s["spot_id"] == "FS_006")
    assert asyncio.run(mc.collect_spot_marine(spot, cache, object(), "kma", "khoa", False, 10800))
    tide_fetch.assert_not_awaited()
    payload = json.loads(cache.setex.await_args.args[2])
    assert payload["source"] == "KMA"
    assert payload["tide_mapping_version"] == TIDE_MAPPING_VERSION
    assert cached_tide_view(payload) == {"tides": [], "golden_time": "정보 없음",
        "tide_status": "mapping_unverified", "tide_station": None}


def test_verified_station_metadata_is_cached(monkeypatch):
    monkeypatch.setattr(mc, "_fetch_weather_warning", AsyncMock(return_value={}))
    tides = [{"time": "13:00", "height": 1.2, "type": "만조"}]
    fetch = AsyncMock(return_value=tides)
    monkeypatch.setattr(mc, "_fetch_tide_forecast", fetch)
    cache = AsyncMock()
    assert asyncio.run(mc.collect_spot_marine(SPOTS[0], cache, object(), "kma", "khoa", False, 10800))
    assert fetch.await_args.args[-1] == "통영"
    payload = json.loads(cache.setex.await_args.args[2])
    assert cached_tide_view(payload)["tides"] == tides
    assert payload["tide_station"] == {
        "code": "DT_0014", "name": "통영", "relation": "regional_reference"}


def test_existing_database_receives_only_station_code_updates():
    from models.database import seed_data
    session = AsyncMock()
    result = MagicMock()
    result.scalar.return_value = 15
    session.execute.return_value = result
    asyncio.run(seed_data(session))
    calls = [call for call in session.execute.await_args_list
             if "UPDATE fishing_spots" in str(call.args[0])]
    assert len(calls) == 15
    assert {c.args[1]["id"]: c.args[1]["code"] for c in calls} == {
        s["spot_id"]: s["khoa_obs_code"] for s in SPOTS}
    for call in calls:
        sql = str(call.args[0])
        assert "SET khoa_obs_code = :code" in sql
        assert "WHERE spot_id = :id" in sql
        assert "name =" not in sql


def test_actual_weather_handler_blocks_old_cached_station_data(monkeypatch):
    from api.routers import marine
    cache = AsyncMock()
    cache.get.return_value = json.dumps({
        "source": "KMA+KHOA", "tides": [{"time": "01:00"}],
        "golden_time": "00:00~02:00", "marine": {},
    })
    monkeypatch.setattr(marine, "_get_redis", lambda: cache)
    monkeypatch.setattr(marine, "get_fishing_spot", AsyncMock(return_value=SPOTS[0]))
    advisor = AsyncMock(return_value={})
    monkeypatch.setattr(marine, "get_marine_recommendation", advisor)
    result = asyncio.run(marine.get_spot_weather("FS_001", object()))
    assert result["tides"] == []
    assert result["golden_time"] == "정보 없음"
    assert result["tide_status"] == "unverified"
    assert advisor.await_args.args[2] == []
