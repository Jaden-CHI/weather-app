"""Date/source validation shared by API responses and notifications."""
from datetime import datetime, timedelta, timezone

KST = timezone(timedelta(hours=9))


def target_date(dday, now=None):
    now = now or datetime.now(KST)
    if now.tzinfo is None:
        now = now.replace(tzinfo=KST)
    return now.astimezone(KST).date() + timedelta(days=dday)


def filter_forecasts(forecasts, dday, now=None):
    expected = target_date(dday, now).strftime('%Y%m%d')
    return sorted(
        [f for f in forecasts if f.get('date') == expected],
        key=lambda f: f.get('time', ''),
    )


def is_sample_source(source):
    return 'MOCK' in str(source or '').upper()


def round_start(dday, hour, minute, now=None):
    # Older clients do not send minutes. Do not invent a cancellation deadline.
    if hour is None or minute is None:
        return None
    day = target_date(dday, now)
    return datetime(day.year, day.month, day.day, hour, minute, tzinfo=KST)
