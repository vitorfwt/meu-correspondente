import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette
  static const Color primary = Color(0xFF0D1B2A);      // Dark Navy / Dark Blue (#0D1B2A)
  static const Color secondary = Color(0xFF1B4965);    // Medium Blue / Dark Blue (#1B4965)
  static const Color accent = Color(0xFF2EC4B6);       // Turquoise (#2EC4B6)
  static const Color lightGrey = Color(0xFFE0E7EF);    // Ice Blue / Light Grey (#E0E7EF)
  static const Color background = Color(0xFFF7F9FC);   // Background (#F7F9FC)

  // Feedback Colors
  static const Color success = Color(0xFF22C55E);      // Success (#22C55E)
  static const Color warning = Color(0xFFF59E0B);      // Warning/Alert (#F59E0B)
  static const Color error = Color(0xFFEF4444);        // Error (#EF4444)
  static const Color info = Color(0xFF3B82F6);         // Information (#3B82F6)

  // Primary Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF1B4965),
      Color(0xFF2EC4B6),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
