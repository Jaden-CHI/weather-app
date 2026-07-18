import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../models/golf_score.dart';
import 'account_service.dart';

class CloudBackupSnapshot {
  const CloudBackupSnapshot({
    required this.schedules,
    required this.scores,
  });

  final Map<String, Map<String, dynamic>> schedules;
  final Map<String, Map<String, dynamic>> scores;
}

class CloudBackupSummary {
  const CloudBackupSummary({
    required this.scheduleCount,
    required this.scoreCount,
    this.lastUploadedAt,
  });

  final int scheduleCount;
  final int scoreCount;
  final DateTime? lastUploadedAt;
}

class CloudBackupService {
  CloudBackupService._();
  static final instance = CloudBackupService._();

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<DatabaseReference> _userRef() async {
    final user = await AccountService.instance.ensureSignedIn();
    return _database.ref('users/${user.uid}');
  }

  Future<void> backupScheduleData(
    String scheduleId,
    Map<String, dynamic> data,
  ) async {
    try {
      final ref = await _userRef();
      await ref.child('schedules/$scheduleId').set({
        ..._normalizeMap(data),
        'syncedAt': ServerValue.timestamp,
      });
      await ref.child('backupMeta').update({
        'lastUploadedAt': ServerValue.timestamp,
      });
    } on FirebaseAuthException catch (e) {
      debugPrint('Schedule cloud backup auth failed: ${e.code}');
    } catch (e) {
      debugPrint('Schedule cloud backup failed: $e');
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    try {
      final ref = await _userRef();
      await ref.child('schedules/$scheduleId').remove();
      await ref.child('backupMeta').update({
        'lastUploadedAt': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Schedule cloud delete failed: $e');
    }
  }

  Future<void> backupScore(GolfRoundScore score) async {
    try {
      final ref = await _userRef();
      await ref.child('scores/${score.scheduleId}').set({
        ..._normalizeMap(score.toJson()),
        'syncedAt': ServerValue.timestamp,
      });
      await ref.child('backupMeta').update({
        'lastUploadedAt': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Score cloud backup failed: $e');
    }
  }

  Future<void> deleteScore(String scheduleId) async {
    try {
      final ref = await _userRef();
      await ref.child('scores/$scheduleId').remove();
      await ref.child('backupMeta').update({
        'lastUploadedAt': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Score cloud delete failed: $e');
    }
  }

  Future<void> uploadAll({
    required Map<String, Map<String, dynamic>> schedules,
    required Map<String, Map<String, dynamic>> scores,
  }) async {
    final ref = await _userRef();
    await ref.child('schedules').set(_normalizeMapOfMaps(schedules));
    await ref.child('scores').set(_normalizeMapOfMaps(scores));
    await ref.child('backupMeta').update({
      'lastUploadedAt': ServerValue.timestamp,
    });
  }

  Future<CloudBackupSnapshot> downloadAll() async {
    final ref = await _userRef();
    final schedulesSnapshot = await ref.child('schedules').get();
    final scoresSnapshot = await ref.child('scores').get();

    return CloudBackupSnapshot(
      schedules: _mapOfMaps(schedulesSnapshot.value),
      scores: _mapOfMaps(scoresSnapshot.value),
    );
  }

  Future<void> deleteAll() async {
    final ref = await _userRef();
    await ref.remove();
  }

  Future<CloudBackupSummary> getSummary() async {
    try {
      final ref = await _userRef();
      final snapshot = await ref.get();
      if (!snapshot.exists) {
        return const CloudBackupSummary(scheduleCount: 0, scoreCount: 0);
      }

      final root = _normalizeMap(snapshot.value);
      final schedules = _mapOfMaps(root['schedules']);
      final scores = _mapOfMaps(root['scores']);
      final meta = _normalizeMap(root['backupMeta']);
      final lastUploadedAt = (meta['lastUploadedAt'] as num?)?.toInt();

      return CloudBackupSummary(
        scheduleCount: schedules.length,
        scoreCount: scores.length,
        lastUploadedAt: lastUploadedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(lastUploadedAt),
      );
    } catch (e) {
      debugPrint('Cloud backup summary failed: $e');
      return const CloudBackupSummary(scheduleCount: 0, scoreCount: 0);
    }
  }

  Map<String, Map<String, dynamic>> _mapOfMaps(Object? value) {
    if (value is! Map) return {};

    final result = <String, Map<String, dynamic>>{};
    value.forEach((key, raw) {
      if (key == null || raw is! Map) return;
      result[key.toString()] = _normalizeMap(raw);
    });
    return result;
  }

  Map<String, Map<String, dynamic>> _normalizeMapOfMaps(
    Map<String, Map<String, dynamic>> source,
  ) {
    return source.map(
      (key, value) => MapEntry(key, _normalizeMap(value)),
    );
  }

  Map<String, dynamic> _normalizeMap(Object? value) {
    if (value is! Map) return {};

    final result = <String, dynamic>{};
    value.forEach((key, raw) {
      if (key == null || raw == null) return;
      result[key.toString()] = _normalizeValue(raw);
    });
    return result;
  }

  dynamic _normalizeValue(Object? value) {
    if (value is Map) return _normalizeMap(value);
    if (value is List) return value.map(_normalizeValue).toList();
    return value;
  }
}
