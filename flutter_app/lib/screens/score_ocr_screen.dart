import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/app_theme.dart';
import '../models/golf_score.dart';
import '../services/score_ocr_parser.dart';
import '../services/scorecard_service.dart';

class ScoreOcrResult {
  final List<HoleScore> holes;
  final List<String> companionNames;
  final List<ScoreOcrCompanionResult> companions;
  final String? courseName;
  final DateTime? playedAt;
  final String? playerName;

  const ScoreOcrResult({
    required this.holes,
    this.companionNames = const [],
    this.companions = const [],
    this.courseName,
    this.playedAt,
    this.playerName,
  });
}

class ScoreOcrScreen extends StatefulWidget {
  final List<HoleScore> baseHoles;

  const ScoreOcrScreen({
    super.key,
    required this.baseHoles,
  });

  @override
  State<ScoreOcrScreen> createState() => _ScoreOcrScreenState();
}

class _ScoreOcrScreenState extends State<ScoreOcrScreen> {
  static const _ocrChannel = MethodChannel('golf_windy/ocr');

  final _picker = ImagePicker();

  File? _image;
  String _rawText = '';
  List<HoleScore> _previewHoles = const [];
  List<String> _companionNames = const [];
  List<ScoreOcrCompanionResult> _companionScores = const [];
  String? _courseName;
  DateTime? _playedAt;
  String? _playerName;
  bool _scanning = false;

  bool get _hasScanResult =>
      _image != null &&
      !_scanning &&
      (_rawText.isNotEmpty ||
          _companionNames.isNotEmpty ||
          _companionScores.isNotEmpty ||
          _changedHoleCount > 0);

  List<String> get _nameOnlyCompanionCandidates {
    final scoredNames = _companionScores
        .map((companion) => normalizeNameCandidate(companion.name))
        .whereType<String>()
        .toSet();

    return _companionNames.where((name) {
      final normalized = normalizeNameCandidate(name);
      return normalized != null && !scoredNames.contains(normalized);
    }).toList(growable: false);
  }

  int get _reviewNeededCompanionCount {
    final duplicateNames = _findDuplicateCompanionNames(
      _companionScores.map((companion) => companion.name),
    );

    return _companionScores.where((companion) {
      final normalized = _normalizeCompanionReviewName(companion.name);
      return _needsCompanionNameReview(companion.name) ||
          duplicateNames.contains(normalized);
    }).length;
  }

  int get _changedHoleCount {
    if (widget.baseHoles.length != _previewHoles.length) {
      return _previewHoles.length;
    }

    var changed = 0;
    for (var index = 0; index < _previewHoles.length; index++) {
      final base = widget.baseHoles[index];
      final preview = _previewHoles[index];
      if (base.par != preview.par ||
          base.strokes != preview.strokes ||
          base.putts != preview.putts ||
          base.puttsTracked != preview.puttsTracked) {
        changed += 1;
      }
    }
    return changed;
  }

  @override
  void initState() {
    super.initState();
    _previewHoles = widget.baseHoles;
  }

