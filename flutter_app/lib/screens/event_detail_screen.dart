import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/golf_event.dart';
import '../models/weather_data.dart';
import '../services/notification_service.dart';
import '../services/share_service.dart';
import '../services/weather_api_service.dart';

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

class EventDetailScreen extends StatefulWidget {
  final GolfEvent golfEvent;

  const EventDetailScreen({super.key, required this.golfEvent});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _api   = WeatherApiService.instance;
  final _notif = NotificationService.instance;
  GolfWeatherData? _golfData;
  bool    _loading   = true;
  String? _error;
  int?    _subId;
  bool    _subLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() => _loading = true);
    try {
      final event = widget.golfEvent;
      String? courseId = event.courseId;
      courseId ??= await _api.searchCourseId(event.courseName ?? event.title);
      if (courseId != null) {
        _golfData = await _api.getGolfWeather(courseId, dday: event.dday.clamp(0, 7));
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _share() async {
    if (_golfData != null) {
      await ShareService.instance.shareGolfWeather(context: context, event: widget.golfEvent, data: _golfData!);
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

    final event = widget.golfEvent;
    final courseId = _golfData?.courseId ?? event.courseId ?? '';
    final eventDate  = event.startDate;
    final eventTitle = event.courseName ?? event.title;

    if (courseId.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('골프장 정보를 찾을 수 없어 구독할 수 없습니다.')));
      setState(() => _subLoading = false);
      return;
    }

    final id = await _notif.subscribeToEvent(
      activityType: 'GOLF', targetId: courseId,
      eventDate: eventDate, eventTitle: eventTitle);

    if (mounted) {
      setState(() { _subId = id; _subLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(id != null ? '날씨 변화 알림을 등록했습니다.' : '알림 등록에 실패했습니다.')));
    }
  }

  String get _title => widget.golfEvent.courseName ?? widget.golfEvent.title;

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
                    : _GolfDetailBody(data: _golfData, event: widget.golfEvent),
          ),
        ]),
      ),
    );
  }
}

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

class _ErrorBody extends StatelessWidget {
  final String message;
  const _ErrorBody({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message, style: const TextStyle(color: _T.red)));
  }
}

class _GolfDetailBody extends StatelessWidget {
  final GolfWeatherData? data;
  final GolfEvent event;

  const _GolfDetailBody({required this.data, required this.event});

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Center(
        child: Text('날씨 데이터를 불러오지 못했습니다', style: TextStyle(color: _T.text2)));
    }

    final rec = data!.aiRecommendation;
    final s = _statusOf(rec.status);
    final policy = data!.cancellationPolicy;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _T.bgElev1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: s.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rec.message,
                style: TextStyle(color: s.color, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(rec.detail, style: const TextStyle(color: _T.text3, fontSize: 13)),
              if (policy.message.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(policy.message, style: const TextStyle(color: _T.text2, fontSize: 13)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (data!.forecast.isNotEmpty) ...[
          const Text('시간대별 예보', style: TextStyle(color: _T.text1, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...data!.forecast.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(width: 50, child: Text(f.timeLabel, style: const TextStyle(color: _T.text2, fontSize: 12))),
                Text(f.skyEmoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                SizedBox(width: 40, child: Text('${f.temp.toInt()}°', style: const TextStyle(color: _T.text1, fontSize: 13, fontWeight: FontWeight.w700))),
                SizedBox(width: 60, child: Text('강수 ${f.rainProb}%', style: const TextStyle(color: _T.text3, fontSize: 12))),
                Expanded(child: Text('바람 ${f.windSpeed.toStringAsFixed(1)}m/s', style: const TextStyle(color: _T.text3, fontSize: 12))),
              ],
            ),
          )),
        ],
      ],
    );
  }
}
