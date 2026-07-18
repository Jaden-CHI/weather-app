import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 디자인 시안의 스트로크 라인 날씨 아이콘 (24x24 뷰박스 기준)
///
/// variant:
///  - sun       : 맑음 (해)
///  - cloud     : 구름
///  - cloudRain : 비구름 + 빗줄기
enum WxIconVariant { sun, cloud, cloudRain }

class WxIcon extends StatelessWidget {
  final WxIconVariant variant;
  final double size;
  final Color color;
  final double strokeWidth;

  const WxIcon({
    super.key,
    required this.variant,
    required this.size,
    required this.color,
    this.strokeWidth = 1.5,
  });

  /// 예보 값으로 변형 자동 선택 (sky: 1=맑음 3=구름많음 4=흐림)
  factory WxIcon.forecast({
    Key? key,
    required int sky,
    required int rainProb,
    required double size,
    required Color color,
    double strokeWidth = 1.5,
  }) {
    final WxIconVariant variant;
    if (rainProb >= 40) {
      variant = WxIconVariant.cloudRain;
    } else if (sky == 1) {
      variant = WxIconVariant.sun;
    } else {
      variant = WxIconVariant.cloud;
    }
    return WxIcon(
      key: key,
      variant: variant,
      size: size,
      color: color,
      strokeWidth: strokeWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _WxIconPainter(
        variant: variant,
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _WxIconPainter extends CustomPainter {
  final WxIconVariant variant;
  final Color color;
  final double strokeWidth;

  _WxIconPainter({
    required this.variant,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.scale(s);

    switch (variant) {
      case WxIconVariant.sun:
        _paintSun(canvas, paint);
      case WxIconVariant.cloud:
        _paintCloud(canvas, paint, rain: false);
      case WxIconVariant.cloudRain:
        _paintCloud(canvas, paint, rain: true);
    }
  }

  /// 해: 중앙 원 + 8방향 광선
  void _paintSun(Canvas canvas, Paint paint) {
    const c = Offset(12, 12);
    canvas.drawCircle(c, 4.4, paint);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + dir * 7.2, c + dir * 9.6, paint);
    }
  }

  /// 구름: M4 14.9 A7 7 0 1 1 15.7 8 h1.8 a4.5 4.5 0 0 1 0 9
  /// 빗줄기: M8 19v2 · M12 20v2 · M16 19v2
  void _paintCloud(Canvas canvas, Paint paint, {required bool rain}) {
    // 비 없는 변형은 구름을 살짝 아래로 내려 중앙 정렬
    if (!rain) canvas.translate(0, 1.6);

    final path = Path()
      ..moveTo(4, 14.9)
      ..arcToPoint(
        const Offset(15.7, 8),
        radius: const Radius.circular(7),
        largeArc: true,
        clockwise: true,
      )
      ..lineTo(17.5, 8)
      ..arcToPoint(
        const Offset(17.5, 17),
        radius: const Radius.circular(4.5),
        clockwise: true,
      );
    canvas.drawPath(path, paint);

    if (rain) {
      canvas.drawLine(const Offset(8, 19), const Offset(8, 21), paint);
      canvas.drawLine(const Offset(12, 20), const Offset(12, 22), paint);
      canvas.drawLine(const Offset(16, 19), const Offset(16, 21), paint);
    }
  }

  @override
  bool shouldRepaint(_WxIconPainter old) =>
      old.variant != variant ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