  Future<void> _pickAndScan(ImageSource source) async {
    final granted = await _ensurePickerPermission(source);
    if (!granted || !mounted) return;

    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 1800,
      );
    } on PlatformException {
      if (!mounted) return;
      if (source == ImageSource.camera) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '카메라 접근에 실패했습니다. 아래 "앱 설정"을 눌러 Golf Windy의 카메라 권한을 확인해 주세요.',
            ),
            action: SnackBarAction(
              label: '앱 설정',
              onPressed: openAppSettings,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '사진 선택 화면을 열지 못했습니다. 앱을 완전히 종료한 뒤 다시 시도해 주세요.',
            ),
          ),
        );
      }
      return;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지를 불러오지 못했습니다: $error')),
      );
      return;
    }

    final selected = picked;
    if (selected == null) return;

    setState(() {
      _image = File(selected.path);
      _scanning = true;
      _rawText = '';
      _courseName = null;
      _playedAt = null;
      _playerName = null;
    });

    try {
      final recognizedText = await _recognizeText(selected.path);
      final parsed = parseScorecardText(recognizedText, widget.baseHoles);
      if (!mounted) return;
      setState(() {
        _rawText = recognizedText.trim();
        _previewHoles = parsed.holes;
        _companionNames = parsed.companionNames;
        _companionScores = parsed.companions;
        _courseName = parsed.courseName;
        _playedAt = parsed.playedAt;
        _playerName = parsed.playerName;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OCR 인식에 실패했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<bool> _ensurePickerPermission(ImageSource source) async {
    if (source == ImageSource.gallery) {
      return true;
    }

    const permission = Permission.camera;

    var status = await permission.status;
    if (status.isGranted) {
      return true;
    }

    status = await permission.request();
    if (status.isGranted) {
      return true;
    }

    if (!mounted) return false;

    final shouldOpenSettings = status.isPermanentlyDenied || status.isRestricted;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shouldOpenSettings
              ? '카메라 권한이 꺼져 있어 OCR 촬영을 시작할 수 없습니다. 아래 "앱 설정"을 눌러 Golf Windy의 카메라 권한을 허용해 주세요.'
              : '카메라 권한이 필요합니다. 권한을 허용한 뒤 다시 시도해 주세요.',
        ),
        action: shouldOpenSettings
            ? const SnackBarAction(
                label: '앱 설정',
                onPressed: openAppSettings,
              )
            : null,
      ),
    );
    return false;
  }

  Future<String> _recognizeText(String imagePath) async {
    final text = await _ocrChannel.invokeMethod<String>(
      'recognizeText',
      {'path': imagePath},
    );
    return text ?? '';
  }

  Future<void> _editHole(int index) async {
    final t = GwTheme.of(context);
    final current = _previewHoles[index];
    final edited = await showModalBottomSheet<HoleScore>(
      context: context,
      backgroundColor: t.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => _HoleEditSheet(hole: current),
    );

    if (edited == null || !mounted) return;
    setState(() {
      final updated = [..._previewHoles];
      updated[index] = edited;
      _previewHoles = updated;
      _companionScores = _companionScores
          .map(
            (companion) => ScoreOcrCompanionResult(
              name: companion.name,
              holes: List.generate(companion.holes.length, (holeIndex) {
                final hole = companion.holes[holeIndex];
                if (holeIndex != index) return hole;
                final strokes =
                    hole.strokes < edited.par ? edited.par : hole.strokes;
                return hole.copyWith(par: edited.par, strokes: strokes);
              }),
            ),
          )
          .toList(growable: false);
    });
  }

  Future<void> _editCompanion(int index) async {
    await _openCompanionEditor(index);
  }

  Future<bool> _openCompanionEditor(int index) async {
    final current = _companionScores[index];
    final edited = await Navigator.push<ScoreOcrCompanionResult>(
      context,
      MaterialPageRoute(
        builder: (_) => _CompanionOcrEditScreen(
          companion: current,
          otherCompanionNames: _companionScores
              .asMap()
              .entries
              .where((entry) => entry.key != index)
              .map((entry) => entry.value.name)
              .toList(growable: false),
        ),
      ),
    );

    if (edited == null || !mounted) return false;
    setState(() {
      final updated = [..._companionScores];
      updated[index] = edited;
      _companionScores = updated;
      _companionNames = _mergeCompanionNamesForPreview(
        updated.map((companion) => companion.name),
        _companionNames,
      );
    });
    return true;
  }

  List<int> _companionReviewIndexes() {
    final duplicateNames = _findDuplicateCompanionNames(
      _companionScores.map((companion) => companion.name),
    );
    return _companionScores
        .asMap()
        .entries
        .where((entry) {
          final normalized = _normalizeCompanionReviewName(entry.value.name);
          return _needsCompanionNameReview(entry.value.name) ||
              duplicateNames.contains(normalized);
        })
        .map((entry) => entry.key)
        .toList(growable: false);
  }

  Future<void> _reviewCompanionsNeedingAttention() async {
    final initialIndexes = _companionReviewIndexes();
    if (initialIndexes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('검토가 필요한 동반자 이름이 없습니다.')),
      );
      return;
    }

    var reviewedCount = 0;
    for (var step = 0; step < initialIndexes.length; step++) {
      if (!mounted) return;
      final currentIndexes = _companionReviewIndexes();
      if (currentIndexes.isEmpty) break;

      final targetIndex = step < currentIndexes.length
          ? currentIndexes[step]
          : currentIndexes.last;
      final applied = await _openCompanionEditor(targetIndex);
      if (!applied || !mounted) break;
      reviewedCount += 1;
    }

    if (!mounted || reviewedCount == 0) return;
    final remainingCount = _companionReviewIndexes().length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          remainingCount == 0
              ? '좋아요, 검토가 필요한 동반자 이름을 모두 확인했어요.'
              : '검토를 $reviewedCount명 진행했고, 아직 $remainingCount명 남아 있습니다.',
        ),
      ),
    );
  }

  void _apply() {
    Navigator.pop(
      context,
      ScoreOcrResult(
        holes: _previewHoles,
        companionNames: _companionNames,
        companions: _companionScores,
        courseName: _courseName,
        playedAt: _playedAt,
        playerName: _playerName,
      ),
    );
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
        title: const Text('스코어카드 OCR'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
        children: [
          _PickCard(
            onCamera: () => _pickAndScan(ImageSource.camera),
            onGallery: () => _pickAndScan(ImageSource.gallery),
            scanning: _scanning,
          ),
          if (_image != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                _image!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _OcrSummaryCard(
            holes: _previewHoles,
            scoredCompanionCount: _companionScores.length,
            nameOnlyCompanionCount: _nameOnlyCompanionCandidates.length,
            reviewNeededCompanionCount: _reviewNeededCompanionCount,
            changedHoleCount: _changedHoleCount,
            hasScanResult: _hasScanResult,
            courseName: _courseName,
            playedAt: _playedAt,
            playerName: _playerName,
          ),
          const SizedBox(height: 16),
          _HolePreviewTable(
            holes: _previewHoles,
            onTapHole: _editHole,
          ),
          if (_companionNames.isNotEmpty) ...[
            const SizedBox(height: 16),
            _CompanionPreviewCard(
              names: _companionNames,
              namesOnlyCandidates: _nameOnlyCompanionCandidates,
              companions: _companionScores,
              onTapCompanion: _editCompanion,
              onReviewNeeded: _reviewCompanionsNeedingAttention,
            ),
          ],
          if (_rawText.isNotEmpty) ...[
            const SizedBox(height: 16),
            _RawTextBox(text: _rawText),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: BoxDecoration(
            color: t.bg,
            border: Border(top: BorderSide(color: t.line)),
          ),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _scanning || !_hasScanResult ? null : _apply,
              style: FilledButton.styleFrom(
                backgroundColor: t.accent,
                foregroundColor: t.accentInk,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.check),
              label: const Text(
                '현재 스코어카드에 적용',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PickCard extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final bool scanning;

  const _PickCard({
    required this.onCamera,
    required this.onGallery,
    required this.scanning,
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
              Icon(
                Icons.document_scanner_outlined,
                color: t.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '스코어카드 이미지 스캔',
                  style: TextStyle(
                    color: t.fg,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (scanning)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '사진 속 숫자를 읽어 홀별 타수 후보를 만듭니다. 인식 결과는 반드시 확인 후 적용하세요.',
            style: TextStyle(
              color: t.fg3,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: scanning ? null : onGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('사진 선택'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.fg,
                    side: BorderSide(color: t.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: scanning ? null : onCamera,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('촬영'),
                  style: FilledButton.styleFrom(
                    backgroundColor: t.accent,
                    foregroundColor: t.accentInk,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OcrSummaryCard extends StatelessWidget {
  final List<HoleScore> holes;
  final int scoredCompanionCount;
  final int nameOnlyCompanionCount;
  final int reviewNeededCompanionCount;
  final int changedHoleCount;
  final bool hasScanResult;
  final String? courseName;
  final DateTime? playedAt;
  final String? playerName;

  const _OcrSummaryCard({
    required this.holes,
    required this.scoredCompanionCount,
    required this.nameOnlyCompanionCount,
    required this.reviewNeededCompanionCount,
    required this.changedHoleCount,
    required this.hasScanResult,
    this.courseName,
    this.playedAt,
    this.playerName,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final frontTotal = _sumHoleStrokes(holes, start: 0, end: 9);
    final backTotal = _sumHoleStrokes(holes, start: 9, end: 18);
    final total = _sumHoleStrokes(holes);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OCR 요약',
            style: TextStyle(
              color: t.fg,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(label: '총합', value: '$total타'),
              _SummaryChip(label: '전반', value: '$frontTotal타'),
              _SummaryChip(label: '후반', value: '$backTotal타'),
              _SummaryChip(label: '점수 동반자', value: '$scoredCompanionCount명'),
              if (nameOnlyCompanionCount > 0)
                _SummaryChip(
                    label: '이름만 감지', value: '$nameOnlyCompanionCount명'),
              if (reviewNeededCompanionCount > 0)
                const _SummaryChip(
                  label: '이름 검토',
                  value: '필요',
                  highlight: true,
                ),
            ],
          ),
          if ((courseName?.trim().isNotEmpty ?? false) ||
              playedAt != null ||
              (playerName?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (courseName?.trim().isNotEmpty ?? false)
                  _SummaryLine(label: '골프장', value: courseName!.trim()),
                if (playedAt != null)
                  _SummaryLine(label: '라운드', value: _formatOcrDateTime(playedAt!)),
                if (playerName?.trim().isNotEmpty ?? false)
                  _SummaryLine(label: '본인', value: playerName!.trim()),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            !hasScanResult
                ? '사진을 선택하거나 촬영하면 OCR 결과가 여기에 정리됩니다. 읽은 뒤에만 현재 스코어카드에 적용할 수 있어요.'
                : changedHoleCount > 0
                ? '기본 스코어카드와 다른 홀 $changedHoleCount개가 반영됐어요. 전반/후반 점수 흐름과 동반자 이름을 한 번만 더 확인하면 좋습니다.'
                : '기본 코스 정보와 큰 차이는 없어요. 그래도 손글씨 카드라면 합계와 동반자 이름은 한 번 확인해 주세요.',
            style: TextStyle(
              color: t.fg3,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              label,
              style: TextStyle(
                color: t.fg3,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: t.fg,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? t.warnBg : t.surface2,
        borderRadius: BorderRadius.circular(12),
        border: highlight ? Border.all(color: t.warn) : null,
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                color: highlight ? t.warn : t.fg3,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: highlight ? t.warn : t.fg,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatOcrDateTime(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  if (value.hour == 0 && value.minute == 0) {
    return '$year/$month/$day';
  }
  return '$year/$month/$day $hour:$minute';
}

class _HolePreviewTable extends StatelessWidget {
  final List<HoleScore> holes;
  final ValueChanged<int> onTapHole;

  const _HolePreviewTable({
    required this.holes,
    required this.onTapHole,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final frontNine = holes.take(9).toList(growable: false);
    final backNine = holes.skip(9).take(9).toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '내 스코어 미리보기',
            style: TextStyle(
              color: t.fg,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '전반/후반 흐름과 파 대비 결과를 보면서 이상한 홀을 바로 수정하세요.',
            style: TextStyle(
              color: t.fg3,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          _HolePreviewSection(
            title: '전반',
            total: _sumHoleStrokes(frontNine),
            holes: frontNine,
            onTapHole: onTapHole,
          ),
          if (backNine.isNotEmpty) ...[
            const SizedBox(height: 12),
            _HolePreviewSection(
              title: '후반',
              total: _sumHoleStrokes(backNine),
              holes: backNine,
              onTapHole: onTapHole,
            ),
          ],
        ],
      ),
    );
  }
}

class _HolePreviewSection extends StatelessWidget {
  final String title;
  final int total;
  final List<HoleScore> holes;
  final ValueChanged<int> onTapHole;

  const _HolePreviewSection({
    required this.title,
    required this.total,
    required this.holes,
    required this.onTapHole,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: t.fg,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$total타',
              style: TextStyle(
                color: t.accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: holes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final hole = holes[index];
            final relation = hole.strokes - hole.par;
            final delta = _scoreDeltaLabel(relation);
            final deltaColor = _scoreDeltaColor(relation, t);

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onTapHole(hole.holeNumber - 1),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: t.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${hole.holeNumber}H · Par ${hole.par}',
                            style: TextStyle(
                              color: t.fg3,
                              fontSize: 11,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: deltaColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            delta,
                            style: TextStyle(
                              color: deltaColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${hole.strokes}타',
                      style: TextStyle(
                        color: t.fg,
                        fontSize: 18,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        fontFamily: GwTheme.numFont,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hole.puttsTracked ? '퍼트 ${hole.putts}' : '퍼트 미입력',
                      style: TextStyle(
                        color: t.fg3,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RawTextBox extends StatelessWidget {
  final String text;

  const _RawTextBox({required this.text});

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
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
                child: Text(
                  '원문 OCR',
                  style: TextStyle(
                    color: t.fg,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('원문 OCR을 복사했어요.'),
                      ),
                    );
                  }
                },
                visualDensity: VisualDensity.compact,
                tooltip: '원문 복사',
                icon: Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: t.fg3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            text,
            style: TextStyle(
              color: t.fg3,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanionPreviewCard extends StatelessWidget {
  final List<String> names;
  final List<String> namesOnlyCandidates;
  final List<ScoreOcrCompanionResult> companions;
  final ValueChanged<int> onTapCompanion;
  final VoidCallback onReviewNeeded;

  const _CompanionPreviewCard({
    required this.names,
    required this.namesOnlyCandidates,
    required this.companions,
    required this.onTapCompanion,
    required this.onReviewNeeded,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final duplicateNames = _findDuplicateCompanionNames(
      companions.map((companion) => companion.name),
    );
    final needsReviewCount = companions.where((companion) {
      final normalized = _normalizeCompanionReviewName(companion.name);
      return _needsCompanionNameReview(companion.name) ||
          duplicateNames.contains(normalized);
    }).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '감지된 동반자 후보',
            style: TextStyle(
              color: t.fg,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '적용하면 아직 없는 이름만 동반자 목록에 자동 추가됩니다. 점수까지 읽힌 동반자는 이름과 홀별 타수를 바로 수정할 수 있습니다.',
            style: TextStyle(
              color: t.fg3,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          if (needsReviewCount > 0) ...[
            const SizedBox(height: 10),
            Text(
              '$needsReviewCount명의 이름은 확인이 필요합니다.',
              style: TextStyle(
                color: t.warn,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onReviewNeeded,
                icon: const Icon(Icons.playlist_play_rounded),
                label: const Text('검토 필요한 동반자 순서대로 보기'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: t.warn,
                  side: BorderSide(color: t.warn),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          if (companions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              '점수까지 감지된 동반자',
              style: TextStyle(
                color: t.fg,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            ...companions.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onTapCompanion(entry.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: t.surface2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: t.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.value.name,
                                    style: TextStyle(
                                      color: t.fg,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  ...() {
                                    final normalizedName =
                                        _normalizeCompanionReviewName(
                                      entry.value.name,
                                    );
                                    final frontTotal = _sumHoleStrokes(
                                      entry.value.holes,
                                      start: 0,
                                      end: 9,
                                    );
                                    final backTotal = _sumHoleStrokes(
                                      entry.value.holes,
                                      start: 9,
                                      end: 18,
                                    );
                                    final flags = <String>[
                                      if (_needsCompanionNameReview(
                                        entry.value.name,
                                      ))
                                        '이름 확인',
                                      if (duplicateNames
                                          .contains(normalizedName))
                                        '중복 후보',
                                    ];
                                    if (flags.isEmpty) {
                                      return <Widget>[];
                                    }
                                    return <Widget>[
                                      const SizedBox(height: 4),
                                      Text(
                                        '전반 $frontTotal · 후반 $backTotal',
                                        style: TextStyle(
                                          color: t.fg3,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (flags.isNotEmpty)
                                        const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: flags
                                            .map(
                                              (flag) => _CompanionWarningBadge(
                                                label: flag,
                                              ),
                                            )
                                            .toList(growable: false),
                                      ),
                                    ];
                                  }(),
                                ],
                              ),
                            ),
                            Text(
                              '${entry.value.holes.fold<int>(0, (sum, hole) => sum + hole.strokes)}타',
                              style: TextStyle(
                                color: t.fg3,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.chevron_right,
                              color: t.fg3,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ],
          if (namesOnlyCandidates.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '이름만 감지된 동반자 후보',
              style: TextStyle(
                color: t.fg,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: namesOnlyCandidates
                  .map((name) => _buildNameChip(t, name))
                  .toList(),
            ),
          ],
          if (companions.isEmpty &&
              namesOnlyCandidates.isEmpty &&
              names.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: names.map((name) => _buildNameChip(t, name)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNameChip(GwTheme t, String name) {
    final needsReview = _needsCompanionNameReview(name);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: needsReview ? t.warnBg : t.surface2,
        borderRadius: BorderRadius.circular(999),
        border: needsReview ? Border.all(color: t.warn) : null,
      ),
      child: Text(
        needsReview ? '$name 확인' : name,
        style: TextStyle(
          color: needsReview ? t.warn : t.fg,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HoleEditSheet extends StatefulWidget {
  final HoleScore hole;

  const _HoleEditSheet({required this.hole});

  @override
  State<_HoleEditSheet> createState() => _HoleEditSheetState();
}

class _HoleEditSheetState extends State<_HoleEditSheet> {
  late int _par;
  late int _strokes;
  late int _putts;

  @override
  void initState() {
    super.initState();
    _par = widget.hole.par;
    _strokes = widget.hole.strokes;
    _putts = widget.hole.putts;
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.hole.holeNumber}번 홀 보정',
              style: TextStyle(
                color: t.fg,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '손글씨 카드나 흐릿한 숫자는 여기서 바로 수정하세요.',
              style: TextStyle(
                color: t.fg3,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            _ValuePickerRow(
              label: 'Par',
              value: _par,
              values: const [3, 4, 5, 6],
              onChanged: (value) {
                setState(() {
                  _par = value;
                  if (_strokes < _par) _strokes = _par;
                });
              },
            ),
            const SizedBox(height: 14),
            _ValuePickerRow(
              label: '타수',
              value: _strokes,
              values: List<int>.generate(12, (index) => index + 1),
              onChanged: (value) {
                setState(() {
                  _strokes = value < _par ? _par : value;
                });
              },
            ),
            const SizedBox(height: 14),
            _ValuePickerRow(
              label: '퍼트',
              value: _putts,
              values: List<int>.generate(6, (index) => index),
              onChanged: (value) {
                setState(() => _putts = value);
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    widget.hole.copyWith(
                      par: _par,
                      strokes: _strokes,
                      putts: _putts,
                      puttsTracked: true,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: t.accent,
                  foregroundColor: t.accentInk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '보정 반영',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValuePickerRow extends StatelessWidget {
  final String label;
  final int value;
  final List<int> values;
  final ValueChanged<int> onChanged;

  const _ValuePickerRow({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: t.fg,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((item) {
            final selected = item == value;
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onChanged(item),
              child: Container(
                width: 42,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? t.accent : t.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? t.accent : t.cardBorder,
                  ),
                ),
                child: Text(
                  '$item',
                  style: TextStyle(
                    color: selected ? t.accentInk : t.fg,
                    fontWeight: FontWeight.w900,
                    fontFamily: GwTheme.numFont,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CompanionOcrEditScreen extends StatefulWidget {
  final ScoreOcrCompanionResult companion;
  final List<String> otherCompanionNames;

  const _CompanionOcrEditScreen({
    required this.companion,
    this.otherCompanionNames = const [],
  });

  @override
  State<_CompanionOcrEditScreen> createState() =>
      _CompanionOcrEditScreenState();
}

class _CompanionOcrEditScreenState extends State<_CompanionOcrEditScreen> {
  late TextEditingController _nameController;
  late List<HoleScore> _holes;
  List<CompanionNameSuggestion> _recommendedNames = const [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.companion.name);
    _holes = widget.companion.holes;
    _loadRecommendedNames();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendedNames() async {
    final names =
        await ScorecardService.instance.getRecommendedCompanionNames();
    if (!mounted) return;
    setState(() {
      _recommendedNames = names
          .where((item) => item.name.trim().isNotEmpty)
          .toList(growable: false);
    });
  }

  Future<void> _editHole(int index) async {
    final t = GwTheme.of(context);
    final current = _holes[index];
    final edited = await showModalBottomSheet<HoleScore>(
      context: context,
      backgroundColor: t.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => _CompanionHoleEditSheet(hole: current),
    );

    if (edited == null || !mounted) return;
    setState(() {
      final updated = [..._holes];
      updated[index] = edited;
      _holes = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    final total = _holes.fold<int>(0, (sum, hole) => sum + hole.strokes);
    final nameInput = _nameController.text;
    final needsNameReview = _needsCompanionNameReview(nameInput);
    final hasDuplicateName = widget.otherCompanionNames.any(
      (name) =>
          _normalizeCompanionReviewName(name) ==
          _normalizeCompanionReviewName(nameInput),
    );
    final sortedRecommendations = [..._recommendedNames]..sort((a, b) {
        final input = _normalizeCompanionReviewName(nameInput);
        final aScore = _scoreCompanionSuggestionMatch(input, a.name);
        final bScore = _scoreCompanionSuggestionMatch(input, b.name);
        if (aScore != bScore) return bScore.compareTo(aScore);
        if (a.roundCount != b.roundCount) {
          return b.roundCount.compareTo(a.roundCount);
        }
        return b.lastPlayedAt.compareTo(a.lastPlayedAt);
      });
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: t.fg,
        title: const Text('동반자 OCR 보정'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
        children: [
          Container(
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
                  '이름',
                  style: TextStyle(
                    color: t.fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: t.fg),
                  decoration: InputDecoration(
                    hintText: '동반자 이름',
                    hintStyle: TextStyle(color: t.fg3),
                    filled: true,
                    fillColor: t.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (needsNameReview) ...[
                  const SizedBox(height: 8),
                  Text(
                    '너무 짧거나 애매한 이름입니다. 추천 이름이나 원문 OCR을 함께 확인해 주세요.',
                    style: TextStyle(
                      color: t.warn,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (hasDuplicateName) ...[
                  const SizedBox(height: 8),
                  Text(
                    '다른 동반자와 이름이 같습니다. 같은 분이 아니라면 이름을 구분해 주세요.',
                    style: TextStyle(
                      color: t.warn,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (_recommendedNames.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    '자주 함께한 이름',
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
                    children: sortedRecommendations
                        .map(
                          (suggestion) => _OcrCompanionSuggestionChip(
                            name: suggestion.name,
                            caption: [
                              if (_scoreCompanionSuggestionMatch(
                                    _normalizeCompanionReviewName(nameInput),
                                    suggestion.name,
                                  ) >=
                                  6)
                                '유사도 높음',
                              '${suggestion.roundCount}회',
                              _formatSuggestionDate(suggestion.lastPlayedAt),
                            ].join(' · '),
                            onTap: () {
                              _nameController.text = suggestion.name;
                              _nameController.selection =
                                  TextSelection.fromPosition(
                                TextPosition(
                                  offset: _nameController.text.length,
                                ),
                              );
                              setState(() {});
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  '현재 합계 $total타',
                  style: TextStyle(
                    color: t.fg3,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CompanionHolePreviewTable(
            holes: _holes,
            onTapHole: _editHole,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: BoxDecoration(
            color: t.bg,
            border: Border(top: BorderSide(color: t.line)),
          ),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  ScoreOcrCompanionResult(
                    name: _nameController.text.trim().isEmpty
                        ? widget.companion.name
                        : _nameController.text.trim(),
                    holes: _holes,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: t.accent,
                foregroundColor: t.accentInk,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '동반자 보정 반영',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OcrCompanionSuggestionChip extends StatelessWidget {
  final String name;
  final String caption;
  final VoidCallback onTap;

  const _OcrCompanionSuggestionChip({
    required this.name,
    required this.caption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: t.surface2,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: t.fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                style: TextStyle(
                  color: t.fg3,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatSuggestionDate(DateTime date) {
  return '${date.month}/${date.day}';
}

class _CompanionHolePreviewTable extends StatelessWidget {
  final List<HoleScore> holes;
  final ValueChanged<int> onTapHole;

  const _CompanionHolePreviewTable({
    required this.holes,
    required this.onTapHole,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '홀별 타수',
            style: TextStyle(
              color: t.fg,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '동반자 홀을 눌러 타수를 수정하세요.',
            style: TextStyle(
              color: t.fg3,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: holes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.32,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final hole = holes[index];
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onTapHole(index),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: t.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${hole.holeNumber}H · Par ${hole.par}',
                        style: TextStyle(
                          color: t.fg3,
                          fontSize: 11,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${hole.strokes}타',
                        style: TextStyle(
                          color: t.fg,
                          fontSize: 18,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          fontFamily: GwTheme.numFont,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CompanionHoleEditSheet extends StatefulWidget {
  final HoleScore hole;

  const _CompanionHoleEditSheet({required this.hole});

  @override
  State<_CompanionHoleEditSheet> createState() =>
      _CompanionHoleEditSheetState();
}

class _CompanionHoleEditSheetState extends State<_CompanionHoleEditSheet> {
  late int _strokes;

  @override
  void initState() {
    super.initState();
    _strokes = widget.hole.strokes;
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.hole.holeNumber}번 홀 동반자 타수',
              style: TextStyle(
                color: t.fg,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Par ${widget.hole.par} 기준으로 타수를 보정합니다.',
              style: TextStyle(
                color: t.fg3,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            _ValuePickerRow(
              label: '타수',
              value: _strokes,
              values: List<int>.generate(12, (index) => index + 1),
              onChanged: (value) {
                setState(() {
                  _strokes = value < widget.hole.par ? widget.hole.par : value;
                });
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    widget.hole.copyWith(
                      strokes: _strokes < widget.hole.par
                          ? widget.hole.par
                          : _strokes,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: t.accent,
                  foregroundColor: t.accentInk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '타수 반영',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanionWarningBadge extends StatelessWidget {
  final String label;

  const _CompanionWarningBadge({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: t.warnBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: t.warn,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

List<String> _mergeCompanionNamesForPreview(
  Iterable<String> prioritized,
  Iterable<String> existing,
) {
  final merged = <String>[];
  final seen = <String>{};

  for (final name in [...prioritized, ...existing]) {
    final normalized = normalizeNameCandidate(name);
    if (normalized == null || !seen.add(normalized)) continue;
    merged.add(name);
    if (merged.length >= 4) break;
  }

  return merged;
}

Set<String> _findDuplicateCompanionNames(Iterable<String> names) {
  final seen = <String>{};
  final duplicates = <String>{};

  for (final name in names) {
    final normalized = _normalizeCompanionReviewName(name);
    if (normalized.isEmpty) continue;
    if (!seen.add(normalized)) {
      duplicates.add(normalized);
    }
  }

  return duplicates;
}

String _normalizeCompanionReviewName(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
}

int _scoreCompanionSuggestionMatch(String input, String candidate) {
  final normalizedCandidate = _normalizeCompanionReviewName(candidate);
  if (input.isEmpty || normalizedCandidate.isEmpty) return 0;
  if (input == normalizedCandidate) return 100;

  var score = 0;
  if (normalizedCandidate.startsWith(input) ||
      input.startsWith(normalizedCandidate)) {
    score += 8;
  }

  final prefixLength = _commonPrefixLength(input, normalizedCandidate);
  score += prefixLength * 2;

  final sharedChars =
      input.split('').where(normalizedCandidate.contains).length;
  score += sharedChars;

  score -= (input.length - normalizedCandidate.length).abs();
  return score;
}

int _commonPrefixLength(String a, String b) {
  final limit = a.length < b.length ? a.length : b.length;
  var count = 0;
  for (var index = 0; index < limit; index++) {
    if (a[index] != b[index]) break;
    count += 1;
  }
  return count;
}

bool _needsCompanionNameReview(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return true;
  if (trimmed.length <= 1) return true;
  if (RegExp(r'[0-9?]').hasMatch(trimmed)) return true;
  return false;
}

int _sumHoleStrokes(
  List<HoleScore> holes, {
  int start = 0,
  int? end,
}) {
  final safeStart = start.clamp(0, holes.length);
  final safeEnd = (end ?? holes.length).clamp(safeStart, holes.length);
  return holes
      .sublist(safeStart, safeEnd)
      .fold<int>(0, (sum, hole) => sum + hole.strokes);
}

String _scoreDeltaLabel(int relationToPar) {
  if (relationToPar == 0) return 'E';
  if (relationToPar > 0) return '+$relationToPar';
  return '$relationToPar';
}

Color _scoreDeltaColor(int relationToPar, GwTheme t) {
  if (relationToPar < 0) return t.accent;
  if (relationToPar == 0) return t.fg3;
  if (relationToPar == 1) return t.warn;
  return t.danger;
}
