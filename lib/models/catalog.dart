class Restaurant {
  final String id;
  final String name;
  final String cuisine;
  final String description;
  final String imagePath;
  final double rating;
  final int deliveryMinutes;
  final double deliveryFee;
  final List<FoodItem> menu;

  Restaurant({
    this.id,
    this.name,
    this.cuisine,
    this.description,
    this.imagePath,
    this.rating,
    this.deliveryMinutes,
    this.deliveryFee,
    this.menu,
  });
}

class FoodItem {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final double price;
  final String badge;

  FoodItem({
    this.id,
    this.name,
    this.description,
    this.imagePath,
    this.price,
    this.badge,
  });
}

const List<String> catalogCategories = <String>[
  'All',
  'Burgers',
  'Pizza',
  'Healthy',
  'Asian',
  'Groceries',
];

final List<Restaurant> demoRestaurants = <Restaurant>[
  Restaurant(
    id: 'fire-and-bun',
    name: 'Fire & Bun',
    cuisine: 'Burgers',
    description: 'Charcoal-grilled burgers, crisp fries, and house sauces.',
    imagePath: 'assets/images/popular_foods/ic_popular_food_1.png',
    rating: 4.8,
    deliveryMinutes: 22,
    deliveryFee: 1.49,
    menu: <FoodItem>[
      FoodItem(
        id: 'smoky-stack',
        name: 'Smoky Stack',
        description:
            'Double smashed beef, smoked cheddar, pickles, and pepper sauce.',
        imagePath: 'assets/images/popular_foods/ic_popular_food_1.png',
        price: 12.90,
        badge: 'Best seller',
      ),
      FoodItem(
        id: 'garden-crunch',
        name: 'Garden Crunch',
        description: 'Crispy mushroom patty, herb slaw, and lemon aioli.',
        imagePath: 'assets/images/popular_foods/ic_popular_food_3.png',
        price: 10.40,
        badge: 'Vegetarian',
      ),
      FoodItem(
        id: 'fire-fries',
        name: 'Fire Fries',
        description: 'Skin-on fries tossed with smoked paprika and sea salt.',
        imagePath: 'assets/images/popular_foods/ic_popular_food_6.png',
        price: 4.80,
        badge: 'Side',
      ),
    ],
  ),
  Restaurant(
    id: 'luna-pizza',
    name: 'Luna Pizza',
    cuisine: 'Pizza',
    description:
        'Slow-fermented dough and seasonal ingredients from local farms.',
    imagePath: 'assets/images/popular_foods/ic_popular_food_2.png',
    rating: 4.7,
    deliveryMinutes: 28,
    deliveryFee: 1.99,
    menu: <FoodItem>[
      FoodItem(
        id: 'margherita-luna',
        name: 'Luna Margherita',
        description: 'Tomato, fior di latte, basil oil, and aged parmesan.',
        imagePath: 'assets/images/popular_foods/ic_popular_food_2.png',
        price: 13.50,
        badge: 'Classic',
      ),
      FoodItem(
        id: 'truffle-mushroom',
        name: 'Truffle Mushroom',
        description: 'Roasted mushrooms, mozzarella, truffle cream, and thyme.',
        imagePath: 'assets/images/popular_foods/ic_popular_food_5.png',
        price: 15.20,
        badge: 'Popular',
      ),
      FoodItem(
        id: 'sparkling-citrus',
        name: 'Sparkling Citrus',
        description: 'House lemon, orange, and rosemary soda.',
        imagePath: 'assets/images/popular_foods/ic_popular_food_6.png',
        price: 3.20,
        badge: 'Drink',
      ),
    ],
  ),
  Restaurant(
    id: 'verde-table',
    name: 'Verde Table',
    cuisine: 'Healthy',
    description: 'Bright bowls and balanced plates made fresh to order.',
    imagePath: 'assets/images/popular_foods/ic_popular_food_4.png',
    rating: 4.9,
    deliveryMinutes: 19,
    deliveryFee: 0.99,
    menu: <FoodItem>[
      FoodItem(
        id: 'salmon-green-bowl',
        name: 'Salmon Green Bowl',
        description: 'Citrus salmon, avocado, greens, quinoa, and sesame.',
        imagePath: 'assets/images/popular_foods/ic_popular_food_4.png',
        price: 14.60,
        badge: 'High protein',
      ),
      FoodItem(
        id: 'rainbow-salad',
        name: 'Rainbow Salad',
        description:
            'Roasted vegetables, chickpeas, seeds, and tahini dressing.',
        imagePath: 'assets/images/popular_foods/ic_popular_food_5.png',
        price: 11.80,
        badge: 'Plant based',
      ),
      FoodItem(
        id: 'miso-broth',
        name: 'Miso Broth',
        description: 'Silky miso broth with tofu, mushrooms, and scallions.',
        imagePath: 'assets/images/popular_foods/ic_popular_food_3.png',
        price: 6.40,
        badge: 'Light meal',
      ),
    ],
  ),
  Restaurant(
    id: 'nori-house',
    name: 'Nori House',
    cuisine: 'Asian',
    description: 'Japanese comfort bowls, rolls, and bright seasonal sides.',
    imagePath: 'assets/images/popular_foods/ic_popular_food_6.png',
    rating: 4.6,
    deliveryMinutes: 25,
    deliveryFee: 1.25,
    menu: <FoodItem>[
      FoodItem(
        id: 'miso-salmon-roll',
        name: 'Miso Salmon Roll',
        description: 'Salmon, cucumber, avocado, and miso sesame glaze.',
        imagePath: 'assets/images/popular_foods/ic_popular_food_6.png',
        price: 12.30,
        badge: 'Chef pick',
      ),
      FoodItem(
        id: 'teriyaki-bowl',
        name: 'Teriyaki Bowl',
        description:
            'Glazed chicken, steamed rice, greens, and pickled ginger.',
        imagePath: 'assets/images/popular_foods/ic_popular_food_1.png',
        price: 11.90,
        badge: 'Comfort food',
      ),
      FoodItem(
        id: 'edamame-salt',
        name: 'Sea Salt Edamame',
        description: 'Warm edamame finished with flaky sea salt.',
        imagePath: 'assets/images/popular_foods/ic_popular_food_3.png',
        price: 4.10,
        badge: 'Side',
      ),
    ],
  ),
  Restaurant(
    id: 'daily-market',
    name: 'Daily Market',
    cuisine: 'Groceries',
    description: 'Fresh produce, pantry staples, and everyday essentials.',
    imagePath: 'assets/images/bestfood/ic_best_food_8.jpeg',
    rating: 4.8,
    deliveryMinutes: 16,
    deliveryFee: 1.19,
    menu: <FoodItem>[
      FoodItem(
        id: 'weekday-produce-box',
        name: 'Weekday Produce Box',
        description: 'Seasonal fruit and vegetables for easy weeknight meals.',
        imagePath: 'assets/images/bestfood/ic_best_food_8.jpeg',
        price: 18.50,
        badge: 'Fresh today',
      ),
      FoodItem(
        id: 'breakfast-starter',
        name: 'Breakfast Starter',
        description: 'Eggs, sourdough, berries, yogurt, and granola.',
        imagePath: 'assets/images/bestfood/ic_best_food_3.jpeg',
        price: 15.90,
        badge: 'Popular basket',
      ),
      FoodItem(
        id: 'pantry-refill',
        name: 'Pantry Refill',
        description: 'Olive oil, pasta, tomatoes, coffee, and sea salt.',
        imagePath: 'assets/images/bestfood/ic_best_food_5.jpeg',
        price: 24.20,
        badge: 'Essentials',
      ),
    ],
  ),
];

List<Restaurant> findRestaurants(String query, String category,
    [List<Restaurant> restaurants]) {
  final String normalizedQuery = query.trim().toLowerCase();
  final List<Restaurant> source = restaurants ?? demoRestaurants;

  return source.where((Restaurant restaurant) {
    final bool matchesCategory =
        category == 'All' || restaurant.cuisine == category;
    final bool matchesQuery = normalizedQuery.isEmpty ||
        restaurant.name.toLowerCase().contains(normalizedQuery) ||
        restaurant.cuisine.toLowerCase().contains(normalizedQuery) ||
        restaurant.menu.any((FoodItem item) =>
            item.name.toLowerCase().contains(normalizedQuery) ||
            item.description.toLowerCase().contains(normalizedQuery));

    return matchesCategory && matchesQuery;
  }).toList();
}

String formatPrice(double amount) {
  return '\$' + amount.toStringAsFixed(2);
}
