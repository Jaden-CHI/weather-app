import 'package:flutter/material.dart';
import 'app_theme.dart';

/// 버전별 업데이트 안내 내용.
///
/// 새 버전 출시 시 여기에 항목을 추가하면 업데이트 후 첫 실행 때
/// 안내 팝업이 표시된다. 항목이 없는 버전은 팝업을 건너뛴다.
class WhatsNew {
  static const entries = <String, List<String>>{
    '1.3.0': [
      'DB에 없는 골프장도 OK — 캘린더 가져오기에서 포털 검색으로 골프장 이름·주소·위치를 자동으로 찾아드립니다',
      '캘린더 가져오기 정확도 개선 및 길찾기에서 네이버 지도 연결 수정',
    ],
    '1.2.1': [
      '캘린더 가져오기 정확도 개선 — 골프와 관련 없는 일정이 함께 들어오던 문제를 수정했습니다',
      '홈 위젯 갱신 안정화 및 라운드 날씨 안내 정확도 개선',
    ],
    '1.2.0': [
      '라운드 성향 설정 추가 — 설정에서 비·바람·추위·더위 민감도를 고르면 라운드 적합도 판정에 반영됩니다',
      '업데이트 후 첫 실행 시 새 기능을 안내하는 팝업이 추가되었습니다',
    ],
  };

  /// '1.2.0+25' → '1.2.0' 형태로 정규화 후 해당 버전 안내 반환
  static List<String>? itemsFor(String version) =>
      entries[version.split('+').first];
}

/// 업데이트 안내 다이얼로그
class WhatsNewDialog extends StatelessWidget {
  final String version;
  final List<String> items;

  const WhatsNewDialog({super.key, required this.version, required this.items});

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: t.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: t.accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.rocket_launch_rounded, color: t.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '업데이트 안내',
                        style: TextStyle(
                          color: t.fg,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'v$version의 새로운 기능이에요.',
                        style: TextStyle(color: t.fg3, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.check_circle_rounded,
                          size: 18, color: t.accent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                            color: t.fg2, fontSize: 14, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: t.accent,
                  foregroundColor: t.accentInk,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
