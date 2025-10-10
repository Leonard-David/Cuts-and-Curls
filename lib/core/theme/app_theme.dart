import 'package:flutter/material.dart';

class AppColors {
  static const Color text = Color(0xFF6D6D6D);
  static const Color accent = Color(0xFFFBA506);
  static const Color bg = Color(0xFFF4F5FF);
  static const Color button = Color(0xFF0F2E4A);
  static const Color notify = Color(0xFF2BFF00);
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.bg,
    primaryColor: AppColors.accent,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: AppColors.accent,
      primary: AppColors.button,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.button,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.text),
      bodyLarge: TextStyle(color: AppColors.text),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.button,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    ),
  );
}
