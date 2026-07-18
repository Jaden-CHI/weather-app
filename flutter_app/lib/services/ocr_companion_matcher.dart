import '../services/score_ocr_parser.dart';
import 'scorecard_service.dart';

class OcrCompanionResolution {
  final String rawName;
  final String resolvedName;
  final int matchScore;

  const OcrCompanionResolution({
    required this.rawName,
    required this.resolvedName,
    required this.matchScore,
  });

  bool get needsConfirmation {
    final rawKey = normalizeOcrCompanionKey(rawName);
    final resolvedKey = normalizeOcrCompanionKey(resolvedName);
    if (rawKey == null || resolvedKey == null) return false;
    if (looksLikeAmbiguousCompanionName(rawName)) return true;
    if (rawKey != resolvedKey) return true;
    return matchScore < 90;
  }
}

List<OcrCompanionResolution> buildOcrCompanionResolutions({
  required Iterable<String> scannedNames,
  required Iterable<String> currentCompanionNames,
  required List<CompanionNameSuggestion> recommendedNames,
}) {
  final uniqueRawNames = <String>[];
  final seen = <String>{};

  for (final name in scannedNames) {
    final normalized = normalizeOcrCompanionKey(name);
    if (normalized == null || !seen.add(normalized)) continue;
    uniqueRawNames.add(name);
  }

  final currentCandidates = currentCompanionNames
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false);

  return uniqueRawNames
      .map(
        (rawName) => resolveOcrCompanionNameWithScore(
          rawName: rawName,
          currentCompanionNames: currentCandidates,
          recommendedNames: recommendedNames,
        ),
      )
      .toList(growable: false);
}

OcrCompanionResolution resolveOcrCompanionNameWithScore({
  required String rawName,
  required List<String> currentCompanionNames,
  required List<CompanionNameSuggestion> recommendedNames,
}) {
  final trimmed = rawName.trim();
  final normalized = normalizeOcrCompanionKey(trimmed);
  if (normalized == null) {
    return OcrCompanionResolution(
      rawName: rawName,
      resolvedName: trimmed,
      matchScore: 0,
    );
  }

  for (final candidate in currentCompanionNames) {
    if (normalizeOcrCompanionKey(candidate) == normalized) {
      return OcrCompanionResolution(
        rawName: rawName,
        resolvedName: candidate,
        matchScore: 100,
      );
    }
  }

  _RankedCompanionCandidate? bestMatch;
  for (final candidate in currentCompanionNames) {
    final score = scoreCompanionNameMatch(trimmed, candidate);
    final ranked = _RankedCompanionCandidate.current(candidate, score);
    if (_isBetterRankedCandidate(ranked, bestMatch)) {
      bestMatch = ranked;
    }
  }

  for (final suggestion in recommendedNames) {
    final candidate = suggestion.name.trim();
    if (candidate.isEmpty) continue;
    final score = scoreCompanionNameMatch(trimmed, candidate);
    final ranked = _RankedCompanionCandidate.recommended(
      candidate,
      score,
      suggestion.roundCount,
      suggestion.lastPlayedAt,
    );
    if (_isBetterRankedCandidate(ranked, bestMatch)) {
      bestMatch = ranked;
    }
  }

  if (bestMatch != null && bestMatch.matchScore >= 74) {
    return OcrCompanionResolution(
      rawName: rawName,
      resolvedName: bestMatch.name,
      matchScore: bestMatch.matchScore,
    );
  }

  return OcrCompanionResolution(
    rawName: rawName,
    resolvedName: trimmed,
    matchScore: bestMatch?.matchScore ?? 0,
  );
}

String? normalizeOcrCompanionKey(String value) {
  return normalizeNameCandidate(value);
}

