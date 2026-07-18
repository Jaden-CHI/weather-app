import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/models/golf_score.dart';
import 'package:weather_app/services/score_ocr_parser.dart';

void main() {
  List<HoleScore> baseHoles() => List.generate(
        18,
        (index) => HoleScore(
          holeNumber: index + 1,
          par: 4,
          strokes: 4,
          putts: 2,
          puttsTracked: false,
          fairway: FairwayResult.notApplicable,
          ob: false,
          penalty: 0,
        ),
      );

  group('parseScorecardText', () {
    test('이름 정규화가 공백과 구두점을 제거해 OCR 이름 매칭을 돕는다', () {
      expect(normalizeNameCandidate('M.N.'), 'MN');
      expect(normalizeNameCandidate('M N'), 'MN');
      expect(normalizeNameCandidate('이 병 헌'), '이병헌');
      expect(normalizeNameCandidate(' 한-지·민 '), '한지민');
      expect(normalizeNameCandidate('김채규 님'), '김채규');
    });

    test('par, score, putt row를 읽는다', () {
      const text = '''
HOLE 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18
PAR 4 4 3 4 5 4 4 3 5 4 4 3 4 5 4 3 4 5
SCORE 5 4 3 5 6 4 5 3 6 4 5 3 4 6 5 3 5 5
PUTT 2 2 1 2 2 2 2 1 2 2 2 1 2 2 2 1 2 2
''';

      final result = parseScorecardText(text, baseHoles());

      expect(result.holes.first.par, 4);
      expect(result.holes[2].par, 3);
      expect(result.holes.first.strokes, 5);
      expect(result.holes[2].strokes, 3);
      expect(result.holes.first.putts, 2);
      expect(result.holes[2].putts, 1);
      expect(result.holes.first.puttsTracked, isTrue);
      expect(result.holes[2].puttsTracked, isTrue);
    });

    test('이름과 점수행이 같은 줄에 있으면 동반자 점수를 읽는다', () {
      const text = '''
SCORE 5 4 3 5 6 4 5 3 6 4 5 3 4 6 5 3 5 5
민수 4 5 3 4 5 5 4 3 5 4 4 3 5 5 4 3 4 5
지훈 5 5 4 5 6 5 5 4 6 5 5 4 5 6 5 4 5 6
''';

      final result = parseScorecardText(text, baseHoles());

      expect(result.companions.length, 2);
      expect(result.companions[0].name, '민수');
      expect(result.companions[0].holes.first.strokes, 4);
      expect(result.companions[1].name, '지훈');
      expect(result.companions[1].holes[1].strokes, 5);
    });

    test('이름 줄 다음 점수 줄도 동반자 점수로 묶는다', () {
      const text = '''
SCORE 5 4 3 5 6 4 5 3 6 4 5 3 4 6 5 3 5 5
민수
4 5 3 4 5 5 4 3 5 4 4 3 5 5 4 3 4 5
지훈
5 5 4 5 6 5 5 4 6 5 5 4 5 6 5 4 5 6
''';

      final result = parseScorecardText(text, baseHoles());

      expect(result.companions.length, 2);
      expect(result.companions[0].name, '민수');
      expect(result.companions[0].holes[3].strokes, 4);
      expect(result.companions[1].name, '지훈');
      expect(result.companions[1].holes[8].strokes, 6);
    });

    test('동반자 이름 후보를 중복 없이 합친다', () {
      const text = '''
민수
민수 4 5 3 4 5 5 4 3 5
지훈
''';

      final result = parseScorecardText(text, baseHoles());

      expect(result.companionNames, containsAll(<String>['민수', '지훈']));
      expect(
        result.companionNames.where((name) => name == '민수').length,
        1,
      );
    });

    test('전후반 9홀 분리 + 파대비 점수 표기를 18홀 실타수로 합친다', () {
      const text = '''
레이크
PAR 5 4 3 4 4 4 3 5 4 36
이병헌 0 2 1 1 3 2 2 2 1 50
한지민 0 1 1 0 1 0 2 1 1 43
마운틴
PAR 4 5 3 4 5 4 3 4 4 36 72
이병헌 1 4 1 1 3 2 1 1 0 50 100
한지민 1 2 1 0 3 1 1 1 0 44 87
''';

      final result = parseScorecardText(text, baseHoles());

      expect(result.holes.length, 18);
      expect(result.holes.first.par, 5);
      expect(result.holes[9].par, 4);
      expect(result.holes.first.strokes, 5);
      expect(result.holes[1].strokes, 6);
      expect(result.holes[9].strokes, 5);
      expect(result.holes[10].strokes, 9);
      expect(
        result.holes.fold<int>(0, (sum, hole) => sum + hole.strokes),
        100,
      );

      expect(result.companions.length, 1);
      expect(result.companions.first.name, '한지민');
      expect(
        result.companions.first.holes.fold<int>(
          0,
          (sum, hole) => sum + hole.strokes,
        ),
        89,
      );
    });

    test('여러 합계 값 중 마지막 총합으로 파대비 점수를 판단한다', () {
      const text = '''
PAR 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4
SCORE 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 41 42 83
''';

      final result = parseScorecardText(text, baseHoles());

      expect(
        result.holes.fold<int>(0, (sum, hole) => sum + hole.strokes),
        83,
      );
      expect(result.holes.first.strokes, 5);
      expect(result.holes[11].strokes, 4);
    });

    test('영문 코스 헤더는 동반자 이름으로 오인하지 않는다', () {
      const text = '''
RIVERSIDE GOLF CLUB
DATE 2015/12/14
SCORE 5 4 4 4 5 4 4 4 5 5 4 4 5 4 4 4 5 4
HAN
4 5 4 4 3 5 4 3 4 4 5 4 4 3 5 4 3 4
''';

      final result = parseScorecardText(text, baseHoles());

      expect(result.companionNames, contains('HAN'));
      expect(result.companionNames, isNot(contains('RIVERSIDE')));
      expect(result.companionNames, isNot(contains('CLUB')));
      expect(result.companions.length, 1);
      expect(result.companions.first.name, 'HAN');
    });

    test('OCR 숫자 오인식 O I Z S B를 숫자로 보정한다', () {
      const text = '''
PAR 4 4 3 4 5 4 4 3 5 4 4 3 4 5 4 3 4 5
SCORE 5 4 3 4 S 4 4 3 5 4 4 3 4 5 4 3 4 B
WIKY O I O I I I O I O 41
''';

      final result = parseScorecardText(text, baseHoles());

      expect(result.holes[4].strokes, 5);
      expect(result.holes[17].strokes, 8);
      expect(result.holes.every((hole) => hole.puttsTracked), isFalse);
      expect(result.companions.length, 1);
      expect(result.companions.first.name, 'WIKY');
      expect(result.companions.first.holes[0].strokes, 4);
      expect(result.companions.first.holes[1].strokes, 5);
      expect(
        result.companions.first.holes.take(9).fold<int>(
              0,
              (sum, hole) => sum + hole.strokes,
            ),
        41,
      );
    });

    test('공백 없이 붙은 OCR 상대타수 문자열도 홀별 점수로 분해한다', () {
      const text = '''
PAR 5 4 3 4 4 4 5 3 4
SCORE O/OO3///O
''';

      final result = parseScorecardText(text, baseHoles());

      expect(
        result.holes.take(9).map((hole) => hole.strokes).toList(),
        <int>[5, 5, 3, 4, 7, 5, 6, 4, 4],
      );
    });

    test('드림파크형 한국 스코어카드에서 본인 이름은 동반자 목록에서 제외한다', () {
      const text = '''
DATE 2026/07/05
TEE OFF 파크 06:57
NAME 김채규 님
OUT 1 2 3 4 5 6 7 8 9 SUB
PAR 4 5 3 4 4 3 5 4 4 36
김채규 2 1 1 0 1 1 4 0 1 47
이민호 2 1 1 2 3 2 0 2 1 50
박서준 3 3 3 2 2 2 0 4 2 57
IN 10 11 12 13 14 15 16 17 18 SUB TOT
PAR 4 4 5 4 3 4 5 3 4 36 72
김채규 2 1 1 2 1 1 0 1 0 45 92
이민호 0 1 0 3 1 1 1 1 0 44 94
박서준 0 2 2 4 3 4 1 3 4 59 116
''';

      final result = parseScorecardText(text, baseHoles());

      expect(result.holes.length, 18);
      expect(result.holes.first.par, 4);
      expect(result.holes[1].par, 5);
      expect(result.holes[9].par, 4);
      expect(result.holes.first.strokes, 6);
      expect(result.holes[9].strokes, 6);
      expect(
        result.holes.fold<int>(0, (sum, hole) => sum + hole.strokes),
        92,
      );
      expect(result.companionNames, isNot(contains('김채규')));
      expect(result.companionNames, containsAll(<String>['이민호', '박서준']));
    });

    test('PAR 행이 없어도 티 거리 행으로 파를 추론한다', () {
      const text = '''
LAKE COURSE
HOLE 1 2 3 4 5 6 7 8 9
BLUE 510 405 180 355 350 355 485 155 330
WIKY 0 0 0 3 1 1 1 0 4 41
''';

      final result = parseScorecardText(text, baseHoles());

      expect(
        result.holes.take(9).map((hole) => hole.par).toList(),
        <int>[5, 4, 3, 4, 4, 4, 5, 3, 4],
      );
      expect(result.holes.first.strokes, 5);
      expect(result.holes[2].strokes, 3);
      expect(result.companions, isEmpty);
    });

    test('여러 티 행이 있으면 같은 티 색의 전후반 거리 행을 우선 묶는다', () {
      const text = '''
HOLE 1 2 3 4 5 6 7 8 9
BLUE 510 405 180 355 350 355 485 155 330
WHITE 490 390 150 345 315 335 470 125 320
HOLE 10 11 12 13 14 15 16 17 18
BLUE 402 544 355 181 545 325 179 366 438
WHITE 371 506 320 155 515 320 168 343 411
SCORE 5 4 3 4 4 4 5 3 4 4 5 4 3 5 4 3 4 4
''';

      final result = parseScorecardText(text, baseHoles());

      expect(
        result.holes.map((hole) => hole.par).toList(),
        <int>[5, 4, 3, 4, 4, 4, 5, 3, 4, 4, 5, 4, 3, 5, 4, 3, 4, 4],
      );
      expect(result.holes[9].par, 4);
      expect(result.holes[10].par, 5);
      expect(result.holes[12].par, 3);
    });

    test('짧은 영문 이니셜 이름도 동반자 이름으로 묶는다', () {
      const text = '''
SCORE 5 4 3 5 6 4 5 3 6 4 5 3 4 6 5 3 5 5
J K
4 5 3 4 5 5 4 3 5 4 4 3 5 5 4 3 4 5
M.N.
5 5 4 5 6 5 5 4 6 5 5 4 5 6 5 4 5 6
''';

      final result = parseScorecardText(text, baseHoles());

      expect(result.companions.length, 2);
      expect(result.companions[0].name, 'JK');
      expect(result.companions[1].name, 'MN');
      expect(result.companionNames, containsAll(<String>['JK', 'MN']));
    });

    test('띄어쓰기된 한글 이름도 하나의 동반자 이름으로 묶는다', () {
      const text = '''
SCORE 5 4 3 5 6 4 5 3 6 4 5 3 4 6 5 3 5 5
이 병 헌
4 5 3 4 5 5 4 3 5 4 4 3 5 5 4 3 4 5
한 지 민
5 5 4 5 6 5 5 4 6 5 5 4 5 6 5 4 5 6
''';

      final result = parseScorecardText(text, baseHoles());

      expect(result.companions.length, 2);
      expect(result.companions[0].name, '이병헌');
      expect(result.companions[1].name, '한지민');
      expect(result.companionNames, containsAll(<String>['이병헌', '한지민']));
    });

    test('슬래시와 막대 기호도 OCR 상대타수 1로 보정한다', () {
      const text = '''
PAR 5 4 3 4 4 4 5 3 4 4 5 4 3 5 4 3 4 4
SCORE O / | ! O / O / O 41 O / O | / / ! O O 41 82
''';

      final result = parseScorecardText(text, baseHoles());

      expect(
        result.holes.take(9).map((hole) => hole.strokes).toList(),
        <int>[5, 5, 4, 5, 4, 5, 5, 4, 4],
      );
      expect(
        result.holes.skip(9).take(9).map((hole) => hole.strokes).toList(),
        <int>[4, 6, 4, 4, 6, 5, 4, 4, 4],
      );
      expect(
        result.holes.fold<int>(0, (sum, hole) => sum + hole.strokes),
        82,
      );
    });

    test('같은 이름이 전후반 코스 섹션에 반복되면 한 사람의 18홀로 합친다', () {
      const text = '''
LAKE COURSE
PAR 5 4 3 4 4 4 5 3 4 36
WIKY 0 0 0 0 1 1 1 1 1 41
CREEK COURSE
PAR 5 4 4 3 4 3 5 4 4 36 72
WIKY 0 1 0 0 1 0 1 1 0 39 80
''';

      final result = parseScorecardText(text, baseHoles());

      expect(result.holes.length, 18);
      expect(
        result.holes.take(9).map((hole) => hole.par).toList(),
        <int>[5, 4, 3, 4, 4, 4, 5, 3, 4],
      );
      expect(
        result.holes.skip(9).take(9).map((hole) => hole.par).toList(),
        <int>[5, 4, 4, 3, 4, 3, 5, 4, 4],
      );
      expect(
        result.holes.take(9).map((hole) => hole.strokes).toList(),
        <int>[5, 4, 3, 4, 5, 5, 6, 4, 5],
      );
      expect(
        result.holes.skip(9).take(9).map((hole) => hole.strokes).toList(),
        <int>[5, 5, 4, 3, 5, 3, 6, 5, 4],
      );
      expect(
        result.holes.fold<int>(0, (sum, hole) => sum + hole.strokes),
        81,
      );
      expect(result.companions, isEmpty);
      expect(result.companionNames, isNot(contains('WIKY')));
    });

    test('Urban CC 샘플처럼 전후반 상대타수와 동반자 점수를 함께 읽는다', () {
      const text = '''
URBAN CC
DATE 2015/12/14
TEE OFF PM 12:52
이병헌 101
레이크 1 2 3 4 5 6 7 8 9 TOTAL
PAR 5 4 3 4 4 4 3 5 4 36
이병헌 0 2 1 1 3 2 2 2 1 50
한지민 0 1 1 0 1 0 2 1 1 43
이민호 0 4 2 1 3 1 1 2 0 50
마운틴 1 2 3 4 5 6 7 8 9 TOTAL
PAR 4 5 3 4 5 4 3 4 4 36 72
이병헌 1 4 1 1 3 2 1 2 0 51 101
한지민 1 2 1 0 3 1 1 1 0 44 87
이민호 4 3 1 3 4 2 2 2 0 57 107
''';

      final result = parseScorecardText(text, baseHoles());

      expect(result.holes.length, 18);
      expect(
        result.holes.take(9).map((hole) => hole.strokes).toList(),
        <int>[5, 6, 4, 5, 7, 6, 5, 7, 5],
      );
      expect(
        result.holes.skip(9).take(9).map((hole) => hole.strokes).toList(),
        <int>[5, 9, 4, 5, 8, 6, 4, 6, 4],
      );
      expect(
        result.holes.fold<int>(0, (sum, hole) => sum + hole.strokes),
        101,
      );
      expect(result.companions.length, 2);
      expect(result.companions[0].name, '한지민');
      expect(result.companions[1].name, '이민호');
      expect(
        result.companions[0].holes
            .fold<int>(0, (sum, hole) => sum + hole.strokes),
        89,
      );
      expect(
        result.companions[1].holes
            .fold<int>(0, (sum, hole) => sum + hole.strokes),
        107,
      );
    });

    test('드림파크 실물형 OCR 텍스트에서도 헤더 이름과 코스 표기를 분리한다', () {
      const text = '''
DATE 2026/07/05
TEE OFF 파크 06:57
NAME 김채규 님
Info Dream Park
( 파크 ) CORSE
OUT 1 2 3 4 5 6 7 8 9 SUB
PAR 4 5 3 4 4 3 5 4 4 36
김채규 2 1 1 0 1 1 4 0 1 47
이민호 2 1 1 2 3 2 0 2 1 50
박서준 3 3 3 2 2 2 0 4 2 57
IN 10 11 12 13 14 15 16 17 18 SUB TOT
PAR 4 4 5 4 3 4 5 3 4 36 72
김채규 2 1 1 2 1 1 0 1 0 45 92
이민호 0 1 0 3 1 1 1 1 0 44 94
박서준 0 2 2 4 3 4 1 3 4 59 116
''';

      final result = parseScorecardText(text, baseHoles());

      expect(
        result.holes.fold<int>(0, (sum, hole) => sum + hole.strokes),
        92,
      );
      expect(result.companions.length, 2);
      expect(result.companions[0].name, '이민호');
      expect(result.companions[1].name, '박서준');
      expect(result.companionNames, isNot(contains('김채규')));
      expect(result.companionNames, isNot(contains('파크')));
      expect(result.companionNames, isNot(contains('Dream')));
    });

    test('SMARTSCORE 카드 상단에서 날짜 시간 골프장명과 본인 이름을 추출한다', () {
      const text = '''
BALIOS COUNTRY CLUB
DATE 2022/11/06
TEE OFF PM 12:20
지우람 92
남 1 2 3 4 5 6 7 8 9 TOTAL
PAR 4 3 4 5 4 4 3 5 4 36
지우람 1 2 3 1 0 0 2 0 1 46
동 1 2 3 4 5 6 7 8 9 TOTAL
PAR 4 5 4 3 4 5 4 3 4 36 72
지우람 1 2 2 2 0 1 2 0 0 46 92
''';

      final result = parseScorecardText(text, baseHoles());

      expect(result.courseName, 'BALIOS COUNTRY CLUB');
      expect(result.playerName, '지우람');
      expect(result.playedAt, DateTime(2022, 11, 6, 12, 20));
      expect(
        result.holes.fold<int>(0, (sum, hole) => sum + hole.strokes),
        92,
      );
    });

    test('벨라스톤 실기기 OCR 원문에서 박재남과 동반자 총타를 유지한다', () {
      const text = '''
97
벨라스톤
2024.04.13 07:45
SMARTSCORE
벨라 1 2 3 4 5 6 7 8 9 합
PAR 4 4 4 3 4 5 4 3 5 36
지우람 0 2 0 1 3 3 1 0 2 48
신형철 0 1 2 1 2 2 3 2 1 50
박재남 1 2 3 1 1 0 1 0 0 45
고영춘 1 0 2 0 1 0 3 1 1 45
스톤 1 2 3 4 5 6 7 8 9 합
PAR 5 4 4 3 4 5 3 4 4 36
지우람 1 1 1 2 1 3 2 1 1 49 97
신형철 2 2 1 0 1 2 1 2 3 50 100
박재남 5 1 1 0 2 1 0 0 4 50 95
고영춘 3 2 1 3 4 0 1 3 2 55 100
Black 362 410 338 148 385 535 356 165 568 546 396 440 175 505 485 189 351 420
Blue 343 365 313 125 351 495 317 142 529 527 384 398 155 487 443 166 329 376
White 320 318 286 94 322 468 294 125 494 500 363 375 145 465 413 138 304 355
Red 265 295 156 81 301 390 212 123 464 438 274 318 117 393 338 128 260 308
''';

      final bellastoneBaseHoles = <int>[
        4,
        4,
        4,
        3,
        4,
        5,
        4,
        3,
        5,
        5,
        4,
        4,
        3,
        4,
        5,
        3,
        4,
        4,
      ].asMap().entries.map((entry) {
        return HoleScore(
          holeNumber: entry.key + 1,
          par: entry.value,
          strokes: entry.value,
          putts: 2,
          puttsTracked: false,
          fairway: FairwayResult.notApplicable,
          ob: false,
          penalty: 0,
        );
      }).toList(growable: false);

      final result = parseScorecardText(text, bellastoneBaseHoles);

      expect(result.courseName, '벨라스톤');
      expect(result.playerName, '지우람');
      expect(result.playedAt, DateTime(2024, 4, 13, 7, 45));
      expect(
        result.holes.fold<int>(0, (sum, hole) => sum + hole.strokes),
        97,
      );
      expect(result.companions.map((item) => item.name).toList(), <String>[
        '신형철',
        '박재남',
        '고영춘',
      ]);
      expect(
        result.companions.map((item) {
          return item.holes.fold<int>(0, (sum, hole) => sum + hole.strokes);
        }).toList(),
        <int>[100, 95, 100],
      );
      expect(result.companionNames, isNot(contains('지우람')));
      expect(result.companionNames, contains('박재남'));
    });

    test('벨라스톤 OCR에서 분절된 한글 동반자 이름도 하나로 붙여 읽는다', () {
      const text = '''
97
벨라스톤
2024.04.13 07:45
SMARTSCORE
벨라 1 2 3 4 5 6 7 8 9 합
PAR 4 4 4 3 4 5 4 3 5 36
지우람 0 2 0 1 3 3 1 0 2 48
신형철 0 1 2 1 2 2 3 2 1 50
박재 남 1 2 3 1 1 0 1 0 0 45
고 영춘 1 0 2 0 1 0 3 1 1 45
스톤 1 2 3 4 5 6 7 8 9 합
PAR 5 4 4 3 4 5 3 4 4 36
지 우 람 1 1 1 2 1 3 2 1 1 49 97
신 형철 2 2 1 0 1 2 1 2 3 50 100
박 재남 5 1 1 0 2 1 0 0 4 50 95
고영 춘 3 2 1 3 4 0 1 3 2 55 100
''';

      final bellastoneBaseHoles = <int>[
        4,
        4,
        4,
        3,
        4,
        5,
        4,
        3,
        5,
        5,
        4,
        4,
        3,
        4,
        5,
        3,
        4,
        4,
      ].asMap().entries.map((entry) {
        return HoleScore(
          holeNumber: entry.key + 1,
          par: entry.value,
          strokes: entry.value,
          putts: 2,
          puttsTracked: false,
          fairway: FairwayResult.notApplicable,
          ob: false,
          penalty: 0,
        );
      }).toList(growable: false);

      final result = parseScorecardText(text, bellastoneBaseHoles);

      expect(result.companions.map((item) => item.name).toList(), <String>[
        '신형철',
        '박재남',
        '고영춘',
      ]);
      expect(
        result.companions.map((item) {
          return item.holes.fold<int>(0, (sum, hole) => sum + hole.strokes);
        }).toList(),
        <int>[100, 95, 100],
      );
      expect(result.companionNames, isNot(contains('지우람')));
    });

    test('SMARTSCORE 광고 문구는 골프장명으로 오인하지 않는다', () {
      const text = '''
DATE 2022/11/06
TEE OFF PM 12:20
SMARTSCORE NO.1 GOLF SERVICE
전국 골프장 스코어 전송
스코어카드 입력대행/직접입력 서비스
스코어카드 무료 출력 서비스
지우람 92
남 1 2 3 4 5 6 7 8 9 TOTAL
PAR 4 3 4 5 4 4 3 5 4 36
지우람 1 2 3 1 0 0 2 0 1 46
동 1 2 3 4 5 6 7 8 9 TOTAL
PAR 4 5 4 3 4 5 4 3 4 36 72
지우람 1 2 2 2 0 1 2 0 0 46 92
''';

      final result = parseScorecardText(text, baseHoles());

      expect(result.courseName, isNull);
      expect(result.playerName, '지우람');
      expect(
        result.holes.fold<int>(0, (sum, hole) => sum + hole.strokes),
        92,
      );
    });

    test('분리된 영문 코스 헤더도 하나의 골프장명으로 합친다', () {
      const text = '''
Northpalm
Country Club
DATE 2024/06/22
TEE OFF PM 12:39
지우람 93
EAST 1 2 3 4 5 6 7 8 9 TOTAL
PAR 4 5 4 4 3 4 4 3 5 36
지우람 0 2 1 1 2 1 1 0 2 46
WEST 1 2 3 4 5 6 7 8 9 TOTAL
PAR 5 4 3 4 5 3 4 4 4 36 72
지우람 2 1 0 3 2 1 1 0 1 47 93
''';

      final result = parseScorecardText(text, baseHoles());

      expect(result.courseName, 'Northpalm Country Club');
      expect(result.playerName, '지우람');
      expect(result.playedAt, DateTime(2024, 6, 22, 12, 39));
    });

    test('세 줄로 끊긴 영문 코스 헤더도 하나의 골프장명으로 합친다', () {
      const text = '''
Northpalm
Country
Club
DATE 2024/06/22
TEE OFF PM 12:39
지우람 93
EAST 1 2 3 4 5 6 7 8 9 TOTAL
PAR 4 5 4 4 3 4 4 3 5 36
지우람 0 2 1 1 2 1 1 0 2 46
WEST 1 2 3 4 5 6 7 8 9 TOTAL
PAR 5 4 3 4 5 3 4 4 4 36 72
지우람 2 1 0 3 2 1 1 0 1 47 93
''';

      final result = parseScorecardText(text, baseHoles());

      expect(result.courseName, 'Northpalm Country Club');
      expect(result.playerName, '지우람');
      expect(result.playedAt, DateTime(2024, 6, 22, 12, 39));
    });

    test('The Heaven SMARTSCORE 카드도 코스명 날짜 시간과 본인 점수를 읽는다', () {
      const text = '''
THE HEAVEN RESORT
DATE 2024/05/25
TEE OFF AM 10:56
지우람 90
SOUTH 1 2 3 4 5 6 7 8 9 TOTAL
PAR 4 5 3 4 4 3 4 4 5 36
지우람 0 2 1 1 2 1 0 0 1 44
WEST 1 2 3 4 5 6 7 8 9 TOTAL
PAR 4 4 4 5 3 5 4 3 4 36 72
지우람 1 1 2 2 0 0 3 0 1 46 90
''';

      final result = parseScorecardText(text, baseHoles());

      expect(result.courseName, 'THE HEAVEN RESORT');
      expect(result.playerName, '지우람');
      expect(result.playedAt, DateTime(2024, 5, 25, 10, 56));
      expect(
        result.holes.fold<int>(0, (sum, hole) => sum + hole.strokes),
        90,
      );
    });

    test('드림파크 SMARTSCORE 카드에서 한글 코스명과 동반자 점수를 함께 읽는다', () {
      const text = '''
드림파크
DATE 2024/08/02
TEE OFF AM 07:28
지우람 92
DREAM OUT 1 2 3 4 5 6 7 8 9 TOTAL
PAR 4 4 4 5 3 4 4 3 5 36
지우람 1 3 0 1 1 0 1 1 0 44
신형철 0 2 4 4 1 2 0 3 2 54
고영춘 1 1 1 0 2 1 3 0 0 45
DREAM IN 1 2 3 4 5 6 7 8 9 TOTAL
PAR 4 4 5 3 4 4 5 3 4 36 72
지우람 2 1 0 2 2 1 1 1 2 48 92
신형철 0 0 0 2 3 3 0 0 0 44 98
고영춘 1 0 3 2 4 3 4 0 4 57 102
''';

      final result = parseScorecardText(text, baseHoles());

      expect(result.courseName, '드림파크');
      expect(result.playerName, '지우람');
      expect(result.playedAt, DateTime(2024, 8, 2, 7, 28));
      expect(result.companions.length, 2);
      expect(result.companions.map((item) => item.name).toList(), <String>[
        '신형철',
        '고영춘',
      ]);
      expect(
        result.holes.fold<int>(0, (sum, hole) => sum + hole.strokes),
        92,
      );
    });

    test('헤더 본인 이름과 일치하는 점수행을 우선 본인 스코어로 선택한다', () {
      const text = '''
드림파크
DATE 2024/08/02
TEE OFF AM 07:28
지우람 92
DREAM OUT 1 2 3 4 5 6 7 8 9 TOTAL
PAR 4 4 4 5 3 4 4 3 5 36
신형철 0 2 4 4 1 2 0 3 2 54
지우람 1 3 0 1 1 0 1 1 0 44
고영춘 1 1 1 0 2 1 3 0 0 45
DREAM IN 1 2 3 4 5 6 7 8 9 TOTAL
PAR 4 4 5 3 4 4 5 3 4 36 72
신형철 0 0 0 2 3 3 0 0 0 44 98
지우람 2 1 0 2 2 1 1 1 2 48 92
고영춘 1 0 3 2 4 3 4 0 4 57 102
''';

      final result = parseScorecardText(text, baseHoles());

      expect(result.playerName, '지우람');
      expect(result.holes.first.strokes, 5);
      expect(result.holes[1].strokes, 7);
      expect(result.holes[9].strokes, 6);
      expect(
        result.holes.fold<int>(0, (sum, hole) => sum + hole.strokes),
        92,
      );
      expect(result.companions.map((item) => item.name).toList(), <String>[
        '신형철',
        '고영춘',
      ]);
    });

    test('드림파크 실기기 OCR 원문처럼 붙은 숫자도 홀별 점수로 분해한다', () {
      const text = '''
DATE 2024/08/02 SMARTSCORE NO.1GOLFSERVICE
드림파크 TEE OFF AM 07:28 ✓ 전국 골프장 스코어 전송
스코어카드 입력대행/직접입력 서비스
지우람 92 ✓ 스코어카드 무료 출력 서비스
DREAM OUT 1 2 3 4 5 6 7 8 9 TOTAL
PAR 4 4 5 3 4 43 5 36
지우람 1 3 0 1 1011 0 44
신형철 0 2 4 4 1 2 0 3 2 54
고영춘 1 11 0 2 1 3 0 0 45
)순타 3 100 1 2 2 2 3 50
DREAM IN 1 2 3 4 5 6 7 8 9 TOTAL
PAR 4 4 5 3 44 5 3 4 36 72
지우람 2 1 0 2 2 1 1 1 2 48 92
신형철 0 0 0 2 3 3 0 0 0 44 98
고영춘 1 0 3 2434 0 4 57 102
이순태 3 3 101 1 1 0 3 49 99
SMARTSCORE 전국 골프장의 스코어•사진•추억을 자동으로!무료로! 관리하세요
''';

      final dreamParkBaseHoles = <int>[
        4,
        4,
        5,
        3,
        4,
        4,
        3,
        5,
        4,
        4,
        4,
        5,
        3,
        4,
        4,
        5,
        3,
        4,
      ].asMap().entries.map((entry) {
        return HoleScore(
          holeNumber: entry.key + 1,
          par: entry.value,
          strokes: entry.value,
          putts: 2,
          puttsTracked: false,
          fairway: FairwayResult.notApplicable,
          ob: false,
          penalty: 0,
        );
      }).toList(growable: false);

      final result = parseScorecardText(text, dreamParkBaseHoles);

      expect(result.courseName, '드림파크');
      expect(result.playerName, '지우람');
      expect(result.playedAt, DateTime(2024, 8, 2, 7, 28));
      expect(
        result.holes.take(9).map((hole) => hole.strokes).toList(),
        <int>[5, 7, 5, 4, 5, 4, 4, 6, 4],
      );
      expect(
        result.holes.skip(9).take(9).map((hole) => hole.strokes).toList(),
        <int>[6, 5, 5, 5, 6, 5, 6, 4, 6],
      );
      expect(
        result.holes.fold<int>(0, (sum, hole) => sum + hole.strokes),
        92,
      );
      expect(result.companions.map((item) => item.name).toList(), <String>[
        '신형철',
        '고영춘',
        '이순태',
      ]);
      expect(
        result.companions.map((item) {
          return item.holes.fold<int>(0, (sum, hole) => sum + hole.strokes);
        }).toList(),
        <int>[98, 102, 99],
      );
      expect(result.companionNames, containsAll(<String>['신형철', '고영춘', '이순태']));
    });

    test('벨라스톤 오버레이형 카드도 코스명과 일시를 헤더에서 분리한다', () {
      const text = '''
97
벨라스톤 2024.04.13 07:45
SMARTSCORE
벨라 1 2 3 4 5 6 7 8 9 합
PAR 4 4 4 3 4 5 4 3 5 36
지우람 0 2 0 1 3 3 1 0 2 48
신형철 0 1 2 1 2 2 3 2 1 50
스톤 1 2 3 4 5 6 7 8 9 합
PAR 5 4 4 3 4 5 3 4 4 36 72
지우람 1 1 1 2 1 3 2 1 1 49 97
신형철 2 2 1 0 1 2 1 2 3 50 100
''';

      final result = parseScorecardText(text, baseHoles());

      expect(result.courseName, '벨라스톤');
      expect(result.playedAt, DateTime(2024, 4, 13, 7, 45));
      expect(result.playerName, '지우람');
      expect(
        result.holes.fold<int>(0, (sum, hole) => sum + hole.strokes),
        97,
      );
    });

    test('벨라스톤 실기기 원문에서 본인 이름이 합합으로 오염되지 않는다', () {
      const text = '''
97
벨라스톤 SMARTSCORE
2024.04.13 07:45
벨라 스톤
지우람 97
HOLE 1 2 3 4 5 6 7 8 9 합 1 2 3 4 5 6 7 8 9 합
PAR 4 4 4 3 4 5 4 3 5 36 5 4 4 3 4 5 3 4 4 36
지우람 0 2 0 1 3 3 1 0 2 48 1 1 1 2 1 3 2 1 1 49
신형철 0 1 2 1 2 2 3 2 1 50 2 2 1 0 1 2 1 2 3 50
박재남 1 2 3 1 1 0 1 0 0 45 5 1 1 0 2 1 0 0 4 50
고영춘 1 0 2 0 1 0 3 1 1 45 3 2 1 3 4 0 1 3 2 55
Total 지우람 97 신형철 100 박재남 95 고영춘 100
Black 362 410 338 148 385 535 356 165 568 546 396 440
175 505 485 189 351 420
Blue 343 365 313 125 351 495 317 142 529 527 384 398 155
487 443 166 329 376
White 320 318 286 94 322 468 294 125 494 500 363 375
145 465 413 138 304 355
Red 265 295 156 81 301 390 212 123 464 438 274 318 117
393 338 128 260 308
''';

      final bellastoneBaseHoles = <int>[
        4,
        4,
        4,
        3,
        4,
        5,
        4,
        3,
        5,
        5,
        4,
        4,
        3,
        4,
        5,
        3,
        4,
        4,
      ].asMap().entries.map((entry) {
        return HoleScore(
          holeNumber: entry.key + 1,
          par: entry.value,
          strokes: entry.value,
          putts: 2,
          puttsTracked: false,
          fairway: FairwayResult.notApplicable,
          ob: false,
          penalty: 0,
        );
      }).toList(growable: false);

      final result = parseScorecardText(text, bellastoneBaseHoles);

      expect(result.courseName, '벨라스톤');
      expect(result.playedAt, DateTime(2024, 4, 13, 7, 45));
      expect(result.playerName, '지우람');
      expect(
        result.holes.fold<int>(0, (sum, hole) => sum + hole.strokes),
        97,
      );
      expect(result.companions.map((item) => item.name).toList(), <String>[
        '신형철',
        '박재남',
        '고영춘',
      ]);
      expect(
        result.companions.map((item) {
          return item.holes.fold<int>(0, (sum, hole) => sum + hole.strokes);
        }).toList(),
        <int>[100, 95, 100],
      );
      expect(result.companionNames, isNot(contains('지우람')));
      expect(result.companionNames, contains('박재남'));
    });

    test('벨라스톤 OCR에서 박재남 줄이 개행돼도 동반자 점수를 유지한다', () {
      const text = '''
97
벨라스톤 SMARTSCORE
2024.04.13 07:45
벨라 스톤
지우람 97
HOLE 1 2 3 4 5 6 7 8 9 합 1 2 3 4 5 6 7 8 9 합
PAR 4 4 4 3 4 5 4 3 5 36 5 4 4 3 4 5 3 4 4 36
지우람 0 2 0 1 3 3 1 0 2 48 1 1 1 2 1 3 2 1 1 49
신형철 0 1 2 1 2 2 3 2 1 50 2 2 1 0 1 2 1 2 3 50
박재남 1 2 3 1 1 0 1 0 0 45 5 1 1 0 2 1 0 0 4
50
고영춘 1 0 2 0 1 0 3 1 1 45 3 2 1 3 4 0 1 3 2 55
Total 지우람 97 신형철 100 박재남 95 고영춘 100
''';

      final bellastoneBaseHoles = <int>[
        4,
        4,
        4,
        3,
        4,
        5,
        4,
        3,
        5,
        5,
        4,
        4,
        3,
        4,
        5,
        3,
        4,
        4,
      ].asMap().entries.map((entry) {
        return HoleScore(
          holeNumber: entry.key + 1,
          par: entry.value,
          strokes: entry.value,
          putts: 2,
          puttsTracked: false,
          fairway: FairwayResult.notApplicable,
          ob: false,
          penalty: 0,
        );
      }).toList(growable: false);

      final result = parseScorecardText(text, bellastoneBaseHoles);

      expect(result.playerName, '지우람');
      expect(result.companions.map((item) => item.name).toList(), <String>[
        '신형철',
        '박재남',
        '고영춘',
      ]);
      expect(
        result.companions.map((item) {
          return item.holes.fold<int>(0, (sum, hole) => sum + hole.strokes);
        }).toList(),
        <int>[100, 95, 100],
      );
    });

    test('벨라스톤 OCR에서 박재남 줄에 숫자 1개가 빠져도 subtotal로 복원한다', () {
      const text = '''
97
벨라스톤 SMARTSCORE
2024.04.13 07:45
벨라 스톤
HOLE 1 2 3 4 5 6 7 8 9 합 1 2 3 4 5 6 7 8 9 합
PAR 4 4 4 3 4 5 4 3 5 36 5 4 4 3 4 5 3 4 4 36
지우람 0 2 0 1 3 3 1 0 2 48 1 1 1 2 1 3 2 1 1 49
신형철 0 1 2 1 2 2 3 2 1 50 2 2 1 0 1 2 1 2 3 50
박재남 1 2 3 1 1 0 1 0 0 45 5 1 1 2 1 0 0 4 50
고영춘 1 0 2 0 1 0 3 1 1 45 3 2 1 3 4 0 1 3 2 55
Total 지우람 97 신형철 100 박재남 95 고영춘 100
''';

      final bellastoneBaseHoles = <int>[
        4,
        4,
        4,
        3,
        4,
        5,
        4,
        3,
        5,
        5,
        4,
        4,
        3,
        4,
        5,
        3,
        4,
        4,
      ].asMap().entries.map((entry) {
        return HoleScore(
          holeNumber: entry.key + 1,
          par: entry.value,
          strokes: entry.value,
          putts: 2,
          puttsTracked: false,
          fairway: FairwayResult.notApplicable,
          ob: false,
          penalty: 0,
        );
      }).toList(growable: false);

      final result = parseScorecardText(text, bellastoneBaseHoles);

      expect(result.playerName, '지우람');
      expect(result.companions.map((item) => item.name).toList(), <String>[
        '신형철',
        '박재남',
        '고영춘',
      ]);
      expect(
        result.companions.map((item) {
          return item.holes.fold<int>(0, (sum, hole) => sum + hole.strokes);
        }).toList(),
        <int>[100, 95, 100],
      );
      expect(result.companionNames, contains('박재남'));
      expect(result.companionNames, isNot(contains('지우람')));
    });

    test('BALIOS 실기기 OCR 원문도 코스명과 본인 총타를 유지한다', () {
      const text = '''
DATE 2022/11/06 SMARTSCORE NO.1GOLF SERVICE
TEE OFF PM 12:20 ✓ 전국 골프장 스코어 전송
BALIOS BALIOS COUNIRY CLUB 지우람 92 ✓ 스코어카드 무료 출력 서비스 스코어카드 입력대행/직접입력 서비스
남 1 2 3 4 5 6 7 8 9 TOTAL
PAR 4 3 4 5 4 4 3 5 4 36
지우람 1 231002 0 1 46
이일영 1 23 2 1 2 2 1 2 52
송문용 3 1210 4 0 4 2 53
엄근용 4 0 2 1 3 4 1 1 2 54
동 1 2 3 4 5 6 7 8 9 TOTAL
PAR 4 5 43 45 4 3 4 3672
지우람 1 2 2 20 1 20 0 46 92
이일영 14 2101 4 1 1 51 103
송문용 1 2 2 3 2 1 3 2 1 53 106
엄근용 0 5 12 2 1 1 1 50 104
SMARTSCORE 전국골프장의 스코어/사진/추억을 자동으로! 무료로! 관리하세요.
''';

      final baliosBaseHoles = <int>[
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
        5,
        4,
        3,
        4,
        5,
        4,
        3,
        4,
      ].asMap().entries.map((entry) {
        return HoleScore(
          holeNumber: entry.key + 1,
          par: entry.value,
          strokes: entry.value,
          putts: 2,
          puttsTracked: false,
          fairway: FairwayResult.notApplicable,
          ob: false,
          penalty: 0,
        );
      }).toList(growable: false);

      final result = parseScorecardText(text, baliosBaseHoles);

      expect(result.courseName, contains('BALIOS'));
      expect(result.playerName, '지우람');
      expect(result.playedAt, DateTime(2022, 11, 6, 12, 20));
      expect(
        result.holes.fold<int>(0, (sum, hole) => sum + hole.strokes),
        92,
      );
      expect(result.companions.map((item) => item.name).toList(), <String>[
        '이일영',
        '송문용',
        '엄근용',
      ]);
      expect(
        result.companions.map((item) {
          return item.holes.fold<int>(0, (sum, hole) => sum + hole.strokes);
        }).toList(),
        <int>[103, 106, 104],
      );
    });

    test('The Heaven 실기기 OCR 원문도 코스명과 본인 총타를 유지한다', () {
      const text = '''
DATE 2024/05/25 SMARTSCORE NO.1GOLFSERVICE
THE HEAVEN TEE OFF AM 10:56 ✓ 전국 골프장 스코어 전송
RESORT ✓ 스코어카드 입력대행/직접입력 서비스
지우람 90 ✓ 스코어카드 무료 출력 서비스
SOUTH 1 2 3 4 5 6 7 8 9 TOTAL
PAR 4 5 344 3 4 5 36
지우람 0 2 112 100 1 44
김응철 0 2 0 110 0 1 2 43
김회석 0 3 232220 2 52
이순태 3 3 0 3 0 200 2 49
WEST 1 2 3 4 5 6 7 8 9 TOTAL
PAR 4 5 3 3 36 72
지우람 1 1 22 0 0 3 0 1 46 90
김응철 2 2 10 2 1 2 0 2 48 91
김회석 1 3 2 2 1 1 1 3 1 51 103
이순태 0 3 430 1 3 0 1 51 100
SMARTSCORE 전국 골프장의 스코어•사진•추억을 자동으로!무료로! 관리하세요
''';

      final heavenBaseHoles = <int>[
        4,
        5,
        3,
        4,
        4,
        3,
        4,
        4,
        5,
        4,
        4,
        4,
        5,
        3,
        5,
        4,
        3,
        4,
      ].asMap().entries.map((entry) {
        return HoleScore(
          holeNumber: entry.key + 1,
          par: entry.value,
          strokes: entry.value,
          putts: 2,
          puttsTracked: false,
          fairway: FairwayResult.notApplicable,
          ob: false,
          penalty: 0,
        );
      }).toList(growable: false);

      final result = parseScorecardText(text, heavenBaseHoles);

      expect(result.courseName, 'THE HEAVEN RESORT');
      expect(result.playerName, '지우람');
      expect(result.playedAt, DateTime(2024, 5, 25, 10, 56));
      expect(
        result.holes.fold<int>(0, (sum, hole) => sum + hole.strokes),
        90,
      );
    });

    test('Northpalm 실기기 OCR 원문도 코스명과 본인 총타를 유지한다', () {
      const text = '''
DATE 2024/06/22
hps SMARTSCORE NO.1GOLFSERVICE
TEE OFF PM 12:39 ✓ 전국 골프장 스코어 전송
Northpalm ✓ 스코어카드 입력대행/직접입력 서비스
Country Club 지우람 93 ✓ 스코어카드 무료 출력 서비스
EAST 1 2 3 4 5 6 7 8 9 TOTAL
PAR 4 5 44 3 4 43 5 36
지우람 0 2 1 1 2 2 46
이상우 0 1 1 2 2 3 1 2 4 52
한기진 0 2 2 3 2 3 2 1 2 53
신형철 0 3 2 4 ㅟ 1 3 0 3 51
WEST 1 2 3 4 5 6 8 9 TOTAL
PAR 5 4 5 3 4 4 4 3672
지우람 2 10 3 2 1 1 0 1 47 93
이상우 0 2 0 1 2 1 1 0 1 44 96
한기진 2 10 42 13 3 1 53 106
신형철 1 200 10 1 2 2 45 96
SMARTSCORE 전국 골프장의 스코어•사진•추억을 자동으로!무료로!관리하세요
''';

      final northPalmBaseHoles = <int>[
        4,
        5,
        4,
        4,
        3,
        4,
        4,
        3,
        5,
        5,
        4,
        3,
        4,
        5,
        3,
        4,
        4,
        4,
      ].asMap().entries.map((entry) {
        return HoleScore(
          holeNumber: entry.key + 1,
          par: entry.value,
          strokes: entry.value,
          putts: 2,
          puttsTracked: false,
          fairway: FairwayResult.notApplicable,
          ob: false,
          penalty: 0,
        );
      }).toList(growable: false);

      final result = parseScorecardText(text, northPalmBaseHoles);

      expect(result.courseName, 'Northpalm Country Club');
      expect(result.playerName, '지우람');
      expect(result.playedAt, DateTime(2024, 6, 22, 12, 39));
      expect(
        result.holes.fold<int>(0, (sum, hole) => sum + hole.strokes),
        93,
      );
    });
  });
}
