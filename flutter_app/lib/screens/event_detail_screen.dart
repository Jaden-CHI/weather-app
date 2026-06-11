import 'package:flutter/material.dart';
import '../models/golf_event.dart';
import '../models/weather_data.dart';
import '../config/app_config.dart';
import '../services/widget_sync_service.dart';
import '../services/notification_service.dart';
import '../services/share_service.dart';
import '../services/weather_api_service.dart';
import '../services/app_schedule_service.dart';
import 'add_schedule_screen.dart';
import 'restaurant_screen.dart';

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

class _St {
  final Color color, bg, border;
  final String label;
  const _St(
      {required this.color,
      required this.bg,
      required this.border,
      required this.label});
}

_St _statusOf(String s) => switch (s) {
      'GREEN' => const _St(
          color: _T.green, bg: _T.greenBg, border: _T.greenBorder, label: '최적'),
      'YELLOW' => const _St(
          color: _T.yellow,
          bg: _T.yellowBg,
          border: _T.yellowBorder,
          label: '주의'),
      'RED' => const _St(
          color: _T.red, bg: _T.redBg, border: _T.redBorder, label: '취소권장'),
      _ => const _St(
          color: _T.text3, bg: _T.divider, border: _T.divider, label: '정보없음'),
    };

class EventDetailScreen extends StatefulWidget {
  final GolfEvent golfEvent;

  const EventDetailScreen({super.key, required this.golfEvent});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _api = WeatherApiService.instance;
  final _notif = NotificationService.instance;
  GolfWeatherData? _golfData;
  bool _loading = true;
  String? _error;
  int? _subId;
  bool _subLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var event = widget.golfEvent;
      String? courseId = event.courseId;
      courseId ??= await _api.searchCourseId(event.courseName ?? event.title);

