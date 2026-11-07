import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
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
    this.portalPlace,
  });

  final String title;
  final DateTime startAt;
  final String sourceText;
  final String? location;
  final String? description;
  final String? courseKeyword;
  final CourseSearchResult? matchedCourse;

  /// 코스 DB에 없을 때 포털(카카오 장소 검색)에서 찾은 골프장
  final PortalGolfPlace? portalPlace;

  String get displayCourseName =>
      matchedCourse?.name ??
      portalPlace?.name ??
      courseKeyword ??
      location ??
      title;

  String? get displayAddress {
    final trimmed = location?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      if (matchedCourse != null && trimmed == matchedCourse!.name) return null;
      return trimmed;
    }
    return portalPlace?.address;
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

  // CC/GC는 대문자 + 단어 경계 한정: soccer, account, "cc: 참조" 오탐 방지
  static final RegExp _golfKeywordPattern = RegExp(
    r'골프|라운드|라운딩|컨트리\s*클럽|골프\s*클럽|골프장|'
    r'(?<![A-Za-z])(?:CC|C\.C|GC|G\.C)(?![A-Za-z])',
  );

  static final RegExp _coursePattern = RegExp(
    r'([가-힣A-Za-z0-9\s·\.\-&]+?'
    r'(?:(?<![A-Za-z])CC(?![A-Za-z])|C\.C|(?<![A-Za-z])GC(?![A-Za-z])|G\.C|골프장|골프클럽|컨트리클럽|컨트리\s*클럽))',
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

        if (!looksLikeGolfEvent(sourceText)) continue;

        final uniqueKey = '${id ?? title}|${startAt.millisecondsSinceEpoch}';
        if (!seen.add(uniqueKey)) continue;

        rawCandidates.add(
          CalendarGolfImportCandidate(
            title: title.isEmpty ? L10n.current.calDefaultGolfTitle : title,
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
      // 코스 DB에 없으면 포털 장소 검색으로 이름·주소·좌표 보강
      final portalPlace =
          matchedCourse == null ? await _searchPortalPlace(candidate) : null;
      enriched.add(
        CalendarGolfImportCandidate(
          title: candidate.title,
          startAt: candidate.startAt,
          sourceText: candidate.sourceText,
          location: candidate.location,
          description: candidate.description,
          courseKeyword: candidate.courseKeyword,
          matchedCourse: matchedCourse,
          portalPlace: portalPlace,
        ),
      );
    }

    return CalendarGolfImportResult(
      permissionGranted: true,
      candidates: enriched,
    );
  }

  /// 골프 키워드 또는 골프장 접미 패턴이 실제로 있을 때만 골프 일정으로 분류.
  /// (_extractCourseKeyword의 임의 텍스트 폴백은 분류 기준으로 쓰지 않는다 —
  /// 쓰면 2~24자 제목의 모든 일정이 골프로 분류되는 오탐이 발생)
  @visibleForTesting
  bool looksLikeGolfEvent(String sourceText) {
    final normalized = sourceText.trim();
    if (normalized.isEmpty) return false;
    return _golfKeywordPattern.hasMatch(normalized) ||
        _coursePattern.hasMatch(normalized);
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

  Future<PortalGolfPlace?> _searchPortalPlace(
    CalendarGolfImportCandidate candidate,
  ) async {
    final queries = <String>[
      if (candidate.courseKeyword?.trim().isNotEmpty ?? false)
        candidate.courseKeyword!.trim(),
      if (candidate.location?.trim().isNotEmpty ?? false)
        candidate.location!.trim(),
    ];

    final seen = <String>{};
    for (final query in queries) {
      if (!seen.add(query)) continue;
      final place = await WeatherApiService.instance.searchPortalGolfPlace(
        query,
      );
      if (place != null) return place;
    }

    return null;
  }
}
