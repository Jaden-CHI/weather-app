import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/golf_event.dart';
import '../models/weather_data.dart';
import '../services/notification_service.dart';
import '../services/share_service.dart';
import '../services/weather_api_service.dart';

// ── 디자인 토큰 (home_screen.dart 동일)
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

class _St {
  final Color color, bg, border;
  final String label;
  const _St({required this.color, required this.bg, required this.border, required this.label});
}

_St _statusOf(String s) => switch (s) {
  'GREEN'  => const _St(color: _T.green,  bg: _T.greenBg,  border: _T.greenBorder,  label: '최적'),
  'YELLOW' => const _St(color: _T.yellow, bg: _T.yellowBg, border: _T.yellowBorder, label: '주의'),
  'RED'    => const _St(color: _T.red,    bg: _T.redBg,    border: _T.redBorder,    label: '취소권장'),
  _        => const _St(color: _T.text3,  bg: _T.divider,  border: _T.divider,      label: '정보없음'),
};

// ══════════════════════════════════════════════════════════════
// 상세 화면
// ══════════════════════════════════════════════════════════════
class EventDetailScreen extends StatefulWidget {
  final GolfEvent? golfEvent;
  final FishingEvent? fishingEvent;

  const EventDetailScreen({super.key, this.golfEvent, this.fishingEvent})
      : assert(golfEvent != null || fishingEvent != null);

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _api   = WeatherApiService.instance;
  final _notif = NotificationService.instance;
  GolfWeatherData?   _golfData;
  MarineWeatherData? _marineData;
  bool    _loading   = true;
  String? _error;
  int?    _subId;
  bool    _subLoading = false;

  bool get _isGolf => widget.golfEvent != null;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() => _loading = true);
    try {
      if (_isGolf) {
        final event = widget.golfEvent!;
        String? courseId = event.courseId;
        courseId ??= await _api.searchCourseId(event.courseName ?? event.title);
        if (courseId != null) {
          _golfData = await _api.getGolfWeather(courseId, dday: event.dday.clamp(0, 7));
        }
      } else {
        final event = widget.fishingEvent!;
        String? spotId = event.spotId;
        if (spotId == null && event.location != null) {
          spotId = await _api.searchSpotId(event.location!);
        }
        if (spotId != null) _marineData = await _api.getMarineWeather(spotId);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _share() async {
    if (_isGolf && _golfData != null) {
      await ShareService.instance.shareGolfWeather(context: context, event: widget.golfEvent!, data: _golfData!);
    } else if (!_isGolf && _marineData != null) {
      await ShareService.instance.shareMarineWeather(context: context, event: widget.fishingEvent!, data: _marineData!);
    }
  }

  Future<void> _toggleSubscription() async {
    if (_subLoading) return;
    setState(() => _subLoading = true);
    if (_subId != null) { setState(() => _subLoading = false); return; }

    final granted = await _notif.requestPermissionAndRegister();
    if (!granted) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림 권한이 필요합니다. 설정에서 허용해주세요.')));
      setState(() => _subLoading = false);
      return;
    }

    final activityType = _isGolf ? 'GOLF' : 'MARINE';
    final targetId = _isGolf
        ? (_golfData?.courseId ?? widget.golfEvent!.courseId ?? '')
        : (_marineData?.spotId ?? widget.fishingEvent!.spotId ?? '');
    final eventDate  = _isGolf ? widget.golfEvent!.startDate : widget.fishingEvent!.startDate;
    final eventTitle = _isGolf
        ? (widget.golfEvent!.courseName ?? widget.golfEvent!.title)
        : widget.fishingEvent!.title;

    if (targetId.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('골프장/출조지 정보를 찾을 수 없어 구독할 수 없습니다.')));
      setState(() => _subLoading = false);
      return;
    }

    final id = await _notif.subscribeToEvent(
      activityType: activityType, targetId: targetId,
      eventDate: eventDate, eventTitle: eventTitle);

    if (mounted) {
      setState(() { _subId = id; _subLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(id != null ? '날씨 변화 알림을 등록했습니다.' : '알림 등록에 실패했습니다.')));
    }
  }

  String get _title => _isGolf
      ? (widget.golfEvent!.courseName ?? widget.golfEvent!.title)
      : widget.fishingEvent!.title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bgDeep,
      body: SafeArea(
        child: Column(children: [
          _DetailNav(
            title: _title,
            onBack: () => Navigator.of(context).pop(),
            onShare: (!_loading && _error == null) ? _share : null,
            onNotif: (!_loading && _error == null) ? _toggleSubscription : null,
            subscribed: _subId != null,
            subLoading: _subLoading,
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _T.brand))
                : _error != null
                    ? _ErrorBody(message: _error!)
                    : _isGolf
                        ? _GolfDetailBody(data: _golfData, event: widget.golfEvent!)
                        : _FishingDetailBody(data: _marineData, event: widget.fishingEvent!),
          ),
        ]),
      ),
    );
  }
}

