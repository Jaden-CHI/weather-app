import 'dart:developer' as developer;

import 'package:weather_app/services/score_ocr_parser.dart';
import 'package:weather_app/models/golf_score.dart';

void main() {
  const text = '''
벨라스톤 SMARTSCORE
2024.04.13 07:45
벨라 스톤
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
  final pars = <int>[4,4,4,3,4,5,4,3,5,5,4,4,3,4,5,3,4,4];
  final baseHoles = pars.asMap().entries.map((e)=>HoleScore(holeNumber:e.key+1,par:e.value,strokes:e.value,putts:2,puttsTracked:false,fairway:FairwayResult.notApplicable,ob:false,penalty:0)).toList();
  final result = parseScorecardText(text, baseHoles);
  developer.log('course=${result.courseName}');
  developer.log('player=${result.playerName}');
  developer.log('companions=${result.companions.map((e)=>'${e.name}:${e.holes.fold<int>(0,(s,h)=>s+h.strokes)}').toList()}');
  developer.log('companionNames=${result.companionNames}');
}
