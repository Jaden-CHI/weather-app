import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../models/restaurant.dart';
import '../services/restaurant_navigation_service.dart';
import '../services/restaurant_service.dart';

class RestaurantDetailScreen extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({
    super.key,
    required this.restaurant,
  });

  Future<void> _callPhoneNumber(String phone) async {
    if (phone.isEmpty) return;
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openPlaceReviews() async {
    if (restaurant.placeUrl.isEmpty) return;
    final url = Uri.parse(restaurant.placeUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return FutureBuilder<RestaurantDetail?>(
      future: RestaurantService().getRestaurantDetail(restaurant),
      builder: (context, snapshot) {
        final detail =
            snapshot.data ?? RestaurantDetail.fromRestaurant(restaurant);

        return Scaffold(
          backgroundColor: t.bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close, color: t.fg),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이름 & 별점
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: TextStyle(
                            color: t.fg,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (restaurant.rating > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: t.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: t.accent.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            '별점 ${restaurant.rating.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: t.accent,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${restaurant.distance.toStringAsFixed(1)}km · ${restaurant.category}',
                    style: TextStyle(
                      color: t.fg3,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 정보 섹션
                  _Section(title: '주소', content: restaurant.address),
                  const SizedBox(height: 16),

                  _Section(title: '영업시간', content: detail.hours),
                  const SizedBox(height: 16),

                  // 버튼들
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              RestaurantNavigationService.showDirectionsSheet(
                            context,
                            restaurant,
                          ),
                          icon: const Icon(Icons.navigation_outlined),
                          label: const Text('길찾기'),
                          style: FilledButton.styleFrom(
                            backgroundColor: t.accent,
                            foregroundColor: t.accentInk,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: detail.phone.isEmpty
                              ? null
                              : () => _callPhoneNumber(detail.phone),
                          icon: const Icon(Icons.call),
                          label: const Text('전화'),
                          style: FilledButton.styleFrom(
                            backgroundColor: t.surface,
                            foregroundColor: t.fg,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: t.line),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (restaurant.placeUrl.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openPlaceReviews,
                        icon: const Icon(Icons.rate_review_outlined),
                        label: const Text('후기 보기'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: t.fg2,
                          side: BorderSide(color: t.line),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // 리뷰 섹션
                  Text(
                    '추천 기준',
                    style: TextStyle(
                      color: t.fg,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...detail.reviews.map((review) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: t.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: t.cardBorder),
                          ),
                          child: Text(
                            review,
                            style: TextStyle(
                              color: t.fg2,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;
  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: t.fg2,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.cardBorder),
          ),
          child: Text(
            content,
            style: TextStyle(
              color: t.fg,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
