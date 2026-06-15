import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/golf_event.dart';

class AppScheduleService {
  static const String _localSchedulesKey = 'golf_schedules_v2';
  static const Set<String> _generatedTestCourseNames = {
    '레이크사이드CC',
    '올림픽CC',
    '남서울CC',
    '강남300CC',
    '리앤리C.C',
  };

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
    final scheduleId = const Uuid().v4();
    final schedules = await _loadSchedules();
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

    schedules[scheduleId] = data;
    await _saveSchedules(schedules);
  }

  Future<List<GolfEvent>> getUpcomingGolfSchedules() async {
    try {
      debugPrint('Getting local golf schedules');
      final data = await _loadSchedules();

      if (data.isEmpty) {
        debugPrint('No local schedules found');
        return [];
      }

      final events = <GolfEvent>[];
      final now = DateTime.now();
      debugPrint('Found ${data.length} local schedules');

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
      debugPrint('Got ${events.length} local golf events');
      return events;
    } catch (e) {
      debugPrint('Golf schedules fetch error: $e');
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
      final schedules = await _loadSchedules();
      final raw = schedules[scheduleId];
      if (raw == null) return null;

      final schedule = Map<String, dynamic>.from(raw);
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
      debugPrint('Error getting schedule $scheduleId: $e');
      return null;
    }
  }

  Future<void> updateSchedule(
    String scheduleId,
    Map<String, dynamic> updates,
  ) async {
    final schedules = await _loadSchedules();
    final current = schedules[scheduleId];
    if (current == null) return;

    updates['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    schedules[scheduleId] = {
      ...current,
      ...updates,
    };
    await _saveSchedules(schedules);
  }

  Future<void> deleteSchedule(String scheduleId) async {
    final schedules = await _loadSchedules();
    schedules.remove(scheduleId);
    await _saveSchedules(schedules);
  }

  bool _isGeneratedTestSchedule(Map<String, dynamic> schedule) {
    final locationName = schedule['locationName'] as String?;
    final title = schedule['title'] as String?;

    return locationName != null &&
        title == '$locationName 라운드' &&
        _generatedTestCourseNames.contains(locationName);
  }

  Future<Map<String, Map<String, dynamic>>> _loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localSchedulesKey);
    if (raw == null || raw.isEmpty) return {};

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(key, Map<String, dynamic>.from(value as Map)),
    );
  }

  Future<void> _saveSchedules(
    Map<String, Map<String, dynamic>> schedules,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localSchedulesKey, jsonEncode(schedules));
  }
}
