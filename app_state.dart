import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';
import './repository.dart';
import '../../utils/debt_calculator.dart';

class AppState extends ChangeNotifier {
  final AppRepository _repo = AppRepository();

  // ── State ─────────────────────────────────────────────────
  List<Member> members = [];
  List<Meal> meals = [];
  List<Meal> unsettledMeals = [];
  List<MemberBalance> balances = [];
  SettlementResult? settlementResult;

  bool isLoading = false;

  // Thủ quỹ = member đầu tiên (có thể đổi trong Settings)
  int get payerId => members.isNotEmpty ? members.first.id : 1;

  // ── Init ──────────────────────────────────────────────────

  Future<void> init() async {
    isLoading = true;
    notifyListeners();
    await _loadAll();
    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadAll() async {
    members = await _repo.getMembers();
    meals = await _repo.getMeals();
    unsettledMeals = meals.where((m) => !m.isSettled).toList();
    _recalculate();
  }

  void _recalculate() {
    if (members.isEmpty) return;
    balances = DebtCalculator.calculateBalances(unsettledMeals, payerId);
    final transactions = DebtCalculator.calculateSettlement(balances);
    final totalDebt = balances
        .where((b) => b.balance < 0)
        .fold(0, (sum, b) => sum + (-b.balance));
    settlementResult = SettlementResult(
      transactions: transactions,
      balances: balances,
      totalDebt: totalDebt,
    );
  }

  // ── MEMBERS ───────────────────────────────────────────────

  Future<void> addMember(String name, String emoji, Color color) async {
    await _repo.addMember(name, emoji, color.value);
    await _loadAll();
    notifyListeners();
  }

  Future<void> updateMember(Member member) async {
    await _repo.updateMember(member);
    await _loadAll();
    notifyListeners();
  }

  Future<void> deleteMember(int id) async {
    await _repo.deleteMember(id);
    await _loadAll();
    notifyListeners();
  }

  // ── MEALS ─────────────────────────────────────────────────

  Future<int> addMeal({
    required String name,
    required String location,
    required DateTime date,
    required int totalAmount,
    required int payerId,
    required List<int> memberIds,
    required List<OrderItem> orderItems,
    String? notes,
  }) async {
    final meal = Meal(
      name: name,
      location: location,
      date: date,
      totalAmount: totalAmount,
      payerId: payerId,
      notes: notes,
    );
    final id = await _repo.saveMeal(meal, memberIds, orderItems);
    await _loadAll();
    notifyListeners();
    return id;
  }

  Future<void> updateMealPhoto(int mealId, String? photoPath) async {
    await _repo.updateMealPhoto(mealId, photoPath);
    await _loadAll();
    notifyListeners();
  }

  Future<Meal?> getMealById(int id) => _repo.getMealById(id);

  // ── MANUAL DEBTS ──────────────────────────────────────────

  Future<void> addManualDebt({
    required int debtorId,
    required int creditorId,
    required int amount,
    required String description,
  }) async {
    await _repo.addManualDebt(
      debtorId: debtorId,
      creditorId: creditorId,
      amount: amount,
      description: description,
    );
    await _loadAll();
    notifyListeners();
  }

  // ── SETTLEMENT ────────────────────────────────────────────

  Future<void> confirmSettlement() async {
    if (settlementResult == null) return;
    final json = _buildSnapshotJson(settlementResult!);
    await _repo.confirmSettlement(json);
    await _loadAll();
    notifyListeners();
  }

  String _buildSnapshotJson(SettlementResult result) {
    return jsonEncode({
      'date': result.date.toIso8601String(),
      'totalDebt': result.totalDebt,
      'transactions': result.transactions
          .map((t) => {'from': t.from.name, 'to': t.to.name, 'amount': t.amount})
          .toList(),
      'balances': result.balances
          .map((b) => {
                'member': b.member.name,
                'balance': b.balance,
                'meals': b.mealBreakdown
                    .map((md) => {'meal': md.mealName, 'amount': md.amount})
                    .toList(),
              })
          .toList(),
    });
  }

  // ── HELPERS ───────────────────────────────────────────────

  int get totalDebt => settlementResult?.totalDebt ?? 0;
  int get unsettledCount => unsettledMeals.length;
  int get memberCount => members.length;
}
