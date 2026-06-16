import 'package:flutter/foundation.dart';
import 'app_schedule_service.dart';
import 'weather_api_service.dart';
import 'widget_updater.dart';

/// 포그라운드에서 홈/잠금 위젯 데이터 동기화
class WidgetSyncService {
  WidgetSyncService._();
  static final instance = WidgetSyncService._();

  Future<void> syncNextGolfEvent() async {
    try {
      final scheduleService = AppScheduleService();
      final api = WeatherApiService.instance;
      final event = await scheduleService.getNextGolfSchedule();

      if (event == null) {
        await WidgetUpdater.showNoEventWidget();
        return;
      }

      var courseId = event.courseId;
      courseId ??= await api.searchCourseId(event.courseName ?? event.title);
      if (courseId == null || courseId.isEmpty) {
        await WidgetUpdater.showNoEventWidget();
        return;
      }

      final weather = await api.getGolfWeather(
        courseId,
        dday: event.dday.clamp(0, 7),
        startHour: event.startDate.hour,
      );
      if (weather == null) {
        await WidgetUpdater.showNoEventWidget();
        return;
      }

      await WidgetUpdater.updateGolfWidget(
        event: event.copyWith(courseId: courseId),
        weather: weather,
      );
    } catch (e, st) {
      debugPrint('Widget sync failed: $e\n$st');
    }
  }
}