// ── 내비게이션 헤더 ────────────────────────────────────────────
class _DetailNav extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onShare;
  final VoidCallback? onNotif;
  final bool subscribed;
  final bool subLoading;

  const _DetailNav({
    required this.title, required this.onBack,
    this.onShare, this.onNotif,
    this.subscribed = false, this.subLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(children: [
        _NavBtn(onTap: onBack,
          child: const Text('‹', style: TextStyle(color: _T.text1, fontSize: 24, height: 1))),
        const SizedBox(width: 12),
        Expanded(child: Text(title,
          style: const TextStyle(color: _T.text1, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          overflow: TextOverflow.ellipsis)),
        if (onShare != null) ...[
          const SizedBox(width: 8),
          _NavBtn(onTap: onShare,
            child: const Icon(Icons.ios_share_outlined, color: _T.text2, size: 18)),
        ],
        if (onNotif != null) ...[
          const SizedBox(width: 8),
          subLoading
              ? const SizedBox(width: 38, height: 38,
                  child: Center(child: SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _T.brand))))
              : _NavBtn(onTap: onNotif,
                  child: Icon(
                    subscribed ? Icons.notifications_active : Icons.notifications_none_outlined,
                    color: subscribed ? _T.brand : _T.text2, size: 18)),
        ],
      ]),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  const _NavBtn({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: _T.bgElev1, shape: BoxShape.circle,
          border: Border.all(color: _T.divider)),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

// ── 골프 상세 라우터 ──────────────────────────────────────────
class _GolfDetailBody extends StatelessWidget {
  final GolfWeatherData? data;
  final GolfEvent event;
  const _GolfDetailBody({required this.data, required this.event});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const _EmptyData(message: '날씨 데이터를 불러오지 못했습니다\n서버 연결을 확인해주세요');
    return data!.aiRecommendation.status == 'GREEN'
        ? _GolfDetailA(data: data!, event: event)
        : _GolfDetailB(data: data!, event: event);
  }
}

// ── 골프 Detail A — GREEN ─────────────────────────────────────
class _GolfDetailA extends StatelessWidget {
  final GolfWeatherData data;
  final GolfEvent event;
  const _GolfDetailA({required this.data, required this.event});

  @override
  Widget build(BuildContext context) {
    final s   = _statusOf(data.aiRecommendation.status);
    final rec = data.aiRecommendation;
    final checklist = _checklist(data.forecast);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _HeroSummary(event: event, status: data.aiRecommendation.status),
        const SizedBox(height: 18),

        // AI 카드
        Container(
          width: double.infinity, padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: s.bg, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: s.border, width: 1.5)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI 라운드 추천',
              style: TextStyle(color: s.color, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(rec.message,
              style: const TextStyle(color: _T.text1, fontSize: 22, fontWeight: FontWeight.w800,
                  letterSpacing: -0.5, height: 1.3)),
            const SizedBox(height: 8),
            Text(rec.detail, style: const TextStyle(color: _T.text2, fontSize: 15, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 14),

        // 3-column 지표 카드
        if (data.forecast.isNotEmpty) _MetricRow(forecasts: data.forecast),
        if (data.forecast.isNotEmpty) const SizedBox(height: 14),

        // 시간별 예보 차트
        if (data.forecast.isNotEmpty) ...[
          _HourlyChartCard(forecasts: data.forecast),
          const SizedBox(height: 14),
        ],

        // 준비물 체크리스트
        if (checklist.isNotEmpty) ...[
          _SectionLabel('준비물 추천'),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8,
            children: checklist.map((item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _T.bgElev1, borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _T.divider)),
              child: Text(item, style: const TextStyle(color: _T.text1, fontSize: 14, fontWeight: FontWeight.w500)),
            )).toList()),
          const SizedBox(height: 14),
        ],

        _CancellationCard(policy: data.cancellationPolicy, golfzonUrl: data.golfzonBookingUrl),
        const SizedBox(height: 20),
        _PrimaryAction(label: '캘린더로 열기', onTap: () {}),
      ]),
    );
  }

  static List<String> _checklist(List<ForecastItem> f) {
    if (f.isEmpty) return [];
    final items = <String>[];
    final maxRain  = f.map((x) => x.rainProb).reduce((a, b) => a > b ? a : b);
    final maxWind  = f.map((x) => x.windSpeed).reduce((a, b) => a > b ? a : b);
    final avgSky   = f.map((x) => x.sky).reduce((a, b) => a + b) / f.length;
    final hasLight = f.any((x) => x.lightning);
    if (avgSky <= 2) { items.add('☀️ 자외선 차단제'); items.add('🧢 모자'); }
    items.add('🧤 그립 장갑');
    items.add('💧 식수 2L');
    if (maxRain >= 30) items.add('☔ 우산 또는 레인수트');
    if (maxWind >= 7)  items.add('🧥 바람막이 재킷');
    if (hasLight)      items.add('⚡ 낙뢰 시 대피 계획');
    return items;
  }
}

