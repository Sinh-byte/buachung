import '../models/models.dart';

class DebtCalculator {
  /// Tính số dư ròng cho từng member
  /// payerId = ID thủ quỹ (người bỏ tiền trước)
  static List<MemberBalance> calculateBalances(
    List<Meal> meals,
    int payerId,
  ) {
    final Map<int, int> balanceMap = {}; // memberId → balance
    final Map<int, List<MealDebt>> breakdownMap = {};
    final Map<int, Member> allMembers = {};

    for (final meal in meals) {
      for (final m in meal.members) {
        allMembers[m.id] = m;
      }
    }

    for (final meal in meals) {
      if (meal.isSettled || meal.members.isEmpty) continue;

      // Tính extra per member
      final Map<int, int> extraMap = {};
      for (final item in meal.orderItems) {
        extraMap[item.memberId] = (extraMap[item.memberId] ?? 0) + item.extraAmount;
      }

      final totalExtra = extraMap.values.fold(0, (a, b) => a + b);
      final baseAmount = (meal.totalAmount - totalExtra) ~/ meal.members.length;

      for (final member in meal.members) {
        final extra = extraMap[member.id] ?? 0;
        final owes = baseAmount + extra;

        if (member.id == payerId) {
          // Thủ quỹ: được trả lại phần của người khác
          final credit = meal.totalAmount - owes;
          balanceMap[member.id] = (balanceMap[member.id] ?? 0) + credit;
        } else {
          // Người khác: nợ phần của họ
          balanceMap[member.id] = (balanceMap[member.id] ?? 0) - owes;
          breakdownMap.putIfAbsent(member.id, () => []).add(
                MealDebt(
                  mealId: meal.id!,
                  mealName: meal.name,
                  mealDate: meal.date,
                  amount: owes,
                ),
              );
        }
      }
    }

    return allMembers.values.map((member) {
      return MemberBalance(
        member: member,
        balance: balanceMap[member.id] ?? 0,
        mealBreakdown: breakdownMap[member.id] ?? [],
      );
    }).toList()
      ..sort((a, b) => a.balance.compareTo(b.balance)); // debtors first
  }

  /// Greedy algorithm – tối thiểu số giao dịch thanh toán
  static List<SettleTransaction> calculateSettlement(
    List<MemberBalance> balances,
  ) {
    final transactions = <SettleTransaction>[];

    // Separate debtors (< 0) và creditors (> 0)
    final debtors = balances
        .where((b) => b.balance < -100)
        .map((b) => _Pair(b.member, -b.balance))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final creditors = balances
        .where((b) => b.balance > 100)
        .map((b) => _Pair(b.member, b.balance))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    while (debtors.isNotEmpty && creditors.isNotEmpty) {
      final debtor = debtors.removeAt(0);
      final creditor = creditors.removeAt(0);

      final amount = debtor.amount < creditor.amount ? debtor.amount : creditor.amount;
      transactions.add(SettleTransaction(
        from: debtor.member,
        to: creditor.member,
        amount: amount,
      ));

      final remainDebt = debtor.amount - amount;
      final remainCredit = creditor.amount - amount;

      if (remainDebt > 100) {
        debtors.insert(0, _Pair(debtor.member, remainDebt));
        debtors.sort((a, b) => b.amount.compareTo(a.amount));
      }
      if (remainCredit > 100) {
        creditors.insert(0, _Pair(creditor.member, remainCredit));
        creditors.sort((a, b) => b.amount.compareTo(a.amount));
      }
    }

    return transactions;
  }

  /// Tính phần ăn của 1 người trong 1 bữa
  static int calculateMemberShare(Meal meal, int memberId) {
    if (meal.members.isEmpty) return 0;

    final Map<int, int> extraMap = {};
    for (final item in meal.orderItems) {
      extraMap[item.memberId] = (extraMap[item.memberId] ?? 0) + item.extraAmount;
    }

    final totalExtra = extraMap.values.fold(0, (a, b) => a + b);
    final baseAmount = (meal.totalAmount - totalExtra) ~/ meal.members.length;
    final extra = extraMap[memberId] ?? 0;

    return baseAmount + extra;
  }
}

class _Pair {
  final Member member;
  final int amount;
  _Pair(this.member, this.amount);
}
