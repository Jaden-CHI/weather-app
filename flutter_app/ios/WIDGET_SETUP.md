# iOS 홈/잠금 위젯 설정

코드에 Widget Extension 타겟이 포함되어 있습니다. **최초 1회** Apple Developer에서 App Group을 등록해야 합니다.

## 1. App Group 등록 (필수)

1. [Apple Developer → Identifiers → App Groups](https://developer.apple.com/account/resources/identifiers/list/applicationGroup)
2. `group.com.weatherapp.widget` 생성
3. Xcode에서 `Runner` 타겟 → **Signing & Capabilities** → **App Groups** → 동일 ID 체크
4. `GolfWeatherWidgetExtension` 타겟에도 동일하게 체크

> 유료 Apple Developer 계정이 필요합니다.

## 2. 위젯 추가 (시뮬레이터/기기)

1. 홈 화면 길게 누르기 → **+** → **Golf Windy** / **켜자마자 날씨**
2. 앱 실행 후 **설정 → 위젯 데이터 새로고침**
3. 일정·날씨가 로드된 상태여야 위젯에 표시됩니다.

## 3. 빌드

```bash
cd flutter_app
flutter pub get
cd ios && pod install && cd ..
flutter run
```

빌드 오류 시 Xcode에서 `ios/Runner.xcworkspace`를 열고 `GolfWeatherWidgetExtension` 스킴이 포함됐는지 확인하세요.
