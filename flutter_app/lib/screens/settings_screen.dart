import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../services/app_schedule_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const BackButton(color: Colors.white),
        title: const Text('설정', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionHeader('알림 임계값'),
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
                      const Divider(color: Colors.white12, height: 24),
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
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                _SectionHeader('알림 타이밍'),
                _SettingsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '일정 몇 시간 전부터 알림을 받을까요?',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [6, 12, 24, 48].map((h) {
                          final selected = _notifyHoursBefore == h;
                          return ChoiceChip(
                            label: Text('$h시간 전'),
                            selected: selected,
                            selectedColor: const Color(0xFF2E7D6B),
                            backgroundColor: const Color(0xFF243447),
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.white54,
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

                const SizedBox(height: 16),
                _SectionHeader('알림 권한'),
                _SettingsCard(
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
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
                      icon: const Icon(Icons.notifications),
                      label: const Text('알림 권한 요청 / 재등록'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                _SectionHeader('테스트 데이터'),
                _SettingsCard(
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await AppScheduleService().addGolfSchedule(
                            title: '테스트 라운드',
                            locationName: '레이크사이드CC',
                            lat: 37.5665,
                            lng: 126.9780,
                            startAt: DateTime.now().add(const Duration(days: 3)),
                            notifyBeforeHours: 24,
                            weatherAlertEnabled: true,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('테스트 일정이 추가되었습니다!')),
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
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('테스트 일정 추가'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                _SectionHeader('디바이스 정보'),
                _SettingsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '익명 디바이스 토큰',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        _userToken ?? '로딩 중...',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '이 앱은 개인정보를 수집하지 않습니다. 위 토큰은 알림 발송에만 사용되는 임의 식별자입니다.',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2B3A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            Text(
              '${value % 1 == 0 ? value.toInt() : value.toStringAsFixed(1)} $unit',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF2E7D6B),
            thumbColor: const Color(0xFF2E7D6B),
            inactiveTrackColor: Colors.white12,
            overlayColor: const Color(0xFF2E7D6B).withOpacity(0.2),
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
