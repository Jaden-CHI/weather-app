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

  /// No description provided for @homeStatusGreen.
  ///
  /// In ko, this message translates to:
  /// **'최적'**
  String get homeStatusGreen;

  /// No description provided for @homeStatusYellow.
  ///
  /// In ko, this message translates to:
  /// **'주의'**
  String get homeStatusYellow;

  /// No description provided for @homeStatusRed.
  ///
  /// In ko, this message translates to:
  /// **'취소권장'**
  String get homeStatusRed;

  /// No description provided for @homeStatusNone.
  ///
  /// In ko, this message translates to:
  /// **'정보없음'**
  String get homeStatusNone;

  /// No description provided for @tutTitle.
  ///
  /// In ko, this message translates to:
  /// **'Golf Windy 빠른 안내'**
  String get tutTitle;

  /// No description provided for @tutSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'핵심 기능만 짧게 보고 바로 시작할게요.'**
  String get tutSubtitle;

  /// No description provided for @tutStep1Title.
  ///
  /// In ko, this message translates to:
  /// **'홈에서 바로 확인'**
  String get tutStep1Title;

  /// No description provided for @tutStep1Desc.
  ///
  /// In ko, this message translates to:
  /// **'다가오는 라운드와 날씨 권고를 첫 화면에서 바로 볼 수 있어요.'**
  String get tutStep1Desc;

  /// No description provided for @tutStep1Bullet1.
  ///
  /// In ko, this message translates to:
  /// **'GREEN / YELLOW / RED 권고를 빠르게 확인'**
  String get tutStep1Bullet1;

  /// No description provided for @tutStep1Bullet2.
  ///
  /// In ko, this message translates to:
  /// **'아래로 당겨 최신 예보 다시 불러오기'**
  String get tutStep1Bullet2;

  /// No description provided for @tutStep2Title.
  ///
  /// In ko, this message translates to:
  /// **'일정 등록은 간단하게'**
  String get tutStep2Title;

  /// No description provided for @tutStep2Desc.
  ///
  /// In ko, this message translates to:
  /// **'일정 탭에서 골프장을 선택하고 티오프 시간을 저장하면 준비가 끝납니다.'**
  String get tutStep2Desc;

  /// No description provided for @tutStep2Bullet1.
  ///
  /// In ko, this message translates to:
  /// **'골프장 검색 후 일정 생성'**
  String get tutStep2Bullet1;

  /// No description provided for @tutStep2Bullet2.
  ///
  /// In ko, this message translates to:
  /// **'일정 상세에서 날씨와 스코어카드 연결'**
  String get tutStep2Bullet2;

  /// No description provided for @tutStep3Title.
  ///
  /// In ko, this message translates to:
  /// **'지도와 맛집 확인'**
  String get tutStep3Title;

  /// No description provided for @tutStep3Desc.
  ///
  /// In ko, this message translates to:
  /// **'지도 탭에서 선택한 골프장 위치와 근처 식당을 함께 확인할 수 있어요.'**
  String get tutStep3Desc;

  /// No description provided for @tutStep3Bullet1.
  ///
  /// In ko, this message translates to:
  /// **'네이버 지도에서 골프장 위치 확인'**
  String get tutStep3Bullet1;

  /// No description provided for @tutStep3Bullet2.
  ///
  /// In ko, this message translates to:
  /// **'조식/중식 추천 위치를 주변 기준으로 탐색'**
  String get tutStep3Bullet2;

  /// No description provided for @tutStep4Title.
  ///
  /// In ko, this message translates to:
  /// **'OCR로 지난 라운드도 저장'**
  String get tutStep4Title;

  /// No description provided for @tutStep4Desc.
  ///
  /// In ko, this message translates to:
  /// **'스코어 관리에서 사진만 선택하면 지난 라운드 기록을 빠르게 남길 수 있어요.'**
  String get tutStep4Desc;

  /// No description provided for @tutStep4Bullet1.
  ///
  /// In ko, this message translates to:
  /// **'일정 상세 또는 스코어 관리에서 OCR 시작'**
  String get tutStep4Bullet1;

  /// No description provided for @tutStep4Bullet2.
  ///
  /// In ko, this message translates to:
  /// **'설정에서 언제든 튜토리얼 다시 보기 가능'**
  String get tutStep4Bullet2;

  /// No description provided for @tutPrev.
  ///
  /// In ko, this message translates to:
  /// **'이전'**
  String get tutPrev;

  /// No description provided for @tutFooter.
  ///
  /// In ko, this message translates to:
  /// **'튜토리얼은 설정 탭에서 언제든 다시 볼 수 있어요.'**
  String get tutFooter;

  /// No description provided for @homeCalendarError.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 오류: {error}'**
  String homeCalendarError(String error);

  /// No description provided for @homeEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'등록된 골프 일정이 없습니다'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In ko, this message translates to:
  /// **'캘린더에 골프 일정을 추가하면\n자동으로 날씨를 확인해드립니다'**
  String get homeEmptyBody;

  /// No description provided for @homeUpcomingRounds.
  ///
  /// In ko, this message translates to:
  /// **'다가오는 라운드 · {count}'**
  String homeUpcomingRounds(int count);

  /// No description provided for @homeNextRoundDday.
  ///
  /// In ko, this message translates to:
  /// **'다음 라운드 · D-DAY'**
  String get homeNextRoundDday;

  /// No description provided for @homeNextRoundDdayN.
  ///
  /// In ko, this message translates to:
  /// **'다음 라운드 · D-{n}'**
  String homeNextRoundDdayN(int n);

  /// No description provided for @homeTeeOffAt.
  ///
  /// In ko, this message translates to:
  /// **'{date} {time} 티오프'**
  String homeTeeOffAt(String date, String time);

  /// No description provided for @homeFeelsLikeInline.
  ///
  /// In ko, this message translates to:
  /// **' · 체감 {temp}°'**
  String homeFeelsLikeInline(int temp);

  /// No description provided for @homeTeeOffForecast.
  ///
  /// In ko, this message translates to:
  /// **'티오프 시간대 예보'**
  String get homeTeeOffForecast;

  /// No description provided for @homeForecastNotYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 예보 제공 전 · 라운드 7일 전부터 확인하세요'**
  String get homeForecastNotYet;

  /// No description provided for @homeAlertSevere.
  ///
  /// In ko, this message translates to:
  /// **'악천후 — 취소 권고'**
  String get homeAlertSevere;

  /// No description provided for @homeAlertCaution.
  ///
  /// In ko, this message translates to:
  /// **'기상 주의'**
  String get homeAlertCaution;

  /// No description provided for @homeStatFeelsLike.
  ///
  /// In ko, this message translates to:
  /// **'체감온도'**
  String get homeStatFeelsLike;

  /// No description provided for @homeStatRainProb.
  ///
  /// In ko, this message translates to:
  /// **'강수확률'**
  String get homeStatRainProb;

  /// No description provided for @homeStatWind.
  ///
  /// In ko, this message translates to:
  /// **'바람'**
  String get homeStatWind;

  /// No description provided for @homeAiRecommend.
  ///
  /// In ko, this message translates to:
  /// **'AI 추천 · {label}'**
  String homeAiRecommend(String label);

  /// No description provided for @homeWxPreparing.
  ///
  /// In ko, this message translates to:
  /// **'날씨 정보 준비 중 · 골프장명/좌표 확인 필요'**
  String get homeWxPreparing;

  /// No description provided for @homeDeleteSchedule.
  ///
  /// In ko, this message translates to:
  /// **'일정 삭제'**
  String get homeDeleteSchedule;

  /// No description provided for @homeDeleteScheduleConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{name} 일정을 삭제할까요?'**
  String homeDeleteScheduleConfirm(String name);

  /// No description provided for @homeScheduleDeleted.
  ///
  /// In ko, this message translates to:
  /// **'일정을 삭제했습니다.'**
  String get homeScheduleDeleted;

  /// No description provided for @homeScheduleDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'일정을 삭제하지 못했습니다: {error}'**
  String homeScheduleDeleteFailed(String error);

  /// No description provided for @homeScheduleLoadError.
  ///
  /// In ko, this message translates to:
  /// **'일정 로드 오류: {error}'**
  String homeScheduleLoadError(String error);

  /// No description provided for @homeImportCalendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 가져오기'**
  String get homeImportCalendar;

  /// No description provided for @homeNextRound.
  ///
  /// In ko, this message translates to:
  /// **'다음 라운드'**
  String get homeNextRound;

  /// No description provided for @homeRainShort.
  ///
  /// In ko, this message translates to:
  /// **'강수 {prob}%'**
  String homeRainShort(int prob);

  /// No description provided for @homeMapLoadError.
  ///
  /// In ko, this message translates to:
  /// **'지도 로드 오류: {error}'**
  String homeMapLoadError(String error);

  /// No description provided for @homeMapLoading.
  ///
  /// In ko, this message translates to:
  /// **'{name} 지도 불러오는 중'**
  String homeMapLoading(String name);

  /// No description provided for @homeMapNoCoords.
  ///
  /// In ko, this message translates to:
  /// **'지도에 표시할 좌표가 없습니다.\n일정 수정에서 주소를 입력하면 위치를 표시할 수 있습니다.'**
  String get homeMapNoCoords;

  /// No description provided for @wxPolicyUnverified.
  ///
  /// In ko, this message translates to:
  /// **'취소 규정은 예약처에 확인해 주세요'**
  String get wxPolicyUnverified;

  /// No description provided for @wxTimeLabel.
  ///
  /// In ko, this message translates to:
  /// **'{h}시'**
  String wxTimeLabel(String h);

  /// No description provided for @wxTimeLabelUnknown.
  ///
  /// In ko, this message translates to:
  /// **'--시'**
  String get wxTimeLabelUnknown;

  /// No description provided for @wxRainHeavy.
  ///
  /// In ko, this message translates to:
  /// **'강한 비'**
  String get wxRainHeavy;

  /// No description provided for @wxRainLight.
  ///
  /// In ko, this message translates to:
  /// **'약한 비'**
  String get wxRainLight;

  /// No description provided for @wxRainDrizzle.
  ///
  /// In ko, this message translates to:
  /// **'한두 방울'**
  String get wxRainDrizzle;

  /// No description provided for @wxClear.
  ///
  /// In ko, this message translates to:
  /// **'맑음'**
  String get wxClear;

  /// No description provided for @wxNoInfo.
  ///
  /// In ko, this message translates to:
  /// **'정보 없음'**
  String get wxNoInfo;

  /// No description provided for @wxBoardingReport.
  ///
  /// In ko, this message translates to:
  /// **'승선신고'**
  String get wxBoardingReport;

  /// No description provided for @evtDateFmt.
  ///
  /// In ko, this message translates to:
  /// **'M/d(E)'**
  String get evtDateFmt;

  /// No description provided for @shareGolfWeatherHeader.
  ///
  /// In ko, this message translates to:
  /// **'⛳ Golf Windy — 라운드 날씨 공유'**
  String get shareGolfWeatherHeader;

  /// No description provided for @shareAiSection.
  ///
  /// In ko, this message translates to:
  /// **'[ AI 권고 ]'**
  String get shareAiSection;

  /// No description provided for @shareForecastSection.
  ///
  /// In ko, this message translates to:
  /// **'[ 시간대별 예보 ]'**
  String get shareForecastSection;

  /// No description provided for @shareForecastLine.
  ///
  /// In ko, this message translates to:
  /// **'{time}  {emoji}  {temp}°  강수 {rain}%  바람 {wind}m/s'**
  String shareForecastLine(
      String time, String emoji, int temp, int rain, String wind);

  /// No description provided for @shareCancelSection.
  ///
  /// In ko, this message translates to:
  /// **'[ 취소 안내 ]'**
  String get shareCancelSection;

  /// No description provided for @shareRainCancelPolicy.
  ///
  /// In ko, this message translates to:
  /// **'🌧️ 우천 특별 정책: {condition}'**
  String shareRainCancelPolicy(String condition);

  /// No description provided for @shareFooter.
  ///
  /// In ko, this message translates to:
  /// **'Golf Windy에서 라운드 일정과 날씨를 확인하세요.'**
  String get shareFooter;

  /// No description provided for @shareWeatherSubject.
  ///
  /// In ko, this message translates to:
  /// **'{course} 날씨 — {message}'**
  String shareWeatherSubject(String course, String message);

  /// No description provided for @shareScheduleHeader.
  ///
  /// In ko, this message translates to:
  /// **'⛳ Golf Windy — 라운드 일정 공유'**
  String get shareScheduleHeader;

  /// No description provided for @shareWeatherPending.
  ///
  /// In ko, this message translates to:
  /// **'날씨 정보는 아직 준비 중입니다. Golf Windy에서 라운드 전 날씨와 취소 권고를 다시 확인해 주세요.'**
  String get shareWeatherPending;

  /// No description provided for @shareScheduleSubject.
  ///
  /// In ko, this message translates to:
  /// **'{course} 라운드 일정'**
  String shareScheduleSubject(String course);

  /// No description provided for @shareDateFmt.
  ///
  /// In ko, this message translates to:
  /// **'M월 d일(E) HH:mm'**
  String get shareDateFmt;

  /// No description provided for @widgetNoSchedule.
  ///
  /// In ko, this message translates to:
  /// **'앱을 열어 라운드를 등록해 주세요'**
  String get widgetNoSchedule;

  /// No description provided for @widgetForecastNotReady.
  ///
  /// In ko, this message translates to:
  /// **'아직 예보 제공 전 · 라운드 7일 전부터 확인하세요'**
  String get widgetForecastNotReady;

  /// No description provided for @widgetChecking.
  ///
  /// In ko, this message translates to:
  /// **'날씨 확인 중 · 눌러서 앱 열기'**
  String get widgetChecking;

  /// No description provided for @widgetWeatherFailed.
  ///
  /// In ko, this message translates to:
  /// **'날씨를 확인하지 못했습니다 · 앱에서 다시 확인'**
  String get widgetWeatherFailed;

  /// No description provided for @widgetInfoFailed.
  ///
  /// In ko, this message translates to:
  /// **'정보를 확인하지 못했습니다 · 앱에서 다시 확인'**
  String get widgetInfoFailed;

  /// No description provided for @ocrTitle.
  ///
  /// In ko, this message translates to:
  /// **'스코어카드 OCR'**
  String get ocrTitle;

  /// No description provided for @ocrCameraAccessFailed.
  ///
  /// In ko, this message translates to:
  /// **'카메라 접근에 실패했습니다. 아래 \"앱 설정\"을 눌러 Golf Windy의 카메라 권한을 확인해 주세요.'**
  String get ocrCameraAccessFailed;

  /// No description provided for @ocrOpenAppSettings.
  ///
  /// In ko, this message translates to:
  /// **'앱 설정'**
  String get ocrOpenAppSettings;

  /// No description provided for @ocrGalleryOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'사진 선택 화면을 열지 못했습니다. 앱을 완전히 종료한 뒤 다시 시도해 주세요.'**
  String get ocrGalleryOpenFailed;

  /// No description provided for @ocrImageLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'이미지를 불러오지 못했습니다: {error}'**
  String ocrImageLoadFailed(String error);

  /// No description provided for @ocrRecognizeFailed.
  ///
  /// In ko, this message translates to:
  /// **'OCR 인식에 실패했습니다: {error}'**
  String ocrRecognizeFailed(String error);

  /// No description provided for @ocrCameraPermissionOff.
  ///
  /// In ko, this message translates to:
  /// **'카메라 권한이 꺼져 있어 OCR 촬영을 시작할 수 없습니다. 아래 \"앱 설정\"을 눌러 Golf Windy의 카메라 권한을 허용해 주세요.'**
  String get ocrCameraPermissionOff;

  /// No description provided for @ocrCameraPermissionNeeded.
  ///
  /// In ko, this message translates to:
  /// **'카메라 권한이 필요합니다. 권한을 허용한 뒤 다시 시도해 주세요.'**
  String get ocrCameraPermissionNeeded;

  /// No description provided for @ocrNoCompanionsToReview.
  ///
  /// In ko, this message translates to:
  /// **'검토가 필요한 동반자 이름이 없습니다.'**
  String get ocrNoCompanionsToReview;

  /// No description provided for @ocrReviewAllDone.
  ///
  /// In ko, this message translates to:
  /// **'좋아요, 검토가 필요한 동반자 이름을 모두 확인했어요.'**
  String get ocrReviewAllDone;

  /// No description provided for @ocrReviewProgress.
  ///
  /// In ko, this message translates to:
  /// **'검토를 {reviewed}명 진행했고, 아직 {remaining}명 남아 있습니다.'**
  String ocrReviewProgress(int reviewed, int remaining);

  /// No description provided for @ocrApplyToScorecard.
  ///
  /// In ko, this message translates to:
  /// **'현재 스코어카드에 적용'**
  String get ocrApplyToScorecard;

  /// No description provided for @ocrScanCardTitle.
  ///
  /// In ko, this message translates to:
  /// **'스코어카드 이미지 스캔'**
  String get ocrScanCardTitle;

  /// No description provided for @ocrScanCardDesc.
  ///
  /// In ko, this message translates to:
  /// **'사진 속 숫자를 읽어 홀별 타수 후보를 만듭니다. 인식 결과는 반드시 확인 후 적용하세요.'**
  String get ocrScanCardDesc;

  /// No description provided for @ocrPickPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 선택'**
  String get ocrPickPhoto;

  /// No description provided for @ocrTakePhoto.
  ///
  /// In ko, this message translates to:
  /// **'촬영'**
  String get ocrTakePhoto;

  /// No description provided for @ocrSummaryTitle.
  ///
  /// In ko, this message translates to:
  /// **'OCR 요약'**
  String get ocrSummaryTitle;

  /// No description provided for @ocrChipTotal.
  ///
  /// In ko, this message translates to:
  /// **'총합'**
  String get ocrChipTotal;

  /// No description provided for @ocrFrontNine.
  ///
  /// In ko, this message translates to:
  /// **'전반'**
  String get ocrFrontNine;

  /// No description provided for @ocrBackNine.
  ///
  /// In ko, this message translates to:
  /// **'후반'**
  String get ocrBackNine;

  /// No description provided for @ocrChipScoredCompanions.
  ///
  /// In ko, this message translates to:
  /// **'점수 동반자'**
  String get ocrChipScoredCompanions;

  /// No description provided for @ocrChipNameOnly.
  ///
  /// In ko, this message translates to:
  /// **'이름만 감지'**
  String get ocrChipNameOnly;

  /// No description provided for @ocrChipNameReview.
  ///
  /// In ko, this message translates to:
  /// **'이름 검토'**
  String get ocrChipNameReview;

  /// No description provided for @ocrChipNeeded.
  ///
  /// In ko, this message translates to:
  /// **'필요'**
  String get ocrChipNeeded;

  /// No description provided for @ocrStrokesValue.
  ///
  /// In ko, this message translates to:
  /// **'{n}타'**
  String ocrStrokesValue(int n);

  /// No description provided for @ocrPeopleValue.
  ///
  /// In ko, this message translates to:
  /// **'{n}명'**
  String ocrPeopleValue(int n);

  /// No description provided for @ocrLabelCourse.
  ///
  /// In ko, this message translates to:
  /// **'골프장'**
  String get ocrLabelCourse;

  /// No description provided for @ocrLabelRound.
  ///
  /// In ko, this message translates to:
  /// **'라운드'**
  String get ocrLabelRound;

  /// No description provided for @ocrLabelPlayer.
  ///
  /// In ko, this message translates to:
  /// **'본인'**
  String get ocrLabelPlayer;

  /// No description provided for @ocrSummaryEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'사진을 선택하거나 촬영하면 OCR 결과가 여기에 정리됩니다. 읽은 뒤에만 현재 스코어카드에 적용할 수 있어요.'**
  String get ocrSummaryEmptyHint;

  /// No description provided for @ocrSummaryChangedHint.
  ///
  /// In ko, this message translates to:
  /// **'기본 스코어카드와 다른 홀 {n}개가 반영됐어요. 전반/후반 점수 흐름과 동반자 이름을 한 번만 더 확인하면 좋습니다.'**
  String ocrSummaryChangedHint(int n);

  /// No description provided for @ocrSummaryNoChangeHint.
  ///
  /// In ko, this message translates to:
  /// **'기본 코스 정보와 큰 차이는 없어요. 그래도 손글씨 카드라면 합계와 동반자 이름은 한 번 확인해 주세요.'**
  String get ocrSummaryNoChangeHint;

  /// No description provided for @ocrMyScorePreview.
  ///
  /// In ko, this message translates to:
  /// **'내 스코어 미리보기'**
  String get ocrMyScorePreview;

  /// No description provided for @ocrMyScorePreviewDesc.
  ///
  /// In ko, this message translates to:
  /// **'전반/후반 흐름과 파 대비 결과를 보면서 이상한 홀을 바로 수정하세요.'**
  String get ocrMyScorePreviewDesc;

  /// No description provided for @ocrPuttsValue.
  ///
  /// In ko, this message translates to:
  /// **'퍼트 {n}'**
  String ocrPuttsValue(int n);

  /// No description provided for @ocrPuttsNotTracked.
  ///
  /// In ko, this message translates to:
  /// **'퍼트 미입력'**
  String get ocrPuttsNotTracked;

  /// No description provided for @ocrRawTextTitle.
  ///
  /// In ko, this message translates to:
  /// **'원문 OCR'**
  String get ocrRawTextTitle;

  /// No description provided for @ocrRawTextCopied.
  ///
  /// In ko, this message translates to:
  /// **'원문 OCR을 복사했어요.'**
  String get ocrRawTextCopied;

  /// No description provided for @ocrCopyRawText.
  ///
  /// In ko, this message translates to:
  /// **'원문 복사'**
  String get ocrCopyRawText;

  /// No description provided for @ocrCompanionCandidatesTitle.
  ///
  /// In ko, this message translates to:
  /// **'감지된 동반자 후보'**
  String get ocrCompanionCandidatesTitle;

  /// No description provided for @ocrCompanionCandidatesDesc.
  ///
  /// In ko, this message translates to:
  /// **'적용하면 아직 없는 이름만 동반자 목록에 자동 추가됩니다. 점수까지 읽힌 동반자는 이름과 홀별 타수를 바로 수정할 수 있습니다.'**
  String get ocrCompanionCandidatesDesc;

  /// No description provided for @ocrCompanionNamesNeedReview.
  ///
  /// In ko, this message translates to:
  /// **'{n}명의 이름은 확인이 필요합니다.'**
  String ocrCompanionNamesNeedReview(int n);

  /// No description provided for @ocrReviewCompanionsInOrder.
  ///
  /// In ko, this message translates to:
  /// **'검토 필요한 동반자 순서대로 보기'**
  String get ocrReviewCompanionsInOrder;

  /// No description provided for @ocrScoredCompanionsTitle.
  ///
  /// In ko, this message translates to:
  /// **'점수까지 감지된 동반자'**
  String get ocrScoredCompanionsTitle;

  /// No description provided for @ocrFlagNameCheck.
  ///
  /// In ko, this message translates to:
  /// **'이름 확인'**
  String get ocrFlagNameCheck;

  /// No description provided for @ocrFlagDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'중복 후보'**
  String get ocrFlagDuplicate;

  /// No description provided for @ocrFrontBackTotals.
  ///
  /// In ko, this message translates to:
  /// **'전반 {front} · 후반 {back}'**
  String ocrFrontBackTotals(int front, int back);

  /// No description provided for @ocrNameOnlyCandidatesTitle.
  ///
  /// In ko, this message translates to:
  /// **'이름만 감지된 동반자 후보'**
  String get ocrNameOnlyCandidatesTitle;

  /// No description provided for @ocrNameCheckChip.
  ///
  /// In ko, this message translates to:
  /// **'{name} 확인'**
  String ocrNameCheckChip(String name);

  /// No description provided for @ocrHoleEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'{n}번 홀 보정'**
  String ocrHoleEditTitle(int n);

  /// No description provided for @ocrHoleEditDesc.
  ///
  /// In ko, this message translates to:
  /// **'손글씨 카드나 흐릿한 숫자는 여기서 바로 수정하세요.'**
  String get ocrHoleEditDesc;

  /// No description provided for @ocrLabelStrokes.
  ///
  /// In ko, this message translates to:
  /// **'타수'**
  String get ocrLabelStrokes;

  /// No description provided for @ocrLabelPutts.
  ///
  /// In ko, this message translates to:
  /// **'퍼트'**
  String get ocrLabelPutts;

  /// No description provided for @ocrApplyFix.
  ///
  /// In ko, this message translates to:
  /// **'보정 반영'**
  String get ocrApplyFix;

  /// No description provided for @ocrCompanionEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'동반자 OCR 보정'**
  String get ocrCompanionEditTitle;

  /// No description provided for @ocrLabelName.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get ocrLabelName;

  /// No description provided for @ocrCompanionNameHint.
  ///
  /// In ko, this message translates to:
  /// **'동반자 이름'**
  String get ocrCompanionNameHint;

  /// No description provided for @ocrNameTooShortWarning.
  ///
  /// In ko, this message translates to:
  /// **'너무 짧거나 애매한 이름입니다. 추천 이름이나 원문 OCR을 함께 확인해 주세요.'**
  String get ocrNameTooShortWarning;

  /// No description provided for @ocrDuplicateNameWarning.
  ///
  /// In ko, this message translates to:
  /// **'다른 동반자와 이름이 같습니다. 같은 분이 아니라면 이름을 구분해 주세요.'**
  String get ocrDuplicateNameWarning;

  /// No description provided for @ocrFrequentNames.
  ///
  /// In ko, this message translates to:
  /// **'자주 함께한 이름'**
  String get ocrFrequentNames;

  /// No description provided for @ocrHighSimilarity.
  ///
  /// In ko, this message translates to:
  /// **'유사도 높음'**
  String get ocrHighSimilarity;

  /// No description provided for @ocrRoundsValue.
  ///
  /// In ko, this message translates to:
  /// **'{n}회'**
  String ocrRoundsValue(int n);

  /// No description provided for @ocrCurrentTotal.
  ///
  /// In ko, this message translates to:
  /// **'현재 합계 {n}타'**
  String ocrCurrentTotal(int n);

  /// No description provided for @ocrApplyCompanionFix.
  ///
  /// In ko, this message translates to:
  /// **'동반자 보정 반영'**
  String get ocrApplyCompanionFix;

  /// No description provided for @ocrHoleStrokesTitle.
  ///
  /// In ko, this message translates to:
  /// **'홀별 타수'**
  String get ocrHoleStrokesTitle;

  /// No description provided for @ocrCompanionHoleEditDesc.
  ///
  /// In ko, this message translates to:
  /// **'동반자 홀을 눌러 타수를 수정하세요.'**
  String get ocrCompanionHoleEditDesc;

  /// No description provided for @ocrCompanionHoleTitle.
  ///
  /// In ko, this message translates to:
  /// **'{n}번 홀 동반자 타수'**
  String ocrCompanionHoleTitle(int n);

  /// No description provided for @ocrCompanionHoleDesc.
  ///
  /// In ko, this message translates to:
  /// **'Par {par} 기준으로 타수를 보정합니다.'**
  String ocrCompanionHoleDesc(int par);

  /// No description provided for @ocrApplyStrokes.
  ///
  /// In ko, this message translates to:
  /// **'타수 반영'**
  String get ocrApplyStrokes;

  /// No description provided for @restTabBreakfast.
  ///
  /// In ko, this message translates to:
  /// **'조식'**
  String get restTabBreakfast;

  /// No description provided for @restTabLunch.
  ///
  /// In ko, this message translates to:
  /// **'중식'**
  String get restTabLunch;

  /// No description provided for @restFilterNoteWithAddress.
  ///
  /// In ko, this message translates to:
  /// **'카페·디저트 제외 · {address} 기준 가까운 순 우선'**
  String restFilterNoteWithAddress(String address);

  /// No description provided for @restFilterNote.
  ///
  /// In ko, this message translates to:
  /// **'카페·디저트 제외 · 실제 후기는 상세에서 확인'**
  String get restFilterNote;

  /// No description provided for @restLoadError.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다: {error}'**
  String restLoadError(String error);

  /// No description provided for @restEmptyNearby.
  ///
  /// In ko, this message translates to:
  /// **'근처에 추천 식당이 없습니다\n(위치: {lat}, {lng})'**
  String restEmptyNearby(String lat, String lng);

  /// No description provided for @restRatingLabel.
  ///
  /// In ko, this message translates to:
  /// **'별점 {rating}'**
  String restRatingLabel(String rating);

  /// No description provided for @restDistanceCategory.
  ///
  /// In ko, this message translates to:
  /// **'{distance}km · {category}'**
  String restDistanceCategory(String distance, String category);

  /// No description provided for @restDirections.
  ///
  /// In ko, this message translates to:
  /// **'길찾기'**
  String get restDirections;

  /// No description provided for @restViewDetails.
  ///
  /// In ko, this message translates to:
  /// **'상세 보기'**
  String get restViewDetails;

  /// No description provided for @restAddressLabel.
  ///
  /// In ko, this message translates to:
  /// **'주소'**
  String get restAddressLabel;

  /// No description provided for @restHoursLabel.
  ///
  /// In ko, this message translates to:
  /// **'영업시간'**
  String get restHoursLabel;

  /// No description provided for @restCall.
  ///
  /// In ko, this message translates to:
  /// **'전화'**
  String get restCall;

  /// No description provided for @restViewReviews.
  ///
  /// In ko, this message translates to:
  /// **'후기 보기'**
  String get restViewReviews;

  /// No description provided for @restRecommendationCriteria.
  ///
  /// In ko, this message translates to:
  /// **'추천 기준'**
  String get restRecommendationCriteria;

  /// No description provided for @restNavKakaoTitle.
  ///
  /// In ko, this message translates to:
  /// **'카카오맵으로 길찾기'**
  String get restNavKakaoTitle;

  /// No description provided for @restNavKakaoSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'설치되어 있으면 앱으로 열고, 없으면 웹으로 연결'**
  String get restNavKakaoSubtitle;

  /// No description provided for @restNavNaverTitle.
  ///
  /// In ko, this message translates to:
  /// **'네이버 지도로 길찾기'**
  String get restNavNaverTitle;

  /// No description provided for @restNavNaverSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'네이버 지도 앱이 있으면 바로 연결'**
  String get restNavNaverSubtitle;

  /// No description provided for @restNavWebTitle.
  ///
  /// In ko, this message translates to:
  /// **'웹 지도로 열기'**
  String get restNavWebTitle;

  /// No description provided for @restNavWebSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'지도 앱이 없어도 브라우저에서 확인'**
  String get restNavWebSubtitle;

  /// No description provided for @restNavOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'길찾기를 열 수 없습니다. 잠시 후 다시 시도해 주세요.'**
  String get restNavOpenFailed;

  /// No description provided for @restSearchError.
  ///
  /// In ko, this message translates to:
  /// **'식당 검색 중 오류가 발생했습니다.\n{error}'**
  String restSearchError(String error);

  /// No description provided for @restApiAuthError.
  ///
  /// In ko, this message translates to:
  /// **'카카오 API 인증에 실패했습니다. 개발자 콘솔에서 REST API 키를 확인해 주세요.'**
  String get restApiAuthError;

  /// No description provided for @restApiForbiddenError.
  ///
  /// In ko, this message translates to:
  /// **'카카오 API 사용이 제한되었습니다. 앱 플랫폼(iOS) 등록 여부를 확인해 주세요.'**
  String get restApiForbiddenError;

  /// No description provided for @restApiError.
  ///
  /// In ko, this message translates to:
  /// **'식당 API 오류 ({statusCode})'**
  String restApiError(int statusCode);

  /// No description provided for @restHoursPending.
  ///
  /// In ko, this message translates to:
  /// **'정보 확인 필요'**
  String get restHoursPending;

  /// No description provided for @restHoursUnspecified.
  ///
  /// In ko, this message translates to:
  /// **'미지정'**
  String get restHoursUnspecified;

  /// No description provided for @restReviewHint1.
  ///
  /// In ko, this message translates to:
  /// **'카카오 장소 페이지에서 방문 후기와 사진을 확인해 보세요.'**
  String get restReviewHint1;

  /// No description provided for @restReviewHint2.
  ///
  /// In ko, this message translates to:
  /// **'라운드 전후 식사에 맞는 음식점 카테고리만 선별했습니다.'**
  String get restReviewHint2;

  /// No description provided for @schedEnterCourseName.
  ///
  /// In ko, this message translates to:
  /// **'골프장을 입력해주세요'**
  String get schedEnterCourseName;

  /// No description provided for @schedCourseNotInDb.
  ///
  /// In ko, this message translates to:
  /// **'{name}는 DB에 없어 날씨 알림 없이 커스텀 일정으로 저장합니다'**
  String schedCourseNotInDb(String name);

  /// No description provided for @schedErrorWithDetail.
  ///
  /// In ko, this message translates to:
  /// **'오류: {error}'**
  String schedErrorWithDetail(String error);

  /// No description provided for @schedCalendarPermissionNeeded.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 접근 권한이 필요합니다. 설정에서 캘린더 권한을 허용해 주세요.'**
  String get schedCalendarPermissionNeeded;

  /// No description provided for @schedNoCalendarCandidates.
  ///
  /// In ko, this message translates to:
  /// **'최근/예정 캘린더에서 골프 일정 후보를 찾지 못했어요.'**
  String get schedNoCalendarCandidates;

  /// No description provided for @schedCalendarImportFailed.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 일정을 불러오지 못했어요: {error}'**
  String schedCalendarImportFailed(String error);

  /// No description provided for @schedCalendarCandidatesTitle.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 일정 후보'**
  String get schedCalendarCandidatesTitle;

  /// No description provided for @schedCalendarCandidatesDesc.
  ///
  /// In ko, this message translates to:
  /// **'가져올 일정을 선택하면 골프장, 날짜, 티오프 시간이 입력됩니다.'**
  String get schedCalendarCandidatesDesc;

  /// No description provided for @schedPortalFoundCourse.
  ///
  /// In ko, this message translates to:
  /// **'포털 검색으로 찾은 골프장이에요 (DB 외) — 주소를 확인해 주세요.'**
  String get schedPortalFoundCourse;

  /// No description provided for @schedVerifyCourseName.
  ///
  /// In ko, this message translates to:
  /// **'골프장명은 저장 전 한 번 확인해 주세요.'**
  String get schedVerifyCourseName;

  /// No description provided for @schedCalendarApplied.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 일정 정보를 입력했습니다. 저장 전 확인해 주세요.'**
  String get schedCalendarApplied;

  /// No description provided for @schedEditSchedule.
  ///
  /// In ko, this message translates to:
  /// **'일정 수정'**
  String get schedEditSchedule;

  /// No description provided for @schedAddNewSchedule.
  ///
  /// In ko, this message translates to:
  /// **'새 일정 추가'**
  String get schedAddNewSchedule;

  /// No description provided for @schedSaveSchedule.
  ///
  /// In ko, this message translates to:
  /// **'일정 저장'**
  String get schedSaveSchedule;

  /// No description provided for @schedIntro.
  ///
  /// In ko, this message translates to:
  /// **'라운드 정보를 입력하면 골프장 날씨와 알림을 함께 확인할 수 있습니다.'**
  String get schedIntro;

  /// No description provided for @schedDateLabel.
  ///
  /// In ko, this message translates to:
  /// **'날짜 *'**
  String get schedDateLabel;

  /// No description provided for @schedTimeLabel.
  ///
  /// In ko, this message translates to:
  /// **'시간 *'**
  String get schedTimeLabel;

  /// No description provided for @schedCourseLabel.
  ///
  /// In ko, this message translates to:
  /// **'골프장 *'**
  String get schedCourseLabel;

  /// No description provided for @schedAddressLabel.
  ///
  /// In ko, this message translates to:
  /// **'주소/위치 메모'**
  String get schedAddressLabel;

  /// No description provided for @schedTitleLabel.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get schedTitleLabel;

  /// No description provided for @schedNotifyLabel.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get schedNotifyLabel;

  /// No description provided for @schedCourseHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 레이크사이드CC'**
  String get schedCourseHint;

  /// No description provided for @schedAddressHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 경기도 용인시 처인구 ...'**
  String get schedAddressHint;

  /// No description provided for @schedTitleHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 주말 라운드'**
  String get schedTitleHint;

  /// No description provided for @schedWeatherAlertToggle.
  ///
  /// In ko, this message translates to:
  /// **'날씨 위험 알림 받기'**
  String get schedWeatherAlertToggle;

  /// No description provided for @schedCheckingCalendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 확인 중'**
  String get schedCheckingCalendar;

  /// No description provided for @schedImportFromCalendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더에서 가져오기'**
  String get schedImportFromCalendar;

  /// No description provided for @schedHoursBefore.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 전'**
  String schedHoursBefore(int hours);

  /// No description provided for @schedDaysBefore.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 전'**
  String schedDaysBefore(int days);

  /// No description provided for @schedDateFmt.
  ///
  /// In ko, this message translates to:
  /// **'M월 d일 (E)'**
  String get schedDateFmt;

  /// No description provided for @schedCalendarDateFmt.
  ///
  /// In ko, this message translates to:
  /// **'yyyy.MM.dd (E) HH:mm'**
  String get schedCalendarDateFmt;

  /// No description provided for @eventStatusOptimal.
  ///
  /// In ko, this message translates to:
  /// **'최적'**
  String get eventStatusOptimal;

  /// No description provided for @eventStatusCaution.
  ///
  /// In ko, this message translates to:
  /// **'주의'**
  String get eventStatusCaution;

  /// No description provided for @eventStatusCancelRecommended.
  ///
  /// In ko, this message translates to:
  /// **'취소권장'**
  String get eventStatusCancelRecommended;

  /// No description provided for @eventStatusUnknown.
  ///
  /// In ko, this message translates to:
  /// **'정보없음'**
  String get eventStatusUnknown;

  /// No description provided for @eventDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'일정 삭제'**
  String get eventDeleteTitle;

  /// No description provided for @eventDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 일정을 삭제하시겠습니까?'**
  String get eventDeleteConfirm;

  /// No description provided for @eventErrorWithDetail.
  ///
  /// In ko, this message translates to:
  /// **'오류: {error}'**
  String eventErrorWithDetail(String error);

  /// No description provided for @eventNotifPermissionNeeded.
  ///
  /// In ko, this message translates to:
  /// **'알림 권한이 필요합니다. 설정에서 허용해주세요.'**
  String get eventNotifPermissionNeeded;

  /// No description provided for @eventSubscribeNoCourse.
  ///
  /// In ko, this message translates to:
  /// **'골프장 정보를 찾을 수 없어 구독할 수 없습니다.'**
  String get eventSubscribeNoCourse;

  /// No description provided for @eventSubscribeSuccess.
  ///
  /// In ko, this message translates to:
  /// **'날씨 변화 알림을 등록했습니다.'**
  String get eventSubscribeSuccess;

  /// No description provided for @eventSubscribeFailed.
  ///
  /// In ko, this message translates to:
  /// **'알림 등록에 실패했습니다.'**
  String get eventSubscribeFailed;

  /// No description provided for @eventBookingForecastTitle.
  ///
  /// In ko, this message translates to:
  /// **'부킹 시간대 예보'**
  String get eventBookingForecastTitle;

  /// No description provided for @eventBookingTimeBase.
  ///
  /// In ko, this message translates to:
  /// **'부킹 {time} 기준'**
  String eventBookingTimeBase(String time);

  /// No description provided for @eventStartMarker.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get eventStartMarker;

  /// No description provided for @eventRainProb.
  ///
  /// In ko, this message translates to:
  /// **'비 {prob}%'**
  String eventRainProb(int prob);

  /// No description provided for @eventRestaurantTitle.
  ///
  /// In ko, this message translates to:
  /// **'근처 식당 추천'**
  String get eventRestaurantTitle;

  /// No description provided for @eventRestaurantSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'조식·중식 장소를 찾아보세요'**
  String get eventRestaurantSubtitle;

  /// No description provided for @eventForecastNotYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 예보 제공 전 · 라운드 7일 전부터 확인하세요'**
  String get eventForecastNotYet;

  /// No description provided for @eventWeatherPendingTitle.
  ///
  /// In ko, this message translates to:
  /// **'날씨 준비 중인 일정'**
  String get eventWeatherPendingTitle;

  /// No description provided for @eventWeatherPendingDesc.
  ///
  /// In ko, this message translates to:
  /// **'골프장 매칭 또는 예보 캐시가 아직 준비되지 않았습니다. 일정, 지도, 식당 추천은 사용할 수 있고 날씨는 잠시 후 다시 확인해 주세요.'**
  String get eventWeatherPendingDesc;

  /// No description provided for @eventMapHint.
  ///
  /// In ko, this message translates to:
  /// **'지도 표시가 안 되면 일정 수정에서 골프장명과 주소를 함께 입력해 주세요.'**
  String get eventMapHint;

  /// No description provided for @eventScorecardTitle.
  ///
  /// In ko, this message translates to:
  /// **'스코어카드'**
  String get eventScorecardTitle;

  /// No description provided for @eventScorecardSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'18홀 타수·퍼트·페어웨이 기록'**
  String get eventScorecardSubtitle;

  /// No description provided for @calDefaultGolfTitle.
  ///
  /// In ko, this message translates to:
  /// **'골프 일정'**
  String get calDefaultGolfTitle;

  /// No description provided for @scoreHistoryTitle.
  ///
  /// In ko, this message translates to:
  /// **'스코어 관리'**
  String get scoreHistoryTitle;

  /// No description provided for @scoreDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'스코어 삭제'**
  String get scoreDeleteTitle;

  /// No description provided for @scoreDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{courseName} 기록을 삭제할까요?'**
  String scoreDeleteConfirm(String courseName);

  /// No description provided for @scoreDeletedSnack.
  ///
  /// In ko, this message translates to:
  /// **'스코어 기록을 삭제했습니다.'**
  String get scoreDeletedSnack;

  /// No description provided for @scoreCourseNameUpdatedSnack.
  ///
  /// In ko, this message translates to:
  /// **'골프장 이름을 수정했습니다.'**
  String get scoreCourseNameUpdatedSnack;

  /// No description provided for @scoreOcrScanning.
  ///
  /// In ko, this message translates to:
  /// **'OCR 스캐닝'**
  String get scoreOcrScanning;

  /// No description provided for @scoreRoundDate.
  ///
  /// In ko, this message translates to:
  /// **'라운드 날짜'**
  String get scoreRoundDate;

  /// No description provided for @scoreToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get scoreToday;

  /// No description provided for @scoreYesterday.
  ///
  /// In ko, this message translates to:
  /// **'어제'**
  String get scoreYesterday;

  /// No description provided for @scoreSevenDaysAgo.
  ///
  /// In ko, this message translates to:
  /// **'7일 전'**
  String get scoreSevenDaysAgo;

  /// No description provided for @scoreOcrNoCourseNameHint.
  ///
  /// In ko, this message translates to:
  /// **'골프장 이름은 먼저 입력하지 않아도 됩니다. 먼저 OCR로 읽고, 필요한 경우에만 마지막에 보정할게요.'**
  String get scoreOcrNoCourseNameHint;

  /// No description provided for @scoreOcrStart.
  ///
  /// In ko, this message translates to:
  /// **'OCR 스캔 시작'**
  String get scoreOcrStart;

  /// No description provided for @scoreRecentRounds.
  ///
  /// In ko, this message translates to:
  /// **'최근 라운드'**
  String get scoreRecentRounds;

  /// No description provided for @scoreLifeBest.
  ///
  /// In ko, this message translates to:
  /// **'라이프베스트'**
  String get scoreLifeBest;

  /// No description provided for @scoreRecentAvgChip.
  ///
  /// In ko, this message translates to:
  /// **'최근 5R 평균 {avg}'**
  String scoreRecentAvgChip(String avg);

  /// No description provided for @scoreThisMonthChip.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 {count}R'**
  String scoreThisMonthChip(int count);

  /// No description provided for @scoreCompanionChip.
  ///
  /// In ko, this message translates to:
  /// **'동반자 기록 {count}R'**
  String scoreCompanionChip(int count);

  /// No description provided for @scoreDetailCompleteChip.
  ///
  /// In ko, this message translates to:
  /// **'세부 완료 {count}R'**
  String scoreDetailCompleteChip(int count);

  /// No description provided for @scoreOptionalFixChip.
  ///
  /// In ko, this message translates to:
  /// **'선택 보정 {count}R'**
  String scoreOptionalFixChip(int count);

  /// No description provided for @scoreOptionalMetricsCount.
  ///
  /// In ko, this message translates to:
  /// **'선택 세부 지표 {count}건'**
  String scoreOptionalMetricsCount(int count);

  /// No description provided for @scoreDetailRecordPercent.
  ///
  /// In ko, this message translates to:
  /// **'세부 기록 {percent}%'**
  String scoreDetailRecordPercent(int percent);

  /// No description provided for @scoreOptionalInputHoles.
  ///
  /// In ko, this message translates to:
  /// **'선택 입력 {count}홀'**
  String scoreOptionalInputHoles(int count);

  /// No description provided for @scorePuttsTrackedChip.
  ///
  /// In ko, this message translates to:
  /// **'퍼트 {tracked}/{total}홀'**
  String scorePuttsTrackedChip(int tracked, int total);

  /// No description provided for @scoreFairwayTrackedChip.
  ///
  /// In ko, this message translates to:
  /// **'페어웨이 {tracked}/{total}홀'**
  String scoreFairwayTrackedChip(int tracked, int total);

  /// No description provided for @scoreFirstIncompleteChip.
  ///
  /// In ko, this message translates to:
  /// **'첫 선택 항목 {hole}H'**
  String scoreFirstIncompleteChip(int hole);

  /// No description provided for @scoreTotalRounds.
  ///
  /// In ko, this message translates to:
  /// **'총 라운드'**
  String get scoreTotalRounds;

  /// No description provided for @scoreTimesCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}회'**
  String scoreTimesCount(int count);

  /// No description provided for @scoreRoundsThisYear.
  ///
  /// In ko, this message translates to:
  /// **'올해 라운드'**
  String get scoreRoundsThisYear;

  /// No description provided for @scoreThisMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달'**
  String get scoreThisMonth;

  /// No description provided for @scoreRecentAvgLabel.
  ///
  /// In ko, this message translates to:
  /// **'최근 5R 평균'**
  String get scoreRecentAvgLabel;

  /// No description provided for @scoreCompanionRecords.
  ///
  /// In ko, this message translates to:
  /// **'동반자 기록'**
  String get scoreCompanionRecords;

  /// No description provided for @scoreNotRecordedYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 기록 전'**
  String get scoreNotRecordedYet;

  /// No description provided for @scoreCompanionSavedCaption.
  ///
  /// In ko, this message translates to:
  /// **'동반자 정보가 함께 저장된 라운드'**
  String get scoreCompanionSavedCaption;

  /// No description provided for @scoreOptionalFix.
  ///
  /// In ko, this message translates to:
  /// **'선택 보정'**
  String get scoreOptionalFix;

  /// No description provided for @scoreAllScoresSaved.
  ///
  /// In ko, this message translates to:
  /// **'스코어 기록은 모두 저장됨'**
  String get scoreAllScoresSaved;

  /// No description provided for @scoreOptionalDetailCaption.
  ///
  /// In ko, this message translates to:
  /// **'퍼트/페어웨이 등 선택 세부 지표'**
  String get scoreOptionalDetailCaption;

  /// No description provided for @scoreCompanionCountBadge.
  ///
  /// In ko, this message translates to:
  /// **'동반자 {count}명'**
  String scoreCompanionCountBadge(int count);

  /// No description provided for @scorePuttRecordBadge.
  ///
  /// In ko, this message translates to:
  /// **'퍼트 기록'**
  String get scorePuttRecordBadge;

  /// No description provided for @scoreFairwayRecordBadge.
  ///
  /// In ko, this message translates to:
  /// **'페어웨이 기록'**
  String get scoreFairwayRecordBadge;

  /// No description provided for @scoreTrackingSummary.
  ///
  /// In ko, this message translates to:
  /// **'선택 지표: 퍼트 {puttTracked}/{puttTotal}홀 · 페어웨이 {fairwayTracked}/{fairwayTotal}홀'**
  String scoreTrackingSummary(
      int puttTracked, int puttTotal, int fairwayTracked, int fairwayTotal);

  /// No description provided for @scoreEditCourseName.
  ///
  /// In ko, this message translates to:
  /// **'골프장명 수정'**
  String get scoreEditCourseName;

  /// No description provided for @scoreEditCourseNameDesc.
  ///
  /// In ko, this message translates to:
  /// **'OCR로 저장된 골프장명이 비었거나 다르면 여기서 바로 고칠 수 있어요.'**
  String get scoreEditCourseNameDesc;

  /// No description provided for @scoreCourseNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'골프장 이름'**
  String get scoreCourseNameLabel;

  /// No description provided for @scoreCourseNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 드림파크CC'**
  String get scoreCourseNameHint;

  /// No description provided for @scoreOcrCardTitle.
  ///
  /// In ko, this message translates to:
  /// **'스코어카드 OCR 스캔'**
  String get scoreOcrCardTitle;

  /// No description provided for @scoreOcrCardDesc.
  ///
  /// In ko, this message translates to:
  /// **'일정 상세의 스코어카드에서 사진을 읽어 적용'**
  String get scoreOcrCardDesc;

  /// No description provided for @scoreOcrGuide.
  ///
  /// In ko, this message translates to:
  /// **'OCR 가이드'**
  String get scoreOcrGuide;

  /// No description provided for @scoreEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 저장된 스코어가 없습니다'**
  String get scoreEmptyTitle;

  /// No description provided for @scoreEmptyDesc.
  ///
  /// In ko, this message translates to:
  /// **'일정 상세 화면에서 스코어카드를 열고 저장하거나\n지난 라운드를 OCR로 바로 등록하면 기록이 여기에 쌓입니다.'**
  String get scoreEmptyDesc;

  /// No description provided for @scoreOcrSheetTitle.
  ///
  /// In ko, this message translates to:
  /// **'스코어카드 OCR 가져오기'**
  String get scoreOcrSheetTitle;

  /// No description provided for @scoreOcrSheetDesc.
  ///
  /// In ko, this message translates to:
  /// **'일정 상세에서 바로 스캔할 수도 있고, 지난 라운드도 OCR 등록으로 기록을 시작할 수 있습니다.'**
  String get scoreOcrSheetDesc;

  /// No description provided for @scoreOcrStep1.
  ///
  /// In ko, this message translates to:
  /// **'스코어카드 화면을 캡처하거나 종이 스코어카드를 촬영'**
  String get scoreOcrStep1;

  /// No description provided for @scoreOcrStep2.
  ///
  /// In ko, this message translates to:
  /// **'일정 상세 스코어카드 또는 OCR 스캐닝에서 이미지 선택'**
  String get scoreOcrStep2;

  /// No description provided for @scoreOcrStep3.
  ///
  /// In ko, this message translates to:
  /// **'홀별 점수를 확인하면 자동 저장되고, 필요할 때만 보정'**
  String get scoreOcrStep3;

  /// No description provided for @scoreOcrStartShort.
  ///
  /// In ko, this message translates to:
  /// **'OCR 시작'**
  String get scoreOcrStartShort;

  /// No description provided for @scoreCompanionOne.
  ///
  /// In ko, this message translates to:
  /// **'동반자 {name}'**
  String scoreCompanionOne(String name);

  /// No description provided for @scoreCompanionTwo.
  ///
  /// In ko, this message translates to:
  /// **'동반자 {name1} · {name2}'**
  String scoreCompanionTwo(String name1, String name2);

  /// No description provided for @scoreCompanionMore.
  ///
  /// In ko, this message translates to:
  /// **'동반자 {name1} · {name2} 외 {count}명'**
  String scoreCompanionMore(String name1, String name2, int count);

  /// No description provided for @scoreCardSavedSnack.
  ///
  /// In ko, this message translates to:
  /// **'스코어카드를 저장했습니다.'**
  String get scoreCardSavedSnack;

  /// No description provided for @scoreSaveFailedSnack.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 못했습니다: {error}'**
  String scoreSaveFailedSnack(String error);

  /// No description provided for @scoreCourseNameConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'골프장 이름 확인'**
  String get scoreCourseNameConfirmTitle;

  /// No description provided for @scoreCourseNameMissingDesc.
  ///
  /// In ko, this message translates to:
  /// **'이번 카드에서는 골프장 이름을 읽지 못했어요. 저장 전에 골프장 이름만 입력해 주세요.'**
  String get scoreCourseNameMissingDesc;

  /// No description provided for @scoreContinueSave.
  ///
  /// In ko, this message translates to:
  /// **'저장 계속'**
  String get scoreContinueSave;

  /// No description provided for @scoreOcrLoadedSnack.
  ///
  /// In ko, this message translates to:
  /// **'OCR 결과를 불러왔어요. 홀별 점수만 한 번 확인해 주세요.'**
  String get scoreOcrLoadedSnack;

  /// No description provided for @scoreOcrLoadedWithCompanionsSnack.
  ///
  /// In ko, this message translates to:
  /// **'OCR 결과와 동반자 {count}명 기록을 불러왔어요.'**
  String scoreOcrLoadedWithCompanionsSnack(int count);

  /// No description provided for @scoreSaving.
  ///
  /// In ko, this message translates to:
  /// **'저장 중'**
  String get scoreSaving;

  /// No description provided for @scoreSaveButton.
  ///
  /// In ko, this message translates to:
  /// **'스코어 저장'**
  String get scoreSaveButton;

  /// No description provided for @scorePastRoundOcr.
  ///
  /// In ko, this message translates to:
  /// **'지난 라운드 OCR'**
  String get scorePastRoundOcr;

  /// No description provided for @scoreCardLabel.
  ///
  /// In ko, this message translates to:
  /// **'스코어카드'**
  String get scoreCardLabel;

  /// No description provided for @scoreCompanionOcrResult.
  ///
  /// In ko, this message translates to:
  /// **'동반자 OCR 결과'**
  String get scoreCompanionOcrResult;

  /// No description provided for @scoreTotalStrokes.
  ///
  /// In ko, this message translates to:
  /// **'총타'**
  String get scoreTotalStrokes;

  /// No description provided for @scoreScoreLabel.
  ///
  /// In ko, this message translates to:
  /// **'스코어'**
  String get scoreScoreLabel;

  /// No description provided for @scorePutts.
  ///
  /// In ko, this message translates to:
  /// **'퍼트'**
  String get scorePutts;

  /// No description provided for @scoreFairway.
  ///
  /// In ko, this message translates to:
  /// **'페어웨이'**
  String get scoreFairway;

  /// No description provided for @scoreObPenalty.
  ///
  /// In ko, this message translates to:
  /// **'OB/벌타'**
  String get scoreObPenalty;

  /// No description provided for @scoreStrokes.
  ///
  /// In ko, this message translates to:
  /// **'타수'**
  String get scoreStrokes;

  /// No description provided for @scorePenalty.
  ///
  /// In ko, this message translates to:
  /// **'벌타'**
  String get scorePenalty;

  /// No description provided for @scoreFairwayHit.
  ///
  /// In ko, this message translates to:
  /// **'성공'**
  String get scoreFairwayHit;

  /// No description provided for @scoreFairwayMiss.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get scoreFairwayMiss;

  /// No description provided for @scoreFairwayNotApplicable.
  ///
  /// In ko, this message translates to:
  /// **'해당 없음'**
  String get scoreFairwayNotApplicable;

  /// No description provided for @scoreStageComplete.
  ///
  /// In ko, this message translates to:
  /// **'세부 기록 완료'**
  String get scoreStageComplete;

  /// No description provided for @scoreStageScoreOnly.
  ///
  /// In ko, this message translates to:
  /// **'스코어 저장'**
  String get scoreStageScoreOnly;

  /// No description provided for @scoreStageNearlyComplete.
  ///
  /// In ko, this message translates to:
  /// **'세부 기록 거의 완료'**
  String get scoreStageNearlyComplete;

  /// No description provided for @scoreStageInProgress.
  ///
  /// In ko, this message translates to:
  /// **'세부 기록 일부'**
  String get scoreStageInProgress;

  /// No description provided for @scoreStageDescComplete.
  ///
  /// In ko, this message translates to:
  /// **'퍼트와 페어웨이까지 모두 기록했어요.'**
  String get scoreStageDescComplete;

  /// No description provided for @scoreStageDescScoreOnly.
  ///
  /// In ko, this message translates to:
  /// **'스코어는 저장됐고 세부 기록은 비어 있어요.'**
  String get scoreStageDescScoreOnly;

  /// No description provided for @scoreStageDescNearlyComplete.
  ///
  /// In ko, this message translates to:
  /// **'세부 기록이 거의 끝났어요. 몇 홀만 더 확인하면 됩니다.'**
  String get scoreStageDescNearlyComplete;

  /// No description provided for @scoreStageDescInProgress.
  ///
  /// In ko, this message translates to:
  /// **'세부 기록을 이어서 보정할 수 있어요.'**
  String get scoreStageDescInProgress;
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
