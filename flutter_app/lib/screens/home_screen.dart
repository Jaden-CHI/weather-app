import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/golf_event.dart';
import '../models/weather_data.dart';
import '../services/app_schedule_service.dart';
import '../services/weather_api_service.dart';
import '../services/background_service.dart';
import 'event_detail_screen.dart';
import 'settings_screen.dart';

// ── 디자인 토큰 ────────────────────────────────────────────────
class _T {
  static const bgDeep  = Color(0xFF0E2A24);
  static const bgElev1 = Color(0xFF143630);
  static const bgElev2 = Color(0xFF1B4332);
  static const brand   = Color(0xFF2E7D6B);

  static const green        = Color(0xFF4ADE80);
  static const greenBg      = Color(0x254ADE80);
  static const greenBorder  = Color(0x664ADE80);
  static const yellow       = Color(0xFFFFC107);
  static const yellowBg     = Color(0x28FFC107);
  static const yellowBorder = Color(0x72FFC107);
  static const red          = Color(0xFFFF6B6B);
  static const redBg        = Color(0x25FF6B6B);
  static const redBorder    = Color(0x66FF6B6B);

  static const text1   = Color(0xFFF4FBF8);
  static const text2   = Color(0xB3F4FBF8);
  static const text3   = Color(0x73F4FBF8);
  static const divider = Color(0x14F4FBF8);
}

// ── 상태 헬퍼 ──────────────────────────────────────────────────
class _Status {
  final Color color, bg, border;
  final String label;
  const _Status({required this.color, required this.bg, required this.border, required this.label});
}

_Status _statusOf(String s) => switch (s) {
  'GREEN'  => const _Status(color: _T.green,  bg: _T.greenBg,  border: _T.greenBorder,  label: '최적'),
  'YELLOW' => const _Status(color: _T.yellow, bg: _T.yellowBg, border: _T.yellowBorder, label: '주의'),
  'RED'    => const _Status(color: _T.red,    bg: _T.redBg,    border: _T.redBorder,    label: '취소권장'),
  _        => const _Status(color: _T.text3,  bg: _T.divider,  border: _T.divider,      label: '정보없음'),
};

// ── 프로바이더 ─────────────────────────────────────────────────
final golfEventsProvider = FutureProvider<List<GolfEvent>>((ref) async {
  return AppScheduleService().getUpcomingGolfSchedules();
});

final fishingEventsProvider = FutureProvider<List<FishingEvent>>((ref) async {
  return AppScheduleService().getUpcomingFishingSchedules();
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
  int _tab    = 0; // 0=골프, 1=낚시
  int _navIdx = 0; // 하단 탭

  @override
  void initState() {
    super.initState();
    BackgroundService.runOnce();
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
                      ref.invalidate(fishingEventsProvider);
                    },
                  ),
                  _SegmentControl(
                    active: _tab,
                    onChanged: (v) => setState(() => _tab = v),
                  ),
                  Expanded(
                    child: _tab == 0
                        ? _GolfTab(ref: ref)
                        : _FishingTab(ref: ref),
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
                    style: const TextStyle(color: _T.text3, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                const Text('PlayWeather',
                    style: TextStyle(color: _T.text1, fontSize: 26, fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
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
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: _T.bgElev1, borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _T.divider),
        ),
        child: Icon(icon, color: _T.text2, size: 20),
      ),
    );
  }
}

