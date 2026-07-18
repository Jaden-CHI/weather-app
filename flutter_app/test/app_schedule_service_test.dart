import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/services/app_schedule_service.dart';

void main() {
  group('AppScheduleService', () {
    test('깨진 로컬 일정 캐시는 빈 목록으로 처리하고 삭제한다', () async {
      SharedPreferences.setMockInitialValues({
        'flutter.golf_schedules_v2': '{broken:{json',
      });

      final schedules = await AppScheduleService().getUpcomingGolfSchedules();
      final prefs = await SharedPreferences.getInstance();

      expect(schedules, isEmpty);
      expect(prefs.getString('golf_schedules_v2'), isNull);
    });
  });
}
