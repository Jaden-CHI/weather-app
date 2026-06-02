import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/weather_data.dart';
import '../models/golf_event.dart' hide FishingEvent;

class ShareService {
  ShareService._();
  static final instance = ShareService._();

  /// 골프 날씨 카드를 텍스트로 공유
  Future<void> shareGolfWeather({
    required BuildContext context,
    required GolfEvent event,
    required GolfWeatherData data,
  }) async {
    final rec = data.aiRecommendation;
    final policy = data.cancellationPolicy;

    final statusEmoji = switch (rec.status) {
      'GREEN' => '✅',
      'YELLOW' => '⚠️',
      'RED' => '❌',
      _ => '🌤️',
    };

    final lines = <String>[
      '⛳ 켜자마자 날씨 — 골프 날씨 공유',
      '',
      '$statusEmoji ${data.courseName} (${event.ddayLabel})',
      '📅 ${_formatDate(event.startDate)}',
      '',
      '[ AI 권고 ]',
      rec.message,
      rec.detail,
    ];

    // 예보 요약 (첫 4슬롯)
    if (data.forecast.isNotEmpty) {
      lines.add('');
      lines.add('[ 시간대별 예보 ]');
      for (final f in data.forecast.take(4)) {
        lines.add(
          '${f.timeLabel}  ${f.skyEmoji}  ${f.temp.toInt()}°  강수 ${f.rainProb}%  바람 ${f.windSpeed.toStringAsFixed(1)}m/s',
        );
      }
    }

    // 취소 정책 요약
    if (policy.message.isNotEmpty) {
      lines.add('');
      lines.add('[ 취소 안내 ]');
      lines.add(policy.message);
      if (policy.rainCancel.available) {
        lines.add('🌧️ 우천 특별 정책: ${policy.rainCancel.condition}');
      }
    }

    lines.add('');
    lines.add('─────────────────');
    lines.add('켜자마자 날씨 앱으로 확인하세요');

    final text = lines.join('\n');
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      text,
      subject: '${data.courseName} 날씨 — ${rec.message}',
      sharePositionOrigin: box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null,
    );
  }

  String _formatDate(DateTime dt) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final wd = weekdays[dt.weekday - 1];
    return '${dt.month}월 ${dt.day}일($wd) ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
