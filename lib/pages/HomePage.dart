import 'package:flutter/material.dart';
import 'package:flutter_app/models/catalog.dart';
import 'package:flutter_app/pages/FoodOrderPage.dart';
import 'package:flutter_app/pages/RestaurantMenuPage.dart';
import 'package:flutter_app/services/catalog_repository.dart';
import 'package:flutter_app/state/cart_store.dart';
import 'package:flutter_app/widgets/CartButton.dart';
import 'package:flutter_app/widgets/catalog_image.dart';

const Color _ink = Color(0xFF172019);
const Color _muted = Color(0xFF687068);
const Color _accent = Color(0xFFE86B47);
const Color _canvas = Color(0xFFF6F5F1);
const Color _lime = Color(0xFFB8F55A);

class HomePage extends StatefulWidget {
  final CartStore cart;

  const HomePage({Key key, @required this.cart}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTab = 0;
  String _query = '';
  String _selectedCategory = 'All';
  String _fulfillment = 'Delivery';
  String _deliveryZone = 'Central District';
  bool _quickOnly = false;
  final CatalogRepository _catalogRepository = CatalogRepository();
  List<Restaurant> _catalogRestaurants = demoRestaurants;
  bool _isRefreshingCatalog = false;
  bool _catalogError = false;

  @override
  void initState() {
    super.initState();
    _refreshCatalog();
  }

  @override
  void dispose() {
    _catalogRepository.close();
    super.dispose();
  }

  List<Restaurant> get _restaurants {
    List<Restaurant> results =
        findRestaurants(_query, _selectedCategory, _catalogRestaurants);
    if (_quickOnly) {
      results = results.where((Restaurant store) {
        return store.deliveryMinutes <= 25;
      }).toList();
    }
    return results;
  }

  bool get _showCatalogStatus {
    return _catalogRepository.isConfigured &&
        (_isRefreshingCatalog || _catalogError);
  }

  Future<void> _refreshCatalog() async {
    if (!_catalogRepository.isConfigured || _isRefreshingCatalog) {
      return;
    }

    setState(() {
      _isRefreshingCatalog = true;
      _catalogError = false;
    });

    try {
      final List<Restaurant> restaurants =
          await _catalogRepository.loadRestaurants();
      if (!mounted) {
        return;
      }
      setState(() {
        if (restaurants.isNotEmpty) {
          _catalogRestaurants = restaurants;
        }
        _isRefreshingCatalog = false;
        _catalogError = restaurants.isEmpty;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isRefreshingCatalog = false;
        _catalogError = true;
      });
    }
  }

  void _openCart() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) => FoodOrderPage(cart: widget.cart),
    ));
  }

  void _openRestaurant(Restaurant restaurant) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) => RestaurantMenuPage(
        restaurant: restaurant,
        cart: widget.cart,
      ),
    ));
  }

  void _showLocationPicker() {
    final List<String> zones = <String>[
      'Central District',
      'Riverside',
      'North Quarter',
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5D8D3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Choose a delivery area',
                style: TextStyle(
                  color: _ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Demo locations control which stores are shown first.',
                style: TextStyle(color: _muted, fontSize: 14),
              ),
              const SizedBox(height: 14),
              Column(
                children: zones.map((String zone) {
                  final bool selected = zone == _deliveryZone;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected ? _accent : _muted,
                    ),
                    title: Text(
                      zone,
                      style: TextStyle(
                        color: _ink,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _deliveryZone = zone;
                      });
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _setCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.cart,
      builder: (BuildContext context, Widget child) {
        return Scaffold(
          backgroundColor: _canvas,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: _buildActiveTab(context),
                  ),
                );
              },
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: _MarketplaceNavigation(
              selectedIndex: _selectedTab,
              onSelected: (int index) {
                setState(() {
                  _selectedTab = index;
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveTab(BuildContext context) {
    if (_selectedTab == 1) {
      return _buildBrowseTab(context);
    }
    if (_selectedTab == 2) {
      return _OrdersTab(cart: widget.cart);
    }
    if (_selectedTab == 3) {
      return _AccountTab(onInfo: _showInfo);
    }
    return _buildHomeTab(context);
  }

  Widget _buildHomeTab(BuildContext context) {
    final List<Restaurant> restaurants = _restaurants;
    final List<Widget> content = <Widget>[
      _buildTopBar(context),
      const SizedBox(height: 22),
      const Text(
        'Your neighborhood,\non demand.',
        style: TextStyle(
          color: _ink,
          fontSize: 39,
          height: 1.0,
          letterSpacing: -1.3,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Restaurants, groceries, and essentials delivered to $_deliveryZone.',
        style: const TextStyle(color: _muted, fontSize: 15, height: 1.4),
      ),
      const SizedBox(height: 20),
      _buildSearchField(),
      const SizedBox(height: 12),
      _buildServiceFilters(),
      _buildCatalogStatus(),
      const SizedBox(height: 26),
      const _SectionHeading(
        title: 'Start with a craving',
        trailing: 'Browse all',
      ),
      const SizedBox(height: 12),
      _buildCategoryRail(),
      const SizedBox(height: 28),
      _buildOfferPanel(),
      const SizedBox(height: 30),
      const _SectionHeading(
        title: 'Picked for you',
        trailing: 'See more',
      ),
      const SizedBox(height: 12),
      _FeaturedRail(
        restaurants: restaurants.take(3).toList(),
        onSelected: _openRestaurant,
      ),
      const SizedBox(height: 30),
      _SectionHeading(
        title: _query.isEmpty ? 'All nearby' : 'Search results',
        trailing: '${restaurants.length} stores',
      ),
      const SizedBox(height: 12),
      _RestaurantFeed(
        restaurants: restaurants,
        onSelected: _openRestaurant,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: content,
    );
  }

  Widget _buildBrowseTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Explore stores',
                style: TextStyle(
                  color: _ink,
                  fontSize: 31,
                  letterSpacing: -0.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            CartButton(cart: widget.cart, onPressed: _openCart),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Find a local favorite or fill a weekly basket.',
          style: TextStyle(color: _muted, fontSize: 15),
        ),
        const SizedBox(height: 20),
        _buildSearchField(),
        const SizedBox(height: 18),
        _buildCategoryRail(compact: true),
        const SizedBox(height: 22),
        _buildServiceFilters(),
        _buildCatalogStatus(),
        const SizedBox(height: 26),
        _SectionHeading(
          title: _selectedCategory == 'All'
              ? 'Every store'
              : '$_selectedCategory near you',
          trailing: '${_restaurants.length} stores',
        ),
        const SizedBox(height: 12),
        _RestaurantFeed(
          restaurants: _restaurants,
          onSelected: _openRestaurant,
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: _ink, shape: BoxShape.circle),
          child: const Text(
            'M',
            style: TextStyle(
              color: _lime,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _showLocationPicker,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'DELIVERING TO',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 10,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          _deliveryZone,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: _ink),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        CartButton(cart: widget.cart, onPressed: _openCart),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: TextFormField(
        key: const Key('restaurant-search'),
        initialValue: _query,
        onChanged: (String value) {
          setState(() {
            _query = value;
          });
        },
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          hintText: 'Search dishes, stores, groceries',
          hintStyle: TextStyle(color: Color(0xFF8B928B), fontSize: 15),
          prefixIcon: Icon(Icons.search, color: _ink),
          suffixIcon: Icon(Icons.tune, color: _ink),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 17),
        ),
      ),
    );
  }

  Widget _buildServiceFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _ServiceFilter(
            label: 'Delivery',
            icon: Icons.delivery_dining,
            selected: _fulfillment == 'Delivery',
            onTap: () {
              setState(() {
                _fulfillment = 'Delivery';
              });
            },
          ),
          const SizedBox(width: 8),
          _ServiceFilter(
            label: 'Pickup',
            icon: Icons.storefront,
            selected: _fulfillment == 'Pickup',
            onTap: () {
              setState(() {
                _fulfillment = 'Pickup';
              });
            },
          ),
          const SizedBox(width: 8),
          _ServiceFilter(
            label: 'Under 25 min',
            icon: Icons.bolt,
            selected: _quickOnly,
            onTap: () {
              setState(() {
                _quickOnly = !_quickOnly;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogStatus() {
    if (!_showCatalogStatus) {
      return const SizedBox.shrink();
    }

    final List<Widget> children = <Widget>[
      _isRefreshingCatalog
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_accent),
              ),
            )
          : const Icon(Icons.cloud_off_outlined, color: _muted, size: 18),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          _isRefreshingCatalog
              ? 'Refreshing nearby stores...'
              : 'Catalog refresh is unavailable.',
          style: const TextStyle(
            color: _muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ];
    if (!_isRefreshingCatalog) {
      children.add(TextButton(
        onPressed: _refreshCatalog,
        child: const Text(
          'Retry',
          style: TextStyle(
            color: _accent,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        key: const Key('catalog-refresh-status'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: children),
      ),
    );
  }

  Widget _buildCategoryRail({bool compact = false}) {
    final double tileWidth = compact ? 92 : 106;
    final double tileHeight = compact ? 92 : 112;

    return SizedBox(
      height: tileHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _categoryOptions.map((_CategoryOption category) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _CategoryTile(
              category: category,
              selected: category.value == _selectedCategory,
              width: tileWidth,
              height: tileHeight,
              onTap: () => _setCategory(category.value),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOfferPanel() {
    return Container(
      height: 166,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -35,
            top: -54,
            child: Container(
              width: 212,
              height: 212,
              decoration:
                  const BoxDecoration(color: _lime, shape: BoxShape.circle),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -25,
            child: Transform.rotate(
              angle: -0.15,
              child: Image.asset(
                'assets/images/popular_foods/ic_popular_food_2.png',
                width: 178,
                height: 178,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'LOCAL FAVORITES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      letterSpacing: 0.9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'A better night\nstarts here.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1.02,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Curated meals, no guesswork.',
                  style: TextStyle(color: Color(0xFFD1D7D0), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String trailing;

  const _SectionHeading({Key key, this.title, this.trailing}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 22,
              letterSpacing: -0.4,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(
            color: _accent,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ServiceFilter extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ServiceFilter({
    Key key,
    this.label,
    this.icon,
    this.selected,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _ink : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 17, color: selected ? _lime : _ink),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryOption {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _CategoryOption(this.value, this.label, this.icon, this.color);
}

const List<_CategoryOption> _categoryOptions = <_CategoryOption>[
  _CategoryOption('All', 'All', Icons.restaurant, Color(0xFFECE8DE)),
  _CategoryOption('Burgers', 'Burgers', Icons.lunch_dining, Color(0xFFFFD9C7)),
  _CategoryOption('Pizza', 'Pizza', Icons.local_pizza, Color(0xFFFFE7A2)),
  _CategoryOption('Healthy', 'Healthy', Icons.eco, Color(0xFFD7EFBE)),
  _CategoryOption('Asian', 'Asian', Icons.ramen_dining, Color(0xFFD9E4FF)),
  _CategoryOption(
      'Groceries', 'Groceries', Icons.local_grocery_store, Color(0xFFFFD5DE)),
];

class _CategoryTile extends StatelessWidget {
  final _CategoryOption category;
  final bool selected;
  final double width;
  final double height;
  final VoidCallback onTap;

  const _CategoryTile({
    Key key,
    this.category,
    this.selected,
    this.width,
    this.height,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _ink : category.color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: height,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withOpacity(0.16)
                        : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category.icon,
                    color: selected ? _lime : _ink,
                    size: 19,
                  ),
                ),
                const Spacer(),
                Text(
                  category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedRail extends StatelessWidget {
  final List<Restaurant> restaurants;
  final ValueChanged<Restaurant> onSelected;

  const _FeaturedRail({Key key, this.restaurants, this.onSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 212,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: restaurants.map((Restaurant restaurant) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _FeaturedCard(
              restaurant: restaurant,
              onTap: () => onSelected(restaurant),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  const _FeaturedCard({Key key, this.restaurant, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: Key('featured-${restaurant.id}'),
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          width: 238,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                        child: Container(
                          color: const Color(0xFFF0ECE2),
                          child: CatalogImage(
                            imagePath: restaurant.imagePath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${restaurant.deliveryMinutes} min',
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      restaurant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${restaurant.cuisine}  |  ${formatPrice(restaurant.deliveryFee)} fee',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestaurantFeed extends StatelessWidget {
  final List<Restaurant> restaurants;
  final ValueChanged<Restaurant> onSelected;

  const _RestaurantFeed({Key key, this.restaurants, this.onSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: <Widget>[
            const Icon(Icons.search_off, color: _muted, size: 38),
            const SizedBox(height: 10),
            const Text(
              'Nothing matches that search yet.',
              style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            const Text(
              'Try another dish, store, or category.',
              style: TextStyle(color: _muted),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isWide = constraints.maxWidth >= 760;
        final double cardWidth =
            isWide ? (constraints.maxWidth - 14) / 2 : constraints.maxWidth;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: restaurants.map((Restaurant restaurant) {
            return SizedBox(
              width: cardWidth,
              child: _RestaurantCard(
                restaurant: restaurant,
                onTap: () => onSelected(restaurant),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  const _RestaurantCard({Key key, this.restaurant, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: Key('restaurant-${restaurant.id}'),
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 1.85,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Container(
                        color: const Color(0xFFF0ECE2),
                        child: CatalogImage(
                          imagePath: restaurant.imagePath,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: _ink,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        restaurant.cuisine.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.star, color: _accent, size: 15),
                          const SizedBox(width: 3),
                          Text(
                            restaurant.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          restaurant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: _accent, size: 18),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    restaurant.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.timer_outlined, color: _muted, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurant.deliveryMinutes} min',
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 13),
                      const Icon(Icons.delivery_dining,
                          color: _muted, size: 17),
                      const SizedBox(width: 4),
                      Text(
                        formatPrice(restaurant.deliveryFee),
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  final CartStore cart;

  const _OrdersTab({Key key, this.cart}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final OrderReceipt receipt = cart.lastOrder;
    if (receipt == null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const Text(
            'Orders',
            style: TextStyle(
              color: _ink,
              fontSize: 31,
              letterSpacing: -0.8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.receipt, color: _lime, size: 34),
                const SizedBox(height: 22),
                const Text(
                  'Nothing in motion yet.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Your active delivery and order history will appear here.',
                  style: TextStyle(color: Color(0xFFD1D7D0), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        const Text(
          'Orders',
          style: TextStyle(
            color: _ink,
            fontSize: 31,
            letterSpacing: -0.8,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'MOST RECENT',
                style: TextStyle(
                  color: _accent,
                  letterSpacing: 0.9,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                receipt.restaurantName,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${receipt.orderNumber}  |  ${receipt.itemCount} item${receipt.itemCount == 1 ? '' : 's'}',
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 18),
              const _OrderStatusRow(
                icon: Icons.check_circle,
                label: 'Order received',
                detail: 'Your kitchen has the request.',
                active: true,
              ),
              const _OrderStatusRow(
                icon: Icons.restaurant,
                label: 'Preparing your order',
                detail: 'Live merchant updates connect next.',
              ),
              const _OrderStatusRow(
                icon: Icons.delivery_dining,
                label: 'Courier pickup',
                detail: 'Dispatch tracking connects next.',
              ),
              const SizedBox(height: 10),
              Text(
                'Total ${formatPrice(receipt.total)}',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderStatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  final bool active;

  const _OrderStatusRow({
    Key key,
    this.icon,
    this.label,
    this.detail,
    this.active = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon,
              color: active ? _accent : const Color(0xFFB7BDB6), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    color: active ? _ink : _muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTab extends StatelessWidget {
  final ValueChanged<String> onInfo;

  const _AccountTab({Key key, this.onInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        const Text(
          'Account',
          style: TextStyle(
            color: _ink,
            fontSize: 31,
            letterSpacing: -0.8,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration:
                    const BoxDecoration(color: _lime, shape: BoxShape.circle),
                child: const Icon(Icons.person_outline, color: _ink, size: 29),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Guest explorer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sign in to save your places and orders.',
                      style: TextStyle(color: Color(0xFFD1D7D0), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _AccountAction(
          icon: Icons.location_on_outlined,
          title: 'Saved places',
          subtitle: 'Home, work, and more',
          onTap: () =>
              onInfo('Address management is the next account feature.'),
        ),
        _AccountAction(
          icon: Icons.payment,
          title: 'Payment methods',
          subtitle: 'Secure payment setup is pending backend integration',
          onTap: () =>
              onInfo('Payment setup will use the selected hosted gateway.'),
        ),
        _AccountAction(
          icon: Icons.local_offer_outlined,
          title: 'Promos and credits',
          subtitle: 'Offers available when checkout is connected',
          onTap: () =>
              onInfo('Promo codes will be validated by the order service.'),
        ),
        _AccountAction(
          icon: Icons.help_outline,
          title: 'Help',
          subtitle: 'Support and delivery playbooks',
          onTap: () =>
              onInfo('Support workflows are planned for the operations phase.'),
        ),
      ],
    );
  }
}

class _AccountAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AccountAction({
    Key key,
    this.icon,
    this.title,
    this.subtitle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0ECE2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _ink, size: 20),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: _muted, size: 15),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketplaceNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _MarketplaceNavigation({Key key, this.selectedIndex, this.onSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    const List<_NavigationDestination> destinations = <_NavigationDestination>[
      _NavigationDestination(Icons.home_outlined, Icons.home, 'Home'),
      _NavigationDestination(Icons.explore_outlined, Icons.explore, 'Browse'),
      _NavigationDestination(Icons.receipt_outlined, Icons.receipt, 'Orders'),
      _NavigationDestination(Icons.person_outline, Icons.person, 'Account'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE7E6E0))),
      ),
      child: Row(
        children: destinations
            .asMap()
            .entries
            .map((MapEntry<int, _NavigationDestination> entry) {
          final int index = entry.key;
          final _NavigationDestination destination = entry.value;
          final bool selected = index == selectedIndex;

          return Expanded(
            child: InkWell(
              key: Key('tab-${destination.label.toLowerCase()}'),
              onTap: () => onSelected(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      color: selected ? _accent : _muted,
                      size: 22,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      destination.label,
                      style: TextStyle(
                        color: selected ? _ink : _muted,
                        fontSize: 11,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavigationDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavigationDestination(this.icon, this.selectedIcon, this.label);
}
