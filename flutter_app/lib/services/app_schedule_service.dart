import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/golf_event.dart';

class AppScheduleService {
  static const String _schedulesPath = 'schedules';

  final _database = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? 'anonymous';

  Future<void> addGolfSchedule({
    required String title,
    required String locationName,
    required double lat,
    required double lng,
    required DateTime startAt,
    required int notifyBeforeHours,
    required bool weatherAlertEnabled,
    String? courseId,
  }) async {
    final scheduleId = _database.child(_schedulesPath).child(_uid).push().key!;
    await _database
        .child(_schedulesPath)
        .child(_uid)
        .child(scheduleId)
        .set({
      'type': 'golf',
      'title': title,
      'locationName': locationName,
      'lat': lat,
      'lng': lng,
      'startAt': startAt.millisecondsSinceEpoch,
      'notifyBeforeHours': notifyBeforeHours,
      'weatherAlertEnabled': weatherAlertEnabled,
      'courseId': courseId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
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
      debugPrint('📊 Found ${data.length} schedules');

      data.forEach((scheduleId, scheduleData) {
        final schedule = Map<String, dynamic>.from(scheduleData);
        if (schedule['type'] == 'golf') {
          events.add(GolfEvent(
            id: scheduleId,
            title: schedule['title'],
            startDate: DateTime.fromMillisecondsSinceEpoch(schedule['startAt']),
            location: schedule['locationName'],
            courseId: schedule['courseId'],
            courseName: schedule['locationName'],
          ));
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
    final events = await getUpcomingGolfSchedules();
    return events.isNotEmpty ? events.first : null;
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
}
