// ═══════════════════════════════════════════════════
//  MEAL DETAIL SCREEN
// ═══════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../widgets/theme.dart';
import '../../data/repository/app_state.dart';
import '../../utils/debt_calculator.dart';

class MealDetailScreen extends StatefulWidget {
  final int mealId;
  const MealDetailScreen({super.key, required this.mealId});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  Meal? _meal;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    final meal = await state.getMealById(widget.mealId);
    if (mounted) setState(() => _meal = meal);
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: AppColors.accent),
            title: const Text('Chụp ảnh mới', style: TextStyle(color: AppColors.white)),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: AppColors.teal),
            title: const Text('Chọn từ thư viện', style: TextStyle(color: AppColors.white)),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          if (_meal?.photoPath != null)
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.red),
              title: const Text('Xoá ảnh', style: TextStyle(color: AppColors.red)),
              onTap: () => Navigator.pop(context, null),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
    if (source == null && _meal?.photoPath != null) {
      // delete
      await context.read<AppState>().updateMealPhoto(widget.mealId, null);
      _load();
      return;
    }
    if (source == null) return;
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      await context.read<AppState>().updateMealPhoto(widget.mealId, picked.path);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final meal = _meal;
    if (meal == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // App bar with photo
          SliverAppBar(
            expandedHeight: meal.photoPath != null ? 220 : 80,
            pinned: true,
            backgroundColor: AppColors.bg,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.accent),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.camera_alt, color: AppColors.accent),
                onPressed: _pickPhoto,
                tooltip: meal.photoPath != null ? 'Thay đổi ảnh' : 'Thêm ảnh',
              ),
            ],
            flexibleSpace: meal.photoPath != null
                ? FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(meal.photoPath!), fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, AppColors.bg.withOpacity(0.9)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.white)),
                  const SizedBox(height: 4),
                  Text('📅 ${Fmt.dateFull(meal.date)}  ·  📍 ${meal.location}',
                      style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                  if (meal.notes != null && meal.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('📝 ${meal.notes}', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                  ],
                  const SizedBox(height: 16),

                  // Total card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accent.withOpacity(0.18), AppColors.accent.withOpacity(0.05)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TỔNG HOÁ ĐƠN',
                                  style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w800, letterSpacing: 1)),
                              const SizedBox(height: 2),
                              Text(
                                '${meal.members.length} người · ${Fmt.money(meal.totalAmount ~/ meal.members.length.clamp(1, 999))}/người (base)',
                                style: const TextStyle(fontSize: 12, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        Text(Fmt.money(meal.totalAmount),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                              fontFamily: 'monospace',
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
              child: Text('PHẦN ĂN TỪNG NGƯỜI',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 1.2)),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final member = meal.members[i];
                  final share = DebtCalculator.calculateMemberShare(meal, member.id);
                  final items = meal.orderItems.where((o) => o.memberId == member.id).toList();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PersonOrderTile(member: member, items: items, share: share),
                  );
                },
                childCount: meal.members.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonOrderTile extends StatelessWidget {
  final Member member;
  final List<OrderItem> items;
  final int share;

  const _PersonOrderTile({required this.member, required this.items, required this.share});

  @override
  Widget build(BuildContext context) {
    return BcCard(
      child: Row(
        children: [
          MemberAvatar(member: member, size: 38, showBorder: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.white)),
                Text(
                  items.isEmpty ? 'Chia đều' : items.map((o) => o.itemName).join(', '),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(Fmt.money(share),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
//  MEMBERS SCREEN
// ═══════════════════════════════════════════════════

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          title: RichText(
            text: const TextSpan(children: [
              TextSpan(text: 'Thành ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.white)),
              TextSpan(text: 'Viên', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.accent)),
            ]),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add, color: AppColors.accent),
              onPressed: () => _showAddMemberDialog(context, state),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text('CÔNG NỢ HIỆN TẠI',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 1.2)),
            ),
            ...state.balances.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MemberBalanceCard(balance: b, onEdit: () => _showEditDialog(context, state, b.member)),
                )),
            if (state.balances.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('Chưa có dữ liệu', style: TextStyle(color: AppColors.muted)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, AppState state) {
    final nameCtrl = TextEditingController();
    String emoji = '😊';
    Color color = AppColors.memberColors.first;
    final emojis = ['😊', '😎', '🤙', '😄', '🌸', '👑', '🎯', '🦁', '🐉', '⚡'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, ss) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Thêm thành viên', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(hintText: 'Tên thành viên'), autofocus: true),
          const SizedBox(height: 14),
          Wrap(spacing: 8, children: emojis.map((e) => GestureDetector(
            onTap: () => ss(() => emoji = e),
            child: Container(width: 36, height: 36,
              decoration: BoxDecoration(color: emoji == e ? AppColors.accent.withOpacity(0.2) : AppColors.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: emoji == e ? AppColors.accent : AppColors.border)),
              alignment: Alignment.center, child: Text(e, style: const TextStyle(fontSize: 18))),
          )).toList()),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: AppColors.memberColors.map((c) => GestureDetector(
            onTap: () => ss(() => color = c),
            child: Container(width: 28, height: 28, decoration: BoxDecoration(color: c, shape: BoxShape.circle,
                border: color == c ? Border.all(color: Colors.white, width: 3) : null)),
          )).toList()),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ', style: TextStyle(color: AppColors.muted))),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              await state.addMember(nameCtrl.text.trim(), emoji, color);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Thêm', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
          ),
        ],
      )),
    );
  }

  void _showEditDialog(BuildContext context, AppState state, Member member) {
    final nameCtrl = TextEditingController(text: member.name);
    String emoji = member.emoji;
    Color color = member.color;
    final emojis = ['😊', '😎', '🤙', '😄', '🌸', '👑', '🎯', '🦁', '🐉', '⚡'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, ss) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Sửa thành viên', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(hintText: 'Tên thành viên')),
          const SizedBox(height: 14),
          Wrap(spacing: 8, children: emojis.map((e) => GestureDetector(
            onTap: () => ss(() => emoji = e),
            child: Container(width: 36, height: 36,
              decoration: BoxDecoration(color: emoji == e ? AppColors.accent.withOpacity(0.2) : AppColors.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: emoji == e ? AppColors.accent : AppColors.border)),
              alignment: Alignment.center, child: Text(e, style: const TextStyle(fontSize: 18))),
          )).toList()),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: AppColors.memberColors.map((c) => GestureDetector(
            onTap: () => ss(() => color = c),
            child: Container(width: 28, height: 28, decoration: BoxDecoration(color: c, shape: BoxShape.circle,
                border: color == c ? Border.all(color: Colors.white, width: 3) : null)),
          )).toList()),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () async {
              await state.deleteMember(member.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            icon: const Icon(Icons.delete, color: AppColors.red, size: 16),
            label: const Text('Xoá thành viên', style: TextStyle(color: AppColors.red)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ', style: TextStyle(color: AppColors.muted))),
          ElevatedButton(
            onPressed: () async {
              await state.updateMember(member.copyWith(name: nameCtrl.text.trim(), emoji: emoji, color: color));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Lưu', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
          ),
        ],
      )),
    );
  }
}

