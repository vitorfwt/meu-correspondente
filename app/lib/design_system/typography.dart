import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get titleLarge => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold, // Bold
      );

  static TextStyle get titleMedium => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600, // SemiBold
      );

  static TextStyle get sectionTitle => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600, // SemiBold
      );

  static TextStyle get body => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal, // Regular
      );

  static TextStyle get legend => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal, // Regular
      );

  static TextStyle get helperText => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500, // Medium
      );
}
