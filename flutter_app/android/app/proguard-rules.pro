# Flutter 엔진/임베딩 (Flutter가 기본 keep 규칙을 제공하지만 명시적으로 유지)
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# Flutter 지연 컴포넌트용 Play Core 참조 (미사용이지만 R8 missing-class 경고 방지)
-dontwarn com.google.android.play.core.**

# flutter_local_notifications (리플렉션/직렬화 사용)
-keep class com.dexterous.** { *; }

# workmanager 콜백
-keep class dev.fluttercommunity.workmanager.** { *; }

# home_widget 위젯 프로바이더 (AndroidManifest에서 리플렉션으로 참조)
-keep class com.weatherapp.weather_app.** { *; }

# Kotlin 메타데이터/코루틴
-dontwarn kotlinx.coroutines.**
