import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/product.dart';
import 'db_helper.dart';

class SeedData {
  static Future<List<Product>> loadProductsFromAssets() async {
    try {
      final raw = await rootBundle.loadString('assets/seed_data.json');
      final Map<String, dynamic> data = json.decode(raw) as Map<String, dynamic>;
      final items = (data['products'] as List<dynamic>? ?? const []) as List<dynamic>;
      return items.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      final raw = await rootBundle.loadString('assets/products.json');
      final List<dynamic> data = json.decode(raw) as List<dynamic>;
      return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  static Future<void> ensureSeeded() async {
    final dbProducts = await DBHelper.getProducts();
    if (dbProducts.isNotEmpty) return;

    final products = await loadProductsFromAssets();
    await DBHelper.insertProductsBatch(products.map((p) => p.toJson()).toList());
  }
}
