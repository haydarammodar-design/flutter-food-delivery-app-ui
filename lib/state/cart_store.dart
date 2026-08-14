import 'package:flutter/foundation.dart';
import 'package:flutter_app/models/catalog.dart';

class CartLine {
  final FoodItem item;
  final int quantity;

  CartLine({this.item, this.quantity});

  double get total => item.price * quantity;

  CartLine copyWithQuantity(int nextQuantity) {
    return CartLine(item: item, quantity: nextQuantity);
  }
}

class OrderReceipt {
  final String orderNumber;
  final String restaurantName;
  final int itemCount;
  final double total;

  OrderReceipt({
    this.orderNumber,
    this.restaurantName,
    this.itemCount,
    this.total,
  });
}

class CartStore extends ChangeNotifier {
  final Map<String, CartLine> _lines = <String, CartLine>{};
  Restaurant _restaurant;
  OrderReceipt _lastOrder;

  List<CartLine> get lines => _lines.values.toList();
  Restaurant get restaurant => _restaurant;
  OrderReceipt get lastOrder => _lastOrder;
  bool get isEmpty => _lines.isEmpty;
  int get itemCount => _lines.values
      .fold(0, (int total, CartLine line) => total + line.quantity);
  double get subtotal => _lines.values
      .fold(0.0, (double total, CartLine line) => total + line.total);
  double get deliveryFee => isEmpty ? 0.0 : _restaurant.deliveryFee;
  double get serviceFee => isEmpty ? 0.0 : 1.25;
  double get total => subtotal + deliveryFee + serviceFee;

  bool addItem(Restaurant restaurant, FoodItem item, [int quantity = 1]) {
    if (_restaurant != null && _restaurant.id != restaurant.id) {
      return false;
    }

    _restaurant = restaurant;
    _addLine(item, quantity);
    notifyListeners();
    return true;
  }

  void replaceWith(Restaurant restaurant, FoodItem item, [int quantity = 1]) {
    _lines.clear();
    _restaurant = restaurant;
    _addLine(item, quantity);
    notifyListeners();
  }

  void increase(String itemId) {
    final CartLine line = _lines[itemId];
    if (line == null) {
      return;
    }

    _lines[itemId] = line.copyWithQuantity(line.quantity + 1);
    notifyListeners();
  }

  void decrease(String itemId) {
    final CartLine line = _lines[itemId];
    if (line == null) {
      return;
    }

    if (line.quantity == 1) {
      _lines.remove(itemId);
    } else {
      _lines[itemId] = line.copyWithQuantity(line.quantity - 1);
    }

    if (_lines.isEmpty) {
      _restaurant = null;
    }
    notifyListeners();
  }

  void remove(String itemId) {
    _lines.remove(itemId);
    if (_lines.isEmpty) {
      _restaurant = null;
    }
    notifyListeners();
  }

  OrderReceipt checkout() {
    if (isEmpty) {
      return null;
    }

    final OrderReceipt receipt = OrderReceipt(
      orderNumber:
          'DLV-' + (DateTime.now().millisecondsSinceEpoch % 100000).toString(),
      restaurantName: _restaurant.name,
      itemCount: itemCount,
      total: total,
    );
    _lastOrder = receipt;
    _lines.clear();
    _restaurant = null;
    notifyListeners();
    return receipt;
  }

  void _addLine(FoodItem item, int quantity) {
    final int normalizedQuantity = quantity < 1 ? 1 : quantity;
    final CartLine existing = _lines[item.id];
    _lines[item.id] = existing == null
        ? CartLine(item: item, quantity: normalizedQuantity)
        : existing.copyWithQuantity(existing.quantity + normalizedQuantity);
  }
}
