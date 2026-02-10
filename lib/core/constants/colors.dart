import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF102289);
  static const Color primaryDark = Color(0xFF0A1A6B);
  static const Color primaryLight = Color(0xFF1A34A3);

  // Accent Colors
  static const Color accent = Color(0xFFFFB400);
  static const Color accentDark = Color(0xFFCC9000);
  static const Color accentLight = Color(0xFFFFC533);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF1A1A1A);
  static const Color gray100 = Color(0xFFF8F9FA);
  static const Color gray200 = Color(0xFFE9ECEF);
  static const Color gray300 = Color(0xFFDEE2E6);
  static const Color gray400 = Color(0xFFCED4DA);
  static const Color gray500 = Color(0xFF6C757D);
  static const Color gray600 = Color(0xFF495057);
  static const Color gray700 = Color(0xFF343A40);
  static const Color gray800 = Color(0xFF212529);
  static const Color gray900 = Color(0xFF121416);
  static const Color gray50 = Color(0xFFFAFBFC);

  // Semantic Colors
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFDC3545);
  static const Color info = Color(0xFF17A2B8);

  // Background Colors
  static const Color background = white;
  static const Color surface = gray100;
  static const Color onBackground = black;
  static const Color onSurface = gray700;

  // Text Colors
  static const Color textPrimary = black;
  static const Color textSecondary = gray600;
  static const Color textHint = gray500;
  static const Color textDisabled = gray400;

  // Border Colors
  static const Color border = gray300;
  static const Color borderFocus = primary;
  static const Color borderError = error;

  // Shadow Colors
  static const Color shadow = Color(0x14000000);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
