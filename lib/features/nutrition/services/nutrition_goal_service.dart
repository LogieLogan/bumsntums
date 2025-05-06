// lib/features/nutrition/services/nutrition_goal_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:math'; // For pow

import '../../auth/models/user_profile.dart'; // Import UserProfile model
import '../models/estimated_goals.dart'; // Import EstimatedGoals model

class NutritionGoalService {

  EstimatedGoals estimateDailyGoals(UserProfile? profile) {
    // Use default values if profile is null or essential data is missing
    if (profile == null ||
        profile.weightKg == null || profile.weightKg! <= 0 ||
        profile.heightCm == null || profile.heightCm! <= 0 ||
        profile.age == null || profile.age! <= 0) {
      if (kDebugMode) {
         print("NutritionGoalService: Insufficient profile data for estimation. Using defaults.");
      }
      return EstimatedGoals.defaults();
    }

    // --- 1. Calculate BMR (Mifflin-St Jeor for female) ---
    // BMR = (10 * weight in kg) + (6.25 * height in cm) - (5 * age in years) - 161
    double bmr = (10 * profile.weightKg!) +
                 (6.25 * profile.heightCm!) -
                 (5 * profile.age!) - 161;

    // --- 2. Determine Activity Factor (Simplified) ---
    // Use fitnessLevel and weeklyWorkoutDays for a basic estimate
    double activityFactor = 1.2; // Default to sedentary
    int workoutDays = profile.weeklyWorkoutDays ?? 0; // Default to 0 if null

    if (workoutDays <= 1 && profile.fitnessLevel == FitnessLevel.beginner) {
       activityFactor = 1.2; // Sedentary / Little exercise
    } else if (workoutDays <= 3 || profile.fitnessLevel == FitnessLevel.beginner) {
       activityFactor = 1.375; // Lightly active (1-3 days/week)
    } else if (workoutDays <= 5 || profile.fitnessLevel == FitnessLevel.intermediate) {
       activityFactor = 1.55; // Moderately active (3-5 days/week)
    } else { // workoutDays > 5 or Advanced
       activityFactor = 1.725; // Very active (6-7 days/week)
    }

    // --- 3. Calculate TDEE (Total Daily Energy Expenditure) ---
    double tdee = bmr * activityFactor;

    // --- 4. Adjust TDEE based on Primary Goal ---
    double targetCalories = tdee;
    // Prioritize Weight Loss goal if present
    if (profile.goals.contains(FitnessGoal.weightLoss)) {
      targetCalories = tdee - 500; // Moderate deficit (ensure minimum ~1200 kcal)
      targetCalories = max(1200, targetCalories); // Safety minimum
    } else if (profile.goals.contains(FitnessGoal.toning) || profile.goals.contains(FitnessGoal.strength)) {
       // Slight deficit or maintenance for toning/strength depending on level, start with maintenance
       targetCalories = tdee; // Aim for maintenance initially
    } else {
       // Default to maintenance if no specific goal like weight loss/toning/strength
       targetCalories = tdee;
    }

    // --- 5. Estimate Macros (Example: 40% C / 30% P / 30% F) ---
    // Adjust percentages based on goals if desired (e.g., higher protein for strength/toning)
    double proteinPercentage = 0.30;
    double carbPercentage = 0.40;
    double fatPercentage = 0.30;

    if (profile.goals.contains(FitnessGoal.toning) || profile.goals.contains(FitnessGoal.strength)) {
        proteinPercentage = 0.35; // Slightly higher protein
        carbPercentage = 0.40;
        fatPercentage = 0.25;
    } else if (profile.goals.contains(FitnessGoal.weightLoss)) {
         proteinPercentage = 0.35; // Higher protein can help satiety
         carbPercentage = 0.35;
         fatPercentage = 0.30;
    }

    int calculatedProtein = ((targetCalories * proteinPercentage) / 4).round(); // 4 kcal/g protein
    int calculatedCarbs = ((targetCalories * carbPercentage) / 4).round();   // 4 kcal/g carbs
    int calculatedFat = ((targetCalories * fatPercentage) / 9).round();     // 9 kcal/g fat

    if (kDebugMode) {
       print("NutritionGoalService: BMR=$bmr, Activity=$activityFactor, TDEE=$tdee");
       print("NutritionGoalService: Estimated Goals -> Cal:${targetCalories.round()}, P:${calculatedProtein}g, C:${calculatedCarbs}g, F:${calculatedFat}g");
    }

    return EstimatedGoals(
      targetCalories: targetCalories.round(),
      targetProtein: calculatedProtein,
      targetCarbs: calculatedCarbs,
      targetFat: calculatedFat,
      areMet: true, // Indicate estimation was successful
    );
  }
}

// --- Riverpod Provider ---
final nutritionGoalServiceProvider = Provider<NutritionGoalService>((ref) {
  return NutritionGoalService();
});