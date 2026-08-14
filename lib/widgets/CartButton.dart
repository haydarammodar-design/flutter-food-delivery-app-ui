import 'package:flutter/material.dart';
import 'package:flutter_app/state/cart_store.dart';

class CartButton extends StatelessWidget {
  final CartStore cart;
  final VoidCallback onPressed;

  const CartButton({Key key, @required this.cart, @required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cart,
      builder: (BuildContext context, Widget child) {
        return Stack(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined),
              tooltip: 'Open cart',
              color: const Color(0xFF1F2A24),
              onPressed: onPressed,
            ),
            cart.itemCount > 0
                ? Positioned(
                    top: 5,
                    right: 4,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 17, minHeight: 17),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE6663F),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${cart.itemCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        );
      },
    );
  }
}
