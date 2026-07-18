import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/restaurant.dart';
import '../models/restaurant_search_result.dart';
import '../services/restaurant_navigation_service.dart';
import '../services/restaurant_service.dart';
import '../services/weather_api_service.dart';
import 'restaurant_detail_screen.dart';

class RestaurantScreen extends StatefulWidget {
  final double lat;
  final double lng;
  final String courseName;
  final String? courseAddress;

  const RestaurantScreen({
    super.key,
    required this.lat,
    required this.lng,
    required this.courseName,
    this.courseAddress,
  });

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  int _selectedTab = 0;
  late Future<RestaurantSearchResult> _restaurantsFuture;

  @override
  void initState() {
    super.initState();
    debugPrint('🍽️ RestaurantScreen 초기화');
    debugPrint('📍 좌표: lat=${widget.lat}, lng=${widget.lng}');
    _loadRestaurants();
  }

  void _loadRestaurants() {
    if (mounted) {
      setState(() {
        _restaurantsFuture = _getRestaurants();
      });
    }
  }

  Future<RestaurantSearchResult> _getRestaurants() async {
    final category = _selectedTab == 0 ? '조식' : '중식';
    var lat = widget.lat;
    var lng = widget.lng;
    var courseAddress = widget.courseAddress;

    try {
      final matchedCourse =
          await WeatherApiService.instance.searchCourse(widget.courseName);
      final trustedLocation =
          await WeatherApiService.instance.resolveTrustedCourseLocation(
        courseName: matchedCourse?.name ?? widget.courseName,
        address: courseAddress ?? matchedCourse?.address,
        currentLat: matchedCourse?.lat ?? lat,
        currentLng: matchedCourse?.lng ?? lng,
      );

      if (trustedLocation != null) {
        lat = trustedLocation.lat;
        lng = trustedLocation.lng;
        courseAddress = trustedLocation.address ?? courseAddress;
      } else if (matchedCourse?.lat != null && matchedCourse?.lng != null) {
        lat = matchedCourse!.lat!;
        lng = matchedCourse.lng!;
        courseAddress = matchedCourse.address ?? courseAddress;
      }
    } catch (e) {
      debugPrint('⚠️ Restaurant location resolve skipped: $e');
    }

    return RestaurantService().searchRestaurants(
      lat: lat,
      lng: lng,
      category: category,
      courseAddress: courseAddress,
    );
  }

  Widget _tabButton(GwTheme t, int idx, String label) {
    final selected = _selectedTab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = idx;
            _loadRestaurants();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? t.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? t.fg : t.fg3,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: t.fg),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.courseName,
          style: TextStyle(
              color: t.fg, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // 탭
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                _tabButton(t, 0, '조식'),
                const SizedBox(width: 20),
                _tabButton(t, 1, '중식'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.courseAddress?.trim().isNotEmpty == true
                    ? '카페·디저트 제외 · ${widget.courseAddress} 기준 가까운 순 우선'
                    : '카페·디저트 제외 · 실제 후기는 상세에서 확인',
                style: TextStyle(
                  color: t.fg3,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          // 리스트
          Expanded(
            child: FutureBuilder<RestaurantSearchResult>(
              future: _restaurantsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: t.accent),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        '오류가 발생했습니다: ${snapshot.error}',
                        style: TextStyle(color: t.fg2),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final result = snapshot.data ??
                    const RestaurantSearchResult(restaurants: []);
                final restaurants = result.restaurants;
                debugPrint('🍽️ 식당 목록 렌더링: ${restaurants.length}개');

                if (result.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        result.errorMessage!,
                        style: TextStyle(color: t.fg2),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (restaurants.isEmpty) {
                  debugPrint('❌ 추천 식당 없음');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        '근처에 추천 식당이 없습니다\n(위치: ${widget.lat.toStringAsFixed(4)}, ${widget.lng.toStringAsFixed(4)})',
                        style: TextStyle(color: t.fg2),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = restaurants[index];
                    return _RestaurantCard(
                      restaurant: restaurant,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RestaurantDetailScreen(
                              restaurant: restaurant,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  const _RestaurantCard({
    required this.restaurant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    restaurant.name,
                    style: TextStyle(
                      color: t.fg,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (restaurant.rating > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: t.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: t.accent.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      '별점 ${restaurant.rating.toStringAsFixed(1)}',
                      style: TextStyle(
                        color: t.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${restaurant.distance.toStringAsFixed(1)}km · ${restaurant.category}',
              style: TextStyle(
                color: t.fg3,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              restaurant.address,
              style: TextStyle(
                color: t.fg2,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        RestaurantNavigationService.showDirectionsSheet(
                      context,
                      restaurant,
                    ),
                    icon: const Icon(Icons.navigation_outlined, size: 16),
                    label: const Text('길찾기'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: t.fg2,
                      side: BorderSide(color: t.line),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      foregroundColor: t.accent,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('상세 보기'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
