import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/models/golf_event.dart';
import 'package:weather_app/models/weather_data.dart';
import 'package:weather_app/services/widget_sync_service.dart';

void main() {
  GolfEvent event(String title, {int days = 1}) => GolfEvent(
        id: 'round', title: title,
        startDate: DateTime.now().add(Duration(days: days)),
      );

  test('deletion during a request clears the widget instead of restoring it', () async {
    GolfEvent? current = event('삭제할 라운드');
    final started = Completer<void>();
    final response = Completer<GolfWeatherData?>();
    final published = <GolfEvent?>[];
    final service = WidgetSyncService(
      initialize: () async {},
      loadNextEvent: () async => current,
      loadWeather: (_) { started.complete(); return response.future; },
      publish: (event, weather, message) async { published.add(event); },
    );
    final first = service.syncNextGolfEvent();
    await started.future;
    current = null;
    final second = service.syncNextGolfEvent();
    response.complete(null);
    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(published.map((e) => e?.title), ['삭제할 라운드', null]);
  });

  test('an edited event is reloaded even without another refresh request', () async {
    GolfEvent? current = event('이전 시간');
    final started = Completer<void>();
    final response = Completer<GolfWeatherData?>();
    final requested = <String>[];
    final published = <String?>[];
    final service = WidgetSyncService(
      initialize: () async {},
      loadNextEvent: () async => current,
      loadWeather: (event) async {
        requested.add(event.title);
        if (requested.length == 1) {
          started.complete();
          return response.future;
        }
        return null;
      },
      publish: (event, weather, message) async { published.add(event?.title); },
    );
    final refresh = service.syncNextGolfEvent();
    await started.future;
    current = event('수정한 시간', days: 2);
    response.complete(null);
    expect(await refresh, isFalse); // New event's network failure is retryable.
    expect(requested, ['이전 시간', '수정한 시간']);
    expect(published, ['이전 시간', '수정한 시간', '수정한 시간']);
  });

  test('a throwing old request cannot restore a deleted event', () async {
    GolfEvent? current = event('삭제할 라운드');
    final published = <GolfEvent?>[];
    final service = WidgetSyncService(
      initialize: () async {},
      loadNextEvent: () async => current,
      loadWeather: (_) async { current = null; throw StateError('offline'); },
      publish: (event, weather, message) async { published.add(event); },
    );
    expect(await service.syncNextGolfEvent(), isFalse);
    expect(published.last, isNull);
  });

  test('events beyond the forecast horizon never request replacement weather', () async {
    final current = event('다음 달 라운드', days: 30);
    var requests = 0;
    final messages = <String>[];
    final service = WidgetSyncService(
      initialize: () async {},
      loadNextEvent: () async => current,
      loadWeather: (_) async { requests++; return null; },
      publish: (event, weather, message) async { messages.add(message); },
    );
    expect(await service.syncNextGolfEvent(), isTrue);
    expect(requests, 0);
    expect(messages.single, contains('예보 제공 전'));
  });
}
