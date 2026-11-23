import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/app_theme.dart';
import 'config/locale_provider.dart';
import 'firebase_options.dart';
import 'l10n/l10n.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';
import 'services/widget_updater.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // 익명 인증 (사용자 데이터 접근 필요)
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }
  await WidgetUpdater.init();
  await BackgroundService.init();
  await BackgroundService.registerPeriodicTask();
  await NotificationService.instance.init();
  runApp(const ProviderScope(child: WeatherApp()));
}

class WeatherApp extends ConsumerWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(gwThemeProvider);
    final locale = ref.watch(appLocaleProvider);
    return MaterialApp(
      title: 'Golf Windy',
      debugShowCheckedModeBanner: false,
      theme: theme.toThemeData(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeListResolutionCallback: (deviceLocales, supported) {
        for (final device in deviceLocales ?? const <Locale>[]) {
          if (device.languageCode == 'ko') return const Locale('ko');
          if (device.languageCode == 'en') return const Locale('en');
        }
        return const Locale('en');
      },
      builder: (context, child) {
        // 서비스 코드(L10n.current)가 화면과 같은 언어를 쓰도록 동기화
        L10n.current = AppLocalizations.of(context);
        return child!;
      },
      home: const HomeScreen(),
    );
  }
}
