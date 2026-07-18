import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/main.dart';

void main() {
  testWidgets('Golf Windy app builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: WeatherApp(),
      ),
    );

    expect(find.text('Golf Windy'), findsOneWidget);
  });
}
