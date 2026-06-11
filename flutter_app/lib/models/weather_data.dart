/// 골프 날씨 API 응답 모델
class GolfWeatherData {
  final String courseId;
  final String courseName;
  final String region;
  final bool golfzonLinked;
  final String? golfzonBookingUrl;
  final int dday;
  final String forecastDate;
  final String? lastUpdated;
  final AiRecommendation aiRecommendation;
  final CancellationPolicy cancellationPolicy;
  final List<ForecastItem> forecast;
  final List<ScreenGolfSuggestion> screenGolfNearby;

  const GolfWeatherData({
    required this.courseId,
    required this.courseName,
    required this.region,
    required this.golfzonLinked,
    this.golfzonBookingUrl,
    required this.dday,
    required this.forecastDate,
    this.lastUpdated,
    required this.aiRecommendation,
    required this.cancellationPolicy,
    required this.forecast,
    required this.screenGolfNearby,
  });

  factory GolfWeatherData.fromJson(Map<String, dynamic> json) =>
      GolfWeatherData(
        courseId: json['course_id'] as String,
        courseName: json['course_name'] as String,
        region: json['region'] as String,
        golfzonLinked: json['golfzon_linked'] as bool? ?? false,
        golfzonBookingUrl: json['golfzon_booking_url'] as String?,
        dday: json['dday'] as int,
        forecastDate: json['forecast_date'] as String,
        lastUpdated: json['last_updated'] as String?,
        aiRecommendation: AiRecommendation.fromJson(
            json['ai_recommendation'] as Map<String, dynamic>),
        cancellationPolicy: CancellationPolicy.fromJson(
            json['cancellation_policy'] as Map<String, dynamic>),
        forecast: (json['forecast'] as List<dynamic>?)
                ?.map((e) => ForecastItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        screenGolfNearby: (json['screen_golf_nearby'] as List<dynamic>?)
                ?.map((e) =>
                    ScreenGolfSuggestion.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class AiRecommendation {
  final String status; // GREEN / YELLOW / RED / UNKNOWN
  final String message;
  final String detail;

  const AiRecommendation({
    required this.status,
    required this.message,
    required this.detail,
  });

  factory AiRecommendation.fromJson(Map<String, dynamic> json) =>
      AiRecommendation(
        status: json['status'] as String? ?? 'UNKNOWN',
        message: json['message'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
      );

  StatusColor get color {
    switch (status) {
      case 'GREEN':
        return StatusColor.green;
      case 'YELLOW':
        return StatusColor.yellow;
      case 'RED':
        return StatusColor.red;
      default:
        return StatusColor.grey;
    }
  }
}

enum StatusColor { green, yellow, red, grey }

class CancellationPolicy {
  final bool? canCancelFree;
  final String? countdown;
  final String urgency; // NORMAL / HIGH / CRITICAL
  final String message;
  final String? deadlineStr;
  final String sameDayPenalty;
  final String noshowPenalty;
  final RainCancelPolicy rainCancel;
  final String policySource; // GOLFZON_API / DB / FALLBACK

  const CancellationPolicy({
    this.canCancelFree,
    this.countdown,
    required this.urgency,
    required this.message,
    this.deadlineStr,
    required this.sameDayPenalty,
    required this.noshowPenalty,
    required this.rainCancel,
    required this.policySource,
  });

  factory CancellationPolicy.fromJson(Map<String, dynamic> json) {
    final rc = json['rain_cancel'] as Map<String, dynamic>? ?? {};
    return CancellationPolicy(
      canCancelFree: json['can_cancel_free'] as bool?,
      countdown: json['countdown'] as String?,
      urgency: json['urgency'] as String? ?? 'NORMAL',
      message: json['message'] as String? ?? '',
      deadlineStr: json['deadline_str'] as String?,
      sameDayPenalty: json['same_day_penalty'] as String? ?? '',
      noshowPenalty: json['noshow_penalty'] as String? ?? '',
      rainCancel: RainCancelPolicy(
        available: rc['available'] as bool? ?? false,
        condition: rc['condition'] as String? ?? '',
        refundRule: rc['refund_rule'] as String? ?? '',
      ),
      policySource: json['policy_source'] as String? ?? 'FALLBACK',
    );
  }
}

class RainCancelPolicy {
  final bool available;
  final String condition;
  final String refundRule;

  const RainCancelPolicy({
    required this.available,
    required this.condition,
    required this.refundRule,
  });
}

class ForecastItem {
  final String date;
  final String time;
  final double temp;
  final double windSpeed;
  final int rainProb;
  final int sky; // 1=맑음 3=구름많음 4=흐림
  final bool lightning;

  const ForecastItem({
    required this.date,
    required this.time,
    required this.temp,
    required this.windSpeed,
    required this.rainProb,
    required this.sky,
    required this.lightning,
  });

  factory ForecastItem.fromJson(Map<String, dynamic> json) => ForecastItem(
        date: json['date'] as String? ?? '',
        time: json['time'] as String? ?? '',
        temp: (json['temp'] as num?)?.toDouble() ?? 0,
        windSpeed: (json['wind_speed'] as num?)?.toDouble() ?? 0,
        rainProb: (json['rain_prob'] as num?)?.toInt() ?? 0,
        sky: (json['sky'] as num?)?.toInt() ?? 1,
        lightning: (json['lightning'] as num?)?.toInt() == 1,
      );

  String get skyEmoji {
    switch (sky) {
      case 1:
        return '☀️';
      case 3:
        return '⛅';
      case 4:
        return '☁️';
      default:
        return rainProb >= 60 ? '🌧️' : '🌤️';
    }
  }

  String get timeLabel {
    if (time.length >= 2) return '${time.substring(0, 2)}시';
    return '--시';
  }

  String get weatherLabel {
    if (rainProb >= 60) return '강한 비';
    if (rainProb >= 40) return '약한 비';
    if (rainProb >= 20) return '한두 방울';
    return '맑음';
  }
}

class ScreenGolfSuggestion {
  final String name;
  final String? message;
  final String? searchUrl;

  const ScreenGolfSuggestion({
    required this.name,
    this.message,
    this.searchUrl,
  });

  factory ScreenGolfSuggestion.fromJson(Map<String, dynamic> json) =>
      ScreenGolfSuggestion(
        name: json['name'] as String? ?? '',
        message: json['message'] as String?,
        searchUrl: json['search_url'] as String?,
      );
}

/// 배낚시 해양 날씨 API 응답 모델
class MarineWeatherData {
  final String spotId;
  final String spotName;
  final String region;
  final String seaType;
  final List<String> mainFish;
  final MarineWarning warning;
  final MarineCurrent current;
  final List<TideForecast> tides;
  final String goldenTime;
  final AiRecommendation aiRecommendation;
  final SafetyGuide safetyGuide;

  const MarineWeatherData({
    required this.spotId,
    required this.spotName,
    required this.region,
    required this.seaType,
    required this.mainFish,
    required this.warning,
    required this.current,
    required this.tides,
    required this.goldenTime,
    required this.aiRecommendation,
    required this.safetyGuide,
  });

  factory MarineWeatherData.fromJson(Map<String, dynamic> json) {
    final cw = json['current_weather'] as Map<String, dynamic>? ?? {};
    final w = json['warning'] as Map<String, dynamic>? ?? {};
    final sg = json['safety_guide'] as Map<String, dynamic>? ?? {};
    return MarineWeatherData(
      spotId: json['spot_id'] as String,
      spotName: json['spot_name'] as String,
      region: json['region'] as String,
      seaType: json['sea_type'] as String,
      mainFish: (json['main_fish'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      warning: MarineWarning(
        hasWarning: w['has_warning'] as bool? ?? false,
        departureBlocked: w['departure_blocked'] as bool? ?? false,
        level: w['level'] as String? ?? '없음',
        message: w['message'] as String? ?? '',
      ),
      current: MarineCurrent(
        waveHeight: (cw['wave_height'] as num?)?.toDouble() ?? 0,
        windSpeed: (cw['wind_speed'] as num?)?.toDouble() ?? 0,
        seaTemp: (cw['sea_temp'] as num?)?.toDouble() ?? 0,
        visibility: (cw['visibility'] as num?)?.toInt() ?? 10,
      ),
      tides: (json['tides'] as List<dynamic>?)
              ?.map((e) => TideForecast.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      goldenTime: json['golden_time'] as String? ?? '정보 없음',
      aiRecommendation: AiRecommendation.fromJson(
          json['ai_recommendation'] as Map<String, dynamic>? ?? {}),
      safetyGuide: SafetyGuide.fromJson(sg),
    );
  }
}

class MarineWarning {
  final bool hasWarning;
  final bool departureBlocked;
  final String level;
  final String message;

  const MarineWarning({
    required this.hasWarning,
    required this.departureBlocked,
    required this.level,
    required this.message,
  });
}

class MarineCurrent {
  final double waveHeight;
  final double windSpeed;
  final double seaTemp;
  final int visibility;

  const MarineCurrent({
    required this.waveHeight,
    required this.windSpeed,
    required this.seaTemp,
    required this.visibility,
  });
}

class TideForecast {
  final String time;
  final double height;
  final String type; // 만조 / 간조

  const TideForecast({
    required this.time,
    required this.height,
    required this.type,
  });

  factory TideForecast.fromJson(Map<String, dynamic> json) => TideForecast(
        time: json['time'] as String? ?? '',
        height: (json['height'] as num?)?.toDouble() ?? 0,
        type: json['type'] as String? ?? '',
      );

  String get emoji => type == '만조' ? '🌊' : '🏖️';
}

class SafetyGuide {
  final BoardingReport boardingReport;
  final String departureBlockedMessage;

  const SafetyGuide({
    required this.boardingReport,
    required this.departureBlockedMessage,
  });

  factory SafetyGuide.fromJson(Map<String, dynamic> json) {
    final br = json['boarding_report'] as Map<String, dynamic>? ?? {};
    return SafetyGuide(
      boardingReport: BoardingReport(
        required_: br['required'] as bool? ?? true,
        title: br['title'] as String? ?? '승선신고',
        steps: (br['steps'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        warning: br['warning'] as String? ?? '',
      ),
      departureBlockedMessage:
          json['departure_blocked_message'] as String? ?? '',
    );
  }
}

class BoardingReport {
  final bool required_;
  final String title;
  final List<String> steps;
  final String warning;

  const BoardingReport({
    required this.required_,
    required this.title,
    required this.steps,
    required this.warning,
  });
}
