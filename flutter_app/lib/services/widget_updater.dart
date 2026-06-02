import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../models/golf_event.dart';
import '../models/weather_data.dart';

/// 잠금화면/홈화면 위젯 데이터 업데이트
///
/// home_widget 패키지가 Flutter ↔ 네이티브(iOS WidgetKit / Android AppWidget) 브릿지 역할
class WidgetUpdater {
  static const _appGroupId = 'group.com.weatherapp.widget';
  static const _iOSWidgetName = 'GolfWeatherWidget';
  static const _androidWidgetName = 'GolfWeatherWidgetProvider';

  /// 앱 시작 시 1회 초기화
  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// 골프 일정 + 날씨 데이터를 위젯에 반영
  static Future<void> updateGolfWidget({
    required GolfEvent event,
    required GolfWeatherData weather,
  }) async {
    final rec = weather.aiRecommendation;
    final policy = weather.cancellationPolicy;

    // 위젯에 전달할 키-값 저장 (네이티브에서 읽음)
    await Future.wait([
      HomeWidget.saveWidgetData('dday_label', event.ddayLabel),
      HomeWidget.saveWidgetData('course_name', event.courseName ?? event.title),
      HomeWidget.saveWidgetData('forecast_date', event.formattedDate),
      HomeWidget.saveWidgetData('status', rec.status),           // GREEN/YELLOW/RED
      HomeWidget.saveWidgetData('status_message', rec.message),
      HomeWidget.saveWidgetData('temp', _tempSummary(weather.forecast)),
      HomeWidget.saveWidgetData('rain_prob', _rainSummary(weather.forecast)),
      HomeWidget.saveWidgetData('wind_speed', _windSummary(weather.forecast)),
      HomeWidget.saveWidgetData('cancel_message', policy.message),
      HomeWidget.saveWidgetData('cancel_urgency', policy.urgency),
      HomeWidget.saveWidgetData('can_cancel_free', policy.canCancelFree?.toString() ?? 'null'),
      HomeWidget.saveWidgetData('last_updated', DateTime.now().toIso8601String()),
    ]);

    await _triggerUpdate();
  }

  /// 배낚시 일정 + 해양 날씨를 위젯에 반영
  static Future<void> updateMarineWidget({
    required FishingEvent event,
    required MarineWeatherData weather,
  }) async {
    final rec = weather.aiRecommendation;
    final warning = weather.warning;

    await Future.wait([
      HomeWidget.saveWidgetData('dday_label', event.ddayLabel),
      HomeWidget.saveWidgetData('course_name', weather.spotName),
      HomeWidget.saveWidgetData('forecast_date', '낚시 출조'),
      HomeWidget.saveWidgetData('status', rec.status),
      HomeWidget.saveWidgetData('status_message', rec.message),
      HomeWidget.saveWidgetData('wave_height', '${weather.current.waveHeight}m'),
      HomeWidget.saveWidgetData('wind_speed', '${weather.current.windSpeed}m/s'),
      HomeWidget.saveWidgetData('golden_time', weather.goldenTime),
      HomeWidget.saveWidgetData('departure_blocked', warning.departureBlocked.toString()),
      HomeWidget.saveWidgetData('warning_level', warning.level),
      HomeWidget.saveWidgetData('last_updated', DateTime.now().toIso8601String()),
    ]);

    await _triggerUpdate();
  }

  /// 데이터 없을 때 위젯 초기화 상태 표시
  static Future<void> showNoEventWidget() async {
    await Future.wait([
      HomeWidget.saveWidgetData('status', 'NONE'),
      HomeWidget.saveWidgetData('status_message', '예정된 야외 일정 없음'),
      HomeWidget.saveWidgetData('dday_label', ''),
    ]);
    await _triggerUpdate();
  }

  static Future<void> _triggerUpdate() async {
    await HomeWidget.updateWidget(
      iOSName: _iOSWidgetName,
      androidName: _androidWidgetName,
    );
  }

  // ── 예보 요약 헬퍼 ───────────────────────────────────────────────

  static String _tempSummary(List<ForecastItem> fc) {
    if (fc.isEmpty) return '--°C';
    final temps = fc.map((e) => e.temp).toList();
    final min = temps.reduce((a, b) => a < b ? a : b);
    final max = temps.reduce((a, b) => a > b ? a : b);
    return '${min.toInt()}~${max.toInt()}°C';
  }

  static String _rainSummary(List<ForecastItem> fc) {
    if (fc.isEmpty) return '--%';
    final max = fc.map((e) => e.rainProb).reduce((a, b) => a > b ? a : b);
    return '$max%';
  }

  static String _windSummary(List<ForecastItem> fc) {
    if (fc.isEmpty) return '--m/s';
    final max = fc.map((e) => e.windSpeed).reduce((a, b) => a > b ? a : b);
    return '${max.toStringAsFixed(1)}m/s';
  }
}