// ── 골프 Detail B — YELLOW / RED ──────────────────────────────
class _GolfDetailB extends StatelessWidget {
  final GolfWeatherData data;
  final GolfEvent event;
  const _GolfDetailB({required this.data, required this.event});

  @override
  Widget build(BuildContext context) {
    final s   = _statusOf(data.aiRecommendation.status);
    final rec = data.aiRecommendation;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 상태 히어로
        Container(
          width: double.infinity, padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [s.color.withValues(alpha: 0.15), _T.bgElev1],
              stops: const [0, 0.6]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: s.border, width: 1.5)),
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 84, height: 84,
                decoration: BoxDecoration(
                  color: s.color, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: s.color.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 4))]),
                alignment: Alignment.center,
                child: Text(rec.status == 'RED' ? '🚫' : '⚠️', style: const TextStyle(fontSize: 38)),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      _DdayBadge(dday: event.dday),
                      const SizedBox(width: 8),
                      Text(event.formattedDate, style: const TextStyle(color: _T.text3, fontSize: 13)),
                    ]),
                    const SizedBox(height: 6),
                    Text(event.courseName ?? event.title,
                      style: const TextStyle(color: _T.text1, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                    const SizedBox(height: 2),
                    Text(event.formattedTime, style: const TextStyle(color: _T.text3, fontSize: 13)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: s.bg, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: s.border)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 14, height: 14, margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(rec.message,
                    style: TextStyle(color: s.color, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text(rec.detail, style: const TextStyle(color: _T.text2, fontSize: 13, height: 1.5)),
                ])),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),

        // 2×2 지표 그리드
        if (data.forecast.isNotEmpty) _BigMetricGrid(forecasts: data.forecast),
        if (data.forecast.isNotEmpty) const SizedBox(height: 14),

        // 18홀 타임라인
        _HoleTimeline(forecasts: data.forecast, event: event),
        const SizedBox(height: 14),

        // 스크린골프 대안 (RED)
        if (rec.status == 'RED' && data.screenGolfNearby.isNotEmpty) ...[
          _ScreenGolfCard(suggestions: data.screenGolfNearby),
          const SizedBox(height: 14),
        ],

        _CancellationCard(policy: data.cancellationPolicy, golfzonUrl: data.golfzonBookingUrl),
        const SizedBox(height: 20),
        _PrimaryAction(
          label: rec.status == 'RED' ? '골프존에서 취소하기' : '알림 다시 받기',
          onTap: () {
            if (data.golfzonBookingUrl != null) launchUrl(Uri.parse(data.golfzonBookingUrl!));
          },
        ),
      ]),
    );
  }
}

