import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/app_config.dart';
import '../utils/map_html.dart';
import '../models/golf_event.dart';
import '../models/restaurant.dart';
import '../models/weather_data.dart';
import '../services/app_schedule_service.dart';
import '../services/restaurant_service.dart';
import '../services/weather_api_service.dart';
import '../services/background_service.dart';
import '../services/widget_sync_service.dart';
import 'event_detail_screen.dart';
import 'settings_screen.dart';
import 'add_schedule_screen.dart';

// ── 디자인 토큰 ────────────────────────────────────────────────
class _T {
  static const bgDeep = Color(0xFF0E2A24);
  static const bgElev1 = Color(0xFF143630);
  static const bgElev2 = Color(0xFF1B4332);
  static const brand = Color(0xFF2E7D6B);

  static const green = Color(0xFF4ADE80);
  static const greenBg = Color(0x254ADE80);
  static const greenBorder = Color(0x664ADE80);
  static const yellow = Color(0xFFFFC107);
  static const yellowBg = Color(0x28FFC107);
  static const yellowBorder = Color(0x72FFC107);
  static const red = Color(0xFFFF6B6B);
  static const redBg = Color(0x25FF6B6B);
  static const redBorder = Color(0x66FF6B6B);

  static const text1 = Color(0xFFF4FBF8);
  static const text2 = Color(0xB3F4FBF8);
  static const text3 = Color(0x73F4FBF8);
  static const divider = Color(0x14F4FBF8);
}

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

