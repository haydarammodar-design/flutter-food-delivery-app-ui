import 'package:flutter/material.dart';
import 'package:flutter_app/models/catalog.dart';
import 'package:flutter_app/state/cart_store.dart';

const Color _ink = Color(0xFF1F2A24);
const Color _muted = Color(0xFF6F766F);
const Color _accent = Color(0xFFE6663F);

class OrderConfirmationPage extends StatelessWidget {
  final OrderReceipt receipt;

  const OrderConfirmationPage({Key key, @required this.receipt})
      : super(key: key);

  void _returnToRestaurants(BuildContext context) {
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F1),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 92,
                    height: 92,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE5F2E7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: Color(0xFF2F8D4E), size: 52),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Order confirmed',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _ink,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your local demo order has been sent to ${receipt.restaurantName}.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: _muted, fontSize: 16, height: 1.45),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: <Widget>[
                        Text(
                          receipt.orderNumber,
                          style: const TextStyle(
                            color: _accent,
                            fontSize: 14,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${receipt.itemCount} item${receipt.itemCount == 1 ? '' : 's'}',
                          style: const TextStyle(color: _muted, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatPrice(receipt.total),
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4EF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'The order timeline will update here when merchant acceptance and courier dispatch are connected.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _ink, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
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
            key: const Key('return-to-restaurants'),
            onPressed: () => _returnToRestaurants(context),
            style: ElevatedButton.styleFrom(
              primary: _accent,
              onPrimary: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Back to restaurants',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}
