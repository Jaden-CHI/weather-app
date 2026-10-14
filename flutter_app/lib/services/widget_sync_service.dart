import 'package:flutter/foundation.dart';
import '../models/golf_event.dart';
import '../models/weather_data.dart';
import 'app_schedule_service.dart';
import 'weather_api_service.dart';
import 'widget_updater.dart';

/// Foreground and background use the same empty/error/forecast states.
class WidgetSyncService {
  WidgetSyncService._()
      : this(
          loadNextEvent: () => AppScheduleService().getNextGolfSchedule(),
          loadWeather: _loadWeatherForEvent,
          initialize: WidgetUpdater.init,
          publish: _publishWidget,
        );

  @visibleForTesting
  WidgetSyncService({
    required Future<GolfEvent?> Function() loadNextEvent,
    required Future<GolfWeatherData?> Function(GolfEvent) loadWeather,
    required Future<void> Function() initialize,
    required Future<void> Function(GolfEvent?, GolfWeatherData?, String) publish,
  })  : _loadNextEvent = loadNextEvent,
        _loadWeather = loadWeather,
        _initialize = initialize,
        _publish = publish;

  static final instance = WidgetSyncService._();
  final Future<GolfEvent?> Function() _loadNextEvent;
  final Future<GolfWeatherData?> Function(GolfEvent) _loadWeather;
  final Future<void> Function() _initialize;
  final Future<void> Function(GolfEvent?, GolfWeatherData?, String) _publish;
  Future<bool>? _activeSync;
  bool _syncAgain = false;

  Future<bool> syncNextGolfEvent() {
    _syncAgain = true;
    // Serialize writes in this isolate and coalesce overlapping requests.
    return _activeSync ??= _drain().whenComplete(() {
      _activeSync = null;
    });
  }

  Future<bool> _drain() async {
    bool result;
    do {
      _syncAgain = false;
      result = await _sync();
    } while (_syncAgain);
    return result;
  }

  Future<bool> _sync() async {
    try {
      await _initialize();
      final event = await _loadNextEvent();
      if (event == null) {
        await _publish(null, null, '앱을 열어 라운드를 등록해 주세요');
        return true;
      }
      if (event.dday < 0 || event.dday > 7) {
        await _publish(event, null, '아직 예보 제공 전 · 라운드 7일 전부터 확인하세요');
        return true;
      }

      // Show the schedule before networking; never leave another round's data.
      await _publish(event, null, '날씨 확인 중 · 눌러서 앱 열기');
      final weather = await _loadWeather(event);
      final latest = await _loadNextEvent();
      // A schedule may have changed while the request was in flight, including
      // changes made by another isolate. Fetch the current schedule again.
      if (_syncAgain || !_sameEvent(event, latest)) {
        _syncAgain = true;
        return true;
      }
      if (weather == null || weather.forecast.isEmpty) {
        await _publish(event, null, '날씨를 확인하지 못했습니다 · 앱에서 다시 확인');
        return false;
      }
      await _publish(event, weather, '');
      return true;
    } catch (e, st) {
      debugPrint('Widget sync failed: $e\n$st');
      try {
        // Do not restore a deleted event even when an old request throws.
        final latest = await _loadNextEvent();
        await _publish(latest, null, latest == null
            ? '앱을 열어 라운드를 등록해 주세요'
            : '정보를 확인하지 못했습니다 · 앱에서 다시 확인');
      } catch (updateError) {
        debugPrint('Widget fallback failed: $updateError');
      }
      return false;
    }
  }

  static bool _sameEvent(GolfEvent a, GolfEvent? b) =>
      b != null && a.id == b.id && a.startDate == b.startDate &&
      a.title == b.title && a.courseId == b.courseId &&
      a.courseName == b.courseName && a.lat == b.lat && a.lng == b.lng;

  static Future<void> _publishWidget(
    GolfEvent? event, GolfWeatherData? weather, String message,
  ) {
    if (event != null && weather != null) {
      return WidgetUpdater.updateGolfWidget(event: event, weather: weather);
    }
    return WidgetUpdater.showUnavailableWidget(event: event, message: message);
  }

  static Future<GolfWeatherData?> _loadWeatherForEvent(GolfEvent event) async {
    final api = WeatherApiService.instance;
    var courseId = event.courseId;
    if (courseId == null || courseId.isEmpty) {
      courseId = await api.searchCourseId(event.courseName ?? event.title);
    }
    if (courseId != null && courseId.isNotEmpty) {
      return api.getGolfWeather(
        courseId, dday: event.dday, startHour: event.startDate.hour,
        startMinute: event.startDate.minute,
      );
    }
    if (event.lat != null && event.lng != null) {
      return api.getCustomGolfWeather(
        lat: event.lat!, lng: event.lng!,
        courseName: event.courseName ?? event.title,
        dday: event.dday, startHour: event.startDate.hour,
        startMinute: event.startDate.minute,
      );
    }
    return null;
  }
}
