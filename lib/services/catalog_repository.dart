import 'package:flutter_app/models/catalog.dart';
import 'package:flutter_app/services/catalog_api_service.dart';

const List<String> _fallbackImages = <String>[
  'assets/images/popular_foods/ic_popular_food_1.png',
  'assets/images/popular_foods/ic_popular_food_2.png',
  'assets/images/popular_foods/ic_popular_food_3.png',
  'assets/images/popular_foods/ic_popular_food_4.png',
  'assets/images/popular_foods/ic_popular_food_5.png',
  'assets/images/popular_foods/ic_popular_food_6.png',
];

class CatalogRepository {
  final CatalogApiService _apiService;

  CatalogRepository({CatalogApiService apiService})
      : _apiService = apiService ?? CatalogApiService();

  bool get isConfigured => _apiService.isConfigured;

  Future<List<Restaurant>> loadRestaurants() async {
    final CatalogApiData catalog = await _apiService.fetchCatalog();
    final Map<String, String> categoryNames =
        _categoryNames(catalog.categories);
    final List<Restaurant> restaurants = <Restaurant>[];

    for (int index = 0; index < catalog.merchants.length; index++) {
      final Restaurant restaurant = _toRestaurant(
        catalog.merchants[index],
        categoryNames,
        index,
      );
      if (restaurant != null) {
        restaurants.add(restaurant);
      }
    }

    return restaurants;
  }

  void close() {
    _apiService.close();
  }

  static Map<String, String> _categoryNames(
      List<Map<String, dynamic>> categories) {
    final Map<String, String> names = <String, String>{};
    for (final Map<String, dynamic> category in categories) {
      final String id = _stringValue(category['id']);
      final String name = _stringValue(category['name']);
      if (id.isNotEmpty && name.isNotEmpty) {
        names[id] = name;
      }
    }
    return names;
  }

  static Restaurant _toRestaurant(
    CatalogMerchantData catalogMerchant,
    Map<String, String> categoryNames,
    int merchantIndex,
  ) {
    final Map<String, dynamic> merchant = catalogMerchant.merchant;
    final String id = _stringValue(merchant['id']);
    final String name = _stringValue(merchant['name']);
    if (id.isEmpty || name.isEmpty) {
      return null;
    }

    final List<FoodItem> menu = <FoodItem>[];
    for (int index = 0; index < catalogMerchant.products.length; index++) {
      final FoodItem item = _toFoodItem(
        catalogMerchant.products[index],
        categoryNames,
        merchantIndex + index,
      );
      if (item != null) {
        menu.add(item);
      }
    }

    int deliveryMinutes =
        _integerValue(merchant['estimatedDeliveryMinutes'], 30);
    if (deliveryMinutes < 1) {
      deliveryMinutes = 30;
    }

    final String description = _stringValue(merchant['description']);
    final String coverImage = _stringValue(merchant['coverImageUrl']);
    final String logoImage = _stringValue(merchant['logoUrl']);
    return Restaurant(
      id: id,
      name: name,
      cuisine: _cuisine(merchant, catalogMerchant.products, categoryNames),
      description: description.isEmpty
          ? 'Local favorites delivered to your door.'
          : description,
      imagePath: _imagePath(
        coverImage.isEmpty ? logoImage : coverImage,
        merchantIndex,
      ),
      rating: 4.7,
      deliveryMinutes: deliveryMinutes,
      deliveryFee: _doubleValue(merchant['deliveryFee'], 0.0),
      menu: menu,
    );
  }

  static FoodItem _toFoodItem(
    Map<String, dynamic> product,
    Map<String, String> categoryNames,
    int imageIndex,
  ) {
    final String id = _stringValue(product['id']);
    final String name = _stringValue(product['name']);
    if (id.isEmpty || name.isEmpty) {
      return null;
    }

    final String category = _productCategory(product, categoryNames);
    final List<String> tags = _stringList(product['tags']);
    final String description = _stringValue(product['description']);
    return FoodItem(
      id: id,
      name: name,
      description: description.isEmpty
          ? 'Prepared fresh and ready for delivery.'
          : description,
      imagePath: _imagePath(_stringValue(product['imageUrl']), imageIndex),
      price: _doubleValue(product['price'], 0.0),
      badge: category.isNotEmpty
          ? category
          : (tags.isEmpty ? 'Menu item' : tags.first),
    );
  }

  static String _cuisine(
    Map<String, dynamic> merchant,
    List<Map<String, dynamic>> products,
    Map<String, String> categoryNames,
  ) {
    final String type = _stringValue(merchant['type']).toUpperCase();
    if (type == 'GROCERY') {
      return 'Groceries';
    }

    for (final Map<String, dynamic> product in products) {
      final String category = _productCategory(product, categoryNames);
      if (category.isNotEmpty) {
        return category;
      }
    }

    if (type.isEmpty || type == 'RESTAURANT') {
      return 'Restaurant';
    }
    return type.substring(0, 1) + type.substring(1).toLowerCase();
  }

  static String _productCategory(
    Map<String, dynamic> product,
    Map<String, String> categoryNames,
  ) {
    final dynamic rawCategory = product['category'];
    if (rawCategory is Map) {
      final String name = _stringValue(rawCategory['name']);
      if (name.isNotEmpty) {
        return name;
      }
      final String id = _stringValue(rawCategory['id']);
      if (id.isNotEmpty && categoryNames.containsKey(id)) {
        return categoryNames[id];
      }
    }

    final String categoryId = _stringValue(product['categoryId']);
    return categoryNames[categoryId] ?? '';
  }

  static String _imagePath(String value, int index) {
    return value.isEmpty
        ? _fallbackImages[index % _fallbackImages.length]
        : value;
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) {
      return <String>[];
    }
    return value
        .map<String>(_stringValue)
        .where((String entry) => entry.isNotEmpty)
        .toList();
  }

  static String _stringValue(dynamic value) {
    return value == null ? '' : value.toString().trim();
  }

  static double _doubleValue(dynamic value, double fallback) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim()) ?? fallback;
    }
    return fallback;
  }

  static int _integerValue(dynamic value, int fallback) {
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      final double parsed = double.tryParse(value.trim());
      return parsed == null ? fallback : parsed.round();
    }
    return fallback;
  }
}
