import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const background = Color(0xFF06070B);
  static const backgroundAlt = Color(0xFF08080C);
  static const panel = Color(0xFF0D0F17);
  static const panelDeep = Color(0xFF0B0D13);
  static const text = Color(0xFFF5F7FB);
  static const muted = Color(0xFFA0AEC0);
  static const dim = Color(0xFF687386);
  static const border = Color(0x14FFFFFF);
  static const accent = Color(0xFF00FF66);
  static const danger = Color(0xFFFF5500);
}

class AppTheme {
  const AppTheme._();

  static ThemeData get data {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        error: AppColors.danger,
        surface: AppColors.panel,
      ),
      fontFamily: 'Inter',
      scaffoldBackgroundColor: AppColors.background,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.text,
          fontSize: 48,
          fontWeight: FontWeight.w900,
          height: 1.02,
        ),
        headlineMedium: TextStyle(
          color: AppColors.text,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          height: 1.1,
        ),
        titleLarge: TextStyle(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        bodyLarge: TextStyle(
          color: AppColors.muted,
          fontSize: 16,
          height: 1.55,
        ),
        bodyMedium: TextStyle(
          color: AppColors.muted,
          fontSize: 14,
          height: 1.45,
        ),
      ),
      useMaterial3: true,
    );
  }
}

class TechText {
  const TechText._();

  static const label = TextStyle(
    color: AppColors.dim,
    fontFamily: 'monospace',
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.2,
  );

  static const monoValue = TextStyle(
    color: AppColors.text,
    fontFamily: 'monospace',
    fontSize: 46,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );
}
