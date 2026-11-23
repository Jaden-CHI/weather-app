import sys
import unittest
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from services.forecast_safety import KST, filter_forecasts, is_sample_source, round_start, target_date
from services.penalty_advisor import get_penalty_advice, get_sample_policy


class ForecastSafetyTests(unittest.TestCase):
    def test_korean_midnight_uses_next_day_even_if_server_is_utc(self):
        self.assertEqual(str(target_date(0, datetime(2026, 10, 14, 15, 5, tzinfo=timezone.utc))), '2026-10-15')

    def test_missing_requested_day_does_not_return_another_day(self):
        self.assertEqual(filter_forecasts([{'date': '20261014', 'time': '0900'}], 1,
                                         datetime(2026, 10, 14, tzinfo=KST)), [])

    def test_only_requested_day_is_sorted(self):
        rows = [{'date': '20261015', 'time': '1200'}, {'date': '20261014', 'time': '0900'},
                {'date': '20261015', 'time': '0600'}]
        self.assertEqual([f['time'] for f in filter_forecasts(rows, 1, datetime(2026, 10, 14, tzinfo=KST))], ['0600', '1200'])

    def test_mock_variants_rejected(self):
        for source in ('MOCK', 'MOCK_CUSTOM', 'mock'):
            self.assertTrue(is_sample_source(source))
        self.assertFalse(is_sample_source('OPEN_METEO'))

    def test_round_start_keeps_minutes(self):
        self.assertEqual(round_start(1, 6, 37, datetime(2026, 10, 14, 19, tzinfo=KST)),
                         datetime(2026, 10, 15, 6, 37, tzinfo=KST))

    def test_legacy_client_without_minutes_has_no_assumed_start(self):
        self.assertIsNone(round_start(1, 6, None))

    def test_sample_policy_never_claims_free_cancellation(self):
        result = get_penalty_advice(get_sample_policy('DEFAULT'), datetime(2026, 10, 16, tzinfo=KST))
        self.assertIsNone(result['can_cancel_free'])
        self.assertIsNone(result['deadline_str'])
        self.assertFalse(result['verified'])

    def test_unverified_db_policy_is_hidden(self):
        result = get_penalty_advice({'free_cancel_hours': 24}, datetime(2026, 10, 16, tzinfo=KST))
        self.assertIsNone(result['can_cancel_free'])

    def test_missing_tee_time_never_creates_deadline(self):
        self.assertIsNone(get_penalty_advice({'free_cancel_hours': 24}, None, verified=True)['deadline_str'])

    def test_verified_policy_deadline_uses_actual_tee_time(self):
        result = get_penalty_advice({'free_cancel_hours': 24}, datetime(2026, 10, 16, 6, 37, tzinfo=KST),
                                   verified=True, now=datetime(2026, 10, 15, 5, 37, tzinfo=KST))
        self.assertEqual(result['deadline_str'], '10/15 06:37')
        self.assertEqual(result['countdown'], '1시간 0분')
        self.assertTrue(result['can_cancel_free'])
        self.assertTrue(result['verified'])

    def test_deadline_boundary_is_expired(self):
        result = get_penalty_advice({'free_cancel_hours': 24}, datetime(2026, 10, 16, 6, 37, tzinfo=KST),
                                   verified=True, now=datetime(2026, 10, 15, 6, 37, tzinfo=KST))
        self.assertFalse(result['can_cancel_free'])

    def test_invalid_policy_hours_are_unknown(self):
        for hours in (-1, '24', float('nan'), float('inf'), True, 999999999):
            result = get_penalty_advice({'free_cancel_hours': hours}, datetime(2026, 10, 16, tzinfo=KST), verified=True)
            self.assertIsNone(result['can_cancel_free'])


if __name__ == '__main__':
    unittest.main()
