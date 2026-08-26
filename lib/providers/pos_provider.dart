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
    // initialize DB and load data
    _init();
  }

  Future<void> _init() async {
    try {
      // ensure DB is initialized
      await DBHelper.database;
      // load products from DB; if empty load from assets and insert
      final dbProducts = await DBHelper.getProducts();
      if (dbProducts.isEmpty) {
        await _loadProductsFromAssets();
        // persist to DB
        final batch = _products.map((p) => p.toJson()).toList();
        await DBHelper.insertProductsBatch(batch);
      } else {
        _products.clear();
        for (final row in dbProducts) {
          _products.add(Product.fromJson({
            'id': row['id'],
            'name': row['name'],
            'category': row['category'],
            'price': row['price'],
            'barcode': row['barcode'],
            'stock': row['stock'],
          }));
        }
      }

      // load sales from DB; if none, load from assets and optionally persist
      final dbSales = await DBHelper.getSales();
      if (dbSales.isEmpty) {
        await _loadSalesFromAssets();
        // persist asset sales into DB
        if (_sales.isNotEmpty) {
          final saleGroup = DateTime.now().millisecondsSinceEpoch.toString();
          final items = _sales.map((s) => {
                'productId': s.productId,
                'qty': s.qty,
                'total': s.total,
              }).toList();
          await DBHelper.insertSaleItems(saleGroup, items);
        }
      } else {
        _sales.clear();
        for (final row in dbSales) {
          _sales.add(Sale(
            id: row['id'] as int,
            saleGroup: row['sale_group'] as String,
            productId: row['productId'] as String,
            qty: (row['qty'] as num).toInt(),
            total: (row['total'] as num).toDouble(),
            date: DateTime.parse(row['date'] as String),
          ));
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('PosProvider init error: $e');
    }
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
        final s = Sale.fromJson(e as Map<String, dynamic>);
        _sales.add(s);
      }
      // Also persist into DB if not present
      // For simplicity, when DB is empty we will use assets initial load elsewhere
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

  /// Perform checkout: persist sales, update product stocks, clear cart
  Future<void> checkout() async {
    if (_cart.isEmpty) return;
    final saleGroup = DateTime.now().millisecondsSinceEpoch.toString();

    // prepare items and update stocks
    final items = <Map<String, dynamic>>[];
    for (final ci in _cart.values) {
      items.add({
        'productId': ci.product.id,
        'qty': ci.qty,
        'total': ci.total,
      });
      // update local product stock
      final productIndex = _products.indexWhere((p) => p.id == ci.product.id);
      if (productIndex != -1) {
        final current = _products[productIndex];
        final newStock = (current.stock - ci.qty).clamp(0, 1 << 31);
        _products[productIndex] = Product(
          id: current.id,
          name: current.name,
          category: current.category,
          price: current.price,
          barcode: current.barcode,
          stock: newStock,
        );
        // persist stock to DB
        await DBHelper.updateProductStock(current.id, newStock);
      }
    }

    // insert sale items into DB
    await DBHelper.insertSaleItems(saleGroup, items);

    // add to in-memory sales list
    final now = DateTime.now();
    for (final it in items) {
      _sales.add(Sale(saleGroup: saleGroup, productId: it['productId'] as String, qty: it['qty'] as int, total: (it['total'] as num).toDouble(), date: now));
    }

    // clear cart
    _cart.clear();
    notifyListeners();
  }

  // ---- Dashboard helpers ----
  int get totalProducts => _products.length;

  int get totalCategories => _products.map((p) => p.category).toSet().length;

  double get salesTotal => _sales.fold(0.0, (s, it) => s + it.total);

  int get ordersCount => _sales.map((s) => s.saleGroup).toSet().length;

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
