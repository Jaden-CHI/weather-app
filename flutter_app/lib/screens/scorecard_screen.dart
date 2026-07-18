import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/golf_event.dart';
import '../models/golf_score.dart';
import '../services/scorecard_service.dart';
import 'score_ocr_screen.dart';

class ScorecardScreen extends StatefulWidget {
  final GolfEvent event;
  final bool openOcrOnStart;

  const ScorecardScreen({
    super.key,
    required this.event,
    this.openOcrOnStart = false,
  });

  @override
  State<ScorecardScreen> createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen> {
  GolfRoundScore? _score;
  bool _loading = true;
  bool _saving = false;
  bool _ocrOpenedFromStart = false;

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
    if (widget.openOcrOnStart && !_ocrOpenedFromStart) {
      _ocrOpenedFromStart = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openOcr();
        }
      });
    }
  }

  Future<void> _saveScore() async {
    var score = _score;
    if (score == null || _saving) return;

    final resolvedCourseName = await _resolveCourseNameBeforeSave(score);
    if (!mounted || resolvedCourseName == null) return;

    if (resolvedCourseName != score.courseName) {
      score = score.copyWith(
        courseName: resolvedCourseName,
        updatedAt: DateTime.now(),
      );
      setState(() => _score = score);
    }

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

  Future<String?> _resolveCourseNameBeforeSave(GolfRoundScore score) async {
    final currentName = score.courseName.trim();
    if (currentName.isNotEmpty) return currentName;

    final controller = TextEditingController();
    final courseName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final t = GwTheme.of(context);
            return AlertDialog(
              backgroundColor: t.surface,
              title: Text(
                '골프장 이름 확인',
                style: TextStyle(color: t.fg),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이번 카드에서는 골프장 이름을 읽지 못했어요. 저장 전에 골프장 이름만 입력해 주세요.',
                    style: TextStyle(
                      color: t.fg3,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: TextStyle(color: t.fg),
                    decoration: const InputDecoration(
                      labelText: '골프장 이름',
                      hintText: '예: 드림파크CC',
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: controller.text.trim().isEmpty
                      ? null
                      : () => Navigator.pop(
                            dialogContext,
                            controller.text.trim(),
                          ),
                  child: const Text('저장 계속'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
    return courseName;
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

  Future<void> _openOcr() async {
    final current = _score;
    if (current == null || _loading) return;

    final result = await Navigator.push<ScoreOcrResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ScoreOcrScreen(baseHoles: current.holes),
      ),
    );

    if (result == null || !mounted) return;

    final companions = result.companions
        .map(
          (companion) => CompanionScore(
            name: companion.name.trim(),
            holes: companion.holes,
          ),
        )
        .where((companion) => companion.name.isNotEmpty)
        .toList(growable: false);

    setState(() {
      _score = current.copyWith(
        courseName: result.courseName?.trim().isNotEmpty == true
            ? result.courseName!.trim()
            : current.courseName,
        playedAt: result.playedAt ?? current.playedAt,
        holes: result.holes,
        companions: companions,
        updatedAt: DateTime.now(),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          companions.isEmpty
              ? 'OCR 결과를 불러왔어요. 홀별 점수만 한 번 확인해 주세요.'
              : 'OCR 결과와 동반자 ${companions.length}명 기록을 불러왔어요.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final score = _score;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(
          children: [
            _ScoreNav(
              title: _resolveScreenTitle(score),
              onBack: () => Navigator.pop(context),
              onOcr: _loading ? null : _openOcr,
            ),
            Expanded(
              child: _loading || score == null
                  ? Center(
                      child: CircularProgressIndicator(
                        color: t.accent,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
                      children: [
                        _RoundSummary(score: score),
                        if (score.companions.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _CompanionSummary(score: score),
                        ],
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
          decoration: BoxDecoration(
            color: t.bg,
            border: Border(
              top: BorderSide(color: t.line),
            ),
          ),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: t.accent,
                foregroundColor: t.accentInk,
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

  String _resolveScreenTitle(GolfRoundScore? score) {
    final scoreName = score?.courseName.trim();
    if (scoreName != null && scoreName.isNotEmpty) {
      return scoreName;
    }

    final eventCourseName = widget.event.courseName?.trim();
    if (eventCourseName != null && eventCourseName.isNotEmpty) {
      return eventCourseName;
    }

    final eventLocation = widget.event.location?.trim();
    if (eventLocation != null && eventLocation.isNotEmpty) {
      return eventLocation;
    }

    final title = widget.event.title.trim();
    if (title.isNotEmpty) {
      return title;
    }

    return '지난 라운드 OCR';
  }
}

class _ScoreNav extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onOcr;

  const _ScoreNav({
    required this.title,
    required this.onBack,
    this.onOcr,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          _RoundIconButton(
            onTap: onBack,
            child: Icon(
              Icons.arrow_back_ios_new,
              color: t.fg,
              size: 17,
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
                    color: t.fg3,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.fg,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _RoundIconButton(
            onTap: onOcr,
            child: Icon(
              Icons.document_scanner_outlined,
              color: t.accent,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanionSummary extends StatelessWidget {
  final GolfRoundScore score;

  const _CompanionSummary({
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final names = score.companions
        .map((companion) => companion.name.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    if (names.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '동반자 OCR 결과',
            style: TextStyle(
              color: t.fg,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            names.join(' · '),
            style: TextStyle(
              color: t.fg2,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.4,
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
    final t = GwTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.cardBorder),
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
    final t = GwTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: t.fg3, fontSize: 12),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: accent ? t.warn : t.fg,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            fontFamily: GwTheme.numFont,
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
    final t = GwTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: t.fg3, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: t.fg,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFamily: GwTheme.numFont,
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
    final t = GwTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.cardBorder),
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
                  color: t.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${hole.holeNumber}H',
                  style: TextStyle(
                    color: t.accentInk,
                    fontWeight: FontWeight.w900,
                    fontFamily: GwTheme.numFont,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Par ${hole.par} · ${_scoreLabel(hole.overPar)}',
                  style: TextStyle(
                    color: t.fg,
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
    final t = GwTheme.of(context);
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: t.fg,
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
    final t = GwTheme.of(context);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.only(left: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? t.accent : t.line,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: enabled ? t.accentInk : t.fg3,
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
    final t = GwTheme.of(context);
    final selected = enabled ? value : FairwayResult.notApplicable;
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            '페어웨이',
            style: TextStyle(
              color: t.fg3,
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
                  return t.accent;
                }
                return t.surface2;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return t.accentInk;
                }
                return t.fg2;
              }),
              side: WidgetStateProperty.all(
                BorderSide(color: t.line),
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
    final t = GwTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? t.dangerBg : t.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? t.dangerBorder : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? t.danger : t.fg3,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? t.danger : t.fg,
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
  final VoidCallback? onTap;
  final Widget child;

  const _RoundIconButton({
    required this.onTap,
    required this.child,
  });

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
          border: Border.all(color: t.cardBorder),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
