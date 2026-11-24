"""Claude API 기반 취소/진행 권고 생성 서비스"""

import json
import math
import os
from datetime import datetime, timedelta, timezone

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
    rule_based = _rule_based_golf(forecasts, dday)
    api_key = os.getenv("ANTHROPIC_API_KEY", "")
    if use_mock or not api_key:
        return rule_based

    summary = _build_weather_summary(forecasts)
    prompt = f"""골프장: {course_name}
D-{dday} 날씨 요약: {summary}

아래 JSON만 출력해. 다른 텍스트 절대 금지:
{{"status":"GREEN|YELLOW|RED","message":"잠금화면 한 줄 (30자 이내)","detail":"상세 권고 (80자 이내)"}}

기준:
- RED: 강수확률 70%↑ OR 풍속 12m/s↑ OR 낙뢰 예보
- YELLOW: 강수확률 40~69% OR 풍속 8~12m/s
- GREEN: 그 외

중요:
- 위 기준을 넘지 않으면 절대 RED로 판단하지 마.
- RED/YELLOW/GREEN은 반드시 제공된 수치만 기준으로 판단해."""

    try:
        resp = await _get_client().messages.create(
            model="claude-sonnet-4-6",
            max_tokens=200,
            messages=[{"role": "user", "content": prompt}],
        )
        ai_result = json.loads(resp.content[0].text.strip())
        return _enforce_golf_weather_status(ai_result, rule_based)
    except Exception:
        return rule_based


async def get_marine_recommendation(
    spot_name: str,
    marine_data: dict,
    tides: list[dict],
    golden_time: str,
    use_mock: bool = False,
) -> dict:
    """배낚시 출항 권고 생성"""
    warning = marine_data.get("warning", {})
    # A language model must not turn unavailable safety inputs into permission.
    return _rule_based_marine(marine_data, warning)


# ── 규칙 기반 폴백 (API 키 없을 때) ──────────────────────────────
def _enforce_golf_weather_status(ai_result: dict, rule_based: dict) -> dict:
    """Keep recommendation severity aligned with measurable weather thresholds."""
    ai_status = str(ai_result.get("status", "")).upper()
    rule_status = str(rule_based.get("status", "UNKNOWN")).upper()
    if ai_status != rule_status:
        return rule_based

    message = str(ai_result.get("message") or rule_based["message"]).strip()
    detail = str(ai_result.get("detail") or rule_based["detail"]).strip()
    return {
        "status": rule_status,
        "message": message[:60],
        "detail": detail[:120],
    }


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
    def measurement(key):
        value = current.get(key)
        return value if isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value) and value >= 0 else None

    wave = measurement("wave_height")
    wind = measurement("wind_speed")
    blocked = warning.get("status") == "available" and warning.get("departure_blocked") is True
    try:
        at = datetime.fromisoformat(current["datetime"])
        age = datetime.now(timezone.utc) - at
        fresh = timedelta(0) <= age < timedelta(hours=1)
    except (KeyError, ValueError, TypeError):
        fresh = False

    if not fresh:
        wave = wind = None

    if blocked or (wave is not None and wave >= 3.0) or (wind is not None and wind >= 14.0):
        return {
            "status": "RED",
            "message": "출조 자제 — 위험 기상 신호",
            "detail": "높은 파도·강풍 또는 특보 정보가 있습니다. 공식 통제 안내를 확인하세요.",
            "departure_ok": False,
        }
    if wave is None or wind is None or warning.get("status") != "available":
        return {
            "status": "UNKNOWN", "message": "출조 판단 보류 — 정보 확인 필요",
            "detail": "바람·파고·해역별 특보 중 확인되지 않은 항목이 있습니다. 공식 안내를 확인하세요.",
            "departure_ok": False,
        }
    elif wave >= 2.0 or wind >= 10.0:
        return {
            "status": "YELLOW",
            "message": "출항 주의 — 파도 높음",
            "detail": f"파고 {wave}m / 풍속 {wind}m/s — 현장 기상과 통제 안내 확인 필요",
            "departure_ok": False,
        }
    return {
        "status": "GREEN",
        "message": "수치상 양호 — 현장 확인 필요",
        "detail": f"파고 {wave}m / 풍속 {wind}m/s — 안전이나 출항 허가를 보장하지 않습니다",
        "departure_ok": False,
    }
