import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: Colors.white,
      background: AppColors.background,
      onSurface: AppColors.text,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      bodyMedium: GoogleFonts.poppins(
        color: AppColors.text,
      ),
      titleLarge: GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        color: AppColors.text,
      ),
      titleMedium: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
      bodySmall: GoogleFonts.poppins(
        color: AppColors.textSecondary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: GoogleFonts.poppins(
        color: AppColors.textSecondary,
      ),
      hintStyle: GoogleFonts.poppins(
        color: AppColors.textSecondary,
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 1,
      space: 1,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    scaffoldBackgroundColor: Colors.grey[900],
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: Colors.blue[300]!,
      secondary: Colors.orange[300]!,
      surface: Colors.grey[800]!,
      background: Colors.grey[900]!,
      onSurface: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ).copyWith(
      bodyMedium: GoogleFonts.poppins(
        color: Colors.white,
      ),
      titleLarge: GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodySmall: GoogleFonts.poppins(
        color: Colors.grey[400],
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[300],
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[800],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.blue[300]!),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: GoogleFonts.poppins(
        color: Colors.grey[400],
      ),
      hintStyle: GoogleFonts.poppins(
        color: Colors.grey[500],
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey[700],
      thickness: 1,
      space: 1,
    ),
  );
}