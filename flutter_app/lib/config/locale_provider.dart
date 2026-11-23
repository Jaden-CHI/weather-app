import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../services/settings_service.dart';

/// 앱 언어 설정: 'system' / 'ko' / 'en'
class AppLanguageNotifier extends StateNotifier<String> {
  AppLanguageNotifier() : super('system') {
    _load();
  }

  Future<void> _load() async {
    state = await SettingsService.instance.getAppLanguage();
    _syncGlobal();
  }

  Future<void> set(String value) async {
    state = value;
    await SettingsService.instance.setAppLanguage(value);
    _syncGlobal();
  }

  void _syncGlobal() {
    L10n.setLocale(
      L10n.resolve(state, ui.PlatformDispatcher.instance.locales),
    );
  }
}

final appLanguageProvider =
    StateNotifierProvider<AppLanguageNotifier, String>(
  (ref) => AppLanguageNotifier(),
);

/// MaterialApp.locale 값 (null이면 시스템 로케일 사용)
final appLocaleProvider = Provider<Locale?>((ref) {
  final language = ref.watch(appLanguageProvider);
  switch (language) {
    case 'ko':
      return const Locale('ko');
    case 'en':
      return const Locale('en');
    default:
      return null;
  }
});
