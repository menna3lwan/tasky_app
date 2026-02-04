import 'package:flutter/material.dart';

/// Application color constants following Single Responsibility Principle
/// This class is responsible only for defining color values used throughout the app
abstract class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF5F33E1);
  static const Color primaryLight = Color(0xFF7B5CE6);
  static const Color primaryDark = Color(0xFF4A1FCF);

  // Background colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color scaffoldBackground = Color(0xFFF5F5F5);

  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6E6E6E);
  static const Color textHint = Color(0xFF9E9E9E);

  // Input field colors
  static const Color inputBorder = Color(0xFFE0E0E0);
  static const Color inputFocusedBorder = primary;
  static const Color inputFill = Color(0xFFF5F5F5);

  // Button colors
  static const Color buttonDisabled = Color(0xFFBDBDBD);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);

  // Splash screen colors
  static const Color splashYellow = Color(0xFFFFE500);

  // Onboarding indicator colors
  static const Color indicatorActive = primary;
  static const Color indicatorInactive = Color(0xFFE0E0E0);
}
