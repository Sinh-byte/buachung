import 'dart:ui';

// ─────────────────────────────────────────────
//  MEMBER
// ─────────────────────────────────────────────

class Member {
  final int id;
  final String name;
  final String emoji;
  final Color color;

  const Member({
    required this.id,
    required this.name,
    this.emoji = '👤',
    this.color = const Color(0xFF888899),
  });

  factory Member.fromMap(Map<String, dynamic> m) => Member(
        id: m['id'] as int,
        name: m['name'] as String,
        emoji: m['emoji'] as String? ?? '👤',
        color: Color(m['color'] as int? ?? 0xFF888899),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'emoji': emoji,
        'color': color.value,
      };

  Member copyWith({String? name, String? emoji, Color? color}) => Member(
        id: id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        color: color ?? this.color,
      );
}

// ─────────────────────────────────────────────
//  ORDER ITEM
// ─────────────────────────────────────────────

class OrderItem {
  final int? id;
  final int mealId;
  final int memberId;
  final String itemName;
  final int extraAmount; // đồng

  const OrderItem({
    this.id,
    required this.mealId,
    required this.memberId,
    required this.itemName,
    required this.extraAmount,
  });

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        id: m['id'] as int?,
        mealId: m['meal_id'] as int,
        memberId: m['member_id'] as int,
        itemName: m['item_name'] as String,
        extraAmount: m['extra_amount'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'meal_id': mealId,
        'member_id': memberId,
        'item_name': itemName,
        'extra_amount': extraAmount,
      };
}

// ─────────────────────────────────────────────
//  MEAL
// ─────────────────────────────────────────────

class Meal {
  final int? id;
  final String name;
  final String location;
  final DateTime date;
  final int totalAmount;
  final String? photoPath;
  final bool isSettled;
  final String? notes;
  final int payerId;
  final List<Member> members;
  final List<OrderItem> orderItems;

  const Meal({
    this.id,
    required this.name,
    required this.location,
    required this.date,
    required this.totalAmount,
    this.photoPath,
    this.isSettled = false,
    this.notes,
    required this.payerId,
    this.members = const [],
    this.orderItems = const [],
  });

  factory Meal.fromMap(Map<String, dynamic> m, {
    List<Member> members = const [],
    List<OrderItem> orderItems = const [],
  }) =>
      Meal(
        id: m['id'] as int?,
        name: m['name'] as String,
        location: m['location'] as String? ?? '',
        date: DateTime.fromMillisecondsSinceEpoch(m['date_millis'] as int),
        totalAmount: m['total_amount'] as int,
        photoPath: m['photo_path'] as String?,
        isSettled: (m['is_settled'] as int) == 1,
        notes: m['notes'] as String?,
        payerId: m['payer_id'] as int,
        members: members,
        orderItems: orderItems,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'location': location,
        'date_millis': date.millisecondsSinceEpoch,
        'total_amount': totalAmount,
        'photo_path': photoPath,
        'is_settled': isSettled ? 1 : 0,
        'notes': notes,
        'payer_id': payerId,
      };
}

// ─────────────────────────────────────────────
//  DEBT MODELS
// ─────────────────────────────────────────────

class MealDebt {
  final int mealId;
  final String mealName;
  final DateTime mealDate;
  final int amount;

  const MealDebt({
    required this.mealId,
    required this.mealName,
    required this.mealDate,
    required this.amount,
  });
}

class MemberBalance {
  final Member member;
  final int balance; // + = được trả, - = nợ
  final List<MealDebt> mealBreakdown;

  const MemberBalance({
    required this.member,
    required this.balance,
    required this.mealBreakdown,
  });
}

class SettleTransaction {
  final Member from;
  final Member to;
  final int amount;

  const SettleTransaction({
    required this.from,
    required this.to,
    required this.amount,
  });
}

class SettlementResult {
  final List<SettleTransaction> transactions;
  final List<MemberBalance> balances;
  final int totalDebt;
  final DateTime date;

  SettlementResult({
    required this.transactions,
    required this.balances,
    required this.totalDebt,
    DateTime? date,
  }) : date = date ?? DateTime.now();
}
