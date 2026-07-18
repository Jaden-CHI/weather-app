import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_theme.dart';
import '../models/restaurant.dart';

class RestaurantNavigationService {
  static const String _naverAppName = 'com.golfwindy.app';

  static Future<void> showDirectionsSheet(
    BuildContext context,
    Restaurant restaurant,
  ) async {
    final t = GwTheme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: t.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Text(
                  restaurant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.fg,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  restaurant.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.fg2,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                _DirectionTile(
                  icon: Icons.navigation_outlined,
                  title: '카카오맵으로 길찾기',
                  subtitle: '설치되어 있으면 앱으로 열고, 없으면 웹으로 연결',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _openKakaoDirections(context, restaurant);
                  },
                ),
                const SizedBox(height: 10),
                _DirectionTile(
                  icon: Icons.map_outlined,
                  title: '네이버 지도로 길찾기',
                  subtitle: '네이버 지도 앱이 있으면 바로 연결',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _openNaverDirections(context, restaurant);
                  },
                ),
                const SizedBox(height: 10),
                _DirectionTile(
                  icon: Icons.public,
                  title: '웹 지도로 열기',
                  subtitle: '지도 앱이 없어도 브라우저에서 확인',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _openWebDirections(context, restaurant);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _openKakaoDirections(
    BuildContext context,
    Restaurant restaurant,
  ) async {
    final appUri = Uri.parse(
      'kakaomap://route?ep=${restaurant.lat},${restaurant.lng}&by=CAR',
    );
    await _launchWithFallback(
      context,
      appUri: appUri,
      fallbackUri: _kakaoWebUri(restaurant),
    );
  }

  static Future<void> _openNaverDirections(
    BuildContext context,
    Restaurant restaurant,
  ) async {
    final appUri = Uri(
      scheme: 'nmap',
      host: 'route',
      path: '/car',
      queryParameters: {
        'dlat': restaurant.lat.toString(),
        'dlng': restaurant.lng.toString(),
        'dname': restaurant.name,
        'appname': _naverAppName,
      },
    );
    await _launchWithFallback(
      context,
      appUri: appUri,
      fallbackUri: _kakaoWebUri(restaurant),
    );
  }

  static Future<void> _openWebDirections(
    BuildContext context,
    Restaurant restaurant,
  ) async {
    await _launchUri(
      _kakaoWebUri(restaurant),
      ScaffoldMessenger.maybeOf(context),
    );
  }

  static Uri _kakaoWebUri(Restaurant restaurant) => Uri.parse(
        'https://map.kakao.com/link/to/${Uri.encodeComponent(restaurant.name)},${restaurant.lat},${restaurant.lng}',
      );

  static Future<void> _launchWithFallback(
    BuildContext context, {
    required Uri appUri,
    required Uri fallbackUri,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (await canLaunchUrl(appUri)) {
      final launched = await launchUrl(
        appUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    }
    await _launchUri(fallbackUri, messenger);
  }

  static Future<void> _launchUri(
    Uri uri,
    ScaffoldMessengerState? messenger,
  ) async {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && messenger != null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('길찾기를 열 수 없습니다. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }
}

class _DirectionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DirectionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: t.accent, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: t.fg,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: t.fg3,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: t.fg3),
          ],
        ),
      ),
    );
  }
}
