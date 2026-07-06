import 'package:flutter/material.dart';

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
      builder: (context) => AlertDialog(
        backgroundColor: _ScoreHistoryColors.bgElev1,
        title: const Text(
          '스코어 삭제',
          style: TextStyle(color: _ScoreHistoryColors.text1),
        ),
        content: Text(
          '${score.courseName} 기록을 삭제할까요?',
          style: const TextStyle(color: _ScoreHistoryColors.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '삭제',
              style: TextStyle(color: _ScoreHistoryColors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ScorecardService.instance.deleteScoreForSchedule(score.scheduleId);
    if (!mounted) return;
    setState(_reload);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('스코어 기록을 삭제했습니다.')),
    );
  }

  void _showOcrGuide() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _ScoreHistoryColors.bgElev1,
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
    final recentScores = await ScorecardService.instance.getAllScores();
    final recentCompanionSuggestions =
        await ScorecardService.instance.getRecommendedCompanionNames(limit: 6);
    if (!mounted) return;
    final prioritizedScores = [...recentScores];
    prioritizedScores.sort((a, b) {
      final incompleteCompare =
          b.incompleteHoleCount.compareTo(a.incompleteHoleCount);
      if (incompleteCompare != 0) return incompleteCompare;
      return b.playedAt.compareTo(a.playedAt);
    });

    final recentCourseSuggestions = <_RecentCourseSuggestion>[];
    for (final score in prioritizedScores) {
      final courseName = score.courseName.trim();
      if (courseName.isEmpty ||
          recentCourseSuggestions
              .any((item) => item.courseName == courseName)) {
        continue;
      }
      recentCourseSuggestions.add(
        _RecentCourseSuggestion(
          courseName: courseName,
          playedAt: score.playedAt,
          needsReview: score.incompleteHoleCount > 0,
          incompleteHoleCount: score.incompleteHoleCount,
        ),
      );
      if (recentCourseSuggestions.length >= 6) break;
    }

    final controller = TextEditingController(
      text: recentCourseSuggestions.isNotEmpty
          ? recentCourseSuggestions.first.courseName
          : '',
    );
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
    DateTime selectedDate = DateTime.now();

    final event = await showDialog<GolfEvent>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _ScoreHistoryColors.bgElev1,
              title: const Text(
                '지난 라운드 OCR 등록',
                style: TextStyle(color: _ScoreHistoryColors.text1),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      style: const TextStyle(color: _ScoreHistoryColors.text1),
                      decoration: const InputDecoration(
                        labelText: '골프장 이름',
                        hintText: '예: 드림파크CC',
                      ),
                    ),
                    if (recentCourseSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text(
                        '최근 골프장',
                        style: TextStyle(
                          color: _ScoreHistoryColors.text3,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: recentCourseSuggestions
                            .map(
                              (suggestion) => _RecentCourseChip(
                                suggestion: suggestion,
                                onTap: () {
                                  controller.text = suggestion.courseName;
                                  controller.selection =
                                      TextSelection.fromPosition(
                                    TextPosition(
                                      offset: controller.text.length,
                                    ),
                                  );
                                  setDialogState(() {});
                                },
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                    if (recentCompanionSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text(
                        '자주 함께한 동반자',
                        style: TextStyle(
                          color: _ScoreHistoryColors.text3,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'OCR 후 이름이 흔들리면 아래 기록을 기준으로 자동 연결됩니다.',
                        style: TextStyle(
                          color: _ScoreHistoryColors.text3,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: recentCompanionSuggestions
                            .map(
                              (suggestion) => _RecentCompanionChip(
                                suggestion: suggestion,
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                    const SizedBox(height: 14),
                    const Text(
                      '라운드 날짜',
                      style: TextStyle(
                        color: _ScoreHistoryColors.text3,
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
                    const Text(
                      '수기 입력보다 먼저 OCR로 읽고, 필요한 항목만 보정하는 흐름입니다.',
                      style: TextStyle(
                        color: _ScoreHistoryColors.text3,
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
                    final courseName = controller.text.trim();
                    if (courseName.isEmpty) return;
                    Navigator.pop(
                      dialogContext,
                      GolfEvent(
                        id: 'ocr_round_${DateTime.now().millisecondsSinceEpoch}',
                        title: courseName,
                        startDate: selectedDate,
                        courseName: courseName,
                        location: courseName,
                      ),
                    );
                  },
                  child: const Text('지난 라운드 OCR 시작'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    if (event == null || !mounted) return;

    final matchedCourse = await WeatherApiService.instance
        .searchCourse(event.courseName ?? event.title);
    if (!mounted) return;

    final resolvedEvent = event.copyWith(
      courseId: matchedCourse?.courseId ?? event.courseId,
      courseName: matchedCourse?.name ?? event.courseName,
      address: matchedCourse?.address,
      lat: matchedCourse?.lat,
      lng: matchedCourse?.lng,
    );

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScorecardScreen(
          event: resolvedEvent,
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
    return Scaffold(
      backgroundColor: _ScoreHistoryColors.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _ScoreHistoryColors.text1,
        title: const Text('스코어 관리'),
        actions: [
          IconButton(
            tooltip: '지난 라운드 OCR 등록',
            onPressed: _createScoreFromOcr,
            icon: const Icon(Icons.add_a_photo_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<GolfRoundScore>>(
        future: _scoresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                color: _ScoreHistoryColors.brand,
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
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? _ScoreHistoryColors.mint
              : _ScoreHistoryColors.bgElev2,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF09241F)
                : _ScoreHistoryColors.text2,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _RecentCourseSuggestion {
  final String courseName;
  final DateTime playedAt;
  final bool needsReview;
  final int incompleteHoleCount;

  const _RecentCourseSuggestion({
    required this.courseName,
    required this.playedAt,
    required this.needsReview,
    required this.incompleteHoleCount,
  });
}

class _RecentCompanionChip extends StatelessWidget {
  final CompanionNameSuggestion suggestion;

  const _RecentCompanionChip({
    required this.suggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _ScoreHistoryColors.bgElev2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _ScoreHistoryColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            suggestion.name,
            style: const TextStyle(
              color: _ScoreHistoryColors.text2,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${suggestion.roundCount}회 · ${_formatDate(suggestion.lastPlayedAt)}',
            style: const TextStyle(
              color: _ScoreHistoryColors.text3,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentCourseChip extends StatelessWidget {
  final _RecentCourseSuggestion suggestion;
  final VoidCallback onTap;

  const _RecentCourseChip({
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _ScoreHistoryColors.bgElev2,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                suggestion.courseName,
                style: const TextStyle(
                  color: _ScoreHistoryColors.text2,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(suggestion.playedAt),
                style: const TextStyle(
                  color: _ScoreHistoryColors.text3,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (suggestion.needsReview) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _ScoreHistoryColors.gold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '선택 보정 ${suggestion.incompleteHoleCount}홀',
                    style: const TextStyle(
                      color: _ScoreHistoryColors.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
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
    final best = stats.lifeBest;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _ScoreHistoryColors.bgElev1,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ScoreHistoryColors.goldBorder),
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
                  color: _ScoreHistoryColors.gold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  color: Color(0xFF241A04),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '라이프베스트',
                  style: TextStyle(
                    color: _ScoreHistoryColors.text1,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${best.totalScore}',
                style: const TextStyle(
                  color: _ScoreHistoryColors.gold,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${best.courseName} · ${_formatDate(best.playedAt)} · ${best.overParLabel}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ScoreHistoryColors.text2,
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
    final first = scores.first;
    final completion = first.trackingCompletionPercent;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _ScoreHistoryColors.bgElev1,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _ScoreHistoryColors.goldBorder),
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
                    color: _ScoreHistoryColors.bgElev2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.track_changes_outlined,
                    color: _ScoreHistoryColors.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '선택 세부 지표 ${scores.length}건',
                        style: const TextStyle(
                          color: _ScoreHistoryColors.text1,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        first.trackingStageDescription,
                        style: const TextStyle(
                          color: _ScoreHistoryColors.text3,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _ScoreHistoryColors.text3,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${first.courseName} · ${_formatDate(first.playedAt)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ScoreHistoryColors.text2,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '세부 기록 $completion%',
                  style: const TextStyle(
                    color: _ScoreHistoryColors.text1,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '선택 입력 ${first.incompleteHoleCount}홀',
                  style: const TextStyle(
                    color: _ScoreHistoryColors.gold,
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
                backgroundColor: _ScoreHistoryColors.bgElev2,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  _ScoreHistoryColors.gold,
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
  final VoidCallback onDelete;

  const _ScoreListTile({
    required this.score,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final badges = <_RoundStatusBadgeData>[
      _RoundStatusBadgeData(
        label: score.trackingStageLabel,
        backgroundColor: _ScoreHistoryColors.bgElev2,
        foregroundColor: score.trackingStage == GolfRoundTrackingStage.complete
            ? _ScoreHistoryColors.mint
            : score.trackingStage == GolfRoundTrackingStage.scoreOnly
                ? _ScoreHistoryColors.text2
                : _ScoreHistoryColors.gold,
      ),
      if (score.companions.isNotEmpty)
        _RoundStatusBadgeData(
          label: '동반자 ${score.companions.length}명',
          backgroundColor: _ScoreHistoryColors.bgElev2,
          foregroundColor: _ScoreHistoryColors.mint,
        ),
      if (score.hasCompletePuttTracking)
        const _RoundStatusBadgeData(
          label: '퍼트 기록',
          backgroundColor: _ScoreHistoryColors.bgElev2,
          foregroundColor: _ScoreHistoryColors.mint,
        ),
      if (score.hasCompleteFairwayTracking)
        const _RoundStatusBadgeData(
          label: '페어웨이 기록',
          backgroundColor: _ScoreHistoryColors.bgElev2,
          foregroundColor: _ScoreHistoryColors.gold,
        ),
      if (score.hasFairwayTracking && !score.hasCompleteFairwayTracking)
        _RoundStatusBadgeData(
          label:
              '페어웨이 ${score.fairwayTrackedCount}/${score.fairwayOpportunityCount}홀',
          backgroundColor: _ScoreHistoryColors.bgElev2,
          foregroundColor: _ScoreHistoryColors.gold,
        ),
      if (score.companions.isEmpty &&
          !score.hasCompletePuttTracking &&
          !score.hasFairwayTracking)
        const _RoundStatusBadgeData(
          label: '스코어 저장',
          backgroundColor: _ScoreHistoryColors.bgElev2,
          foregroundColor: _ScoreHistoryColors.text2,
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
          color: _ScoreHistoryColors.bgElev1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _ScoreHistoryColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _ScoreHistoryColors.brand,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${score.totalScore}',
                style: const TextStyle(
                  color: _ScoreHistoryColors.text1,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
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
                    style: const TextStyle(
                      color: _ScoreHistoryColors.text1,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(score.playedAt)} · ${score.overParLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ScoreHistoryColors.text3,
                      fontSize: 13,
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
                      style: const TextStyle(
                        color: _ScoreHistoryColors.mint,
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
                    style: const TextStyle(
                      color: _ScoreHistoryColors.text3,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '삭제',
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline,
                color: _ScoreHistoryColors.red,
              ),
            ),
          ],
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ScoreHistoryColors.bgElev1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ScoreHistoryColors.divider),
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
                  color: _ScoreHistoryColors.bgElev2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: _ScoreHistoryColors.mint,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '스코어카드 OCR 스캔',
                      style: TextStyle(
                        color: _ScoreHistoryColors.text1,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '일정 상세의 스코어카드에서 사진을 읽어 적용',
                      style: TextStyle(
                        color: _ScoreHistoryColors.text3,
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
                    label: const Text('지난 라운드 OCR 등록'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _ScoreHistoryColors.mint,
                      foregroundColor: const Color(0xFF09241F),
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
                      foregroundColor: _ScoreHistoryColors.text1,
                      side: const BorderSide(
                        color: _ScoreHistoryColors.divider,
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
                    color: _ScoreHistoryColors.bgElev1,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _ScoreHistoryColors.divider),
                  ),
                  child: const Icon(
                    Icons.scoreboard_outlined,
                    color: _ScoreHistoryColors.mint,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  '아직 저장된 스코어가 없습니다',
                  style: TextStyle(
                    color: _ScoreHistoryColors.text1,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '일정 상세 화면에서 스코어카드를 열고 저장하거나\n지난 라운드를 OCR로 바로 등록하면 기록이 여기에 쌓입니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ScoreHistoryColors.text3,
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
                  color: _ScoreHistoryColors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Icon(
                  Icons.document_scanner_outlined,
                  color: _ScoreHistoryColors.mint,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '스코어카드 OCR 가져오기',
                    style: TextStyle(
                      color: _ScoreHistoryColors.text1,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '일정 상세에서 바로 스캔할 수도 있고, 지난 라운드도 OCR 등록으로 기록을 시작할 수 있습니다.',
              style: TextStyle(
                color: _ScoreHistoryColors.text2,
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
              text: '일정 상세 스코어카드 또는 지난 라운드 OCR 등록에서 이미지 선택',
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
                      backgroundColor: _ScoreHistoryColors.mint,
                      foregroundColor: const Color(0xFF09241F),
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
                    foregroundColor: _ScoreHistoryColors.text1,
                    side: const BorderSide(
                      color: _ScoreHistoryColors.divider,
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
              color: _ScoreHistoryColors.bgElev2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: _ScoreHistoryColors.mint,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _ScoreHistoryColors.text2,
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ScoreHistoryColors.bgElev1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _ScoreHistoryColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _ScoreHistoryColors.text3,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _ScoreHistoryColors.text1,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ScoreHistoryColors.text3,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _ScoreHistoryColors.bgElev2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _ScoreHistoryColors.text2,
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
    return Text(
      title,
      style: const TextStyle(
        color: _ScoreHistoryColors.text1,
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

class _ScoreHistoryColors {
  static const bgDeep = Color(0xFF0E2A24);
  static const bgElev1 = Color(0xFF143630);
  static const bgElev2 = Color(0xFF1B4332);
  static const brand = Color(0xFF2E7D6B);
  static const mint = Color(0xFF8DE7C1);
  static const gold = Color(0xFFFFC857);
  static const goldBorder = Color(0x66FFC857);
  static const red = Color(0xFFFF6B6B);
  static const text1 = Color(0xFFF4FBF8);
  static const text2 = Color(0xB3F4FBF8);
  static const text3 = Color(0x73F4FBF8);
  static const divider = Color(0x14F4FBF8);
}
