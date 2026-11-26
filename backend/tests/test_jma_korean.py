import copy
import unittest

from services.jma_korean import localize_reference, translate_forecast


class KoreanForecastTests(unittest.TestCase):
    def test_wave_values_order_units_and_qualifiers(self):
        self.assertEqual(translate_forecast('２．５メートル　後　１．５メートル'), '2.5 m, 이후 1.5 m')
        self.assertEqual(translate_forecast('０メートル'), '0 m')
        self.assertEqual(translate_forecast('３メートル　うねりを伴う'), '3 m 너울 동반')
        self.assertEqual(translate_forecast('２．５メートル　ただし　瀬戸内側　では　１メートル'), '2.5 m, 다만 세토내해 쪽에서는 1 m')

    def test_direction_changes_and_sea_qualifier(self):
        self.assertEqual(translate_forecast('北西の風　やや強く　後　西の風'), '북서풍 다소 강함, 이후 서풍')
        self.assertEqual(translate_forecast('北の風　後　南の風　海上　では　北西の風　やや強く'),
                         '북풍, 이후 남풍 · 해상에서는 북서풍 다소 강함')
        self.assertEqual(translate_forecast('南東の風　非常に強く'), '남동풍 매우 강함')

    def test_weather_precipitation_alternatives_and_timing(self):
        self.assertEqual(translate_forecast('くもり　所により　明け方　まで　雨か雪'), '흐림, 곳에 따라 새벽까지 비 또는 눈')
        self.assertEqual(translate_forecast('くもり　時々　晴れ'), '흐림, 가끔 맑음')
        self.assertEqual(translate_forecast('晴れ　昼過ぎ　から　夕方　くもり'), '맑음, 이른 오후부터 저녁까지 흐림')
        self.assertEqual(translate_forecast('雨　雷を伴い　激しく降る'), '비, 천둥을 동반하며 매우 강하게 내림')

    def test_no_partial_translation_of_unknown_qualifiers(self):
        for value in ('３メートル 未知の危険情報', '晴れ ただし 新しい表現', '北西の風 弱くならない', '', None):
            self.assertIsNone(translate_forecast(value))

    def test_cached_original_and_provenance_are_unchanged(self):
        raw = {'status': 'stale', 'issued_at': '2026-11-24T11:00:00+09:00',
               'fetched_at': '2026-11-24T12:00:00+09:00',
               'days': [{'time': '2026-11-24T11:00:00+09:00', 'waves': '２メートル',
                         'winds': None, 'weathers': '未知'}]}
        before = copy.deepcopy(raw)
        result = localize_reference(raw)
        self.assertEqual(raw, before)
        self.assertEqual(result['days'][0]['waves'], '２メートル')
        self.assertEqual(result['days'][0]['ko'], {'waves': '2 m', 'winds': None, 'weathers': None})
        for key in ('status', 'issued_at', 'fetched_at'):
            self.assertEqual(result[key], raw[key])
