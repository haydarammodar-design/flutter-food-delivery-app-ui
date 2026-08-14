import 'package:flutter/material.dart';
import 'package:flutter_app/models/catalog.dart';
import 'package:flutter_app/pages/FoodDetailsPage.dart';
import 'package:flutter_app/pages/FoodOrderPage.dart';
import 'package:flutter_app/state/cart_store.dart';
import 'package:flutter_app/widgets/CartButton.dart';
import 'package:flutter_app/widgets/catalog_image.dart';

const Color _ink = Color(0xFF172019);
const Color _muted = Color(0xFF687068);
const Color _accent = Color(0xFFE86B47);
const Color _canvas = Color(0xFFF6F5F1);
const Color _lime = Color(0xFFB8F55A);

class RestaurantMenuPage extends StatelessWidget {
  final Restaurant restaurant;
  final CartStore cart;

  const RestaurantMenuPage(
      {Key key, @required this.restaurant, @required this.cart})
      : super(key: key);

  void _openCart(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) => FoodOrderPage(cart: cart),
    ));
  }

  void _openItem(BuildContext context, FoodItem item) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) => FoodDetailsPage(
        restaurant: restaurant,
        item: item,
        cart: cart,
      ),
    ));
  }

  Future<void> _quickAdd(BuildContext context, FoodItem item) async {
    final bool added = cart.addItem(restaurant, item);
    if (!added) {
      final bool replace = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Start a new basket?'),
            content: Text(
              'Your basket has items from ${cart.restaurant.name}. '
              'Keep one kitchen per basket for a smoother delivery.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep basket'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(primary: _accent),
                child: const Text('Start new'),
              ),
            ],
          );
        },
      );

      if (replace != true) {
        return;
      }
      cart.replaceWith(restaurant, item);
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${item.name} added to your basket.'),
      action: SnackBarAction(
        label: 'VIEW BASKET',
        onPressed: () => _openCart(context),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: _canvas,
        elevation: 0,
        iconTheme: const IconThemeData(color: _ink),
        actions: <Widget>[
          CartButton(cart: cart, onPressed: () => _openCart(context)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: _buildContent(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context) {
    final List<Widget> content = <Widget>[
      Hero(
        tag: 'restaurant-${restaurant.id}',
        child: Container(
          height: 242,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFF0ECE2),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: CatalogImage(
                  imagePath: restaurant.imagePath,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                left: 14,
                top: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _ink,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'OPEN NOW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      letterSpacing: 0.9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 14,
                top: 14,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.favorite_border, color: _ink, size: 21),
                ),
              ),
              Positioned(
                left: 14,
                bottom: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.star, color: _accent, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurant.rating.toStringAsFixed(1)} rated',
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 12,
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
      ),
      const SizedBox(height: 22),
      Text(
        restaurant.cuisine.toUpperCase(),
        style: const TextStyle(
          color: _accent,
          fontSize: 12,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        restaurant.name,
        style: const TextStyle(
          color: _ink,
          fontSize: 32,
          letterSpacing: -0.8,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        restaurant.description,
        style: const TextStyle(color: _muted, fontSize: 15, height: 1.4),
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: <Widget>[
            _StoreStat(
              icon: Icons.timer_outlined,
              label: '${restaurant.deliveryMinutes} min',
            ),
            _StoreStat(
              icon: Icons.delivery_dining,
              label: formatPrice(restaurant.deliveryFee),
            ),
            const _StoreStat(
                icon: Icons.thumb_up_alt_outlined, label: 'Top pick'),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFE7F8C9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.local_offer_outlined, color: _ink),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Free delivery unlocks automatically on orders over \$25.',
                style: TextStyle(
                  color: _ink,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 30),
      const Text(
        'Popular picks',
        style: TextStyle(
          color: _ink,
          fontSize: 23,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 5),
      const Text(
        'Tap for details or add straight to your basket.',
        style: TextStyle(color: _muted, fontSize: 13),
      ),
      const SizedBox(height: 14),
    ];

    for (final FoodItem item in restaurant.menu) {
      content.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _MenuItemCard(
          item: item,
          onTap: () => _openItem(context, item),
          onAdd: () => _quickAdd(context, item),
        ),
      ));
    }
    return content;
  }
}

class _StoreStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StoreStat({Key key, this.icon, this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: _accent, size: 18),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final FoodItem item;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _MenuItemCard({Key key, this.item, this.onTap, this.onAdd})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        key: Key('menu-${item.id}'),
        borderRadius: BorderRadius.circular(19),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: <Widget>[
              Hero(
                tag: 'food-${item.id}',
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0ECE2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CatalogImage(
                      imagePath: item.imagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.badge.toUpperCase(),
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 10,
                        letterSpacing: 0.7,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      formatPrice(item.price),
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: _ink,
                shape: const CircleBorder(),
                child: IconButton(
                  key: Key('quick-add-${item.id}'),
                  icon: const Icon(Icons.add),
                  color: _lime,
                  tooltip: 'Add ${item.name}',
                  onPressed: onAdd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
