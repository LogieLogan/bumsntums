// lib/features/nutrition/services/nutrition_calculator_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/food_item.dart'; // Import FoodItem for NutritionInfo access

// CalculatedNutrition class remains the same
class CalculatedNutrition {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final bool isApproximation;

  const CalculatedNutrition({
    this.calories = 0.0,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
    this.isApproximation = false, // Default to precise unless fallback is used
  });
}

class NutritionCalculatorService {
  static const double _baseAmount = 100.0;
  static const double _gramsPerOunce = 28.3495;

  CalculatedNutrition calculateNutrition({
    required NutritionInfo? baseNutrition,
    required double servingSize,
    required String servingUnit,
    double? userDefinedWeightPerServing,
    // Correct parameter names:
    double? knownWeightOfApiServingUnit,
    String? apiServingUnitDescription,
  }) {
    if (baseNutrition == null) {
      /* ... */
      return const CalculatedNutrition(isApproximation: true);
    }
    if (servingSize <= 0) {
      /* ... */
      return const CalculatedNutrition();
    }

    double calculationFactor = 0.0;
    final String unitLower = servingUnit.toLowerCase();
    bool isApprox = false; // isApproximation flag for the result

    try {
      if (unitLower == 'g' || unitLower == 'ml') {
        calculationFactor = servingSize / _baseAmount;
      } else if (unitLower == 'oz') {
        calculationFactor = ((servingSize * _gramsPerOunce) / _baseAmount);
      } else {
        // Handle Countable Units
        double? weightPerUnit = 0.0;

        if (userDefinedWeightPerServing != null &&
            userDefinedWeightPerServing > 0) {
          weightPerUnit = userDefinedWeightPerServing;
          if (kDebugMode) {
            print(
              "[Calc] Using user-defined weight ($weightPerUnit g/ml) for unit '$servingUnit'.",
            );
          }
        }
        // --- Corrected Variable Name ---
        else if (unitLower == apiServingUnitDescription?.toLowerCase() &&
            knownWeightOfApiServingUnit !=
                null && // Use the correct parameter name
            knownWeightOfApiServingUnit > 0) {
          weightPerUnit =
              knownWeightOfApiServingUnit; // Use the correct parameter name
          if (kDebugMode) {
            print(
              "[Calc] Using API known weight ($weightPerUnit g/ml) for unit '$servingUnit'.",
            );
          }
        }
        // --- End Correction ---

        if (weightPerUnit > 0) {
          calculationFactor = (weightPerUnit / _baseAmount) * servingSize;
        } else {
          if (kDebugMode) {
            print(
              "[Calc] Fallback: No weight found for unit '$servingUnit'. Cannot calculate accurately.",
            );
          }
          return const CalculatedNutrition(
            isApproximation: true,
          ); // Mark as approximation/failure
        }
      }

      if (calculationFactor > 0) {
        return CalculatedNutrition(
          calories: (baseNutrition.calories ?? 0.0) * calculationFactor,
          protein: (baseNutrition.protein ?? 0.0) * calculationFactor,
          carbs: (baseNutrition.carbs ?? 0.0) * calculationFactor,
          fat: (baseNutrition.fat ?? 0.0) * calculationFactor,
          isApproximation:
              isApprox, // isApprox is currently always false here, could be refined
        );
      } else {
        if (kDebugMode) {
          print(
            "[Calc] Calculation factor is zero or negative. Returning zeros.",
          );
        }
        return const CalculatedNutrition(isApproximation: true);
      }
    } catch (e) {
      if (kDebugMode) {
        print("[Calc] Error during calculation: $e");
      }
      return const CalculatedNutrition(isApproximation: true);
    }
  }
}

// Provider remains the same
final nutritionCalculatorServiceProvider = Provider<NutritionCalculatorService>(
  (ref) {
    return NutritionCalculatorService();
  },
);
