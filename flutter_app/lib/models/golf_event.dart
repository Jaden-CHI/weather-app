/// 캘린더에서 파싱된 골프 일정
class GolfEvent {
  final String id;
  final String title;
  final DateTime startDate;
  final String? location;
  final String? courseId; // 백엔드 골프장 ID (API 매핑 후 채움)
  final String? courseName; // 매핑된 골프장 공식 이름
  final String? address;
  final double? lat;
  final double? lng;

  const GolfEvent({
    required this.id,
    required this.title,
    required this.startDate,
    this.location,
    this.courseId,
    this.courseName,
    this.address,
    this.lat,
    this.lng,
  });

  /// D-day 계산 (오늘 = 0, 내일 = 1 ...)
  int get dday {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final eventDate = DateTime(startDate.year, startDate.month, startDate.day);
    return eventDate.difference(todayDate).inDays;
  }

  String get ddayLabel {
    final d = dday;
    if (d == 0) return 'D-Day';
    if (d > 0) return 'D-$d';
    return 'D+${d.abs()}';
  }

  String get formattedDate => _formatKoreanDate(startDate);
  String get formattedTime => _formatTime(startDate);
  double get searchLat => lat ?? 37.5665;
  double get searchLng => lng ?? 126.9780;

  GolfEvent copyWith({
    String? courseId,
    String? courseName,
    String? address,
    double? lat,
    double? lng,
  }) =>
      GolfEvent(
        id: id,
        title: title,
        startDate: startDate,
        location: location,
        courseId: courseId ?? this.courseId,
        courseName: courseName ?? this.courseName,
        address: address ?? this.address,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
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
    final todayDate = DateTime(today.year, today.month, today.day);
    final eventDate = DateTime(startDate.year, startDate.month, startDate.day);
    return eventDate.difference(todayDate).inDays;
  }

  String get ddayLabel {
    final d = dday;
    if (d == 0) return 'D-Day';
    if (d > 0) return 'D-$d';
    return 'D+${d.abs()}';
  }

  String get formattedDate => _formatKoreanDate(startDate);
  String get formattedTime => _formatTime(startDate);
}

String _formatKoreanDate(DateTime date) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${date.month}/${date.day}(${weekdays[date.weekday - 1]})';
}

String _formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