// ── 낚시 상세 ─────────────────────────────────────────────────
class _FishingDetailBody extends StatelessWidget {
  final MarineWeatherData? data;
  final FishingEvent event;
  const _FishingDetailBody({required this.data, required this.event});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const _EmptyData(message: '해양 날씨 데이터를 불러오지 못했습니다');
    final d = data!;
    final statusStr = d.warning.departureBlocked ? 'RED' : (d.warning.hasWarning ? 'YELLOW' : 'GREEN');
    final s = _statusOf(statusStr);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 출항 상태 히어로
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: s.bg, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: s.border, width: 1.5)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _DdayBadge(dday: event.dday),
              const SizedBox(width: 8),
              Expanded(child: Text(event.title,
                style: const TextStyle(color: _T.text1, fontSize: 18, fontWeight: FontWeight.w800))),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Container(width: 14, height: 14, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(d.warning.departureBlocked ? '⛔ 출항 불가' : '✅ 출항 가능',
                style: TextStyle(color: s.color, fontSize: 18, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 6),
            Text(d.warning.message, style: const TextStyle(color: _T.text2, fontSize: 14, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 14),

        _AiCard(rec: d.aiRecommendation),
        const SizedBox(height: 14),

        // 현재 해양 상태
        _SectionLabel('현재 해양 상태'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _SmallMetricCard(icon: '🌊', value: '${d.current.waveHeight}m', label: '파고')),
          const SizedBox(width: 10),
          Expanded(child: _SmallMetricCard(icon: '💨', value: '${d.current.windSpeed}m/s', label: '풍속')),
          const SizedBox(width: 10),
          Expanded(child: _SmallMetricCard(icon: '🌡', value: '${d.current.seaTemp}°', label: '수온')),
          const SizedBox(width: 10),
          Expanded(child: _SmallMetricCard(icon: '👁', value: '${d.current.visibility}km', label: '시정')),
        ]),
        const SizedBox(height: 14),

        _TideCard(tides: d.tides, goldenTime: d.goldenTime, mainFish: d.mainFish),
        const SizedBox(height: 14),

        _BoardingCard(guide: d.safetyGuide),
        const SizedBox(height: 20),
        _PrimaryAction(label: '기상청 해양예보 보기', onTap: () {}),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 공유 컴포넌트
// ══════════════════════════════════════════════════════════════

class _HeroSummary extends StatelessWidget {
  final GolfEvent event;
  final String status;
  const _HeroSummary({required this.event, required this.status});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _DdayBadge(dday: event.dday),
        const SizedBox(width: 10),
        _StatusPill(status: status),
      ]),
      const SizedBox(height: 12),
      Text(event.courseName ?? event.title,
        style: const TextStyle(color: _T.text1, fontSize: 32, fontWeight: FontWeight.w800,
            letterSpacing: -0.8, height: 1.15)),
      const SizedBox(height: 4),
      Text('${event.formattedDate} · ${event.formattedTime}',
        style: const TextStyle(color: _T.text2, fontSize: 16)),
      if (event.location != null) ...[
        const SizedBox(height: 2),
        Text('📍 ${event.location!}', style: const TextStyle(color: _T.text3, fontSize: 14)),
      ],
    ]);
  }
}

