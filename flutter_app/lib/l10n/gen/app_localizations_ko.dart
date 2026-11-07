// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Golf Windy';

  @override
  String get commonConfirm => '확인';

  @override
  String get commonCancel => '취소';

  @override
  String get commonSave => '저장';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonEdit => '수정';

  @override
  String get commonClose => '닫기';

  @override
  String get commonRetry => '다시 시도';

  @override
  String get commonSearch => '검색';

  @override
  String get commonLoading => '불러오는 중…';

  @override
  String get commonError => '오류가 발생했어요';

  @override
  String get commonNone => '없음';

  @override
  String get commonDone => '완료';

  @override
  String get commonNext => '다음';

  @override
  String get commonSkip => '건너뛰기';

  @override
  String get commonStart => '시작하기';

  @override
  String get navHome => '홈';

  @override
  String get navSchedule => '일정';

  @override
  String get navMap => '지도';

  @override
  String get navSettings => '설정';

  @override
  String get setTitle => '설정';

  @override
  String get setSectionTheme => '테마 · THEME';

  @override
  String get setSectionThresholds => '알림 임계값';

  @override
  String get setRainThresholdLabel => '강수 확률 기준';

  @override
  String get setWindThresholdLabel => '풍속 기준';

  @override
  String get setThresholdHint => '이 임계값 초과 시 YELLOW/RED 권고가 발령됩니다';

  @override
  String get setSectionRoundProfile => '라운드 성향';

  @override
  String get setSensitivityRain => '비 민감도';

  @override
  String get setSensitivityWind => '바람 민감도';

  @override
  String get setSensitivityCold => '추위 민감도';

  @override
  String get setSensitivityHeat => '더위 민감도';

  @override
  String get setSensitivityHint => '민감도가 높을수록 라운드 적합도가 더 보수적으로 판정됩니다';

  @override
  String get setSectionNotifyTiming => '알림 타이밍';

  @override
  String get setNotifyTimingQuestion => '일정 몇 시간 전부터 알림을 받을까요?';

  @override
  String setHoursBefore(int h) {
    return '$h시간 전';
  }

  @override
  String get setSectionNotifyPermission => '알림 권한';

  @override
  String get setNotifyPermissionButton => '알림 권한 요청 / 재등록';

  @override
  String get setNotifyGranted => '알림 권한이 허용되었습니다.';

  @override
  String get setNotifyDenied => '알림 권한이 거부되었습니다.';

  @override
  String get setSectionHelp => '도움말';

  @override
  String get setHelpDesc => '핵심 기능 안내를 다시 열 수 있습니다.';

  @override
  String get setHelpTutorialButton => '튜토리얼 다시 보기';

  @override
  String get setSectionScore => '스코어';

  @override
  String get setScoreDesc => 'OCR 스캔과 지난 라운드 기록 관리를 여기서 바로 열 수 있습니다.';

  @override
  String get setScoreOpenButton => '스코어 관리 열기';

  @override
  String get setSectionDevice => '디바이스 정보';

  @override
  String get setDeviceTokenLabel => '익명 디바이스 토큰';

  @override
  String get setDeviceTokenLoading => '로딩 중...';

  @override
  String get setDevicePrivacyNote =>
      '이 앱은 개인정보를 수집하지 않습니다. 위 토큰은 알림 발송에만 사용되는 임의 식별자입니다.';

  @override
  String get setLanguageSection => '언어';

  @override
  String get setLanguageTitle => '앱 언어';

  @override
  String get setLanguageSystem => '시스템 설정 따름';

  @override
  String get setLanguageKorean => '한국어';

  @override
  String get setLanguageEnglish => 'English';

  @override
  String get whatsNewTitle => '업데이트 안내';

  @override
  String whatsNewSubtitle(String version) {
    return 'v$version의 새로운 기능이에요.';
  }

  @override
  String suitRed(int dday, String label) {
    return 'D-$dday 취소 권고 — $label 주의보';
  }

  @override
  String suitYellow(int dday, String label) {
    return 'D-$dday 주의 — $label 준비';
  }

  @override
  String suitGreen(int dday) {
    return 'D-$dday 라운딩 적합';
  }

  @override
  String get suitWorstRain => '악천후';

  @override
  String get suitWorstWind => '강풍';

  @override
  String get suitWorstCold => '한파';

  @override
  String get suitWorstHeat => '폭염';

  @override
  String get suitPrepRain => '우비';

  @override
  String get suitPrepWind => '방풍';

  @override
  String get suitPrepCold => '방한';

  @override
  String get suitPrepHeat => '더위 대비';

  @override
  String suitDetailRainProb(int p) {
    return '강수확률 $p%';
  }

  @override
  String suitDetailWind(String w) {
    return '풍속 ${w}m/s';
  }

  @override
  String suitDetailMinTemp(int t) {
    return '최저 $t°C';
  }

  @override
  String suitDetailMaxTemp(int t) {
    return '최고 $t°C';
  }

  @override
  String get suitDetailLightning => '낙뢰 예보';

  @override
  String get suitDetailProfileApplied => ' — 내 라운드 성향 반영 판정';

  @override
  String get weatherPendingMessage =>
      '날씨 정보가 아직 준비 중입니다.\n골프장 DB에는 등록되어 있지만 해당 위치의 예보 캐시가 아직 수집되지 않았거나, 좌표 보정이 필요할 수 있어요. 잠시 후 다시 확인하거나 일정의 골프장명을 수정해 주세요.';

  @override
  String weatherUnavailableMessage(String url) {
    return '날씨 정보를 불러오지 못했습니다.\n네트워크 연결 또는 서버 상태를 확인해 주세요. 실기기 테스트 중이라면 설정의 API 주소가 배포 서버를 가리키는지도 확인하면 좋습니다.\n현재 주소: $url';
  }

  @override
  String get splashTagline => '스마트한 라운드 관리';

  @override
  String get mapCourseLocation => '골프장 위치';

  @override
  String get themeSubtitleFairwaySky => '쿨 틸 · 다크';

  @override
  String get themeSubtitleLightAir => '오프화이트 · 라이트';

  @override
  String get themeSubtitleMidnightLime => '네이비 + 라임 · 다크';

  @override
  String get notifChannelName => '날씨 알림';

  @override
  String get notifChannelDesc => '골프·낚시 일정 기상 변화 알림';

  @override
  String get sensitivityLow => '둔감';

  @override
  String get sensitivityNormal => '보통';

  @override
  String get sensitivityHigh => '민감';
}
