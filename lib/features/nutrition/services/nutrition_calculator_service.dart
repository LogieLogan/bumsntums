// lib/features/nutrition/services/nutrition_calculator_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/food_item.dart';

// CalculatedNutrition class remains the same
class CalculatedNutrition {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const CalculatedNutrition({
    this.calories = 0.0,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
  });
}


class NutritionCalculatorService {

  static const double _baseAmount = 100.0;

  CalculatedNutrition calculateNutrition({
    required NutritionInfo? baseNutrition,
    required double servingSize,
    required String servingUnit,
    String? servingSizeStringFromApi,
  }) {
    if (baseNutrition == null) {
       if (kDebugMode) { print("NutritionCalculator: No base nutrition info."); }
       return const CalculatedNutrition();
    }
    if (servingSize <= 0) {
       if (kDebugMode) { print("NutritionCalculator: Invalid serving size ($servingSize)."); }
       return const CalculatedNutrition();
    }

    double calculationFactor = 0.0;
    final unitLower = servingUnit.toLowerCase();

    if (unitLower == 'g' || unitLower == 'ml') {
      calculationFactor = servingSize / _baseAmount;
       if (kDebugMode) { print("NutritionCalculator: Unit '$servingUnit'. Factor: $calculationFactor"); }
    } else if (unitLower == 'serving') {
       // Use the static public method here
       final double? weightFromApi = parseWeightFromServingString(servingSizeStringFromApi);
       if (weightFromApi != null) {
          calculationFactor = (weightFromApi / _baseAmount) * servingSize;
           if (kDebugMode) { print("NutritionCalculator: Unit 'serving'. Parsed weight: $weightFromApi g/ml. User servings: $servingSize. Factor: $calculationFactor"); }
       } else {
           if (kDebugMode) { print("NutritionCalculator: Unit 'serving'. Could not parse weight from API string '$servingSizeStringFromApi'. Returning zeros."); }
          return const CalculatedNutrition();
       }
    } else if (unitLower == 'piece' || unitLower == 'slice') {
        if (kDebugMode) { print("NutritionCalculator: Cannot calculate for unit '$servingUnit' based on per-100g data. Returning zeros."); }
        return const CalculatedNutrition();
    } else {
      if (kDebugMode) { print("NutritionCalculator: Unknown serving unit '$servingUnit'."); }
      return const CalculatedNutrition();
    }

    if (calculationFactor > 0) {
      return CalculatedNutrition(
        calories: (baseNutrition.calories ?? 0.0) * calculationFactor,
        protein: (baseNutrition.protein ?? 0.0) * calculationFactor,
        carbs: (baseNutrition.carbs ?? 0.0) * calculationFactor,
        fat: (baseNutrition.fat ?? 0.0) * calculationFactor,
      );
    } else {
       return const CalculatedNutrition();
    }
  }

  // --- Make Helper Method public and static ---
  static double? parseWeightFromServingString(String? servingString) {
    if (servingString == null || servingString.isEmpty) { return null; }
    final regex = RegExp(r'\(?(\d*\.?\d+)\s?(g|ml)\)?');
    final match = regex.firstMatch(servingString);

    if (match != null && match.groupCount >= 1) {
       final valueString = match.group(1);
       if (valueString != null) {
          return double.tryParse(valueString);
       }
    }
    return null;
  }
  // --- End Helper Method Change ---
}

// Provider remains the same
final nutritionCalculatorServiceProvider = Provider<NutritionCalculatorService>((ref) {
  return NutritionCalculatorService();
});