class _DdayBadge extends StatelessWidget {
  final int dday;
  const _DdayBadge({required this.dday});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;
    if (dday == 0) {
      bg = _T.yellow; fg = const Color(0xFF1A1000); label = 'D-Day';
    } else if (dday > 0 && dday <= 2) {
      bg = _T.brand; fg = Colors.white; label = 'D-$dday';
    } else {
      bg = _T.bgElev2; fg = _T.text2; label = dday < 0 ? 'D+${dday.abs()}' : 'D-$dday';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
        style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: s.bg, borderRadius: BorderRadius.circular(999),
        border: Border.all(color: s.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(s.label, style: TextStyle(color: s.color, fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _AiCard extends StatelessWidget {
  final AiRecommendation rec;
  const _AiCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    final s = _statusOf(rec.status);
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: s.bg, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: s.border, width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('AI 추천',
          style: TextStyle(color: s.color, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(rec.message,
          style: const TextStyle(color: _T.text1, fontSize: 20, fontWeight: FontWeight.w800,
              letterSpacing: -0.4, height: 1.3)),
        const SizedBox(height: 8),
        Text(rec.detail, style: const TextStyle(color: _T.text2, fontSize: 14, height: 1.5)),
      ]),
    );
  }
}

// 3-column 지표 행 (골프 Detail A)
class _MetricRow extends StatelessWidget {
  final List<ForecastItem> forecasts;
  const _MetricRow({required this.forecasts});

  @override
  Widget build(BuildContext context) {
    final temps   = forecasts.map((f) => f.temp).toList();
    final avgTemp = temps.reduce((a, b) => a + b) / temps.length;
    final maxTemp = temps.reduce((a, b) => a > b ? a : b);
    final minTemp = temps.reduce((a, b) => a < b ? a : b);
    final avgRain = forecasts.map((f) => f.rainProb.toDouble()).reduce((a, b) => a + b) / forecasts.length;
    final avgWind = forecasts.map((f) => f.windSpeed).reduce((a, b) => a + b) / forecasts.length;
    final maxWind = forecasts.map((f) => f.windSpeed).reduce((a, b) => a > b ? a : b);

    return Row(children: [
      Expanded(child: _MetricCard(
        icon: '🌡', value: '${avgTemp.toInt()}°', label: '평균 기온',
        sub: '${minTemp.toInt()}° ~ ${maxTemp.toInt()}°')),
      const SizedBox(width: 10),
      Expanded(child: _MetricCard(
        icon: '💧', value: '${avgRain.toInt()}%', label: '강수 확률',
        sub: '${forecasts.length}시간 기준')),
      const SizedBox(width: 10),
      Expanded(child: _MetricCard(
        icon: '🌬', value: '${avgWind.toStringAsFixed(1)}m/s', label: '평균 풍속',
        sub: '최대 ${maxWind.toStringAsFixed(1)}m/s')),
    ]);
  }
}

class _MetricCard extends StatelessWidget {
  final String icon, value, label, sub;
  const _MetricCard({required this.icon, required this.value, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: _T.bgElev1, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: _T.text1, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: _T.text2, fontSize: 11, fontWeight: FontWeight.w600)),
        if (sub.isNotEmpty) ...[
          const SizedBox(height: 1),
          Text(sub, style: const TextStyle(color: _T.text3, fontSize: 10)),
        ],
      ]),
    );
  }
}

class _SmallMetricCard extends StatelessWidget {
  final String icon, value, label;
  const _SmallMetricCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: _T.bgElev1, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.divider)),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: _T.text1, fontSize: 14, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: _T.text3, fontSize: 11)),
      ]),
    );
  }
}

// 2×2 빅 지표 그리드 (골프 Detail B)
class _BigMetricGrid extends StatelessWidget {
  final List<ForecastItem> forecasts;
  const _BigMetricGrid({required this.forecasts});

  @override
  Widget build(BuildContext context) {
    final temps   = forecasts.map((f) => f.temp).toList();
    final avgTemp = temps.reduce((a, b) => a + b) / temps.length;
    final maxTemp = temps.reduce((a, b) => a > b ? a : b);
    final minTemp = temps.reduce((a, b) => a < b ? a : b);
    final maxRain = forecasts.map((f) => f.rainProb).reduce((a, b) => a > b ? a : b);
    final avgWind = forecasts.map((f) => f.windSpeed).reduce((a, b) => a + b) / forecasts.length;
    final maxWind = forecasts.map((f) => f.windSpeed).reduce((a, b) => a > b ? a : b);
    final feelsLike = avgTemp - avgWind * 0.4;

    return Column(children: [
      Row(children: [
        Expanded(child: _BigMetricCard(
          label: '평균 기온', value: '${avgTemp.toInt()}°',
          sub: '최고 ${maxTemp.toInt()}° · 최저 ${minTemp.toInt()}°', tint: _T.yellow)),
        const SizedBox(width: 12),
        Expanded(child: _BigMetricCard(
          label: '강수 확률', value: '$maxRain%',
          sub: '최대 강수확률', tint: _T.red)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _BigMetricCard(
          label: '평균 풍속', value: '${avgWind.toStringAsFixed(1)}m/s',
          sub: '최대 ${maxWind.toStringAsFixed(1)}m/s', tint: _T.yellow)),
        const SizedBox(width: 12),
        Expanded(child: _BigMetricCard(
          label: '체감 온도', value: '${feelsLike.toInt()}°',
          sub: '바람에 의한 체감', tint: _T.yellow)),
      ]),
    ]);
  }
}

