import 'package:flutter/foundation.dart';

import '../models/product.dart';

class CartItem {
  final Product product;
  int qty;

  CartItem(this.product, [this.qty = 1]);

  double get lineTotal => product.price * qty;
}

/// Shopping cart shared across the app through Provider.
class Cart extends ChangeNotifier {
  static const double shippingFlatRate = 10;
  static const double discountThreshold = 150;
  static const double discountRate = 0.10;

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get count => _items.fold(0, (sum, i) => sum + i.qty);
  bool get hasPhysical => _items.any((i) => !i.product.isDigital);

  double get subtotal => _items.fold(0, (sum, i) => sum + i.lineTotal);

  /// 10% off orders of RM150 or more.
  double get discount =>
      subtotal >= discountThreshold ? subtotal * discountRate : 0;

  /// Flat shipping applies only when the cart contains physical items.
  double get shipping => hasPhysical ? shippingFlatRate : 0;

  double get total => subtotal - discount + shipping;

  void add(Product product, [int qty = 1]) {
    final existing = _items.where((i) => i.product.id == product.id);
    if (existing.isNotEmpty) {
      existing.first.qty += qty;
    } else {
      _items.add(CartItem(product, qty));
    }
    notifyListeners();
  }

  void setQty(String productId, int qty) {
    if (qty <= 0) {
      remove(productId);
      return;
    }
    for (final i in _items) {
      if (i.product.id == productId) i.qty = qty;
    }
    notifyListeners();
  }

  void remove(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
