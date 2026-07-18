import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../utils/map_html.dart';
import '../models/golf_event.dart';
import '../models/restaurant.dart';
import '../models/weather_data.dart';
import '../services/app_schedule_service.dart';
import '../services/restaurant_service.dart';
import '../services/weather_api_service.dart';
import '../services/background_service.dart';
import '../services/settings_service.dart';
import '../services/widget_sync_service.dart';
import '../widgets/wx_icon.dart';
import 'event_detail_screen.dart';
import 'settings_screen.dart';
import 'add_schedule_screen.dart';

// ── 상태 헬퍼 ──────────────────────────────────────────────────
class _Status {
  final Color color, bg, border;
  final String label;
  const _Status(
      {required this.color,
      required this.bg,
      required this.border,
      required this.label});
}

_Status _statusOf(GwTheme t, String s) => switch (s) {
      'GREEN' => _Status(
          color: t.success,
          bg: t.successBg,
          border: t.successBorder,
          label: '최적'),
      'YELLOW' => _Status(
          color: t.warn, bg: t.warnBg, border: t.warnBorder, label: '주의'),
      'RED' => _Status(
          color: t.danger,
          bg: t.dangerBg,
          border: t.dangerBorder,
          label: '취소권장'),
      _ => _Status(color: t.fg3, bg: t.line, border: t.line, label: '정보없음'),
    };

// ── 일정별 날씨 로딩 (히어로/리스트 공용) ──────────────────────
Future<GolfWeatherData?> _loadEventWeather(GolfEvent original) async {
  final api = WeatherApiService.instance;
  var event = original;
  var courseId = event.courseId;
  courseId ??= await api.searchCourseId(
    event.courseName ?? event.title,
  );

  if (courseId != null && courseId.isNotEmpty) {
    return api.getGolfWeather(
      courseId,
      dday: event.dday.clamp(0, 7),
      startHour: event.startDate.hour,
    );
  }

  double? lat = event.lat;
  double? lng = event.lng;
  if (lat == null || lng == null) {
    final geocoded = await api.geocodeBestEffort(
      courseName: event.courseName ?? event.location ?? event.title,
      address: event.address,
    );
    lat = geocoded?.lat;
    lng = geocoded?.lng;
    if (lat != null && lng != null) {
      event = event.copyWith(lat: lat, lng: lng);
      await AppScheduleService().updateSchedule(event.id, {
        'lat': lat,
        'lng': lng,
      });
    }
  }
  if (lat == null || lng == null) return null;
  return api.getCustomGolfWeather(
    lat: lat,
    lng: lng,
    courseName: event.courseName ?? event.location ?? event.title,
    dday: event.dday.clamp(0, 7),
    startHour: event.startDate.hour,
  );
}

/// 체감온도 근사치 (풍속 기반 wind chill, 저온에서만 보정)
double _feelsLike(double temp, double windSpeed) {
  if (temp <= 10 && windSpeed >= 1.4) {
    final v = math.pow(windSpeed * 3.6, 0.16).toDouble();
    return 13.12 + 0.6215 * temp - 11.37 * v + 0.3965 * temp * v;
  }
  return temp;
}

// ── 프로바이더 ─────────────────────────────────────────────────
final golfEventsProvider = FutureProvider<List<GolfEvent>>((ref) async {
  return AppScheduleService().getUpcomingGolfSchedules();
});

// ═══════════════════════════════════════════════════════════════
// 홈 화면
// ═══════════════════════════════════════════════════════════════
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIdx = 0; // 하단 탭
  bool _tutorialCheckStarted = false;
  bool _showingTutorial = false;

  @override
  void initState() {
    super.initState();
    BackgroundService.runOnce();
    WidgetSyncService.instance.syncNextGolfEvent();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowTutorial();
    });
  }

  Future<void> _maybeShowTutorial() async {
    if (!mounted || _tutorialCheckStarted) return;
    _tutorialCheckStarted = true;
    final seen = await SettingsService.instance.hasSeenHomeTutorial();
    if (!mounted || seen) return;
    await _showTutorial(markSeen: true);
  }

  Future<void> _showTutorial({bool markSeen = false}) async {
    if (!mounted || _showingTutorial) return;
    _showingTutorial = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _AppTutorialDialog(),
      );
      if (markSeen) {
        await SettingsService.instance.setHomeTutorialSeen(true);
      }
    } finally {
      _showingTutorial = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        bottom: false,
        child: _navIdx == 0
            ? _GolfTab(ref: ref)
            : _navIdx == 1
                ? const _ScheduleScreen()
                : _navIdx == 2
                    ? const _MapScreen()
                    : SettingsScreen(
                        onOpenTutorial: () {
                          _showTutorial();
                        },
                      ),
      ),
      bottomNavigationBar: _BottomBar(
        active: _navIdx,
        onChanged: (i) => setState(() => _navIdx = i),
      ),
      floatingActionButton: _navIdx == 1
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const AddScheduleScreen()),
                );
                if (result == true && mounted) {
                  ref.invalidate(golfEventsProvider);
                }
              },
              backgroundColor: t.accent,
              foregroundColor: t.accentInk,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _TutorialStepData {
  final IconData icon;
  final String title;
  final String description;
  final List<String> bullets;

  const _TutorialStepData({
    required this.icon,
    required this.title,
    required this.description,
    required this.bullets,
  });
}