class _BigMetricCard extends StatelessWidget {
  final String label, value, sub;
  final Color tint;
  const _BigMetricCard({required this.label, required this.value, required this.sub, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.bgElev1, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: _T.text2, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: _T.text1, fontSize: 34, fontWeight: FontWeight.w800,
            letterSpacing: -1, height: 1)),
        const SizedBox(height: 8),
        Row(children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: tint, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Expanded(child: Text(sub, style: const TextStyle(color: _T.text3, fontSize: 12))),
        ]),
      ]),
    );
  }
}

// ── 시간별 예보 차트 ──────────────────────────────────────────
class _HourlyChartCard extends StatelessWidget {
  final List<ForecastItem> forecasts;
  const _HourlyChartCard({required this.forecasts});

  @override
  Widget build(BuildContext context) {
    final temps = forecasts.map((f) => f.temp).toList();
    final tMin  = (temps.reduce((a, b) => a < b ? a : b) - 2).clamp(0.0, 50.0);
    final tMax  = (temps.reduce((a, b) => a > b ? a : b) + 2).clamp(0.0, 50.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: _T.bgElev1, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('시간별 예보',
            style: TextStyle(color: _T.text1, fontSize: 17, fontWeight: FontWeight.w700)),
          Text('티오프부터 ${forecasts.length}시간',
            style: const TextStyle(color: _T.text3, fontSize: 12)),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 110,
          child: CustomPaint(
            painter: _ChartPainter(forecasts: forecasts, tMin: tMin, tMax: tMax),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 8),
        Row(children: forecasts.map((f) => Expanded(
          child: Text(f.timeLabel, textAlign: TextAlign.center,
            style: const TextStyle(color: _T.text3, fontSize: 11)),
        )).toList()),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _ChartLegend(color: _T.yellow, label: '기온'),
          const SizedBox(width: 16),
          _ChartLegend(color: Color(0xAA4A9EDE), label: '강수확률'),
        ]),
      ]),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<ForecastItem> forecasts;
  final double tMin, tMax;

  _ChartPainter({required this.forecasts, required this.tMin, required this.tMax});

  @override
  void paint(Canvas canvas, Size size) {
    final n = forecasts.length;
    if (n == 0) return;
    final w = size.width;
    final h = size.height;

    // gridlines
    final gridPaint = Paint()..color = const Color(0x0FF4FBF8)..strokeWidth = 1;
    for (final p in [0.25, 0.5, 0.75]) {
      canvas.drawLine(Offset(0, p * h), Offset(w, p * h), gridPaint);
    }

    // rain bars
    final rainPaint = Paint()..color = const Color(0x594A9EDE);
    final barW = (w / n) * 0.5;
    for (var i = 0; i < n; i++) {
      final cx  = (i + 0.5) * (w / n);
      final barH = (forecasts[i].rainProb / 100.0) * h * 0.75;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx - barW / 2, h - barH, barW, barH), const Radius.circular(3)),
        rainPaint);
    }

    // temp polyline
    final range = (tMax - tMin).clamp(1.0, 100.0);
    final pts = List.generate(n, (i) {
      final x = (i + 0.5) * (w / n);
      final y = h - 5 - ((forecasts[i].temp - tMin) / range) * (h - 15);
      return Offset(x, y);
    });

    final linePaint = Paint()
      ..color = const Color(0xFFFFC107)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < pts.length; i++) path.lineTo(pts[i].dx, pts[i].dy);
    canvas.drawPath(path, linePaint);

    // dots
    final dotPaint = Paint()..color = const Color(0xFFFFC107);
    for (final pt in pts) canvas.drawCircle(pt, 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.forecasts != forecasts;
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: _T.text3, fontSize: 12)),
    ]);
  }
}

// ── 18홀 타임라인 ─────────────────────────────────────────────
class _HoleTimeline extends StatelessWidget {
  final List<ForecastItem> forecasts;
  final GolfEvent event;
  const _HoleTimeline({required this.forecasts, required this.event});

