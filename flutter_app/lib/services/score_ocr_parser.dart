import '../models/golf_score.dart';

class ScoreOcrCompanionResult {
  final String name;
  final List<HoleScore> holes;

  const ScoreOcrCompanionResult({
    required this.name,
    required this.holes,
  });
}

class ScoreOcrParseResult {
  final List<HoleScore> holes;
  final List<String> companionNames;
  final List<ScoreOcrCompanionResult> companions;
  final String? courseName;
  final DateTime? playedAt;
  final String? playerName;

  const ScoreOcrParseResult({
    required this.holes,
    this.companionNames = const [],
    this.companions = const [],
    this.courseName,
    this.playedAt,
    this.playerName,
  });
}

class _ScoreRowCandidate {
  final int lineIndex;
  final List<int> values;
  final String? name;
  final bool hasKeyword;
  final List<int> declaredTotals;

  const _ScoreRowCandidate({
    required this.lineIndex,
    required this.values,
    required this.name,
    required this.hasKeyword,
    this.declaredTotals = const [],
  });
}

class _DistanceSegmentCandidate {
  final List<int> values;
  final bool isMeters;
  final String? groupKey;

  const _DistanceSegmentCandidate({
    required this.values,
    required this.isMeters,
    this.groupKey,
  });
}

class _SummaryNameTotal {
  final String name;
  final int total;

  const _SummaryNameTotal({
    required this.name,
    required this.total,
  });
}

ScoreOcrParseResult parseScorecardText(
  String text,
  List<HoleScore> baseHoles,
) {
  final rawLines = text
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  final lines = _mergeWrappedScoreLines(rawLines);

  final parsedPars = _findParValues(lines);
  final resolvedPars = _resolveParValues(parsedPars, baseHoles);
  final parsedPutts = _findPuttValues(lines);
  final scoreRows = _findScoreRows(lines);
  final metadata = _extractScorecardMetadata(lines, scoreRows);
  final resolvedRows = _resolveScoreRows(scoreRows, resolvedPars);
  final summaryNameTotals = _extractSummaryNameTotals(lines);
  final resolvedPlayerNameKey =
      normalizeNameCandidate(metadata.playerName ?? '');
  var primaryRowIndex = resolvedRows.indexWhere((row) {
    if (resolvedPlayerNameKey == null || row.name.trim().isEmpty) return false;
    return normalizeNameCandidate(row.name) == resolvedPlayerNameKey;
  });
  if (primaryRowIndex < 0 && metadata.headerTotalScore != null) {
    final matchingIndexes = <int>[];
    for (var index = 0; index < resolvedRows.length; index++) {
      final total = resolvedRows[index].holes.fold<int>(
            0,
            (sum, hole) => sum + hole.strokes,
          );
      if (total == metadata.headerTotalScore) {
        matchingIndexes.add(index);
      }
    }
    if (matchingIndexes.length == 1) {
      primaryRowIndex = matchingIndexes.single;
    }
  }
  final primaryRow = resolvedRows.isEmpty
      ? null
      : (primaryRowIndex >= 0
          ? resolvedRows[primaryRowIndex]
          : resolvedRows.first);
  final primaryScoreRow =
      primaryRow?.holes.map((hole) => hole.strokes).toList() ?? const <int>[];
  final canInferPrimaryPlayerFromRow = metadata.playerName != null ||
      metadata.courseName != null ||
      metadata.playedAt != null;
  final resolvedPlayerName = metadata.playerName ??
      (() {
        final headerTotal = metadata.headerTotalScore;
        if (headerTotal == null) return null;
        for (final candidate in summaryNameTotals) {
          if (candidate.total == headerTotal) return candidate.name;
        }
        return null;
      })() ??
      (canInferPrimaryPlayerFromRow &&
              (primaryRow?.name.trim().isNotEmpty ?? false)
          ? primaryRow!.name
          : null);
  final primaryRowNameKey = normalizeNameCandidate(primaryRow?.name ?? '');
  final headerPlayerNameKey = normalizeNameCandidate(resolvedPlayerName ?? '');

  final holes = List.generate(baseHoles.length, (index) {
    final base = baseHoles[index];
    final par = _valueAt(resolvedPars, index, min: 3, max: 6) ?? base.par;
    final strokes =
        _valueAt(primaryScoreRow, index, min: 1, max: 15) ?? base.strokes;
    final putts = _valueAt(parsedPutts, index, min: 0, max: 8) ?? base.putts;
    final puttsTracked = _valueAt(parsedPutts, index, min: 0, max: 8) != null ||
        base.puttsTracked;

    return base.copyWith(
      par: par,
      strokes: strokes < par ? par : strokes,
      putts: putts,
      puttsTracked: puttsTracked,
    );
  });

  final companions = _resolveCompanionsFromRows(
    resolvedRows: resolvedRows,
    primaryRow: primaryRow,
    playerName: resolvedPlayerName,
    summaryNameTotals: summaryNameTotals,
  );

  var companionNames = mergeCompanionNames(
    companions.map((companion) => companion.name),
    [
      ...extractCompanionNames(text),
      ...summaryNameTotals.map((entry) => entry.name),
    ],
  ).where((name) {
    final normalized = normalizeNameCandidate(name);
    if (normalized == null) return false;
    if (headerPlayerNameKey != null && normalized == headerPlayerNameKey) {
      return false;
    }
    return true;
  }).toList(growable: false);

  if (resolvedPlayerName == null &&
      (primaryRow?.name.trim().isNotEmpty ?? false)) {
    final primaryName = primaryRow!.name;
    final primaryKey = normalizeNameCandidate(primaryName);
    final alreadyIncluded = companionNames.any(
      (name) => normalizeNameCandidate(name) == primaryKey,
    );
    if (primaryKey != null && !alreadyIncluded) {
      companionNames = [primaryName, ...companionNames];
    }
  }

  if (companions.isEmpty &&
      primaryRowNameKey != null &&
      companionNames.length == 1 &&
      normalizeNameCandidate(companionNames.first) == primaryRowNameKey) {
    companionNames = const [];
  }

  return ScoreOcrParseResult(
    holes: holes,
    companionNames: companionNames,
    companions: companions,
    courseName: metadata.courseName,
    playedAt: metadata.playedAt,
    playerName: resolvedPlayerName,
  );
}

List<ScoreOcrCompanionResult> _resolveCompanionsFromRows({
  required List<ScoreOcrCompanionResult> resolvedRows,
  required ScoreOcrCompanionResult? primaryRow,
  required String? playerName,
  required List<_SummaryNameTotal> summaryNameTotals,
}) {
  final playerKey = normalizeNameCandidate(playerName ?? '');
  final companions = resolvedRows
      .where((row) => primaryRow == null || row != primaryRow)
      .toList(growable: true);

  final usedNames = companions
      .map((row) => normalizeNameCandidate(row.name))
      .whereType<String>()
      .toSet();

  for (var index = 0; index < companions.length; index++) {
    final companion = companions[index];
    if (companion.name.trim().isNotEmpty) continue;

    final companionTotal = _holesTotal(companion.holes);
    _SummaryNameTotal? matched;
    for (final candidate in summaryNameTotals) {
      final normalized = normalizeNameCandidate(candidate.name);
      if (normalized == null || normalized == playerKey) continue;
      if (usedNames.contains(normalized)) continue;
      if (candidate.total != companionTotal) continue;
      matched = candidate;
      break;
    }

    if (matched == null) continue;
    usedNames.add(normalizeNameCandidate(matched.name)!);
    companions[index] = ScoreOcrCompanionResult(
      name: matched.name,
      holes: companion.holes,
    );
  }

  for (var index = 0; index < companions.length; index++) {
    final companion = companions[index];
    if (companion.name.trim().isNotEmpty) continue;

    final companionTotal = _holesTotal(companion.holes);
    _SummaryNameTotal? matched;
    var bestDiff = 999;

    for (final candidate in summaryNameTotals) {
      final normalized = normalizeNameCandidate(candidate.name);
      if (normalized == null || normalized == playerKey) continue;
      if (usedNames.contains(normalized)) continue;

      final diff = (candidate.total - companionTotal).abs();
      if (diff > 6) continue;
      if (diff >= bestDiff) continue;
      matched = candidate;
      bestDiff = diff;
    }

    if (matched == null) continue;
    usedNames.add(normalizeNameCandidate(matched.name)!);
    companions[index] = ScoreOcrCompanionResult(
      name: matched.name,
      holes: _adjustHolesToTargetTotal(companion.holes, matched.total),
    );
  }

  for (var index = 0; index < companions.length; index++) {
    final companion = companions[index];
    final normalized = normalizeNameCandidate(companion.name);
    if (normalized == null) continue;

    final matched = summaryNameTotals.where((candidate) {
      return normalizeNameCandidate(candidate.name) == normalized;
    }).fold<_SummaryNameTotal?>(
      null,
      (previous, current) => current,
    );
    if (matched == null) continue;

    final adjustedHoles = _adjustHolesToTargetTotal(
      companion.holes,
      matched.total,
    );
    companions[index] = ScoreOcrCompanionResult(
      name: companion.name,
      holes: adjustedHoles,
    );
  }

  return companions
      .where((row) => row.name.trim().isNotEmpty)
      .take(3)
      .toList(growable: false);
}

