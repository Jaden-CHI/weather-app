import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/golf_event.dart';

class AppScheduleService {
  static const String _schedulesPath = 'schedules';
  static const Set<String> _generatedTestCourseNames = {
    '레이크사이드CC',
    '올림픽CC',
    '남서울CC',
    '강남300CC',
    '리앤리C.C',
  };

  final _database = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? 'anonymous';

  Future<void> addGolfSchedule({
    required String title,
    required String locationName,
    String? address,
    double? lat,
    double? lng,
    required DateTime startAt,
    required int notifyBeforeHours,
    required bool weatherAlertEnabled,
    String? courseId,
  }) async {
    final scheduleId = _database.child(_schedulesPath).child(_uid).push().key!;
    final data = {
      'type': 'golf',
      'title': title,
      'locationName': locationName,
      'startAt': startAt.millisecondsSinceEpoch,
      'notifyBeforeHours': notifyBeforeHours,
      'weatherAlertEnabled': weatherAlertEnabled,
      'courseId': courseId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    if (address != null && address.trim().isNotEmpty) {
      data['address'] = address.trim();
    }
    if (lat != null && lng != null) {
      data['lat'] = lat;
      data['lng'] = lng;
    }
    await _database
        .child(_schedulesPath)
        .child(_uid)
        .child(scheduleId)
        .set(data);
  }

  Future<List<GolfEvent>> getUpcomingGolfSchedules() async {
    try {
      debugPrint('📍 Getting golf schedules for UID: $_uid');
      final snapshot = await _database
          .child(_schedulesPath)
          .child(_uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!snapshot.exists) {
        debugPrint('⚠️ No schedules found for UID: $_uid');
        return [];
      }

      final events = <GolfEvent>[];
      final data = snapshot.value as Map<dynamic, dynamic>;
      final now = DateTime.now();
      debugPrint('📊 Found ${data.length} schedules');

      data.forEach((scheduleId, scheduleData) {
        final schedule = Map<String, dynamic>.from(scheduleData);
        if (schedule['type'] == 'golf') {
          final event = GolfEvent(
            id: scheduleId,
            title: schedule['title'],
            startDate: DateTime.fromMillisecondsSinceEpoch(schedule['startAt']),
            location: schedule['locationName'],
            courseId: schedule['courseId'],
            courseName: schedule['locationName'],
            address: schedule['address'],
            lat: (schedule['lat'] as num?)?.toDouble(),
            lng: (schedule['lng'] as num?)?.toDouble(),
          );

          if (event.startDate.isBefore(now)) return;
          if (_isGeneratedTestSchedule(schedule)) return;

          events.add(event);
        }
      });

      events.sort((a, b) => a.startDate.compareTo(b.startDate));
      debugPrint('✅ Got ${events.length} golf events');
      return events;
    } catch (e) {
      debugPrint('❌ Golf schedules fetch error: $e');
      return [];
    }
  }

  Future<GolfEvent?> getNextGolfSchedule() async {
    final schedules = await getUpcomingGolfSchedules();
    final now = DateTime.now();

    for (final schedule in schedules) {
      if (schedule.startDate.isAfter(now)) return schedule;
    }

    return null;
  }

  Future<GolfEvent?> getScheduleById(String scheduleId) async {
    try {
      final snapshot = await _database
          .child(_schedulesPath)
          .child(_uid)
          .child(scheduleId)
          .get();

      if (!snapshot.exists) return null;

      final schedule = Map<String, dynamic>.from(snapshot.value as Map);
      if (schedule['type'] != 'golf') return null;

      return GolfEvent(
        id: scheduleId,
        title: schedule['title'],
        startDate: DateTime.fromMillisecondsSinceEpoch(schedule['startAt']),
        location: schedule['locationName'],
        courseId: schedule['courseId'],
        courseName: schedule['locationName'],
        address: schedule['address'],
        lat: (schedule['lat'] as num?)?.toDouble(),
        lng: (schedule['lng'] as num?)?.toDouble(),
      );
    } catch (e) {
      debugPrint('❌ Error getting schedule $scheduleId: $e');
      return null;
    }
  }

  Future<void> updateSchedule(
    String scheduleId,
    Map<String, dynamic> updates,
  ) async {
    updates['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    await _database
        .child(_schedulesPath)
        .child(_uid)
        .child(scheduleId)
        .update(updates);
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _database
        .child(_schedulesPath)
        .child(_uid)
        .child(scheduleId)
        .remove();
  }

  bool _isGeneratedTestSchedule(Map<String, dynamic> schedule) {
    final locationName = schedule['locationName'] as String?;
    final title = schedule['title'] as String?;

    return locationName != null &&
        title == '$locationName 라운드' &&
        _generatedTestCourseNames.contains(locationName);
  }
}
