import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/main.dart';
import 'package:weather_app/screens/home_screen.dart';

void main() {
  testWidgets('Golf Windy app builds and shows home', (tester) async {
    // 테스트 환경에는 플러그인 채널이 없으므로 SharedPreferences를 모킹하고,
    // 튜토리얼을 본 상태로 두어 첫 프레임에 다이얼로그가 뜨지 않게 한다.
    SharedPreferences.setMockInitialValues({
      'setting_home_tutorial_seen': true,
    });

    await tester.pumpWidget(const ProviderScope(child: WeatherApp()));
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
    // 하단 탭바가 첫 프레임에 렌더링되는지 확인
    for (final label in ['홈', '일정', '지도', '설정']) {
      expect(find.text(label), findsOneWidget);
    }
  });
}
