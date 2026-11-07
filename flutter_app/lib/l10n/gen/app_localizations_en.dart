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
}
