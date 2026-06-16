import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../config/api_keys.dart';
import '../models/weather_data.dart';

class CourseSearchResult {
  final String courseId;
  final String name;
  final String? nameShort;
  final double? lat;
  final double? lng;

  const CourseSearchResult({
    required this.courseId,
    required this.name,
    this.nameShort,
    this.lat,
    this.lng,
  });

  factory CourseSearchResult.fromJson(Map<String, dynamic> json) {
    return CourseSearchResult(
      courseId: json['course_id'] as String,
      name: json['name'] as String? ?? '',
      nameShort: json['name_short'] as String?,
      lat: _asDouble(json['lat']),
      lng: _asDouble(json['lon'] ?? json['lng']),
    );
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class LocationSearchResult {
  final double lat;
  final double lng;

  const LocationSearchResult({required this.lat, required this.lng});
}

/// 백엔드 FastAPI 서버와 통신하는 서비스
class WeatherApiService {
  WeatherApiService._();
  static final instance = WeatherApiService._();

  static const Map<String, String> _fallbackCourseIds = {
    '레이크사이드CC': 'CC_025',
    '올림픽': 'CC_014',
    '올림픽CC': 'CC_014',
    '올림픽골프장': 'CC_014',
    '올림픽 골프장': 'CC_014',
    '남서울': 'CC_042',
    '남서울CC': 'CC_042',
    '남서울컨트리클럽': 'CC_042',
  };

  Dio get _dio => Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 12),
          headers: {'Content-Type': 'application/json'},
        ),
      )..interceptors.add(_CacheInterceptor());

  /// 골프장 이름 검색 → course_id 반환
  Future<String?> searchCourseId(String keyword) async {
    final course = await searchCourse(keyword);
    if (course != null) return course.courseId;

    final fallbackId = _fallbackCourseIds[_canonicalCourseKeyword(keyword)];
    if (fallbackId != null) {
      debugPrint('✅ courseId fallback matched: $keyword → $fallbackId');
      return fallbackId;
    }

    debugPrint('⚠️ courseId not found for: $keyword');
    return null;
  }

  /// 골프장 이름 검색 → 백엔드 검색 결과 반환
  Future<CourseSearchResult?> searchCourse(String keyword) async {
    final candidates = _courseSearchCandidates(keyword);
    if (candidates.isEmpty) return null;

    for (final q in candidates) {
      try {
        final resp = await _dio.get(
          '/api/v1/golf/courses/search',
          queryParameters: {'q': q},
        );
        final results = (resp.data['results'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((e) => CourseSearchResult.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList();
        if (results.isEmpty) continue;

        final best = _bestCourseMatch(keyword, results);
        debugPrint('✅ courseId matched: $keyword → ${best.courseId}');
        return best;
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) continue;
        debugPrint('⚠️ course search failed for "$q": ${e.message}');
        break;
      } catch (e) {
        debugPrint('⚠️ course search failed for "$q": $e');
        break;
      }
    }

    return null;
  }

  /// 골프장 이름 검색 → 입력 자동완성용 후보 목록 반환
  Future<List<CourseSearchResult>> searchCourseSuggestions(
    String keyword, {
    int limit = 6,
  }) async {
    final candidates = _courseSearchCandidates(keyword);
    if (candidates.isEmpty) return const [];

    final seen = <String>{};
    final suggestions = <CourseSearchResult>[];

    for (final q in candidates) {
      try {
        final resp = await _dio.get(
          '/api/v1/golf/courses/search',
          queryParameters: {'q': q},
        );
        final results = (resp.data['results'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((e) => CourseSearchResult.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList();

        for (final result in results) {
          if (seen.add(result.courseId)) {
            suggestions.add(result);
          }
          if (suggestions.length >= limit) return suggestions;
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) continue;
        debugPrint('⚠️ course suggestions failed for "$q": ${e.message}');
        break;
      } catch (e) {
        debugPrint('⚠️ course suggestions failed for "$q": $e');
        break;
      }
    }

    suggestions.sort((a, b) =>
        _courseMatchScore(keyword, a).compareTo(_courseMatchScore(keyword, b)));
    return suggestions.take(limit).toList();
  }

  Future<LocationSearchResult?> geocodeLocation(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;

    final kakao = await _geocodeWithKakao(trimmed);
    if (kakao != null) return kakao;

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://nominatim.openstreetmap.org',
          connectTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 8),
          headers: {
            'User-Agent': 'GolfWindy/1.0 contact:appstore',
          },
        ),
      );
      final resp = await dio.get(
        '/search',
        queryParameters: {
          'q': trimmed,
          'format': 'json',
          'limit': '1',
        },
      );
      final results = resp.data as List<dynamic>? ?? [];
      if (results.isEmpty) return null;
      final first = Map<String, dynamic>.from(results.first as Map);
      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lng = double.tryParse(first['lon']?.toString() ?? '');
      if (lat == null || lng == null) return null;
      return LocationSearchResult(lat: lat, lng: lng);
    } catch (e) {
      debugPrint('⚠️ location geocode failed for "$trimmed": $e');
      return null;
    }
  }

  Future<LocationSearchResult?> _geocodeWithKakao(String query) async {
    if (ApiKeys.kakaoMapKey.trim().isEmpty) return null;

    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://dapi.kakao.com',
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 8),
        headers: {
          'Authorization': 'KakaoAK ${ApiKeys.kakaoMapKey}',
        },
      ),
    );

    for (final path in const [
      '/v2/local/search/keyword.json',
      '/v2/local/search/address.json',
    ]) {
      try {
        final resp = await dio.get(
          path,
          queryParameters: {'query': query, 'size': 1},
        );
        final documents = resp.data['documents'] as List<dynamic>? ?? [];
        if (documents.isEmpty) continue;

        final first = Map<String, dynamic>.from(documents.first as Map);
        final lat = double.tryParse(first['y']?.toString() ?? '');
        final lng = double.tryParse(first['x']?.toString() ?? '');
        if (lat != null && lng != null) {
          debugPrint('✅ Kakao geocode matched: $query → $lat,$lng');
          return LocationSearchResult(lat: lat, lng: lng);
        }
      } catch (e) {
        debugPrint('⚠️ Kakao geocode failed for "$query" ($path): $e');
      }
    }

    return null;
  }

  Future<LocationSearchResult?> geocodeBestEffort({
    required String courseName,
    String? address,
  }) async {
    final trimmedCourse = courseName.trim();
    final trimmedAddress = address?.trim() ?? '';
    final queries = <String>[
      if (trimmedAddress.isNotEmpty && trimmedCourse.isNotEmpty)
        '$trimmedAddress $trimmedCourse',
      if (trimmedCourse.isNotEmpty && trimmedAddress.isNotEmpty)
        '$trimmedCourse $trimmedAddress',
      if (trimmedAddress.isNotEmpty) trimmedAddress,
      if (trimmedCourse.isNotEmpty) trimmedCourse,
    ];

    for (final query in queries.toSet()) {
      final result = await geocodeLocation(query);
      if (result != null) return result;
    }

    return null;
  }

  static List<String> _courseSearchCandidates(String keyword) {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return const [];

    final withoutRoundText =
        trimmed.replaceAll(RegExp(r'라운딩|라운드|골프\s*일정'), '').trim();
    final noSpaces = withoutRoundText.replaceAll(RegExp(r'\s+'), '');
    final withoutSuffix = noSpaces
        .replaceAll(
          RegExp(
            r'(컨트리클럽|골프클럽|골프장|CC|C\.C|GC|G\.C)$',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    final candidates = <String>[];
    for (final value in [trimmed, withoutRoundText, noSpaces, withoutSuffix]) {
      if (value.isNotEmpty && !candidates.contains(value)) {
        candidates.add(value);
      }
    }
    return candidates;
  }

  static CourseSearchResult _bestCourseMatch(
    String keyword,
    List<CourseSearchResult> results,
  ) {
    results.sort((a, b) =>
        _courseMatchScore(keyword, a).compareTo(_courseMatchScore(keyword, b)));
    return results.first;
  }

  static int _courseMatchScore(String keyword, CourseSearchResult course) {
    final needle = _canonicalCourseKeyword(keyword);
    final name = _canonicalCourseKeyword(course.name);
    final shortName = _canonicalCourseKeyword(course.nameShort ?? '');
    if (name == needle || shortName == needle) return 0;
    if (name.startsWith(needle) || shortName.startsWith(needle)) return 1;
    if (name.contains(needle) || shortName.contains(needle)) return 2;
    return 3;
  }

  static String _canonicalCourseKeyword(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[.\-_/·()]'), '')
        .toUpperCase();
  }

  /// 골프장 날씨 + 취소 권고 조회
  Future<GolfWeatherData?> getGolfWeather(
    String courseId, {
    int dday = 0,
    int? startHour,
  }) async {
    try {
      final resp = await _dio.get(
        '/api/v1/golf/courses/$courseId/weather',
        queryParameters: {
          'dday': dday,
          if (startHour != null) 'start_hour': startHour,
        },
      );
      return GolfWeatherData.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 503) {
        // 캐시 없음 — 워커가 아직 수집 전
        return null;
      }
      rethrow;
    }
  }

  /// DB에 없는 커스텀 골프장용 좌표 기반 날씨 조회
  Future<GolfWeatherData?> getCustomGolfWeather({
    required double lat,
    required double lng,
    required String courseName,
    int dday = 0,
    int? startHour,
  }) async {
    try {
      final resp = await _dio.get(
        '/api/v1/golf/custom/weather',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'name': courseName,
          'dday': dday,
          if (startHour != null) 'start_hour': startHour,
        },
      );
      return GolfWeatherData.fromJson(resp.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('⚠️ custom golf weather failed: $e');
      return null;
    }
  }

  /// 낚시 출항지 이름 검색 → spot_id 반환
  Future<String?> searchSpotId(String keyword) async {
    try {
      final resp = await _dio.get(
        '/api/v1/marine/spots/search',
        queryParameters: {'q': keyword},
      );
      final results = resp.data['results'] as List<dynamic>;
      if (results.isEmpty) return null;
      return results.first['spot_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// 배낚시 해양 날씨 + 출항 권고 조회
  Future<MarineWeatherData?> getMarineWeather(String spotId) async {
    try {
      final resp = await _dio.get('/api/v1/marine/spots/$spotId/weather');
      return MarineWeatherData.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 503) return null;
      rethrow;
    }
  }

  /// FCM 디바이스 토큰 등록
  Future<void> registerDevice({
    required String userToken,
    required String fcmToken,
    required String platform,
  }) async {
    try {
      await _dio.post('/api/v1/devices/register', data: {
        'user_token': userToken,
        'fcm_token': fcmToken,
        'platform': platform,
      });
    } catch (_) {
      // 알림 등록 실패는 앱 동작에 영향 없음
    }
  }

  /// 일정 날씨 알림 구독
  Future<int?> subscribeEvent({
    required String userToken,
    required String activityType,
    required String targetId,
    required DateTime eventDate,
    String? eventTitle,
    int rainThreshold = 60,
    double windThreshold = 10.0,
  }) async {
    try {
      final resp = await _dio.post('/api/v1/devices/subscribe', data: {
        'user_token': userToken,
        'activity_type': activityType,
        'target_id': targetId,
        'event_date':
            '${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}',
        'event_title': eventTitle,
        'rain_threshold': rainThreshold,
        'wind_threshold': windThreshold,
      });
      return resp.data['sub_id'] as int?;
    } catch (_) {
      return null;
    }
  }
}

/// 응답을 SharedPreferences에 간단 캐싱 (오프라인 대비)
class _CacheInterceptor extends Interceptor {
  static const _ttl = Duration(hours: 1);

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cache_${response.realUri}';
      await prefs.setString(key, response.data.toString());
      await prefs.setInt(
        '${key}_ts',
        DateTime.now().millisecondsSinceEpoch,
      );
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 네트워크 오류 시 캐시 반환
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.receiveTimeout) {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cache_${err.requestOptions.uri}';
      final cached = prefs.getString(key);
      final ts = prefs.getInt('${key}_ts') ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - ts;

      if (cached != null && age < _ttl.inMilliseconds) {
        handler.resolve(
          Response(
            requestOptions: err.requestOptions,
            data: cached,
            statusCode: 200,
            headers: Headers.fromMap({
              'X-From-Cache': ['true']
            }),
          ),
        );
        return;
      }
    }
    handler.next(err);
  }
}
