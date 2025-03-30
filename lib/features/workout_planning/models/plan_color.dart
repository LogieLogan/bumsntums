// lib/features/workouts/models/plan_color.dart
import 'package:flutter/material.dart';
import '../../../shared/theme/color_palette.dart';

class PlanColor {
  final Color color;
  final String name;
  final String emoji;

  const PlanColor({
    required this.color,
    required this.name,
    required this.emoji,
  });

  // Predefined color options for plans
  static const List<PlanColor> predefinedColors = [
    PlanColor(color: AppColors.pink, name: 'Pink', emoji: '💗'),
    PlanColor(color: AppColors.popCoral, name: 'Coral', emoji: '🧡'),
    PlanColor(color: AppColors.popTurquoise, name: 'Turquoise', emoji: '💙'),
    PlanColor(color: AppColors.popBlue, name: 'Blue', emoji: '🦋'),
    PlanColor(color: AppColors.popGreen, name: 'Green', emoji: '🥑'),
    PlanColor(color: AppColors.popYellow, name: 'Yellow', emoji: '🌟'),
    PlanColor(color: AppColors.terracotta, name: 'Terracotta', emoji: '🧱'),
    PlanColor(color: Color(0xFF9C27B0), name: 'Purple', emoji: '🍇'),
  ];

  // Get color by name
  static Color? getColorByName(String name) {
    final planColor = predefinedColors.firstWhere(
      (color) => color.name.toLowerCase() == name.toLowerCase(),
      orElse: () => predefinedColors.first,
    );
    return planColor.color;
  }

  // Generate a color if none is specified (based on plan name)
  static PlanColor generateFromName(String planName) {
    // Simple hash function to get a consistent color for the same plan name
    final hash = planName.hashCode.abs() % predefinedColors.length;
    return predefinedColors[hash];
  }
}