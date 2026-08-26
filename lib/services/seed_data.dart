import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/product.dart';
import 'db_helper.dart';

/// Utilities to seed initial products data from assets into the local database.
class SeedData {
  /// Read assets/products.json and return parsed Product list.
  static Future<List<Product>> loadProductsFromAssets() async {
    final raw = await rootBundle.loadString('assets/products.json');
    final List<dynamic> data = json.decode(raw) as List<dynamic>;
    final List<Product> out = [];
    for (final e in data) {
      out.add(Product.fromJson(e as Map<String, dynamic>));
    }
    return out;
  }

  /// Ensure products table is seeded. If the products table is empty, this
  /// reads products.json and inserts all products into the DB.
  static Future<void> ensureSeeded() async {
    final dbProducts = await DBHelper.getProducts();
    if (dbProducts.isNotEmpty) return;

    final products = await loadProductsFromAssets();
    final batch = products.map((p) => p.toJson()).toList();
    await DBHelper.insertProductsBatch(batch);
  }
}
