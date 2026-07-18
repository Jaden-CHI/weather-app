import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/services/ocr_companion_matcher.dart';
import 'package:weather_app/services/scorecard_service.dart';

void main() {
  group('OCR companion matcher', () {
    test('현재 스코어카드 동반자와 정확히 같으면 바로 연결한다', () {
      final result = buildOcrCompanionResolutions(
        scannedNames: const ['한 지 민'],
        currentCompanionNames: const ['한지민'],
        recommendedNames: const [],
      );

      expect(result, hasLength(1));
      expect(result.first.resolvedName, '한지민');
      expect(result.first.matchScore, 100);
      expect(result.first.needsConfirmation, isFalse);
    });

    test('영문 OCR 치환이 섞여도 기존 추천 이름으로 보정한다', () {
      final result = resolveOcrCompanionNameWithScore(
        rawName: 'W1KY',
        currentCompanionNames: const [],
        recommendedNames: [
          CompanionNameSuggestion(
            name: 'WIKY',
            roundCount: 3,
            lastPlayedAt: DateTime(2026, 7, 1),
          ),
        ],
      );

      expect(result.resolvedName, 'WIKY');
      expect(result.matchScore, greaterThanOrEqualTo(90));
      expect(result.needsConfirmation, isTrue);
    });

    test('동점이면 더 자주 함께 친 추천 동반자를 우선한다', () {
      final result = resolveOcrCompanionNameWithScore(
        rawName: '민호',
        currentCompanionNames: const [],
        recommendedNames: [
          CompanionNameSuggestion(
            name: '이민호',
            roundCount: 7,
            lastPlayedAt: DateTime(2026, 7, 2),
          ),
          CompanionNameSuggestion(
            name: '박민호',
            roundCount: 2,
            lastPlayedAt: DateTime(2026, 7, 4),
          ),
        ],
      );

      expect(result.resolvedName, '이민호');
    });

    test('애매한 한 글자 이름은 검토 필요로 남긴다', () {
      final result = resolveOcrCompanionNameWithScore(
        rawName: '김',
        currentCompanionNames: const ['김채규'],
        recommendedNames: const [],
      );

      expect(result.needsConfirmation, isTrue);
    });

    test('중복 스캔 이름은 하나로 합친다', () {
      final result = buildOcrCompanionResolutions(
        scannedNames: const ['김채규 님', '김채규', '김 채 규'],
        currentCompanionNames: const [],
        recommendedNames: const [],
      );

      expect(result, hasLength(1));
      expect(result.first.resolvedName, '김채규 님');
    });
  });
}
