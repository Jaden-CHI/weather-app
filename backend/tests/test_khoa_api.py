import asyncio
from datetime import datetime
from unittest.mock import AsyncMock

import httpx
import pytest

from services.khoa_api import KhoaApiError, TIDE_URL, fetch_tides, parse_tides
from workers import marine_collector as mc


DATE = "20261123"
KEY = "test-secret/with+reserved="


def row(time="00:47", height=190, kind=2):
    return {"predcDt": f"2026-11-23 {time}", "predcTdlvVl": height, "extrSe": kind}


def payload(rows):
    return {"response": {
        "header": {"resultCode": "00", "resultMsg": "NORMAL_SERVICE"},
        "body": {"items": {"item": rows}},
    }}


def fetch(handler, key=KEY):
    async def run():
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            return await fetch_tides(client, "DT_0018", key, DATE)
    return asyncio.run(run())


def test_request_uses_new_https_api_and_query_contract():
    def handler(request):
        assert str(request.url).split("?")[0] == TIDE_URL
        assert dict(request.url.params) == {
            "serviceKey": KEY, "obsCode": "DT_0018", "reqDate": DATE,
            "type": "json", "pageNo": "1", "numOfRows": "300",
        }
        return httpx.Response(200, json=payload([row()]))
    assert fetch(handler) == [{"time": "00:47", "height": 1.9, "type": "간조"}]


def test_extrema_units_and_chronological_order():
    result = parse_tides(payload([
        row("19:00", -15, 4), row("01:00", 550, 1),
        row("13:00", 420, 3), row("07:00", 30, 2),
    ]), DATE)
    assert [t["time"] for t in result] == ["01:00", "07:00", "13:00", "19:00"]
    assert [t["type"] for t in result] == ["만조", "간조", "만조", "간조"]
    assert [t["height"] for t in result] == [5.5, 0.3, 4.2, -0.15]


def test_unwrapped_response_and_single_item():
    assert parse_tides(payload(row())["response"], DATE)[0]["time"] == "00:47"


@pytest.mark.parametrize("bad", [
    {}, [], {"response": None},
    payload([]), payload(None), payload([{}]),
    payload([row(kind=9)]), payload([row(height="nan")]),
    payload([row(height="inf")]), payload([row(time="bad")]),
    payload([{"predcDt": "2026-11-22 01:00", "predcTdlvVl": 10, "extrSe": 1}]),
])
def test_bad_data_is_not_treated_as_fresh_forecast(bad):
    with pytest.raises(KhoaApiError):
        parse_tides(bad, DATE)


@pytest.mark.parametrize("code", ["03", "30", "99", KEY])
def test_api_errors_do_not_echo_provider_message_or_key(code):
    with pytest.raises(KhoaApiError) as exc:
        parse_tides({"header": {"resultCode": code, "resultMsg": KEY}}, DATE)
    assert KEY not in str(exc.value)


@pytest.mark.parametrize("status", [307, 403, 503])
def test_http_errors_do_not_follow_redirect_or_leak_credentials(status):
    calls = []
    def handler(request):
        calls.append(request)
        return httpx.Response(status, text=str(request.url), headers={"location": "/503.html"})
    with pytest.raises(KhoaApiError, match=f"HTTP {status}") as exc:
        fetch(handler)
    assert len(calls) == 1
    assert KEY not in str(exc.value)
    assert "serviceKey" not in str(exc.value)


def test_timeout_is_identifiable_without_url():
    def handler(request):
        raise httpx.ReadTimeout(str(request.url), request=request)
    with pytest.raises(KhoaApiError, match="ReadTimeout") as exc:
        fetch(handler)
    assert "serviceKey" not in str(exc.value)


def test_html_error_is_not_a_json_forecast():
    with pytest.raises(KhoaApiError, match="non-JSON"):
        fetch(lambda request: httpx.Response(200, text=f"<html>{KEY}</html>"))


def test_missing_key_does_not_make_a_request():
    def handler(request):
        pytest.fail("A missing key must not be sent upstream")
    with pytest.raises(KhoaApiError, match="missing"):
        fetch(handler, key="  ")


def test_worker_requests_korean_calendar_date(monkeypatch):
    monkeypatch.setattr(mc, "_now_kst", lambda: datetime(2026, 11, 23, 0, 5))
    mocked = AsyncMock(return_value=[])
    monkeypatch.setattr(mc, "fetch_tides", mocked)
    client = object()
    asyncio.run(mc._fetch_tide_forecast("DT_0018", KEY, client))
    mocked.assert_awaited_once_with(client, "DT_0018", KEY, DATE)


def test_collection_failure_preserves_cache_and_hides_raw_exception(monkeypatch, capsys):
    monkeypatch.setattr(mc, "_fetch_weather_warning", AsyncMock(return_value={}))
    monkeypatch.setattr(mc, "_fetch_tide_forecast", AsyncMock(
        side_effect=httpx.ReadTimeout(f"url?serviceKey={KEY}")))
    cache = AsyncMock()
    cache.get.return_value = "existing-cache"
    ok = asyncio.run(mc.collect_spot_marine(
        {"spot_id": "FS_001", "khoa_obs_code": "DT_0018"},
        cache, object(), "kma-test-key", KEY, False, 10800,
    ))
    assert ok is False
    cache.setex.assert_not_awaited()
    cache.expire.assert_awaited_once_with("marine:FS_001", 3600)
    log = capsys.readouterr().out
    assert "ReadTimeout" in log
    assert KEY not in log
    assert "serviceKey" not in log
