import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/services/calendar_import_service.dart';

void main() {
  final service = CalendarImportService.instance;

  group('looksLikeGolfEvent — 골프 일정은 통과', () {
    const golfTitles = [
      '이천 뉴스프링빌CC 라운드',
      '레이크사이드CC',
      '남촌GC 티오프 07:30',
      '주말 골프 약속',
      '라운딩 - 양평',
      '곤지암 컨트리 클럽',
      '파주 골프장 예약',
      '해슬리 C.C 모임',
    ];
    for (final title in golfTitles) {
      test(title, () => expect(service.looksLikeGolfEvent(title), isTrue));
    }
  });

  group('looksLikeGolfEvent — 비골프 일정은 제외', () {
    const nonGolfTitles = [
      '치과 예약',
      '팀 회의',
      '엄마 생신',
      '주간 보고 cc: 홍길동',
      'soccer practice',
      'ACCOUNT review',
      '점심 약속 - 강남',
      'PCC 세미나 참석', // CC 앞뒤에 영문자가 붙으면 골프장 약어가 아님
    ];
    for (final title in nonGolfTitles) {
      test(title, () => expect(service.looksLikeGolfEvent(title), isFalse));
    }
  });

  test('빈 문자열은 제외', () {
    expect(service.looksLikeGolfEvent('   '), isFalse);
  });
}
