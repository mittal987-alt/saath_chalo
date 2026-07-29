import 'package:flutter/material.dart';

class AppColors {
  // Premium Primary Colors (Emerald & Teal vibes)
  static const Color primary = Color(0xFF0F9D58);      // Premium Green
  static const Color primaryDark = Color(0xFF0B8043);  // Deep Forest Green
  static const Color primaryLight = Color(0xFF66C894); // Soft Emerald
  
  // Secondary Colors
  static const Color secondary = Color(0xFF2B3A42);    // Sophisticated Dark Blue/Grey
  static const Color secondaryLight = Color(0xFF3F5460);

  // Accent Colors
  static const Color accent = Color(0xFFFFA000);       // Warm Amber for accents

  // Light Mode Background Colors
  static const Color background = Color(0xFFF7F9FA);   // Off-white with blue tint
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF121212);        // Softer black for premium feel

  // Dark Mode Background Colors
  static const Color darkBackground = Color(0xFF121212); // Deep OLED Black
  static const Color darkSurface = Color(0xFF1E1E1E);    // Dark Gray Surface
  static const Color darkCardBg = Color(0xFF242526);     // Slightly lighter for cards

  // Light Mode Text Colors
  static const Color textPrimary = Color(0xFF202124);  // Google-style primary text
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textHint = Color(0xFF9AA0A6);

  // Dark Mode Text Colors
  static const Color darkTextPrimary = Color(0xFFE8EAED);
  static const Color darkTextSecondary = Color(0xFF9AA0A6);

  // Status Colors
  static const Color success = Color(0xFF1E8E3E);
  static const Color error = Color(0xFFD93025);
  static const Color warning = Color(0xFFF9AB00);
  static const Color info = Color(0xFF1A73E8);

  // Card & Border (Soft shadows & borders)
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE8EAED);
  static const Color divider = Color(0xFFF1F3F4);
  
  static const Color darkBorder = Color(0xFF3C4043);
  static const Color darkDivider = Color(0xFF3C4043);

  // Gradient Colors (For modern headers/buttons)
  static const List<Color> primaryGradient = [
    Color(0xFF0F9D58),
    Color(0xFF0B8043),
  ];
}