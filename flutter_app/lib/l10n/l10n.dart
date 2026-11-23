import 'package:flutter/widgets.dart';

import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

/// 화면 코드에서 `context.l10n.key` 로 짧게 접근
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// BuildContext가 없는 서비스 코드용 전역 접근자.
///
/// MaterialApp.builder와 백그라운드 isolate 초기화에서 갱신된다.
class L10n {
  L10n._();

  static AppLocalizations current = lookupAppLocalizations(const Locale('ko'));

  /// 저장된 언어 설정('system'/'ko'/'en')과 기기 언어로 로케일 결정
  static Locale resolve(String saved, List<Locale> deviceLocales) {
    switch (saved) {
      case 'ko':
        return const Locale('ko');
      case 'en':
        return const Locale('en');
      default:
        for (final locale in deviceLocales) {
          if (locale.languageCode == 'ko') return const Locale('ko');
          if (locale.languageCode == 'en') return const Locale('en');
        }
        return const Locale('en');
    }
  }

  /// 서비스/백그라운드 코드에서 로케일을 반영
  static void setLocale(Locale locale) {
    current = lookupAppLocalizations(
      AppLocalizations.supportedLocales.firstWhere(
        (l) => l.languageCode == locale.languageCode,
        orElse: () => const Locale('en'),
      ),
    );
  }
}
