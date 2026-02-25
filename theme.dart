import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────
//  COLORS
// ─────────────────────────────────────────────

class AppColors {
  static const bg       = Color(0xFF0F0F14);
  static const surface  = Color(0xFF1A1A24);
  static const surface2 = Color(0xFF22222F);
  static const border   = Color(0xFF2E2E40);
  static const accent   = Color(0xFFF4C430);
  static const red      = Color(0xFFFF6B6B);
  static const green    = Color(0xFF6BCB77);
  static const teal     = Color(0xFF4ECDC4);
  static const muted    = Color(0xFF888899);
  static const white    = Color(0xFFF0F0F5);

  static const memberColors = [
    Color(0xFFF4C430),
    Color(0xFF4ECDC4),
    Color(0xFFFF6B6B),
    Color(0xFF6BCB77),
    Color(0xFFB07EFF),
    Color(0xFFFF9F43),
    Color(0xFF48DBFB),
    Color(0xFFFF9FF3),
  ];
}

// ─────────────────────────────────────────────
//  THEME
// ─────────────────────────────────────────────

ThemeData buildAppTheme() {
  return ThemeData(
    colorScheme: ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.accent,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: AppColors.white,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.muted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.muted),
      hintStyle: const TextStyle(color: AppColors.muted),
    ),
  );
}

// ─────────────────────────────────────────────
//  FORMATTERS
// ─────────────────────────────────────────────

class Fmt {
  static final _vnd = NumberFormat('#,###', 'vi_VN');
  static final _date = DateFormat('dd/MM/yyyy', 'vi_VN');
  static final _dateShort = DateFormat('dd/MM', 'vi_VN');
  static final _dateFull = DateFormat('EEEE, dd/MM/yyyy', 'vi_VN');

  static String money(int amount) => '${_vnd.format(amount)}₫';

  static String moneyShort(int amount) {
    if (amount >= 1000000) {
      final m = amount / 1000000;
      return '${m.toStringAsFixed(m.truncateToDouble() == m ? 0 : 1)}M₫';
    }
    if (amount >= 1000) return '${_vnd.format(amount ~/ 1000)}k';
    return '${amount}₫';
  }

  static String date(DateTime d) => _date.format(d);
  static String dateShort(DateTime d) => _dateShort.format(d);
  static String dateFull(DateTime d) => _dateFull.format(d);

  static String sign(int amount) => amount >= 0 ? '+${money(amount)}' : money(amount);
}

// ─────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────

class BcCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double radius;

  const BcCard({
    super.key,
    required this.child,
    this.borderColor,
    this.padding,
    this.onTap,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor ?? AppColors.border),
          ),
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

class MemberChip extends StatelessWidget {
  final String name;
  final String emoji;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const MemberChip({
    super.key,
    required this.name,
    required this.emoji,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.18) : AppColors.surface2,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? color : AppColors.muted,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle, size: 14, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

class MemberAvatar extends StatelessWidget {
  final Member member;
  final double size;
  final bool showBorder;

  const MemberAvatar({
    super.key,
    required this.member,
    this.size = 32,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: member.color.withOpacity(0.25),
        border: showBorder
            ? Border.all(color: AppColors.bg, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        member.emoji,
        style: TextStyle(fontSize: size * 0.45),
      ),
    );
  }
}

// Re-export models for convenience
export '../../data/models/models.dart';