  @override
  Widget build(BuildContext context) {
    final milestones = _build();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _T.bgElev1, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('18홀 진행 예상',
          style: TextStyle(color: _T.text1, fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        ...milestones.asMap().entries.map((entry) {
          final i      = entry.key;
          final m      = entry.value;
          final isLast = i == milestones.length - 1;
          final s      = _statusOf(m.status);
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
              if (!isLast) Container(width: 2, height: 44, color: _T.divider, margin: const EdgeInsets.only(top: 4)),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(m.label, style: const TextStyle(color: _T.text1, fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(m.time, style: const TextStyle(color: _T.text2, fontSize: 13)),
                  ]),
                  const SizedBox(height: 2),
                  Text(m.wx, style: TextStyle(color: s.color, fontSize: 13, fontWeight: FontWeight.w600)),
                  if (!isLast) const SizedBox(height: 30),
                ]),
              ),
            ),
          ]);
        }),
      ]),
    );
  }

  List<_Milestone> _build() {
    final start = event.startDate;
    final offsets = [
      (Duration.zero,          '1번 홀 티오프'),
      (const Duration(hours: 2),  '전반 종료'),
      (const Duration(hours: 3),  '식사 / 후반 시작'),
      (const Duration(hours: 5),  '18번 홀 그린'),
    ];
    return offsets.map((pair) {
      final dt    = start.add(pair.$1);
      final label = pair.$2;
      final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

      ForecastItem? match;
      if (forecasts.isNotEmpty) {
        match = forecasts.reduce((a, b) {
          int hour(ForecastItem f) => f.time.length >= 2 ? int.tryParse(f.time.substring(0, 2)) ?? 0 : 0;
          return (hour(a) - dt.hour).abs() <= (hour(b) - dt.hour).abs() ? a : b;
        });
      }

      String wx = '예보 정보 없음';
      String status = 'UNKNOWN';
      if (match != null) {
        wx = '${match.skyEmoji} ${match.temp.toInt()}°  💧${match.rainProb}%';
        status = (match.lightning || match.rainProb >= 60) ? 'RED'
                 : match.rainProb >= 30 ? 'YELLOW'
                 : 'GREEN';
      }
      return _Milestone(time: timeStr, label: label, wx: wx, status: status);
    }).toList();
  }
}

class _Milestone {
  final String time, label, wx, status;
  const _Milestone({required this.time, required this.label, required this.wx, required this.status});
}

// ── 취소 정책 카드 ─────────────────────────────────────────────
class _CancellationCard extends StatelessWidget {
  final CancellationPolicy policy;
  final String? golfzonUrl;
  const _CancellationCard({required this.policy, this.golfzonUrl});

  @override
  Widget build(BuildContext context) {
    final urgencyColor = switch (policy.urgency) {
      'HIGH'     => _T.yellow,
      'CRITICAL' => _T.red,
      _          => _T.text2,
    };
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.bgElev1, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📋 취소 정책',
          style: TextStyle(color: _T.text2, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: urgencyColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: urgencyColor.withValues(alpha: 0.3))),
          child: Row(children: [
            Icon(policy.canCancelFree == true ? Icons.check_circle : Icons.warning,
              color: urgencyColor, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(policy.message,
              style: TextStyle(color: urgencyColor, fontWeight: FontWeight.w600, fontSize: 13))),
          ]),
        ),
        const SizedBox(height: 12),
        if (policy.sameDayPenalty.isNotEmpty) _PolicyRow('당일 취소', policy.sameDayPenalty),
        if (policy.noshowPenalty.isNotEmpty)   _PolicyRow('노쇼',     policy.noshowPenalty),
        if (policy.rainCancel.available) ...[
          const Divider(color: _T.divider, height: 20),
          const Row(children: [
            Text('🌧️', style: TextStyle(fontSize: 14)),
            SizedBox(width: 6),
            Text('우천 특별 정책',
              style: TextStyle(color: Color(0xFF90CAF9), fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
          const SizedBox(height: 6),
          Text(policy.rainCancel.condition, style: const TextStyle(color: _T.text3, fontSize: 13)),
          if (policy.rainCancel.refundRule.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(policy.rainCancel.refundRule, style: const TextStyle(color: _T.text3, fontSize: 13)),
          ],
        ],
        if (golfzonUrl != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse(golfzonUrl!)),
              icon: const Text('⛳', style: TextStyle(fontSize: 14)),
              label: const Text('골프존에서 직접 취소하기'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _T.text2, side: const BorderSide(color: _T.divider)),
            ),
          ),
        ],
      ]),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  final String label, value;
  const _PolicyRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 70, child: Text(label, style: const TextStyle(color: _T.text3, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(color: _T.text2, fontSize: 13))),
      ]),
    );
  }
}

