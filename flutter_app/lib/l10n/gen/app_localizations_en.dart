// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Golf Windy';

  @override
  String get commonConfirm => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get commonNone => 'None';

  @override
  String get commonDone => 'Done';

  @override
  String get commonNext => 'Next';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonStart => 'Get Started';

  @override
  String get navHome => 'Home';

  @override
  String get navSchedule => 'Rounds';

  @override
  String get navMap => 'Map';

  @override
  String get navSettings => 'Settings';

  @override
  String get setTitle => 'Settings';

  @override
  String get setSectionTheme => 'Theme';

  @override
  String get setSectionThresholds => 'Alert Thresholds';

  @override
  String get setRainThresholdLabel => 'Rain probability';

  @override
  String get setWindThresholdLabel => 'Wind speed';

  @override
  String get setThresholdHint =>
      'YELLOW/RED advisories trigger above these thresholds';

  @override
  String get setSectionRoundProfile => 'Round Preferences';

  @override
  String get setSensitivityRain => 'Rain sensitivity';

  @override
  String get setSensitivityWind => 'Wind sensitivity';

  @override
  String get setSensitivityCold => 'Cold sensitivity';

  @override
  String get setSensitivityHeat => 'Heat sensitivity';

  @override
  String get setSensitivityHint =>
      'Higher sensitivity makes round suitability more conservative';

  @override
  String get setSectionNotifyTiming => 'Notification Timing';

  @override
  String get setNotifyTimingQuestion =>
      'How long before a round should we notify you?';

  @override
  String setHoursBefore(int h) {
    return '${h}h before';
  }

  @override
  String get setSectionNotifyPermission => 'Notification Permission';

  @override
  String get setNotifyPermissionButton => 'Request / re-register permission';

  @override
  String get setNotifyGranted => 'Notification permission granted.';

  @override
  String get setNotifyDenied => 'Notification permission denied.';

  @override
  String get setSectionHelp => 'Help';

  @override
  String get setHelpDesc => 'Reopen the guide to the app\'s key features.';

  @override
  String get setHelpTutorialButton => 'Replay Tutorial';

  @override
  String get setSectionScore => 'Scores';

  @override
  String get setScoreDesc =>
      'Open OCR scanning and past round history from here.';

  @override
  String get setScoreOpenButton => 'Open Score Manager';

  @override
  String get setSectionDevice => 'Device Info';

  @override
  String get setDeviceTokenLabel => 'Anonymous device token';

  @override
  String get setDeviceTokenLoading => 'Loading...';

  @override
  String get setDevicePrivacyNote =>
      'This app collects no personal data. The token above is a random identifier used only for notifications.';

  @override
  String get setLanguageSection => 'Language';

  @override
  String get setLanguageTitle => 'App Language';

  @override
  String get setLanguageSystem => 'Use device language';

  @override
  String get setLanguageKorean => '한국어';

  @override
  String get setLanguageEnglish => 'English';

  @override
  String get whatsNewTitle => 'What\'s New';

  @override
  String whatsNewSubtitle(String version) {
    return 'New in v$version.';
  }

  @override
  String suitRed(int dday, String label) {
    return 'D-$dday Consider cancelling — $label warning';
  }

  @override
  String suitYellow(int dday, String label) {
    return 'D-$dday Caution — bring $label';
  }

  @override
  String suitGreen(int dday) {
    return 'D-$dday Good conditions for golf';
  }

  @override
  String get suitWorstRain => 'severe weather';

  @override
  String get suitWorstWind => 'strong wind';

  @override
  String get suitWorstCold => 'extreme cold';

  @override
  String get suitWorstHeat => 'extreme heat';

  @override
  String get suitPrepRain => 'rain gear';

  @override
  String get suitPrepWind => 'windproof layers';

  @override
  String get suitPrepCold => 'warm layers';

  @override
  String get suitPrepHeat => 'heat protection';

  @override
  String suitDetailRainProb(int p) {
    return 'Rain $p%';
  }

  @override
  String suitDetailWind(String w) {
    return 'Wind $w m/s';
  }

  @override
  String suitDetailMinTemp(int t) {
    return 'Low $t°C';
  }

  @override
  String suitDetailMaxTemp(int t) {
    return 'High $t°C';
  }

  @override
  String get suitDetailLightning => 'Lightning forecast';

  @override
  String get suitDetailProfileApplied => ' — based on your round preferences';

  @override
  String get weatherPendingMessage =>
      'Weather data isn\'t ready yet.\nThe course is in our database, but its forecast cache hasn\'t been collected yet or the coordinates may need adjusting. Check back shortly, or edit the course name on the schedule.';

  @override
  String weatherUnavailableMessage(String url) {
    return 'Couldn\'t load weather data.\nCheck your network connection or the server status. If you\'re testing on a device, make sure the API address in settings points to the production server.\nCurrent address: $url';
  }

  @override
  String get splashTagline => 'Smart round management';

  @override
  String get mapCourseLocation => 'Course location';

  @override
  String get themeSubtitleFairwaySky => 'Cool teal · Dark';

  @override
  String get themeSubtitleLightAir => 'Off-white · Light';

  @override
  String get themeSubtitleMidnightLime => 'Navy + lime · Dark';

  @override
  String get notifChannelName => 'Weather Alerts';

  @override
  String get notifChannelDesc => 'Weather change alerts for your golf rounds';

  @override
  String get sensitivityLow => 'Relaxed';

  @override
  String get sensitivityNormal => 'Normal';

  @override
  String get sensitivityHigh => 'Sensitive';

  @override
  String get homeStatusGreen => 'Ideal';

  @override
  String get homeStatusYellow => 'Caution';

  @override
  String get homeStatusRed => 'Cancel advised';

  @override
  String get homeStatusNone => 'No data';

  @override
  String get tutTitle => 'Golf Windy Quick Tour';

  @override
  String get tutSubtitle =>
      'A quick look at the key features, then you\'re all set.';

  @override
  String get tutStep1Title => 'Check right from Home';

  @override
  String get tutStep1Desc =>
      'See your upcoming round and weather advisories right on the first screen.';

  @override
  String get tutStep1Bullet1 => 'Quickly check GREEN / YELLOW / RED advisories';

  @override
  String get tutStep1Bullet2 => 'Pull down to refresh the latest forecast';

  @override
  String get tutStep2Title => 'Add rounds in seconds';

  @override
  String get tutStep2Desc =>
      'Pick a golf course in the Schedule tab and save your tee-off time — that\'s it.';

  @override
  String get tutStep2Bullet1 => 'Search for a course and create a round';

  @override
  String get tutStep2Bullet2 =>
      'Weather and scorecards linked from round details';

  @override
  String get tutStep3Title => 'Maps and nearby eats';

  @override
  String get tutStep3Desc =>
      'See the selected course and nearby restaurants together in the Map tab.';

  @override
  String get tutStep3Bullet1 => 'View the course location on Naver Map';

  @override
  String get tutStep3Bullet2 =>
      'Find breakfast and lunch spots around the course';

  @override
  String get tutStep4Title => 'Save past rounds with OCR';

  @override
  String get tutStep4Desc =>
      'Just pick a photo in score management to quickly log a past round.';

  @override
  String get tutStep4Bullet1 =>
      'Start OCR from round details or score management';

  @override
  String get tutStep4Bullet2 => 'Replay this tutorial anytime from Settings';

  @override
  String get tutPrev => 'Back';

  @override
  String get tutFooter =>
      'You can revisit this tutorial anytime in the Settings tab.';

  @override
  String homeCalendarError(String error) {
    return 'Calendar error: $error';
  }

  @override
  String get homeEmptyTitle => 'No golf rounds scheduled';

  @override
  String get homeEmptyBody =>
      'Add a golf round to your calendar\nand we\'ll check the weather for you';

  @override
  String homeUpcomingRounds(int count) {
    return 'Upcoming rounds · $count';
  }

  @override
  String get homeNextRoundDday => 'Next round · D-DAY';

  @override
  String homeNextRoundDdayN(int n) {
    return 'Next round · D-$n';
  }

  @override
  String homeTeeOffAt(String date, String time) {
    return 'Tee off $date $time';
  }

  @override
  String homeFeelsLikeInline(int temp) {
    return ' · Feels like $temp°';
  }

  @override
  String get homeTeeOffForecast => 'Tee-time forecast';

  @override
  String get homeForecastNotYet =>
      'Forecast not available yet · Check back within 7 days of your round';

  @override
  String get homeAlertSevere => 'Severe weather — cancellation advised';

  @override
  String get homeAlertCaution => 'Weather caution';

  @override
  String get homeStatFeelsLike => 'Feels like';

  @override
  String get homeStatRainProb => 'Rain chance';

  @override
  String get homeStatWind => 'Wind';

  @override
  String homeAiRecommend(String label) {
    return 'AI pick · $label';
  }

  @override
  String get homeWxPreparing =>
      'Weather not ready · Check course name/coordinates';

  @override
  String get homeDeleteSchedule => 'Delete round';

  @override
  String homeDeleteScheduleConfirm(String name) {
    return 'Delete the round at $name?';
  }

  @override
  String get homeScheduleDeleted => 'Round deleted.';

  @override
  String homeScheduleDeleteFailed(String error) {
    return 'Couldn\'t delete the round: $error';
  }

  @override
  String homeScheduleLoadError(String error) {
    return 'Failed to load schedule: $error';
  }

  @override
  String get homeImportCalendar => 'Import from calendar';

  @override
  String get homeNextRound => 'Next round';

  @override
  String homeRainShort(int prob) {
    return 'Rain $prob%';
  }

  @override
  String homeMapLoadError(String error) {
    return 'Map load error: $error';
  }

  @override
  String homeMapLoading(String name) {
    return 'Loading map for $name';
  }

  @override
  String get homeMapNoCoords =>
      'No coordinates to show on the map.\nAdd an address in round editing to display the location.';

  @override
  String get wxPolicyUnverified =>
      'Check the cancellation policy with your booking provider';

  @override
  String wxTimeLabel(String h) {
    return '$h:00';
  }

  @override
  String get wxTimeLabelUnknown => '--:--';

  @override
  String get wxRainHeavy => 'Heavy rain';

  @override
  String get wxRainLight => 'Light rain';

  @override
  String get wxRainDrizzle => 'A few drops';

  @override
  String get wxClear => 'Clear';

  @override
  String get wxNoInfo => 'No info';

  @override
  String get wxBoardingReport => 'Boarding report';

  @override
  String get evtDateFmt => 'EEE, M/d';

  @override
  String get shareGolfWeatherHeader => '⛳ Golf Windy — Round Weather';

  @override
  String get shareAiSection => '[ AI Recommendation ]';

  @override
  String get shareForecastSection => '[ Hourly Forecast ]';

  @override
  String shareForecastLine(
      String time, String emoji, int temp, int rain, String wind) {
    return '$time  $emoji  $temp°  Rain $rain%  Wind ${wind}m/s';
  }

  @override
  String get shareCancelSection => '[ Cancellation Info ]';

  @override
  String shareRainCancelPolicy(String condition) {
    return '🌧️ Rain cancellation policy: $condition';
  }

  @override
  String get shareFooter =>
      'Check your round schedule and weather in Golf Windy.';

  @override
  String shareWeatherSubject(String course, String message) {
    return '$course weather — $message';
  }

  @override
  String get shareScheduleHeader => '⛳ Golf Windy — Round Schedule';

  @override
  String get shareWeatherPending =>
      'Weather info isn\'t ready yet. Check the weather and cancellation advice again in Golf Windy before your round.';

  @override
  String shareScheduleSubject(String course) {
    return '$course round schedule';
  }

  @override
  String get shareDateFmt => 'EEE, MMM d, HH:mm';

  @override
  String get widgetNoSchedule => 'Open the app to add a round';

  @override
  String get widgetForecastNotReady =>
      'Forecast not available yet · Check from 7 days before your round';

  @override
  String get widgetChecking => 'Checking weather · Tap to open the app';

  @override
  String get widgetWeatherFailed =>
      'Couldn\'t load weather · Check again in the app';

  @override
  String get widgetInfoFailed => 'Couldn\'t load info · Check again in the app';

  @override
  String get ocrTitle => 'Scorecard OCR';

  @override
  String get ocrCameraAccessFailed =>
      'Camera access failed. Tap \"App Settings\" below to check Golf Windy\'s camera permission.';

  @override
  String get ocrOpenAppSettings => 'App Settings';

  @override
  String get ocrGalleryOpenFailed =>
      'Couldn\'t open the photo picker. Fully close the app and try again.';

  @override
  String ocrImageLoadFailed(String error) {
    return 'Failed to load the image: $error';
  }

  @override
  String ocrRecognizeFailed(String error) {
    return 'OCR recognition failed: $error';
  }

  @override
  String get ocrCameraPermissionOff =>
      'Camera permission is off, so OCR capture can\'t start. Tap \"App Settings\" below to allow Golf Windy\'s camera permission.';

  @override
  String get ocrCameraPermissionNeeded =>
      'Camera permission is required. Allow it and try again.';

  @override
  String get ocrNoCompanionsToReview => 'No companion names need review.';

  @override
  String get ocrReviewAllDone =>
      'Great — every companion name that needed review has been checked.';

  @override
  String ocrReviewProgress(int reviewed, int remaining) {
    return 'Reviewed $reviewed companions; $remaining still remaining.';
  }

  @override
  String get ocrApplyToScorecard => 'Apply to current scorecard';

  @override
  String get ocrScanCardTitle => 'Scan a scorecard image';

  @override
  String get ocrScanCardDesc =>
      'Reads the numbers in the photo to suggest per-hole strokes. Always review the results before applying.';

  @override
  String get ocrPickPhoto => 'Choose photo';

  @override
  String get ocrTakePhoto => 'Take photo';

  @override
  String get ocrSummaryTitle => 'OCR summary';

  @override
  String get ocrChipTotal => 'Total';

  @override
  String get ocrFrontNine => 'Front 9';

  @override
  String get ocrBackNine => 'Back 9';

  @override
  String get ocrChipScoredCompanions => 'Scored companions';

  @override
  String get ocrChipNameOnly => 'Names only';

  @override
  String get ocrChipNameReview => 'Name review';

  @override
  String get ocrChipNeeded => 'Needed';

  @override
  String ocrStrokesValue(int n) {
    return '$n';
  }

  @override
  String ocrPeopleValue(int n) {
    return '$n';
  }

  @override
  String get ocrLabelCourse => 'Course';

  @override
  String get ocrLabelRound => 'Round';

  @override
  String get ocrLabelPlayer => 'You';

  @override
  String get ocrSummaryEmptyHint =>
      'Choose or take a photo and the OCR results will be summarized here. You can apply them to the current scorecard only after a scan.';

  @override
  String ocrSummaryChangedHint(int n) {
    return '$n holes differ from the base scorecard. Give the front/back score flow and companion names one more look.';
  }

  @override
  String get ocrSummaryNoChangeHint =>
      'No big differences from the base course info. Still, for handwritten cards, double-check the totals and companion names.';

  @override
  String get ocrMyScorePreview => 'My score preview';

  @override
  String get ocrMyScorePreviewDesc =>
      'Review the front/back flow and score vs. par, and fix any odd holes right away.';

  @override
  String ocrPuttsValue(int n) {
    return 'Putts $n';
  }

  @override
  String get ocrPuttsNotTracked => 'No putts entered';

  @override
  String get ocrRawTextTitle => 'Raw OCR text';

  @override
  String get ocrRawTextCopied => 'Raw OCR text copied.';

  @override
  String get ocrCopyRawText => 'Copy raw text';

  @override
  String get ocrCompanionCandidatesTitle => 'Detected companion candidates';

  @override
  String get ocrCompanionCandidatesDesc =>
      'Applying adds only new names to your companion list. For companions whose scores were read, you can edit the name and per-hole strokes right away.';

  @override
  String ocrCompanionNamesNeedReview(int n) {
    return '$n companion names need checking.';
  }

  @override
  String get ocrReviewCompanionsInOrder => 'Review flagged companions in order';

  @override
  String get ocrScoredCompanionsTitle => 'Companions with detected scores';

  @override
  String get ocrFlagNameCheck => 'Check name';

  @override
  String get ocrFlagDuplicate => 'Possible duplicate';

  @override
  String ocrFrontBackTotals(int front, int back) {
    return 'Front $front · Back $back';
  }

  @override
  String get ocrNameOnlyCandidatesTitle => 'Candidates detected by name only';

  @override
  String ocrNameCheckChip(String name) {
    return 'Check $name';
  }

  @override
  String ocrHoleEditTitle(int n) {
    return 'Fix hole $n';
  }

  @override
  String get ocrHoleEditDesc => 'Fix handwritten or blurry numbers right here.';

  @override
  String get ocrLabelStrokes => 'Strokes';

  @override
  String get ocrLabelPutts => 'Putts';

  @override
  String get ocrApplyFix => 'Apply fix';

  @override
  String get ocrCompanionEditTitle => 'Fix companion OCR';

  @override
  String get ocrLabelName => 'Name';

  @override
  String get ocrCompanionNameHint => 'Companion name';

  @override
  String get ocrNameTooShortWarning =>
      'This name looks too short or unclear. Check the suggested names or the raw OCR text.';

  @override
  String get ocrDuplicateNameWarning =>
      'This name matches another companion. If they\'re different people, make the names distinct.';

  @override
  String get ocrFrequentNames => 'Frequent companions';

  @override
  String get ocrHighSimilarity => 'Close match';

  @override
  String ocrRoundsValue(int n) {
    return '$n rounds';
  }

  @override
  String ocrCurrentTotal(int n) {
    return 'Current total: $n';
  }

  @override
  String get ocrApplyCompanionFix => 'Apply companion fix';

  @override
  String get ocrHoleStrokesTitle => 'Strokes by hole';

  @override
  String get ocrCompanionHoleEditDesc =>
      'Tap a hole to edit the companion\'s strokes.';

  @override
  String ocrCompanionHoleTitle(int n) {
    return 'Hole $n companion strokes';
  }

  @override
  String ocrCompanionHoleDesc(int par) {
    return 'Adjust strokes against Par $par.';
  }

  @override
  String get ocrApplyStrokes => 'Apply strokes';

  @override
  String get restTabBreakfast => 'Breakfast';

  @override
  String get restTabLunch => 'Lunch';

  @override
  String restFilterNoteWithAddress(String address) {
    return 'No cafes or desserts · Closest to $address first';
  }

  @override
  String get restFilterNote =>
      'No cafes or desserts · See details for real reviews';

  @override
  String restLoadError(String error) {
    return 'An error occurred: $error';
  }

  @override
  String restEmptyNearby(String lat, String lng) {
    return 'No recommended restaurants nearby\n(Location: $lat, $lng)';
  }

  @override
  String restRatingLabel(String rating) {
    return 'Rating $rating';
  }

  @override
  String restDistanceCategory(String distance, String category) {
    return '$distance km · $category';
  }

  @override
  String get restDirections => 'Directions';

  @override
  String get restViewDetails => 'View details';

  @override
  String get restAddressLabel => 'Address';

  @override
  String get restHoursLabel => 'Hours';

  @override
  String get restCall => 'Call';

  @override
  String get restViewReviews => 'View reviews';

  @override
  String get restRecommendationCriteria => 'Why we recommend these';

  @override
  String get restNavKakaoTitle => 'Directions in KakaoMap';

  @override
  String get restNavKakaoSubtitle =>
      'Opens the app if installed, otherwise the web version';

  @override
  String get restNavNaverTitle => 'Directions in Naver Map';

  @override
  String get restNavNaverSubtitle =>
      'Opens directly if the Naver Map app is installed';

  @override
  String get restNavWebTitle => 'Open web map';

  @override
  String get restNavWebSubtitle => 'View in your browser, no map app needed';

  @override
  String get restNavOpenFailed =>
      'Couldn\'t open directions. Please try again later.';

  @override
  String restSearchError(String error) {
    return 'An error occurred while searching for restaurants.\n$error';
  }

  @override
  String get restApiAuthError =>
      'Kakao API authentication failed. Please check the REST API key in the developer console.';

  @override
  String get restApiForbiddenError =>
      'Kakao API access is restricted. Please check that the iOS platform is registered for the app.';

  @override
  String restApiError(int statusCode) {
    return 'Restaurant API error ($statusCode)';
  }

  @override
  String get restHoursPending => 'Information not yet available';

  @override
  String get restHoursUnspecified => 'Not specified';

  @override
  String get restReviewHint1 =>
      'Check visitor reviews and photos on the Kakao place page.';

  @override
  String get restReviewHint2 =>
      'Only restaurant categories suited to pre- and post-round meals were selected.';

  @override
  String get schedEnterCourseName => 'Please enter a golf course';

  @override
  String schedCourseNotInDb(String name) {
    return '$name isn\'t in our database, so it will be saved as a custom schedule without weather alerts';
  }

  @override
  String schedErrorWithDetail(String error) {
    return 'Error: $error';
  }

  @override
  String get schedCalendarPermissionNeeded =>
      'Calendar access is required. Please allow calendar permission in Settings.';

  @override
  String get schedNoCalendarCandidates =>
      'No golf schedule candidates were found in your recent or upcoming calendar events.';

  @override
  String schedCalendarImportFailed(String error) {
    return 'Couldn\'t load calendar events: $error';
  }

  @override
  String get schedCalendarCandidatesTitle => 'Calendar candidates';

  @override
  String get schedCalendarCandidatesDesc =>
      'Select an event to fill in the course, date, and tee-off time.';

  @override
  String get schedPortalFoundCourse =>
      'Found via portal search (not in our DB) — please check the address.';

  @override
  String get schedVerifyCourseName =>
      'Please double-check the course name before saving.';

  @override
  String get schedCalendarApplied =>
      'Calendar event details were filled in. Please review before saving.';

  @override
  String get schedEditSchedule => 'Edit Schedule';

  @override
  String get schedAddNewSchedule => 'New Schedule';

  @override
  String get schedSaveSchedule => 'Save Schedule';

  @override
  String get schedIntro =>
      'Enter your round details to get course weather and alerts together.';

  @override
  String get schedDateLabel => 'Date *';

  @override
  String get schedTimeLabel => 'Time *';

  @override
  String get schedCourseLabel => 'Golf course *';

  @override
  String get schedAddressLabel => 'Address / location note';

  @override
  String get schedTitleLabel => 'Title';

  @override
  String get schedNotifyLabel => 'Reminder';

  @override
  String get schedCourseHint => 'e.g. Lakeside CC';

  @override
  String get schedAddressHint => 'e.g. Cheoin-gu, Yongin-si, Gyeonggi-do ...';

  @override
  String get schedTitleHint => 'e.g. Weekend round';

  @override
  String get schedWeatherAlertToggle => 'Get weather risk alerts';

  @override
  String get schedCheckingCalendar => 'Checking calendar';

  @override
  String get schedImportFromCalendar => 'Import from calendar';

  @override
  String schedHoursBefore(int hours) {
    return '${hours}h before';
  }

  @override
  String schedDaysBefore(int days) {
    return '${days}d before';
  }

  @override
  String get schedDateFmt => 'EEE, MMM d';

  @override
  String get schedCalendarDateFmt => 'EEE, MMM d, yyyy HH:mm';

  @override
  String get eventStatusOptimal => 'Optimal';

  @override
  String get eventStatusCaution => 'Caution';

  @override
  String get eventStatusCancelRecommended => 'Consider canceling';

  @override
  String get eventStatusUnknown => 'No data';

  @override
  String get eventDeleteTitle => 'Delete Schedule';

  @override
  String get eventDeleteConfirm => 'Delete this schedule?';

  @override
  String eventErrorWithDetail(String error) {
    return 'Error: $error';
  }

  @override
  String get eventNotifPermissionNeeded =>
      'Notification permission is required. Please allow it in Settings.';

  @override
  String get eventSubscribeNoCourse =>
      'Can\'t subscribe because the course couldn\'t be found.';

  @override
  String get eventSubscribeSuccess => 'Weather change alerts are on.';

  @override
  String get eventSubscribeFailed => 'Failed to register the alert.';

  @override
  String get eventBookingForecastTitle => 'Tee time forecast';

  @override
  String eventBookingTimeBase(String time) {
    return 'Based on $time tee time';
  }

  @override
  String get eventStartMarker => 'Start';

  @override
  String eventRainProb(int prob) {
    return 'Rain $prob%';
  }

  @override
  String get eventRestaurantTitle => 'Nearby restaurants';

  @override
  String get eventRestaurantSubtitle => 'Find breakfast and lunch spots';

  @override
  String get eventForecastNotYet =>
      'Forecast not available yet · Check back within 7 days of your round';

  @override
  String get eventWeatherPendingTitle => 'Weather being prepared';

  @override
  String get eventWeatherPendingDesc =>
      'Course matching or the forecast cache isn\'t ready yet. Schedule, map, and restaurant features still work — check back for weather shortly.';

  @override
  String get eventMapHint =>
      'If the map doesn\'t show, edit the schedule and enter both the course name and address.';

  @override
  String get eventScorecardTitle => 'Scorecard';

  @override
  String get eventScorecardSubtitle =>
      'Track 18-hole strokes, putts, and fairways';

  @override
  String get calDefaultGolfTitle => 'Golf round';

  @override
  String get scoreHistoryTitle => 'Score History';

  @override
  String get scoreDeleteTitle => 'Delete Score';

  @override
  String scoreDeleteConfirm(String courseName) {
    return 'Delete the record for $courseName?';
  }

  @override
  String get scoreDeletedSnack => 'Score record deleted.';

  @override
  String get scoreCourseNameUpdatedSnack => 'Course name updated.';

  @override
  String get scoreOcrScanning => 'OCR Scan';

  @override
  String get scoreRoundDate => 'Round date';

  @override
  String get scoreToday => 'Today';

  @override
  String get scoreYesterday => 'Yesterday';

  @override
  String get scoreSevenDaysAgo => '7 days ago';

  @override
  String get scoreOcrNoCourseNameHint =>
      'No need to enter the course name first. We\'ll read it with OCR, and you can fix it at the end only if needed.';

  @override
  String get scoreOcrStart => 'Start OCR Scan';

  @override
  String get scoreRecentRounds => 'Recent Rounds';

  @override
  String get scoreLifeBest => 'Personal Best';

  @override
  String scoreRecentAvgChip(String avg) {
    return 'Last 5R avg $avg';
  }

  @override
  String scoreThisMonthChip(int count) {
    return '${count}R this month';
  }

  @override
  String scoreCompanionChip(int count) {
    return '${count}R with companions';
  }

  @override
  String scoreDetailCompleteChip(int count) {
    return '${count}R fully detailed';
  }

  @override
  String scoreOptionalFixChip(int count) {
    return '${count}R with optional edits left';
  }

  @override
  String scoreOptionalMetricsCount(int count) {
    return 'Optional details: $count rounds';
  }

  @override
  String scoreDetailRecordPercent(int percent) {
    return 'Details $percent%';
  }

  @override
  String scoreOptionalInputHoles(int count) {
    return 'Optional input: $count holes';
  }

  @override
  String scorePuttsTrackedChip(int tracked, int total) {
    return 'Putts $tracked/$total holes';
  }

  @override
  String scoreFairwayTrackedChip(int tracked, int total) {
    return 'Fairways $tracked/$total holes';
  }

  @override
  String scoreFirstIncompleteChip(int hole) {
    return 'First open item ${hole}H';
  }

  @override
  String get scoreTotalRounds => 'Total Rounds';

  @override
  String scoreTimesCount(int count) {
    return '$count';
  }

  @override
  String get scoreRoundsThisYear => 'Rounds This Year';

  @override
  String get scoreThisMonth => 'This Month';

  @override
  String get scoreRecentAvgLabel => 'Last 5R Avg';

  @override
  String get scoreCompanionRecords => 'Companion Rounds';

  @override
  String get scoreNotRecordedYet => 'None yet';

  @override
  String get scoreCompanionSavedCaption => 'Rounds saved with companion info';

  @override
  String get scoreOptionalFix => 'Optional Edits';

  @override
  String get scoreAllScoresSaved => 'All scores saved';

  @override
  String get scoreOptionalDetailCaption =>
      'Optional details like putts/fairways';

  @override
  String scoreCompanionCountBadge(int count) {
    return '$count companions';
  }

  @override
  String get scorePuttRecordBadge => 'Putts tracked';

  @override
  String get scoreFairwayRecordBadge => 'Fairways tracked';

  @override
  String scoreTrackingSummary(
      int puttTracked, int puttTotal, int fairwayTracked, int fairwayTotal) {
    return 'Optional stats: putts $puttTracked/$puttTotal · fairways $fairwayTracked/$fairwayTotal';
  }

  @override
  String get scoreEditCourseName => 'Edit Course Name';

  @override
  String get scoreEditCourseNameDesc =>
      'If the course name from OCR is missing or wrong, you can fix it right here.';

  @override
  String get scoreCourseNameLabel => 'Course name';

  @override
  String get scoreCourseNameHint => 'e.g. Dream Park CC';

  @override
  String get scoreOcrCardTitle => 'Scorecard OCR Scan';

  @override
  String get scoreOcrCardDesc =>
      'Reads a photo from the scorecard in schedule details';

  @override
  String get scoreOcrGuide => 'OCR Guide';

  @override
  String get scoreEmptyTitle => 'No saved scores yet';

  @override
  String get scoreEmptyDesc =>
      'Open and save a scorecard from schedule details,\nor register a past round with OCR to build your history here.';

  @override
  String get scoreOcrSheetTitle => 'Import Scorecard via OCR';

  @override
  String get scoreOcrSheetDesc =>
      'Scan right from schedule details, or start your history by registering a past round with OCR.';

  @override
  String get scoreOcrStep1 =>
      'Capture the scorecard screen or photograph a paper scorecard';

  @override
  String get scoreOcrStep2 =>
      'Pick the image from the schedule scorecard or OCR scan';

  @override
  String get scoreOcrStep3 =>
      'Confirm hole scores to auto-save; edit only when needed';

  @override
  String get scoreOcrStartShort => 'Start OCR';

  @override
  String scoreCompanionOne(String name) {
    return 'With $name';
  }

  @override
  String scoreCompanionTwo(String name1, String name2) {
    return 'With $name1 · $name2';
  }

  @override
  String scoreCompanionMore(String name1, String name2, int count) {
    return 'With $name1 · $name2 and $count more';
  }

  @override
  String get scoreCardSavedSnack => 'Scorecard saved.';

  @override
  String scoreSaveFailedSnack(String error) {
    return 'Could not save: $error';
  }

  @override
  String get scoreCourseNameConfirmTitle => 'Confirm Course Name';

  @override
  String get scoreCourseNameMissingDesc =>
      'We couldn\'t read the course name from this card. Please enter just the course name before saving.';

  @override
  String get scoreContinueSave => 'Continue Saving';

  @override
  String get scoreOcrLoadedSnack =>
      'OCR results loaded. Please double-check the hole scores.';

  @override
  String scoreOcrLoadedWithCompanionsSnack(int count) {
    return 'Loaded OCR results with $count companion records.';
  }

  @override
  String get scoreSaving => 'Saving';

  @override
  String get scoreSaveButton => 'Save Score';

  @override
  String get scorePastRoundOcr => 'Past Round OCR';

  @override
  String get scoreCardLabel => 'Scorecard';

  @override
  String get scoreCompanionOcrResult => 'Companion OCR Results';

  @override
  String get scoreTotalStrokes => 'Total';

  @override
  String get scoreScoreLabel => 'Score';

  @override
  String get scorePutts => 'Putts';

  @override
  String get scoreFairway => 'Fairway';

  @override
  String get scoreObPenalty => 'OB/Penalty';

  @override
  String get scoreStrokes => 'Strokes';

  @override
  String get scorePenalty => 'Penalty';

  @override
  String get scoreFairwayHit => 'Hit';

  @override
  String get scoreFairwayMiss => 'Miss';

  @override
  String get scoreFairwayNotApplicable => 'N/A';

  @override
  String get scoreStageComplete => 'Details complete';

  @override
  String get scoreStageScoreOnly => 'Score saved';

  @override
  String get scoreStageNearlyComplete => 'Details nearly complete';

  @override
  String get scoreStageInProgress => 'Partial details';

  @override
  String get scoreStageDescComplete => 'Putts and fairways are all recorded.';

  @override
  String get scoreStageDescScoreOnly =>
      'Score is saved; detailed stats are still empty.';

  @override
  String get scoreStageDescNearlyComplete =>
      'Details are almost done. Just a few holes left to confirm.';

  @override
  String get scoreStageDescInProgress => 'You can keep filling in the details.';
}
