import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/app_theme.dart';
import 'firebase_options.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';
import 'services/widget_updater.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    return MaterialApp(
      title: 'Golf Windy',
      debugShowCheckedModeBanner: false,
      theme: theme.toThemeData(),
      home: const HomeScreen(),
    );
  }
}
