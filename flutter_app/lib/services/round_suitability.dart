import '../models/weather_data.dart';
import 'settings_service.dart';

/// 날씨 항목별 민감도 (라운드 성향)
enum WeatherSensitivity {
  low('low', '낮음'),
  normal('normal', '보통'),
  high('high', '높음');

  final String id;
  final String label;
  const WeatherSensitivity(this.id, this.label);

  static WeatherSensitivity byId(String? id) =>
      values.firstWhere((s) => s.id == id, orElse: () => normal);
}

/// 사용자 라운드 성향 프로필 (비·바람·추위·더위 민감도)
class UserWeatherProfile {
  final WeatherSensitivity rain;
  final WeatherSensitivity wind;
  final WeatherSensitivity cold;
  final WeatherSensitivity heat;

  const UserWeatherProfile({
    this.rain = WeatherSensitivity.normal,
    this.wind = WeatherSensitivity.normal,
    this.cold = WeatherSensitivity.normal,
    this.heat = WeatherSensitivity.normal,
  });

  static Future<UserWeatherProfile> load() async {
    final s = SettingsService.instance;
    return UserWeatherProfile(
      rain: WeatherSensitivity.byId(await s.getWeatherSensitivity('rain')),
      wind: WeatherSensitivity.byId(await s.getWeatherSensitivity('wind')),
      cold: WeatherSensitivity.byId(await s.getWeatherSensitivity('cold')),
      heat: WeatherSensitivity.byId(await s.getWeatherSensitivity('heat')),
    );
  }
}

class _Band {
  final double yellow;
  final double red;
  const _Band(this.yellow, this.red);
}

/// 사용자 성향을 반영한 라운드 적합도 재판정.
///
/// 백엔드 룰(강수 40/70%, 풍속 8/12m/s)과 동일한 기준을 '보통' 민감도로 두고,
/// 민감도에 따라 임계값을 조정한다. 추위·더위는 백엔드에 없는 클라이언트 전용 판정.
class RoundSuitability {
  // 민감도별 YELLOW/RED 임계값 (rain %, wind m/s: 이상 / temp °C: cold 이하, heat 이상)
  static const _rainBands = {
    WeatherSensitivity.low: _Band(55, 85),
    WeatherSensitivity.normal: _Band(40, 70),
    WeatherSensitivity.high: _Band(30, 55),
  };
  static const _windBands = {
    WeatherSensitivity.low: _Band(10, 15),
    WeatherSensitivity.normal: _Band(8, 12),
    WeatherSensitivity.high: _Band(6, 9),
  };
  static const _coldBands = {
    WeatherSensitivity.low: _Band(0, -6),
    WeatherSensitivity.normal: _Band(3, -2),
    WeatherSensitivity.high: _Band(6, 1),
  };
  static const _heatBands = {
    WeatherSensitivity.low: _Band(33, 36),
    WeatherSensitivity.normal: _Band(31, 34),
    WeatherSensitivity.high: _Band(29, 32),
  };

  /// API 응답에 성향 판정을 적용한 사본을 돌려준다.
  static Future<GolfWeatherData> apply(
    GolfWeatherData data, {
    int? startHour,
  }) async {
    if (data.aiRecommendation.status == 'UNKNOWN' || data.forecast.isEmpty) {
      return data;
    }
    final profile = await UserWeatherProfile.load();
    return data.withRecommendation(
      evaluate(data, profile, startHour: startHour),
    );
  }

