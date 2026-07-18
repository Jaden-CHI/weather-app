import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/golf_event.dart';
import '../services/app_schedule_service.dart';
import '../services/restaurant_service.dart';
import '../services/scorecard_service.dart';
import '../services/weather_api_service.dart';
import 'score_history_screen.dart';

class ReleaseQaScreen extends StatefulWidget {
  const ReleaseQaScreen({super.key});

  @override
  State<ReleaseQaScreen> createState() => _ReleaseQaScreenState();
}

class _ReleaseQaScreenState extends State<ReleaseQaScreen> {
  final _scheduleService = AppScheduleService();
  final _weatherApi = WeatherApiService.instance;
  final _restaurantService = RestaurantService();

  bool _running = true;
  List<_QaItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _runChecks();
  }

  Future<void> _runChecks() async {
    setState(() {
      _running = true;
      _items = const [];
    });

    final items = <_QaItem>[];
    GolfEvent? targetEvent;
    CourseSearchResult? matchedCourse;

    try {
      final schedules = await _scheduleService.getUpcomingGolfSchedules();
      targetEvent = schedules.isNotEmpty ? schedules.first : null;
      items.add(
        _QaItem(
          title: '일정',
          status: schedules.isNotEmpty ? _QaStatus.pass : _QaStatus.warn,
          detail: schedules.isNotEmpty
              ? '예정 일정 ${schedules.length}개 · ${targetEvent!.courseName ?? targetEvent.title}'
              : '예정 일정이 없습니다. 일정 추가 후 다시 확인해 주세요.',
        ),
      );
    } catch (e) {
      items.add(_QaItem.fail('일정', '일정 로드 실패: $e'));
    }

    if (targetEvent != null) {
      try {
        matchedCourse = await _weatherApi.searchCourse(
          targetEvent.courseName ?? targetEvent.location ?? targetEvent.title,
        );
        items.add(
          _QaItem(
            title: '골프장 매칭',
            status: matchedCourse != null ? _QaStatus.pass : _QaStatus.warn,
            detail: matchedCourse != null
                ? '${matchedCourse.name} · ${matchedCourse.courseId}'
                : 'DB 매칭 없음. 골프장명 수정 또는 좌표 보정이 필요할 수 있습니다.',
          ),
        );
      } catch (e) {
        items.add(_QaItem.fail('골프장 매칭', '검색 실패: $e'));
      }

      try {
        final courseId = targetEvent.courseId ?? matchedCourse?.courseId;
        final status = courseId == null
            ? null
            : await _weatherApi.getWeatherCacheStatus(courseId);
        items.add(
          _QaItem(
            title: '날씨 캐시',
            status: status == null
                ? _QaStatus.warn
                : status.cached
                    ? _QaStatus.pass
                    : _QaStatus.warn,
            detail: status == null
                ? '코스 ID가 없거나 캐시 상태를 확인하지 못했습니다.'
                : status.cached
                    ? '${status.courseName} · ${status.effectiveSource ?? status.source ?? 'source 없음'} · ${status.lastUpdated ?? '시간 없음'}'
                    : '${status.courseName} · grid ${status.gridX},${status.gridY} 캐시 없음',
          ),
        );
      } catch (e) {
        items.add(_QaItem.fail('날씨 캐시', '상태 확인 실패: $e'));
      }

      try {
        final location = await _weatherApi.resolveTrustedCourseLocation(
          courseName: targetEvent.courseName ?? targetEvent.title,
          address: targetEvent.address,
          currentLat: targetEvent.lat,
          currentLng: targetEvent.lng,
        );
        items.add(
          _QaItem(
            title: '지도 좌표',
            status: location != null ? _QaStatus.pass : _QaStatus.warn,
            detail: location != null
                ? '${location.lat.toStringAsFixed(5)}, ${location.lng.toStringAsFixed(5)}'
                : '지도 좌표를 확인하지 못했습니다.',
          ),
        );

        if (location != null) {
          final restaurants = await _restaurantService.searchRestaurants(
            lat: location.lat,
            lng: location.lng,
            category: '조식',
            courseAddress: location.address ?? targetEvent.address,
          );
          items.add(
            _QaItem(
              title: '식당 추천',
              status: restaurants.restaurants.isNotEmpty
                  ? _QaStatus.pass
                  : _QaStatus.warn,
              detail: restaurants.restaurants.isNotEmpty
                  ? '근처 식당 ${restaurants.restaurants.length}개 확인'
                  : restaurants.errorMessage ?? '근처 식당 결과가 없습니다.',
            ),
          );
        }
      } catch (e) {
        items.add(_QaItem.fail('지도/식당', '좌표 또는 식당 확인 실패: $e'));
      }
    }

    try {
      final scores = await ScorecardService.instance.getAllScores();
      items.add(
        _QaItem(
          title: 'OCR/스코어',
          status: _QaStatus.pass,
          detail: scores.isEmpty
              ? '저장된 스코어는 아직 없습니다. 스코어 관리에서 OCR을 실행해 보세요.'
              : '저장 스코어 ${scores.length}개 · 최근 ${scores.first.courseName}',
        ),
      );
    } catch (e) {
      items.add(_QaItem.fail('OCR/스코어', '스코어 로드 실패: $e'));
    }

    if (!mounted) return;
    setState(() {
      _items = items;
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: t.fg,
        title: const Text('출시 전 QA 체크'),
        actions: [
          IconButton(
            tooltip: '다시 확인',
            onPressed: _running ? null : _runChecks,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _QaIntroCard(running: _running),
          const SizedBox(height: 14),
          if (_running)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: CircularProgressIndicator(color: t.accent),
              ),
            )
          else
            ..._items.map(_QaResultTile.new),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScoreHistoryScreen()),
              );
            },
            icon: const Icon(Icons.document_scanner_outlined),
            label: const Text('OCR/스코어 화면 열기'),
            style: OutlinedButton.styleFrom(
              foregroundColor: t.fg,
              side: BorderSide(color: t.line),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _QaIntroCard extends StatelessWidget {
  final bool running;

  const _QaIntroCard({required this.running});

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.cardBorder),
      ),
      child: Text(
        running
            ? '지도, OCR, 일정, 날씨, 식당 추천 상태를 확인하는 중입니다.'
            : '예정된 첫 골프 일정을 기준으로 출시 전 핵심 흐름을 빠르게 점검했습니다.',
        style: TextStyle(
          color: t.fg2,
          fontSize: 13,
          height: 1.45,
        ),
      ),
    );
  }
}

class _QaResultTile extends StatelessWidget {
  final _QaItem item;

  const _QaResultTile(this.item);

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final color = switch (item.status) {
      _QaStatus.pass => t.success,
      _QaStatus.warn => t.warn,
      _QaStatus.fail => t.danger,
    };
    final icon = switch (item.status) {
      _QaStatus.pass => Icons.check_circle_outline,
      _QaStatus.warn => Icons.info_outline,
      _QaStatus.fail => Icons.error_outline,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: t.fg,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.detail,
                  style: TextStyle(
                    color: t.fg2,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _QaStatus { pass, warn, fail }

class _QaItem {
  final String title;
  final _QaStatus status;
  final String detail;

  const _QaItem({
    required this.title,
    required this.status,
    required this.detail,
  });

  factory _QaItem.fail(String title, String detail) => _QaItem(
        title: title,
        status: _QaStatus.fail,
        detail: detail,
      );
}
