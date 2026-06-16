import 'package:flutter/material.dart';

import '../models/golf_event.dart';
import '../models/golf_score.dart';
import '../services/scorecard_service.dart';

class ScorecardScreen extends StatefulWidget {
  final GolfEvent event;

  const ScorecardScreen({
    super.key,
    required this.event,
  });

  @override
  State<ScorecardScreen> createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen> {
  GolfRoundScore? _score;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    final score =
        await ScorecardService.instance.getOrCreateScore(widget.event);
    if (!mounted) return;
    setState(() {
      _score = score;
      _loading = false;
    });
  }

  Future<void> _saveScore() async {
    final score = _score;
    if (score == null || _saving) return;

    setState(() => _saving = true);
    try {
      await ScorecardService.instance.saveScore(score);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('스코어카드를 저장했습니다.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장하지 못했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _updateHole(int index, HoleScore hole) {
    final current = _score;
    if (current == null) return;

    final holes = [...current.holes];
    holes[index] = hole;
    setState(() {
      _score = current.copyWith(holes: holes, updatedAt: DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final score = _score;

    return Scaffold(
      backgroundColor: _ScoreColors.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            _ScoreNav(
              title: widget.event.courseName ??
                  widget.event.location ??
                  widget.event.title,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: _loading || score == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: _ScoreColors.brand,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
                      children: [
                        _RoundSummary(score: score),
                        const SizedBox(height: 14),
                        ...List.generate(score.holes.length, (index) {
                          final hole = score.holes[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _HoleScoreCard(
                              hole: hole,
                              onChanged: (updated) =>
                                  _updateHole(index, updated),
                            ),
                          );
                        }),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          decoration: const BoxDecoration(
            color: _ScoreColors.bgDeep,
            border: Border(
              top: BorderSide(color: _ScoreColors.divider),
            ),
          ),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _ScoreColors.mint,
                foregroundColor: const Color(0xFF09241F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _loading || _saving ? null : _saveScore,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _saving ? '저장 중' : '스코어 저장',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreNav extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _ScoreNav({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          _RoundIconButton(
            onTap: onBack,
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: _ScoreColors.text1,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '스코어카드',
                  style: TextStyle(
                    color: _ScoreColors.text3,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ScoreColors.text1,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundSummary extends StatelessWidget {
  final GolfRoundScore score;

  const _RoundSummary({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _ScoreColors.bgElev1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ScoreColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: '총타',
                  value: '${score.totalScore}',
                  accent: true,
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  label: '스코어',
                  value: score.overParLabel,
                  accent: true,
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  label: '퍼트',
                  value: '${score.totalPutts}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TinyMetric(
                  label: '페어웨이',
                  value: _percent(score.fairwayRate),
                ),
              ),
              Expanded(
                child: _TinyMetric(
                  label: 'GIR',
                  value: _percent(score.girRate),
                ),
              ),
              Expanded(
                child: _TinyMetric(
                  label: 'OB/벌타',
                  value: '${score.obCount}/${score.penaltyCount}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _percent(double value) => '${(value * 100).round()}%';
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;

  const _SummaryMetric({
    required this.label,
    required this.value,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: _ScoreColors.text3, fontSize: 12),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: accent ? _ScoreColors.yellow : _ScoreColors.text1,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _TinyMetric extends StatelessWidget {
  final String label;
  final String value;

  const _TinyMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: _ScoreColors.bgElev2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _ScoreColors.text3, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ScoreColors.text1,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HoleScoreCard extends StatelessWidget {
  final HoleScore hole;
  final ValueChanged<HoleScore> onChanged;

  const _HoleScoreCard({
    required this.hole,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ScoreColors.bgElev1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _ScoreColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _ScoreColors.brand,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${hole.holeNumber}H',
                  style: const TextStyle(
                    color: _ScoreColors.text1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Par ${hole.par} · ${_scoreLabel(hole.overPar)}',
                  style: const TextStyle(
                    color: _ScoreColors.text1,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _MiniStepper(
                value: hole.par,
                min: 3,
                max: 5,
                onChanged: (value) {
                  final strokes = hole.strokes < value ? value : hole.strokes;
                  onChanged(hole.copyWith(par: value, strokes: strokes));
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _LabeledStepper(
                  label: '타수',
                  value: hole.strokes,
                  min: 1,
                  max: 12,
                  onChanged: (value) => onChanged(
                    hole.copyWith(strokes: value),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LabeledStepper(
                  label: '퍼트',
                  value: hole.putts,
                  min: 0,
                  max: 6,
                  onChanged: (value) => onChanged(
                    hole.copyWith(putts: value),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FairwaySelector(
            value: hole.fairway,
            enabled: hole.par != 3,
            onChanged: (value) => onChanged(hole.copyWith(fairway: value)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TogglePill(
                  label: 'OB',
                  selected: hole.ob,
                  onTap: () => onChanged(hole.copyWith(ob: !hole.ob)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LabeledStepper(
                  label: '벌타',
                  value: hole.penalty,
                  min: 0,
                  max: 6,
                  onChanged: (value) => onChanged(
                    hole.copyWith(penalty: value),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _scoreLabel(int overPar) {
    if (overPar == 0) return 'E';
    if (overPar > 0) return '+$overPar';
    return '$overPar';
  }
}

class _LabeledStepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _LabeledStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _ScoreColors.bgElev2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ScoreColors.text1,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _SmallIconButton(
            icon: Icons.remove,
            enabled: value > min,
            onTap: () => onChanged(value - 1),
          ),
          _SmallIconButton(
            icon: Icons.add,
            enabled: value < max,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _MiniStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _MiniStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SmallIconButton(
          icon: Icons.remove,
          enabled: value > min,
          onTap: () => onChanged(value - 1),
        ),
        _SmallIconButton(
          icon: Icons.add,
          enabled: value < max,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _SmallIconButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.only(left: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? _ScoreColors.brand : _ScoreColors.divider,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: enabled ? _ScoreColors.text1 : _ScoreColors.text3,
          size: 16,
        ),
      ),
    );
  }
}

class _FairwaySelector extends StatelessWidget {
  final FairwayResult value;
  final bool enabled;
  final ValueChanged<FairwayResult> onChanged;

  const _FairwaySelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = enabled ? value : FairwayResult.notApplicable;
    return Row(
      children: [
        const SizedBox(
          width: 64,
          child: Text(
            '페어웨이',
            style: TextStyle(
              color: _ScoreColors.text3,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: SegmentedButton<FairwayResult>(
            segments: const [
              ButtonSegment(
                value: FairwayResult.hit,
                label: Text('성공'),
              ),
              ButtonSegment(
                value: FairwayResult.miss,
                label: Text('실패'),
              ),
              ButtonSegment(
                value: FairwayResult.notApplicable,
                label: Text('-'),
              ),
            ],
            selected: {selected},
            showSelectedIcon: false,
            onSelectionChanged:
                enabled ? (values) => onChanged(values.first) : null,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return _ScoreColors.mint;
                }
                return _ScoreColors.bgElev2;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF09241F);
                }
                return _ScoreColors.text2;
              }),
              side: WidgetStateProperty.all(
                const BorderSide(color: _ScoreColors.divider),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TogglePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TogglePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? _ScoreColors.redBg : _ScoreColors.bgElev2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _ScoreColors.redBorder : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? _ScoreColors.red : _ScoreColors.text3,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? _ScoreColors.red : _ScoreColors.text1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _RoundIconButton({
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _ScoreColors.bgElev1,
          shape: BoxShape.circle,
          border: Border.all(color: _ScoreColors.divider),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _ScoreColors {
  static const bgDeep = Color(0xFF0E2A24);
  static const bgElev1 = Color(0xFF143630);
  static const bgElev2 = Color(0xFF1B4332);
  static const brand = Color(0xFF2E7D6B);
  static const mint = Color(0xFF8DE7C1);
  static const yellow = Color(0xFFFFC857);
  static const red = Color(0xFFFF6B6B);
  static const redBg = Color(0x25FF6B6B);
  static const redBorder = Color(0x66FF6B6B);
  static const text1 = Color(0xFFF4FBF8);
  static const text2 = Color(0xB3F4FBF8);
  static const text3 = Color(0x73F4FBF8);
  static const divider = Color(0x14F4FBF8);
}
