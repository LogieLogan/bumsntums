// lib/shared/theme/text_styles.dart
import 'package:flutter/material.dart';
// Remove the google_fonts import if you are exclusively using bundled fonts now
// import 'package:google_fonts/google_fonts.dart';
import 'color_palette.dart'; // Ensure this import points to your AppColors file

/// Text styles based on design system using bundled variable fonts
class AppTextStyles {
  // Use Raleway for headings
  static const TextStyle h1 = TextStyle(
    fontFamily: 'Raleway', // Use the family name from pubspec
    fontSize: 32,
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.darkGrey,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: 'Raleway',
    fontSize: 24,
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.darkGrey,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: 'Raleway',
    fontSize: 20,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.darkGrey,
  );

  // Use Roboto for body text (Ensure you use standard Roboto, NOT Roboto Mono)
  static const TextStyle body = TextStyle(
    fontFamily: 'Roboto', // Use the family name from pubspec
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.darkGrey,
  );

  static const TextStyle small = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.darkGrey,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 12,
    fontWeight: FontWeight.w300, // Light
    color: AppColors.mediumGrey,
  );

  // Decide if you still need an 'accent' style and which font/weight to use
  // Using Raleway Italic might be nice if you download/include an italic variable font
  // or if the regular variable font supports an italic axis.
  // For simplicity, let's use Raleway regular for now.
  static const TextStyle accent = TextStyle(
    fontFamily: 'Raleway',
    fontSize: 18,
    fontWeight: FontWeight.w400, // Regular Raleway for accent? Or choose another weight/style.
    color: AppColors.popCoral, // Example color
  );
}