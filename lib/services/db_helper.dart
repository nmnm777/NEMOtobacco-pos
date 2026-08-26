import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

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

  /// Remove all rows from products and sales tables. Used for resetting to factory defaults.
  static Future<void> clearAllData() async {
    final db = await database;
    // delete sales first because they may reference products
    await db.delete('sales');
    await db.delete('products');
  }

  /// Return the full path to the sqlite database file.
  static Future<String> getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, 'tobacco_pos.db');
  }

  /// Export the sqlite database file to the user's Downloads folder and return the destination path.
  static Future<String> exportDatabaseToDownloads() async {
    final dbPath = await getDatabasePath();
    final src = File(dbPath);
    if (!await src.exists()) throw Exception('Database file not found at $dbPath');

    Directory? downloadsDir;
    try {
      downloadsDir = await getDownloadsDirectory();
    } catch (e) {
      downloadsDir = null;
    }

    final baseDir = downloadsDir ?? await getApplicationDocumentsDirectory();
    final destPath = join(baseDir.path, 'tobacco_pos_backup_${DateTime.now().millisecondsSinceEpoch}.db');
    final dest = File(destPath);
    await src.copy(dest.path);
    return dest.path;
  }
}
