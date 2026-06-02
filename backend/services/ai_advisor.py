"""Claude API 기반 취소/진행 권고 생성 서비스"""

import json
import os
from typing import Any

import anthropic

_client: anthropic.AsyncAnthropic | None = None


def _get_client() -> anthropic.AsyncAnthropic:
    global _client
    if _client is None:
        _client = anthropic.AsyncAnthropic(api_key=os.getenv("ANTHROPIC_API_KEY", ""))
    return _client


def _build_weather_summary(forecasts: list[dict]) -> str:
    if not forecasts:
        return "예보 없음"
    sample = forecasts[:8]  # 최대 8개 시간대
    lines = []
    for f in sample:
        time = f.get("time", "")[:2] + "시"
        lines.append(
            f"{time}: {f.get('temp','?')}°C, "
            f"강수{f.get('rain_prob','?')}%, "
            f"풍속{f.get('wind_speed','?')}m/s"
            + (" ⚡낙뢰" if f.get("lightning", 0) else "")
        )
    return " | ".join(lines)


async def get_golf_recommendation(
    course_name: str,
    forecasts: list[dict],
    dday: int,
    use_mock: bool = False,
) -> dict:
    """골프 취소/진행 권고 생성. ANTHROPIC_API_KEY 없으면 규칙 기반으로 폴백"""
    api_key = os.getenv("ANTHROPIC_API_KEY", "")
    if use_mock or not api_key:
        return _rule_based_golf(forecasts, dday)

    summary = _build_weather_summary(forecasts)
    prompt = f"""골프장: {course_name}
D-{dday} 날씨 요약: {summary}

아래 JSON만 출력해. 다른 텍스트 절대 금지:
{{"status":"GREEN|YELLOW|RED","message":"잠금화면 한 줄 (30자 이내)","detail":"상세 권고 (80자 이내)"}}

기준:
- RED: 강수확률 70%↑ OR 풍속 12m/s↑ OR 낙뢰 예보
- YELLOW: 강수확률 40~69% OR 풍속 8~12m/s
- GREEN: 그 외"""

    try:
        resp = await _get_client().messages.create(
            model="claude-sonnet-4-6",
            max_tokens=200,
            messages=[{"role": "user", "content": prompt}],
        )
        return json.loads(resp.content[0].text.strip())
    except Exception:
        return _rule_based_golf(forecasts, dday)


async def get_marine_recommendation(
    spot_name: str,
    marine_data: dict,
    tides: list[dict],
    golden_time: str,
    use_mock: bool = False,
) -> dict:
    """배낚시 출항 권고 생성"""
    api_key = os.getenv("ANTHROPIC_API_KEY", "")
    warning = marine_data.get("warning", {})

    if use_mock or not api_key:
        return _rule_based_marine(marine_data, warning)

    current = marine_data.get("current", {})
    prompt = f"""낚시 출항지: {spot_name}
현재 해양 상태:
- 파고: {current.get('wave_height','?')}m
- 풍속: {current.get('wind_speed','?')}m/s
- 수온: {current.get('sea_temp','?')}°C
- 기상특보: {warning.get('level','없음')}
- 입질 골든타임: {golden_time}

아래 JSON만 출력:
{{"status":"GREEN|YELLOW|RED","message":"잠금화면 한 줄 (30자 이내)","detail":"출항 권고 상세 (80자 이내)","departure_ok":true|false}}

기준:
- RED: 풍랑특보 발효 OR 파고 3m↑ OR 풍속 14m/s↑
- YELLOW: 파고 2~3m OR 풍속 10~14m/s
- GREEN: 그 외"""

    try:
        resp = await _get_client().messages.create(
            model="claude-sonnet-4-6",
            max_tokens=200,
            messages=[{"role": "user", "content": prompt}],
        )
        return json.loads(resp.content[0].text.strip())
    except Exception:
        return _rule_based_marine(marine_data, warning)


# ── 규칙 기반 폴백 (API 키 없을 때) ──────────────────────────────
def _rule_based_golf(forecasts: list[dict], dday: int) -> dict:
    if not forecasts:
        return {"status": "UNKNOWN", "message": "예보 데이터 없음", "detail": "기상 데이터를 불러오지 못했습니다"}

    max_rain = max((f.get("rain_prob", 0) for f in forecasts), default=0)
    max_wind = max((f.get("wind_speed", 0) for f in forecasts), default=0)
    has_lightning = any(f.get("lightning", 0) for f in forecasts)

    if max_rain >= 70 or float(max_wind) >= 12 or has_lightning:
        return {
            "status": "RED",
            "message": f"D-{dday} 취소 권고 — 악천후 예상",
            "detail": f"강수확률 {max_rain}% / 풍속 {max_wind}m/s" + (" / 낙뢰 예보" if has_lightning else ""),
        }
    elif max_rain >= 40 or float(max_wind) >= 8:
        return {
            "status": "YELLOW",
            "message": f"D-{dday} 주의 — 우비·방풍 준비",
            "detail": f"강수확률 {max_rain}% / 풍속 {max_wind}m/s — 진행은 가능하나 주의 필요",
        }
    return {
        "status": "GREEN",
        "message": f"D-{dday} 라운딩 최적",
        "detail": f"강수확률 {max_rain}% / 풍속 {max_wind}m/s — 쾌적한 날씨 예상",
    }


def _rule_based_marine(marine_data: dict, warning: dict) -> dict:
    current = marine_data.get("current", {})
    wave = float(current.get("wave_height", 0))
    wind = float(current.get("wind_speed", 0))
    blocked = warning.get("departure_blocked", False)

    if blocked or wave >= 3.0 or wind >= 14.0:
        return {
            "status": "RED",
            "message": "출항 불가 — 풍랑특보 또는 고파도",
            "detail": f"파고 {wave}m / 풍속 {wind}m/s — 출항 자제",
            "departure_ok": False,
        }
    elif wave >= 2.0 or wind >= 10.0:
        return {
            "status": "YELLOW",
            "message": "출항 주의 — 파도 높음",
            "detail": f"파고 {wave}m / 풍속 {wind}m/s — 숙련자만 출항 권고",
            "departure_ok": True,
        }
    return {
        "status": "GREEN",
        "message": "출항 가능 — 조황 양호",
        "detail": f"파고 {wave}m / 풍속 {wind}m/s — 출조 최적 조건",
        "departure_ok": True,
    }
