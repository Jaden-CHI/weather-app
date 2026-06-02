import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart' show Color;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'weather_api_service.dart';

/// 백그라운드 메시지 핸들러 (최상위 함수 필수)
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // 백그라운드 알림은 FCM이 자동 표시 — 추가 처리 불필요
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _localNotif = FlutterLocalNotificationsPlugin();

  static const _userTokenKey = 'user_anonymous_token';

  // ── 초기화 ────────────────────────────────────────────────────
  Future<void> init() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Android 알림 채널
    await _localNotif.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'weather_alert',
          '날씨 알림',
          description: '골프·낚시 일정 기상 변화 알림',
          importance: Importance.high,
        ));

    await _localNotif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    // 포그라운드 알림 표시 설정
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );

    // 포그라운드 메시지 → 로컬 알림으로 표시
    FirebaseMessaging.onMessage.listen(_showLocalNotification);
  }

  // ── 권한 요청 + 토큰 등록 ─────────────────────────────────────
  Future<bool> requestPermissionAndRegister() async {
    final settings = await _fcm.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );
    final granted = settings.authorizationStatus == AuthorizationStatus.authorized
        || settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!granted) return false;

    final fcmToken = await _fcm.getToken();
    if (fcmToken == null) return false;

    final userToken = await _getOrCreateUserToken();
    final platform = _detectPlatform();

    await WeatherApiService.instance.registerDevice(
      userToken: userToken,
      fcmToken: fcmToken,
      platform: platform,
    );

    // 토큰 갱신 시 재등록
    _fcm.onTokenRefresh.listen((newToken) async {
      await WeatherApiService.instance.registerDevice(
        userToken: userToken,
        fcmToken: newToken,
        platform: platform,
      );
    });

    return true;
  }

  // ── 일정 구독 등록 ────────────────────────────────────────────
  Future<int?> subscribeToEvent({
    required String activityType,
    required String targetId,
    required DateTime eventDate,
    String? eventTitle,
    int rainThreshold = 60,
    double windThreshold = 10.0,
  }) async {
    final userToken = await _getOrCreateUserToken();
    return WeatherApiService.instance.subscribeEvent(
      userToken: userToken,
      activityType: activityType,
      targetId: targetId,
      eventDate: eventDate,
      eventTitle: eventTitle,
      rainThreshold: rainThreshold,
      windThreshold: windThreshold,
    );
  }

  // ── 포그라운드 알림 표시 ──────────────────────────────────────
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;

    final status = message.data['status'] ?? 'GREEN';
    final color = switch (status) {
      'RED'    => const Color(0xFFF44336).value,
      'YELLOW' => const Color(0xFFFFC107).value,
      _        => const Color(0xFF4CAF50).value,
    };

    await _localNotif.show(
      notif.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'weather_alert',
          '날씨 알림',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(color),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ── 익명 사용자 토큰 관리 ─────────────────────────────────────
  Future<String> _getOrCreateUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_userTokenKey);
    if (existing != null) return existing;
    final newToken = const Uuid().v4();
    await prefs.setString(_userTokenKey, newToken);
    return newToken;
  }

  Future<String> get userToken => _getOrCreateUserToken();

  String _detectPlatform() => Platform.isIOS ? 'IOS' : 'ANDROID';
}
