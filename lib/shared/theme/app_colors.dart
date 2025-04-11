// lib/shared/theme/color_palette.dart
import 'package:flutter/material.dart';

/// App color palette based on design system
class AppColors {
  // Primary colors
  static const Color pink = Color(0xFFFF66C4); // New main pink
  static const Color salmon = Color(0xFFFF66C4); // For backward compatibility
  static const Color popCoral = Color(0xFFFF6B6B);
  static const Color terracotta = Color(0xFFC65B4D);
  
  // Secondary colors
  static const Color popYellow = Color(0xFFFFD53E); // Bright retro yellow
  static const Color popTurquoise = Color(0xFF00D8C9); // Turquoise
  static const Color popBlue = Color(0xFF1B9CFC); // Bright blue
  static const Color popGreen = Color(0xFF2ECC71); // Bright green
  
  // Background/Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF9F9F9); // Slightly off-white
  static const Color paleGrey = Color(0xFFF5F5F5);
  
  // Utility colors
  static const Color black = Color(0xFF111111);
  static const Color darkGrey = Color(0xFF333333);
  static const Color mediumGrey = Color(0xFF666666);
  static const Color lightGrey = Color(0xFFAAAAAA);
  static const Color error = Color(0xFFFF5252);
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFB74D);
}