import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF253B6E);
  static const Color ink = Color(0xFF16213A);
  static const Color textMuted = Color(0xFF6F7890);
  static const Color blush = Color(0xFFF36C9A);
  static const Color peach = Color(0xFFFFE7D1);
  static const Color mint = Color(0xFFDDF7EA);
  static const Color sky = Color(0xFFDCEEFF);
  static const Color paper = Color(0xFFFFFBF6);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF4F1EA);
  static const Color border = Color(0xFFE9E2D7);
  static const Color success = Color(0xFF29A56C);
  static const Color warning = Color(0xFFF08A24);
  static const Color danger = Color(0xFFE55353);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: blush,
      primary: primary,
      secondary: blush,
      surface: surface,
      surfaceContainerHighest: surfaceMuted,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: paper,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(
          fontSize: 12,
          color: ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 1.4),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
