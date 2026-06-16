import 'golf_event.dart';

enum FairwayResult {
  hit,
  miss,
  notApplicable;

  String get label => switch (this) {
        FairwayResult.hit => '성공',
        FairwayResult.miss => '실패',
        FairwayResult.notApplicable => '해당 없음',
      };

  static FairwayResult fromName(String? value) {
    return FairwayResult.values.firstWhere(
      (result) => result.name == value,
      orElse: () => FairwayResult.notApplicable,
    );
  }
}

class HoleScore {
  final int holeNumber;
  final int par;
  final int strokes;
  final int putts;
  final FairwayResult fairway;
  final bool ob;
  final int penalty;
  final String? memo;

  const HoleScore({
    required this.holeNumber,
    required this.par,
    required this.strokes,
    required this.putts,
    required this.fairway,
    required this.ob,
    required this.penalty,
    this.memo,
  });

  int get overPar => strokes - par;
  bool get gir => strokes - putts <= par - 2;

  HoleScore copyWith({
    int? par,
    int? strokes,
    int? putts,
    FairwayResult? fairway,
    bool? ob,
    int? penalty,
    String? memo,
  }) {
    return HoleScore(
      holeNumber: holeNumber,
      par: par ?? this.par,
      strokes: strokes ?? this.strokes,
      putts: putts ?? this.putts,
      fairway: fairway ?? this.fairway,
      ob: ob ?? this.ob,
      penalty: penalty ?? this.penalty,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toJson() => {
        'holeNumber': holeNumber,
        'par': par,
        'strokes': strokes,
        'putts': putts,
        'fairway': fairway.name,
        'ob': ob,
        'penalty': penalty,
        if (memo != null && memo!.trim().isNotEmpty) 'memo': memo!.trim(),
      };

  factory HoleScore.fromJson(Map<String, dynamic> json) {
    return HoleScore(
      holeNumber: (json['holeNumber'] as num?)?.toInt() ?? 1,
      par: (json['par'] as num?)?.toInt() ?? 4,
      strokes: (json['strokes'] as num?)?.toInt() ?? 4,
      putts: (json['putts'] as num?)?.toInt() ?? 2,
      fairway: FairwayResult.fromName(json['fairway'] as String?),
      ob: json['ob'] == true,
      penalty: (json['penalty'] as num?)?.toInt() ?? 0,
      memo: json['memo'] as String?,
    );
  }
}

class CompanionScore {
  final String name;
  final List<HoleScore> holes;

  const CompanionScore({
    required this.name,
    required this.holes,
  });

  int get totalScore => holes.fold(0, (sum, hole) => sum + hole.strokes);
  int get totalPar => holes.fold(0, (sum, hole) => sum + hole.par);
  int get overPar => totalScore - totalPar;

  Map<String, dynamic> toJson() => {
        'name': name,
        'holes': holes.map((hole) => hole.toJson()).toList(),
      };

  factory CompanionScore.fromJson(Map<String, dynamic> json) {
    return CompanionScore(
      name: json['name'] as String? ?? '',
      holes: (json['holes'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((hole) => HoleScore.fromJson(Map<String, dynamic>.from(hole)))
          .toList(),
    );
  }
}

class GolfRoundScore {
  final String id;
  final String scheduleId;
  final String courseName;
  final DateTime playedAt;
  final List<HoleScore> holes;
  final List<CompanionScore> companions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GolfRoundScore({
    required this.id,
    required this.scheduleId,
    required this.courseName,
    required this.playedAt,
    required this.holes,
    this.companions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalScore => holes.fold(0, (sum, hole) => sum + hole.strokes);
  int get totalPar => holes.fold(0, (sum, hole) => sum + hole.par);
  int get overPar => totalScore - totalPar;
  int get totalPutts => holes.fold(0, (sum, hole) => sum + hole.putts);
  int get obCount => holes.where((hole) => hole.ob).length;
  int get penaltyCount => holes.fold(0, (sum, hole) => sum + hole.penalty);
  int get girCount => holes.where((hole) => hole.gir).length;
  int get fairwayHitCount =>
      holes.where((hole) => hole.fairway == FairwayResult.hit).length;
  int get fairwayTargetCount =>
      holes.where((hole) => hole.fairway != FairwayResult.notApplicable).length;

  double get fairwayRate =>
      fairwayTargetCount == 0 ? 0 : fairwayHitCount / fairwayTargetCount;
  double get girRate => holes.isEmpty ? 0 : girCount / holes.length;

  String get overParLabel {
    if (overPar == 0) return 'E';
    if (overPar > 0) return '+$overPar';
    return '$overPar';
  }

  GolfRoundScore copyWith({
    List<HoleScore>? holes,
    List<CompanionScore>? companions,
    DateTime? updatedAt,
  }) {
    return GolfRoundScore(
      id: id,
      scheduleId: scheduleId,
      courseName: courseName,
      playedAt: playedAt,
      holes: holes ?? this.holes,
      companions: companions ?? this.companions,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scheduleId': scheduleId,
        'courseName': courseName,
        'playedAt': playedAt.millisecondsSinceEpoch,
        'holes': holes.map((hole) => hole.toJson()).toList(),
        'companions':
            companions.map((companion) => companion.toJson()).toList(),
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory GolfRoundScore.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return GolfRoundScore(
      id: json['id'] as String? ?? '',
      scheduleId: json['scheduleId'] as String? ?? '',
      courseName: json['courseName'] as String? ?? '',
      playedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['playedAt'] as num?)?.toInt() ?? now.millisecondsSinceEpoch,
      ),
      holes: (json['holes'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((hole) => HoleScore.fromJson(Map<String, dynamic>.from(hole)))
          .toList(),
      companions: (json['companions'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((companion) =>
              CompanionScore.fromJson(Map<String, dynamic>.from(companion)))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num?)?.toInt() ?? now.millisecondsSinceEpoch,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['updatedAt'] as num?)?.toInt() ?? now.millisecondsSinceEpoch,
      ),
    );
  }

  factory GolfRoundScore.emptyForEvent(GolfEvent event) {
    final now = DateTime.now();
    return GolfRoundScore(
      id: 'score_${event.id}',
      scheduleId: event.id,
      courseName: event.courseName ?? event.location ?? event.title,
      playedAt: event.startDate,
      holes: List.generate(18, (index) {
        final hole = index + 1;
        final par = _defaultParForHole(hole);
        return HoleScore(
          holeNumber: hole,
          par: par,
          strokes: par,
          putts: 2,
          fairway: par == 3
              ? FairwayResult.notApplicable
              : FairwayResult.notApplicable,
          ob: false,
          penalty: 0,
        );
      }),
      createdAt: now,
      updatedAt: now,
    );
  }
}

int _defaultParForHole(int hole) {
  if (hole == 3 || hole == 8 || hole == 12 || hole == 16) return 3;
  if (hole == 5 || hole == 9 || hole == 14 || hole == 18) return 5;
  return 4;
}
