import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_data.dart';

/// 백엔드 FastAPI 서버와 통신하는 서비스
class WeatherApiService {
  WeatherApiService._();
  static final instance = WeatherApiService._();

  // 개발: localhost, 운영: 실제 서버 URL로 교체
  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  late final _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(_CacheInterceptor());

  /// 골프장 이름 검색 → course_id 반환
  Future<String?> searchCourseId(String keyword) async {
    try {
      final resp = await _dio.get(
        '/api/v1/golf/courses/search',
        queryParameters: {'q': keyword},
      );
      final results = resp.data['results'] as List<dynamic>;
      if (results.isEmpty) return null;
      return results.first['course_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// 골프장 날씨 + 취소 권고 조회
  Future<GolfWeatherData?> getGolfWeather(String courseId, {int dday = 0}) async {
    try {
      final resp = await _dio.get(
        '/api/v1/golf/courses/$courseId/weather',
        queryParameters: {'dday': dday},
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
        'event_date': '${eventDate.year}-${eventDate.month.toString().padLeft(2,'0')}-${eventDate.day.toString().padLeft(2,'0')}',
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
            headers: Headers.fromMap({'X-From-Cache': ['true']}),
          ),
        );
        return;
      }
    }
    handler.next(err);
  }
}