// ── 스크린골프 카드 ───────────────────────────────────────────
class _ScreenGolfCard extends StatelessWidget {
  final List<ScreenGolfSuggestion> suggestions;
  const _ScreenGolfCard({required this.suggestions});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.bgElev1, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🕹️ 스크린골프 대안',
          style: TextStyle(color: _T.text2, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...suggestions.map((s) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.sports_golf, color: _T.text3),
          title: Text(s.name, style: const TextStyle(color: _T.text2)),
          subtitle: s.message != null
              ? Text(s.message!, style: const TextStyle(color: _T.text3, fontSize: 12))
              : null,
          trailing: s.searchUrl != null
              ? TextButton(
                  onPressed: () => launchUrl(Uri.parse(s.searchUrl!)),
                  child: const Text('예약', style: TextStyle(color: _T.brand)))
              : null,
        )),
      ]),
    );
  }
}

// ── 낚시 전용 카드 ────────────────────────────────────────────
class _TideCard extends StatelessWidget {
  final List<TideForecast> tides;
  final String goldenTime;
  final List<String> mainFish;
  const _TideCard({required this.tides, required this.goldenTime, required this.mainFish});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.bgElev1, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🌊 오늘 물때',
          style: TextStyle(color: _T.text2, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: _T.yellowBg, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            const Text('🐟', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text('입질 골든타임: $goldenTime',
              style: const TextStyle(color: _T.yellow, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 12),
        ...tides.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Text(t.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(t.time,
              style: const TextStyle(color: _T.text1, fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(width: 8),
            Text(t.type, style: const TextStyle(color: _T.text3, fontSize: 13)),
            const Spacer(),
            Text('${t.height}m', style: const TextStyle(color: Color(0xFF90CAF9), fontSize: 13)),
          ]),
        )),
        if (mainFish.isNotEmpty) ...[
          const Divider(color: _T.divider, height: 20),
          Text('주요 어종: ${mainFish.join(', ')}',
            style: const TextStyle(color: _T.text3, fontSize: 13)),
        ],
      ]),
    );
  }
}

class _BoardingCard extends StatelessWidget {
  final SafetyGuide guide;
  const _BoardingCard({required this.guide});

  @override
  Widget build(BuildContext context) {
    final br = guide.boardingReport;
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.bgElev1, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('🛟 ${br.title}',
          style: const TextStyle(color: _T.text2, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...br.steps.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 20, height: 20, alignment: Alignment.center,
              decoration: const BoxDecoration(color: _T.brand, shape: BoxShape.circle),
              child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 11))),
            const SizedBox(width: 10),
            Expanded(child: Text(e.value, style: const TextStyle(color: _T.text2, fontSize: 13))),
          ]),
        )),
        if (br.warning.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _T.redBg, borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _T.redBorder)),
            child: Row(children: [
              const Icon(Icons.warning_amber, color: _T.red, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(br.warning, style: const TextStyle(color: _T.red, fontSize: 12))),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ── 공통 유틸 ─────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
      style: const TextStyle(color: _T.text3, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8));
  }
}

class _PrimaryAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56, width: double.infinity,
        decoration: BoxDecoration(
          color: _T.brand, borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x662E7D6B), blurRadius: 20, offset: Offset(0, 8))]),
        alignment: Alignment.center,
        child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
      ),
    );
  }
}

class _EmptyData extends StatelessWidget {
  final String message;
  const _EmptyData({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(message,
          style: const TextStyle(color: _T.text3, height: 1.6), textAlign: TextAlign.center),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  const _ErrorBody({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(message,
          style: const TextStyle(color: _T.red), textAlign: TextAlign.center),
      ),
    );
  }
}
