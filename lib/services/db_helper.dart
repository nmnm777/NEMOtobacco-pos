import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  static Future<Database> initDB() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'tobacco_pos.db');

    return await openDatabase(path, version: 2, onCreate: (db, version) async {
      // products table with optional Arabic name
      await db.execute('''
        CREATE TABLE products(
          id TEXT PRIMARY KEY,
          name TEXT,
          name_ar TEXT,
          category TEXT,
          price REAL,
          barcode TEXT,
          stock INTEGER
        )
      ''');

      // sales table: each row is an item in a sale; sale_group groups items into a transaction
      await db.execute('''
        CREATE TABLE sales(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sale_group TEXT,
          productId TEXT,
          qty INTEGER,
          total REAL,
          date TEXT
        )
      ''');
    }, onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        try {
          await db.execute('ALTER TABLE products ADD COLUMN name_ar TEXT');
        } catch (e) {
          // ignore - column may already exist
        }
      }
    });
  }

  // Products
  static Future<void> insertProductsBatch(List<Map<String, dynamic>> products) async {
    final db = await database;
    final batch = db.batch();
    for (final p in products) {
      batch.insert('products', p, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    return await db.query('products');
  }

  static Future<void> updateProductStock(String id, int newStock) async {
    final db = await database;
    await db.update('products', {'stock': newStock}, where: 'id = ?', whereArgs: [id]);
  }

  // Sales
  static Future<void> insertSaleItems(String saleGroup, List<Map<String, dynamic>> items) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    for (final it in items) {
      final row = {
        'sale_group': saleGroup,
        'productId': it['productId'],
        'qty': it['qty'],
        'total': it['total'],
        'date': now,
      };
      batch.insert('sales', row);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getSales() async {
    final db = await database;
    return await db.query('sales', orderBy: 'date DESC');
  }
}
