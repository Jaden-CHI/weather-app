import 'package:workmanager/workmanager.dart';
import 'app_schedule_service.dart';
import 'weather_api_service.dart';
import 'widget_updater.dart';

const _taskName = 'weatherWidgetRefresh';
const _taskTag = 'com.weatherapp.widget.refresh';

/// Workmanager 콜백 (백그라운드에서 실행 — Flutter isolate 밖)
@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != _taskName) return Future.value(true);

    try {
      await WidgetUpdater.init();
      final scheduleService = AppScheduleService();
      final apiService = WeatherApiService.instance;

      // 1. 가장 임박한 골프 일정 확인
      final golfEvent = await scheduleService.getNextGolfSchedule();
      if (golfEvent != null) {
        // course_id 매핑
        String? courseId = golfEvent.courseId;
        if (courseId == null) {
          final hint = golfEvent.courseName ?? golfEvent.title;
          courseId = await apiService.searchCourseId(hint);
        }
        if (courseId != null) {
          final weather = await apiService.getGolfWeather(
            courseId,
            dday: golfEvent.dday.clamp(0, 7),
          );
          if (weather != null) {
            await WidgetUpdater.updateGolfWidget(
              event: golfEvent.copyWith(courseId: courseId),
              weather: weather,
            );
            return Future.value(true);
          }
        }
      }

      // 2. 골프 일정 없으면 위젯 빈 상태
      await WidgetUpdater.showNoEventWidget();
      return Future.value(true);
    } catch (e) {
      return Future.value(false); // false = Workmanager 재시도
    }
  });
}

/// 백그라운드 서비스 초기화 + 주기 등록
class BackgroundService {
  static Future<void> init() async {
    await Workmanager().initialize(
      backgroundDispatcher,
      isInDebugMode: false,
    );
  }

  /// 1시간마다 위젯 갱신 등록
  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      _taskTag,
      _taskName,
      frequency: const Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  /// 즉시 1회 실행 (앱 포그라운드 진입 시)
  static Future<void> runOnce() async {
    await Workmanager().registerOneOffTask(
      '${_taskTag}_once',
      _taskName,
      initialDelay: Duration.zero,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }
}
