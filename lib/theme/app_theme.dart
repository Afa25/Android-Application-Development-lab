// ============================================================
//  GRADE MASTER  App Theme
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  
  static const Color primary = Color(0xFF1A237E); // Deep Indigo
  static const Color primaryLight = Color(0xFF3949AB);
  static const Color primaryDark = Color(0xFF0D1257);
  static const Color accent = Color(0xFF00BCD4); // Cyan
  static const Color accentGold = Color(0xFFFFB300); // Gold for honors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color surface = Color(0xFFF5F7FF);
  static const Color cardBg = Color(0xFFFFFFFF);


  static Color gradeColor(String letter) {
    switch (letter.substring(0, 1)) {
      case 'A':
        return const Color(0xFF2E7D32);
      case 'B':
        return const Color(0xFF1565C0);
      case 'C':
        return const Color(0xFFE65100);
      case 'D':
        return const Color(0xFFBF360C);
      case 'F':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF616161);
    }
  }

  
  static Color standingColor(String title) {
    switch (title) {
      case 'Summa Cum Laude':
        return const Color(0xFFFFB300);
      case 'Magna Cum Laude':
        return const Color(0xFF9E9E9E);
      case 'Cum Laude':
        return const Color(0xFF8D6E63);
      case 'Upper Class Honours':
        return const Color(0xFF2E7D32);
      case 'Second Class Upper':
        return const Color(0xFF1565C0);
      case 'Second Class Lower':
        return const Color(0xFFE65100);
      case 'Third Class':
        return const Color(0xFFBF360C);
      default:
        return const Color(0xFFC62828);
    }
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: accent,
        surface: surface,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: cardBg,
        shadowColor: primary.withValues(alpha: 0.1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE8EAF6),
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primaryLight,
        secondary: accent,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );
  }
}
