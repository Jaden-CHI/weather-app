import 'package:shared_preferences/shared_preferences.dart';

/// 사용자 앱 설정 (SharedPreferences 기반)
class SettingsService {
  SettingsService._();
  static final instance = SettingsService._();

  static const _keyRainThreshold = 'setting_rain_threshold';
  static const _keyWindThreshold = 'setting_wind_threshold';
  static const _keyNotifyHoursBefore = 'setting_notify_hours_before';
  static const _keyFavoriteCourses = 'setting_favorite_courses';
  static const _keyFavoriteSpots = 'setting_favorite_spots';

  Future<int> getRainThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyRainThreshold) ?? 60;
  }

  Future<void> setRainThreshold(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRainThreshold, value.clamp(10, 100));
  }

  Future<double> getWindThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getDouble(_keyWindThreshold) ?? 10.0);
  }

  Future<void> setWindThreshold(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyWindThreshold, value.clamp(3.0, 30.0));
  }

  Future<int> getNotifyHoursBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyNotifyHoursBefore) ?? 24;
  }

  Future<void> setNotifyHoursBefore(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyNotifyHoursBefore, hours);
  }

  Future<List<String>> getFavoriteCourses() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyFavoriteCourses) ?? [];
  }

  Future<void> addFavoriteCourse(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyFavoriteCourses) ?? [];
    if (!list.contains(courseId)) {
      list.add(courseId);
      await prefs.setStringList(_keyFavoriteCourses, list);
    }
  }

  Future<void> removeFavoriteCourse(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyFavoriteCourses) ?? [];
    list.remove(courseId);
    await prefs.setStringList(_keyFavoriteCourses, list);
  }

  Future<List<String>> getFavoriteSpots() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyFavoriteSpots) ?? [];
  }

  Future<void> addFavoriteSpot(String spotId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyFavoriteSpots) ?? [];
    if (!list.contains(spotId)) {
      list.add(spotId);
      await prefs.setStringList(_keyFavoriteSpots, list);
    }
  }

  Future<void> removeFavoriteSpot(String spotId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyFavoriteSpots) ?? [];
    list.remove(spotId);
    await prefs.setStringList(_keyFavoriteSpots, list);
  }
}