class _AppTutorialDialog extends StatefulWidget {
  const _AppTutorialDialog();

  @override
  State<_AppTutorialDialog> createState() => _AppTutorialDialogState();
}

class _AppTutorialDialogState extends State<_AppTutorialDialog> {
  static const _steps = [
    _TutorialStepData(
      icon: Icons.home_outlined,
      title: '홈에서 바로 확인',
      description: '다가오는 라운드와 날씨 권고를 첫 화면에서 바로 볼 수 있어요.',
      bullets: [
        'GREEN / YELLOW / RED 권고를 빠르게 확인',
        '아래로 당겨 최신 예보 다시 불러오기',
      ],
    ),
    _TutorialStepData(
      icon: Icons.calendar_today_outlined,
      title: '일정 등록은 간단하게',
      description: '일정 탭에서 골프장을 선택하고 티오프 시간을 저장하면 준비가 끝납니다.',
      bullets: [
        '골프장 검색 후 일정 생성',
        '일정 상세에서 날씨와 스코어카드 연결',
      ],
    ),
    _TutorialStepData(
      icon: Icons.map_outlined,
      title: '지도와 맛집 확인',
      description: '지도 탭에서 선택한 골프장 위치와 근처 식당을 함께 확인할 수 있어요.',
      bullets: [
        '네이버 지도에서 골프장 위치 확인',
        '조식/중식 추천 위치를 주변 기준으로 탐색',
      ],
    ),
    _TutorialStepData(
      icon: Icons.document_scanner_outlined,
      title: 'OCR로 지난 라운드도 저장',
      description: '스코어 관리에서 사진만 선택하면 지난 라운드 기록을 빠르게 남길 수 있어요.',
      bullets: [
        '일정 상세 또는 스코어 관리에서 OCR 시작',
        '설정에서 언제든 튜토리얼 다시 보기 가능',
      ],
    ),
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _steps.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_isLastPage) {
      Navigator.of(context).pop();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: t.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: t.accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.waving_hand_rounded,
                    color: t.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Golf Windy 빠른 안내',
                        style: TextStyle(
                          color: t.fg,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '핵심 기능만 짧게 보고 바로 시작할게요.',
                        style: TextStyle(
                          color: t.fg3,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('건너뛰기', style: TextStyle(color: t.fg2)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 330,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return _TutorialStepCard(
                    step: step,
                    pageIndex: index,
                    pageCount: _steps.length,
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                ...List.generate(_steps.length, (index) {
                  final selected = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: selected ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: selected ? t.accent : t.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
                const Spacer(),
                if (_currentPage > 0)
                  TextButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      );
                    },
                    child: Text('이전', style: TextStyle(color: t.fg2)),
                  ),
                const SizedBox(width: 6),
                FilledButton(
                  onPressed: _goNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: t.accent,
                    foregroundColor: t.accentInk,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  child: Text(_isLastPage ? '시작하기' : '다음'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialStepCard extends StatelessWidget {
  final _TutorialStepData step;
  final int pageIndex;
  final int pageCount;

  const _TutorialStepCard({
    required this.step,
    required this.pageIndex,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: t.surface2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: t.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: t.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: t.accent.withValues(alpha: 0.35)),
                ),
                child: Icon(step.icon, color: t.accent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP ${pageIndex + 1} / $pageCount',
                      style: TextStyle(
                        color: t.fg3,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.title,
                      style: TextStyle(
                        color: t.fg,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          step.description,
          style: TextStyle(
            color: t.fg2,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        ...step.bullets.map(
          (bullet) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Icon(
                    Icons.check_circle,
                    color: t.accent,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bullet,
                    style: TextStyle(
                      color: t.fg,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.line,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '튜토리얼은 설정 탭에서 언제든 다시 볼 수 있어요.',
            style: TextStyle(
              color: t.fg2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 하단 탭 바 ─────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int active;
  final ValueChanged<int> onChanged;
  const _BottomBar({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.surface2,
        border: Border(top: BorderSide(color: t.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _NavItem(
                  idx: 0,
                  icon: Icons.home_outlined,
                  label: '홈',
                  active: active,
                  onTap: onChanged),
              _NavItem(
                  idx: 1,
                  icon: Icons.calendar_today_outlined,
                  label: '일정',
                  active: active,
                  onTap: onChanged),
              _NavItem(
                  idx: 2,
                  icon: Icons.map_outlined,
                  label: '지도',
                  active: active,
                  onTap: onChanged),
              _NavItem(
                  idx: 3,
                  icon: Icons.tune,
                  label: '설정',
                  active: active,
                  onTap: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int idx, active;
  final IconData icon;
  final String label;
  final ValueChanged<int> onTap;
  const _NavItem(
      {required this.idx,
      required this.active,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final on = idx == active;
    final color = on ? t.accent : t.fg3;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(idx),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 홈 탭
// ═══════════════════════════════════════════════════════════════
class _GolfTab extends StatelessWidget {
  final WidgetRef ref;
  const _GolfTab({required this.ref});

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final async = ref.watch(golfEventsProvider);
    return async.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: t.accent)),
      error: (e, _) => _ErrorView('캘린더 오류: $e'),
      data: (events) {
        if (events.isEmpty) {
          return const _EmptyView(
            icon: Icons.flag_outlined,
            activity: '골프',
          );
        }
        return RefreshIndicator(
          color: t.accent,
          backgroundColor: t.surface,
          onRefresh: () async => ref.invalidate(golfEventsProvider),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              _HomeHero(event: events.first),
              if (events.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel('다가오는 라운드 · ${events.length - 1}'),
                      const SizedBox(height: 11),
                      ...events.skip(1).map((e) => _GolfRowCard(event: e)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── 홈 히어로 (다음 라운드 + 대형 온도 + 티오프 예보) ─────────
class _HomeHero extends StatefulWidget {
  final GolfEvent event;
  const _HomeHero({required this.event});
  @override
  State<_HomeHero> createState() => _HomeHeroState();
}

class _HomeHeroState extends State<_HomeHero> {
  GolfWeatherData? _wx;
  bool _weatherResolved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _loadEventWeather(widget.event);
      if (mounted) {
        setState(() {
          _wx = data;
          _weatherResolved = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _weatherResolved = true);
    }
  }

  /// 티오프 시간과 가장 가까운 예보 항목
  ForecastItem? get _teeOffItem {
    final forecast = _wx?.forecast ?? const <ForecastItem>[];
    if (forecast.isEmpty) return null;
    final teeHour = widget.event.startDate.hour;
    ForecastItem best = forecast.first;
    var bestDiff = 999;
    for (final f in forecast) {
      final h = int.tryParse(
              f.time.length >= 2 ? f.time.substring(0, 2) : '') ??
          -99;
      final diff = (h - teeHour).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = f;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final e = widget.event;
    final status = _wx?.aiRecommendation.status ?? 'NONE';
    final tee = _teeOffItem;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => EventDetailScreen(golfEvent: e))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 그라데이션 히어로
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(26, 18, 26, 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [t.gradTop, t.bg],
                stops: const [0, 0.88],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.dday == 0
                                ? '다음 라운드 · D-DAY'
                                : '다음 라운드 · D-${e.dday}',
                            style: TextStyle(
                              color: t.accent,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            e.courseName ?? e.title,
                            style: TextStyle(
                              color: t.fg,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${e.formattedDate} ${e.formattedTime} 티오프',
                            style: TextStyle(color: t.fg2, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (tee != null)
                      WxIcon.forecast(
                        sky: tee.sky,
                        rainProb: tee.rainProb,
                        size: 50,
                        color: t.accent,
                        strokeWidth: 1.4,
                      ),
                  ],
                ),
                if (tee != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${tee.temp.round()}°',
                    style: TextStyle(
                      color: t.fg,
                      fontSize: 88,
                      fontWeight: FontWeight.w500,
                      fontFamily: GwTheme.numFont,
                      height: 0.92,
                      letterSpacing: -3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      text: tee.weatherLabel,
                      style: TextStyle(
                        color: t.fg,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                      children: [
                        TextSpan(
                          text:
                              ' · 체감 ${_feelsLike(tee.temp, tee.windSpeed).round()}°',
                          style: TextStyle(
                            color: t.fg2,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_wx != null && _wx!.forecast.isNotEmpty) ...[
                  const _SectionLabel('티오프 시간대 예보'),
                  const SizedBox(height: 11),
                  _TeeOffStrip(
                    forecast: _wx!.forecast,
                    teeHour: e.startDate.hour,
                  ),
                  if (status == 'RED' || status == 'YELLOW') ...[
                    const SizedBox(height: 16),
                    _AlertBanner(status: status, rec: _wx!.aiRecommendation),
                  ],
                  const SizedBox(height: 16),
                  if (tee != null) _StatRow(tee: tee),
                ] else ...[
                  const SizedBox(height: 8),
                  _weatherResolved
                      ? const _WxUnavailable()
                      : const _WxLoading(),
                ],
                if (_wx != null && status == 'GREEN') ...[
                  const SizedBox(height: 16),
                  _AiChip(rec: _wx!.aiRecommendation),
                ],
                // 상태 필 (참고용, 정보 없음 제외)
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 티오프 시간대 예보 스트립 ─────────────────────────────────
class _TeeOffStrip extends StatelessWidget {
  final List<ForecastItem> forecast;
  final int teeHour;
  const _TeeOffStrip({required this.forecast, required this.teeHour});

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);

    int hourOf(ForecastItem f) =>
        int.tryParse(f.time.length >= 2 ? f.time.substring(0, 2) : '') ?? -99;

    // 티오프와 가장 가까운 항목 중심으로 최대 5칸
    var teeIdx = 0;
    var bestDiff = 999;
    for (var i = 0; i < forecast.length; i++) {
      final diff = (hourOf(forecast[i]) - teeHour).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        teeIdx = i;
      }
    }
    final count = math.min(5, forecast.length);
    var start = teeIdx - 2;
    start = start.clamp(0, forecast.length - count);
    final items = forecast.sublist(start, start + count);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.cardBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          for (final f in items)
            Expanded(
              flex: identical(f, forecast[teeIdx]) ? 115 : 100,
              child: identical(f, forecast[teeIdx])
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: t.accent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text('T-OFF',
                              style: TextStyle(
                                  color: t.accentInk,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 5),
                          Text('${f.temp.round()}°',
                              style: TextStyle(
                                  color: t.accentInk,
                                  fontSize: 15,
                                  fontFamily: GwTheme.numFont,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text('${f.rainProb}%',
                              style: TextStyle(
                                  color: t.accentInk,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Text(f.timeLabel,
                            style: TextStyle(color: t.fg2, fontSize: 12)),
                        const SizedBox(height: 8),
                        Text('${f.temp.round()}°',
                            style: TextStyle(
                                color: t.fg,
                                fontSize: 15,
                                fontFamily: GwTheme.numFont,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 3),
                        Text('${f.rainProb}%',
                            style: TextStyle(color: t.sky, fontSize: 11)),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}

// ── 악천후 배너 ────────────────────────────────────────────────
class _AlertBanner extends StatelessWidget {
  final String status;
  final AiRecommendation rec;
  const _AlertBanner({required this.status, required this.rec});

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final danger = status == 'RED';
    final color = danger ? t.danger : t.warn;
    final bg = danger ? t.dangerBg : t.warnBg;
    final border = danger ? t.dangerBorder : t.warnBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          WxIcon(
            variant: WxIconVariant.cloudRain,
            size: 26,
            color: color,
            strokeWidth: 1.8,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  danger ? '악천후 — 취소 권고' : '기상 주의',
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rec.message,
                  style: TextStyle(color: t.fg2, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 체감/강수/바람 3분할 카드 ─────────────────────────────────
class _StatRow extends StatelessWidget {
  final ForecastItem tee;
  const _StatRow({required this.tee});

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    Widget cell(String label, String value, Color valueColor) => Expanded(
          child: Column(
            children: [
              Text(label, style: TextStyle(color: t.fg3, fontSize: 11.5)),
              const SizedBox(height: 5),
              Text(value,
                  style: TextStyle(
                      color: valueColor,
                      fontSize: 22,
                      fontFamily: GwTheme.numFont,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.cardBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          cell('체감온도', '${_feelsLike(tee.temp, tee.windSpeed).round()}°',
              t.fg),
          Container(width: 1, height: 40, color: t.line),
          cell('강수확률', '${tee.rainProb}%', t.sky),
          Container(width: 1, height: 40, color: t.line),
          cell('바람', tee.windSpeed.toStringAsFixed(1), t.warn),
        ],
      ),
    );
  }
}

class _AiChip extends StatelessWidget {
  final AiRecommendation rec;
  const _AiChip({required this.rec});

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final s = _statusOf(t, rec.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: s.border),
      ),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: s.color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI 추천 · ${s.label}',
                    style: TextStyle(
                        color: s.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(rec.message,
                    style: TextStyle(
                        color: t.fg2,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WxLoading extends StatelessWidget {
  const _WxLoading();
  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Container(
      height: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.cardBorder),
      ),
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(color: t.accent, strokeWidth: 2),
      ),
    );
  }
}

class _WxUnavailable extends StatelessWidget {
  const _WxUnavailable();

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.cardBorder),
      ),
      child: Text(
        '날씨 정보 준비 중 · 골프장명/좌표 확인 필요',
        style: TextStyle(
          color: t.fg3,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── 골프 리스트 카드 ───────────────────────────────────────────
class _GolfRowCard extends StatefulWidget {
  final GolfEvent event;
  final VoidCallback? onDelete;
  const _GolfRowCard({required this.event, this.onDelete});
  @override
  State<_GolfRowCard> createState() => _GolfRowCardState();
}

class _GolfRowCardState extends State<_GolfRowCard> {
  GolfWeatherData? _wx;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _loadEventWeather(widget.event);
      if (mounted) setState(() => _wx = data);
    } catch (_) {
      // 백엔드 미연결 시 카드는 일정 정보만 표시
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final e = widget.event;
    final status = _wx?.aiRecommendation.status ?? 'NONE';
    final s = _statusOf(t, status);

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => EventDetailScreen(golfEvent: e))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.cardBorder),
        ),
        child: Row(
          children: [
            _DdayBadge(dday: e.dday),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.courseName ?? e.title,
                      style: TextStyle(
                          color: t.fg,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                      '${e.formattedDate.split(' ').take(2).join(' ')} · ${e.formattedTime}',
                      style: TextStyle(color: t.fg3, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (_wx != null && _wx!.forecast.isNotEmpty) ...[
              Text('${_wx!.forecast.first.temp.round()}°',
                  style: TextStyle(
                      color: t.fg,
                      fontSize: 20,
                      fontFamily: GwTheme.numFont,
                      fontWeight: FontWeight.w500)),
              const SizedBox(width: 12),
            ],
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: s.color,
                shape: BoxShape.circle,
              ),
            ),
            if (widget.onDelete != null) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: '일정 삭제',
                icon: Icon(Icons.delete_outline, color: t.fg3),
                onPressed: widget.onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 공통 원자 위젯 ──────────────────────────────────────────────
class _DdayBadge extends StatelessWidget {
  final int dday;
  const _DdayBadge({required this.dday});

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final isToday = dday == 0;
    final label =
        isToday ? 'D-DAY' : (dday > 0 ? 'D-$dday' : 'D+${dday.abs()}');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isToday ? t.accent : t.surface2,
        border: Border.all(color: isToday ? t.accent : t.line),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(label,
          style: TextStyle(
            color: isToday ? t.accentInk : t.fg2,
            fontWeight: FontWeight.w500,
            fontFamily: GwTheme.numFont,
            fontSize: 12.5,
            letterSpacing: 0.3,
          )),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final s = _statusOf(t, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: s.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: s.color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(s.label,
              style: TextStyle(
                  color: s.color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Text(text,
        style: TextStyle(
            color: t.fg3,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2));
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String activity;
  const _EmptyView({required this.icon, required this.activity});
  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: t.cardBorder),
              ),
              child: Icon(icon, color: t.fg2, size: 34),
            ),
            const SizedBox(height: 16),
            Text('등록된 $activity 일정이 없습니다',
                style: TextStyle(
                    color: t.fg, fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('캘린더에 $activity 일정을 추가하면\n자동으로 날씨를 확인해드립니다',
                style: TextStyle(color: t.fg3, fontSize: 14),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String msg;
  const _ErrorView(this.msg);
  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Center(child: Text(msg, style: TextStyle(color: t.danger)));
  }
}

// ═══════════════════════════════════════════════════════════════
// 일정 화면
// ═══════════════════════════════════════════════════════════════
class _ScheduleScreen extends ConsumerWidget {
  const _ScheduleScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
          child: Row(
            children: [
              Expanded(
                child: Text('일정',
                    style: TextStyle(
                        color: t.fg,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4)),
              ),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddScheduleScreen(
                        autoImportFromCalendar: true,
                      ),
                    ),
                  );
                  if (result == true) {
                    ref.invalidate(golfEventsProvider);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: t.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_available_outlined,
                          color: t.accent, size: 16),
                      const SizedBox(width: 6),
                      Text('캘린더 가져오기',
                          style: TextStyle(
                              color: t.fg2,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Expanded(
          child: _AllScheduleList(),
        ),
      ],
    );
  }
}

// ── 다음 라운드 카드 (일정 탭 상단) ────────────────────────────
class _NextRoundCard extends StatefulWidget {
  final GolfEvent event;
  const _NextRoundCard({required this.event});
  @override
  State<_NextRoundCard> createState() => _NextRoundCardState();
}

class _NextRoundCardState extends State<_NextRoundCard> {
  GolfWeatherData? _wx;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _loadEventWeather(widget.event);
      if (mounted) setState(() => _wx = data);
    } catch (_) {
      // 날씨 미확보 시 일정 정보만 표시
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final e = widget.event;
    final status = _wx?.aiRecommendation.status ?? 'NONE';
    final f = (_wx?.forecast.isNotEmpty ?? false) ? _wx!.forecast.first : null;

    final sub = [
      '${e.formattedDate} ${e.formattedTime} 티오프',
      if (f != null) '${f.weatherLabel} ${f.temp.round()}°',
      if (f != null) '강수 ${f.rainProb}%',
    ].join(' · ');

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => EventDetailScreen(golfEvent: e))),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: t.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('다음 라운드',
                    style: TextStyle(
                        color: t.fg3,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4)),
                if (status != 'NONE') _StatusPill(status: status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  e.dday == 0 ? 'D-DAY' : 'D-${e.dday}',
                  style: TextStyle(
                      color: t.accent,
                      fontSize: 15,
                      fontFamily: GwTheme.numFont,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(e.courseName ?? e.title,
                      style: TextStyle(
                          color: t.fg,
                          fontSize: 22,
                          fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(sub, style: TextStyle(color: t.fg2, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _AllScheduleList extends ConsumerWidget {
  const _AllScheduleList();

  Future<void> _deleteSchedule(
    BuildContext context,
    WidgetRef ref,
    GolfEvent event,
  ) async {
    try {
      await AppScheduleService().deleteSchedule(event.id);
      ref.invalidate(golfEventsProvider);
      await WidgetSyncService.instance.syncNextGolfEvent();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정을 삭제했습니다.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일정을 삭제하지 못했습니다: $e')),
      );
    }
  }

  Future<bool> _confirmDelete(BuildContext context, GolfEvent event) async {
    final t = GwTheme.of(context);
    final courseName = event.courseName ?? event.title;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: t.surface,
        title: Text('일정 삭제', style: TextStyle(color: t.fg)),
        content: Text(
          '$courseName 일정을 삭제할까요?',
          style: TextStyle(color: t.fg2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: t.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Widget _dismissible(
    BuildContext context,
    WidgetRef ref,
    GolfEvent event,
    Widget child,
  ) {
    final t = GwTheme.of(context);
    return Dismissible(
      key: ValueKey('schedule-${event.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await _confirmDelete(context, event);
        if (confirmed && context.mounted) {
          await _deleteSchedule(context, ref, event);
        }
        return confirmed;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: t.dangerBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.dangerBorder),
        ),
        child: Icon(Icons.delete_outline, color: t.danger),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTheme.of(context);
    final golf = ref.watch(golfEventsProvider);

    return golf.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: t.accent)),
      error: (e, _) => _ErrorView('일정 로드 오류: $e'),
      data: (golfEvents) {
        if (golfEvents.isEmpty) {
          return const _EmptyView(
            icon: Icons.calendar_today_outlined,
            activity: '골프',
          );
        }

        final next = golfEvents.first;
        final rest = golfEvents.skip(1).toList();

        return RefreshIndicator(
          color: t.accent,
          backgroundColor: t.surface,
          onRefresh: () async {
            ref.invalidate(golfEventsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
            children: [
              _dismissible(context, ref, next, _NextRoundCard(event: next)),
              if (rest.isNotEmpty) ...[
                const SizedBox(height: 22),
                _SectionLabel('다가오는 라운드 · ${rest.length}'),
                const SizedBox(height: 11),
                ...rest.map(
                  (event) => _dismissible(
                    context,
                    ref,
                    event,
                    _GolfRowCard(
                      event: event,
                      onDelete: () async {
                        final confirmed = await _confirmDelete(context, event);
                        if (confirmed && context.mounted) {
                          await _deleteSchedule(context, ref, event);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 지도 화면 (WebView)
// ═══════════════════════════════════════════════════════════════
class _MapScreen extends ConsumerStatefulWidget {
  const _MapScreen();

  @override
  ConsumerState<_MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<_MapScreen> {
  late WebViewController webViewController;
  String? _selectedEventId;
  String? _loadedMapKey;
  GolfEvent? _fallbackEvent;
  bool _isMapLoading = false;
  bool _isMapReady = false;
  final Set<String> _resolvingLocationIds = {};
  final Set<String> _loadingRestaurantEventIds = {};
  final Map<String, List<_MapRestaurantMarker>> _restaurantMarkersByEventId =
      {};

  @override
  void initState() {
    super.initState();
    webViewController = _createWebViewController();
  }

  WebViewController _createWebViewController() {
    late final WebViewController controller;
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isMapLoading = true;
              _isMapReady = false;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _isMapLoading = false;
              _isMapReady = true;
            });
          },
          onWebResourceError: (error) {
            final isMainFrameError = error.isForMainFrame ?? false;
            final failedUrl = error.url ?? '';
            final isCourseMapRequest = failedUrl.contains('/map/course') ||
                failedUrl.contains('/map/windy');
            if (!isMainFrameError || !isCourseMapRequest) {
              return;
            }

            final event = _fallbackEvent;
            if (event?.lat == null || event?.lng == null) return;
            controller.loadHtmlString(
              buildMapHtml(
                lat: event!.lat!,
                lng: event.lng!,
                label: event.courseName ?? event.location ?? event.title,
              ),
            );
          },
        ),
      );
    return controller;
  }

  Widget _buildMapLoadingCover(String label) {
    final t = GwTheme.of(context);
    return Positioned.fill(
      child: Container(
        color: t.bg,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: t.accent),
            const SizedBox(height: 14),
            Text(
              '$label 지도 불러오는 중',
              style: TextStyle(
                color: t.fg2,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadMap(GolfEvent event) async {
    if (event.lat == null || event.lng == null) return;

    final markers = _restaurantMarkersByEventId[event.id] ?? const [];
    final key = '${event.id}:${event.lat}:${event.lng}:${markers.length}';
    if (_loadedMapKey == key) return;

    setState(() {
      _loadedMapKey = key;
      _fallbackEvent = event;
      _isMapLoading = true;
      _isMapReady = false;
      webViewController = _createWebViewController();
    });

    await webViewController.loadRequest(
      AppConfig.courseMapUri(
        lat: event.lat!,
        lng: event.lng!,
        label: event.courseName ?? event.location ?? event.title,
        restaurantsJson: markers.isEmpty
            ? null
            : jsonEncode(markers.map((e) => e.toJson()).toList()),
      ),
    );

    _warmNearbyRestaurants(event);
  }

  Future<void> _warmNearbyRestaurants(GolfEvent event) async {
    if (event.lat == null || event.lng == null) return;
    if (_restaurantMarkersByEventId.containsKey(event.id)) return;
    if (_loadingRestaurantEventIds.contains(event.id)) return;

    _loadingRestaurantEventIds.add(event.id);
    try {
      final result = await RestaurantService().searchRestaurants(
        lat: event.lat!,
        lng: event.lng!,
        category: '추천',
        courseAddress: event.address,
        radius: 3200,
      );

      final markers = result.restaurants
          .where((restaurant) => restaurant.lat != 0 && restaurant.lng != 0)
          .take(4)
          .map(_MapRestaurantMarker.fromRestaurant)
          .toList(growable: false);

      _restaurantMarkersByEventId[event.id] = markers;

      if (!mounted || markers.isEmpty || _selectedEventId != event.id) {
        return;
      }

      setState(() {
        _loadedMapKey = null;
      });
      await _loadMap(event);
    } catch (e) {
      debugPrint('⚠️ nearby restaurants warmup failed: $e');
    } finally {
      _loadingRestaurantEventIds.remove(event.id);
    }
  }

  Future<void> _resolveLocationAndLoadMap(GolfEvent event) async {
    if (event.lat != null && event.lng != null) {
      await _loadMap(event);
      return;
    }

    if (_resolvingLocationIds.contains(event.id)) return;

    _resolvingLocationIds.add(event.id);
    if (mounted) {
      setState(() => _isMapLoading = true);
    }

    try {
      final result = await WeatherApiService.instance.geocodeBestEffort(
        courseName: event.courseName ?? event.location ?? event.title,
        address: event.address,
      );
      if (result == null) return;

      await AppScheduleService().updateSchedule(event.id, {
        'lat': result.lat,
        'lng': result.lng,
      });
      ref.invalidate(golfEventsProvider);

      await _loadMap(event.copyWith(lat: result.lat, lng: result.lng));
    } finally {
      _resolvingLocationIds.remove(event.id);
      if (mounted) {
        setState(() => _isMapLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final async = ref.watch(golfEventsProvider);

    return async.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: t.accent)),
      error: (e, _) => _ErrorView('지도 로드 오류: $e'),
      data: (events) {
        if (events.isEmpty) {
          return const _EmptyView(
            icon: Icons.map_outlined,
            activity: '골프',
          );
        }

        final defaultEvent = events.firstWhere(
          (e) => e.lat != null && e.lng != null,
          orElse: () => events.firstWhere(
            (e) => (e.address ?? '').trim().isNotEmpty,
            orElse: () => events.first,
          ),
        );
        final selected = events.firstWhere(
          (e) => e.id == _selectedEventId,
          orElse: () => defaultEvent,
        );
        _selectedEventId ??= selected.id;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _resolveLocationAndLoadMap(selected);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
              child: Text('지도',
                  style: TextStyle(
                      color: t.fg,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4)),
            ),
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final event = events[index];
                  final selectedChip = event.id == selected.id;
                  return ChoiceChip(
                    label: Text(event.courseName ?? event.title),
                    selected: selectedChip,
                    onSelected: (_) {
                      setState(() {
                        _selectedEventId = event.id;
                        _loadedMapKey = null;
                        _isMapLoading = true;
                        _isMapReady = false;
                      });
                    },
                    showCheckmark: false,
                    selectedColor: t.accent,
                    backgroundColor: t.surface,
                    labelStyle: TextStyle(
                      color: selectedChip ? t.accentInk : t.fg2,
                      fontWeight:
                          selectedChip ? FontWeight.w800 : FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: selectedChip ? t.accent : t.cardBorder,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: selected.lat == null || selected.lng == null
                      ? Stack(
                          children: [
                            _MapMissingLocation(event: selected),
                            if (_isMapLoading)
                              _buildMapLoadingCover(
                                selected.courseName ?? selected.title,
                              ),
                          ],
                        )
                      : Stack(
                          children: [
                            Opacity(
                              opacity: _isMapReady ? 1 : 0,
                              child: IgnorePointer(
                                ignoring: !_isMapReady,
                                child: WebViewWidget(
                                  key: ValueKey(
                                      _loadedMapKey ?? _selectedEventId),
                                  controller: webViewController,
                                  gestureRecognizers: {
                                    Factory<OneSequenceGestureRecognizer>(
                                      () => EagerGestureRecognizer(),
                                    ),
                                  },
                                ),
                              ),
                            ),
                            if (_isMapLoading || !_isMapReady)
                              _buildMapLoadingCover(
                                selected.courseName ?? selected.title,
                              ),
                          ],
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
              child: _MapCourseCard(event: selected),
            ),
          ],
        );
      },
    );
  }
}

// ── 지도 하단 골프장 카드 ─────────────────────────────────────
class _MapCourseCard extends StatelessWidget {
  final GolfEvent event;
  const _MapCourseCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final sub = [
      '${event.formattedDate} ${event.formattedTime}',
      if ((event.address ?? event.location) != null)
        (event.address ?? event.location)!,
    ].join(' · ');

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => EventDetailScreen(golfEvent: event))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 17),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                            color: t.accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(event.courseName ?? event.title,
                            style: TextStyle(
                                color: t.fg,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(sub,
                      style: TextStyle(color: t.fg2, fontSize: 12.5),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right, color: t.accent, size: 26),
          ],
        ),
      ),
    );
  }
}

class _MapRestaurantMarker {
  final String name;
  final String category;
  final double lat;
  final double lng;
  final double distanceKm;

  const _MapRestaurantMarker({
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    required this.distanceKm,
  });

  factory _MapRestaurantMarker.fromRestaurant(Restaurant restaurant) {
    return _MapRestaurantMarker(
      name: restaurant.name,
      category: restaurant.category,
      lat: restaurant.lat,
      lng: restaurant.lng,
      distanceKm: restaurant.distance,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'lat': lat,
        'lng': lng,
        'distance_km': distanceKm,
      };
}

class _MapMissingLocation extends StatelessWidget {
  final GolfEvent event;
  const _MapMissingLocation({required this.event});

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: t.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_outlined, color: t.fg2, size: 34),
              const SizedBox(height: 12),
              Text(event.courseName ?? event.title,
                  style: TextStyle(
                      color: t.fg,
                      fontSize: 17,
                      fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                '지도에 표시할 좌표가 없습니다.\n일정 수정에서 주소를 입력하면 위치를 표시할 수 있습니다.',
                style: TextStyle(color: t.fg3, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
