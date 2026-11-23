import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/l10n.dart';
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
    final l10n = context.l10n;
    final rec = data.aiRecommendation;
    final policy = data.cancellationPolicy;

    final statusEmoji = switch (rec.status) {
      'GREEN' => '✅',
      'YELLOW' => '⚠️',
      'RED' => '❌',
      _ => '🌤️',
    };

    final lines = <String>[
      l10n.shareGolfWeatherHeader,
      '',
      '$statusEmoji ${data.courseName} (${event.ddayLabel})',
      '📅 ${_formatDate(event.startDate)}',
      '',
      l10n.shareAiSection,
      rec.message,
      rec.detail,
    ];

    // 예보 요약 (첫 4슬롯)
    if (data.forecast.isNotEmpty) {
      lines.add('');
      lines.add(l10n.shareForecastSection);
      for (final f in data.forecast.take(4)) {
        lines.add(
          l10n.shareForecastLine(
            f.timeLabel,
            f.skyEmoji,
            f.temp.toInt(),
            f.rainProb,
            f.windSpeed.toStringAsFixed(1),
          ),
        );
      }
    }

    // 취소 정책 요약
    if (policy.message.isNotEmpty) {
      lines.add('');
      lines.add(l10n.shareCancelSection);
      lines.add(policy.message);
      if (policy.rainCancel.available) {
        lines.add(l10n.shareRainCancelPolicy(policy.rainCancel.condition));
      }
    }

    lines.add('');
    lines.add('─────────────────');
    lines.add(l10n.shareFooter);

    final text = lines.join('\n');
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      text,
      subject: l10n.shareWeatherSubject(data.courseName, rec.message),
      sharePositionOrigin:
          box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  /// 날씨가 아직 준비되지 않은 일정도 카카오톡/문자 공유 시트로 공유
  Future<void> shareGolfSchedule({
    required BuildContext context,
    required GolfEvent event,
    GolfWeatherData? data,
  }) async {
    if (data != null) {
      return shareGolfWeather(context: context, event: event, data: data);
    }

    final l10n = context.l10n;
    final courseName = event.courseName ?? event.location ?? event.title;
    final lines = <String>[
      l10n.shareScheduleHeader,
      '',
      '$courseName (${event.ddayLabel})',
      '📅 ${_formatDate(event.startDate)}',
      if ((event.address ?? '').trim().isNotEmpty)
        '📍 ${event.address!.trim()}',
      '',
      l10n.shareWeatherPending,
      '',
      '─────────────────',
      l10n.shareFooter,
    ];

    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      lines.join('\n'),
      subject: l10n.shareScheduleSubject(courseName),
      sharePositionOrigin:
          box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  String _formatDate(DateTime dt) {
    final l10n = L10n.current;
    return DateFormat(l10n.shareDateFmt, l10n.localeName).format(dt);
  }
}
