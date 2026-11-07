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

  @override
  String get homeStatusGreen => '최적';

  @override
  String get homeStatusYellow => '주의';

  @override
  String get homeStatusRed => '취소권장';

  @override
  String get homeStatusNone => '정보없음';

  @override
  String get tutTitle => 'Golf Windy 빠른 안내';

  @override
  String get tutSubtitle => '핵심 기능만 짧게 보고 바로 시작할게요.';

  @override
  String get tutStep1Title => '홈에서 바로 확인';

  @override
  String get tutStep1Desc => '다가오는 라운드와 날씨 권고를 첫 화면에서 바로 볼 수 있어요.';

  @override
  String get tutStep1Bullet1 => 'GREEN / YELLOW / RED 권고를 빠르게 확인';

  @override
  String get tutStep1Bullet2 => '아래로 당겨 최신 예보 다시 불러오기';

  @override
  String get tutStep2Title => '일정 등록은 간단하게';

  @override
  String get tutStep2Desc => '일정 탭에서 골프장을 선택하고 티오프 시간을 저장하면 준비가 끝납니다.';

  @override
  String get tutStep2Bullet1 => '골프장 검색 후 일정 생성';

  @override
  String get tutStep2Bullet2 => '일정 상세에서 날씨와 스코어카드 연결';

  @override
  String get tutStep3Title => '지도와 맛집 확인';

  @override
  String get tutStep3Desc => '지도 탭에서 선택한 골프장 위치와 근처 식당을 함께 확인할 수 있어요.';

  @override
  String get tutStep3Bullet1 => '네이버 지도에서 골프장 위치 확인';

  @override
  String get tutStep3Bullet2 => '조식/중식 추천 위치를 주변 기준으로 탐색';

  @override
  String get tutStep4Title => 'OCR로 지난 라운드도 저장';

  @override
  String get tutStep4Desc => '스코어 관리에서 사진만 선택하면 지난 라운드 기록을 빠르게 남길 수 있어요.';

  @override
  String get tutStep4Bullet1 => '일정 상세 또는 스코어 관리에서 OCR 시작';

  @override
  String get tutStep4Bullet2 => '설정에서 언제든 튜토리얼 다시 보기 가능';

  @override
  String get tutPrev => '이전';

  @override
  String get tutFooter => '튜토리얼은 설정 탭에서 언제든 다시 볼 수 있어요.';

  @override
  String homeCalendarError(String error) {
    return '캘린더 오류: $error';
  }

  @override
  String get homeEmptyTitle => '등록된 골프 일정이 없습니다';

  @override
  String get homeEmptyBody => '캘린더에 골프 일정을 추가하면\n자동으로 날씨를 확인해드립니다';

  @override
  String homeUpcomingRounds(int count) {
    return '다가오는 라운드 · $count';
  }

  @override
  String get homeNextRoundDday => '다음 라운드 · D-DAY';

  @override
  String homeNextRoundDdayN(int n) {
    return '다음 라운드 · D-$n';
  }

  @override
  String homeTeeOffAt(String date, String time) {
    return '$date $time 티오프';
  }

  @override
  String homeFeelsLikeInline(int temp) {
    return ' · 체감 $temp°';
  }

  @override
  String get homeTeeOffForecast => '티오프 시간대 예보';

  @override
  String get homeForecastNotYet => '아직 예보 제공 전 · 라운드 7일 전부터 확인하세요';

  @override
  String get homeAlertSevere => '악천후 — 취소 권고';

  @override
  String get homeAlertCaution => '기상 주의';

  @override
  String get homeStatFeelsLike => '체감온도';

  @override
  String get homeStatRainProb => '강수확률';

  @override
  String get homeStatWind => '바람';

  @override
  String homeAiRecommend(String label) {
    return 'AI 추천 · $label';
  }

  @override
  String get homeWxPreparing => '날씨 정보 준비 중 · 골프장명/좌표 확인 필요';

  @override
  String get homeDeleteSchedule => '일정 삭제';

  @override
  String homeDeleteScheduleConfirm(String name) {
    return '$name 일정을 삭제할까요?';
  }

  @override
  String get homeScheduleDeleted => '일정을 삭제했습니다.';

  @override
  String homeScheduleDeleteFailed(String error) {
    return '일정을 삭제하지 못했습니다: $error';
  }

  @override
  String homeScheduleLoadError(String error) {
    return '일정 로드 오류: $error';
  }

  @override
  String get homeImportCalendar => '캘린더 가져오기';

  @override
  String get homeNextRound => '다음 라운드';

  @override
  String homeRainShort(int prob) {
    return '강수 $prob%';
  }

  @override
  String homeMapLoadError(String error) {
    return '지도 로드 오류: $error';
  }

  @override
  String homeMapLoading(String name) {
    return '$name 지도 불러오는 중';
  }

  @override
  String get homeMapNoCoords =>
      '지도에 표시할 좌표가 없습니다.\n일정 수정에서 주소를 입력하면 위치를 표시할 수 있습니다.';

  @override
  String get wxPolicyUnverified => '취소 규정은 예약처에 확인해 주세요';

  @override
  String wxTimeLabel(String h) {
    return '$h시';
  }

  @override
  String get wxTimeLabelUnknown => '--시';

  @override
  String get wxRainHeavy => '강한 비';

  @override
  String get wxRainLight => '약한 비';

  @override
  String get wxRainDrizzle => '한두 방울';

  @override
  String get wxClear => '맑음';

  @override
  String get wxNoInfo => '정보 없음';

  @override
  String get wxBoardingReport => '승선신고';

  @override
  String get evtDateFmt => 'M/d(E)';

  @override
  String get shareGolfWeatherHeader => '⛳ Golf Windy — 라운드 날씨 공유';

  @override
  String get shareAiSection => '[ AI 권고 ]';

  @override
  String get shareForecastSection => '[ 시간대별 예보 ]';

  @override
  String shareForecastLine(
      String time, String emoji, int temp, int rain, String wind) {
    return '$time  $emoji  $temp°  강수 $rain%  바람 ${wind}m/s';
  }

  @override
  String get shareCancelSection => '[ 취소 안내 ]';

  @override
  String shareRainCancelPolicy(String condition) {
    return '🌧️ 우천 특별 정책: $condition';
  }

  @override
  String get shareFooter => 'Golf Windy에서 라운드 일정과 날씨를 확인하세요.';

  @override
  String shareWeatherSubject(String course, String message) {
    return '$course 날씨 — $message';
  }

  @override
  String get shareScheduleHeader => '⛳ Golf Windy — 라운드 일정 공유';

  @override
  String get shareWeatherPending =>
      '날씨 정보는 아직 준비 중입니다. Golf Windy에서 라운드 전 날씨와 취소 권고를 다시 확인해 주세요.';

  @override
  String shareScheduleSubject(String course) {
    return '$course 라운드 일정';
  }

  @override
  String get shareDateFmt => 'M월 d일(E) HH:mm';

  @override
  String get widgetNoSchedule => '앱을 열어 라운드를 등록해 주세요';

  @override
  String get widgetForecastNotReady => '아직 예보 제공 전 · 라운드 7일 전부터 확인하세요';

  @override
  String get widgetChecking => '날씨 확인 중 · 눌러서 앱 열기';

  @override
  String get widgetWeatherFailed => '날씨를 확인하지 못했습니다 · 앱에서 다시 확인';

  @override
  String get widgetInfoFailed => '정보를 확인하지 못했습니다 · 앱에서 다시 확인';

  @override
  String get ocrTitle => '스코어카드 OCR';

  @override
  String get ocrCameraAccessFailed =>
      '카메라 접근에 실패했습니다. 아래 \"앱 설정\"을 눌러 Golf Windy의 카메라 권한을 확인해 주세요.';

  @override
  String get ocrOpenAppSettings => '앱 설정';

  @override
  String get ocrGalleryOpenFailed =>
      '사진 선택 화면을 열지 못했습니다. 앱을 완전히 종료한 뒤 다시 시도해 주세요.';

  @override
  String ocrImageLoadFailed(String error) {
    return '이미지를 불러오지 못했습니다: $error';
  }

  @override
  String ocrRecognizeFailed(String error) {
    return 'OCR 인식에 실패했습니다: $error';
  }

  @override
  String get ocrCameraPermissionOff =>
      '카메라 권한이 꺼져 있어 OCR 촬영을 시작할 수 없습니다. 아래 \"앱 설정\"을 눌러 Golf Windy의 카메라 권한을 허용해 주세요.';

  @override
  String get ocrCameraPermissionNeeded =>
      '카메라 권한이 필요합니다. 권한을 허용한 뒤 다시 시도해 주세요.';

  @override
  String get ocrNoCompanionsToReview => '검토가 필요한 동반자 이름이 없습니다.';

  @override
  String get ocrReviewAllDone => '좋아요, 검토가 필요한 동반자 이름을 모두 확인했어요.';

  @override
  String ocrReviewProgress(int reviewed, int remaining) {
    return '검토를 $reviewed명 진행했고, 아직 $remaining명 남아 있습니다.';
  }

  @override
  String get ocrApplyToScorecard => '현재 스코어카드에 적용';

  @override
  String get ocrScanCardTitle => '스코어카드 이미지 스캔';

  @override
  String get ocrScanCardDesc =>
      '사진 속 숫자를 읽어 홀별 타수 후보를 만듭니다. 인식 결과는 반드시 확인 후 적용하세요.';

  @override
  String get ocrPickPhoto => '사진 선택';

  @override
  String get ocrTakePhoto => '촬영';

  @override
  String get ocrSummaryTitle => 'OCR 요약';

  @override
  String get ocrChipTotal => '총합';

  @override
  String get ocrFrontNine => '전반';

  @override
  String get ocrBackNine => '후반';

  @override
  String get ocrChipScoredCompanions => '점수 동반자';

  @override
  String get ocrChipNameOnly => '이름만 감지';

  @override
  String get ocrChipNameReview => '이름 검토';

  @override
  String get ocrChipNeeded => '필요';

  @override
  String ocrStrokesValue(int n) {
    return '$n타';
  }

  @override
  String ocrPeopleValue(int n) {
    return '$n명';
  }

  @override
  String get ocrLabelCourse => '골프장';

  @override
  String get ocrLabelRound => '라운드';

  @override
  String get ocrLabelPlayer => '본인';

  @override
  String get ocrSummaryEmptyHint =>
      '사진을 선택하거나 촬영하면 OCR 결과가 여기에 정리됩니다. 읽은 뒤에만 현재 스코어카드에 적용할 수 있어요.';

  @override
  String ocrSummaryChangedHint(int n) {
    return '기본 스코어카드와 다른 홀 $n개가 반영됐어요. 전반/후반 점수 흐름과 동반자 이름을 한 번만 더 확인하면 좋습니다.';
  }

  @override
  String get ocrSummaryNoChangeHint =>
      '기본 코스 정보와 큰 차이는 없어요. 그래도 손글씨 카드라면 합계와 동반자 이름은 한 번 확인해 주세요.';

  @override
  String get ocrMyScorePreview => '내 스코어 미리보기';

  @override
  String get ocrMyScorePreviewDesc => '전반/후반 흐름과 파 대비 결과를 보면서 이상한 홀을 바로 수정하세요.';

  @override
  String ocrPuttsValue(int n) {
    return '퍼트 $n';
  }

  @override
  String get ocrPuttsNotTracked => '퍼트 미입력';

  @override
  String get ocrRawTextTitle => '원문 OCR';

  @override
  String get ocrRawTextCopied => '원문 OCR을 복사했어요.';

  @override
  String get ocrCopyRawText => '원문 복사';

  @override
  String get ocrCompanionCandidatesTitle => '감지된 동반자 후보';

  @override
  String get ocrCompanionCandidatesDesc =>
      '적용하면 아직 없는 이름만 동반자 목록에 자동 추가됩니다. 점수까지 읽힌 동반자는 이름과 홀별 타수를 바로 수정할 수 있습니다.';

  @override
  String ocrCompanionNamesNeedReview(int n) {
    return '$n명의 이름은 확인이 필요합니다.';
  }

  @override
  String get ocrReviewCompanionsInOrder => '검토 필요한 동반자 순서대로 보기';

  @override
  String get ocrScoredCompanionsTitle => '점수까지 감지된 동반자';

  @override
  String get ocrFlagNameCheck => '이름 확인';

  @override
  String get ocrFlagDuplicate => '중복 후보';

  @override
  String ocrFrontBackTotals(int front, int back) {
    return '전반 $front · 후반 $back';
  }

  @override
  String get ocrNameOnlyCandidatesTitle => '이름만 감지된 동반자 후보';

  @override
  String ocrNameCheckChip(String name) {
    return '$name 확인';
  }

  @override
  String ocrHoleEditTitle(int n) {
    return '$n번 홀 보정';
  }

  @override
  String get ocrHoleEditDesc => '손글씨 카드나 흐릿한 숫자는 여기서 바로 수정하세요.';

  @override
  String get ocrLabelStrokes => '타수';

  @override
  String get ocrLabelPutts => '퍼트';

  @override
  String get ocrApplyFix => '보정 반영';

  @override
  String get ocrCompanionEditTitle => '동반자 OCR 보정';

  @override
  String get ocrLabelName => '이름';

  @override
  String get ocrCompanionNameHint => '동반자 이름';

  @override
  String get ocrNameTooShortWarning =>
      '너무 짧거나 애매한 이름입니다. 추천 이름이나 원문 OCR을 함께 확인해 주세요.';

  @override
  String get ocrDuplicateNameWarning =>
      '다른 동반자와 이름이 같습니다. 같은 분이 아니라면 이름을 구분해 주세요.';

  @override
  String get ocrFrequentNames => '자주 함께한 이름';

  @override
  String get ocrHighSimilarity => '유사도 높음';

  @override
  String ocrRoundsValue(int n) {
    return '$n회';
  }

  @override
  String ocrCurrentTotal(int n) {
    return '현재 합계 $n타';
  }

  @override
  String get ocrApplyCompanionFix => '동반자 보정 반영';

  @override
  String get ocrHoleStrokesTitle => '홀별 타수';

  @override
  String get ocrCompanionHoleEditDesc => '동반자 홀을 눌러 타수를 수정하세요.';

  @override
  String ocrCompanionHoleTitle(int n) {
    return '$n번 홀 동반자 타수';
  }

  @override
  String ocrCompanionHoleDesc(int par) {
    return 'Par $par 기준으로 타수를 보정합니다.';
  }

  @override
  String get ocrApplyStrokes => '타수 반영';

  @override
  String get restTabBreakfast => '조식';

  @override
  String get restTabLunch => '중식';

  @override
  String restFilterNoteWithAddress(String address) {
    return '카페·디저트 제외 · $address 기준 가까운 순 우선';
  }

  @override
  String get restFilterNote => '카페·디저트 제외 · 실제 후기는 상세에서 확인';

  @override
  String restLoadError(String error) {
    return '오류가 발생했습니다: $error';
  }

  @override
  String restEmptyNearby(String lat, String lng) {
    return '근처에 추천 식당이 없습니다\n(위치: $lat, $lng)';
  }

  @override
  String restRatingLabel(String rating) {
    return '별점 $rating';
  }

  @override
  String restDistanceCategory(String distance, String category) {
    return '${distance}km · $category';
  }

  @override
  String get restDirections => '길찾기';

  @override
  String get restViewDetails => '상세 보기';

  @override
  String get restAddressLabel => '주소';

  @override
  String get restHoursLabel => '영업시간';

  @override
  String get restCall => '전화';

  @override
  String get restViewReviews => '후기 보기';

  @override
  String get restRecommendationCriteria => '추천 기준';

  @override
  String get restNavKakaoTitle => '카카오맵으로 길찾기';

  @override
  String get restNavKakaoSubtitle => '설치되어 있으면 앱으로 열고, 없으면 웹으로 연결';

  @override
  String get restNavNaverTitle => '네이버 지도로 길찾기';

  @override
  String get restNavNaverSubtitle => '네이버 지도 앱이 있으면 바로 연결';

  @override
  String get restNavWebTitle => '웹 지도로 열기';

  @override
  String get restNavWebSubtitle => '지도 앱이 없어도 브라우저에서 확인';

  @override
  String get restNavOpenFailed => '길찾기를 열 수 없습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String restSearchError(String error) {
    return '식당 검색 중 오류가 발생했습니다.\n$error';
  }

  @override
  String get restApiAuthError =>
      '카카오 API 인증에 실패했습니다. 개발자 콘솔에서 REST API 키를 확인해 주세요.';

  @override
  String get restApiForbiddenError =>
      '카카오 API 사용이 제한되었습니다. 앱 플랫폼(iOS) 등록 여부를 확인해 주세요.';

  @override
  String restApiError(int statusCode) {
    return '식당 API 오류 ($statusCode)';
  }

  @override
  String get restHoursPending => '정보 확인 필요';

  @override
  String get restHoursUnspecified => '미지정';

  @override
  String get restReviewHint1 => '카카오 장소 페이지에서 방문 후기와 사진을 확인해 보세요.';

  @override
  String get restReviewHint2 => '라운드 전후 식사에 맞는 음식점 카테고리만 선별했습니다.';

  @override
  String get schedEnterCourseName => '골프장을 입력해주세요';

  @override
  String schedCourseNotInDb(String name) {
    return '$name는 DB에 없어 날씨 알림 없이 커스텀 일정으로 저장합니다';
  }

  @override
  String schedErrorWithDetail(String error) {
    return '오류: $error';
  }

  @override
  String get schedCalendarPermissionNeeded =>
      '캘린더 접근 권한이 필요합니다. 설정에서 캘린더 권한을 허용해 주세요.';

  @override
  String get schedNoCalendarCandidates => '최근/예정 캘린더에서 골프 일정 후보를 찾지 못했어요.';

  @override
  String schedCalendarImportFailed(String error) {
    return '캘린더 일정을 불러오지 못했어요: $error';
  }

  @override
  String get schedCalendarCandidatesTitle => '캘린더 일정 후보';

  @override
  String get schedCalendarCandidatesDesc =>
      '가져올 일정을 선택하면 골프장, 날짜, 티오프 시간이 입력됩니다.';

  @override
  String get schedPortalFoundCourse =>
      '포털 검색으로 찾은 골프장이에요 (DB 외) — 주소를 확인해 주세요.';

  @override
  String get schedVerifyCourseName => '골프장명은 저장 전 한 번 확인해 주세요.';

  @override
  String get schedCalendarApplied => '캘린더 일정 정보를 입력했습니다. 저장 전 확인해 주세요.';

  @override
  String get schedEditSchedule => '일정 수정';

  @override
  String get schedAddNewSchedule => '새 일정 추가';

  @override
  String get schedSaveSchedule => '일정 저장';

  @override
  String get schedIntro => '라운드 정보를 입력하면 골프장 날씨와 알림을 함께 확인할 수 있습니다.';

  @override
  String get schedDateLabel => '날짜 *';

  @override
  String get schedTimeLabel => '시간 *';

  @override
  String get schedCourseLabel => '골프장 *';

  @override
  String get schedAddressLabel => '주소/위치 메모';

  @override
  String get schedTitleLabel => '제목';

  @override
  String get schedNotifyLabel => '알림';

  @override
  String get schedCourseHint => '예: 레이크사이드CC';

  @override
  String get schedAddressHint => '예: 경기도 용인시 처인구 ...';

  @override
  String get schedTitleHint => '예: 주말 라운드';

  @override
  String get schedWeatherAlertToggle => '날씨 위험 알림 받기';

  @override
  String get schedCheckingCalendar => '캘린더 확인 중';

  @override
  String get schedImportFromCalendar => '캘린더에서 가져오기';

  @override
  String schedHoursBefore(int hours) {
    return '$hours시간 전';
  }

  @override
  String schedDaysBefore(int days) {
    return '$days일 전';
  }

  @override
  String get schedDateFmt => 'M월 d일 (E)';

  @override
  String get schedCalendarDateFmt => 'yyyy.MM.dd (E) HH:mm';

  @override
  String get eventStatusOptimal => '최적';

  @override
  String get eventStatusCaution => '주의';

  @override
  String get eventStatusCancelRecommended => '취소권장';

  @override
  String get eventStatusUnknown => '정보없음';

  @override
  String get eventDeleteTitle => '일정 삭제';

  @override
  String get eventDeleteConfirm => '이 일정을 삭제하시겠습니까?';

  @override
  String eventErrorWithDetail(String error) {
    return '오류: $error';
  }

  @override
  String get eventNotifPermissionNeeded => '알림 권한이 필요합니다. 설정에서 허용해주세요.';

  @override
  String get eventSubscribeNoCourse => '골프장 정보를 찾을 수 없어 구독할 수 없습니다.';

  @override
  String get eventSubscribeSuccess => '날씨 변화 알림을 등록했습니다.';

  @override
  String get eventSubscribeFailed => '알림 등록에 실패했습니다.';

  @override
  String get eventBookingForecastTitle => '부킹 시간대 예보';

  @override
  String eventBookingTimeBase(String time) {
    return '부킹 $time 기준';
  }

  @override
  String get eventStartMarker => '시작';

  @override
  String eventRainProb(int prob) {
    return '비 $prob%';
  }

  @override
  String get eventRestaurantTitle => '근처 식당 추천';

  @override
  String get eventRestaurantSubtitle => '조식·중식 장소를 찾아보세요';

  @override
  String get eventForecastNotYet => '아직 예보 제공 전 · 라운드 7일 전부터 확인하세요';

  @override
  String get eventWeatherPendingTitle => '날씨 준비 중인 일정';

  @override
  String get eventWeatherPendingDesc =>
      '골프장 매칭 또는 예보 캐시가 아직 준비되지 않았습니다. 일정, 지도, 식당 추천은 사용할 수 있고 날씨는 잠시 후 다시 확인해 주세요.';

  @override
  String get eventMapHint => '지도 표시가 안 되면 일정 수정에서 골프장명과 주소를 함께 입력해 주세요.';

  @override
  String get eventScorecardTitle => '스코어카드';

  @override
  String get eventScorecardSubtitle => '18홀 타수·퍼트·페어웨이 기록';

  @override
  String get calDefaultGolfTitle => '골프 일정';

  @override
  String get scoreHistoryTitle => '스코어 관리';

  @override
  String get scoreDeleteTitle => '스코어 삭제';

  @override
  String scoreDeleteConfirm(String courseName) {
    return '$courseName 기록을 삭제할까요?';
  }

  @override
  String get scoreDeletedSnack => '스코어 기록을 삭제했습니다.';

  @override
  String get scoreCourseNameUpdatedSnack => '골프장 이름을 수정했습니다.';

  @override
  String get scoreOcrScanning => 'OCR 스캐닝';

  @override
  String get scoreRoundDate => '라운드 날짜';

  @override
  String get scoreToday => '오늘';

  @override
  String get scoreYesterday => '어제';

  @override
  String get scoreSevenDaysAgo => '7일 전';

  @override
  String get scoreOcrNoCourseNameHint =>
      '골프장 이름은 먼저 입력하지 않아도 됩니다. 먼저 OCR로 읽고, 필요한 경우에만 마지막에 보정할게요.';

  @override
  String get scoreOcrStart => 'OCR 스캔 시작';

  @override
  String get scoreRecentRounds => '최근 라운드';

  @override
  String get scoreLifeBest => '라이프베스트';

  @override
  String scoreRecentAvgChip(String avg) {
    return '최근 5R 평균 $avg';
  }

  @override
  String scoreThisMonthChip(int count) {
    return '이번 달 ${count}R';
  }

  @override
  String scoreCompanionChip(int count) {
    return '동반자 기록 ${count}R';
  }

  @override
  String scoreDetailCompleteChip(int count) {
    return '세부 완료 ${count}R';
  }

  @override
  String scoreOptionalFixChip(int count) {
    return '선택 보정 ${count}R';
  }

  @override
  String scoreOptionalMetricsCount(int count) {
    return '선택 세부 지표 $count건';
  }

  @override
  String scoreDetailRecordPercent(int percent) {
    return '세부 기록 $percent%';
  }

  @override
  String scoreOptionalInputHoles(int count) {
    return '선택 입력 $count홀';
  }

  @override
  String scorePuttsTrackedChip(int tracked, int total) {
    return '퍼트 $tracked/$total홀';
  }

  @override
  String scoreFairwayTrackedChip(int tracked, int total) {
    return '페어웨이 $tracked/$total홀';
  }

  @override
  String scoreFirstIncompleteChip(int hole) {
    return '첫 선택 항목 ${hole}H';
  }

  @override
  String get scoreTotalRounds => '총 라운드';

  @override
  String scoreTimesCount(int count) {
    return '$count회';
  }

  @override
  String get scoreRoundsThisYear => '올해 라운드';

  @override
  String get scoreThisMonth => '이번 달';

  @override
  String get scoreRecentAvgLabel => '최근 5R 평균';

  @override
  String get scoreCompanionRecords => '동반자 기록';

  @override
  String get scoreNotRecordedYet => '아직 기록 전';

  @override
  String get scoreCompanionSavedCaption => '동반자 정보가 함께 저장된 라운드';

  @override
  String get scoreOptionalFix => '선택 보정';

  @override
  String get scoreAllScoresSaved => '스코어 기록은 모두 저장됨';

  @override
  String get scoreOptionalDetailCaption => '퍼트/페어웨이 등 선택 세부 지표';

  @override
  String scoreCompanionCountBadge(int count) {
    return '동반자 $count명';
  }

  @override
  String get scorePuttRecordBadge => '퍼트 기록';

  @override
  String get scoreFairwayRecordBadge => '페어웨이 기록';

  @override
  String scoreTrackingSummary(
      int puttTracked, int puttTotal, int fairwayTracked, int fairwayTotal) {
    return '선택 지표: 퍼트 $puttTracked/$puttTotal홀 · 페어웨이 $fairwayTracked/$fairwayTotal홀';
  }

  @override
  String get scoreEditCourseName => '골프장명 수정';

  @override
  String get scoreEditCourseNameDesc =>
      'OCR로 저장된 골프장명이 비었거나 다르면 여기서 바로 고칠 수 있어요.';

  @override
  String get scoreCourseNameLabel => '골프장 이름';

  @override
  String get scoreCourseNameHint => '예: 드림파크CC';

  @override
  String get scoreOcrCardTitle => '스코어카드 OCR 스캔';

  @override
  String get scoreOcrCardDesc => '일정 상세의 스코어카드에서 사진을 읽어 적용';

  @override
  String get scoreOcrGuide => 'OCR 가이드';

  @override
  String get scoreEmptyTitle => '아직 저장된 스코어가 없습니다';

  @override
  String get scoreEmptyDesc =>
      '일정 상세 화면에서 스코어카드를 열고 저장하거나\n지난 라운드를 OCR로 바로 등록하면 기록이 여기에 쌓입니다.';

  @override
  String get scoreOcrSheetTitle => '스코어카드 OCR 가져오기';

  @override
  String get scoreOcrSheetDesc =>
      '일정 상세에서 바로 스캔할 수도 있고, 지난 라운드도 OCR 등록으로 기록을 시작할 수 있습니다.';

  @override
  String get scoreOcrStep1 => '스코어카드 화면을 캡처하거나 종이 스코어카드를 촬영';

  @override
  String get scoreOcrStep2 => '일정 상세 스코어카드 또는 OCR 스캐닝에서 이미지 선택';

  @override
  String get scoreOcrStep3 => '홀별 점수를 확인하면 자동 저장되고, 필요할 때만 보정';

  @override
  String get scoreOcrStartShort => 'OCR 시작';

  @override
  String scoreCompanionOne(String name) {
    return '동반자 $name';
  }

  @override
  String scoreCompanionTwo(String name1, String name2) {
    return '동반자 $name1 · $name2';
  }

  @override
  String scoreCompanionMore(String name1, String name2, int count) {
    return '동반자 $name1 · $name2 외 $count명';
  }

  @override
  String get scoreCardSavedSnack => '스코어카드를 저장했습니다.';

  @override
  String scoreSaveFailedSnack(String error) {
    return '저장하지 못했습니다: $error';
  }

  @override
  String get scoreCourseNameConfirmTitle => '골프장 이름 확인';

  @override
  String get scoreCourseNameMissingDesc =>
      '이번 카드에서는 골프장 이름을 읽지 못했어요. 저장 전에 골프장 이름만 입력해 주세요.';

  @override
  String get scoreContinueSave => '저장 계속';

  @override
  String get scoreOcrLoadedSnack => 'OCR 결과를 불러왔어요. 홀별 점수만 한 번 확인해 주세요.';

  @override
  String scoreOcrLoadedWithCompanionsSnack(int count) {
    return 'OCR 결과와 동반자 $count명 기록을 불러왔어요.';
  }

  @override
  String get scoreSaving => '저장 중';

  @override
  String get scoreSaveButton => '스코어 저장';

  @override
  String get scorePastRoundOcr => '지난 라운드 OCR';

  @override
  String get scoreCardLabel => '스코어카드';

  @override
  String get scoreCompanionOcrResult => '동반자 OCR 결과';

  @override
  String get scoreTotalStrokes => '총타';

  @override
  String get scoreScoreLabel => '스코어';

  @override
  String get scorePutts => '퍼트';

  @override
  String get scoreFairway => '페어웨이';

  @override
  String get scoreObPenalty => 'OB/벌타';

  @override
  String get scoreStrokes => '타수';

  @override
  String get scorePenalty => '벌타';

  @override
  String get scoreFairwayHit => '성공';

  @override
  String get scoreFairwayMiss => '실패';

  @override
  String get scoreFairwayNotApplicable => '해당 없음';

  @override
  String get scoreStageComplete => '세부 기록 완료';

  @override
  String get scoreStageScoreOnly => '스코어 저장';

  @override
  String get scoreStageNearlyComplete => '세부 기록 거의 완료';

  @override
  String get scoreStageInProgress => '세부 기록 일부';

  @override
  String get scoreStageDescComplete => '퍼트와 페어웨이까지 모두 기록했어요.';

  @override
  String get scoreStageDescScoreOnly => '스코어는 저장됐고 세부 기록은 비어 있어요.';

  @override
  String get scoreStageDescNearlyComplete => '세부 기록이 거의 끝났어요. 몇 홀만 더 확인하면 됩니다.';

  @override
  String get scoreStageDescInProgress => '세부 기록을 이어서 보정할 수 있어요.';
}
