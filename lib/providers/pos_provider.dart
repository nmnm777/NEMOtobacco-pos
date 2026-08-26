import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/cart_item.dart';

class PosProvider extends ChangeNotifier {
  // initial demo products - in future load from JSON or API
  final List<Product> _products = [
    Product(id: 'p1', name: 'Classic Cigarette Pack', category: 'Cigarettes', price: 5.0, barcode: '10001'),
    Product(id: 'p2', name: 'Premium Cigarette Pack', category: 'Cigarettes', price: 7.5, barcode: '10002'),
    Product(id: 'p3', name: 'Shisha Mix 50g', category: 'Shisha / Molasses', price: 12.0, barcode: '20001'),
    Product(id: 'p4', name: 'Hookah Coals (box)', category: 'Shisha / Molasses', price: 4.0, barcode: '20002'),
    Product(id: 'p5', name: 'Vape Pod', category: 'Vapes', price: 15.0, barcode: '30001'),
    Product(id: 'p6', name: 'Vape Liquid 30ml', category: 'Vapes', price: 9.99, barcode: '30002'),
    Product(id: 'p7', name: 'Lighter', category: 'Accessories', price: 1.5, barcode: '40001'),
    Product(id: 'p8', name: 'Rolling Papers', category: 'Accessories', price: 2.0, barcode: '40002'),
  ];

  String _selectedCategory = 'All';
  final Map<String, CartItem> _cart = {};

  List<Product> get products => List.unmodifiable(_products);
  String get selectedCategory => _selectedCategory;
  Map<String, CartItem> get cart => _cart;

  List<Product> filteredProducts() {
    if (_selectedCategory == 'All') return products;
    return products.where((p) => p.category == _selectedCategory).toList(growable: false);
  }

  void setCategory(String c) {
    _selectedCategory = c;
    notifyListeners();
  }

  void addToCart(Product p, {int qty = 1}) {
    if (_cart.containsKey(p.id)) {
      _cart[p.id]!.qty += qty;
    } else {
      _cart[p.id] = CartItem(product: p, qty: qty);
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cart.remove(productId);
    notifyListeners();
  }

  void changeQty(String productId, int delta) {
    final item = _cart[productId];
    if (item == null) return;
    item.qty += delta;
    if (item.qty <= 0) _cart.remove(productId);
    notifyListeners();
  }

  double get totalPrice => _cart.values.fold(0.0, (s, it) => s + it.total);

  Product? findByBarcode(String code) {
    return _products.firstWhereOrNull((p) => p.barcode.trim() == code.trim());
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }
}

// small extension locally to avoid collection package dependency
extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
