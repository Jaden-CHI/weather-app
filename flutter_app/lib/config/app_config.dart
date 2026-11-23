import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';

/// API 서버 주소 및 플랫폼별 개발 기본값
class AppConfig {
  AppConfig._();

  static const _productionBaseUrl =
      'https://weather-app-production-7ab9.up.railway.app';
  static const _prefApiBaseUrl = 'api_base_url';
  static const _dartDefineBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String? _savedBaseUrl;

  static String get productionBaseUrl => _productionBaseUrl;

  /// main()에서 1회 호출
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _savedBaseUrl = prefs.getString(_prefApiBaseUrl);
  }

  static Future<void> setApiBaseUrl(String url) async {
    final trimmed = url.trim();
    _savedBaseUrl = trimmed.isEmpty ? null : trimmed;
    final prefs = await SharedPreferences.getInstance();
    if (_savedBaseUrl == null) {
      await prefs.remove(_prefApiBaseUrl);
    } else {
      await prefs.setString(_prefApiBaseUrl, _savedBaseUrl!);
    }
  }

  /// 우선순위: dart-define → 설정 저장값 → 플랫폼 기본값
  static String get apiBaseUrl {
    if (_dartDefineBaseUrl.isNotEmpty) return _dartDefineBaseUrl;
    if (_savedBaseUrl != null && _savedBaseUrl!.isNotEmpty) {
      return _savedBaseUrl!;
    }
    if (kIsWeb) return _productionBaseUrl;
    if (Platform.isAndroid) return _productionBaseUrl;
    if (Platform.isIOS) return _productionBaseUrl;
    return 'http://127.0.0.1:8000';
  }

  static Uri courseMapUri({
    required double lat,
    required double lng,
    required String label,
    int zoom = 13,
    String? restaurantsJson,
  }) {
    final base = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base/map/course').replace(queryParameters: {
      'lat': lat.toString(),
      'lng': lng.toString(),
      'zoom': zoom.toString(),
      'label': label,
      if (restaurantsJson != null && restaurantsJson.isNotEmpty)
        'restaurants': restaurantsJson,
    });
  }

  static Uri windyMapUri({
    required double lat,
    required double lng,
    required String label,
    int zoom = 13,
    String? restaurantsJson,
  }) {
    return courseMapUri(
      lat: lat,
      lng: lng,
      label: label,
      zoom: zoom,
      restaurantsJson: restaurantsJson,
    );
  }

  static String get weatherPendingMessage => L10n.current.weatherPendingMessage;

  static String get weatherUnavailableMessage =>
      L10n.current.weatherUnavailableMessage(apiBaseUrl);
}
