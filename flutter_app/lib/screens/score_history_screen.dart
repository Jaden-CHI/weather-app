import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/golf_event.dart';
import '../models/golf_score.dart';
import '../services/scorecard_service.dart';
import '../services/weather_api_service.dart';
import 'scorecard_screen.dart';

class ScoreHistoryScreen extends StatefulWidget {
  final bool openOcrOnStart;

  const ScoreHistoryScreen({
    super.key,
    this.openOcrOnStart = false,
  });

  @override
  State<ScoreHistoryScreen> createState() => _ScoreHistoryScreenState();
}

class _ScoreHistoryScreenState extends State<ScoreHistoryScreen> {
  late Future<List<GolfRoundScore>> _scoresFuture;

  @override
  void initState() {
    super.initState();
    _reload();
    if (widget.openOcrOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _createScoreFromOcr();
        }
      });
    }
  }

  void _reload() {
    _scoresFuture = ScorecardService.instance.getAllScores();
  }

  Future<void> _openScore(GolfRoundScore score) async {
    final event = GolfEvent(
      id: score.scheduleId,
      title: score.courseName,
      startDate: score.playedAt,
      courseId: score.courseId,
      courseName: score.courseName,
      location: score.courseName,
    );

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ScorecardScreen(event: event)),
    );
    if (updated == true && mounted) {
      setState(_reload);
    }
  }

  Future<void> _deleteScore(GolfRoundScore score) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final t = GwTheme.of(context);
        return AlertDialog(
          backgroundColor: t.surface,
          title: Text(
            '스코어 삭제',
            style: TextStyle(color: t.fg),
          ),
          content: Text(
            '${score.courseName} 기록을 삭제할까요?',
            style: TextStyle(color: t.fg2),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                '삭제',
                style: TextStyle(color: t.danger),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    await ScorecardService.instance.deleteScoreForSchedule(score.scheduleId);
    if (!mounted) return;
    setState(_reload);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('스코어 기록을 삭제했습니다.')),
    );
  }

  Future<void> _editCourseName(GolfRoundScore score) async {
    final updated = await showDialog<GolfRoundScore>(
      context: context,
      builder: (context) => _EditCourseNameDialog(score: score),
    );

    if (updated == null) return;
    await ScorecardService.instance.saveScore(updated);
    if (!mounted) return;
    setState(_reload);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('골프장 이름을 수정했습니다.')),
    );
  }

  void _showOcrGuide() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: GwTheme.of(context).surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => _OcrReadySheet(
        onCreateRound: _createScoreFromOcr,
      ),
    );
  }

  Future<void> _createScoreFromOcr() async {
    if (!mounted) return;
    DateTime selectedDate = DateTime.now();

    final event = await showDialog<GolfEvent>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final t = GwTheme.of(context);
            return AlertDialog(
              backgroundColor: t.surface,
              title: Text(
                'OCR 스캐닝',
                style: TextStyle(color: t.fg),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    Text(
                      '라운드 날짜',
                      style: TextStyle(
                        color: t.fg3,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _QuickDateChip(
                          label: '오늘',
                          isSelected: _isSameDay(selectedDate, DateTime.now()),
                          onTap: () => setDialogState(
                              () => selectedDate = DateTime.now()),
                        ),
                        _QuickDateChip(
                          label: '어제',
                          isSelected: _isSameDay(
                            selectedDate,
                            DateTime.now().subtract(const Duration(days: 1)),
                          ),
                          onTap: () => setDialogState(
                            () => selectedDate = DateTime.now()
                                .subtract(const Duration(days: 1)),
                          ),
                        ),
                        _QuickDateChip(
                          label: '7일 전',
                          isSelected: _isSameDay(
                            selectedDate,
                            DateTime.now().subtract(const Duration(days: 7)),
                          ),
                          onTap: () => setDialogState(
                            () => selectedDate = DateTime.now()
                                .subtract(const Duration(days: 7)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        '${selectedDate.year}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '골프장 이름은 먼저 입력하지 않아도 됩니다. 먼저 OCR로 읽고, 필요한 경우에만 마지막에 보정할게요.',
                      style: TextStyle(
                        color: t.fg3,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      GolfEvent(
                        id: 'ocr_round_${DateTime.now().millisecondsSinceEpoch}',
                        title: '',
                        startDate: selectedDate,
                      ),
                    );
                  },
                  child: const Text('OCR 스캔 시작'),
                ),
              ],
            );
          },
        );
      },
    );
    if (event == null || !mounted) return;

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScorecardScreen(
          event: event,
          openOcrOnStart: true,
        ),
      ),
    );
    if (updated == true && mounted) {
      setState(_reload);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: t.fg,
        title: const Text('스코어 관리'),
        actions: [
          IconButton(
            tooltip: 'OCR 스캐닝',
            onPressed: _createScoreFromOcr,
            icon: const Icon(Icons.add_a_photo_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<GolfRoundScore>>(
        future: _scoresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(
                color: t.accent,
              ),
            );
          }

          final scores = snapshot.data ?? const [];
          if (scores.isEmpty) {
            return _EmptyScoreState(
              onOcrGuide: _showOcrGuide,
              onCreateRound: _createScoreFromOcr,
            );
          }

          final stats = _ScoreStats(scores);
          final incompleteScores = scores
              .where((score) => score.incompleteHoleCount > 0)
              .toList(growable: false);
          return RefreshIndicator(
            onRefresh: () async => setState(_reload),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              children: [
                _PremiumBanner(stats: stats),
                const SizedBox(height: 14),
                if (incompleteScores.isNotEmpty) ...[
                  _TrackingResumeCard(
                    scores: incompleteScores,
                    onTap: () => _openScore(incompleteScores.first),
                  ),
                  const SizedBox(height: 14),
                ],
                _StatsGrid(stats: stats),
                const SizedBox(height: 14),
                _OcrGuideCard(
                  onTap: _showOcrGuide,
                  onCreateRound: _createScoreFromOcr,
                ),
                const SizedBox(height: 20),
                const _SectionTitle('최근 라운드'),
                const SizedBox(height: 10),
                ...scores.map(
                  (score) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ScoreListTile(
                      score: score,
                      onTap: () => _openScore(score),
                      onEdit: () => _editCourseName(score),
                      onDelete: () => _deleteScore(score),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuickDateChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickDateChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? t.accent : t.surface2,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? t.accentInk : t.fg2,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ScoreStats {
  final List<GolfRoundScore> scores;

  _ScoreStats(this.scores);

  int get roundCount => scores.length;
  int get bestScore => lifeBest.totalScore;

  GolfRoundScore get lifeBest {
    final sorted = [...scores];
    sorted.sort((a, b) {
      final overPar = a.overPar.compareTo(b.overPar);
      if (overPar != 0) return overPar;
      return a.totalScore.compareTo(b.totalScore);
    });
    return sorted.first;
  }

  double get averageScore =>
      scores.fold<int>(0, (sum, score) => sum + score.totalScore) /
      scores.length;

  int get roundCountThisYear {
    final now = DateTime.now();
    return scores.where((score) => score.playedAt.year == now.year).length;
  }

  int get roundCountThisMonth {
    final now = DateTime.now();
    return scores
        .where(
          (score) =>
              score.playedAt.year == now.year &&
              score.playedAt.month == now.month,
        )
        .length;
  }

  int get companionRoundCount =>
      scores.where((score) => score.companions.isNotEmpty).length;

  int get incompleteRoundCount =>
      scores.where((score) => score.incompleteHoleCount > 0).length;

  int get completeRoundCount =>
      scores.where((score) => score.incompleteHoleCount == 0).length;

  double get recentAverageScore {
    final recent = scores.take(5).toList();
    if (recent.isEmpty) return 0;
    return recent.fold<int>(0, (sum, score) => sum + score.totalScore) /
        recent.length;
  }
}

class _PremiumBanner extends StatelessWidget {
  final _ScoreStats stats;

  const _PremiumBanner({required this.stats});

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final best = stats.lifeBest;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.warnBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.warn,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.emoji_events_outlined,
                  color: t.accentInk,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '라이프베스트',
                  style: TextStyle(
                    color: t.fg,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${best.totalScore}',
                style: TextStyle(
                  color: t.warn,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  fontFamily: GwTheme.numFont,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${best.courseName} · ${_formatDate(best.playedAt)} · ${best.overParLabel}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: t.fg2,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FeatureChip(
                  '최근 5R 평균 ${stats.recentAverageScore.toStringAsFixed(1)}'),
              _FeatureChip('이번 달 ${stats.roundCountThisMonth}R'),
              _FeatureChip('동반자 기록 ${stats.companionRoundCount}R'),
              _FeatureChip('세부 완료 ${stats.completeRoundCount}R'),
              if (stats.incompleteRoundCount > 0)
                _FeatureChip('선택 보정 ${stats.incompleteRoundCount}R'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackingResumeCard extends StatelessWidget {
  final List<GolfRoundScore> scores;
  final VoidCallback onTap;

  const _TrackingResumeCard({
    required this.scores,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final first = scores.first;
    final completion = first.trackingCompletionPercent;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.warnBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.surface2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.track_changes_outlined,
                    color: t.warn,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '선택 세부 지표 ${scores.length}건',
                        style: TextStyle(
                          color: t.fg,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        first.trackingStageDescription,
                        style: TextStyle(
                          color: t.fg3,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: t.fg3,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${first.courseName} · ${_formatDate(first.playedAt)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: t.fg2,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '세부 기록 $completion%',
                  style: TextStyle(
                    color: t.fg,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '선택 입력 ${first.incompleteHoleCount}홀',
                  style: TextStyle(
                    color: t.warn,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: first.trackingCompletionProgress,
                minHeight: 8,
                backgroundColor: t.surface2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  t.warn,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeatureChip(
                  '퍼트 ${first.puttsTrackedCount}/${first.holes.length}홀',
                ),
                _FeatureChip(
                  '페어웨이 ${first.fairwayTrackedCount}/${first.fairwayOpportunityCount}홀',
                ),
                if (first.firstIncompleteHoleNumber != null)
                  _FeatureChip('첫 선택 항목 ${first.firstIncompleteHoleNumber}H'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final _ScoreStats stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 1.55,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _StatCard(label: '총 라운드', value: '${stats.roundCount}회'),
        _StatCard(label: '올해 라운드', value: '${stats.roundCountThisYear}회'),
        _StatCard(label: '이번 달', value: '${stats.roundCountThisMonth}회'),
        _StatCard(
          label: '최근 5R 평균',
          value: stats.recentAverageScore.toStringAsFixed(1),
        ),
        _StatCard(
          label: '동반자 기록',
          value: '${stats.companionRoundCount}회',
          caption:
              stats.companionRoundCount == 0 ? '아직 기록 전' : '동반자 정보가 함께 저장된 라운드',
        ),
        _StatCard(
          label: '선택 보정',
          value: '${stats.incompleteRoundCount}회',
          caption: stats.incompleteRoundCount == 0
              ? '스코어 기록은 모두 저장됨'
              : '퍼트/페어웨이 등 선택 세부 지표',
        ),
      ],
    );
  }
}

class _ScoreListTile extends StatelessWidget {
  final GolfRoundScore score;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScoreListTile({
    required this.score,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final badges = <_RoundStatusBadgeData>[
      _RoundStatusBadgeData(
        label: score.trackingStageLabel,
        backgroundColor: t.surface2,
        foregroundColor: score.trackingStage == GolfRoundTrackingStage.complete
            ? t.accent
            : score.trackingStage == GolfRoundTrackingStage.scoreOnly
                ? t.fg2
                : t.warn,
      ),
      if (score.companions.isNotEmpty)
        _RoundStatusBadgeData(
          label: '동반자 ${score.companions.length}명',
          backgroundColor: t.surface2,
          foregroundColor: t.accent,
        ),
      if (score.hasCompletePuttTracking)
        _RoundStatusBadgeData(
          label: '퍼트 기록',
          backgroundColor: t.surface2,
          foregroundColor: t.accent,
        ),
      if (score.hasCompleteFairwayTracking)
        _RoundStatusBadgeData(
          label: '페어웨이 기록',
          backgroundColor: t.surface2,
          foregroundColor: t.warn,
        ),
      if (score.hasFairwayTracking && !score.hasCompleteFairwayTracking)
        _RoundStatusBadgeData(
          label:
              '페어웨이 ${score.fairwayTrackedCount}/${score.fairwayOpportunityCount}홀',
          backgroundColor: t.surface2,
          foregroundColor: t.warn,
        ),
      if (score.companions.isEmpty &&
          !score.hasCompletePuttTracking &&
          !score.hasFairwayTracking)
        _RoundStatusBadgeData(
          label: '스코어 저장',
          backgroundColor: t.surface2,
          foregroundColor: t.fg2,
        ),
    ];
    final trackingSummary =
        '선택 지표: 퍼트 ${score.puttsTrackedCount}/${score.holes.length}홀 · '
        '페어웨이 ${score.fairwayTrackedCount}/${score.fairwayOpportunityCount}홀';
    final completion = score.trackingCompletionPercent;
    final companionPreview = _buildCompanionPreview(score.companions);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${score.totalScore}',
                style: TextStyle(
                  color: t.accentInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: GwTheme.numFont,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    score.courseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.fg,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(score.playedAt)} · ${score.overParLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.fg3,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: t.surface2,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: t.line,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_location_alt_outlined,
                              color: t.accent,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '골프장명 수정',
                              style: TextStyle(
                                color: t.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (badges.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: badges
                          .map((badge) => _RoundStatusBadge(data: badge))
                          .toList(growable: false),
                    ),
                  ],
                  if (companionPreview != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      companionPreview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '${score.trackingStageDescription} · 세부 기록 $completion% · $trackingSummary',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.fg3,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: '골프장명 수정',
                  onPressed: onEdit,
                  icon: Icon(
                    Icons.edit_outlined,
                    color: t.fg2,
                  ),
                ),
                IconButton(
                  tooltip: '삭제',
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    color: t.danger,
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

class _EditCourseNameDialog extends StatefulWidget {
  final GolfRoundScore score;

  const _EditCourseNameDialog({required this.score});

  @override
  State<_EditCourseNameDialog> createState() => _EditCourseNameDialogState();
}

class _EditCourseNameDialogState extends State<_EditCourseNameDialog> {
  late final TextEditingController _controller;
  Timer? _debounce;
  List<CourseSearchResult> _suggestions = const [];
  CourseSearchResult? _selectedCourse;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.score.courseName);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final keyword = _controller.text.trim();
    if (_selectedCourse != null && _selectedCourse!.name != keyword) {
      _selectedCourse = null;
    }

    _debounce?.cancel();
    if (keyword.isEmpty) {
      setState(() {
        _suggestions = const [];
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 260), () {
      _searchSuggestions(keyword);
    });
    setState(() {});
  }

  Future<void> _searchSuggestions(String keyword) async {
    if (!mounted) return;
    setState(() => _isSearching = true);
    final results =
        await WeatherApiService.instance.searchCourseSuggestions(keyword);
    if (!mounted || _controller.text.trim() != keyword) return;
    setState(() {
      _suggestions = results;
      _isSearching = false;
    });
  }

  void _selectSuggestion(CourseSearchResult course) {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.text = course.name;
    _controller.selection = TextSelection.collapsed(
      offset: course.name.length,
    );
    _controller.addListener(_onTextChanged);
    setState(() {
      _selectedCourse = course;
      _suggestions = const [];
      _isSearching = false;
    });
  }

  Future<void> _submit() async {
    final courseName = _controller.text.trim();
    if (courseName.isEmpty) return;

    final matchedCourse = _selectedCourse?.name == courseName
        ? _selectedCourse
        : await WeatherApiService.instance.searchCourse(courseName);

    if (!mounted) return;
    Navigator.pop(
      context,
      GolfRoundScore(
        id: widget.score.id,
        scheduleId: widget.score.scheduleId,
        courseId: matchedCourse?.courseId ?? widget.score.courseId,
        courseName: courseName,
        playedAt: widget.score.playedAt,
        holes: widget.score.holes,
        companions: widget.score.companions,
        createdAt: widget.score.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final hasText = _controller.text.trim().isNotEmpty;

    return AlertDialog(
      backgroundColor: t.surface,
      title: Text(
        '골프장명 수정',
        style: TextStyle(color: t.fg),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OCR로 저장된 골프장명이 비었거나 다르면 여기서 바로 고칠 수 있어요.',
              style: TextStyle(
                color: t.fg3,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              style: TextStyle(color: t.fg),
              decoration: const InputDecoration(
                labelText: '골프장 이름',
                hintText: '예: 드림파크CC',
              ),
              onSubmitted: (_) => hasText ? _submit() : null,
            ),
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: t.surface2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    t.accent,
                  ),
                ),
              ),
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: t.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.cardBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _suggestions.map((course) {
                    final subtitle = course.nameShort?.trim();
                    return InkWell(
                      onTap: () => _selectSuggestion(course),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              size: 18,
                              color: t.accent,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: t.fg,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (subtitle != null &&
                                      subtitle.isNotEmpty &&
                                      subtitle != course.name)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: t.fg3,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(growable: false),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: hasText ? _submit : null,
          child: const Text('저장'),
        ),
      ],
    );
  }
}

String? _buildCompanionPreview(List<CompanionScore> companions) {
  if (companions.isEmpty) return null;
  final names = companions
      .map((companion) => companion.name.trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
  if (names.isEmpty) return null;
  if (names.length == 1) return '동반자 ${names.first}';
  if (names.length == 2) return '동반자 ${names[0]} · ${names[1]}';
  return '동반자 ${names[0]} · ${names[1]} 외 ${names.length - 2}명';
}

class _RoundStatusBadgeData {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _RoundStatusBadgeData({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });
}

class _RoundStatusBadge extends StatelessWidget {
  final _RoundStatusBadgeData data;

  const _RoundStatusBadge({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: data.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        data.label,
        style: TextStyle(
          color: data.foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OcrGuideCard extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onCreateRound;

  const _OcrGuideCard({
    required this.onTap,
    required this.onCreateRound,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
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
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome_outlined,
                  color: t.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '스코어카드 OCR 스캔',
                      style: TextStyle(
                        color: t.fg,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '일정 상세의 스코어카드에서 사진을 읽어 적용',
                      style: TextStyle(
                        color: t.fg3,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onCreateRound,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('OCR 스캐닝'),
                    style: FilledButton.styleFrom(
                      backgroundColor: t.accent,
                      foregroundColor: t.accentInk,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.help_outline),
                    label: const Text('OCR 가이드'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: t.fg,
                      side: BorderSide(
                        color: t.line,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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

class _EmptyScoreState extends StatelessWidget {
  final VoidCallback onOcrGuide;
  final VoidCallback onCreateRound;

  const _EmptyScoreState({
    required this.onOcrGuide,
    required this.onCreateRound,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 70),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: t.cardBorder),
                  ),
                  child: Icon(
                    Icons.scoreboard_outlined,
                    color: t.accent,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '아직 저장된 스코어가 없습니다',
                  style: TextStyle(
                    color: t.fg,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '일정 상세 화면에서 스코어카드를 열고 저장하거나\n지난 라운드를 OCR로 바로 등록하면 기록이 여기에 쌓입니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: t.fg3,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        _OcrGuideCard(
          onTap: onOcrGuide,
          onCreateRound: onCreateRound,
        ),
      ],
    );
  }
}

class _OcrReadySheet extends StatelessWidget {
  final VoidCallback onCreateRound;

  const _OcrReadySheet({
    required this.onCreateRound,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: t.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(
                  Icons.document_scanner_outlined,
                  color: t.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '스코어카드 OCR 가져오기',
                    style: TextStyle(
                      color: t.fg,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '일정 상세에서 바로 스캔할 수도 있고, 지난 라운드도 OCR 등록으로 기록을 시작할 수 있습니다.',
              style: TextStyle(
                color: t.fg2,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const _OcrStep(
              number: '1',
              text: '스코어카드 화면을 캡처하거나 종이 스코어카드를 촬영',
            ),
            const _OcrStep(
              number: '2',
              text: '일정 상세 스코어카드 또는 OCR 스캐닝에서 이미지 선택',
            ),
            const _OcrStep(
              number: '3',
              text: '홀별 점수를 확인하면 자동 저장되고, 필요할 때만 보정',
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        onCreateRound();
                      });
                    },
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('OCR 시작'),
                    style: FilledButton.styleFrom(
                      backgroundColor: t.accent,
                      foregroundColor: t.accentInk,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.fg,
                    side: BorderSide(
                      color: t.line,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('닫기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OcrStep extends StatelessWidget {
  final String number;
  final String text;

  const _OcrStep({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.surface2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              number,
              style: TextStyle(
                color: t.accent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: t.fg2,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;

  const _StatCard({
    required this.label,
    required this.value,
    this.caption,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: t.fg3,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: t.fg,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontFamily: GwTheme.numFont,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: t.fg3,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;

  const _FeatureChip(this.label);

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: t.fg2,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Text(
      title,
      style: TextStyle(
        color: t.fg,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
