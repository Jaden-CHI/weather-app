import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API 서버 주소 및 플랫폼별 개발 기본값
class AppConfig {
  AppConfig._();

  static const _prefApiBaseUrl = 'api_base_url';
  static const _dartDefineBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String? _savedBaseUrl;

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
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    if (Platform.isIOS) return 'http://127.0.0.1:8000';
    return 'http://127.0.0.1:8000';
  }

  static Uri windyMapUri({
    required double lat,
    required double lng,
    required String label,
    int zoom = 12,
  }) {
    final base = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base/map/windy').replace(queryParameters: {
      'lat': lat.toString(),
      'lng': lng.toString(),
      'zoom': zoom.toString(),
      'label': label,
    });
  }

  static String get weatherUnavailableMessage => '날씨 서버에 연결할 수 없습니다.\n'
      '백엔드(docker-compose) 실행 후, 실기기는 설정에서 Mac IP 주소(예: http://192.168.0.10:8000)를 입력해 주세요.\n'
      '현재 주소: $apiBaseUrl';
}
