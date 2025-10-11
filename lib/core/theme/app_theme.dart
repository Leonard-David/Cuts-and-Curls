// lib/core/theme/app_theme.dart
//
// --------------------------------------------------------
// Global theme configuration for Cuts & Curls
// --------------------------------------------------------
// This defines your brand colors, text styles, and button design
// consistent across all screens.
// --------------------------------------------------------

import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0A2940); // Navy blue (Sign In button)
  static const Color accent = Color(0xFFFFA726); // Amber (logo accent)
  static const Color background = Colors.white;
  static const Color text = Colors.black87;
  static const Color hint = Colors.grey;
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.text,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      hintStyle: const TextStyle(color: AppColors.hint),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}