int _holesTotal(List<HoleScore> holes) {
  return holes.fold<int>(0, (sum, hole) => sum + hole.strokes);
}

List<HoleScore> _adjustHolesToTargetTotal(
  List<HoleScore> holes,
  int targetTotal,
) {
  final currentTotal = _holesTotal(holes);
  if (currentTotal == targetTotal) return holes;
  if (holes.isEmpty) return holes;

  final adjusted = holes.map((hole) => hole.copyWith()).toList(growable: false);
  var delta = targetTotal - currentTotal;

  if (delta < 0) {
    final indexes = List<int>.generate(adjusted.length, (index) => index)
      ..sort((a, b) {
        final aHeadroom = adjusted[a].strokes - adjusted[a].par;
        final bHeadroom = adjusted[b].strokes - adjusted[b].par;
        final headroomCompare = bHeadroom.compareTo(aHeadroom);
        if (headroomCompare != 0) return headroomCompare;
        return adjusted[b].strokes.compareTo(adjusted[a].strokes);
      });

    while (delta < 0) {
      var changed = false;
      for (final index in indexes) {
        final hole = adjusted[index];
        if (hole.strokes <= hole.par) continue;
        adjusted[index] = hole.copyWith(strokes: hole.strokes - 1);
        delta += 1;
        changed = true;
        if (delta == 0) break;
      }
      if (!changed) break;
    }
  } else {
    final indexes = List<int>.generate(adjusted.length, (index) => index)
      ..sort((a, b) {
        final parCompare = adjusted[b].par.compareTo(adjusted[a].par);
        if (parCompare != 0) return parCompare;
        return a.compareTo(b);
      });

    while (delta > 0) {
      for (final index in indexes) {
        final hole = adjusted[index];
        adjusted[index] = hole.copyWith(strokes: hole.strokes + 1);
        delta -= 1;
        if (delta == 0) break;
      }
    }
  }

  return adjusted;
}

List<int> _resolveParValues(List<int> parsedPars, List<HoleScore> baseHoles) {
  final basePars = baseHoles.map((hole) => hole.par).toList(growable: false);
  if (parsedPars.isEmpty) return basePars;

  final hasCourseSpecificBasePars = basePars.toSet().length > 1;
  final hasFullCoverage = parsedPars.length >= baseHoles.length;

  if (hasCourseSpecificBasePars && !hasFullCoverage) {
    return basePars;
  }

  return List<int>.generate(baseHoles.length, (index) {
    return _valueAt(parsedPars, index, min: 3, max: 6) ?? basePars[index];
  }, growable: false);
}

class _ScorecardMetadata {
  final String? courseName;
  final DateTime? playedAt;
  final String? playerName;
  final int? headerTotalScore;

  const _ScorecardMetadata({
    this.courseName,
    this.playedAt,
    this.playerName,
    this.headerTotalScore,
  });
}

_ScorecardMetadata _extractScorecardMetadata(
  List<String> lines,
  List<_ScoreRowCandidate> scoreRows,
) {
  final date = _extractScoreDate(lines);
  final teeTime = _extractTeeTime(lines);
  final playerName = _extractHeaderPlayerName(lines, scoreRows);
  final courseName = _extractCourseName(lines, scoreRows);
  final headerTotalScore = _extractHeaderTotalScore(lines);

  DateTime? playedAt;
  if (date != null) {
    playedAt = teeTime == null
        ? date
        : DateTime(
            date.year,
            date.month,
            date.day,
            teeTime.hour,
            teeTime.minute,
          );
  }

  return _ScorecardMetadata(
    courseName: courseName,
    playedAt: playedAt,
    playerName: playerName,
    headerTotalScore: headerTotalScore,
  );
}

DateTime? _extractScoreDate(List<String> lines) {
  final datePattern = RegExp(
    r'(20\d{2})\s*[./-]\s*(\d{1,2})\s*[./-]\s*(\d{1,2})',
    caseSensitive: false,
  );

  for (final line in lines.take(12)) {
    final match = datePattern.firstMatch(line);
    if (match == null) continue;
    final year = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    final day = int.tryParse(match.group(3) ?? '');
    if (year == null || month == null || day == null) continue;
    if (month < 1 || month > 12 || day < 1 || day > 31) continue;
    return DateTime(year, month, day);
  }

  return null;
}

DateTime? _extractTeeTime(List<String> lines) {
  final timePattern = RegExp(
    r'(?:(AM|PM|오전|오후)\s*)?(\d{1,2})[:.](\d{2})',
    caseSensitive: false,
  );

  for (final line in lines.take(12)) {
    final lower = line.toLowerCase();
    if (!(lower.contains('tee') ||
        lower.contains('off') ||
        line.contains('티오프') ||
        line.contains('티 오프'))) {
      continue;
    }

    final matches = timePattern.allMatches(line).toList(growable: false);
    if (matches.isEmpty) continue;
    final match = matches.last;
    final meridiem = (match.group(1) ?? '').toUpperCase();
    var hour = int.tryParse(match.group(2) ?? '');
    final minute = int.tryParse(match.group(3) ?? '');
    if (hour == null || minute == null) continue;
    if (hour < 0 || hour > 12 || minute < 0 || minute > 59) continue;

    if (meridiem == 'PM' || meridiem == '오후') {
      if (hour < 12) hour += 12;
    } else if (meridiem == 'AM' || meridiem == '오전') {
      if (hour == 12) hour = 0;
    }

    return DateTime(2000, 1, 1, hour, minute);
  }

  for (final line in lines.take(8)) {
    if (!RegExp(r'20\d{2}\s*[./-]\s*\d{1,2}\s*[./-]\s*\d{1,2}')
        .hasMatch(line)) {
      continue;
    }

    final matches = timePattern.allMatches(line).toList(growable: false);
    if (matches.isEmpty) continue;
    final match = matches.last;
    final meridiem = (match.group(1) ?? '').toUpperCase();
    var hour = int.tryParse(match.group(2) ?? '');
    final minute = int.tryParse(match.group(3) ?? '');
    if (hour == null || minute == null) continue;
    if (hour < 0 || hour > 12 || minute < 0 || minute > 59) continue;

    if (meridiem == 'PM' || meridiem == '오후') {
      if (hour < 12) hour += 12;
    } else if (meridiem == 'AM' || meridiem == '오전') {
      if (hour == 12) hour = 0;
    }

    return DateTime(2000, 1, 1, hour, minute);
  }

  return null;
}

int? _extractHeaderTotalScore(List<String> lines) {
  final datePattern = RegExp(
    r'20\d{2}\s*[./-]\s*\d{1,2}\s*[./-]\s*\d{1,2}',
    caseSensitive: false,
  );
  final timePattern = RegExp(
    r'(?:(AM|PM|오전|오후)\s*)?\d{1,2}[:.]\d{2}',
    caseSensitive: false,
  );

  for (final line in lines.take(6)) {
    final lower = line.toLowerCase();
    if (_looksLikePromotionalLine(lower) ||
        lower.contains('tee') ||
        lower.contains('off') ||
        line.contains('티오프') ||
        line.contains('티 오프') ||
        datePattern.hasMatch(line) ||
        timePattern.hasMatch(line)) {
      continue;
    }

    final numbers = _numbersInLine(line)
        .where((value) => value >= 40 && value <= 150)
        .toList(growable: false);
    if (numbers.length == 1) {
      return numbers.single;
    }
  }

  return null;
}

String? _extractCourseName(
  List<String> lines,
  List<_ScoreRowCandidate> scoreRows,
) {
  final scoreStartIndex = scoreRows.isEmpty
      ? lines.length
      : scoreRows
          .map((row) => row.lineIndex)
          .reduce((value, element) => value < element ? value : element);
  final headerLimit = scoreStartIndex.clamp(0, 14);
  if (headerLimit == 0) return null;

  final headerLines = lines.take(headerLimit).toList(growable: false);
  final candidates = <String, int>{};

  void addCandidate(String? raw, int score) {
    final cleaned = _sanitizeCourseDisplay(raw ?? '');
    if (cleaned == null || cleaned.isEmpty) return;
    final previous = candidates[cleaned];
    if (previous == null || score > previous) {
      candidates[cleaned] = score;
    }
  }

  for (var index = 0; index < headerLines.length; index++) {
    final line = headerLines[index];
    if (_looksLikeHeaderPlayerSummaryLine(line)) continue;
    addCandidate(line, _courseLineScore(line));
    addCandidate(
      _extractInlineCourseNameCandidate(line),
      _courseLineScore(_extractInlineCourseNameCandidate(line) ?? ''),
    );

    if (index >= headerLines.length - 1) continue;
    final merged = _mergeCourseHeaderLines(line, headerLines[index + 1]);
    if (merged != null) {
      addCandidate(merged, _courseLineScore(merged) + 1);
    }

    if (index < headerLines.length - 2) {
      final mergedTriple = _mergeCourseHeaderSequence(
        headerLines[index],
        headerLines[index + 1],
        headerLines[index + 2],
      );
      if (mergedTriple != null) {
        addCandidate(mergedTriple, _courseLineScore(mergedTriple) + 2);
      }
    }
  }

  if (candidates.isEmpty) return null;
  final entries = candidates.entries.toList(growable: false)
    ..sort((a, b) {
      final scoreCompare = b.value.compareTo(a.value);
      if (scoreCompare != 0) return scoreCompare;
      return b.key.length.compareTo(a.key.length);
    });
  if (entries.first.value <= 0) return null;

  final selected = entries.first.key;
  final hasHeaderContext = headerLines.any((line) {
    final lower = line.toLowerCase();
    return lower.contains('date') ||
        lower.contains('tee off') ||
        line.contains('티오프') ||
        line.contains('티 오프') ||
        RegExp(r'20\d{2}\s*[./-]\s*\d{1,2}\s*[./-]\s*\d{1,2}').hasMatch(line) ||
        RegExp(r'(?:(?:AM|PM|오전|오후)\s*)?\d{1,2}[:.]\d{2}', caseSensitive: false)
            .hasMatch(line) ||
        lower.contains('country club') ||
        lower.contains('golf club') ||
        lower.contains('resort') ||
        line.contains('컨트리클럽') ||
        line.contains('골프클럽') ||
        line.contains('골프장');
  });

  if (!hasHeaderContext && _looksLikeBarePlayerName(selected)) {
    return null;
  }

  return selected;
}

