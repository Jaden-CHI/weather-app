import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/golf_event.dart';
import '../models/weather_data.dart';
import '../config/app_config.dart';
import '../services/widget_sync_service.dart';
import '../services/notification_service.dart';
import '../services/share_service.dart';
import '../services/weather_api_service.dart';
import '../services/app_schedule_service.dart';
import '../widgets/wx_icon.dart';
import 'add_schedule_screen.dart';
import 'restaurant_screen.dart';
import 'scorecard_screen.dart';

class _St {
  final Color color, bg, border;
  final String label;
  const _St(
      {required this.color,
      required this.bg,
      required this.border,
      required this.label});
}

_St _statusOf(GwTheme t, String s) => switch (s) {
      'GREEN' => _St(
          color: t.success,
          bg: t.successBg,
          border: t.successBorder,
          label: '최적'),
      'YELLOW' => _St(
          color: t.warn, bg: t.warnBg, border: t.warnBorder, label: '주의'),
      'RED' => _St(
          color: t.danger,
          bg: t.dangerBg,
          border: t.dangerBorder,
          label: '취소권장'),
      _ => _St(color: t.fg3, bg: t.line, border: t.line, label: '정보없음'),
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
        _golfData = await _api.getGolfWeather(
          courseId,
          dday: event.dday.clamp(0, 7),
          startHour: event.startDate.hour,
        );
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
            startHour: event.startDate.hour,
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
    await ShareService.instance.shareGolfSchedule(
      context: context,
      event: widget.golfEvent,
      data: _golfData,
    );
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

  Future<void> _openScorecard() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScorecardScreen(event: widget.golfEvent),
      ),
    );
  }

  Future<void> _delete() async {
    final t = GwTheme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        title: Text('일정 삭제', style: TextStyle(color: t.fg)),
        content: Text('이 일정을 삭제하시겠습니까?', style: TextStyle(color: t.fg2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('취소', style: TextStyle(color: t.fg2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('삭제', style: TextStyle(color: t.danger)),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('알림 권한이 필요합니다. 설정에서 허용해주세요.')));
      }
      setState(() => _subLoading = false);
      return;
    }

    final event = widget.golfEvent;
    final courseId = _golfData?.courseId ?? event.courseId ?? '';
    final eventDate = event.startDate;
    final eventTitle = event.courseName ?? event.title;

    if (courseId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('골프장 정보를 찾을 수 없어 구독할 수 없습니다.')));
      }
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
    final t = GwTheme.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(children: [
          _DetailNav(
            title: _title,
            onBack: () => Navigator.of(context).pop(),
            onShare: !_loading ? _share : null,
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
                ? Center(child: CircularProgressIndicator(color: t.accent))
                : _error != null
                    ? _ErrorBody(message: _error!)
                    : _GolfDetailBody(
                        data: _golfData,
                        event: widget.golfEvent,
                        onScorecard: _openScorecard,
                      ),
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
    final t = GwTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(children: [
        _NavBtn(
            onTap: onBack,
            child: Text('‹',
                style: TextStyle(color: t.fg, fontSize: 24, height: 1))),
        const SizedBox(width: 12),
        Expanded(
            child: Text(title,
                style: TextStyle(
                    color: t.fg, fontSize: 17, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis)),
        if (onShare != null) ...[
          const SizedBox(width: 8),
          _NavBtn(
              onTap: onShare,
              child:
                  Icon(Icons.ios_share_outlined, color: t.fg2, size: 18)),
        ],
        if (onNotif != null) ...[
          const SizedBox(width: 8),
          subLoading
              ? SizedBox(
                  width: 38,
                  height: 38,
                  child: Center(
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: t.accent))))
              : _NavBtn(
                  onTap: onNotif,
                  child: Icon(
                      subscribed
                          ? Icons.notifications_active
                          : Icons.notifications_none_outlined,
                      color: subscribed ? t.accent : t.fg2,
                      size: 18)),
        ],
        if (onEdit != null) ...[
          const SizedBox(width: 8),
          _NavBtn(
              onTap: onEdit,
              child: Icon(Icons.edit_outlined, color: t.fg2, size: 18)),
        ],
        if (onDelete != null) ...[
          const SizedBox(width: 8),
          _NavBtn(
              onTap: onDelete,
              child: Icon(Icons.delete_outline, color: t.danger, size: 18)),
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
    final t = GwTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
            color: t.surface,
            shape: BoxShape.circle,
            border: Border.all(color: t.cardBorder)),
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
    final t = GwTheme.of(context);
    return Center(child: Text(message, style: TextStyle(color: t.danger)));
  }
}

class _GolfDetailBody extends StatelessWidget {
  final GolfWeatherData? data;
  final GolfEvent event;
  final VoidCallback? onScorecard;

  const _GolfDetailBody({
    required this.data,
    required this.event,
    this.onScorecard,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    if (data == null) {
      return _CustomGolfDetailBody(
        event: event,
        onScorecard: onScorecard,
      );
    }

    final rec = data!.aiRecommendation;
    final s = _statusOf(t, rec.status);
    final policy = data!.cancellationPolicy;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(18),
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
              Text(rec.detail, style: TextStyle(color: t.fg3, fontSize: 13)),
              if (policy.message.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(policy.message,
                    style: TextStyle(color: t.fg2, fontSize: 13)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _ScorecardEntry(event: event, onTap: onScorecard),
        const SizedBox(height: 20),
        if (data!.forecast.isNotEmpty) ...[
          Text('부킹 시간대 예보',
              style: TextStyle(
                  color: t.fg3,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2)),
          const SizedBox(height: 11),
          _ForecastTrendCard(
            forecast: data!.forecast,
            bookingTime: event.startDate,
          ),
        ],
        const SizedBox(height: 24),
        _RestaurantEntry(
          lat: event.searchLat,
          lng: event.searchLng,
          courseName: event.courseName ?? event.title,
        ),
      ],
    );
  }
}

class _RestaurantEntry extends StatelessWidget {
  final double lat;
  final double lng;
  final String courseName;

  const _RestaurantEntry({
    required this.lat,
    required this.lng,
    required this.courseName,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RestaurantScreen(
              lat: lat,
              lng: lng,
              courseName: courseName,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('근처 식당 추천',
                    style: TextStyle(
                        color: t.fg,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('조식·중식 장소를 찾아보세요',
                    style: TextStyle(color: t.fg3, fontSize: 12)),
              ],
            ),
            Icon(Icons.arrow_forward, color: t.accent),
          ],
        ),
      ),
    );
  }
}

class _CustomGolfDetailBody extends StatelessWidget {
  final GolfEvent event;
  final VoidCallback? onScorecard;
  const _CustomGolfDetailBody({
    required this.event,
    this.onScorecard,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final hasLocation = event.lat != null && event.lng != null;
    final address = event.address?.trim();
    final location = event.location ?? event.courseName ?? event.title;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: t.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('날씨 준비 중인 일정',
                  style: TextStyle(
                      color: t.fg,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                '골프장 매칭 또는 예보 캐시가 아직 준비되지 않았습니다. 일정, 지도, 식당 추천은 사용할 수 있고 날씨는 잠시 후 다시 확인해 주세요.',
                style: TextStyle(color: t.fg2, fontSize: 13, height: 1.4),
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
                Text(
                  '지도 표시가 안 되면 일정 수정에서 골프장명과 주소를 함께 입력해 주세요.',
                  style:
                      TextStyle(color: t.warn, fontSize: 12, height: 1.35),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _ScorecardEntry(event: event, onTap: onScorecard),
        const SizedBox(height: 20),
        if (hasLocation)
          _RestaurantEntry(
            lat: event.lat!,
            lng: event.lng!,
            courseName: event.courseName ?? event.title,
          ),
      ],
    );
  }
}

class _ScorecardEntry extends StatelessWidget {
  final GolfEvent event;
  final VoidCallback? onTap;

  const _ScorecardEntry({
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: t.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.accent.withValues(alpha: 0.35)),
              ),
              child: Icon(
                Icons.scoreboard_outlined,
                color: t.accent,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '스코어카드',
                    style: TextStyle(
                      color: t.fg,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '18홀 타수·퍼트·페어웨이 기록',
                    style: TextStyle(color: t.fg3, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: t.fg3, size: 16),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: t.fg3, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(color: t.fg2, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _ForecastTrendCard extends StatelessWidget {
  final List<ForecastItem> forecast;
  final DateTime bookingTime;
  const _ForecastTrendCard({
    required this.forecast,
    required this.bookingTime,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final items = _bookingWindowItems();
    if (items.isEmpty) return const SizedBox.shrink();

    final temps = items.map((e) => e.temp).toList();
    final minTemp = temps.reduce((a, b) => a < b ? a : b);
    final maxTemp = temps.reduce((a, b) => a > b ? a : b);
    final range = (maxTemp - minTemp).abs() < 0.1 ? 1.0 : maxTemp - minTemp;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_outlined, color: t.fg3, size: 15),
              const SizedBox(width: 6),
              Text(
                '부킹 ${_bookingTimeLabel()} 기준',
                style: TextStyle(color: t.fg3, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: items.map((f) {
                final normalized = ((f.temp - minTemp) / range).clamp(0.0, 1.0);
                final barHeight = 18 + (normalized * 42);
                final rainHeight = (f.rainProb / 100 * 34).clamp(4.0, 34.0);
                final isStart = _isBookingHour(f);

                return Container(
                  width: 76,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: isStart
                        ? t.accent.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isStart
                          ? t.accent.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(f.timeLabel,
                          style: TextStyle(
                              color: isStart ? t.fg : t.fg3,
                              fontSize: 12,
                              fontWeight:
                                  isStart ? FontWeight.w800 : FontWeight.w500)),
                      SizedBox(
                        height: 16,
                        child: Text(isStart ? '시작' : '',
                            style: TextStyle(
                                color: t.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w800)),
                      ),
                      SizedBox(
                        height: 26,
                        child: Center(
                          child: WxIcon.forecast(
                            sky: f.sky,
                            rainProb: f.rainProb,
                            size: 22,
                            color: isStart ? t.accent : t.fg2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 66,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 8,
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: t.accent.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('${f.temp.toInt()}°',
                          style: TextStyle(
                              color: t.fg,
                              fontSize: 15,
                              fontFamily: GwTheme.numFont,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 34,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 22,
                            height: rainHeight,
                            decoration: BoxDecoration(
                              color: f.rainProb >= 40 ? t.warn : t.sky,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('비 ${f.rainProb}%',
                          style: TextStyle(color: t.fg3, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text('${f.windSpeed.toStringAsFixed(1)}m/s',
                          style: TextStyle(color: t.fg3, fontSize: 11)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<ForecastItem> _bookingWindowItems() {
    final sorted = [...forecast]..sort((a, b) =>
        (_forecastMinutes(a) ?? 0).compareTo(_forecastMinutes(b) ?? 0));
    final bookingMinutes = bookingTime.hour * 60 + bookingTime.minute;
    final windowStart = bookingMinutes - 60;
    final windowEnd = bookingMinutes + (5 * 60);

    final window = sorted.where((f) {
      final minutes = _forecastMinutes(f);
      if (minutes == null) return false;
      return minutes >= windowStart && minutes <= windowEnd;
    }).toList();

    if (window.isNotEmpty) return window;

    sorted.sort((a, b) {
      final am = _forecastMinutes(a) ?? 0;
      final bm = _forecastMinutes(b) ?? 0;
      return (am - bookingMinutes).abs().compareTo((bm - bookingMinutes).abs());
    });
    return sorted.take(8).toList()
      ..sort((a, b) =>
          (_forecastMinutes(a) ?? 0).compareTo(_forecastMinutes(b) ?? 0));
  }

  bool _isBookingHour(ForecastItem item) {
    final minutes = _forecastMinutes(item);
    if (minutes == null) return false;
    return (minutes ~/ 60) == bookingTime.hour;
  }

  int? _forecastMinutes(ForecastItem item) {
    final raw = item.time.padLeft(4, '0');
    if (raw.length < 4) return null;
    final hour = int.tryParse(raw.substring(0, 2));
    final minute = int.tryParse(raw.substring(2, 4));
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  String _bookingTimeLabel() {
    final hour = bookingTime.hour.toString().padLeft(2, '0');
    final minute = bookingTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
