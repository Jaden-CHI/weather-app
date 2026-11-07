import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko')
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'Golf Windy'**
  String get appTitle;

  /// No description provided for @commonConfirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get commonConfirm;

  /// No description provided for @commonCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get commonEdit;

  /// No description provided for @commonClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get commonRetry;

  /// No description provided for @commonSearch.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get commonSearch;

  /// No description provided for @commonLoading.
  ///
  /// In ko, this message translates to:
  /// **'불러오는 중…'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했어요'**
  String get commonError;

  /// No description provided for @commonNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get commonNone;

  /// No description provided for @commonDone.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get commonDone;

  /// No description provided for @commonNext.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get commonNext;

  /// No description provided for @commonSkip.
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기'**
  String get commonSkip;

  /// No description provided for @commonStart.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get commonStart;

  /// No description provided for @navHome.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get navHome;

  /// No description provided for @navSchedule.
  ///
  /// In ko, this message translates to:
  /// **'일정'**
  String get navSchedule;

  /// No description provided for @navMap.
  ///
  /// In ko, this message translates to:
  /// **'지도'**
  String get navMap;

  /// No description provided for @navSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get navSettings;

  /// No description provided for @setTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get setTitle;

  /// No description provided for @setSectionTheme.
  ///
  /// In ko, this message translates to:
  /// **'테마 · THEME'**
  String get setSectionTheme;

  /// No description provided for @setSectionThresholds.
  ///
  /// In ko, this message translates to:
  /// **'알림 임계값'**
  String get setSectionThresholds;

  /// No description provided for @setRainThresholdLabel.
  ///
  /// In ko, this message translates to:
  /// **'강수 확률 기준'**
  String get setRainThresholdLabel;

  /// No description provided for @setWindThresholdLabel.
  ///
  /// In ko, this message translates to:
  /// **'풍속 기준'**
  String get setWindThresholdLabel;

  /// No description provided for @setThresholdHint.
  ///
  /// In ko, this message translates to:
  /// **'이 임계값 초과 시 YELLOW/RED 권고가 발령됩니다'**
  String get setThresholdHint;

  /// No description provided for @setSectionRoundProfile.
  ///
  /// In ko, this message translates to:
  /// **'라운드 성향'**
  String get setSectionRoundProfile;

  /// No description provided for @setSensitivityRain.
  ///
  /// In ko, this message translates to:
  /// **'비 민감도'**
  String get setSensitivityRain;

  /// No description provided for @setSensitivityWind.
  ///
  /// In ko, this message translates to:
  /// **'바람 민감도'**
  String get setSensitivityWind;

  /// No description provided for @setSensitivityCold.
  ///
  /// In ko, this message translates to:
  /// **'추위 민감도'**
  String get setSensitivityCold;

  /// No description provided for @setSensitivityHeat.
  ///
  /// In ko, this message translates to:
  /// **'더위 민감도'**
  String get setSensitivityHeat;

  /// No description provided for @setSensitivityHint.
  ///
  /// In ko, this message translates to:
  /// **'민감도가 높을수록 라운드 적합도가 더 보수적으로 판정됩니다'**
  String get setSensitivityHint;

  /// No description provided for @setSectionNotifyTiming.
  ///
  /// In ko, this message translates to:
  /// **'알림 타이밍'**
  String get setSectionNotifyTiming;

  /// No description provided for @setNotifyTimingQuestion.
  ///
  /// In ko, this message translates to:
  /// **'일정 몇 시간 전부터 알림을 받을까요?'**
  String get setNotifyTimingQuestion;

  /// No description provided for @setHoursBefore.
  ///
  /// In ko, this message translates to:
  /// **'{h}시간 전'**
  String setHoursBefore(int h);

  /// No description provided for @setSectionNotifyPermission.
  ///
  /// In ko, this message translates to:
  /// **'알림 권한'**
  String get setSectionNotifyPermission;

  /// No description provided for @setNotifyPermissionButton.
  ///
  /// In ko, this message translates to:
  /// **'알림 권한 요청 / 재등록'**
  String get setNotifyPermissionButton;

  /// No description provided for @setNotifyGranted.
  ///
  /// In ko, this message translates to:
  /// **'알림 권한이 허용되었습니다.'**
  String get setNotifyGranted;

  /// No description provided for @setNotifyDenied.
  ///
  /// In ko, this message translates to:
  /// **'알림 권한이 거부되었습니다.'**
  String get setNotifyDenied;

  /// No description provided for @setSectionHelp.
  ///
  /// In ko, this message translates to:
  /// **'도움말'**
  String get setSectionHelp;

  /// No description provided for @setHelpDesc.
  ///
  /// In ko, this message translates to:
  /// **'핵심 기능 안내를 다시 열 수 있습니다.'**
  String get setHelpDesc;

  /// No description provided for @setHelpTutorialButton.
  ///
  /// In ko, this message translates to:
  /// **'튜토리얼 다시 보기'**
  String get setHelpTutorialButton;

  /// No description provided for @setSectionScore.
  ///
  /// In ko, this message translates to:
  /// **'스코어'**
  String get setSectionScore;

  /// No description provided for @setScoreDesc.
  ///
  /// In ko, this message translates to:
  /// **'OCR 스캔과 지난 라운드 기록 관리를 여기서 바로 열 수 있습니다.'**
  String get setScoreDesc;

  /// No description provided for @setScoreOpenButton.
  ///
  /// In ko, this message translates to:
  /// **'스코어 관리 열기'**
  String get setScoreOpenButton;

  /// No description provided for @setSectionDevice.
  ///
  /// In ko, this message translates to:
  /// **'디바이스 정보'**
  String get setSectionDevice;

  /// No description provided for @setDeviceTokenLabel.
  ///
  /// In ko, this message translates to:
  /// **'익명 디바이스 토큰'**
  String get setDeviceTokenLabel;

  /// No description provided for @setDeviceTokenLoading.
  ///
  /// In ko, this message translates to:
  /// **'로딩 중...'**
  String get setDeviceTokenLoading;

  /// No description provided for @setDevicePrivacyNote.
  ///
  /// In ko, this message translates to:
  /// **'이 앱은 개인정보를 수집하지 않습니다. 위 토큰은 알림 발송에만 사용되는 임의 식별자입니다.'**
  String get setDevicePrivacyNote;

  /// No description provided for @setLanguageSection.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get setLanguageSection;

  /// No description provided for @setLanguageTitle.
  ///
  /// In ko, this message translates to:
  /// **'앱 언어'**
  String get setLanguageTitle;

  /// No description provided for @setLanguageSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정 따름'**
  String get setLanguageSystem;

  /// No description provided for @setLanguageKorean.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get setLanguageKorean;

  /// No description provided for @setLanguageEnglish.
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get setLanguageEnglish;

  /// No description provided for @whatsNewTitle.
  ///
  /// In ko, this message translates to:
  /// **'업데이트 안내'**
  String get whatsNewTitle;

  /// No description provided for @whatsNewSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'v{version}의 새로운 기능이에요.'**
  String whatsNewSubtitle(String version);

  /// No description provided for @suitRed.
  ///
  /// In ko, this message translates to:
  /// **'D-{dday} 취소 권고 — {label} 주의보'**
  String suitRed(int dday, String label);

  /// No description provided for @suitYellow.
  ///
  /// In ko, this message translates to:
  /// **'D-{dday} 주의 — {label} 준비'**
  String suitYellow(int dday, String label);

  /// No description provided for @suitGreen.
  ///
  /// In ko, this message translates to:
  /// **'D-{dday} 라운딩 적합'**
  String suitGreen(int dday);

  /// No description provided for @suitWorstRain.
  ///
  /// In ko, this message translates to:
  /// **'악천후'**
  String get suitWorstRain;

  /// No description provided for @suitWorstWind.
  ///
  /// In ko, this message translates to:
  /// **'강풍'**
  String get suitWorstWind;

  /// No description provided for @suitWorstCold.
  ///
  /// In ko, this message translates to:
  /// **'한파'**
  String get suitWorstCold;

  /// No description provided for @suitWorstHeat.
  ///
  /// In ko, this message translates to:
  /// **'폭염'**
  String get suitWorstHeat;

  /// No description provided for @suitPrepRain.
  ///
  /// In ko, this message translates to:
  /// **'우비'**
  String get suitPrepRain;

  /// No description provided for @suitPrepWind.
  ///
  /// In ko, this message translates to:
  /// **'방풍'**
  String get suitPrepWind;

  /// No description provided for @suitPrepCold.
  ///
  /// In ko, this message translates to:
  /// **'방한'**
  String get suitPrepCold;

  /// No description provided for @suitPrepHeat.
  ///
  /// In ko, this message translates to:
  /// **'더위 대비'**
  String get suitPrepHeat;

  /// No description provided for @suitDetailRainProb.
  ///
  /// In ko, this message translates to:
  /// **'강수확률 {p}%'**
  String suitDetailRainProb(int p);

  /// No description provided for @suitDetailWind.
  ///
  /// In ko, this message translates to:
  /// **'풍속 {w}m/s'**
  String suitDetailWind(String w);

  /// No description provided for @suitDetailMinTemp.
  ///
  /// In ko, this message translates to:
  /// **'최저 {t}°C'**
  String suitDetailMinTemp(int t);

  /// No description provided for @suitDetailMaxTemp.
  ///
  /// In ko, this message translates to:
  /// **'최고 {t}°C'**
  String suitDetailMaxTemp(int t);

  /// No description provided for @suitDetailLightning.
  ///
  /// In ko, this message translates to:
  /// **'낙뢰 예보'**
  String get suitDetailLightning;

  /// No description provided for @suitDetailProfileApplied.
  ///
  /// In ko, this message translates to:
  /// **' — 내 라운드 성향 반영 판정'**
  String get suitDetailProfileApplied;

  /// No description provided for @weatherPendingMessage.
  ///
  /// In ko, this message translates to:
  /// **'날씨 정보가 아직 준비 중입니다.\n골프장 DB에는 등록되어 있지만 해당 위치의 예보 캐시가 아직 수집되지 않았거나, 좌표 보정이 필요할 수 있어요. 잠시 후 다시 확인하거나 일정의 골프장명을 수정해 주세요.'**
  String get weatherPendingMessage;

  /// No description provided for @weatherUnavailableMessage.
  ///
  /// In ko, this message translates to:
  /// **'날씨 정보를 불러오지 못했습니다.\n네트워크 연결 또는 서버 상태를 확인해 주세요. 실기기 테스트 중이라면 설정의 API 주소가 배포 서버를 가리키는지도 확인하면 좋습니다.\n현재 주소: {url}'**
  String weatherUnavailableMessage(String url);

  /// No description provided for @splashTagline.
  ///
  /// In ko, this message translates to:
  /// **'스마트한 라운드 관리'**
  String get splashTagline;

  /// No description provided for @mapCourseLocation.
  ///
  /// In ko, this message translates to:
  /// **'골프장 위치'**
  String get mapCourseLocation;

  /// No description provided for @themeSubtitleFairwaySky.
  ///
  /// In ko, this message translates to:
  /// **'쿨 틸 · 다크'**
  String get themeSubtitleFairwaySky;

  /// No description provided for @themeSubtitleLightAir.
  ///
  /// In ko, this message translates to:
  /// **'오프화이트 · 라이트'**
  String get themeSubtitleLightAir;

  /// No description provided for @themeSubtitleMidnightLime.
  ///
  /// In ko, this message translates to:
  /// **'네이비 + 라임 · 다크'**
  String get themeSubtitleMidnightLime;

  /// No description provided for @notifChannelName.
  ///
  /// In ko, this message translates to:
  /// **'날씨 알림'**
  String get notifChannelName;

  /// No description provided for @notifChannelDesc.
  ///
  /// In ko, this message translates to:
  /// **'골프·낚시 일정 기상 변화 알림'**
  String get notifChannelDesc;

  /// No description provided for @sensitivityLow.
  ///
  /// In ko, this message translates to:
  /// **'둔감'**
  String get sensitivityLow;

  /// No description provided for @sensitivityNormal.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get sensitivityNormal;

  /// No description provided for @sensitivityHigh.
  ///
  /// In ko, this message translates to:
  /// **'민감'**
  String get sensitivityHigh;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
