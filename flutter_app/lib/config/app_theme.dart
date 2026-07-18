import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';

/// 앱 전역 디자인 토큰 (Claude Design "Golf Windy App" 기반)
///
/// 3가지 선택형 테마:
///  - fairway_sky   : 쿨 틸 다크 (기본)
///  - light_air     : 오프화이트 라이트
///  - midnight_lime : 네이비 + 라임 다크
class GwTheme extends ThemeExtension<GwTheme> {
  final String id;
  final String name;
  final String subtitle;
  final Brightness brightness;

  final Color bg; // 화면 배경
  final Color gradTop; // 홈 히어로 그라데이션 상단
  final Color surface; // 카드 배경
  final Color surface2; // 탭바/보조 배경
  final Color accent; // 브랜드 강조색
  final Color accentInk; // 강조색 위 텍스트
  final Color fg; // 주 텍스트
  final Color fg2; // 보조 텍스트
  final Color fg3; // 희미한 텍스트
  final Color line; // 구분선
  final Color cardBorder; // 카드 테두리
  final Color sky; // 강수/하늘 지표색
  final Color warn; // 주의
  final Color danger; // 위험
  final Color success; // 최적
  final Color dangerBg;
  final Color dangerBorder;

  /// 테마 선택 카드의 스와치 3색
  final List<Color> swatch;

  const GwTheme({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.brightness,
    required this.bg,
    required this.gradTop,
    required this.surface,
    required this.surface2,
    required this.accent,
    required this.accentInk,
    required this.fg,
    required this.fg2,
    required this.fg3,
    required this.line,
    required this.cardBorder,
    required this.sky,
    required this.warn,
    required this.danger,
    required this.success,
    required this.dangerBg,
    required this.dangerBorder,
    required this.swatch,
  });

  /// 숫자 표시용 폰트 (온도, D-day, 통계 값)
  static const numFont = 'SpaceGrotesk';

  bool get isDark => brightness == Brightness.dark;

  Color get warnBg => warn.withValues(alpha: 0.12);
  Color get warnBorder => warn.withValues(alpha: 0.35);
  Color get successBg => success.withValues(alpha: 0.12);
  Color get successBorder => success.withValues(alpha: 0.35);

  static const fairwaySky = GwTheme(
    id: 'fairway_sky',
    name: 'Fairway & Sky',
    subtitle: '쿨 틸 · 다크',
    brightness: Brightness.dark,
    bg: Color(0xFF0D2830),
    gradTop: Color(0xFF0F4A52),
    surface: Color(0xFF123138),
    surface2: Color(0xFF0F2A31),
    accent: Color(0xFF6FE7DE),
    accentInk: Color(0xFF06232A),
    fg: Color(0xFFEAF6F5),
    fg2: Color(0x9EEAF6F5),
    fg3: Color(0x6BEAF6F5),
    line: Color(0x17EAF6F5),
    cardBorder: Color(0x12EAF6F5),
    sky: Color(0xFF6FE7DE),
    warn: Color(0xFFFFD07A),
    danger: Color(0xFFFF6B6B),
    success: Color(0xFF4ADE80),
    dangerBg: Color(0x1AFF6B6B),
    dangerBorder: Color(0x47FF6B6B),
    swatch: [Color(0xFF0D2830), Color(0xFF123138), Color(0xFF6FE7DE)],
  );

  static const lightAir = GwTheme(
    id: 'light_air',
    name: 'Light Air',
    subtitle: '오프화이트 · 라이트',
    brightness: Brightness.light,
    bg: Color(0xFFEDF2EF),
    gradTop: Color(0xFFDCEDE5),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFFFFFFF),
    accent: Color(0xFF1E9E6A),
    accentInk: Color(0xFFFFFFFF),
    fg: Color(0xFF13251E),
    fg2: Color(0x9E13251E),
    fg3: Color(0x6B13251E),
    line: Color(0x12000000),
    cardBorder: Color(0x12000000),
    sky: Color(0xFF1E9E6A),
    warn: Color(0xFFE0912B),
    danger: Color(0xFFE5484D),
    success: Color(0xFF1E9E6A),
    dangerBg: Color(0x17E5484D),
    dangerBorder: Color(0x4DE5484D),
    swatch: [Color(0xFFEDF2EF), Color(0xFFFFFFFF), Color(0xFF1E9E6A)],
  );

  static const midnightLime = GwTheme(
    id: 'midnight_lime',
    name: 'Midnight Lime',
    subtitle: '네이비 + 라임 · 다크',
    brightness: Brightness.dark,
    bg: Color(0xFF0B1220),
    gradTop: Color(0xFF182338),
    surface: Color(0xFF141C2B),
    surface2: Color(0xFF0F1626),
    accent: Color(0xFFC6F24E),
    accentInk: Color(0xFF14200A),
    fg: Color(0xFFF3F6FB),
    fg2: Color(0x9EF3F6FB),
    fg3: Color(0x6BF3F6FB),
    line: Color(0x17F3F6FB),
    cardBorder: Color(0x12F3F6FB),
    sky: Color(0xFFC6F24E),
    warn: Color(0xFFFFB454),
    danger: Color(0xFFFF7A7A),
    success: Color(0xFF7EE08C),
    dangerBg: Color(0x1AFF7A7A),
    dangerBorder: Color(0x47FF7A7A),
    swatch: [Color(0xFF0B1220), Color(0xFF141C2B), Color(0xFFC6F24E)],
  );

  static const all = [fairwaySky, lightAir, midnightLime];

  static GwTheme byId(String? id) =>
      all.firstWhere((t) => t.id == id, orElse: () => fairwaySky);

  static GwTheme of(BuildContext context) =>
      Theme.of(context).extension<GwTheme>() ?? fairwaySky;

  ThemeData toThemeData() => ThemeData(
        useMaterial3: true,
        brightness: brightness,
        scaffoldBackgroundColor: bg,
        fontFamily: 'Pretendard',
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
          surface: bg,
        ),
        extensions: [this],
      );

  @override
  GwTheme copyWith() => this;

  @override
  GwTheme lerp(ThemeExtension<GwTheme>? other, double t) =>
      t < 0.5 ? this : (other as GwTheme? ?? this);
}

/// 현재 선택된 테마 (SharedPreferences 영속화)
class GwThemeNotifier extends Notifier<GwTheme> {
  @override
  GwTheme build() {
    _restore();
    return GwTheme.fairwaySky;
  }

  Future<void> _restore() async {
    final id = await SettingsService.instance.getThemeId();
    if (id != null && id != state.id) {
      state = GwTheme.byId(id);
    }
  }

  Future<void> select(GwTheme theme) async {
    state = theme;
    await SettingsService.instance.setThemeId(theme.id);
  }
}

final gwThemeProvider =
    NotifierProvider<GwThemeNotifier, GwTheme>(GwThemeNotifier.new);
