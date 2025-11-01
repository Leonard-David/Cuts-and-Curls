// lib/core/constants/colors.dart
// Centralized color palette for the entire app.

import 'package:flutter/material.dart';

class AppColors {
  // Primary dark navy blue (used for buttons)
  static const Color primary = Color(0xFF0A2941);

  // Secondary accent (orange)
  static const Color accent = Color(0xFFFFA726);

  // Background white
  static const Color background = Colors.white;

  // Text colors
  static const Color text = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF6E6E6E);

  // Input border color
  static const Color border = Color(0xFFE0E0E0);

  // Error red
  static const Color error = Color(0xFFD32F2F); 
  
  // Success green
  static const Color success = Color(0xFF388E3C);

  // Surface colors for cards
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Additional colors for better Material 3 support
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.black;
  static const Color onBackground = Color(0xFF000000);
  static const Color onSurface = Color(0xFF000000);
  static const Color onError = Colors.white;
}