_Status _statusOf(String s) => switch (s) {
      'GREEN' => const _Status(
          color: _T.green, bg: _T.greenBg, border: _T.greenBorder, label: '최적'),
      'YELLOW' => const _Status(
          color: _T.yellow,
          bg: _T.yellowBg,
          border: _T.yellowBorder,
          label: '주의'),
      'RED' => const _Status(
          color: _T.red, bg: _T.redBg, border: _T.redBorder, label: '취소권장'),
      _ => const _Status(
          color: _T.text3, bg: _T.divider, border: _T.divider, label: '정보없음'),
    };

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

  @override
  void initState() {
    super.initState();
    BackgroundService.runOnce();
    WidgetSyncService.instance.syncNextGolfEvent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bgDeep,
      body: SafeArea(
        bottom: false,
        child: _navIdx == 0
            ? Column(
                children: [
                  _Header(
                    onRefreshTap: () {
                      ref.invalidate(golfEventsProvider);
                    },
                  ),
                  Expanded(
                    child: _GolfTab(ref: ref),
                  ),
                ],
              )
            : _navIdx == 1
                ? const _ScheduleScreen()
                : _navIdx == 2
                    ? const _MapScreen()
                    : const SettingsScreen(),
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
              backgroundColor: _T.brand,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// ── 헤더 ───────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final VoidCallback onRefreshTap;
  const _Header({required this.onRefreshTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final subtitle = '${now.month}월 ${now.day}일 ${weekdays[now.weekday - 1]}요일';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle,
                    style: const TextStyle(
                        color: _T.text3,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                const Text('Golf Windy',
                    style: TextStyle(
                        color: _T.text1,
                        fontSize: 26,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          _IconBtn(Icons.refresh, onRefreshTap),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _T.bgElev1,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _T.divider),
        ),
        child: Icon(icon, color: _T.text2, size: 20),
      ),
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
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xEB0E2A24),
        border: Border(top: BorderSide(color: _T.divider)),
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
                  icon: Icons.settings_outlined,
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
    final on = idx == active;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(idx),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: on ? _T.text1 : _T.text3, size: 23),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                  color: on ? _T.text1 : _T.text3,
                  fontSize: 11,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 골프 탭
// ═══════════════════════════════════════════════════════════════
class _GolfTab extends StatelessWidget {
  final WidgetRef ref;
  const _GolfTab({required this.ref});

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(golfEventsProvider);
    return async.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _T.brand)),
      error: (e, _) => _ErrorView('캘린더 오류: $e'),
      data: (events) {
        if (events.isEmpty) {
          return const _EmptyView(
            icon: Icons.flag_outlined,
            activity: '골프',
          );
        }
        return RefreshIndicator(
          color: _T.brand,
          backgroundColor: _T.bgElev1,
          onRefresh: () async => ref.invalidate(golfEventsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            children: [
              // 히어로 카드
              _GolfHeroCard(event: events.first),
              if (events.length > 1) ...[
                const SizedBox(height: 20),
                const _SectionLabel('다가오는 라운드'),
                const SizedBox(height: 10),
                ...events.skip(1).map((e) => _GolfRowCard(event: e)),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── 골프 히어로 카드 ───────────────────────────────────────────
class _GolfHeroCard extends StatefulWidget {
  final GolfEvent event;
  const _GolfHeroCard({required this.event});
  @override
  State<_GolfHeroCard> createState() => _GolfHeroCardState();
}

class _GolfHeroCardState extends State<_GolfHeroCard> {
  GolfWeatherData? _wx;
  bool _weatherResolved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = WeatherApiService.instance;
      var event = widget.event;
      var courseId = event.courseId;
      courseId ??= await api.searchCourseId(
        event.courseName ?? event.title,
      );

      GolfWeatherData? data;
      if (courseId != null && courseId.isNotEmpty) {
        data = await api.getGolfWeather(
          courseId,
          dday: event.dday.clamp(0, 7),
          startHour: event.startDate.hour,
        );
      } else {
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
        if (lat != null && lng != null) {
          data = await api.getCustomGolfWeather(
            lat: lat,
            lng: lng,
            courseName: event.courseName ?? event.location ?? event.title,
            dday: event.dday.clamp(0, 7),
            startHour: event.startDate.hour,
          );
        }
      }

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

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final status = _wx?.aiRecommendation.status ?? 'NONE';
    final s = _statusOf(status);

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => EventDetailScreen(golfEvent: e))),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B4332), Color(0xFF143630)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: s.border, width: 1.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상태 스트라이프
            Container(height: 4, color: s.color),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('다음 라운드',
                      style: TextStyle(
                          color: _T.text3,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  // D-day + 상태 필
                  Row(children: [
                    _DdayBadge(dday: e.dday, large: true),
                    const SizedBox(width: 10),
                    if (status != 'NONE') _StatusPill(status: status),
                  ]),
                  const SizedBox(height: 14),
                  // 골프장명
                  Text(e.courseName ?? e.title,
                      style: const TextStyle(
                          color: _T.text1,
                          fontSize: 26,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('${e.formattedDate} · ${e.formattedTime}',
                      style: const TextStyle(color: _T.text2, fontSize: 15)),
                  if (e.location != null) ...[
                    const SizedBox(height: 2),
                    Text('📍 ${e.location}',
                        style: const TextStyle(color: _T.text3, fontSize: 13)),
                  ],
                  // 날씨 스트립
                  if (_wx != null) ...[
                    const SizedBox(height: 18),
                    _WeatherStrip(data: _wx!),
                    const SizedBox(height: 14),
                    _AiChip(rec: _wx!.aiRecommendation),
                  ] else ...[
                    const SizedBox(height: 14),
                    _weatherResolved
                        ? const _WxUnavailable()
                        : const _WxLoading(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherStrip extends StatelessWidget {
  final GolfWeatherData data;
  const _WeatherStrip({required this.data});

  @override
  Widget build(BuildContext context) {
    final f = data.forecast.isNotEmpty ? data.forecast.first : null;
    final temp = f?.temp.toInt() ?? 0;
    final rain = f?.rainProb ?? 0;
    final wind = f?.windSpeed ?? 0.0;
    final emoji = f?.skyEmoji ?? '🌤';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$temp°',
                    style: const TextStyle(
                        color: _T.text1,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        height: 1)),
                const SizedBox(height: 2),
                Text(f?.weatherLabel ?? '',
                    style: const TextStyle(color: _T.text2, fontSize: 14)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Metric('💧', '$rain%', '강수'),
              const SizedBox(height: 8),
              _Metric('🌬', '${wind.toStringAsFixed(1)}m/s', '바람'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String icon, value, label;
  const _Metric(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(value,
            style: const TextStyle(
                color: _T.text1, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: _T.text3, fontSize: 12)),
      ],
    );
  }
}

class _AiChip extends StatelessWidget {
  final AiRecommendation rec;
  const _AiChip({required this.rec});

  @override
  Widget build(BuildContext context) {
    final s = _statusOf(rec.status);
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
                    style: const TextStyle(
                        color: _T.text2,
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
    return Container(
      height: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(color: _T.brand, strokeWidth: 2),
      ),
    );
  }
}

class _WxUnavailable extends StatelessWidget {
  const _WxUnavailable();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.divider),
      ),
      child: const Text(
        '주소 기반 날씨를 찾을 수 없습니다',
        style: TextStyle(
          color: _T.text3,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── 골프 리스트 카드 (히어로 아래) ────────────────────────────
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
      final api = WeatherApiService.instance;
      var event = widget.event;
      var courseId = event.courseId;
      courseId ??= await api.searchCourseId(
        event.courseName ?? event.title,
      );

      GolfWeatherData? data;
      if (courseId != null && courseId.isNotEmpty) {
        data = await api.getGolfWeather(
          courseId,
          dday: event.dday.clamp(0, 7),
          startHour: event.startDate.hour,
        );
      } else {
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
        if (lat != null && lng != null) {
          data = await api.getCustomGolfWeather(
            lat: lat,
            lng: lng,
            courseName: event.courseName ?? event.location ?? event.title,
            dday: event.dday.clamp(0, 7),
            startHour: event.startDate.hour,
          );
        }
      }

      if (mounted) setState(() => _wx = data);
    } catch (_) {
      // 백엔드 미연결 시 카드는 일정 정보만 표시
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final status = _wx?.aiRecommendation.status ?? 'NONE';
    final s = _statusOf(status);

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => EventDetailScreen(golfEvent: e))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _T.bgElev1,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _T.divider),
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
                      style: const TextStyle(
                          color: _T.text1,
                          fontSize: 17,
                          fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                      '${e.formattedDate.split(' ').take(2).join(' ')} · ${e.location ?? ''}',
                      style: const TextStyle(color: _T.text3, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_wx != null && _wx!.forecast.isNotEmpty)
                  Text('${_wx!.forecast.first.temp.toInt()}°',
                      style: const TextStyle(
                          color: _T.text1,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: s.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: s.color.withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 1)
                    ],
                  ),
                ),
              ],
            ),
            if (widget.onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: '일정 삭제',
                icon: const Icon(Icons.delete_outline, color: _T.text3),
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
  final bool large;
  const _DdayBadge({required this.dday, this.large = false});

  @override
  Widget build(BuildContext context) {
    final isToday = dday == 0;
    final urgent = dday <= 2;
    final bg =
        isToday ? _T.yellow : (urgent ? _T.brand : const Color(0x1AF4FBF8));
    final fg = isToday ? const Color(0xFF1A2E12) : Colors.white;
    final label =
        isToday ? 'D-DAY' : (dday > 0 ? 'D-$dday' : 'D+${dday.abs()}');

    return Container(
      padding: large
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w800,
            fontSize: large ? 18 : 13,
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
    final s = _statusOf(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: s.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: s.color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(s.label,
              style: TextStyle(
                  color: s.color, fontSize: 14, fontWeight: FontWeight.w700)),
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
    return Text(text.toUpperCase(),
        style: const TextStyle(
            color: _T.text3,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8));
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String activity;
  const _EmptyView({required this.icon, required this.activity});
  @override
  Widget build(BuildContext context) {
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
                color: _T.bgElev1,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _T.divider),
              ),
              child: Icon(icon, color: _T.text2, size: 34),
            ),
            const SizedBox(height: 16),
            Text('등록된 $activity 일정이 없습니다',
                style: const TextStyle(
                    color: _T.text1, fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('캘린더에 $activity 일정을 추가하면\n자동으로 날씨를 확인해드립니다',
                style: const TextStyle(color: _T.text3, fontSize: 14),
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
  Widget build(BuildContext context) =>
      Center(child: Text(msg, style: const TextStyle(color: _T.red)));
}

// ═══════════════════════════════════════════════════════════════
// 일정 화면
// ═══════════════════════════════════════════════════════════════
class _ScheduleScreen extends StatelessWidget {
  const _ScheduleScreen();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('일정',
                        style: TextStyle(
                            color: _T.text3,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    const Text('골프 일정',
                        style: TextStyle(
                            color: _T.text1,
                            fontSize: 26,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _AllScheduleList(),
        ),
      ],
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
    final courseName = event.courseName ?? event.title;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _T.bgElev1,
        title: const Text('일정 삭제', style: TextStyle(color: _T.text1)),
        content: Text(
          '$courseName 일정을 삭제할까요?',
          style: const TextStyle(color: _T.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _T.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final golf = ref.watch(golfEventsProvider);

    return golf.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _T.brand)),
      error: (e, _) => _ErrorView('일정 로드 오류: $e'),
      data: (golfEvents) {
        if (golfEvents.isEmpty) {
          return const _EmptyView(
            icon: Icons.calendar_today_outlined,
            activity: '골프',
          );
        }

        return RefreshIndicator(
          color: _T.brand,
          backgroundColor: _T.bgElev1,
          onRefresh: () async {
            ref.invalidate(golfEventsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: golfEvents.length,
            itemBuilder: (_, i) {
              final event = golfEvents[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
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
                      color: _T.redBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _T.redBorder),
                    ),
                    child: const Icon(Icons.delete_outline, color: _T.red),
                  ),
                  child: _GolfRowCard(
                    event: event,
                    onDelete: () async {
                      final confirmed = await _confirmDelete(context, event);
                      if (confirmed && context.mounted) {
                        await _deleteSchedule(context, ref, event);
                      }
                    },
                  ),
                ),
              );
            },
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
  final Set<String> _resolvingLocationIds = {};
  final Set<String> _loadingRestaurantEventIds = {};
  final Map<String, List<_MapRestaurantMarker>> _restaurantMarkersByEventId = {};

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (_) {
            final event = _fallbackEvent;
            if (event?.lat == null || event?.lng == null) return;
            webViewController.loadHtmlString(
              buildMapHtml(
                lat: event!.lat!,
                lng: event.lng!,
                label: event.courseName ?? event.location ?? event.title,
              ),
            );
          },
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

    if (mounted) {
      setState(() => _isMapLoading = false);
    }

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
    final async = ref.watch(golfEventsProvider);

    return async.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _T.brand)),
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
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('지도',
                            style: TextStyle(
                                color: _T.text3,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(selected.courseName ?? selected.title,
                            style: const TextStyle(
                                color: _T.text1,
                                fontSize: 26,
                                fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      });
                    },
                    selectedColor: _T.brand,
                    backgroundColor: _T.bgElev1,
                    labelStyle: TextStyle(
                      color: selectedChip ? _T.text1 : _T.text2,
                      fontWeight:
                          selectedChip ? FontWeight.w800 : FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: selectedChip ? _T.greenBorder : _T.divider,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: selected.lat == null || selected.lng == null
                  ? Stack(
                      children: [
                        _MapMissingLocation(event: selected),
                        if (_isMapLoading)
                          const Center(
                            child: CircularProgressIndicator(color: _T.brand),
                          ),
                      ],
                    )
                  : Stack(
                      children: [
                        WebViewWidget(
                          controller: webViewController,
                          gestureRecognizers: {
                            Factory<OneSequenceGestureRecognizer>(
                              () => EagerGestureRecognizer(),
                            ),
                          },
                        ),
                        if (_isMapLoading)
                          const Center(
                            child: CircularProgressIndicator(color: _T.brand),
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _T.bgElev1,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _T.divider),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_outlined,
                  color: _T.text2, size: 34),
              const SizedBox(height: 12),
              Text(event.courseName ?? event.title,
                  style: const TextStyle(
                      color: _T.text1,
                      fontSize: 17,
                      fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                '지도에 표시할 좌표가 없습니다.\n일정 수정에서 주소를 입력하면 위치를 표시할 수 있습니다.',
                style: TextStyle(color: _T.text3, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
