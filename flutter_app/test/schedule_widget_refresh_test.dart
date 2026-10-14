import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/services/app_schedule_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all saved schedule changes notify widget listeners after persistence', () async {
    SharedPreferences.setMockInitialValues({});
    final service = AppScheduleService();
    final snapshots = <Future<Map<String, Map<String, dynamic>>>>[];
    void onChange() { snapshots.add(service.exportSchedules()); }
    AppScheduleService.changes.addListener(onChange);
    addTearDown(() => AppScheduleService.changes.removeListener(onChange));

    await service.addGolfSchedule(
      title: '테스트 라운드', locationName: '테스트 골프장',
      startAt: DateTime.now().add(const Duration(days: 1)),
      notifyBeforeHours: 24, weatherAlertEnabled: true,
    );
    expect(snapshots, hasLength(1));
    final saved = await snapshots.last;
    final id = saved.keys.single;
    expect(saved[id]!['title'], '테스트 라운드');

    await service.updateSchedule(id, {'title': '변경한 라운드'});
    expect(snapshots, hasLength(2));
    expect((await snapshots.last)[id]!['title'], '변경한 라운드');

    await service.deleteSchedule(id);
    expect(snapshots, hasLength(3));
    expect(await snapshots.last, isEmpty);

    await service.importSchedules(saved);
    expect(snapshots, hasLength(4));
    expect((await snapshots.last)[id]!['title'], '테스트 라운드');
  });
}
