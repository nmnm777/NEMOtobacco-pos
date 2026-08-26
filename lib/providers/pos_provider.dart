import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/sale.dart';
import '../models/transaction.dart';
import '../services/db_helper.dart';
import '../services/seed_data.dart';

class PosProvider extends ChangeNotifier {
  final List<Product> _products = [];
  final List<Sale> _sales = [];

  String _selectedCategory = 'All';
  final Map<String, CartItem> _cart = {};

  PosProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      await DBHelper.database;
      final dbProducts = await DBHelper.getProducts();
      if (dbProducts.isEmpty) {
        try {
          await SeedData.ensureSeeded();
        } catch (e) {
          debugPrint('SeedData failed: $e');
          await _loadProductsFromAssets();
          await DBHelper.insertProductsBatch(_products.map((p) => p.toJson()).toList());
        }
      }
      await _reloadProductsFromDb();

      final dbSales = await DBHelper.getSales();
      if (dbSales.isEmpty) {
        await _loadSalesFromAssets();
        if (_sales.isNotEmpty) {
          final saleGroup = DateTime.now().millisecondsSinceEpoch.toString();
          final items = _sales
              .map((s) => {'productId': s.productId, 'qty': s.qty, 'total': s.total})
              .toList();
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

  Future<void> _reloadProductsFromDb() async {
    final dbProducts = await DBHelper.getProducts();
    _products.clear();
    for (final row in dbProducts) {
      _products.add(Product.fromJson({
        'id': row['id'],
        'name': row['name'],
        'name_ar': row['name_ar'],
        'nameAr': row['name_ar'],
        'category': row['category'],
        'price': row['price'],
        'barcode': row['barcode'],
        'stock': row['stock'],
      }));
    }
  }

  Future<void> _loadProductsFromAssets() async {
    try {
      final raw = await rootBundle.loadString('assets/seed_data.json');
      final Map<String, dynamic> jsonData = json.decode(raw) as Map<String, dynamic>;
      final data = jsonData['products'] as List<dynamic>? ?? const [];
      _products.clear();
      for (final e in data) {
        _products.add(Product.fromJson(e as Map<String, dynamic>));
      }
      notifyListeners();
    } on FlutterError catch (_) {
      final raw = await rootBundle.loadString('assets/products.json');
      final List<dynamic> data = json.decode(raw) as List<dynamic>;
      _products.clear();
      for (final e in data) {
        _products.add(Product.fromJson(e as Map<String, dynamic>));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load products seed: $e');
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
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load sales.json: $e');
    }
  }

  List<Product> get products => List.unmodifiable(_products);
  String get selectedCategory => _selectedCategory;
  Map<String, CartItem> get cart => _cart;
  List<Sale> get sales => List.unmodifiable(_sales);
  List<String> get categories => ['All', ..._products.map((p) => p.category).toSet().toList()..sort()];

  List<TransactionSummary> getTransactions() {
    final Map<String, List<Sale>> groups = {};
    for (final s in _sales) {
      groups.putIfAbsent(s.saleGroup, () => []).add(s);
    }
    final List<TransactionSummary> out = [];
    groups.forEach((group, items) {
      final total = items.fold(0.0, (t, it) => t + it.total);
      final date = items.isNotEmpty ? items.first.date : DateTime.now();
      out.add(TransactionSummary(saleGroup: group, date: date, total: total, items: items));
    });
    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Product? findByBarcode(String code) {
    return _products.firstWhereOrNull((p) => p.barcode.trim() == code.trim());
  }

  List<Product> filteredProducts() {
    if (_selectedCategory == 'All') return products;
    return products.where((p) => p.category == _selectedCategory).toList(growable: false);
  }

  void setCategory(String c) {
    _selectedCategory = c;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    final trimmed = product.copyWith(
      id: product.id.trim(),
      name: product.name.trim(),
      category: product.category.trim(),
      barcode: product.barcode.trim(),
      nameAr: product.nameAr?.trim(),
    );
    if (trimmed.id.isEmpty || trimmed.name.isEmpty || trimmed.barcode.isEmpty) {
      throw ArgumentError('يجب إدخال اسم ورمز باركود للمنتج');
    }
    final existing = _products.any((p) => p.id == trimmed.id || p.barcode == trimmed.barcode);
    if (existing) {
      throw ArgumentError('معرف أو باركود المنتج موجود بالفعل');
    }
    await DBHelper.insertProduct(trimmed.toJson());
    _products.add(trimmed);
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    final trimmed = product.copyWith(
      id: product.id.trim(),
      name: product.name.trim(),
      category: product.category.trim(),
      barcode: product.barcode.trim(),
      nameAr: product.nameAr?.trim(),
    );
    final idx = _products.indexWhere((p) => p.id == trimmed.id);
    if (idx == -1) {
      throw ArgumentError('المنتج غير موجود');
    }
    await DBHelper.updateProduct(trimmed.toJson());
    _products[idx] = trimmed;
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    await DBHelper.deleteProduct(id);
    _products.removeWhere((p) => p.id == id);
    _cart.remove(id);
    notifyListeners();
  }

  Future<void> adjustStock(String id, int delta) async {
    final product = getProductById(id);
    if (product == null) return;
    final nextStock = (product.stock + delta).clamp(0, 999999);
    await DBHelper.updateProductStock(id, nextStock);
    final idx = _products.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _products[idx] = _products[idx].copyWith(stock: nextStock);
      notifyListeners();
    }
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

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  Map<String, int> checkCartAvailability() {
    final shortages = <String, int>{};
    for (final ci in _cart.values) {
      final product = _products.firstWhere((p) => p.id == ci.product.id);
      if (ci.qty > product.stock) {
        shortages[product.id] = ci.qty - product.stock;
      }
    }
    return shortages;
  }

  Future<void> checkout() async {
    if (_cart.isEmpty) return;

    final saleGroup = DateTime.now().millisecondsSinceEpoch.toString();
    final items = <Map<String, dynamic>>[];
    for (final ci in _cart.values) {
      items.add({'productId': ci.product.id, 'qty': ci.qty, 'total': ci.total});
      final productIndex = _products.indexWhere((p) => p.id == ci.product.id);
      if (productIndex != -1) {
        final current = _products[productIndex];
        final newStock = (current.stock - ci.qty).clamp(0, 1 << 31);
        _products[productIndex] = current.copyWith(stock: newStock);
        await DBHelper.updateProductStock(current.id, newStock);
      }
    }

    await DBHelper.insertSaleItems(saleGroup, items);

    final now = DateTime.now();
    for (final it in items) {
      _sales.add(Sale(
        saleGroup: saleGroup,
        productId: it['productId'] as String,
        qty: it['qty'] as int,
        total: (it['total'] as num).toDouble(),
        date: now,
      ));
    }

    _cart.clear();
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    try {
      await DBHelper.clearAllData();
      await SeedData.ensureSeeded();
      await _reloadProductsFromDb();

      final dbSales = await DBHelper.getSales();
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

      notifyListeners();
    } catch (e) {
      debugPrint('resetToDefaults error: $e');
      rethrow;
    }
  }

  int get totalProducts => _products.length;
  int get totalCategories => _products.map((p) => p.category).toSet().length;
  double get salesTotal => _sales.fold(0.0, (s, it) => s + it.total);
  int get ordersCount => _sales.map((s) => s.saleGroup).toSet().length;
  List<Product> get lowStockProducts => _products.where((p) => p.stock <= 50).toList(growable: false);

  List<Sale> salesBetween(DateTime start, DateTime end) =>
      _sales.where((s) => s.date.isAfter(start) && s.date.isBefore(end)).toList(growable: false);
}

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