String? _extractInlineCourseNameCandidate(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return null;

  final cutPatterns = <Pattern>[
    RegExp(r'\bTEE\s*OFF\b', caseSensitive: false),
    RegExp(r'\bDATE\b', caseSensitive: false),
    RegExp(r'\bSMARTSCORE\b', caseSensitive: false),
    '티오프',
    '티 오프',
    '전국 골프장',
    '스코어카드',
    '입력대행',
    '직접입력',
    '무료 출력',
    '서비스',
    '✓',
  ];

  var cutIndex = text.length;
  for (final pattern in cutPatterns) {
    final matchIndex = pattern is RegExp
        ? pattern.firstMatch(text)?.start
        : text.indexOf(pattern.toString());
    if (matchIndex != null && matchIndex >= 0 && matchIndex < cutIndex) {
      cutIndex = matchIndex;
    }
  }

  if (cutIndex <= 0) return null;
  text = text.substring(0, cutIndex).trim();
  return _sanitizeCourseDisplay(text);
}

String? _mergeCourseHeaderLines(String first, String second) {
  final left =
      _extractInlineCourseNameCandidate(first) ?? _sanitizeCourseDisplay(first);
  final right = _extractInlineCourseNameCandidate(second) ??
      _sanitizeCourseDisplay(second);
  if (left == null || right == null) return null;

  final rightLower = right.toLowerCase();
  if (!_looksLikeCourseSuffixLine(rightLower)) return null;
  if (left.toLowerCase() == rightLower) return right;
  if (rightLower.contains(left.toLowerCase())) return right;
  return '$left $right';
}

String? _mergeCourseHeaderSequence(String first, String second, String third) {
  final left =
      _extractInlineCourseNameCandidate(first) ?? _sanitizeCourseDisplay(first);
  final middle = _extractInlineCourseNameCandidate(second) ??
      _sanitizeCourseDisplay(second);
  final right =
      _extractInlineCourseNameCandidate(third) ?? _sanitizeCourseDisplay(third);
  if (left == null || middle == null || right == null) return null;

  final joined = '$left $middle $right';
  final sanitized = _sanitizeCourseDisplay(joined);
  if (sanitized == null) return null;
  if (!_looksLikeCourseSuffixLine(sanitized.toLowerCase())) return null;
  return sanitized;
}

bool _looksLikeCourseSuffixLine(String value) {
  return const <String>[
    'country club',
    'country',
    'club',
    'golf club',
    'golf',
    'resort',
    'cc',
    'gc',
    '컨트리클럽',
    '컨트리',
    '골프클럽',
    '골프장',
    '골프',
    '리조트',
    '클럽',
  ].any(value.contains);
}

int _courseLineScore(String raw) {
  final cleaned = _sanitizeCourseDisplay(raw);
  if (cleaned == null) return -10;

  final lower = cleaned.toLowerCase();
  var score = 0;
  if (RegExp(r'\d').hasMatch(cleaned)) score -= 4;
  if (_looksLikePromotionalLine(lower)) score -= 12;
  if (lower.contains('country club') ||
      lower.contains('golf club') ||
      lower.contains('resort') ||
      lower.contains('cc') ||
      lower.contains('gc') ||
      cleaned.contains('컨트리클럽') ||
      cleaned.contains('골프클럽') ||
      cleaned.contains('골프장')) {
    score += 8;
  }
  if (_looksLikeCourseLabel(cleaned)) score += 5;
  if (cleaned.length >= 3 && cleaned.length <= 28) score += 2;
  return score;
}

bool _looksLikePromotionalLine(String lower) {
  final compact = lower.replaceAll(RegExp(r'[^a-z0-9가-힣]+'), '');
  return const [
    'smartscore',
    'no.1',
    'service',
    '전국골프장',
    '스코어카드',
    '입력대행',
    '직접입력',
    '무료',
    '자동으로',
    '관리하세요',
    '스코어전송',
    '무료출력',
    '골프서비스',
  ].any((keyword) => lower.contains(keyword) || compact.contains(keyword));
}

bool _looksLikeCourseLabel(String value) {
  final compact = value.replaceAll(RegExp(r'\s+'), '');
  if (RegExp(r'^[A-Za-z&.\- ]{3,28}$').hasMatch(value)) return true;
  if (RegExp(r'^[가-힣A-Za-z ]{2,20}$').hasMatch(value)) return true;
  return compact.length >= 2 && compact.length <= 20;
}

bool _looksLikeBarePlayerName(String value) {
  final compact = value.replaceAll(RegExp(r'\s+'), '');
  if (RegExp(r'^[가-힣]{2,4}$').hasMatch(compact)) return true;
  if (RegExp(r'^[A-Za-z]{2,4}$').hasMatch(compact)) return true;
  return false;
}

