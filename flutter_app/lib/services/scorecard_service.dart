import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/golf_event.dart';
import '../models/golf_score.dart';

class ScorecardService {
  ScorecardService._();
  static final instance = ScorecardService._();

  static const String _scoresKey = 'golf_round_scores_v1';

  Future<GolfRoundScore?> getScoreForSchedule(String scheduleId) async {
    try {
      final scores = await _loadScores();
      final raw = scores[scheduleId];
      if (raw == null) return null;
      return GolfRoundScore.fromJson(raw);
    } catch (e) {
      debugPrint('Score load failed: $e');
      return null;
    }
  }

  Future<GolfRoundScore> getOrCreateScore(GolfEvent event) async {
    final existing = await getScoreForSchedule(event.id);
    if (existing != null) return existing;
    return GolfRoundScore.emptyForEvent(event);
  }

  Future<List<GolfRoundScore>> getAllScores() async {
    final scores = await _loadScores();
    final list = scores.values.map(GolfRoundScore.fromJson).toList();
    list.sort((a, b) => b.playedAt.compareTo(a.playedAt));
    return list;
  }

  Future<void> saveScore(GolfRoundScore score) async {
    final scores = await _loadScores();
    scores[score.scheduleId] =
        score.copyWith(updatedAt: DateTime.now()).toJson();
    await _saveScores(scores);
  }

  Future<void> deleteScoreForSchedule(String scheduleId) async {
    final scores = await _loadScores();
    scores.remove(scheduleId);
    await _saveScores(scores);
  }

  Future<GolfRoundScore?> getLifeBest() async {
    final scores = await getAllScores();
    if (scores.isEmpty) return null;
    scores.sort((a, b) => a.totalScore.compareTo(b.totalScore));
    return scores.first;
  }

  Future<Map<String, Map<String, dynamic>>> _loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scoresKey);
    if (raw == null || raw.isEmpty) return {};

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(key, Map<String, dynamic>.from(value as Map)),
    );
  }

  Future<void> _saveScores(
    Map<String, Map<String, dynamic>> scores,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scoresKey, jsonEncode(scores));
  }
}
