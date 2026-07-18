import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/models/restaurant.dart';
import 'package:weather_app/services/restaurant_service.dart';

void main() {
  group('Restaurant.fromJson', () {
    test('Kakao distance 값이 있으면 그 값을 우선 사용한다', () {
      final restaurant = Restaurant.fromJson(
        {
          'id': '1',
          'place_name': '테스트 식당',
          'category_name': '음식점 > 한식',
          'address_name': '인천',
          'x': '126.6000',
          'y': '37.5000',
          'distance': '850',
        },
        37.4000,
        126.5000,
      );

      expect(restaurant.distance, closeTo(0.85, 0.0001));
    });

    test('distance 값이 없으면 좌표로 거리를 계산한다', () {
      final restaurant = Restaurant.fromJson(
        {
          'id': '2',
          'place_name': '근처 식당',
          'category_name': '음식점 > 한식',
          'address_name': '서울',
          'x': '127.0000',
          'y': '37.0000',
        },
        37.0000,
        127.0090,
      );

      expect(restaurant.distance, greaterThan(0.7));
      expect(restaurant.distance, lessThan(1.1));
    });
  });

  group('RestaurantService locality helpers', () {
    Restaurant restaurant({
      required String id,
      required String address,
      required double distance,
    }) {
      return Restaurant(
        id: id,
        name: id,
        rating: 0,
        reviewCount: 0,
        distance: distance,
        category: '한식',
        address: address,
        lat: 37,
        lng: 126,
      );
    }

    test('골프장 주소에서 지역 토큰을 추출한다', () {
      expect(
        RestaurantService.extractLocalityTokens('인천광역시 서구 거월로 61'),
        containsAllInOrder(<String>['서구', '인천광역시']),
      );
    });

    test('같은 구 주소를 더 가깝게 우선순위 매긴다', () {
      expect(
        RestaurantService.localityMatchLevel(
          '인천 서구 원창동 381-76',
          '인천광역시 서구 거월로 61',
        ),
        0,
      );
      expect(
        RestaurantService.localityMatchLevel(
          '인천 중구 운서동 123-4',
          '인천광역시 서구 거월로 61',
        ),
        1,
      );
      expect(
        RestaurantService.localityMatchLevel(
          '경기 김포시 고촌읍 10',
          '인천광역시 서구 거월로 61',
        ),
        3,
      );
    });

    test('같은 광역시라도 먼 식당보다 실제 가까운 식당을 우선한다', () {
      final farSameCity = restaurant(
        id: '먼 인천 식당',
        address: '인천광역시 중구 운서동 123-4',
        distance: 3.2,
      );
      final nearBorder = restaurant(
        id: '가까운 경계 식당',
        address: '경기도 김포시 고촌읍 10',
        distance: 0.8,
      );

      const courseAddress = '인천광역시 서구 거월로 61';

      expect(
        RestaurantService.restaurantSortScore(nearBorder, courseAddress),
        lessThan(
          RestaurantService.restaurantSortScore(farSameCity, courseAddress),
        ),
      );
    });

    test('같은 구 식당은 비슷한 거리의 타지역 식당보다 우선한다', () {
      final sameDistrict = restaurant(
        id: '서구 식당',
        address: '인천광역시 서구 오류동 1',
        distance: 1.6,
      );
      final otherRegion = restaurant(
        id: '타지역 식당',
        address: '경기도 김포시 고촌읍 10',
        distance: 1.0,
      );

      const courseAddress = '인천광역시 서구 거월로 61';

      expect(
        RestaurantService.restaurantSortScore(sameDistrict, courseAddress),
        lessThan(
          RestaurantService.restaurantSortScore(otherRegion, courseAddress),
        ),
      );
    });
  });
}
