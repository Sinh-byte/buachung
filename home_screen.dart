import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../widgets/theme.dart';
import '../../data/repository/app_state.dart';
import 'add_meal_screen.dart';
import 'other_screens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, state),
              SliverToBoxAdapter(child: _SummaryRow(state: state)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, 10),
                  child: Text(
                    'BỮA ĂN GẦN ĐÂY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              if (state.meals.isEmpty)
                const SliverFillRemaining(child: _EmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MealCard(meal: state.meals[i]),
                      ),
                      childCount: state.meals.length,
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddMeal(context),
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add),
            label: const Text(
              'Thêm bữa ăn',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        );
      },
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, AppState state) {
    return SliverAppBar(
      backgroundColor: AppColors.bg,
      pinned: true,
      title: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'Bữa',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 26,
                color: AppColors.white,
              ),
            ),
            TextSpan(
              text: 'Chung',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 26,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddMeal(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const AddMealScreen(),
      fullscreenDialog: true,
    ));
  }
}

// ─────────────────────────────────────────────
//  SUMMARY ROW
// ─────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final AppState state;
  const _SummaryRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(child: _SummaryCard('Tổng nợ', Fmt.moneyShort(state.totalDebt), AppColors.red)),
          const SizedBox(width: 10),
          Expanded(child: _SummaryCard('Bữa ăn', '${state.unsettledCount}', AppColors.accent)),
          const SizedBox(width: 10),
          Expanded(child: _SummaryCard('Thành viên', '${state.memberCount}', AppColors.green)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MEAL CARD
// ─────────────────────────────────────────────

class _MealCard extends StatelessWidget {
  final Meal meal;
  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    final accentColor = meal.isSettled ? AppColors.green : AppColors.accent;

    return BcCard(
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MealDetailScreen(mealId: meal.id!),
        ));
      },
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            meal.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        _StatusBadge(settled: meal.isSettled),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📅 ${Fmt.date(meal.date)}  ·  📍 ${meal.location}',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    if (meal.photoPath != null) ...[
                      const SizedBox(height: 4),
                      const Text('📸 Có ảnh', style: TextStyle(fontSize: 11, color: AppColors.teal)),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _AvatarRow(members: meal.members),
                        const Spacer(),
                        Text(
                          Fmt.money(meal.totalAmount),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool settled;
  const _StatusBadge({required this.settled});

  @override
  Widget build(BuildContext context) {
    final color = settled ? AppColors.green : AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        settled ? 'Đã thanh toán' : 'Còn nợ',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _AvatarRow extends StatelessWidget {
  final List<Member> members;
  const _AvatarRow({required this.members});

  @override
  Widget build(BuildContext context) {
    final show = members.take(4).toList();
    final extra = members.length - show.length;

    return SizedBox(
      height: 28,
      width: show.length * 22.0 + (extra > 0 ? 22 : 0),
      child: Stack(
        children: [
          ...show.asMap().entries.map((e) => Positioned(
                left: e.key * 20.0,
                child: MemberAvatar(member: e.value, size: 28),
              )),
          if (extra > 0)
            Positioned(
              left: show.length * 20.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface2,
                  border: Border.all(color: AppColors.bg, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$extra',
                  style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('Chưa có bữa ăn nào',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.white)),
          const SizedBox(height: 8),
          Text('Nhấn "Thêm bữa ăn" để bắt đầu',
              style: TextStyle(color: AppColors.muted, fontSize: 14)),
        ],
      ),
    );
  }
}
