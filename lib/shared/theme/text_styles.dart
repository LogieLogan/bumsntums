// lib/shared/theme/text_styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_palette.dart';

/// Text styles based on design system
class AppTextStyles {
  static TextStyle get h1 => GoogleFonts.poiretOne(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.darkGrey,
  );
  
  static TextStyle get h2 => GoogleFonts.poiretOne(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.darkGrey,
  );
  
  static TextStyle get h3 => GoogleFonts.poiretOne(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.darkGrey,
  );
  
  static TextStyle get body => GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.darkGrey,
  );
  
  static TextStyle get small => GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.darkGrey,
  );
  
  static TextStyle get caption => GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w300,
    color: AppColors.mediumGrey,
  );
  
  static TextStyle get accent => GoogleFonts.pacifico(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: AppColors.popCoral,
  );
}