import '../db/database.dart';
import '../models/models.dart';

class AppRepository {
  // ── MEMBERS ───────────────────────────────────────────────

  Future<List<Member>> getMembers() async {
    final rows = await AppDatabase.getMembers();
    return rows.map(Member.fromMap).toList();
  }

  Future<Member> addMember(String name, String emoji, int colorValue) async {
    final id = await AppDatabase.insertMember({
      'name': name,
      'emoji': emoji,
      'color': colorValue,
    });
    return Member(id: id, name: name, emoji: emoji);
  }

  Future<void> updateMember(Member member) async {
    await AppDatabase.updateMember(member.id, member.toMap());
  }

  Future<void> deleteMember(int id) async {
    await AppDatabase.deleteMember(id);
  }

  // ── MEALS ─────────────────────────────────────────────────

  Future<List<Meal>> getMeals({bool? settled}) async {
    final mealRows = await AppDatabase.getMeals(settled: settled);
    final meals = <Meal>[];

    for (final row in mealRows) {
      final mealId = row['id'] as int;
      final memberIds = await AppDatabase.getMealMemberIds(mealId);
      final allMemberRows = await AppDatabase.getMembers();
      final members = allMemberRows
          .map(Member.fromMap)
          .where((m) => memberIds.contains(m.id))
          .toList();
      final orderItemRows = await AppDatabase.getOrderItems(mealId);
      final orderItems = orderItemRows.map(OrderItem.fromMap).toList();
      meals.add(Meal.fromMap(row, members: members, orderItems: orderItems));
    }

    return meals;
  }

  Future<Meal?> getMealById(int id) async {
    final row = await AppDatabase.getMealById(id);
    if (row == null) return null;

    final memberIds = await AppDatabase.getMealMemberIds(id);
    final allMemberRows = await AppDatabase.getMembers();
    final members = allMemberRows
        .map(Member.fromMap)
        .where((m) => memberIds.contains(m.id))
        .toList();
    final orderItemRows = await AppDatabase.getOrderItems(id);
    final orderItems = orderItemRows.map(OrderItem.fromMap).toList();

    return Meal.fromMap(row, members: members, orderItems: orderItems);
  }

  Future<int> saveMeal(
    Meal meal,
    List<int> memberIds,
    List<OrderItem> orderItems,
  ) async {
    final mealId = await AppDatabase.insertMeal(meal.toMap());
    await AppDatabase.setMealMembers(mealId, memberIds);
    await AppDatabase.deleteOrderItemsForMeal(mealId);
    for (final item in orderItems) {
      await AppDatabase.insertOrderItem(item.toMap()..['meal_id'] = mealId);
    }
    return mealId;
  }

  Future<void> updateMealPhoto(int mealId, String? photoPath) async {
    await AppDatabase.updateMeal(mealId, {'photo_path': photoPath});
  }

  Future<void> markMealsSettled(List<int> mealIds) async {
    await AppDatabase.markMealsSettled(mealIds);
  }

  // ── ORDER ITEMS ───────────────────────────────────────────

  Future<void> deleteOrderItem(int id) async {
    await AppDatabase.deleteOrderItem(id);
  }

  // ── MANUAL DEBTS ──────────────────────────────────────────

  Future<void> addManualDebt({
    required int debtorId,
    required int creditorId,
    required int amount,
    required String description,
  }) async {
    await AppDatabase.insertManualDebt({
      'debtor_id': debtorId,
      'creditor_id': creditorId,
      'amount': amount,
      'description': description,
      'date_millis': DateTime.now().millisecondsSinceEpoch,
      'is_settled': 0,
    });
  }

  // ── SETTLEMENTS ───────────────────────────────────────────

  Future<void> confirmSettlement(String summaryJson) async {
    await AppDatabase.insertSettlement({
      'date_millis': DateTime.now().millisecondsSinceEpoch,
      'summary_json': summaryJson,
    });
    final unsettled = await getMeals(settled: false);
    final ids = unsettled.map((m) => m.id!).toList();
    if (ids.isNotEmpty) await markMealsSettled(ids);
    await AppDatabase.markManualDebtsSettled();
  }

  Future<List<Map<String, dynamic>>> getSettlementHistory() async {
    return AppDatabase.getSettlements();
  }
}
