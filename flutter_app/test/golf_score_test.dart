import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/models/golf_score.dart';

void main() {
  List<HoleScore> buildTrackedHoles({
    required int trackedPutts,
    required int trackedFairways,
  }) {
    const pars = <int>[
      4,
      4,
      3,
      4,
      5,
      4,
      4,
      3,
      5,
      4,
      4,
      3,
      4,
      5,
      4,
      3,
      4,
      5,
    ];

    var puttCount = 0;
    var fairwayCount = 0;

    return List<HoleScore>.generate(18, (index) {
      final par = pars[index];
      final canTrackFairway = par != 3;
      final puttsTracked = puttCount < trackedPutts;
      if (puttsTracked) {
        puttCount += 1;
      }

      FairwayResult fairway = FairwayResult.notApplicable;
      if (canTrackFairway) {
        if (fairwayCount < trackedFairways) {
          fairway =
              fairwayCount.isEven ? FairwayResult.hit : FairwayResult.miss;
          fairwayCount += 1;
        } else {
          fairway = FairwayResult.notApplicable;
        }
      }

      return HoleScore(
        holeNumber: index + 1,
        par: par,
        strokes: par,
        putts: 2,
        puttsTracked: puttsTracked,
        fairway: fairway,
        ob: false,
        penalty: 0,
      );
    });
  }

  GolfRoundScore buildScore({
    required int trackedPutts,
    required int trackedFairways,
  }) {
    final now = DateTime(2026, 7, 4);
    return GolfRoundScore(
      id: 'score_1',
      scheduleId: 'schedule_1',
      courseName: '테스트 골프장',
      playedAt: now,
      holes: buildTrackedHoles(
        trackedPutts: trackedPutts,
        trackedFairways: trackedFairways,
      ),
      createdAt: now,
      updatedAt: now,
    );
  }

  group('GolfRoundScore tracking completion', () {
    test('퍼트와 페어웨이 진행률 평균으로 완성도를 계산한다', () {
      final score = buildScore(trackedPutts: 9, trackedFairways: 7);

      expect(score.puttTrackingProgress, closeTo(0.5, 0.0001));
      expect(score.fairwayTrackingProgress, closeTo(0.5, 0.0001));
      expect(score.trackingCompletionProgress, closeTo(0.5, 0.0001));
      expect(score.trackingCompletionPercent, 50);
    });

    test('모든 추적이 끝나면 완성도 100%를 반환한다', () {
      final score = buildScore(trackedPutts: 18, trackedFairways: 14);

      expect(score.hasCompletePuttTracking, isTrue);
      expect(score.hasCompleteFairwayTracking, isTrue);
      expect(score.trackingCompletionProgress, 1.0);
      expect(score.trackingCompletionPercent, 100);
      expect(score.incompleteHoleCount, 0);
      expect(score.firstIncompleteHoleNumber, isNull);
      expect(score.trackingStage, GolfRoundTrackingStage.complete);
      expect(score.trackingStageLabel, '세부 기록 완료');
    });

    test('아직 세부 지표를 입력하지 않으면 스코어만 저장 상태를 반환한다', () {
      final score = buildScore(trackedPutts: 0, trackedFairways: 0);

      expect(score.hasAnyTrackingData, isFalse);
      expect(score.trackingStage, GolfRoundTrackingStage.scoreOnly);
      expect(score.trackingStageLabel, '스코어 저장');
    });

    test('일부 세부 지표가 기록되면 세부 기록 일부 상태를 반환한다', () {
      final score = buildScore(trackedPutts: 5, trackedFairways: 4);

      expect(score.hasAnyTrackingData, isTrue);
      expect(score.trackingCompletionPercent, lessThan(80));
      expect(score.trackingStage, GolfRoundTrackingStage.inProgress);
      expect(score.trackingStageLabel, '세부 기록 일부');
    });

    test('세부 지표 기록률이 높으면 거의 완료 상태를 반환한다', () {
      final score = buildScore(trackedPutts: 16, trackedFairways: 12);

      expect(score.trackingCompletionPercent, greaterThanOrEqualTo(80));
      expect(score.incompleteHoleCount, greaterThan(0));
      expect(score.trackingStage, GolfRoundTrackingStage.nearlyComplete);
      expect(score.trackingStageLabel, '세부 기록 거의 완료');
    });
  });
}
