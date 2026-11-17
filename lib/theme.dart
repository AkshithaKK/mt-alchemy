import 'package:flutter/material.dart';

/// Brand colours used across the whole app.
const Color navy = Color(0xFF0B1426);
const Color blue = Color(0xFF172B4D);
const Color yellow = Color(0xFFD8B56D);
// Legacy accent name retained so existing widgets keep working; now uses the brand gold.
const Color purple = Color(0xFFD8B56D);
const Color brandPurple = Color(0xFF5B3E96);
const Color pageBg = Color(0xFFF4F2ED);
const Color borderColor = Color(0xFFE8E2D5);
const Color success = Color(0xFF168A79);
const Color danger = Color(0xFFB4413C);

/// Visual identity (icon + colour) for a course or product category.
({IconData icon, Color color}) categoryVisual(String category) {
  switch (category) {
    case 'Emotional Intelligence':
      return (icon: Icons.psychology_alt_rounded, color: brandPurple);
    case 'Mindfulness':
      return (icon: Icons.self_improvement_rounded, color: success);
    case 'Leadership':
      return (icon: Icons.groups_rounded, color: navy);
    case 'Communication':
      return (icon: Icons.forum_rounded, color: blue);
    case 'Team Effectiveness':
      return (icon: Icons.diversity_3_rounded, color: Color(0xFF8A5A1E));
    case 'Workplace Well-being':
      return (icon: Icons.spa_rounded, color: Color(0xFF2E7D5B));
    case 'Personal Development':
      return (icon: Icons.trending_up_rounded, color: Color(0xFF9C6B10));
    case 'Workbooks':
      return (icon: Icons.auto_stories_rounded, color: brandPurple);
    case 'Journals':
      return (icon: Icons.edit_note_rounded, color: success);
    case 'Learning Kits':
      return (icon: Icons.inventory_2_rounded, color: navy);
    case 'Cards':
      return (icon: Icons.style_rounded, color: Color(0xFF8A5A1E));
    case 'Templates':
      return (icon: Icons.description_rounded, color: blue);
    default:
      return (icon: Icons.menu_book_rounded, color: blue);
  }
}

const courseCategories = [
  'Emotional Intelligence',
  'Mindfulness',
  'Leadership',
  'Communication',
  'Team Effectiveness',
  'Workplace Well-being',
  'Personal Development',
  'Organizational Development',
];

const productCategories = [
  'Workbooks',
  'Journals',
  'Templates',
  'Learning Kits',
  'Cards',
  'Merchandise',
];

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: pageBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: yellow,
      brightness: Brightness.light,
      primary: navy,
      secondary: yellow,
      surface: Colors.white,
    ),
    fontFamily: 'Arial',
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: navy.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: borderColor),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFAF9F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD8D3C8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD8D3C8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: navy, width: 1.5),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: navy,
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        animationDuration: const Duration(milliseconds: 220),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        animationDuration: const Duration(milliseconds: 220),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
  );
}
