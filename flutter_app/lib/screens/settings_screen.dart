import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../services/app_schedule_service.dart';
import 'release_qa_screen.dart';
import 'score_history_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onOpenTutorial;

  const SettingsScreen({
    super.key,
    this.onOpenTutorial,
  });

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _settings = SettingsService.instance;

  int _rainThreshold = 60;
  double _windThreshold = 10.0;
  int _notifyHoursBefore = 24;
  bool _loading = true;
  String? _userToken;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rain = await _settings.getRainThreshold();
    final wind = await _settings.getWindThreshold();
    final hours = await _settings.getNotifyHoursBefore();
    final token = await NotificationService.instance.userToken;
    if (mounted) {
      setState(() {
        _rainThreshold = rain;
        _windThreshold = wind;
        _notifyHoursBefore = hours;
        _userToken = token;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final current = ref.watch(gwThemeProvider);

    return _loading
        ? Center(child: CircularProgressIndicator(color: t.accent))
        : ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 0, 22),
                child: Text('설정',
                    style: TextStyle(
                        color: t.fg,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4)),
              ),
              const _SectionHeader('테마 · THEME'),
              ...GwTheme.all.map(
                (theme) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: _ThemeCard(
                    theme: theme,
                    selected: theme.id == current.id,
                    onTap: () =>
                        ref.read(gwThemeProvider.notifier).select(theme),
                  ),
                ),
              ),
              const SizedBox(height: 13),
              const _SectionHeader('알림 임계값'),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SliderRow(
                      label: '강수 확률 기준',
                      value: _rainThreshold.toDouble(),
                      min: 10,
                      max: 90,
                      divisions: 8,
                      unit: '%',
                      onChanged: (v) async {
                        setState(() => _rainThreshold = v.toInt());
                        await _settings.setRainThreshold(v.toInt());
                      },
                    ),
                    Divider(color: t.line, height: 24),
                    _SliderRow(
                      label: '풍속 기준',
                      value: _windThreshold,
                      min: 3,
                      max: 20,
                      divisions: 17,
                      unit: 'm/s',
                      onChanged: (v) async {
                        setState(() => _windThreshold = v);
                        await _settings.setWindThreshold(v);
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '이 임계값 초과 시 YELLOW/RED 권고가 발령됩니다',
                      style: TextStyle(color: t.fg3, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SectionHeader('알림 타이밍'),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '일정 몇 시간 전부터 알림을 받을까요?',
                      style: TextStyle(color: t.fg2, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [6, 12, 24, 48].map((h) {
                        final selected = _notifyHoursBefore == h;
                        return ChoiceChip(
                          label: Text('$h시간 전'),
                          selected: selected,
                          showCheckmark: false,
                          selectedColor: t.accent,
                          backgroundColor: t.surface2,
                          labelStyle: TextStyle(
                            color: selected ? t.accentInk : t.fg2,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: selected ? t.accent : t.line,
                          ),
                          onSelected: (_) async {
                            setState(() => _notifyHoursBefore = h);
                            await _settings.setNotifyHoursBefore(h);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SectionHeader('알림 권한'),
              _SettingsCard(
                child: SizedBox(
                  width: double.infinity,
                  child: _OutlineActionButton(
                    icon: Icons.notifications_outlined,
                    label: '알림 권한 요청 / 재등록',
                    onPressed: () async {
                      final granted = await NotificationService.instance
                          .requestPermissionAndRegister();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            granted ? '알림 권한이 허용되었습니다.' : '알림 권한이 거부되었습니다.',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 24),
                const _SectionHeader('테스트 데이터'),
                _SettingsCard(
                  child: SizedBox(
                    width: double.infinity,
                    child: _OutlineActionButton(
                      icon: Icons.calendar_today_outlined,
                      label: '테스트 일정 추가',
                      onPressed: () async {
                        try {
                          await AppScheduleService().addGolfSchedule(
                            title: '테스트 라운드',
                            locationName: '레이크사이드CC',
                            lat: 37.5665,
                            lng: 126.9780,
                            startAt:
                                DateTime.now().add(const Duration(days: 3)),
                            notifyBeforeHours: 24,
                            weatherAlertEnabled: true,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('테스트 일정이 추가되었습니다!'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('오류: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const _SectionHeader('도움말'),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '핵심 기능 안내를 다시 열 수 있습니다.',
                      style: TextStyle(color: t.fg2, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _OutlineActionButton(
                        icon: Icons.play_circle_outline,
                        label: '튜토리얼 다시 보기',
                        onPressed: widget.onOpenTutorial,
                      ),
                    ),
                  ],
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 24),
                const _SectionHeader('출시 전 점검'),
                _SettingsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '지도, OCR, 일정, 날씨, 식당 추천 흐름을 한 번에 확인합니다.',
                        style: TextStyle(color: t.fg2, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: _OutlineActionButton(
                          icon: Icons.fact_check_outlined,
                          label: 'QA 체크 열기',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ReleaseQaScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const _SectionHeader('스코어'),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OCR 스캔과 지난 라운드 기록 관리를 여기서 바로 열 수 있습니다.',
                      style: TextStyle(color: t.fg2, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _OutlineActionButton(
                        icon: Icons.scoreboard_outlined,
                        label: '스코어 관리 열기',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ScoreHistoryScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SectionHeader('디바이스 정보'),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '익명 디바이스 토큰',
                      style: TextStyle(color: t.fg3, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      _userToken ?? '로딩 중...',
                      style: TextStyle(
                        color: t.fg2,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '이 앱은 개인정보를 수집하지 않습니다. 위 토큰은 알림 발송에만 사용되는 임의 식별자입니다.',
                      style: TextStyle(color: t.fg3, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          );
  }
}

// ── 테마 선택 카드 ─────────────────────────────────────────────
class _ThemeCard extends StatelessWidget {
  final GwTheme theme;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? t.accent : t.cardBorder,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              height: 22,
              child: Stack(
                children: [
                  for (var i = 0; i < theme.swatch.length; i++)
                    Positioned(
                      left: i * 14.0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: theme.swatch[i],
                          shape: BoxShape.circle,
                          border: Border.all(color: t.surface, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(theme.name,
                      style: TextStyle(
                          color: t.fg,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(theme.subtitle,
                      style: TextStyle(color: t.fg3, fontSize: 12)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_rounded, color: t.accent, size: 22),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Text(
        title,
        style: TextStyle(
          color: t.fg3,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.cardBorder),
      ),
      child: child,
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _OutlineActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: t.fg2,
        side: BorderSide(color: t.line),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String unit;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: t.fg2, fontSize: 14)),
            Text(
              '${value % 1 == 0 ? value.toInt() : value.toStringAsFixed(1)} $unit',
              style: TextStyle(
                color: t.fg,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: t.accent,
            thumbColor: t.accent,
            inactiveTrackColor: t.line,
            overlayColor: t.accent.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
