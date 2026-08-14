import 'package:flutter/material.dart';
import 'package:flutter_app/models/catalog.dart';
import 'package:flutter_app/pages/OrderConfirmationPage.dart';
import 'package:flutter_app/state/cart_store.dart';
import 'package:flutter_app/widgets/catalog_image.dart';

const Color _ink = Color(0xFF172019);
const Color _muted = Color(0xFF687068);
const Color _accent = Color(0xFFE86B47);
const Color _canvas = Color(0xFFF6F5F1);

class FoodOrderPage extends StatelessWidget {
  final CartStore cart;

  const FoodOrderPage({Key key, @required this.cart}) : super(key: key);

  void _placeOrder(BuildContext context) {
    final OrderReceipt receipt = cart.checkout();
    if (receipt == null) {
      return;
    }

    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (BuildContext context) =>
          OrderConfirmationPage(receipt: receipt),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cart,
      builder: (BuildContext context, Widget child) {
        return Scaffold(
          backgroundColor: _canvas,
          appBar: AppBar(
            backgroundColor: const Color(0xFFF7F5F0),
            elevation: 0,
            iconTheme: const IconThemeData(color: _ink),
            title: const Text(
              'Your basket',
              style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
            ),
          ),
          body: cart.isEmpty ? _EmptyBasket() : _BasketContents(cart: cart),
          bottomNavigationBar: cart.isEmpty
              ? null
              : SafeArea(
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
                    child: ElevatedButton(
                      key: const Key('place-order'),
                      onPressed: () => _placeOrder(context),
                      style: ElevatedButton.styleFrom(
                        primary: _accent,
                        onPrimary: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Place order - ${formatPrice(cart.total)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _EmptyBasket extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: Color(0xFFF2EEE5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  color: _accent, size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your basket is waiting.',
              style: TextStyle(
                color: _ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a kitchen and add something that looks good.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Keep browsing',
                style: TextStyle(color: _accent, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BasketContents extends StatelessWidget {
  final CartStore cart;

  const _BasketContents({Key key, this.cart}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Widget> content = <Widget>[
      Text(
        'From ${cart.restaurant.name}',
        style: const TextStyle(
          color: _accent,
          fontSize: 12,
          letterSpacing: 0.9,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 5),
      const Text(
        'Your basket',
        style: TextStyle(
          color: _ink,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'} ready for checkout',
        style: const TextStyle(color: _muted, fontSize: 14),
      ),
      const SizedBox(height: 22),
    ];

    for (final CartLine line in cart.lines) {
      content.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _CartLineCard(line: line, cart: cart),
      ));
    }

    content.add(const SizedBox(height: 12));
    content.add(const _CheckoutDetails());
    content.add(const SizedBox(height: 16));
    content.add(_PriceBreakdown(cart: cart));
    content.add(const SizedBox(height: 16));
    content.add(Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4EF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.verified_user_outlined, color: _ink),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your restaurant total is confirmed before the order is sent.',
              style: TextStyle(color: _ink, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    ));
    content.add(const SizedBox(height: 110));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: content,
    );
  }
}

class _CheckoutDetails extends StatelessWidget {
  const _CheckoutDetails({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: <Widget>[
          _CheckoutDetailRow(
            icon: Icons.location_on_outlined,
            label: 'Deliver to',
            value: 'Central District',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          _CheckoutDetailRow(
            icon: Icons.payment,
            label: 'Payment',
            value: 'Cash on delivery',
          ),
        ],
      ),
    );
  }
}

class _CheckoutDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CheckoutDetailRow({Key key, this.icon, this.label, this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFF0ECE2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _ink, size: 19),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: _muted,
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: _muted),
      ],
    );
  }
}

class _CartLineCard extends StatelessWidget {
  final CartLine line;
  final CartStore cart;

  const _CartLineCard({Key key, this.line, this.cart}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: const Color(0xFFF2EEE5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CatalogImage(
                imagePath: line.item.imagePath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  line.item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatPrice(line.item.price),
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    _QuantityControl(
                      icon: Icons.remove,
                      tooltip: 'Decrease ${line.item.name}',
                      onPressed: () => cart.decrease(line.item.id),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      child: Text(
                        '${line.quantity}',
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _QuantityControl(
                      icon: Icons.add,
                      tooltip: 'Increase ${line.item.name}',
                      onPressed: () => cart.increase(line.item.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.close),
                color: _muted,
                tooltip: 'Remove ${line.item.name}',
                onPressed: () => cart.remove(line.item.id),
              ),
              const SizedBox(height: 8),
              Text(
                formatPrice(line.total),
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _QuantityControl({Key key, this.icon, this.tooltip, this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Material(
        color: const Color(0xFFF2EEE5),
        borderRadius: BorderRadius.circular(8),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 16),
          tooltip: tooltip,
          color: _ink,
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _PriceBreakdown extends StatelessWidget {
  final CartStore cart;

  const _PriceBreakdown({Key key, this.cart}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: <Widget>[
          _PriceRow(label: 'Subtotal', value: formatPrice(cart.subtotal)),
          const SizedBox(height: 10),
          _PriceRow(label: 'Delivery', value: formatPrice(cart.deliveryFee)),
          const SizedBox(height: 10),
          _PriceRow(label: 'Service fee', value: formatPrice(cart.serviceFee)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          _PriceRow(
            label: 'Total',
            value: formatPrice(cart.total),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _PriceRow({
    Key key,
    this.label,
    this.value,
    this.emphasized = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextStyle style = TextStyle(
      color: _ink,
      fontSize: emphasized ? 17 : 14,
      fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
