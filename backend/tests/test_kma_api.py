import asyncio

import httpx
import pytest

from services import kma_api

HUB_KEY = "A" * 22
PORTAL_KEY = "B" * 88


def _client(handler):
    return httpx.AsyncClient(transport=httpx.MockTransport(handler))


def _fetch(handler, key=HUB_KEY, **kwargs):
    async def run():
        async with _client(handler) as client:
            return await kma_api.fetch_items(
                client, "VilageFcstInfoService_2.0/getVilageFcst", key, {"nx": 1}, **kwargs
            )

    return asyncio.run(run())


def test_provider_is_detected_from_key_length(monkeypatch):
    monkeypatch.delenv("KMA_API_PROVIDER", raising=False)
    assert kma_api.resolve_provider(HUB_KEY) == kma_api.APIHUB
    assert kma_api.resolve_provider(PORTAL_KEY) == kma_api.DATAGOKR


def test_provider_env_overrides_detection(monkeypatch):
    monkeypatch.setenv("KMA_API_PROVIDER", "datagokr")
    assert kma_api.resolve_provider(HUB_KEY) == kma_api.DATAGOKR
    monkeypatch.setenv("KMA_API_PROVIDER", "apihub")
    assert kma_api.resolve_provider(PORTAL_KEY) == kma_api.APIHUB


def test_request_uses_provider_specific_url_and_key_param():
    url, params = kma_api.build_request("X/getY", HUB_KEY, {"nx": 1}, kma_api.APIHUB)
    assert url == "https://apihub.kma.go.kr/api/typ02/openApi/X/getY"
    assert params == {"authKey": HUB_KEY, "nx": 1}

    url, params = kma_api.build_request("X/getY", PORTAL_KEY, {"nx": 1}, kma_api.DATAGOKR)
    assert url == "http://apis.data.go.kr/1360000/X/getY"
    assert params == {"serviceKey": PORTAL_KEY, "nx": 1}


def test_fetch_items_returns_item_list(monkeypatch):
    monkeypatch.delenv("KMA_API_PROVIDER", raising=False)
    seen = {}

    def handler(request):
        seen["url"] = str(request.url)
        return httpx.Response(200, json={"response": {
            "header": {"resultCode": "00", "resultMsg": "NORMAL_SERVICE"},
            "body": {"items": {"item": [{"category": "TMP"}]}},
        }})

    assert _fetch(handler) == [{"category": "TMP"}]
    assert seen["url"].startswith("https://apihub.kma.go.kr/api/typ02/openApi/")
    assert f"authKey={HUB_KEY}" in seen["url"]


def test_http_error_never_leaks_the_key(monkeypatch):
    monkeypatch.delenv("KMA_API_PROVIDER", raising=False)
    with pytest.raises(kma_api.KmaApiError) as exc:
        _fetch(lambda request: httpx.Response(403, text="Forbidden"))
    assert "403" in str(exc.value)
    assert HUB_KEY not in str(exc.value)


def test_connection_error_never_leaks_the_key(monkeypatch):
    monkeypatch.delenv("KMA_API_PROVIDER", raising=False)

    def handler(request):
        raise httpx.ConnectError("boom", request=request)

    with pytest.raises(kma_api.KmaApiError) as exc:
        _fetch(handler)
    assert HUB_KEY not in str(exc.value)
    assert exc.value.__cause__ is None


def test_api_level_error_is_reported_with_result_message():
    def handler(request):
        return httpx.Response(200, json={"response": {
            "header": {"resultCode": "30", "resultMsg": "SERVICE_KEY_IS_NOT_REGISTERED_ERROR"},
        }})

    with pytest.raises(kma_api.KmaApiError, match="SERVICE_KEY_IS_NOT_REGISTERED_ERROR"):
        _fetch(handler)


def test_non_json_body_is_reported_not_crashed():
    with pytest.raises(kma_api.KmaApiError, match="비정상 응답"):
        _fetch(lambda request: httpx.Response(200, text="<OpenAPI_ServiceResponse/>"))


def test_no_data_is_empty_only_when_allowed():
    def handler(request):
        return httpx.Response(200, json={"response": {
            "header": {"resultCode": "03", "resultMsg": "NO_DATA"},
        }})

    assert _fetch(handler, allow_empty=True) == []
    with pytest.raises(kma_api.KmaApiError):
        _fetch(handler)