String? _sanitizeCourseDisplay(String raw) {
  if (_looksLikeScoreTableHeader(raw)) return null;

  final text = raw
      .replaceAll(
        RegExp(r'20\d{2}\s*[./-]\s*\d{1,2}\s*[./-]\s*\d{1,2}'),
        ' ',
      )
      .replaceAll(
        RegExp(r'(?:(?:AM|PM|오전|오후)\s*)?\d{1,2}[:.]\d{2}',
            caseSensitive: false),
        ' ',
      )
      .replaceAll(RegExp(r'^\s*\d{2,3}\s+'), ' ')
      .replaceAll(RegExp(r'\s+\d{2,3}\s*$'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[^A-Za-z가-힣]+|[^A-Za-z가-힣]+$'), '')
      .trim();
  if (text.isEmpty || text.length < 2 || text.length > 80) return null;

  var cleaned = text
      .replaceAll(RegExp(r'COUNIRY', caseSensitive: false), 'COUNTRY')
      .replaceAll(RegExp(r'\bCOUNIRY\b', caseSensitive: false), 'COUNTRY')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  cleaned = cleaned
      .replaceFirst(
        RegExp(r'\s+[가-힣A-Za-z]{2,10}\s+\d{2,3}(?:\s+.*)?$'),
        '',
      )
      .trim();
  final suffixWithName = RegExp(
    r'^(.*?\b(?:COUNTRY CLUB|GOLF CLUB|RESORT|CC|GC|컨트리클럽|골프클럽|골프장))\s+[가-힣A-Za-z]{2,10}$',
    caseSensitive: false,
  ).firstMatch(cleaned);
  if (suffixWithName != null) {
    cleaned = (suffixWithName.group(1) ?? cleaned).trim();
  }

  final koreanParts = cleaned
      .split(' ')
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  final shouldJoinKoreanCourseName = koreanParts.length >= 2 &&
      koreanParts.length <= 3 &&
      koreanParts.every(
        (part) => RegExp(r'^[가-힣]{1,3}$').hasMatch(part),
      ) &&
      !koreanParts.any((part) => const [
            '컨트리',
            '클럽',
            '골프',
            '골프장',
            '리조트',
            '동',
            '서',
            '남',
            '북',
            '합',
          ].contains(part));
  if (shouldJoinKoreanCourseName) {
    cleaned = koreanParts.join();
  }

  if (cleaned.isEmpty || cleaned.length < 2 || cleaned.length > 48) return null;
  if (_looksLikePromotionalLine(cleaned.toLowerCase())) return null;
  final lower = cleaned.toLowerCase();
  if (const [
    'date',
    'tee off',
    'name',
    'score',
    'par',
    'out',
    'in',
    'dream out',
    'dream in',
    'east',
    'west',
    'south',
    'north',
  ].contains(lower)) {
    return null;
  }
  return cleaned;
}

bool _looksLikeScoreTableHeader(String raw) {
  final lower = raw.toLowerCase();
  final numbers = _numbersInLine(raw);
  final compact = raw.replaceAll(RegExp(r'\s+'), '');

  final headerKeyword = lower.contains('total') ||
      lower.contains('tot') ||
      lower.contains('sub') ||
      lower.contains('hole') ||
      lower.contains('par') ||
      compact.contains('합') ||
      compact.contains('남') ||
      compact.contains('동') ||
      compact.contains('서') ||
      compact.contains('북') ||
      compact.contains('dreamout') ||
      compact.contains('dreamin') ||
      compact.contains('east') ||
      compact.contains('west') ||
      compact.contains('south') ||
      compact.contains('north');

  if (!headerKeyword) return false;

  if (numbers.length >= 5) return true;
  return _isSequential(numbers.take(9).toList());
}

bool _looksLikeHeaderPlayerSummaryLine(String line) {
  final lower = line.toLowerCase();
  if (_looksLikePromotionalLine(lower)) return false;
  if (RegExp(r'20\d{2}\s*[./-]\s*\d{1,2}\s*[./-]\s*\d{1,2}').hasMatch(line) ||
      RegExp(r'(?:(?:AM|PM|오전|오후)\s*)?\d{1,2}[:.]\d{2}', caseSensitive: false)
          .hasMatch(line)) {
    return false;
  }

  final numbers = _numbersInLine(line);
  if (!numbers.any((value) => value >= 40 && value <= 150)) return false;

  final name = _extractPrimaryNameFromLine(line);
  if (name == null) return false;

  final compact = line
      .replaceAll(RegExp(r'\d+'), ' ')
      .replaceAll(RegExp(r'[:|/\\\\,;]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final parts = compact.split(' ').where((part) => part.isNotEmpty).toList();
  return parts.length <= 3;
}

List<_ScoreRowCandidate> _findScoreRows(List<String> lines) {
  final candidates = <_ScoreRowCandidate>[];

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    final numbers = _dropHoleLabels(_numbersInLine(line));

    final lower = line.toLowerCase();
    if (const [
      'par',
      'putt',
      '퍼트',
      'hole',
      'out',
      'front',
      'back',
      'nine',
      'sub',
      'tot',
      'handicap',
      'hcp',
      'white',
      'blue',
      'red',
      'black',
    ].any(lower.contains)) {
      continue;
    }

    final values = _extractScoreValuesFromLine(line, numbers);
    final declaredTotals = _extractDeclaredTotals(numbers);
    final canRepairNineHoleRow =
        declaredTotals.isNotEmpty && values.length >= 6 && values.length <= 8;
    if (values.length != 9 && values.length != 18 && !canRepairNineHoleRow) {
      continue;
    }
    if (_isHoleNumberSequence(values)) continue;
    final scoreLikeCount = values.where((n) => n >= 1 && n <= 12).length;
    final relativeLikeCount = values.where((n) => n >= 0 && n <= 5).length;
    if (scoreLikeCount < values.length && relativeLikeCount < values.length) {
      continue;
    }

    final hasKeyword =
        const ['score', '스코어', '타수', 'gross', 'total'].any(lower.contains);

    candidates.add(
      _ScoreRowCandidate(
        lineIndex: index,
        values: values,
        name: hasKeyword ? null : _resolveScoreRowName(lines, index),
        hasKeyword: hasKeyword,
        declaredTotals: declaredTotals,
      ),
    );
  }

  candidates.sort((a, b) {
    if (a.hasKeyword != b.hasKeyword) {
      return a.hasKeyword ? -1 : 1;
    }

    final aNamed = a.name != null;
    final bNamed = b.name != null;
    if (aNamed != bNamed) {
      return aNamed ? 1 : -1;
    }

    final aScoreLike = a.values.where((n) => n >= 1 && n <= 12).length;
    final bScoreLike = b.values.where((n) => n >= 1 && n <= 12).length;
    return bScoreLike.compareTo(aScoreLike);
  });

  return candidates;
}

List<ScoreOcrCompanionResult> _resolveScoreRows(
  List<_ScoreRowCandidate> rows,
  List<int> pars,
) {
  if (rows.isEmpty) return const [];

  final orderedRows = [...rows]
    ..sort((a, b) => a.lineIndex.compareTo(b.lineIndex));

  final pairedResults = _resolveRepeatedRosterRows(orderedRows, pars);
  if (pairedResults.isNotEmpty) {
    return pairedResults;
  }

  final ordered = <String?>[];
  final grouped = <String?, List<_ScoreRowCandidate>>{};
  for (final row in orderedRows) {
    final key = normalizeNameCandidate(row.name ?? '__PRIMARY__');
    if (!grouped.containsKey(key)) {
      ordered.add(key);
      grouped[key] = <_ScoreRowCandidate>[];
    }
    grouped[key]!.add(row);
  }

  final results = <ScoreOcrCompanionResult>[];
  for (final key in ordered) {
    final group = grouped[key]!;
    final mergedValues = _mergeScoreSegments(group, pars);
    if (mergedValues.isEmpty) continue;

    final holes = List.generate(mergedValues.length, (index) {
      final par = index < pars.length ? pars[index] : 4;
      final raw = mergedValues[index];
      final isRelative = _looksLikeRelativeScore(
        mergedValues,
        mergedValues.length == 9 ? pars.take(9).toList() : pars,
        group.expand((row) => row.declaredTotals),
      );
      final strokes = isRelative ? par + raw : raw;
      return HoleScore(
        holeNumber: index + 1,
        par: par,
        strokes: strokes < par ? par : strokes,
        putts: 2,
        puttsTracked: false,
        fairway: par == 3
            ? FairwayResult.notApplicable
            : FairwayResult.notApplicable,
        ob: false,
        penalty: 0,
      );
    });

    final resolvedHoles = holes.length == 9
        ? [
            ...holes,
            ...List.generate(
              9,
              (index) => HoleScore(
                holeNumber: index + 10,
                par: index + 9 < pars.length ? pars[index + 9] : 4,
                strokes: index + 9 < pars.length ? pars[index + 9] : 4,
                putts: 2,
                puttsTracked: false,
                fairway: FairwayResult.notApplicable,
                ob: false,
                penalty: 0,
              ),
            ),
          ]
        : holes;

    results.add(
      ScoreOcrCompanionResult(
        name: key == '__PRIMARY__' ? '' : (group.first.name ?? ''),
        holes: resolvedHoles,
      ),
    );
  }

  results.sort((a, b) {
    final aPrimary = a.name.isEmpty;
    final bPrimary = b.name.isEmpty;
    if (aPrimary != bPrimary) return aPrimary ? -1 : 1;
    return 0;
  });

  return results;
}

List<ScoreOcrCompanionResult> _resolveRepeatedRosterRows(
  List<_ScoreRowCandidate> orderedRows,
  List<int> pars,
) {
  if (orderedRows.length < 2 || orderedRows.length.isOdd) return const [];
  if (orderedRows
      .any((row) => row.values.length < 6 || row.values.length > 9)) {
    return const [];
  }

  final half = orderedRows.length ~/ 2;
  final frontRows = orderedRows.take(half).toList(growable: false);
  final backRows = orderedRows.skip(half).toList(growable: false);

  var matchedPairs = 0;
  for (var index = 0; index < half; index++) {
    if (_looksLikeSamePlayerName(frontRows[index].name, backRows[index].name)) {
      matchedPairs += 1;
    }
  }

  if (orderedRows.length > 2 && matchedPairs == 0) {
    return const [];
  }

  return List<ScoreOcrCompanionResult>.generate(half, (index) {
    final front = frontRows[index];
    final back = backRows[index];
    final frontValues = _repairRelativeNineHoleValues(
      front.values,
      pars.take(9).toList(growable: false),
      front.declaredTotals,
    );
    final backValues = _repairRelativeNineHoleValues(
      back.values,
      pars.skip(9).take(9).toList(growable: false),
      back.declaredTotals,
    );
    final mergedValues = <int>[
      ...frontValues.take(9),
      ...backValues.take(9),
    ];
    final declaredTotals = <int>[
      ...front.declaredTotals,
      ...back.declaredTotals,
    ];
    final isRelative = _looksLikeRelativeScore(
      mergedValues,
      pars,
      declaredTotals,
    );

    final holes = List<HoleScore>.generate(mergedValues.length, (holeIndex) {
      final par = holeIndex < pars.length ? pars[holeIndex] : 4;
      final raw = mergedValues[holeIndex];
      final strokes = isRelative ? par + raw : raw;
      return HoleScore(
        holeNumber: holeIndex + 1,
        par: par,
        strokes: strokes < par ? par : strokes,
        putts: 2,
        puttsTracked: false,
        fairway: FairwayResult.notApplicable,
        ob: false,
        penalty: 0,
      );
    });

    return ScoreOcrCompanionResult(
      name: _pickMergedRowName(front.name, back.name),
      holes: holes,
    );
  }, growable: false);
}

List<int> _repairRelativeNineHoleValues(
  List<int> values,
  List<int> pars,
  List<int> declaredTotals,
) {
  if (values.length >= 9 || values.length < 6) return values;
  if (pars.length < 9) return values;

  final subtotal =
      declaredTotals.where((value) => value >= 35 && value <= 70).fold<int?>(
            null,
            (previous, current) => current,
          );
  if (subtotal == null) return values;

  final parTotal = pars.take(9).fold<int>(0, (sum, par) => sum + par);
  final targetRelative = subtotal - parTotal;
  if (targetRelative < 0 || targetRelative > 36) return values;

  final currentRelative = values.fold<int>(0, (sum, value) => sum + value);
  final missingCount = 9 - values.length;
  final missingRelative = targetRelative - currentRelative;
  if (missingCount <= 0 ||
      missingRelative < 0 ||
      missingRelative > missingCount * 4) {
    return values;
  }

  final fillers = List<int>.filled(missingCount, 0);
  var remaining = missingRelative;
  for (var index = 0; index < fillers.length && remaining > 0; index++) {
    final assign = remaining > 1 ? 1 : remaining;
    fillers[index] = assign;
    remaining -= assign;
  }
  if (remaining > 0) {
    for (var index = 0; index < fillers.length && remaining > 0; index++) {
      final room = 4 - fillers[index];
      if (room <= 0) continue;
      final assign = remaining > room ? room : remaining;
      fillers[index] += assign;
      remaining -= assign;
    }
  }
  if (remaining != 0) return values;

  return <int>[
    ...values.take(values.length - 1),
    ...fillers,
    values.last,
  ];
}

String _pickMergedRowName(String? first, String? second) {
  final left = first?.trim() ?? '';
  final right = second?.trim() ?? '';
  if (left.isEmpty) return right;
  if (right.isEmpty) return left;

  if (_looksLikeSamePlayerName(left, right)) {
    return _preferBetterNameCandidate(left, right);
  }

  return left;
}

String _preferBetterNameCandidate(String first, String second) {
  final firstCompact = first.replaceAll(RegExp(r'\\s+'), '');
  final secondCompact = second.replaceAll(RegExp(r'\\s+'), '');

  final firstHasSurname = RegExp(r'^[가-힣]{3,5}$').hasMatch(firstCompact);
  final secondHasSurname = RegExp(r'^[가-힣]{3,5}$').hasMatch(secondCompact);
  if (firstHasSurname != secondHasSurname) {
    return secondHasSurname ? second : first;
  }

  if (secondCompact.length != firstCompact.length) {
    return secondCompact.length > firstCompact.length ? second : first;
  }

  return first;
}

bool _looksLikeSamePlayerName(String? first, String? second) {
  final left = normalizeNameCandidate(first ?? '');
  final right = normalizeNameCandidate(second ?? '');
  if (left == null || right == null) return false;
  if (left == right) return true;

  final leftVariants = _nameMatchVariants(left);
  final rightVariants = _nameMatchVariants(right);
  if (leftVariants.intersection(rightVariants).isNotEmpty) {
    return true;
  }

  for (final leftVariant in leftVariants) {
    for (final rightVariant in rightVariants) {
      if (leftVariant.length < 2 || rightVariant.length < 2) continue;
      if (leftVariant.length != rightVariant.length) continue;
      if (_editDistance(leftVariant, rightVariant) <= 1) {
        return true;
      }
    }
  }

  return false;
}

Set<String> _nameMatchVariants(String normalized) {
  final variants = <String>{normalized};
  if (RegExp(r'^[가-힣]{3,5}$').hasMatch(normalized)) {
    variants.add(normalized.substring(1));
  }
  return variants;
}

int _editDistance(String first, String second) {
  if (first == second) return 0;
  if (first.isEmpty) return second.length;
  if (second.isEmpty) return first.length;

  final previous = List<int>.generate(second.length + 1, (index) => index);
  final current = List<int>.filled(second.length + 1, 0);

  for (var i = 1; i <= first.length; i++) {
    current[0] = i;
    for (var j = 1; j <= second.length; j++) {
      final cost = first[i - 1] == second[j - 1] ? 0 : 1;
      current[j] = [
        previous[j] + 1,
        current[j - 1] + 1,
        previous[j - 1] + cost,
      ].reduce((a, b) => a < b ? a : b);
    }
    for (var j = 0; j < current.length; j++) {
      previous[j] = current[j];
    }
  }

  return previous.last;
}

List<int> _mergeScoreSegments(
  List<_ScoreRowCandidate> rows,
  List<int> pars,
) {
  final orderedRows = [...rows]
    ..sort((a, b) => a.lineIndex.compareTo(b.lineIndex));

  for (final row in orderedRows) {
    if (row.values.length >= 18) {
      return row.values.take(18).toList(growable: false);
    }
  }

  for (final row in orderedRows) {
    if (row.values.length < 15 || row.values.length >= 18) continue;
    final repaired = _repairRelativeEighteenHoleValues(
      row.values,
      pars,
      row.declaredTotals,
    );
    if (repaired.length >= 18) {
      return repaired.take(18).toList(growable: false);
    }
  }

  final segments = orderedRows
      .where((row) => row.values.length == 9)
      .toList(growable: false);
  if (segments.length >= 2) {
    return [
      ...segments[0].values.take(9),
      ...segments[1].values.take(9),
    ];
  }

  if (segments.isNotEmpty) {
    return segments.first.values;
  }

  return const [];
}

List<int> _repairRelativeEighteenHoleValues(
  List<int> values,
  List<int> pars,
  List<int> declaredTotals,
) {
  if (values.length >= 18 || values.length < 15) return values;
  if (pars.length < 18) return values;

  final subtotals = declaredTotals
      .where((value) => value >= 35 && value <= 70)
      .take(2)
      .toList(growable: false);
  if (subtotals.length < 2) return values;

  for (var frontLength = 9; frontLength >= 6; frontLength--) {
    final backLength = values.length - frontLength;
    if (backLength < 6 || backLength > 9) continue;

    final frontPars = pars.take(9).toList(growable: false);
    final backPars = pars.skip(9).take(9).toList(growable: false);
    final frontValues = _repairRelativeNineHoleValues(
      values.take(frontLength).toList(growable: false),
      frontPars,
      [subtotals[0]],
    );
    final backValues = _repairRelativeNineHoleValues(
      values.skip(frontLength).toList(growable: false),
      backPars,
      [subtotals[1]],
    );

    if (frontValues.length != 9 || backValues.length != 9) continue;
    if (!_matchesDeclaredSubtotal(frontValues, frontPars, subtotals[0])) {
      continue;
    }
    if (!_matchesDeclaredSubtotal(backValues, backPars, subtotals[1])) {
      continue;
    }

    return <int>[...frontValues, ...backValues];
  }

  return values;
}

bool _matchesDeclaredSubtotal(
  List<int> values,
  List<int> pars,
  int subtotal,
) {
  if (values.length != 9 || pars.length < 9) return false;
  final relativeTotal = values.fold<int>(0, (sum, value) => sum + value);
  final parTotal = pars.take(9).fold<int>(0, (sum, par) => sum + par);
  return relativeTotal + parTotal == subtotal;
}

bool _looksLikeRelativeScore(
  List<int> values,
  List<int> pars,
  Iterable<int> declaredTotals,
) {
  final smallValues = values.where((value) => value >= 0 && value <= 4).length;
  if (smallValues >= values.length && values.contains(0)) return true;
  final relativeValues =
      values.where((value) => value >= 0 && value <= 5).length;
  if (relativeValues >= values.length && values.contains(0)) return true;

  if (pars.length < values.length) return false;
  final parTotal =
      pars.take(values.length).fold<int>(0, (sum, par) => sum + par);
  final valueTotal = values.fold<int>(0, (sum, value) => sum + value);
  return declaredTotals
      .any((declaredTotal) => valueTotal + parTotal == declaredTotal);
}

List<int> _findParValues(List<String> lines) {
  final segments = _findSegmentedNumberRows(
    lines,
    const ['par', '파'],
    min: 3,
    max: 6,
  );
  final explicitPars = _combineSegments(segments, maxLength: 18);
  if (explicitPars.isNotEmpty) return explicitPars;

  final distanceSegments = _findSegmentedDistanceRows(lines);
  if (distanceSegments.isEmpty) return const [];

  return _combineDistancePars(distanceSegments);
}

List<int> _findPuttValues(List<String> lines) {
  final segments = _findSegmentedNumberRows(
    lines,
    const ['putt', '퍼트'],
    min: 0,
    max: 8,
  );
  return _combineSegments(segments, maxLength: 18);
}

List<List<int>> _findSegmentedNumberRows(
  List<String> lines,
  List<String> keywords, {
  required int min,
  required int max,
}) {
  final segments = <List<int>>[];
  for (final line in lines) {
    final lower = line.toLowerCase();
    if (!keywords.any(lower.contains)) continue;
    final numbers = _dropHoleLabels(_numbersInLine(line));
    final values = _extractSegmentValuesFromLine(
      line,
      numbers,
      min: min,
      max: max,
      preserveTrailingTotals:
          keywords.contains('par') || keywords.contains('파'),
    );
    if (values.length >= 18) {
      segments.add(values.take(18).toList(growable: false));
    } else if (values.length >= 9) {
      segments.add(values.take(9).toList(growable: false));
    }
  }
  return segments;
}

List<_DistanceSegmentCandidate> _findSegmentedDistanceRows(List<String> lines) {
  final teeKeywords = <String>[
    'blue',
    'white',
    'red',
    'black',
    'gold',
    'yellow',
    'lady',
    'champion',
    'forward',
    'regular',
    '레이크',
    '마운틴',
    'lake',
    'mountain',
    'course',
  ];
  final blockedKeywords = <String>[
    'score',
    '스코어',
    'putt',
    '퍼트',
    'par',
    '파',
    'handicap',
    'hcp',
  ];

  final segments = <_DistanceSegmentCandidate>[];
  for (final line in lines) {
    final lower = line.toLowerCase();
    if (blockedKeywords.any(lower.contains)) continue;

    final hasTeeHint = teeKeywords.any(lower.contains);
    final numbers = _dropHoleLabels(_numbersInLine(line));
    final values = numbers
        .where((value) => value >= 80 && value <= 700)
        .toList(growable: false);
    if (values.length < 9) continue;

    final selected = values.length >= 18
        ? values.take(18).toList(growable: false)
        : values.take(9).toList(growable: false);
    final maxValue = selected.reduce((a, b) => a > b ? a : b);
    if (!hasTeeHint && maxValue < 120) continue;

    segments.add(
      _DistanceSegmentCandidate(
        values: selected,
        isMeters: _looksLikeMeters(line, selected),
        groupKey: _extractDistanceGroupKey(line),
      ),
    );
  }
  return segments;
}

List<int> _combineSegments(
  List<List<int>> segments, {
  required int maxLength,
}) {
  if (segments.isEmpty) return const [];
  for (final segment in segments) {
    if (segment.length >= maxLength) {
      return segment.take(maxLength).toList(growable: false);
    }
  }
  if (segments.length >= 2 &&
      segments[0].length == 9 &&
      segments[1].length == 9) {
    return [...segments[0], ...segments[1]];
  }
  return segments.first;
}

List<int> _combineDistancePars(List<_DistanceSegmentCandidate> segments) {
  for (final segment in segments) {
    if (segment.values.length >= 18) {
      return segment.values
          .take(18)
          .map((distance) => _inferParFromDistance(distance, segment.isMeters))
          .toList(growable: false);
    }
  }

  final grouped = <String, List<_DistanceSegmentCandidate>>{};
  for (final segment in segments) {
    final key = segment.groupKey;
    if (key == null || key.isEmpty) continue;
    grouped.putIfAbsent(key, () => <_DistanceSegmentCandidate>[]).add(segment);
  }

  for (final entry in grouped.entries) {
    final group =
        entry.value.where((segment) => segment.values.length == 9).toList();
    if (group.length < 2) continue;
    return [
      ...group[0].values.take(9).map(
          (distance) => _inferParFromDistance(distance, group[0].isMeters)),
      ...group[1].values.take(9).map(
          (distance) => _inferParFromDistance(distance, group[1].isMeters)),
    ];
  }

  if (segments.length >= 2 &&
      segments[0].values.length == 9 &&
      segments[1].values.length == 9) {
    return [
      ...segments[0].values.take(9).map(
          (distance) => _inferParFromDistance(distance, segments[0].isMeters)),
      ...segments[1].values.take(9).map(
          (distance) => _inferParFromDistance(distance, segments[1].isMeters)),
    ];
  }

  return segments.first.values
      .map((distance) =>
          _inferParFromDistance(distance, segments.first.isMeters))
      .toList(growable: false);
}

List<int> _extractScoreValues(List<int> numbers) {
  final values = numbers.where((value) => value >= 0 && value <= 12).toList();
  if (values.length >= 18) {
    return values.take(18).toList(growable: false);
  }
  if (values.length >= 9) {
    return values.take(9).toList(growable: false);
  }
  return const [];
}

List<int> _extractScoreValuesFromLine(String line, List<int> numbers) {
  final declaredTotals = _extractDeclaredTotals(numbers);
  final values = _extractSegmentValuesFromLine(
    line,
    numbers,
    min: 0,
    max: 12,
    preserveTrailingTotals: true,
    forcedTargetLength: declaredTotals.length >= 2
        ? 18
        : (declaredTotals.isNotEmpty ? 9 : null),
    preferRelativeSplits: declaredTotals.isNotEmpty,
  );
  if (values.length >= 18) {
    return values.take(18).toList(growable: false);
  }
  if (values.length >= 15) {
    return values;
  }
  if (values.length >= 9) {
    return values.take(9).toList(growable: false);
  }
  if (values.length >= 6) {
    return values;
  }
  return const [];
}

List<int> _extractSegmentValuesFromLine(
  String line,
  List<int> numbers, {
  required int min,
  required int max,
  bool preserveTrailingTotals = false,
  int? forcedTargetLength,
  bool preferRelativeSplits = false,
}) {
  final baseValues = numbers
      .where((value) => value >= min && value <= max)
      .toList(growable: false);
  if (baseValues.length == 9 || baseValues.length == 18) {
    return baseValues;
  }

  final tokens = line
      .replaceAll(RegExp(r'[:,;()\[\]{}]'), ' ')
      .split(RegExp(r'\s+'))
      .map((token) => token.trim())
      .where((token) => token.isNotEmpty)
      .toList(growable: false);
  if (tokens.isEmpty) return baseValues;

  final parsedTokens = tokens
      .map((token) => _ParsedCompactToken.fromToken(token, min: min, max: max))
      .whereType<_ParsedCompactToken>()
      .toList(growable: false);
  if (parsedTokens.isEmpty) return baseValues;

  final relativeLikeLine =
      preferRelativeSplits || _looksRelativeCompactLine(parsedTokens, max: max);
  final targetLength = forcedTargetLength ?? (baseValues.length <= 9 ? 9 : 18);

  var trailingTotals = 0;
  if (preserveTrailingTotals) {
    for (final token in parsedTokens.reversed) {
      if (token.directValue != null && token.directValue! >= 18) {
        trailingTotals += 1;
        continue;
      }
      break;
    }
  }

  final selected = <int>[];
  for (var index = 0; index < parsedTokens.length; index++) {
    final token = parsedTokens[index];
    final isTrailingTotal =
        preserveTrailingTotals && index >= parsedTokens.length - trailingTotals;
    if (isTrailingTotal) continue;

    final remainingTokens = parsedTokens.length - trailingTotals - index - 1;
    final remainingSlots = targetLength - selected.length;

    if (remainingSlots <= 0) break;

    final splitCandidate = token.splitValues;
    final directValue = token.directValue;

    final shouldPreferSplit = splitCandidate != null &&
        splitCandidate.isNotEmpty &&
        _shouldPreferSplitToken(
          token,
          directValue: directValue,
          splitCandidate: splitCandidate,
          relativeLikeLine: relativeLikeLine,
          min: min,
          max: max,
          remainingSlots: remainingSlots,
          remainingTokens: remainingTokens,
        );

    if (shouldPreferSplit) {
      final takeCount = splitCandidate.length <= remainingSlots
          ? splitCandidate.length
          : remainingSlots;
      selected.addAll(splitCandidate.take(takeCount));
      continue;
    }

    if (directValue != null && directValue >= min && directValue <= max) {
      selected.add(directValue);
    }
  }

  return selected.length > baseValues.length ? selected : baseValues;
}

bool _shouldPreferSplitToken(
  _ParsedCompactToken token, {
  required int? directValue,
  required List<int> splitCandidate,
  required bool relativeLikeLine,
  required int min,
  required int max,
  required int remainingSlots,
  required int remainingTokens,
}) {
  if (splitCandidate.isEmpty) return false;
  if (splitCandidate.length > remainingSlots && directValue != null) {
    return false;
  }

  if (directValue == null || directValue < min || directValue > max) {
    return splitCandidate.length <= remainingSlots;
  }

  if (token.raw.length <= 1) return false;

  final allDigitsWithinRelativeRange =
      splitCandidate.every((value) => value >= 0 && value <= 4);
  if (relativeLikeLine && allDigitsWithinRelativeRange) {
    final minimumNeededSlots = remainingTokens + 1;
    return splitCandidate.length <= remainingSlots ||
        minimumNeededSlots < remainingSlots;
  }

  return false;
}

bool _looksRelativeCompactLine(
  List<_ParsedCompactToken> tokens, {
  required int max,
}) {
  final directValues = tokens
      .map((token) => token.directValue)
      .whereType<int>()
      .where((value) => value >= 0 && value <= max)
      .toList(growable: false);
  if (directValues.isEmpty) return false;

  final relativeCount = directValues.where((value) => value <= 4).length;
  final highCount = directValues.where((value) => value >= 7).length;
  return relativeCount >= 5 && highCount <= 1;
}

class _ParsedCompactToken {
  final String raw;
  final int? directValue;
  final List<int>? splitValues;

  const _ParsedCompactToken({
    required this.raw,
    required this.directValue,
    required this.splitValues,
  });

  static _ParsedCompactToken? fromToken(
    String token, {
    required int min,
    required int max,
  }) {
    final raw = token.trim();
    if (raw.isEmpty) return null;

    final directValue = int.tryParse(raw);
    final splitValues = _splitCompactToken(raw, min: min, max: max);

    if (directValue == null && splitValues == null) return null;
    return _ParsedCompactToken(
      raw: raw,
      directValue: directValue,
      splitValues: splitValues,
    );
  }
}

List<int>? _splitCompactToken(
  String token, {
  required int min,
  required int max,
}) {
  final compact = token.trim();
  if (compact.length < 2 || compact.length > 9) return null;

  final digits = <int>[];
  for (final rune in compact.runes) {
    final char = String.fromCharCode(rune);
    final direct = int.tryParse(char);
    if (direct != null) {
      digits.add(direct);
      continue;
    }

    final normalized = _normalizeOcrDigitToken(char);
    final mapped = int.tryParse(normalized);
    if (mapped == null) return null;
    digits.add(mapped);
  }

  if (digits.every((value) => value >= min && value <= max)) {
    return digits;
  }
  return null;
}

List<int> _extractDeclaredTotals(List<int> numbers) {
  return numbers.where((value) => value >= 18).toList(growable: false);
}

bool _looksLikeMeters(String line, List<int> distances) {
  final lower = line.toLowerCase();
  if (lower.contains('unit') && lower.contains('m')) return true;

  final average =
      distances.fold<int>(0, (sum, value) => sum + value) / distances.length;
  final maxValue = distances.reduce((a, b) => a > b ? a : b);
  return average < 360 && maxValue < 560;
}

String? _extractDistanceGroupKey(String line) {
  final lower = line.toLowerCase();
  const groupKeywords = <String>[
    'blue',
    'white',
    'red',
    'black',
    'gold',
    'yellow',
    'lady',
    'champion',
    'forward',
    'regular',
  ];

  for (final keyword in groupKeywords) {
    if (lower.contains(keyword)) return keyword;
  }
  return null;
}

int _inferParFromDistance(int distance, bool isMeters) {
  if (isMeters) {
    if (distance <= 210) return 3;
    if (distance >= 430) return 5;
    return 4;
  }

  if (distance <= 235) return 3;
  if (distance >= 470) return 5;
  return 4;
}

String? _resolveScoreRowName(List<String> lines, int index) {
  final current = _extractPrimaryNameFromLine(lines[index]);
  if (current != null) return current;

  for (final offset in const [-1, 1, -2]) {
    final candidateIndex = index + offset;
    if (candidateIndex < 0 || candidateIndex >= lines.length) continue;
    final candidateLine = lines[candidateIndex];
    if (RegExp(r'\d').hasMatch(candidateLine)) continue;
    final name = _extractPrimaryNameFromLine(candidateLine);
    if (name != null) return name;
  }

  return null;
}

List<int> _numbersInLine(String line) {
  final tokens = line
      .replaceAll(RegExp(r'[:,;()\[\]{}]'), ' ')
      .split(RegExp(r'\s+'))
      .map((token) => token.trim())
      .where((token) => token.isNotEmpty);

  final values = <int>[];
  for (final token in tokens) {
    final direct = int.tryParse(token);
    if (direct != null && direct >= 0 && direct <= 9999) {
      values.add(direct);
      continue;
    }

    final compactOcrDigits = _extractCompactOcrDigits(token);
    if (compactOcrDigits.isNotEmpty) {
      values.addAll(compactOcrDigits);
      continue;
    }

    final digitMatches = RegExp(r'\d+').allMatches(token);
    for (final match in digitMatches) {
      final parsed = int.tryParse(match.group(0) ?? '');
      if (parsed != null && parsed >= 0 && parsed <= 9999) {
        values.add(parsed);
      }
    }
    if (digitMatches.isNotEmpty) continue;

    final normalized = _normalizeOcrDigitToken(token);
    final lookalike = int.tryParse(normalized);
    if (lookalike != null && lookalike >= 0 && lookalike <= 9) {
      values.add(lookalike);
    }
  }

  return values;
}

List<int> _extractCompactOcrDigits(String token) {
  final trimmed = token.trim();
  if (trimmed.length < 4 || trimmed.length > 24) return const [];
  if (!RegExp(r'^[0-9OQILZSB/\\|!]+$', caseSensitive: false)
      .hasMatch(trimmed)) {
    return const [];
  }

  final lookalikeCount = RegExp(r'[OQILZSB/\\|!]', caseSensitive: false)
      .allMatches(trimmed)
      .length;
  if (lookalikeCount < 4) return const [];

  final values = <int>[];
  for (final rune in trimmed.runes) {
    final char = String.fromCharCode(rune);
    final direct = int.tryParse(char);
    if (direct != null) {
      values.add(direct);
      continue;
    }

    final normalized = _normalizeOcrDigitToken(char);
    final mapped = int.tryParse(normalized);
    if (mapped == null) return const [];
    values.add(mapped);
  }

  return values.length >= 4 ? values : const [];
}

String _normalizeOcrDigitToken(String token) {
  final trimmed = token.trim();
  if (trimmed.isEmpty || trimmed.length > 3) return '';
  if (RegExp(r'^[\/\\|!Il]+$').hasMatch(trimmed)) {
    return '1';
  }
  if (RegExp(r'^[OQ]+$', caseSensitive: false).hasMatch(trimmed)) {
    return '0';
  }
  if (trimmed.length != 1) return '';

  switch (trimmed.toUpperCase()) {
    case 'O':
    case 'Q':
      return '0';
    case 'I':
    case 'L':
      return '1';
    case 'Z':
      return '2';
    case 'S':
      return '5';
    case 'B':
      return '8';
    default:
      return '';
  }
}

List<int> _dropHoleLabels(List<int> numbers) {
  if (numbers.length >= 27) {
    final firstNine = numbers.take(9).toList();
    final firstEighteen = numbers.take(18).toList();
    if (_isSequential(firstNine) || _isSequential(firstEighteen)) {
      return numbers.skip(firstEighteen.length).toList();
    }
  }

  if (numbers.length >= 18) {
    final firstNine = numbers.take(9).toList();
    if (_isSequential(firstNine)) return numbers.skip(9).toList();
  }

  return numbers;
}

bool _isSequential(List<int> values) {
  if (values.isEmpty) return false;
  for (var i = 0; i < values.length; i++) {
    if (values[i] != i + 1) return false;
  }
  return true;
}

bool _isHoleNumberSequence(List<int> values) {
  if (_isSequential(values)) return true;
  if (values.length != 9) return false;
  for (var i = 0; i < values.length; i++) {
    if (values[i] != i + 10) return false;
  }
  return true;
}

int? _valueAt(
  List<int> values,
  int index, {
  required int min,
  required int max,
}) {
  if (index >= values.length) return null;
  final value = values[index];
  if (value < min || value > max) return null;
  return value;
}

List<String> extractCompanionNames(String text) {
  final rawLines = text
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  final lines = _mergeWrappedScoreLines(rawLines);

  final candidates = <String>[];
  final seen = <String>{};
  final rowCandidates = _findScoreRows(lines);

  for (final row in rowCandidates) {
    final name = row.name;
    final normalized = normalizeNameCandidate(name ?? '');
    if (name == null || normalized == null || !seen.add(normalized)) continue;
    candidates.add(name);
    if (candidates.length >= 4) return candidates;
  }

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    if (!_isCompanionNameContext(lines, index)) continue;
    final tokens = _tokenizeNameCandidates(line);
    for (final token in tokens) {
      final normalized = normalizeNameCandidate(token);
      if (normalized == null || !seen.add(normalized)) continue;
      candidates.add(token);
      if (candidates.length >= 4) return candidates;
    }
  }

  return candidates;
}

List<String> _mergeWrappedScoreLines(List<String> lines) {
  if (lines.length < 2) return lines;

  final merged = <String>[];
  var index = 0;

  while (index < lines.length) {
    var current = lines[index];

    while (index + 1 < lines.length &&
        _shouldMergeWrappedScoreLine(current, lines[index + 1])) {
      current = '$current ${lines[index + 1]}';
      index += 1;
    }

    merged.add(current);
    index += 1;
  }

  return merged;
}

bool _shouldMergeWrappedScoreLine(String current, String next) {
  final currentName = _extractPrimaryNameFromLine(current);
  if (currentName == null) return false;
  if (_looksLikeScoreTableHeader(current) || _looksLikeScoreTableHeader(next)) {
    return false;
  }
  if (_looksLikePromotionalLine(next.toLowerCase())) return false;

  final currentNumbers = _dropHoleLabels(_numbersInLine(current));
  final currentValues = _extractScoreValuesFromLine(current, currentNumbers);
  if (currentValues.length < 9 || currentValues.length >= 18) {
    return false;
  }

  final nextName = _extractPrimaryNameFromLine(next);
  if (nextName != null) return false;

  final nextNumbers = _dropHoleLabels(_numbersInLine(next));
  if (nextNumbers.isEmpty || nextNumbers.length > 4) return false;
  if (nextNumbers.any((value) => value > 120)) return false;

  final mergedLine = '$current $next';
  final mergedNumbers = _dropHoleLabels(_numbersInLine(mergedLine));
  final mergedValues = _extractScoreValuesFromLine(mergedLine, mergedNumbers);

  return mergedValues.length > currentValues.length;
}

List<_SummaryNameTotal> _extractSummaryNameTotals(List<String> lines) {
  final results = <_SummaryNameTotal>[];
  final seen = <String>{};

  for (final line in lines) {
    final lower = line.toLowerCase();
    if (!(lower.contains('total') || line.contains('합계'))) continue;

    final normalized = line
        .replaceAll(RegExp(r'[:|/\\\\,;]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) continue;

    final tokens =
        normalized.split(' ').where((part) => part.isNotEmpty).toList();
    if (tokens.isEmpty) continue;

    final nameBuffer = <String>[];
    for (final token in tokens) {
      final tokenLower = token.toLowerCase();
      if (tokenLower == 'total' || token == '합계') {
        nameBuffer.clear();
        continue;
      }

      final score = int.tryParse(token);
      if (score != null) {
        if (score < 40 || score > 150 || nameBuffer.isEmpty) {
          nameBuffer.clear();
          continue;
        }

        final name = _extractPrimaryNameFromLine(nameBuffer.join(' '));
        final normalizedName = normalizeNameCandidate(name ?? '');
        if (name != null &&
            normalizedName != null &&
            seen.add(normalizedName)) {
          results.add(_SummaryNameTotal(name: name, total: score));
        }
        nameBuffer.clear();
        continue;
      }

      if (RegExp(r'\d').hasMatch(token)) continue;
      nameBuffer.add(token);
    }
  }

  return results;
}

bool _isCompanionNameContext(List<String> lines, int index) {
  final line = lines[index];
  if (RegExp(r'\d').hasMatch(line)) return false;

  for (final offset in const [-1, 1, -2, 2]) {
    final candidateIndex = index + offset;
    if (candidateIndex < 0 || candidateIndex >= lines.length) continue;

    final candidateLine = lines[candidateIndex];
    final lower = candidateLine.toLowerCase();
    if (const [
      'score',
      '스코어',
      'par',
      '파',
      'putt',
      '퍼트',
      'hole',
      'handicap',
      'hcp',
      'tee',
      'date',
      'attested',
      'approved',
    ].any(lower.contains)) {
      continue;
    }

    final numbers = _dropHoleLabels(_numbersInLine(candidateLine));
    final values = _extractScoreValues(numbers);
    if (values.length == 9 || values.length == 18) {
      return true;
    }
  }

  return false;
}

List<String> mergeCompanionNames(
  Iterable<String> prioritized,
  Iterable<String> fallback,
) {
  final merged = <String>[];
  final seen = <String>{};

  for (final name in [...prioritized, ...fallback]) {
    final normalized = normalizeNameCandidate(name);
    if (normalized == null || !seen.add(normalized)) continue;
    merged.add(name);
    if (merged.length >= 4) break;
  }

  return merged;
}

List<String> _tokenizeNameCandidates(String line) {
  if (RegExp(r'\d').hasMatch(line)) return const [];

  final compact = line
      .replaceAll(RegExp(r'[:|/\\,;]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (compact.isEmpty) return const [];

  final parts = compact.split(' ');
  if (parts.length > 1) {
    final initials = _tryJoinInitialSequence(parts);
    if (initials != null) {
      return [initials];
    }
    final koreanName = _tryJoinKoreanNameSequence(parts);
    if (koreanName != null) {
      return [koreanName];
    }
    final filtered = parts
        .map((part) => _sanitizeNameCandidate(part))
        .whereType<String>()
        .toList();
    if (filtered.length >= 2 && filtered.length <= 4) {
      return filtered;
    }
  }

  final single = _sanitizeNameCandidate(compact);
  return single == null ? const [] : [single];
}

String? _sanitizeNameCandidate(String raw) {
  final cleaned =
      raw.trim().replaceAll(RegExp(r'^[^A-Za-z가-힣]+|[^A-Za-z가-힣]+$'), '');
  final text = _stripKoreanHonorificSuffix(
    cleaned.replaceAll(RegExp(r"[.'`-]"), ''),
  );
  if (text.isEmpty) return null;
  if (text.length < 2 || text.length > 10) return null;

  final lower = text.toLowerCase();
  const blocked = {
    'score',
    'gross',
    'total',
    'out',
    'in',
    'par',
    'putt',
    'player',
    'name',
    'hole',
    'ocr',
    'course',
    'windy',
    'golf',
    'date',
    'tee',
    'off',
    'info',
    'sub',
    'tot',
    'front',
    'back',
    'nine',
    'attested',
    'approved',
    'dream',
    'park',
    'urban',
    'lake',
    'mountain',
    '동반자',
    '스코어',
    '타수',
    '퍼트',
    '합계',
    '골프',
    '코스',
    '이름',
    '성명',
    '플레이어',
    '드림',
    '파크',
    '어반',
    '레이크',
    '마운틴',
    '전반',
    '후반',
  };
  if (blocked.contains(lower) || blocked.contains(text)) return null;

  final isKorean = RegExp(r'^[가-힣]{2,5}$').hasMatch(text);
  final isEnglish = RegExp(r'^[A-Za-z]{2,10}$').hasMatch(text);
  if (!isKorean && !isEnglish) return null;
  return text;
}

String? _tryJoinInitialSequence(List<String> parts) {
  final letters = parts
      .map((part) => part.trim().replaceAll(RegExp(r'[^A-Za-z]'), ''))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (letters.length < 2 || letters.length > 4) return null;
  if (!letters.every((part) => part.length == 1)) return null;

  final joined = letters.join().toUpperCase();
  if (joined.length < 2 || joined.length > 4) return null;

  const blocked = {'IN', 'OUT', 'PAR', 'HCP'};
  if (blocked.contains(joined)) return null;
  return joined;
}

String? _tryJoinKoreanNameSequence(List<String> parts) {
  final syllables = parts
      .map((part) => part.trim().replaceAll(RegExp(r'[^가-힣]'), ''))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (syllables.length < 2 || syllables.length > 4) return null;
  if (!syllables.every((part) => part.isNotEmpty && part.length <= 2)) {
    return null;
  }

  final joined = syllables.join();
  if (joined.length < 2 || joined.length > 4) return null;
  if (syllables.every((part) => part == '합')) return null;

  return _sanitizeNameCandidate(joined);
}

String? _extractPrimaryNameFromLine(String line) {
  final withoutNumbers = line.replaceAll(RegExp(r'\d+'), ' ');
  final normalized = withoutNumbers
      .replaceAll(RegExp(r'[:|/\\\\,;]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (normalized.isEmpty) return null;

  final parts = normalized.split(' ');
  final initials = _tryJoinInitialSequence(parts);
  if (initials != null) return initials;
  final koreanName = _tryJoinKoreanNameSequence(parts);
  if (koreanName != null) return koreanName;

  final tokens = parts.map(_sanitizeNameCandidate).whereType<String>().toList();

  if (tokens.isEmpty) return null;
  if (tokens.length >= 2 && tokens.length <= 4) {
    return tokens.first;
  }
  return tokens.first;
}

String? _extractHeaderPlayerName(
  List<String> lines,
  List<_ScoreRowCandidate> scoreRows,
) {
  final scoreStartIndex = scoreRows.isEmpty
      ? lines.length
      : scoreRows
          .map((row) => row.lineIndex)
          .reduce((value, element) => value < element ? value : element);
  final headerLines = lines.take(scoreStartIndex.clamp(0, 12)).toList();

  for (final line in headerLines) {
    final lower = line.toLowerCase();
    if (!(lower.contains('name') ||
        lower.contains('player') ||
        line.contains('성명') ||
        line.contains('이름'))) {
      continue;
    }

    final tokens = _tokenizeNameCandidates(line);
    for (final token in tokens) {
      if (_sanitizeNameCandidate(token) != null) return token;
    }

    final inlineName = _extractPrimaryNameFromLine(line);
    if (inlineName != null) return inlineName;
  }

  for (final line in headerLines) {
    final lower = line.toLowerCase();
    if (_looksLikePromotionalLine(lower) ||
        lower.contains('date') ||
        lower.contains('tee off') ||
        _looksLikeScoreTableHeader(line) ||
        line.contains('티오프') ||
        line.contains('티 오프')) {
      continue;
    }

    final numbers = _numbersInLine(line);
    if (numbers.isEmpty || numbers.length > 3) continue;
    if (!numbers.any((value) => value >= 40 && value <= 150)) continue;

    final inlineName = _extractPrimaryNameFromLine(line);
    if (inlineName != null) return inlineName;
  }

  for (final line in headerLines) {
    if (_looksLikeScoreTableHeader(line)) continue;
    if (_looksLikeHeaderPlayerSummaryLine(line)) {
      final inlineName = _extractPrimaryNameFromLine(line);
      if (inlineName != null) return inlineName;
    }
  }

  return null;
}

String? normalizeNameCandidate(String value) {
  final text = _stripKoreanHonorificSuffix(
    value
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r"[.'`·\-_/()]"), '')
        .toUpperCase(),
  );
  if (text.isEmpty) return null;
  return text;
}

String _stripKoreanHonorificSuffix(String value) {
  if (value.length >= 3 && value.endsWith('님')) {
    return value.substring(0, value.length - 1);
  }
  return value;
}
