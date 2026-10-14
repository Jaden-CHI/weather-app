import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'widget_sync_service.dart';

const _taskName = 'weatherWidgetRefresh';
const _taskTag = 'com.weatherapp.widget.refresh';

/// Workmanager 콜백 (백그라운드에서 실행 — Flutter isolate 밖)
@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != _taskName) return Future.value(true);

    return WidgetSyncService.instance.syncNextGolfEvent();
  });
}

/// 백그라운드 서비스 초기화 + 주기 등록
class BackgroundService {
  static Future<void> init() async {
    try {
      await Workmanager().initialize(backgroundDispatcher);
    } catch (e) {
      debugPrint('BackgroundService init skipped: $e');
    }
  }

  /// 1시간마다 위젯 갱신 등록
  static Future<void> registerPeriodicTask() async {
    try {
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
    } catch (e) {
      debugPrint('BackgroundService periodic task skipped: $e');
    }
  }

  /// 즉시 1회 실행 (앱 포그라운드 진입 시)
  static Future<void> runOnce() async {
    try {
      await Workmanager().registerOneOffTask(
        '${_taskTag}_once',
        _taskName,
        initialDelay: Duration.zero,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } catch (e) {
      debugPrint('BackgroundService one-off task skipped: $e');
    }
  }

  static Future<void> cancelAll() async {
    try {
      await Workmanager().cancelAll();
    } catch (e) {
      debugPrint('BackgroundService cancel skipped: $e');
    }
  }
}
