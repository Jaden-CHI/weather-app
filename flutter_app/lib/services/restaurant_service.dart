import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_keys.dart';
import '../models/restaurant.dart';
import '../models/restaurant_search_result.dart';

class RestaurantService {
  static const String _keywordUrl =
      'https://dapi.kakao.com/v2/local/search/keyword';
  static const String _categoryUrl =
      'https://dapi.kakao.com/v2/local/search/category';

  Future<RestaurantSearchResult> searchRestaurants({
    required double lat,
    required double lng,
    required String category,
    String? courseAddress,
    int radius = 3000,
  }) async {
    try {
      debugPrint(
          '🔍 Searching restaurants: lat=$lat, lng=$lng, category=$category');

      final queries = _getCategoryQueries(category);
      final restaurantsById = <String, Restaurant>{};
      final maxDistanceKm = radius / 1000 * 1.15;
      String? lastError;

      final categoryResponse =
          await _searchByCategory(lat: lat, lng: lng, radius: radius);
      if (categoryResponse.statusCode == 200) {
        final data = json.decode(categoryResponse.body) as Map<String, dynamic>;
        final documents = data['documents'] as List<dynamic>? ?? [];
        for (var i = 0; i < documents.length; i++) {
          final restaurant = Restaurant.fromJson(
            documents[i] as Map<String, dynamic>,
            lat,
            lng,
            recommendationRank: i + 100,
          );
          if (_isNearbyMealPlace(restaurant, maxDistanceKm)) {
            restaurantsById.putIfAbsent(restaurant.id, () => restaurant);
          }
        }
      } else {
        lastError = _kakaoErrorMessage(
          categoryResponse.statusCode,
          categoryResponse.body,
        );
      }

      for (final query in queries) {
        final response = await _searchByKeyword(
          query: query,
          lat: lat,
          lng: lng,
          radius: radius,
        );

        if (response.statusCode != 200) {
          debugPrint(
            '❌ Kakao keyword API: ${response.statusCode} ${response.body}',
          );
          lastError = _kakaoErrorMessage(response.statusCode, response.body);
          continue;
        }

        final data = json.decode(response.body) as Map<String, dynamic>;
        final documents = data['documents'] as List<dynamic>? ?? [];

        for (var i = 0; i < documents.length; i++) {
          final restaurant = Restaurant.fromJson(
            documents[i] as Map<String, dynamic>,
            lat,
            lng,
            recommendationRank: i,
          );
          if (_isNearbyMealPlace(restaurant, maxDistanceKm)) {
            restaurantsById.putIfAbsent(restaurant.id, () => restaurant);
          }
        }
      }

      if (restaurantsById.isEmpty && lastError != null) {
        return RestaurantSearchResult(
          restaurants: const [],
          errorMessage: lastError,
        );
      }

      final restaurants = restaurantsById.values.toList()
        ..sort((a, b) {
          final scoreCompare = restaurantSortScore(
            a,
            courseAddress,
          ).compareTo(
            restaurantSortScore(
              b,
              courseAddress,
            ),
          );
          if (scoreCompare != 0) return scoreCompare;
          final distanceCompare = a.distance.compareTo(b.distance);
          if (distanceCompare != 0) return distanceCompare;
          final localityCompare = localityMatchLevel(
            a.address,
            courseAddress,
          ).compareTo(
            localityMatchLevel(
              b.address,
              courseAddress,
            ),
          );
          if (localityCompare != 0) return localityCompare;
          final rankCompare =
              a.recommendationRank.compareTo(b.recommendationRank);
          if (rankCompare != 0) return rankCompare;
          return b.reviewCount.compareTo(a.reviewCount);
        });

      debugPrint('✅ Found ${restaurants.length} restaurants');
      return RestaurantSearchResult(restaurants: restaurants);
    } catch (e) {
      debugPrint('❌ Restaurant search error: $e');
      return RestaurantSearchResult(
        restaurants: const [],
        errorMessage: '식당 검색 중 오류가 발생했습니다.\n$e',
      );
    }
  }

  Future<http.Response> _searchByKeyword({
    required String query,
    required double lat,
    required double lng,
    required int radius,
  }) async {
    final url = Uri.parse(_keywordUrl).replace(queryParameters: {
      'query': query,
      'category_group_code': 'FD6',
      'x': lng.toString(),
      'y': lat.toString(),
      'radius': radius.toString(),
      'sort': 'distance',
      'size': '15',
    });
    return http.get(
      url,
      headers: {'Authorization': 'KakaoAK ${ApiKeys.kakaoMapKey}'},
    ).timeout(const Duration(seconds: 12));
  }

  Future<http.Response> _searchByCategory({
    required double lat,
    required double lng,
    required int radius,
  }) async {
    final url = Uri.parse(_categoryUrl).replace(queryParameters: {
      'category_group_code': 'FD6',
      'x': lng.toString(),
      'y': lat.toString(),
      'radius': radius.toString(),
      'sort': 'distance',
      'size': '15',
    });
    return http.get(
      url,
      headers: {'Authorization': 'KakaoAK ${ApiKeys.kakaoMapKey}'},
    ).timeout(const Duration(seconds: 12));
  }

