import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get instance async {
    _db ??= await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'buachung.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE members (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            name     TEXT NOT NULL,
            emoji    TEXT NOT NULL DEFAULT '👤',
            color    INTEGER NOT NULL DEFAULT 4284612846
          )
        ''');

        await db.execute('''
          CREATE TABLE meals (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT NOT NULL,
            location    TEXT NOT NULL DEFAULT '',
            date_millis INTEGER NOT NULL,
            total_amount INTEGER NOT NULL DEFAULT 0,
            photo_path  TEXT,
            is_settled  INTEGER NOT NULL DEFAULT 0,
            notes       TEXT,
            payer_id    INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE meal_members (
            meal_id   INTEGER NOT NULL,
            member_id INTEGER NOT NULL,
            PRIMARY KEY (meal_id, member_id)
          )
        ''');

        await db.execute('''
          CREATE TABLE order_items (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            meal_id      INTEGER NOT NULL,
            member_id    INTEGER NOT NULL,
            item_name    TEXT NOT NULL,
            extra_amount INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE manual_debts (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            debtor_id   INTEGER NOT NULL,
            creditor_id INTEGER NOT NULL,
            amount      INTEGER NOT NULL,
            description TEXT NOT NULL,
            date_millis INTEGER NOT NULL,
            is_settled  INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE settlements (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            date_millis INTEGER NOT NULL,
            summary_json TEXT NOT NULL
          )
        ''');

        // Seed dữ liệu mẫu để demo
        await db.insert('members', {'name': 'Tuấn (Thủ quỹ)', 'emoji': '👑', 'color': 0xFFF4C430});
        await db.insert('members', {'name': 'Hùng', 'emoji': '😎', 'color': 0xFF4ECDC4});
        await db.insert('members', {'name': 'Minh', 'emoji': '🤙', 'color': 0xFFFF6B6B});
        await db.insert('members', {'name': 'Nam', 'emoji': '😄', 'color': 0xFF6BCB77});
        await db.insert('members', {'name': 'Linh', 'emoji': '🌸', 'color': 0xFFB07EFF});
      },
    );
  }

  // ── MEMBERS ───────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getMembers() async {
    final db = await instance;
    return db.query('members', orderBy: 'id ASC');
  }

  static Future<int> insertMember(Map<String, dynamic> data) async {
    final db = await instance;
    return db.insert('members', data);
  }

  static Future<void> updateMember(int id, Map<String, dynamic> data) async {
    final db = await instance;
    await db.update('members', data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteMember(int id) async {
    final db = await instance;
    await db.delete('members', where: 'id = ?', whereArgs: [id]);
  }

  // ── MEALS ─────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getMeals({bool? settled}) async {
    final db = await instance;
    String? where;
    List<dynamic>? whereArgs;
    if (settled != null) {
      where = 'is_settled = ?';
      whereArgs = [settled ? 1 : 0];
    }
    return db.query('meals', where: where, whereArgs: whereArgs, orderBy: 'date_millis DESC');
  }

  static Future<Map<String, dynamic>?> getMealById(int id) async {
    final db = await instance;
    final rows = await db.query('meals', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  static Future<int> insertMeal(Map<String, dynamic> data) async {
    final db = await instance;
    return db.insert('meals', data);
  }

  static Future<void> updateMeal(int id, Map<String, dynamic> data) async {
    final db = await instance;
    await db.update('meals', data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> markMealsSettled(List<int> ids) async {
    final db = await instance;
    await db.update(
      'meals',
      {'is_settled': 1},
      where: 'id IN (${ids.map((_) => '?').join(',')})',
      whereArgs: ids,
    );
  }

  // ── MEAL MEMBERS ──────────────────────────────────────────

  static Future<List<int>> getMealMemberIds(int mealId) async {
    final db = await instance;
    final rows = await db.query('meal_members', where: 'meal_id = ?', whereArgs: [mealId]);
    return rows.map((r) => r['member_id'] as int).toList();
  }

  static Future<void> setMealMembers(int mealId, List<int> memberIds) async {
    final db = await instance;
    await db.delete('meal_members', where: 'meal_id = ?', whereArgs: [mealId]);
    for (final mid in memberIds) {
      await db.insert('meal_members', {'meal_id': mealId, 'member_id': mid},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ── ORDER ITEMS ───────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getOrderItems(int mealId) async {
    final db = await instance;
    return db.query('order_items', where: 'meal_id = ?', whereArgs: [mealId]);
  }

  static Future<int> insertOrderItem(Map<String, dynamic> data) async {
    final db = await instance;
    return db.insert('order_items', data);
  }

  static Future<void> deleteOrderItem(int id) async {
    final db = await instance;
    await db.delete('order_items', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteOrderItemsForMeal(int mealId) async {
    final db = await instance;
    await db.delete('order_items', where: 'meal_id = ?', whereArgs: [mealId]);
  }

  // ── MANUAL DEBTS ──────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getUnsettledManualDebts() async {
    final db = await instance;
    return db.query('manual_debts', where: 'is_settled = 0', orderBy: 'date_millis DESC');
  }

  static Future<int> insertManualDebt(Map<String, dynamic> data) async {
    final db = await instance;
    return db.insert('manual_debts', data);
  }

  static Future<void> markManualDebtsSettled() async {
    final db = await instance;
    await db.update('manual_debts', {'is_settled': 1}, where: 'is_settled = 0');
  }

  // ── SETTLEMENTS ───────────────────────────────────────────

  static Future<int> insertSettlement(Map<String, dynamic> data) async {
    final db = await instance;
    return db.insert('settlements', data);
  }

  static Future<List<Map<String, dynamic>>> getSettlements() async {
    final db = await instance;
    return db.query('settlements', orderBy: 'date_millis DESC', limit: 20);
  }
}
