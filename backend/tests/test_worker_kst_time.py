from datetime import datetime, timedelta, timezone

from workers import weather_collector as wc


def test_now_kst_is_utc_plus_nine_regardless_of_server_timezone():
    utc_now = datetime.now(timezone.utc).replace(tzinfo=None)
    delta = wc._now_kst() - utc_now
    assert abs(delta - timedelta(hours=9)) < timedelta(seconds=5)


def test_latest_base_time_uses_the_most_recent_kst_release():
    # 한국 시각 10:30 → 08:00 발표분 (UTC 01:30 기준으로 계산하면 전날 23시가 됨)
    assert wc._latest_base_time(datetime(2026, 11, 23, 10, 30)) == ("20261123", "0800")
    assert wc._latest_base_time(datetime(2026, 11, 23, 1, 30)) == ("20261122", "2300")
