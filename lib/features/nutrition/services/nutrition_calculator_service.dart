// lib/features/nutrition/services/nutrition_calculator_service.dart
// ... (imports and CalculatedNutrition class) ...
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/food_item.dart';

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
    required double servingSize, // This is the 'count' of units (e.g., 2 servings, 150 g)
    required String servingUnit,
    String? servingSizeStringFromApi,
    double? userDefinedWeightPerServing, // New: e.g., if user says 1 piece = 30g
  }) {
    if (baseNutrition == null) { /* ... (no change) ... */
       if (kDebugMode) { print("NutritionCalculator: No base nutrition info."); }
       return const CalculatedNutrition();
    }
    if (servingSize <= 0) { /* ... (no change) ... */
       if (kDebugMode) { print("NutritionCalculator: Invalid serving size ($servingSize)."); }
       return const CalculatedNutrition();
    }

    double calculationFactor = 0.0;
    final unitLower = servingUnit.toLowerCase();

    if (unitLower == 'g' || unitLower == 'ml') {
      calculationFactor = servingSize / _baseAmount;
       if (kDebugMode) { print("NutritionCalculator: Unit '$servingUnit'. Factor: $calculationFactor"); }
    }
    // --- Updated Logic for Countable Units ---
    else if (['serving', 'piece', 'slice', 'cup', 'tbsp', 'tsp', 'oz'].contains(unitLower)) {
      // Priority:
      // 1. User-defined weight for this countable unit
      // 2. Parsed weight from API's serving_size string (if unit is 'serving')
      // 3. Fallback (approximate or zero)

      if (userDefinedWeightPerServing != null && userDefinedWeightPerServing > 0) {
        // User specified how much 1 of their chosen units weighs (e.g., 1 piece = 30g)
        calculationFactor = (userDefinedWeightPerServing / _baseAmount) * servingSize;
        if (kDebugMode) { print("NutritionCalculator: Unit '$servingUnit'. User-defined weight: $userDefinedWeightPerServing g. Quantity: $servingSize. Factor: $calculationFactor"); }
      } else if (unitLower == 'serving' && servingSizeStringFromApi != null) {
        final double? weightFromApi = parseWeightFromServingString(servingSizeStringFromApi);
        if (weightFromApi != null) {
          calculationFactor = (weightFromApi / _baseAmount) * servingSize;
           if (kDebugMode) { print("NutritionCalculator: Unit 'serving'. Parsed API weight: $weightFromApi g/ml. Quantity: $servingSize. Factor: $calculationFactor"); }
        } else {
          // API string not parsable for 'serving', treat as uncalculable for now
           if (kDebugMode) { print("NutritionCalculator: Unit 'serving'. API string '$servingSizeStringFromApi' not parsable for weight. Fallback."); }
           return _fallbackForUncertainUnits(baseNutrition);
        }
      } else if (unitLower == 'oz') {
          // Add conversion for ounces (1 oz ~ 28.35g)
          const double gramsPerOunce = 28.3495;
          calculationFactor = ( (servingSize * gramsPerOunce) / _baseAmount );
          if (kDebugMode) { print("NutritionCalculator: Unit 'oz'. Quantity: $servingSize. Factor: $calculationFactor"); }
      }
      else {
        // No user-defined weight, and not 'serving' with parsable API string, or it's 'piece', 'slice' etc.
         if (kDebugMode) { print("NutritionCalculator: Unit '$servingUnit'. No specific weight known. Fallback."); }
        return _fallbackForUncertainUnits(baseNutrition);
      }
    }
    // --- End Updated Logic ---
    else {
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
       // This case should ideally be hit less often with the new logic
       if (kDebugMode) { print("NutritionCalculator: Calculation factor is zero or negative. Returning zeros."); }
       return const CalculatedNutrition();
    }
  }

  // --- NEW Fallback Method ---
  CalculatedNutrition _fallbackForUncertainUnits(NutritionInfo baseNutrition) {
    // Option: Return raw per 100g values if user logged "1 serving/piece" etc.
    // This gives *some* info but needs clear UI indication it's not per "their" serving.
    // For now, let's return zeros to force user to define weight or use g/ml.
    // If we returned baseNutrition directly, the UI would show "per 100g" which is fine,
    // but the "Calculated Nutrition" title might be misleading.
    if (kDebugMode) {
      print("NutritionCalculator: Fallback - Returning zero nutrition for uncertain unit. User should define weight or use g/ml.");
    }
    return const CalculatedNutrition(
      // To give some hint, maybe provide the per 100g values but it should be clear on UI
      // calories: baseNutrition.calories ?? 0.0, // This would be the "per 100g" value
      // protein: baseNutrition.protein ?? 0.0,
      // carbs: baseNutrition.carbs ?? 0.0,
      // fat: baseNutrition.fat ?? 0.0,
    );
  }
  // --- End NEW Fallback Method ---

  static double? parseWeightFromServingString(String? servingString) { /* ... (no change) ... */
    if (servingString == null || servingString.isEmpty) { return null; }
    final regex = RegExp(r'\(?(\d*\.?\d+)\s?(g|ml)\)?');
    final match = regex.firstMatch(servingString);
    if (match != null && match.groupCount >= 1) {
       final valueString = match.group(1);
       if (valueString != null) { return double.tryParse(valueString); }
    }
    return null;
  }
}

final nutritionCalculatorServiceProvider = Provider<NutritionCalculatorService>((ref) {
  return NutritionCalculatorService();
});