class _MemberBalanceCard extends StatelessWidget {
  final MemberBalance balance;
  final VoidCallback onEdit;
  const _MemberBalanceCard({required this.balance, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isCredit = balance.balance >= 0;
    final color = isCredit ? AppColors.green : AppColors.red;
    final sign = isCredit ? '+' : '';

    return BcCard(
      onTap: onEdit,
      child: Row(children: [
        MemberAvatar(member: balance.member, size: 44, showBorder: false),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(balance.member.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.white)),
            Text('${balance.mealBreakdown.length} bữa chưa quyết toán',
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
        Text('$sign${Fmt.money(balance.balance)}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color, fontFamily: 'monospace')),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════
//  SETTLE SCREEN
// ═══════════════════════════════════════════════════

class SettleScreen extends StatefulWidget {
  const SettleScreen({super.key});

  @override
  State<SettleScreen> createState() => _SettleScreenState();
}

class _SettleScreenState extends State<SettleScreen> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    if (_confirmed) return const _SuccessView();

    return Consumer<AppState>(
      builder: (context, state, _) {
        final result = state.settlementResult;

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.bg,
                pinned: true,
                automaticallyImplyLeading: false,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💳 Quyết Toán',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.white)),
                    Text('${result?.transactions.length ?? 0} giao dịch tối ưu',
                        style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              if (result == null || result.transactions.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('🎉', style: TextStyle(fontSize: 56)),
                      SizedBox(height: 16),
                      Text('Không có nợ nào!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.green)),
                    ]),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
                    child: Row(children: [
                      const Text('AI CHUYỂN KHOẢN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 1.2)),
                      const Spacer(),
                      Text('Tổng: ${Fmt.money(result.totalDebt)}',
                          style: const TextStyle(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _TransactionCard(txn: result.transactions[i]),
                      ),
                      childCount: result.transactions.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: () => _confirmDialog(context, state),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('✅  Xác nhận đã quyết toán',
                          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
                    child: Text('CHI TIẾT TỪNG NGƯỜI',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 1.2)),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final b = result.balances[i];
                        if (b.balance >= 0) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _DebtDetailCard(balance: b),
                        );
                      },
                      childCount: result.balances.length,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _confirmDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xác nhận quyết toán?', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800)),
        content: const Text('Tất cả bữa ăn sẽ được đánh dấu đã thanh toán. Lịch sử vẫn được lưu lại.',
            style: TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ', style: TextStyle(color: AppColors.muted))),
          ElevatedButton(
            onPressed: () async {
              await state.confirmSettlement();
              if (context.mounted) {
                Navigator.pop(context);
                setState(() => _confirmed = true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final SettleTransaction txn;
  const _TransactionCard({required this.txn});

  @override
  Widget build(BuildContext context) {
    return BcCard(
      child: Row(children: [
        Column(children: [
          MemberAvatar(member: txn.from, size: 36, showBorder: false),
          const SizedBox(height: 4),
          Text(txn.from.name, style: const TextStyle(fontSize: 11, color: AppColors.white, fontWeight: FontWeight.w700)),
        ]),
        Expanded(
          child: Column(children: [
            const Text('chuyển', style: TextStyle(fontSize: 10, color: AppColors.muted)),
            Text(Fmt.money(txn.amount),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.accent, fontFamily: 'monospace')),
            const Text('→', style: TextStyle(fontSize: 20, color: AppColors.muted)),
          ]),
        ),
        Column(children: [
          MemberAvatar(member: txn.to, size: 36, showBorder: false),
          const SizedBox(height: 4),
          Text(txn.to.name, style: const TextStyle(fontSize: 11, color: AppColors.white, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}

class _DebtDetailCard extends StatelessWidget {
  final MemberBalance balance;
  const _DebtDetailCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return BcCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          MemberAvatar(member: balance.member, size: 28, showBorder: false),
          const SizedBox(width: 8),
          Text(balance.member.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.white)),
          const Spacer(),
          Text(Fmt.money(-balance.balance),
              style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
        ]),
        if (balance.mealBreakdown.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),
          ...balance.mealBreakdown.map((md) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  Text(Fmt.dateShort(md.mealDate),
                      style: const TextStyle(fontSize: 11, color: AppColors.muted, fontFamily: 'monospace')),
                  const SizedBox(width: 8),
                  Expanded(child: Text(md.mealName, style: const TextStyle(fontSize: 12, color: AppColors.muted))),
                  Text(Fmt.money(md.amount),
                      style: const TextStyle(fontSize: 12, color: AppColors.white, fontFamily: 'monospace')),
                ]),
              )),
        ],
      ]),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🎉', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 20),
          const Text('Quyết toán xong!',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.green)),
          const SizedBox(height: 8),
          const Text('Lịch sử đã được lưu lại', style: TextStyle(color: AppColors.muted, fontSize: 15)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.surface, side: const BorderSide(color: AppColors.border)),
            child: const Text('Bữa ăn mới sẽ bắt đầu tích luỹ từ đây', style: TextStyle(color: AppColors.muted)),
          ),
        ]),
      ),
    );
  }
}
