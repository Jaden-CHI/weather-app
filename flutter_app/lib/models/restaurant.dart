import 'dart:math';

class Restaurant {
  final String id;
  final String name;
  final double rating;
  final int reviewCount;
  final double distance;
  final String category;
  final String categoryPath;
  final String address;
  final double lat;
  final double lng;
  final String phone;
  final String placeUrl;
  final int recommendationRank;

  Restaurant({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviewCount,
    required this.distance,
    required this.category,
    this.categoryPath = '',
    required this.address,
    required this.lat,
    required this.lng,
    this.phone = '',
    this.placeUrl = '',
    this.recommendationRank = 999,
  });

  factory Restaurant.fromJson(
    Map<String, dynamic> json,
    double userLat,
    double userLng, {
    int recommendationRank = 999,
  }) {
    final x = double.tryParse(json['x']?.toString() ?? '0') ?? 0.0;
    final y = double.tryParse(json['y']?.toString() ?? '0') ?? 0.0;
    final apiDistanceMeters =
        double.tryParse(json['distance']?.toString() ?? '');
    final distanceMeters = apiDistanceMeters != null && apiDistanceMeters > 0
        ? apiDistanceMeters
        : _distanceMetersBetween(
            lat1: userLat,
            lng1: userLng,
            lat2: y,
            lng2: x,
          );

    return Restaurant(
      id: json['id']?.toString() ?? '',
      name: json['place_name'] as String? ?? '',
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      reviewCount: int.tryParse(json['review_count']?.toString() ?? '0') ?? 0,
      distance: distanceMeters / 1000,
      category: _extractCategory(json['category_name'] as String? ?? ''),
      categoryPath: json['category_name'] as String? ?? '',
      address: json['address_name'] as String? ?? '',
      lat: y,
      lng: x,
      phone: json['phone'] as String? ?? '',
      placeUrl: json['place_url'] as String? ?? '',
      recommendationRank: recommendationRank,
    );
  }

  static String _extractCategory(String categoryPath) {
    final parts = categoryPath
        .split('>')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length >= 2) return parts[1];
    if (parts.isNotEmpty) return parts.first;
    return '';
  }

  static double _distanceMetersBetween({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}

class RestaurantDetail extends Restaurant {
  final String hours;
  final List<String> reviews;

  RestaurantDetail({
    required super.id,
    required super.name,
    required super.rating,
    required super.reviewCount,
    required super.distance,
    required super.category,
    required super.categoryPath,
    required super.address,
    required super.lat,
    required super.lng,
    required super.phone,
    required this.hours,
    required this.reviews,
    required super.placeUrl,
  });

  factory RestaurantDetail.fromRestaurant(
    Restaurant restaurant, {
    String phone = '',
    String hours = '미지정',
    List<String> reviews = const [],
  }) {
    return RestaurantDetail(
      id: restaurant.id,
      name: restaurant.name,
      rating: restaurant.rating,
      reviewCount: restaurant.reviewCount,
      distance: restaurant.distance,
      category: restaurant.category,
      categoryPath: restaurant.categoryPath,
      address: restaurant.address,
      lat: restaurant.lat,
      lng: restaurant.lng,
      phone: phone.isNotEmpty ? phone : restaurant.phone,
      hours: hours,
      reviews: reviews,
      placeUrl: restaurant.placeUrl,
    );
  }
}
