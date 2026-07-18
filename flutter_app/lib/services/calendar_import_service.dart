import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'weather_api_service.dart';

class CalendarGolfImportCandidate {
  const CalendarGolfImportCandidate({
    required this.title,
    required this.startAt,
    required this.sourceText,
    this.location,
    this.description,
    this.courseKeyword,
    this.matchedCourse,
  });

  final String title;
  final DateTime startAt;
  final String sourceText;
  final String? location;
  final String? description;
  final String? courseKeyword;
  final CourseSearchResult? matchedCourse;

  String get displayCourseName =>
      matchedCourse?.name ?? courseKeyword ?? location ?? title;

  String? get displayAddress {
    final trimmed = location?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    if (matchedCourse != null && trimmed == matchedCourse!.name) return null;
    return trimmed;
  }
}

class CalendarGolfImportResult {
  const CalendarGolfImportResult({
    required this.permissionGranted,
    required this.candidates,
  });

  final bool permissionGranted;
  final List<CalendarGolfImportCandidate> candidates;
}

class CalendarImportService {
  CalendarImportService._();
  static final instance = CalendarImportService._();

  static const MethodChannel _channel = MethodChannel('golf_windy/calendar');

  static final RegExp _golfKeywordPattern = RegExp(
    r'(골프|라운드|라운딩|컨트리\s*클럽|골프\s*클럽|골프장|CC|C\.C|GC|G\.C)',
    caseSensitive: false,
  );

  static final RegExp _coursePattern = RegExp(
    r'([가-힣A-Za-z0-9\s·\.\-&]+?(?:CC|C\.C|GC|G\.C|골프장|골프클럽|컨트리클럽|컨트리\s*클럽))',
    caseSensitive: false,
  );

  Future<CalendarGolfImportResult> findGolfEvents({
    DateTime? start,
    DateTime? end,
  }) async {
    final now = DateTime.now();
    final rangeStart = start ?? now.subtract(const Duration(days: 30));
    final rangeEnd = end ?? now.add(const Duration(days: 180));

    final nativeResult = await _channel.invokeMapMethod<String, dynamic>(
      'findGolfEvents',
      {
        'startMillis': rangeStart.millisecondsSinceEpoch,
        'endMillis': rangeEnd.millisecondsSinceEpoch,
      },
    );

    if (nativeResult?['permissionGranted'] != true) {
      return const CalendarGolfImportResult(
        permissionGranted: false,
        candidates: [],
      );
    }

    final rawCandidates = <CalendarGolfImportCandidate>[];
    final seen = <String>{};
    final events = (nativeResult?['events'] as List<dynamic>? ?? const []);

    for (final event in events) {
      if (event is! Map) continue;

      try {
        final id = event['id']?.toString();
        final startMillis = event['startMillis'];
        if (startMillis is! int) continue;

        final startAt = DateTime.fromMillisecondsSinceEpoch(
          startMillis,
          isUtc: false,
        ).toLocal();
        final title = (event['title']?.toString() ?? '').trim();
        final location = (event['location']?.toString() ?? '').trim();
        final description = (event['description']?.toString() ?? '').trim();
        final sourceText = [title, location, description]
            .where((value) => value.trim().isNotEmpty)
            .join('\n');

        if (!_looksLikeGolfEvent(sourceText)) continue;

        final uniqueKey = '${id ?? title}|${startAt.millisecondsSinceEpoch}';
        if (!seen.add(uniqueKey)) continue;

        rawCandidates.add(
          CalendarGolfImportCandidate(
            title: title.isEmpty ? '골프 일정' : title,
            startAt: startAt,
            location: location.isEmpty ? null : location,
            description: description.isEmpty ? null : description,
            sourceText: sourceText,
            courseKeyword: _extractCourseKeyword(sourceText),
          ),
        );
      } catch (e) {
        debugPrint('Calendar event parse failed: $e');
      }
    }

    rawCandidates.sort((a, b) => a.startAt.compareTo(b.startAt));
    final enriched = <CalendarGolfImportCandidate>[];

    for (final candidate in rawCandidates.take(20)) {
      final matchedCourse = await _matchCourse(candidate);
      enriched.add(
        CalendarGolfImportCandidate(
          title: candidate.title,
          startAt: candidate.startAt,
          sourceText: candidate.sourceText,
          location: candidate.location,
          description: candidate.description,
          courseKeyword: candidate.courseKeyword,
          matchedCourse: matchedCourse,
        ),
      );
    }

    return CalendarGolfImportResult(
      permissionGranted: true,
      candidates: enriched,
    );
  }

  bool _looksLikeGolfEvent(String sourceText) {
    final normalized = sourceText.trim();
    if (normalized.isEmpty) return false;
    return _golfKeywordPattern.hasMatch(normalized) ||
        _extractCourseKeyword(normalized) != null;
  }

  String? _extractCourseKeyword(String sourceText) {
    final normalized = sourceText
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('라운딩', ' ')
        .replaceAll('라운드', ' ')
        .trim();

    final match = _coursePattern.firstMatch(normalized);
    if (match != null) {
      return _cleanKeyword(match.group(1));
    }

    final lines = sourceText
        .split(RegExp(r'[\n,/]'))
        .map((line) => _cleanKeyword(line))
        .whereType<String>();
    for (final line in lines) {
      if (line.length >= 2 && line.length <= 24) return line;
    }

    return null;
  }

  String? _cleanKeyword(String? value) {
    if (value == null) return null;
    final cleaned = value
        .replaceAll(RegExp(r'\b(AM|PM)\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\d{1,4}[./-]\d{1,2}[./-]\d{1,2}'), ' ')
        .replaceAll(RegExp(r'\d{1,2}:\d{2}'), ' ')
        .replaceAll(RegExp(r'(골프|라운드|라운딩)\s*일정'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return null;
    return cleaned;
  }

  Future<CourseSearchResult?> _matchCourse(
    CalendarGolfImportCandidate candidate,
  ) async {
    final queries = <String>[
      if (candidate.courseKeyword?.trim().isNotEmpty ?? false)
        candidate.courseKeyword!.trim(),
      if (candidate.location?.trim().isNotEmpty ?? false)
        candidate.location!.trim(),
      candidate.title.trim(),
    ];

    final seen = <String>{};
    for (final query in queries) {
      if (!seen.add(query)) continue;
      final course = await WeatherApiService.instance.searchCourse(query);
      if (course != null) return course;
    }

    return null;
  }
}
