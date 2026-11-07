import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../config/locale_provider.dart';
import '../l10n/l10n.dart';
import '../services/notification_service.dart';
import '../services/round_suitability.dart';
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
  final _sensitivities = <String, WeatherSensitivity>{
    'rain': WeatherSensitivity.normal,
    'wind': WeatherSensitivity.normal,
    'cold': WeatherSensitivity.normal,
    'heat': WeatherSensitivity.normal,
  };

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
    for (final dim in _sensitivities.keys.toList()) {
      _sensitivities[dim] =
          WeatherSensitivity.byId(await _settings.getWeatherSensitivity(dim));
    }
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

  Future<void> _setSensitivity(String dim, WeatherSensitivity s) async {
    setState(() => _sensitivities[dim] = s);
    await _settings.setWeatherSensitivity(dim, s.id);
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final l10n = context.l10n;
    final current = ref.watch(gwThemeProvider);
    final language = ref.watch(appLanguageProvider);

    return _loading
        ? Center(child: CircularProgressIndicator(color: t.accent))
        : ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 0, 22),
                child: Text(l10n.setTitle,
                    style: TextStyle(
                        color: t.fg,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4)),
              ),
              _SectionHeader(l10n.setLanguageSection),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final option in const [
                      ('system', null),
                      ('ko', '한국어'),
                      ('en', 'English'),
                    ]) ...[
                      _LanguageOption(
                        label: option.$2 ?? l10n.setLanguageSystem,
                        selected: language == option.$1,
                        onTap: () => ref
                            .read(appLanguageProvider.notifier)
                            .set(option.$1),
                      ),
                      if (option.$1 != 'en')
                        Divider(color: t.line, height: 4),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(l10n.setSectionTheme),
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
              _SectionHeader(l10n.setSectionThresholds),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SliderRow(
                      label: l10n.setRainThresholdLabel,
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
                      label: l10n.setWindThresholdLabel,
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
                      l10n.setThresholdHint,
                      style: TextStyle(color: t.fg3, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(l10n.setSectionRoundProfile),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SensitivityRow(
                      icon: Icons.water_drop_outlined,
                      label: l10n.setSensitivityRain,
                      value: _sensitivities['rain']!,
                      onChanged: (s) => _setSensitivity('rain', s),
                    ),
                    Divider(color: t.line, height: 22),
                    _SensitivityRow(
                      icon: Icons.air_rounded,
                      label: l10n.setSensitivityWind,
                      value: _sensitivities['wind']!,
                      onChanged: (s) => _setSensitivity('wind', s),
                    ),
                    Divider(color: t.line, height: 22),
                    _SensitivityRow(
                      icon: Icons.ac_unit_rounded,
                      label: l10n.setSensitivityCold,
                      value: _sensitivities['cold']!,
                      onChanged: (s) => _setSensitivity('cold', s),
                    ),
                    Divider(color: t.line, height: 22),
                    _SensitivityRow(
                      icon: Icons.wb_sunny_outlined,
                      label: l10n.setSensitivityHeat,
                      value: _sensitivities['heat']!,
                      onChanged: (s) => _setSensitivity('heat', s),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.setSensitivityHint,
                      style: TextStyle(color: t.fg3, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(l10n.setSectionNotifyTiming),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.setNotifyTimingQuestion,
                      style: TextStyle(color: t.fg2, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [6, 12, 24, 48].map((h) {
                        final selected = _notifyHoursBefore == h;
                        return ChoiceChip(
                          label: Text(l10n.setHoursBefore(h)),
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
              _SectionHeader(l10n.setSectionNotifyPermission),
              _SettingsCard(
                child: SizedBox(
                  width: double.infinity,
                  child: _OutlineActionButton(
                    icon: Icons.notifications_outlined,
                    label: l10n.setNotifyPermissionButton,
                    onPressed: () async {
                      final granted = await NotificationService.instance
                          .requestPermissionAndRegister();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            granted
                                ? context.l10n.setNotifyGranted
                                : context.l10n.setNotifyDenied,
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
              _SectionHeader(l10n.setSectionHelp),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.setHelpDesc,
                      style: TextStyle(color: t.fg2, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _OutlineActionButton(
                        icon: Icons.play_circle_outline,
                        label: l10n.setHelpTutorialButton,
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
              _SectionHeader(l10n.setSectionScore),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.setScoreDesc,
                      style: TextStyle(color: t.fg2, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _OutlineActionButton(
                        icon: Icons.scoreboard_outlined,
                        label: l10n.setScoreOpenButton,
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
              _SectionHeader(l10n.setSectionDevice),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.setDeviceTokenLabel,
                      style: TextStyle(color: t.fg3, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      _userToken ?? l10n.setDeviceTokenLoading,
                      style: TextStyle(
                        color: t.fg2,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.setDevicePrivacyNote,
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

  String _localizedSubtitle(BuildContext context) => switch (theme.id) {
        'light_air' => context.l10n.themeSubtitleLightAir,
        'midnight_lime' => context.l10n.themeSubtitleMidnightLime,
        _ => context.l10n.themeSubtitleFairwaySky,
      };

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
                  Text(_localizedSubtitle(context),
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

// ── 언어 선택 행 ────────────────────────────────────────────────
class _LanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? t.fg : t.fg2,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, color: t.accent, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── 라운드 성향 민감도 선택 행 ─────────────────────────────────
class _SensitivityRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final WeatherSensitivity value;
  final ValueChanged<WeatherSensitivity> onChanged;

  const _SensitivityRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: t.fg2),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
                color: t.fg, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: t.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: t.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: WeatherSensitivity.values.map((s) {
              final selected = s == value;
              return GestureDetector(
                onTap: () => onChanged(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? t.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    s.label,
                    style: TextStyle(
                      color: selected ? t.accentInk : t.fg2,
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
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