// ── 세그먼트 컨트롤 ────────────────────────────────────────────
class _SegmentControl extends StatelessWidget {
  final int active;
  final ValueChanged<int> onChanged;
  const _SegmentControl({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _T.bgElev1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.divider),
      ),
      child: Row(
        children: [
          _Segment(id: 0, label: '⛳ 골프',   active: active, onTap: () => onChanged(0)),
          _Segment(id: 1, label: '🎣 배낚시', active: active, onTap: () => onChanged(1)),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final int id, active;
  final String label;
  final VoidCallback onTap;
  const _Segment({required this.id, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final on = id == active;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 46,
          decoration: BoxDecoration(
            color: on ? _T.bgElev2 : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                color: on ? _T.text1 : _T.text3,
                fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
              )),
        ),
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
              _NavItem(idx: 0, icon: '🏠', label: '홈',  active: active, onTap: onChanged),
              _NavItem(idx: 1, icon: '📅', label: '일정', active: active, onTap: onChanged),
              _NavItem(idx: 2, icon: '🗺', label: '지도', active: active, onTap: onChanged),
              _NavItem(idx: 3, icon: '⚙️', label: '설정', active: active, onTap: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int idx, active;
  final String icon, label;
  final ValueChanged<int> onTap;
  const _NavItem({required this.idx, required this.active, required this.icon,
      required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final on = idx == active;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(idx),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
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
      loading: () => const Center(child: CircularProgressIndicator(color: _T.brand)),
      error:   (e, _) => _ErrorView('캘린더 오류: $e'),
      data: (events) {
        if (events.isEmpty) return const _EmptyView(icon: '⛳', activity: '골프');
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.event.courseId == null) return;
    final data = await WeatherApiService.instance.getGolfWeather(
      widget.event.courseId!, dday: widget.event.dday.clamp(0, 7));
    if (mounted) setState(() => _wx = data);
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
            begin: Alignment.topLeft, end: Alignment.bottomRight,
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
                  // D-day + 상태 필
                  Row(children: [
                    _DdayBadge(dday: e.dday, large: true),
                    const SizedBox(width: 10),
                    if (status != 'NONE') _StatusPill(status: status),
                  ]),
                  const SizedBox(height: 14),
                  // 골프장명
                  Text(e.courseName ?? e.title,
                      style: const TextStyle(color: _T.text1, fontSize: 26,
                          fontWeight: FontWeight.w800, letterSpacing: -0.5)),
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
                    const _WxLoading(),
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
    final temp    = f?.temp.toInt() ?? 0;
    final rain    = f?.rainProb ?? 0;
    final wind    = f?.windSpeed ?? 0.0;
    final emoji   = f?.skyEmoji ?? '🌤';

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
                    style: const TextStyle(color: _T.text1, fontSize: 40,
                        fontWeight: FontWeight.w800, letterSpacing: -1, height: 1)),
                const SizedBox(height: 2),
                Text(f?.weatherLabel ?? '', style: const TextStyle(color: _T.text2, fontSize: 14)),
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
        Text(value, style: const TextStyle(color: _T.text1, fontSize: 15, fontWeight: FontWeight.w700)),
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
        color: s.bg, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: s.border),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI 추천 · ${s.label}',
                    style: TextStyle(color: s.color, fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(rec.message,
                    style: const TextStyle(color: _T.text2, fontSize: 13, fontWeight: FontWeight.w500)),
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
      height: 80, alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(color: _T.brand, strokeWidth: 2),
      ),
    );
  }
}

// ── 골프 리스트 카드 (히어로 아래) ────────────────────────────
class _GolfRowCard extends StatefulWidget {
  final GolfEvent event;
  const _GolfRowCard({required this.event});
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
    if (widget.event.courseId == null) return;
    final data = await WeatherApiService.instance.getGolfWeather(
      widget.event.courseId!, dday: widget.event.dday.clamp(0, 7));
    if (mounted) setState(() => _wx = data);
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
          color: _T.bgElev1, borderRadius: BorderRadius.circular(18),
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
                      style: const TextStyle(color: _T.text1, fontSize: 17,
                          fontWeight: FontWeight.w700, letterSpacing: -0.3),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text('${e.formattedDate.split(' ').take(2).join(' ')} · ${e.location ?? ''}',
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
                      style: const TextStyle(color: _T.text1, fontSize: 22,
                          fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: s.color, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: s.color.withOpacity(0.4), blurRadius: 6, spreadRadius: 1)],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 낚시 탭
// ═══════════════════════════════════════════════════════════════
class _FishingTab extends StatelessWidget {
  final WidgetRef ref;
  const _FishingTab({required this.ref});

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(fishingEventsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _T.brand)),
      error:   (e, _) => _ErrorView('캘린더 오류: $e'),
      data: (events) {
        if (events.isEmpty) return const _EmptyView(icon: '🎣', activity: '배낚시');
        return RefreshIndicator(
          color: _T.brand,
          backgroundColor: _T.bgElev1,
          onRefresh: () async => ref.invalidate(fishingEventsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            children: [
              _FishingHeroCard(event: events.first),
              if (events.length > 1) ...[
                const SizedBox(height: 20),
                const _SectionLabel('다가오는 출조'),
                const SizedBox(height: 10),
                ...events.skip(1).map((e) => _FishingRowCard(event: e)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FishingHeroCard extends StatefulWidget {
  final FishingEvent event;
  const _FishingHeroCard({required this.event});
  @override
  State<_FishingHeroCard> createState() => _FishingHeroCardState();
}

class _FishingHeroCardState extends State<_FishingHeroCard> {
  MarineWeatherData? _wx;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = widget.event;
    String? spotId = e.spotId;
    if (spotId == null && e.location != null) {
      spotId = await WeatherApiService.instance.searchSpotId(e.location!);
    }
    if (spotId == null) return;
    final data = await WeatherApiService.instance.getMarineWeather(spotId);
    if (mounted) setState(() => _wx = data);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final status = _wx?.aiRecommendation.status ?? 'NONE';
    final s = _statusOf(status);
    final blocked = _wx?.warning.departureBlocked ?? false;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => EventDetailScreen(fishingEvent: e))),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF143D5C), Color(0xFF0E2A3A)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: s.border, width: 1.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 4, color: s.color),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _DdayBadge(dday: e.dday, large: true),
                    const SizedBox(width: 10),
                    if (_wx != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: blocked ? _T.redBg : _T.greenBg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: blocked ? _T.redBorder : _T.greenBorder),
                        ),
                        child: Text(
                          blocked ? '⛔ 출항 불가' : '✅ 출항 가능',
                          style: TextStyle(
                            color: blocked ? _T.red : _T.green,
                            fontSize: 13, fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 14),
                  Text(e.title,
                      style: const TextStyle(color: _T.text1, fontSize: 24,
                          fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  Text('${e.formattedDate} · ${e.formattedTime}',
                      style: const TextStyle(color: _T.text2, fontSize: 15)),
                  if (e.location != null) ...[
                    const SizedBox(height: 2),
                    Text('📍 ${e.location}', style: const TextStyle(color: _T.text3, fontSize: 13)),
                  ],
                  if (_wx != null) ...[
                    const SizedBox(height: 18),
                    _MarineStrip(data: _wx!),
                    const SizedBox(height: 14),
                    _AiChip(rec: _wx!.aiRecommendation),
                  ] else ...[
                    const SizedBox(height: 14),
                    const _WxLoading(),
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

class _MarineStrip extends StatelessWidget {
  final MarineWeatherData data;
  const _MarineStrip({required this.data});

  @override
  Widget build(BuildContext context) {
    final c = data.current;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MarineStat('🌊', '${c.waveHeight}m', '파고'),
          _Divider(),
          _MarineStat('🌬', '${c.windSpeed}m/s', '풍속'),
          _Divider(),
          _MarineStat('🌡', '${c.seaTemp}°C', '수온'),
          _Divider(),
          _MarineStat('👁', '${c.visibility}km', '시정'),
        ],
      ),
    );
  }
}

class _MarineStat extends StatelessWidget {
  final String icon, value, label;
  const _MarineStat(this.icon, this.value, this.label);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: _T.text1, fontWeight: FontWeight.w700, fontSize: 15)),
        Text(label, style: const TextStyle(color: _T.text3, fontSize: 11)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: _T.divider);
}

class _FishingRowCard extends StatelessWidget {
  final FishingEvent event;
  const _FishingRowCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final e = event;
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => EventDetailScreen(fishingEvent: e))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _T.bgElev1, borderRadius: BorderRadius.circular(18),
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
                  Text(e.title,
                      style: const TextStyle(color: _T.text1, fontSize: 17,
                          fontWeight: FontWeight.w700, letterSpacing: -0.3),
                      overflow: TextOverflow.ellipsis),
                  if (e.location != null)
                    Text(e.location!,
                        style: const TextStyle(color: _T.text3, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _T.text3, size: 20),
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
    final urgent  = dday <= 2;
    final bg = isToday ? _T.yellow : (urgent ? _T.brand : const Color(0x1AF4FBF8));
    final fg = isToday ? const Color(0xFF1A2E12) : Colors.white;
    final label = isToday ? 'D-DAY' : 'D-$dday';

    return Container(
      padding: large
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
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
        color: s.bg, borderRadius: BorderRadius.circular(999),
        border: Border.all(color: s.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(s.label, style: TextStyle(color: s.color, fontSize: 14, fontWeight: FontWeight.w700)),
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
        style: const TextStyle(color: _T.text3, fontSize: 12,
            fontWeight: FontWeight.w700, letterSpacing: 0.8));
  }
}

class _EmptyView extends StatelessWidget {
  final String icon, activity;
  const _EmptyView({required this.icon, required this.activity});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text('등록된 $activity 일정이 없습니다',
                style: const TextStyle(color: _T.text1, fontSize: 18, fontWeight: FontWeight.w700),
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
                    const Text('일정', style: TextStyle(color: _T.text3, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    const Text('골프·배낚시 일정', style: TextStyle(color: _T.text1, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final golf = ref.watch(golfEventsProvider);
    final fishing = ref.watch(fishingEventsProvider);

    return golf.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _T.brand)),
      error: (e, _) => _ErrorView('일정 로드 오류: $e'),
      data: (golfEvents) => fishing.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _T.brand)),
        error: (e, _) => _ErrorView('일정 로드 오류: $e'),
        data: (fishingEvents) {
          final allEvents = <({String type, dynamic event, int dday})>[];
          for (var e in golfEvents) allEvents.add((type: 'golf', event: e, dday: e.dday));
          for (var e in fishingEvents) allEvents.add((type: 'fishing', event: e, dday: e.dday));
          allEvents.sort((a, b) => a.dday.compareTo(b.dday));

          if (allEvents.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('📅', style: TextStyle(fontSize: 52)),
                    SizedBox(height: 16),
                    Text('등록된 일정이 없습니다',
                        style: TextStyle(color: _T.text1, fontSize: 18, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center),
                    SizedBox(height: 8),
                    Text('일정을 추가하면 여기에 표시됩니다',
                        style: TextStyle(color: _T.text3, fontSize: 14),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: _T.brand,
            backgroundColor: _T.bgElev1,
            onRefresh: () async {
              ref.invalidate(golfEventsProvider);
              ref.invalidate(fishingEventsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              itemCount: allEvents.length,
              itemBuilder: (_, i) {
                final item = allEvents[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: item.type == 'golf'
                      ? _GolfRowCard(event: item.event as GolfEvent)
                      : _FishingRowCard(event: item.event as FishingEvent),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 지도 화면
// ═══════════════════════════════════════════════════════════════
class _MapScreen extends StatefulWidget {
  const _MapScreen();

  @override
  State<_MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<_MapScreen> {
  late GoogleMapController mapController;
  LatLng? currentLocation;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        currentLocation = const LatLng(37.5665, 126.9780); // 서울
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || currentLocation == null) {
      return const Center(child: CircularProgressIndicator(color: _T.brand));
    }

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
                    const Text('지도', style: TextStyle(color: _T.text3, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    const Text('골프장·출조지 검색', style: TextStyle(color: _T.text1, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GoogleMap(
            onMapCreated: (controller) => mapController = controller,
            initialCameraPosition: CameraPosition(target: currentLocation!, zoom: 12),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
        ),
      ],
    );
  }
}