      if (courseId != null && courseId.isNotEmpty) {
        _golfData =
            await _api.getGolfWeather(courseId, dday: event.dday.clamp(0, 7));
      } else {
        double? lat = event.lat;
        double? lng = event.lng;

        if (lat == null || lng == null) {
          final geocoded = await _api.geocodeBestEffort(
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
          _golfData = await _api.getCustomGolfWeather(
            lat: lat,
            lng: lng,
            courseName: event.courseName ?? event.location ?? event.title,
            dday: event.dday.clamp(0, 7),
          );
        } else {
          _golfData = null;
        }
      }

      if (_golfData != null) {
        await WidgetSyncService.instance.syncNextGolfEvent();
      }
    } catch (e) {
      _error = AppConfig.weatherUnavailableMessage;
      debugPrint('Weather error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _share() async {
    if (_golfData != null) {
      await ShareService.instance.shareGolfWeather(
          context: context, event: widget.golfEvent, data: _golfData!);
    }
  }

  Future<void> _edit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => AddScheduleScreen(editingEvent: widget.golfEvent)),
    );
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _T.bgElev1,
        title: const Text('일정 삭제', style: TextStyle(color: _T.text1)),
        content:
            const Text('이 일정을 삭제하시겠습니까?', style: TextStyle(color: _T.text2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: _T.text2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: _T.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AppScheduleService().deleteSchedule(widget.golfEvent.id);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('오류: $e')));
        }
      }
    }
  }

  Future<void> _toggleSubscription() async {
    if (_subLoading) return;
    setState(() => _subLoading = true);
    if (_subId != null) {
      setState(() => _subLoading = false);
      return;
    }

    final granted = await _notif.requestPermissionAndRegister();
    if (!granted) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('알림 권한이 필요합니다. 설정에서 허용해주세요.')));
      setState(() => _subLoading = false);
      return;
    }

    final event = widget.golfEvent;
    final courseId = _golfData?.courseId ?? event.courseId ?? '';
    final eventDate = event.startDate;
    final eventTitle = event.courseName ?? event.title;

    if (courseId.isEmpty) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('골프장 정보를 찾을 수 없어 구독할 수 없습니다.')));
      setState(() => _subLoading = false);
      return;
    }

    final id = await _notif.subscribeToEvent(
        activityType: 'GOLF',
        targetId: courseId,
        eventDate: eventDate,
        eventTitle: eventTitle);

    if (mounted) {
      setState(() {
        _subId = id;
        _subLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(id != null ? '날씨 변화 알림을 등록했습니다.' : '알림 등록에 실패했습니다.')));
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
            onShare: (!_loading && _golfData != null) ? _share : null,
            onNotif: (!_loading &&
                    _golfData != null &&
                    _golfData!.courseId != 'CUSTOM')
                ? _toggleSubscription
                : null,
            onEdit: !_loading ? _edit : null,
            onDelete: !_loading ? _delete : null,
            subscribed: _subId != null,
            subLoading: _subLoading,
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _T.brand))
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
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool subscribed;
  final bool subLoading;

  const _DetailNav({
    required this.title,
    required this.onBack,
    this.onShare,
    this.onNotif,
    this.onEdit,
    this.onDelete,
    this.subscribed = false,
    this.subLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(children: [
        _NavBtn(
            onTap: onBack,
            child: const Text('‹',
                style: TextStyle(color: _T.text1, fontSize: 24, height: 1))),
        const SizedBox(width: 12),
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: _T.text1, fontSize: 17, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis)),
        if (onShare != null) ...[
          const SizedBox(width: 8),
          _NavBtn(
              onTap: onShare,
              child: const Icon(Icons.ios_share_outlined,
                  color: _T.text2, size: 18)),
        ],
        if (onNotif != null) ...[
          const SizedBox(width: 8),
          subLoading
              ? const SizedBox(
                  width: 38,
                  height: 38,
                  child: Center(
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _T.brand))))
              : _NavBtn(
                  onTap: onNotif,
                  child: Icon(
                      subscribed
                          ? Icons.notifications_active
                          : Icons.notifications_none_outlined,
                      color: subscribed ? _T.brand : _T.text2,
                      size: 18)),
        ],
        if (onEdit != null) ...[
          const SizedBox(width: 8),
          _NavBtn(
              onTap: onEdit,
              child:
                  const Icon(Icons.edit_outlined, color: _T.text2, size: 18)),
        ],
        if (onDelete != null) ...[
          const SizedBox(width: 8),
          _NavBtn(
              onTap: onDelete,
              child: const Icon(Icons.delete_outline, color: _T.red, size: 18)),
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
        width: 38,
        height: 38,
        decoration: BoxDecoration(
            color: _T.bgElev1,
            shape: BoxShape.circle,
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
      return _CustomGolfDetailBody(event: event);
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
                  style: TextStyle(
                      color: s.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(rec.detail,
                  style: const TextStyle(color: _T.text3, fontSize: 13)),
              if (policy.message.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(policy.message,
                    style: const TextStyle(color: _T.text2, fontSize: 13)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (data!.forecast.isNotEmpty) ...[
          const Text('시간대별 예보',
              style: TextStyle(
                  color: _T.text1, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _ForecastTrendCard(forecast: data!.forecast),
        ],
        const SizedBox(height: 24),
        // 식당 추천 섹션
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RestaurantScreen(
                  lat: event.searchLat,
                  lng: event.searchLng,
                  courseName: event.courseName ?? event.title,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _T.bgElev1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _T.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🍽️ 근처 식당 추천',
                        style: TextStyle(
                            color: _T.text1,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('조식·중식 장소를 찾아보세요',
                        style: TextStyle(color: _T.text3, fontSize: 12)),
                  ],
                ),
                Icon(Icons.arrow_forward, color: _T.text2),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomGolfDetailBody extends StatelessWidget {
  final GolfEvent event;
  const _CustomGolfDetailBody({required this.event});

  @override
  Widget build(BuildContext context) {
    final hasLocation = event.lat != null && event.lng != null;
    final address = event.address?.trim();
    final location = event.location ?? event.courseName ?? event.title;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _T.bgElev1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _T.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('커스텀 골프장 일정',
                  style: TextStyle(
                      color: _T.text1,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                'DB에 등록되지 않은 골프장이라 날씨 위험 알림은 제공되지 않지만, 일정과 지도 위치는 사용할 수 있습니다.',
                style: TextStyle(color: _T.text2, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              _InfoLine(
                  icon: Icons.calendar_today_outlined,
                  text: '${event.formattedDate} · ${event.formattedTime}'),
              const SizedBox(height: 8),
              _InfoLine(
                  icon: Icons.place_outlined,
                  text: address?.isNotEmpty == true ? address! : location),
              if (!hasLocation) ...[
                const SizedBox(height: 12),
                const Text(
                  '지도 표시가 안 되면 일정 수정에서 골프장명과 주소를 함께 입력해 주세요.',
                  style:
                      TextStyle(color: _T.yellow, fontSize: 12, height: 1.35),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (hasLocation)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RestaurantScreen(
                    lat: event.lat!,
                    lng: event.lng!,
                    courseName: event.courseName ?? event.title,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _T.bgElev1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _T.divider),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('근처 식당 추천',
                          style: TextStyle(
                              color: _T.text1,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('조식·중식 장소를 찾아보세요',
                          style: TextStyle(color: _T.text3, fontSize: 12)),
                    ],
                  ),
                  Icon(Icons.arrow_forward, color: _T.text2),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _T.text3, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: _T.text2, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _ForecastTrendCard extends StatelessWidget {
  final List<ForecastItem> forecast;
  const _ForecastTrendCard({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final items = forecast.take(24).toList();
    final temps = items.map((e) => e.temp).toList();
    final minTemp = temps.reduce((a, b) => a < b ? a : b);
    final maxTemp = temps.reduce((a, b) => a > b ? a : b);
    final range = (maxTemp - minTemp).abs() < 0.1 ? 1.0 : maxTemp - minTemp;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: _T.bgElev1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.divider),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items.map((f) {
            final normalized = ((f.temp - minTemp) / range).clamp(0.0, 1.0);
            final barHeight = 18 + (normalized * 42);
            final rainHeight = (f.rainProb / 100 * 34).clamp(4.0, 34.0);

            return SizedBox(
              width: 72,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(f.timeLabel,
                      style: const TextStyle(color: _T.text3, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(f.skyEmoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 66,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 8,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: _T.green.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('${f.temp.toInt()}°',
                      style: const TextStyle(
                          color: _T.text1,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 34,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 22,
                        height: rainHeight,
                        decoration: BoxDecoration(
                          color: f.rainProb >= 40 ? _T.yellow : _T.brand,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('비 ${f.rainProb}%',
                      style: const TextStyle(color: _T.text3, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text('${f.windSpeed.toStringAsFixed(1)}m/s',
                      style: const TextStyle(color: _T.text3, fontSize: 11)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