int scoreCompanionNameMatch(String source, String candidate) {
  final normalizedSource = normalizeOcrCompanionKey(source);
  final normalizedCandidate = normalizeOcrCompanionKey(candidate);
  if (normalizedSource == null || normalizedCandidate == null) return 0;
  if (normalizedSource == normalizedCandidate) return 100;

  final sourceShape = _normalizeAsciiOcrShape(normalizedSource);
  final candidateShape = _normalizeAsciiOcrShape(normalizedCandidate);
  if (sourceShape == candidateShape) return 96;

  final maxLen = normalizedSource.length > normalizedCandidate.length
      ? normalizedSource.length
      : normalizedCandidate.length;
  if (maxLen == 0) return 0;

  final distance = _levenshteinDistance(normalizedSource, normalizedCandidate);
  var score = (((maxLen - distance) / maxLen) * 100).round();

  if (normalizedSource.startsWith(normalizedCandidate) ||
      normalizedCandidate.startsWith(normalizedSource)) {
    score += 8;
  }

  if (normalizedSource.contains(normalizedCandidate) ||
      normalizedCandidate.contains(normalizedSource)) {
    score += 14;
  }

  final prefixLength =
      _commonPrefixLength(normalizedSource, normalizedCandidate);
  score += prefixLength * 4;

  if (_shareSameLastCharacter(normalizedSource, normalizedCandidate)) {
    score += 4;
  }

  return score.clamp(0, 99);
}

bool looksLikeAmbiguousCompanionName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return true;
  if (trimmed.length <= 1) return true;
  if (RegExp(r'[0-9?]').hasMatch(trimmed)) return true;
  return false;
}

class _RankedCompanionCandidate {
  final String name;
  final int matchScore;
  final bool fromCurrentCompanion;
  final int roundCount;
  final DateTime lastPlayedAt;

  const _RankedCompanionCandidate({
    required this.name,
    required this.matchScore,
    required this.fromCurrentCompanion,
    required this.roundCount,
    required this.lastPlayedAt,
  });

  factory _RankedCompanionCandidate.current(String name, int matchScore) {
    return _RankedCompanionCandidate(
      name: name,
      matchScore: matchScore,
      fromCurrentCompanion: true,
      roundCount: 0,
      lastPlayedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory _RankedCompanionCandidate.recommended(
    String name,
    int matchScore,
    int roundCount,
    DateTime lastPlayedAt,
  ) {
    return _RankedCompanionCandidate(
      name: name,
      matchScore: matchScore,
      fromCurrentCompanion: false,
      roundCount: roundCount,
      lastPlayedAt: lastPlayedAt,
    );
  }
}

bool _isBetterRankedCandidate(
  _RankedCompanionCandidate candidate,
  _RankedCompanionCandidate? currentBest,
) {
  if (currentBest == null) return true;
  if (candidate.matchScore != currentBest.matchScore) {
    return candidate.matchScore > currentBest.matchScore;
  }
  if (candidate.fromCurrentCompanion != currentBest.fromCurrentCompanion) {
    return candidate.fromCurrentCompanion;
  }
  if (candidate.roundCount != currentBest.roundCount) {
    return candidate.roundCount > currentBest.roundCount;
  }
  if (candidate.lastPlayedAt != currentBest.lastPlayedAt) {
    return candidate.lastPlayedAt.isAfter(currentBest.lastPlayedAt);
  }
  return candidate.name.length < currentBest.name.length;
}

String _normalizeAsciiOcrShape(String value) {
  if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value)) return value;

  return value
      .replaceAll('0', 'O')
      .replaceAll('1', 'I')
      .replaceAll('2', 'Z')
      .replaceAll('5', 'S')
      .replaceAll('8', 'B');
}

int _commonPrefixLength(String a, String b) {
  final limit = a.length < b.length ? a.length : b.length;
  var count = 0;
  for (var index = 0; index < limit; index++) {
    if (a[index] != b[index]) break;
    count += 1;
  }
  return count;
}

bool _shareSameLastCharacter(String a, String b) {
  if (a.isEmpty || b.isEmpty) return false;
  return a[a.length - 1] == b[b.length - 1];
}

int _levenshteinDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  final previous = List<int>.generate(b.length + 1, (index) => index);
  final current = List<int>.filled(b.length + 1, 0);

  for (var i = 0; i < a.length; i++) {
    current[0] = i + 1;
    for (var j = 0; j < b.length; j++) {
      final substitutionCost = a[i] == b[j] ? 0 : 1;
      final insert = current[j] + 1;
      final delete = previous[j + 1] + 1;
      final substitute = previous[j] + substitutionCost;
      current[j + 1] = [insert, delete, substitute].reduce(
        (best, value) => value < best ? value : best,
      );
    }
    for (var j = 0; j < current.length; j++) {
      previous[j] = current[j];
    }
  }

  return previous[b.length];
}
