"""Personal KMA thresholds; parity with Fishing Windy's assessTrip, not safety advice."""
import math
from datetime import datetime, timedelta, timezone

UTC = timezone.utc
LABELS = {'within': '내 기준 이내', 'exceeded': '내 기준 초과',
          'unavailable': '판단 보류', 'waiting': '예보 대기', 'finished': '일정 종료'}


def instant(value):
    if isinstance(value, datetime):
        return value.astimezone(UTC) if value.tzinfo else None
    try:
        return instant(datetime.fromisoformat(value.replace('Z', '+00:00')))
    except (TypeError, ValueError, AttributeError):
        return None


def assess(plan, provider, now):
    start, end = instant(plan['startsAt']), instant(plan['endsAt'])
    if end <= now:
        return 'finished'
    if start > now + timedelta(hours=48):
        return 'waiting'
    provider = provider or {}
    def recent(field, hours):
        at = instant(provider.get(field))
        return at is not None and -300 <= (now - at).total_seconds() <= hours * 3600
    if (provider.get('status') != 'available' or not recent('fetched_at', 3)
            or not recent('issued_at', 12)):
        return 'unavailable'
    rows = {instant(r.get('time')): r for r in provider.get('hourly', [])}
    at = max(start, now.replace(minute=0, second=0, microsecond=0))
    missing = exceeded = False
    while at < end:
        row = rows.get(at, {})
        for limit, field in [('maxWind', 'wind_speed'), ('maxWave', 'wave_height')]:
            if plan.get(limit) is None:
                continue
            value = row.get(field)
            if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) or value < 0:
                missing = True
            elif value > plan[limit]:
                exceeded = True
        at += timedelta(hours=1)
    return 'exceeded' if exceeded else 'unavailable' if missing else 'within'


def should_notify(old, new):
    return old != new and (new in ('within', 'exceeded') or
                          new == 'unavailable' and old in ('within', 'exceeded'))


def body_for(state):
    return {
        'within': '남은 출조 시간의 예보가 개인 기준 이내입니다. 안전을 보장하지 않습니다.',
        'exceeded': '남은 출조 시간에 바람 또는 파고가 개인 기준을 넘는 예보가 있습니다. 최신 정보를 확인하세요.',
        'unavailable': '최신 예보가 없거나 일부 시간·항목이 누락되어 판단을 보류합니다. 출조 전 다시 확인하세요.',
    }[state]
