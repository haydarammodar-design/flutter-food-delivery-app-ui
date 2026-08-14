import 'package:flutter/material.dart';
import 'package:flutter_app/models/catalog.dart';
import 'package:flutter_app/pages/FoodOrderPage.dart';
import 'package:flutter_app/state/cart_store.dart';
import 'package:flutter_app/widgets/CartButton.dart';
import 'package:flutter_app/widgets/catalog_image.dart';

const Color _ink = Color(0xFF1F2A24);
const Color _muted = Color(0xFF6F766F);
const Color _accent = Color(0xFFE6663F);

class FoodDetailsPage extends StatefulWidget {
  final Restaurant restaurant;
  final FoodItem item;
  final CartStore cart;

  const FoodDetailsPage({
    Key key,
    @required this.restaurant,
    @required this.item,
    @required this.cart,
  }) : super(key: key);

  @override
  _FoodDetailsPageState createState() => _FoodDetailsPageState();
}

class _FoodDetailsPageState extends State<FoodDetailsPage> {
  int _quantity = 1;

  void _openCart() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) => FoodOrderPage(cart: widget.cart),
    ));
  }

  Future<void> _addToCart() async {
    final bool added =
        widget.cart.addItem(widget.restaurant, widget.item, _quantity);

    if (!added) {
      final bool replace = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Start a new basket?'),
            content: Text(
              'Your basket has items from ${widget.cart.restaurant.name}. '
              'A basket can only contain items from one kitchen.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep current'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(primary: _accent),
                child: const Text('Replace basket'),
              ),
            ],
          );
        },
      );

      if (replace != true) {
        return;
      }
      widget.cart.replaceWith(widget.restaurant, widget.item, _quantity);
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${widget.item.name} added to your basket.'),
      action: SnackBarAction(label: 'VIEW CART', onPressed: _openCart),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5F0),
        elevation: 0,
        iconTheme: const IconThemeData(color: _ink),
        actions: <Widget>[
          CartButton(cart: widget.cart, onPressed: _openCart),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: <Widget>[
          Hero(
            tag: 'food-${widget.item.id}',
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFFF2EEE5),
                borderRadius: BorderRadius.circular(26),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: CatalogImage(
                  imagePath: widget.item.imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            widget.item.badge.toUpperCase(),
            style: const TextStyle(
              color: _accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  widget.item.name,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 29,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatPrice(widget.item.price),
                style: const TextStyle(
                  color: _ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'from ${widget.restaurant.name}',
            style: const TextStyle(color: _muted, fontSize: 14),
          ),
          const SizedBox(height: 18),
          Text(
            widget.item.description,
            style: const TextStyle(color: _muted, fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: <Widget>[
                _DetailMetric(
                  icon: Icons.timer_outlined,
                  label: '${widget.restaurant.deliveryMinutes} min',
                ),
                _DetailMetric(
                  icon: Icons.delivery_dining,
                  label: formatPrice(widget.restaurant.deliveryFee),
                ),
                const _DetailMetric(
                  icon: Icons.eco_outlined,
                  label: 'Fresh',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Kitchen note',
            style: TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'This local demo keeps order data on-device. Payment, inventory, '
            'and live courier updates will connect when the service layer is ready.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.45),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 16,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EEE5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.remove),
                      color: _ink,
                      tooltip: 'Decrease quantity',
                      onPressed: _quantity == 1
                          ? null
                          : () {
                              setState(() {
                                _quantity--;
                              });
                            },
                    ),
                    Text(
                      '$_quantity',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      color: _accent,
                      tooltip: 'Increase quantity',
                      onPressed: () {
                        setState(() {
                          _quantity++;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  key: const Key('add-to-basket'),
                  onPressed: _addToCart,
                  style: ElevatedButton.styleFrom(
                    primary: _accent,
                    onPrimary: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Add $_quantity - ${formatPrice(widget.item.price * _quantity)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailMetric({Key key, this.icon, this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Icon(icon, color: _accent, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
