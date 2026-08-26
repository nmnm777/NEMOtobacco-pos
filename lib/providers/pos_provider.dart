import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/sale.dart';

class PosProvider extends ChangeNotifier {
  final List<Product> _products = [];
  final List<Sale> _sales = [];

  String _selectedCategory = 'All';
  final Map<String, CartItem> _cart = {};

  PosProvider() {
    // load assets on construction
    _loadProductsFromAssets();
    _loadSalesFromAssets();
  }

  Future<void> _loadProductsFromAssets() async {
    try {
      final raw = await rootBundle.loadString('assets/products.json');
      final List<dynamic> data = json.decode(raw) as List<dynamic>;
      _products.clear();
      for (final e in data) {
        _products.add(Product.fromJson(e as Map<String, dynamic>));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load products.json: $e');
    }
  }

  Future<void> _loadSalesFromAssets() async {
    try {
      final raw = await rootBundle.loadString('assets/sales.json');
      final List<dynamic> data = json.decode(raw) as List<dynamic>;
      _sales.clear();
      for (final e in data) {
        _sales.add(Sale.fromJson(e as Map<String, dynamic>));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load sales.json: $e');
    }
  }

  List<Product> get products => List.unmodifiable(_products);
  String get selectedCategory => _selectedCategory;
  Map<String, CartItem> get cart => _cart;
  List<Sale> get sales => List.unmodifiable(_sales);

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

  // ---- Dashboard helpers ----
  int get totalProducts => _products.length;

  int get totalCategories => _products.map((p) => p.category).toSet().length;

  double get salesTotal => _sales.fold(0.0, (s, it) => s + it.total);

  int get ordersCount => _sales.length;

  List<Product> get lowStockProducts => _products.where((p) => p.stock <= 50).toList(growable: false);

  // get sales in a date range
  List<Sale> salesBetween(DateTime start, DateTime end) =>
      _sales.where((s) => s.date.isAfter(start) && s.date.isBefore(end)).toList(growable: false);
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
