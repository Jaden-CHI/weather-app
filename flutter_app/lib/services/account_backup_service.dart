import 'package:flutter/foundation.dart';

import 'account_service.dart';
import 'app_schedule_service.dart';
import 'cloud_backup_service.dart';
import 'scorecard_service.dart';

class AccountBackupService {
  AccountBackupService._();
  static final instance = AccountBackupService._();

  Future<void> syncNow() async {
    await AccountService.instance.ensureSignedIn();
    final schedules = await AppScheduleService().exportSchedules();
    final scores = await ScorecardService.instance.exportScores();
    await CloudBackupService.instance.uploadAll(
      schedules: schedules,
      scores: scores,
    );
  }

  Future<void> mergeCloudIntoLocalThenUpload() async {
    await AccountService.instance.ensureSignedIn();
    final snapshot = await CloudBackupService.instance.downloadAll();
    await AppScheduleService().importSchedules(snapshot.schedules);
    await ScorecardService.instance.importScores(snapshot.scores);
    await syncNow();
  }

  Future<void> mergeLinkedAccountOnStartup() async {
    try {
      final user = await AccountService.instance.ensureSignedIn();
      if (user.isAnonymous) return;
      await mergeCloudIntoLocalThenUpload();
    } catch (e) {
      debugPrint('Startup backup merge failed: $e');
    }
  }

  Future<CloudBackupSummary> summary() {
    return CloudBackupService.instance.getSummary();
  }

  Future<void> deleteCloudBackup() {
    return CloudBackupService.instance.deleteAll();
  }

  Future<void> signOutToAnonymous() async {
    try {
      await syncNow();
    } catch (e) {
      debugPrint('Backup before sign-out failed: $e');
    }
    await AccountService.instance.signOutToAnonymous();
  }
}
