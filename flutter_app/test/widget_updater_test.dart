import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/models/golf_event.dart';
import 'package:weather_app/models/weather_data.dart';
import 'package:weather_app/services/widget_updater.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('home_widget');
  final stored = <String, dynamic>{};
  var updates = 0;

  setUp(() {
    stored
      ..clear()
      ..addAll({'course_name': '지난 골프장', 'temp': '28°C',
        'rain_prob': '80%', 'wind_speed': '12m/s',
        'cancel_message': '무료 취소 가능', 'can_cancel_free': 'true'});
    updates = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'saveWidgetData') {
        final args = call.arguments as Map;
        stored[args['id'] as String] = args['data'];
      } else if (call.method == 'updateWidget') {
        updates++;
      }
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('deleting last event clears old weather and cancellation information', () async {
    await WidgetUpdater.showNoEventWidget();
    expect(stored['course_name'], 'Golf Windy');
    expect(stored['status'], 'NONE');
    for (final key in ['temp', 'rain_prob', 'wind_speed', 'cancel_message']) {
      expect(stored[key], isEmpty);
    }
    expect(stored['can_cancel_free'], 'null');
    expect(stored['status_message'], isNotEmpty);
    expect(updates, 1);
  });

  test('network failure retains the upcoming event without old weather', () async {
    final event = GolfEvent(id: 'next', title: '다음 라운드',
        startDate: DateTime.now().add(const Duration(days: 1)));
    await WidgetUpdater.showUnavailableWidget(event: event, message: '예보 확인 필요');
    expect(stored['course_name'], '다음 라운드');
    expect(stored['dday_label'], event.ddayLabel);
    expect(stored['status'], 'UNKNOWN');
    expect(stored['temp'], isEmpty);
    expect(stored['cancel_message'], isEmpty);
    expect(updates, 1);
  });

  test('old server sample terms cannot claim free cancellation', () {
    final policy = CancellationPolicy.fromJson({
      'policy_source': 'FALLBACK', 'can_cancel_free': true,
      'message': '무료 취소 가능', 'deadline_str': '10/15 06:37',
    });
    expect(policy.canCancelFree, isNull);
    expect(policy.deadlineStr, isNull);
    expect(policy.message, '취소 규정은 예약처에 확인해 주세요');
  });
}
