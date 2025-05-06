// lib/features/nutrition/models/estimated_goals.dart
import 'package:equatable/equatable.dart';

class EstimatedGoals extends Equatable {
  final int targetCalories;
  final int targetProtein; // in grams
  final int targetCarbs;   // in grams
  final int targetFat;     // in grams
  final bool areMet; // Flag to indicate if minimum required profile data was met for estimation

  const EstimatedGoals({
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
    required this.areMet,
  });

  // Factory for default/placeholder values when estimation isn't possible
  factory EstimatedGoals.defaults() {
    return const EstimatedGoals(
      targetCalories: 2000, // General default
      targetProtein: 100,   // General default
      targetCarbs: 250,    // General default
      targetFat: 65,       // General default
      areMet: false,        // Indicate these are not estimated based on user data
    );
  }

  @override
  List<Object?> get props => [
    targetCalories,
    targetProtein,
    targetCarbs,
    targetFat,
    areMet,
  ];
}