  String _kakaoErrorMessage(int statusCode, String body) {
    if (statusCode == 401) {
      return '카카오 API 인증에 실패했습니다. 개발자 콘솔에서 REST API 키를 확인해 주세요.';
    }
    if (statusCode == 403) {
      return '카카오 API 사용이 제한되었습니다. 앱 플랫폼(iOS) 등록 여부를 확인해 주세요.';
    }
    return '식당 API 오류 ($statusCode)';
  }

  List<String> _getCategoryQueries(String category) {
    switch (category.toLowerCase()) {
      case '조식':
        return const [
          '아침식사 맛집',
          '해장국',
          '국밥',
          '한식 맛집',
        ];
      case '중식':
        return const [
          '점심 맛집',
          '백반',
          '한식 맛집',
          '국수',
          '갈비탕',
        ];
      default:
        return const ['음식점 맛집'];
    }
  }

  bool _isMealPlace(Restaurant restaurant) {
    final haystack =
        '${restaurant.name} ${restaurant.category} ${restaurant.categoryPath}'
            .toLowerCase();
    const excludedKeywords = [
      '카페',
      '커피',
      'coffee',
      '스타벅스',
      '투썸',
      '이디야',
      '메가커피',
      '컴포즈',
      '빽다방',
      '커피빈',
      '할리스',
      '엔제리너스',
      '파스쿠찌',
      '디저트',
      '베이커리',
      '간식',
      '제과',
      '파리바게뜨',
      '뚜레쥬르',
      '던킨',
      '배스킨',
      '공차',
    ];
    return !excludedKeywords.any(haystack.contains);
  }

  bool _isNearbyMealPlace(Restaurant restaurant, double maxDistanceKm) {
    return restaurant.distance <= maxDistanceKm && _isMealPlace(restaurant);
  }

  @visibleForTesting
  static double restaurantSortScore(
    Restaurant restaurant,
    String? courseAddress,
  ) {
    final localityPenalty = switch (
        localityMatchLevel(restaurant.address, courseAddress)) {
      0 => -0.35,
      1 => 0.75,
      2 => 1.25,
      _ => 2.0,
    };
    return restaurant.distance + localityPenalty;
  }

  @visibleForTesting
  static List<String> extractLocalityTokens(String? address) {
    final trimmed = address?.trim() ?? '';
    if (trimmed.isEmpty) return const [];

    final tokens = trimmed
        .split(RegExp(r'[\s,]+'))
        .map((token) => token.trim())
        .where((token) =>
            token.isNotEmpty &&
            RegExp(r'(특별시|광역시|특별자치시|도|시|군|구|읍|면)$').hasMatch(token))
        .toList(growable: false);

    final seen = <String>{};
    final ordered = <String>[];
    for (final token in tokens.reversed) {
      if (seen.add(token)) ordered.add(token);
    }
    return ordered;
  }

  @visibleForTesting
  static int localityMatchLevel(
      String restaurantAddress, String? courseAddress) {
    final courseTokens = extractLocalityTokens(courseAddress);
    if (courseTokens.isEmpty) return 2;

    final restaurantTokens = extractLocalityTokens(restaurantAddress).toSet();
    final restaurantRegion = _extractRegionStem(restaurantAddress);
    final courseRegion = _extractRegionStem(courseAddress ?? '');
    final districtTokens = courseTokens
        .where((token) => token.endsWith('구') || token.endsWith('군'))
        .toList(growable: false);
    final cityTokens = courseTokens
        .where((token) => token.endsWith('시'))
        .toList(growable: false);
    final regionTokens = courseTokens
        .where((token) =>
            token.endsWith('도') || token.endsWith('읍') || token.endsWith('면'))
        .toList(growable: false);

    if (districtTokens.any(restaurantTokens.contains)) return 0;
    if (restaurantRegion != null &&
        courseRegion != null &&
        restaurantRegion == courseRegion) {
      return 1;
    }
    if (cityTokens.any(restaurantTokens.contains)) return 1;
    if (regionTokens.any(restaurantTokens.contains)) return 2;
    return 3;
  }

  static String? _extractRegionStem(String address) {
    final words = address
        .trim()
        .split(RegExp(r'[\s,]+'))
        .where((token) => token.trim().isNotEmpty);
    if (words.isEmpty) return null;

    final normalized = words.first
        .replaceAll('특별자치시', '')
        .replaceAll('특별시', '')
        .replaceAll('광역시', '')
        .replaceAll('자치시', '')
        .replaceAll('도', '')
        .replaceAll('시', '')
        .trim();
    return normalized.isEmpty ? null : normalized;
  }

  Future<RestaurantDetail?> getRestaurantDetail(Restaurant restaurant) async {
    try {
      return RestaurantDetail.fromRestaurant(
        restaurant,
        phone: restaurant.phone,
        hours: '정보 확인 필요',
        reviews: const [
          '카카오 장소 페이지에서 방문 후기와 사진을 확인해 보세요.',
          '라운드 전후 식사에 맞는 음식점 카테고리만 선별했습니다.',
        ],
      );
    } catch (e) {
      debugPrint('❌ Error getting restaurant detail: $e');
      return null;
    }
  }
}
