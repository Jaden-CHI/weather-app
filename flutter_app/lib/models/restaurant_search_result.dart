import 'restaurant.dart';

class RestaurantSearchResult {
  final List<Restaurant> restaurants;
  final String? errorMessage;

  const RestaurantSearchResult({
    required this.restaurants,
    this.errorMessage,
  });

  bool get hasError => errorMessage != null;
}
