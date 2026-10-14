import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/models/weather_data.dart';
import 'package:weather_app/services/round_suitability.dart';

GolfWeatherData _data({
  required List<ForecastItem> forecast,
  String status = 'GREEN',
  String message = '백엔드 메시지',
}) =>
    GolfWeatherData(
      courseId: 'C1',
      courseName: '테스트CC',
      region: '경기',
      golfzonLinked: false,
      dday: 2,
      forecastDate: '20260721',
      aiRecommendation:
          AiRecommendation(status: status, message: message, detail: ''),
      cancellationPolicy: const CancellationPolicy(
        urgency: 'NORMAL',
        message: '',
        sameDayPenalty: '',
        noshowPenalty: '',
        rainCancel:
            RainCancelPolicy(available: false, condition: '', refundRule: ''),
        policySource: 'FALLBACK',
      ),
      forecast: forecast,
      screenGolfNearby: const [],
    );

ForecastItem _f({
  String time = '10',
  double temp = 22,
  double wind = 3,
  int rain = 10,
  bool lightning = false,
}) =>
    ForecastItem(
      date: '20260721',
      time: '${time}00',
      temp: temp,
      windSpeed: wind,
      rainProb: rain,
      sky: 1,
      lightning: lightning,
    );

void main() {
  const standard = UserWeatherProfile();

  group('RoundSuitability.evaluate', () {
    test('보통 민감도 + 좋은 날씨 → 백엔드 GREEN 유지 (메시지 보존)', () {
      final data = _data(forecast: [_f()]);
      final rec = RoundSuitability.evaluate(data, standard);
      expect(rec.status, 'GREEN');
      expect(rec.message, '백엔드 메시지');
    });

    test('비 민감도 높음 → 강수 35%가 GREEN에서 YELLOW로', () {
      final data = _data(forecast: [_f(rain: 35)]);
      const profile = UserWeatherProfile(rain: WeatherSensitivity.high);
      expect(RoundSuitability.evaluate(data, standard).status, 'GREEN');
      final rec = RoundSuitability.evaluate(data, profile);
      expect(rec.status, 'YELLOW');
      expect(rec.detail, contains('성향 반영'));
    });

    test('비 민감도 낮음 → 강수 50%가 YELLOW에서 GREEN으로', () {
      final data = _data(forecast: [_f(rain: 50)], status: 'YELLOW');
      const profile = UserWeatherProfile(rain: WeatherSensitivity.low);
      expect(RoundSuitability.evaluate(data, profile).status, 'GREEN');
    });

    test('바람 민감도 높음 → 풍속 9.5m/s가 YELLOW에서 RED로', () {
      final data = _data(forecast: [_f(wind: 9.5)], status: 'YELLOW');
      const profile = UserWeatherProfile(wind: WeatherSensitivity.high);
      final rec = RoundSuitability.evaluate(data, profile);
      expect(rec.status, 'RED');
      expect(rec.message, contains('취소 권고'));
    });

    test('추위 민감도 보통 → 최저 2°C면 YELLOW (백엔드에 없는 판정)', () {
      final data = _data(forecast: [_f(temp: 2)]);
      final rec = RoundSuitability.evaluate(data, standard);
      expect(rec.status, 'YELLOW');
      expect(rec.message, contains('방한'));
    });

    test('더위 민감도 높음 → 최고 30°C면 YELLOW', () {
      final data = _data(forecast: [_f(temp: 30)]);
      const profile = UserWeatherProfile(heat: WeatherSensitivity.high);
      expect(RoundSuitability.evaluate(data, standard).status, 'GREEN');
      expect(RoundSuitability.evaluate(data, profile).status, 'YELLOW');
    });

    test('낙뢰는 민감도와 무관하게 RED', () {
      final data = _data(forecast: [_f(lightning: true)]);
      const tolerant = UserWeatherProfile(
        rain: WeatherSensitivity.low,
        wind: WeatherSensitivity.low,
      );
      expect(RoundSuitability.evaluate(data, tolerant).status, 'RED');
    });

    test('라운드 윈도우 밖 악천후는 무시 (티오프 10시, 18시 폭우)', () {
      final data = _data(forecast: [
        _f(time: '10', rain: 10),
        _f(time: '18', rain: 90),
      ]);
      final rec = RoundSuitability.evaluate(data, standard, startHour: 10);
      expect(rec.status, 'GREEN');
      final noWindow = RoundSuitability.evaluate(data, standard);
      expect(noWindow.status, 'RED');
    });

    test('UNKNOWN/빈 예보는 백엔드 판정 유지', () {
      final data = _data(forecast: [], status: 'UNKNOWN');
      expect(RoundSuitability.evaluate(data, standard).status, 'UNKNOWN');
    });
  });
}
