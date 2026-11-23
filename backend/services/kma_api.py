"""
기상청 OpenAPI 호출 공통부.

같은 API를 두 곳에서 제공하며 인증키가 서로 호환되지 않는다.
- 공공데이터포털(data.go.kr): `serviceKey` 파라미터, 80자 이상 긴 키
- 기상청 API허브(apihub.kma.go.kr): `authKey` 파라미터, 20여 자 짧은 키

KMA_API_PROVIDER(datagokr | apihub)로 지정하고, 없으면 키 길이로 판별한다.
"""

import os
from typing import Any

import httpx

DATAGOKR = "datagokr"
APIHUB = "apihub"

_BASE_URLS = {
    DATAGOKR: "http://apis.data.go.kr/1360000",
    APIHUB: "https://apihub.kma.go.kr/api/typ02/openApi",
}
_KEY_PARAMS = {DATAGOKR: "serviceKey", APIHUB: "authKey"}

# API허브 키는 22자 안팎, 공공데이터포털 키는 80자 이상
_APIHUB_KEY_MAX_LEN = 40


class KmaApiError(RuntimeError):
    """기상청 호출 실패. 메시지에 인증키를 담지 않는다."""


def resolve_provider(api_key: str, configured: str | None = None) -> str:
    value = (
        configured if configured is not None else os.getenv("KMA_API_PROVIDER", "")
    ).strip().lower()
    if value in ("apihub", "kma", "hub"):
        return APIHUB
    if value in ("datagokr", "data.go.kr", "datago", "public"):
        return DATAGOKR
    return APIHUB if len(api_key.strip()) <= _APIHUB_KEY_MAX_LEN else DATAGOKR


def build_request(
    path: str, api_key: str, params: dict[str, Any], provider: str | None = None
) -> tuple[str, dict[str, Any]]:
    """(url, params) 반환. path 예: 'VilageFcstInfoService_2.0/getVilageFcst'"""
    provider = provider or resolve_provider(api_key)
    url = f"{_BASE_URLS[provider]}/{path.lstrip('/')}"
    return url, {_KEY_PARAMS[provider]: api_key.strip(), **params}


async def fetch_items(
    client: httpx.AsyncClient,
    path: str,
    api_key: str,
    params: dict[str, Any],
    *,
    timeout: float = 10.0,
    allow_empty: bool = False,
) -> list[dict]:
    """기상청 API를 호출해 item 목록을 돌려준다. 실패 시 KmaApiError."""
    provider = resolve_provider(api_key)
    url, query = build_request(path, api_key, params, provider)

    try:
        resp = await client.get(url, params=query, timeout=timeout)
    except httpx.HTTPError as e:
        # httpx 예외 문자열에는 키가 포함된 URL이 들어가므로 종류만 남긴다
        raise KmaApiError(f"기상청({provider}) 연결 실패: {type(e).__name__}") from None

    if resp.status_code != 200:
        raise KmaApiError(
            f"기상청({provider}) HTTP {resp.status_code}: {_snippet(resp.text)}"
        )

    try:
        payload = resp.json()
    except ValueError:
        # 키 오류 등은 JSON이 아닌 XML/텍스트로 내려온다
        raise KmaApiError(
            f"기상청({provider}) 비정상 응답: {_snippet(resp.text)}"
        ) from None

    response = payload.get("response") if isinstance(payload, dict) else None
    if not isinstance(response, dict):
        raise KmaApiError(f"기상청({provider}) 비정상 응답: {_snippet(resp.text)}")

    header = response.get("header") or {}
    code = str(header.get("resultCode", ""))
    if code == "03" and allow_empty:  # NO_DATA
        return []
    if code not in ("00", "0"):
        raise KmaApiError(
            f"기상청({provider}) 오류 {code}: {header.get('resultMsg', '')}"
        )

    body = response.get("body")
    items = body.get("items") if isinstance(body, dict) else None
    items = items.get("item", []) if isinstance(items, dict) else []
    if isinstance(items, dict):
        items = [items]
    return items


def _snippet(text: str, limit: int = 160) -> str:
    return " ".join(text.split())[:limit]
