import 'package:intl/intl.dart';

/// 캘린더에서 파싱된 골프 일정
class GolfEvent {
  final String id;
  final String title;
  final DateTime startDate;
  final String? location;
  final String? courseId;   // 백엔드 골프장 ID (API 매핑 후 채움)
  final String? courseName; // 매핑된 골프장 공식 이름

  const GolfEvent({
    required this.id,
    required this.title,
    required this.startDate,
    this.location,
    this.courseId,
    this.courseName,
  });

  /// D-day 계산 (오늘 = 0, 내일 = 1 ...)
  int get dday {
    final today = DateTime.now();
    final diff = startDate.difference(DateTime(today.year, today.month, today.day));
    return diff.inDays;
  }

  String get ddayLabel {
    final d = dday;
    if (d == 0) return 'D-Day';
    if (d > 0) return 'D-$d';
    return 'D+${d.abs()}';
  }

  String get formattedDate {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final wd = weekdays[startDate.weekday - 1];
    return '${startDate.month}월 ${startDate.day}일($wd)';
  }
  String get formattedTime => DateFormat('HH:mm').format(startDate);

  GolfEvent copyWith({String? courseId, String? courseName}) => GolfEvent(
        id: id,
        title: title,
        startDate: startDate,
        location: location,
        courseId: courseId ?? this.courseId,
        courseName: courseName ?? this.courseName,
      );
}

/// 캘린더에서 파싱된 낚시 일정
class FishingEvent {
  final String id;
  final String title;
  final DateTime startDate;
  final String? location;
  final String? spotId; // 백엔드 출항지 ID

  const FishingEvent({
    required this.id,
    required this.title,
    required this.startDate,
    this.location,
    this.spotId,
  });

  int get dday {
    final today = DateTime.now();
    return startDate.difference(DateTime(today.year, today.month, today.day)).inDays;
  }

  String get ddayLabel {
    final d = dday;
    if (d == 0) return 'D-Day';
    if (d > 0) return 'D-$d';
    return 'D+${d.abs()}';
  }

  String get formattedDate {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final wd = weekdays[startDate.weekday - 1];
    return '${startDate.month}월 ${startDate.day}일($wd)';
  }
  String get formattedTime => DateFormat('HH:mm').format(startDate);
}
