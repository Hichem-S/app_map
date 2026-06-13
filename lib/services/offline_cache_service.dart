import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// On web: falls back to SharedPreferences (no sqflite).
/// On mobile/desktop: uses SQLite for proper offline storage.
class OfflineCacheService {
  static Database? _db;

  // ── SQLite (mobile) ──────────────────────────────────────────────────────────

  static Future<Database> get _database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, 'inventory_cache.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE products_cache (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            cached_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  static Future<void> cacheProducts(List<dynamic> products) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('products_cache', jsonEncode(products));
      await prefs.setString('products_last_sync', DateTime.now().toIso8601String());
      return;
    }
    final db = await _database;
    final batch = db.batch();
    for (final item in products) {
      batch.insert('products_cache', {
        'id': item['id'] as String,
        'data': jsonEncode(item),
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    await db.insert(
      'meta',
      {'key': 'products_last_sync', 'value': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getCachedProducts() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('products_cache');
      if (raw == null) return [];
      return (jsonDecode(raw) as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }
    final db = await _database;
    final rows = await db.query('products_cache', orderBy: 'cached_at DESC');
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  static Future<String?> getLastSync() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('products_last_sync');
    }
    final db = await _database;
    final rows = await db.query('meta',
        where: 'key = ?', whereArgs: ['products_last_sync']);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  static Future<void> clearProducts() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('products_cache');
      return;
    }
    final db = await _database;
    await db.delete('products_cache');
  }
}