  /// 성향 반영 판정. 백엔드 판정과 같은 상태면 백엔드(AI) 메시지를 그대로 유지한다.
  static AiRecommendation evaluate(
    GolfWeatherData data,
    UserWeatherProfile profile, {
    int? startHour,
  }) {
    final items = _roundWindow(data.forecast, startHour);
    if (items.isEmpty) return data.aiRecommendation;

    final maxRain = items.map((f) => f.rainProb).reduce((a, b) => a > b ? a : b);
    final maxWind =
        items.map((f) => f.windSpeed).reduce((a, b) => a > b ? a : b);
    final minTemp = items.map((f) => f.temp).reduce((a, b) => a < b ? a : b);
    final maxTemp = items.map((f) => f.temp).reduce((a, b) => a > b ? a : b);
    final hasLightning = items.any((f) => f.lightning);

    // 항목별 위험 수준: 0=양호 1=주의 2=위험
    final rainBand = _rainBands[profile.rain]!;
    final windBand = _windBands[profile.wind]!;
    final coldBand = _coldBands[profile.cold]!;
    final heatBand = _heatBands[profile.heat]!;

    final levels = <String, int>{
      'rain': maxRain >= rainBand.red
          ? 2
          : maxRain >= rainBand.yellow
              ? 1
              : 0,
      'wind': maxWind >= windBand.red
          ? 2
          : maxWind >= windBand.yellow
              ? 1
              : 0,
      'cold': minTemp <= coldBand.red
          ? 2
          : minTemp <= coldBand.yellow
              ? 1
              : 0,
      'heat': maxTemp >= heatBand.red
          ? 2
          : maxTemp >= heatBand.yellow
              ? 1
              : 0,
    };
    if (hasLightning) levels['rain'] = 2;

    final worst = levels.values.reduce((a, b) => a > b ? a : b);
    final status = worst >= 2
        ? 'RED'
        : worst == 1
            ? 'YELLOW'
            : 'GREEN';

    // 판정이 백엔드와 같으면 AI가 만든 메시지를 그대로 사용
    if (status == data.aiRecommendation.status) return data.aiRecommendation;

    final dday = data.dday;
    final windStr = maxWind.toStringAsFixed(maxWind == maxWind.roundToDouble() ? 0 : 1);
    final parts = <String>['강수확률 $maxRain%', '풍속 ${windStr}m/s'];
    if (levels['cold']! > 0) parts.add('최저 ${minTemp.round()}°C');
    if (levels['heat']! > 0) parts.add('최고 ${maxTemp.round()}°C');
    if (hasLightning) parts.add('낙뢰 예보');
    final detail = '${parts.join(' / ')} — 내 라운드 성향 반영 판정';

    switch (status) {
      case 'RED':
        return AiRecommendation(
          status: 'RED',
          message: 'D-$dday 취소 권고 — ${_worstLabel(levels)} 주의보',
          detail: detail,
        );
      case 'YELLOW':
        return AiRecommendation(
          status: 'YELLOW',
          message: 'D-$dday 주의 — ${_prepLabel(levels)} 준비',
          detail: detail,
        );
      default:
        return AiRecommendation(
          status: 'GREEN',
          message: 'D-$dday 라운딩 적합',
          detail: detail,
        );
    }
  }

  static String _worstLabel(Map<String, int> levels) {
    final worst = levels.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return const {
      'rain': '악천후',
      'wind': '강풍',
      'cold': '한파',
      'heat': '폭염',
    }[worst.key]!;
  }

  static String _prepLabel(Map<String, int> levels) {
    final worst = levels.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return const {
      'rain': '우비',
      'wind': '방풍',
      'cold': '방한',
      'heat': '더위 대비',
    }[worst.key]!;
  }

  /// 백엔드 _filter_by_round_window와 동일: 티오프 1시간 전 ~ 5시간 후
  static List<ForecastItem> _roundWindow(
    List<ForecastItem> forecast,
    int? startHour,
  ) {
    if (startHour == null) return forecast;
    final start = (startHour - 1).clamp(0, 23);
    final end = (startHour + 5).clamp(0, 23);
    final filtered = forecast.where((f) {
      if (f.time.length < 2) return false;
      final h = int.tryParse(f.time.substring(0, 2));
      return h != null && h >= start && h <= end;
    }).toList();
    return filtered.isEmpty ? forecast : filtered;
  }
}
