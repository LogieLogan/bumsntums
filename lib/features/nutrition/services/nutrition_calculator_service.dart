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
    required double servingSize, // The 'count' or 'amount' entered by user
    required String servingUnit,  // The unit selected by user
    String? servingSizeStringFromApi, // Raw string like "1 piece (30g)"
    double? userDefinedWeightPerServing, // User input e.g., 30 (for 30g per piece)
    double? knownWeightOfApiServingUnit, // Pre-parsed weight of API's unit (e.g., 30 if apiServingUnitDescription is "piece" and it's 30g)
  }) {
    if (baseNutrition == null) { /* ... */ return const CalculatedNutrition(); }
    if (servingSize <= 0) { /* ... */ return const CalculatedNutrition(); }

    double calculationFactor = 0.0;
    final unitLower = servingUnit.toLowerCase();

    if (unitLower == 'g' || unitLower == 'ml') {
      calculationFactor = servingSize / _baseAmount;
    } else if (userDefinedWeightPerServing != null && userDefinedWeightPerServing > 0) {
      // Highest priority: User explicitly defined weight for the selected countable unit
      calculationFactor = (userDefinedWeightPerServing / _baseAmount) * servingSize;
      if (kDebugMode) { print("NutritionCalculator: Using user-defined weight ($userDefinedWeightPerServing g/ml) for '$servingUnit'. Quantity: $servingSize. Factor: $calculationFactor");}
    } else if (knownWeightOfApiServingUnit != null && knownWeightOfApiServingUnit > 0) {
      // Next priority: The selected unit is the API's defined unit, and we know its weight
      calculationFactor = (knownWeightOfApiServingUnit / _baseAmount) * servingSize;
       if (kDebugMode) { print("NutritionCalculator: Using API known weight ($knownWeightOfApiServingUnit g/ml) for '$servingUnit'. Quantity: $servingSize. Factor: $calculationFactor");}
    } else if (unitLower == 'serving' && servingSizeStringFromApi != null) {
        // Fallback for generic "serving" if API string has a parsable weight (but not directly tied to knownWeightOfApiServingUnit)
        final double? weightFromApi = parseWeightFromServingString(servingSizeStringFromApi);
        if (weightFromApi != null) {
          calculationFactor = (weightFromApi / _baseAmount) * servingSize;
           if (kDebugMode) { print("NutritionCalculator: Unit 'serving'. Parsed API weight: $weightFromApi g/ml. Quantity: $servingSize. Factor: $calculationFactor"); }
        } else {
           if (kDebugMode) { print("NutritionCalculator: Unit 'serving'. API string '$servingSizeStringFromApi' not parsable. Fallback."); }
           return _fallbackForUncertainUnits(baseNutrition);
        }
    } else if (unitLower == 'oz') {
        const double gramsPerOunce = 28.3495;
        calculationFactor = ((servingSize * gramsPerOunce) / _baseAmount);
    } else {
        // All other countable units without a user-defined or API-defined weight
        if (kDebugMode) { print("NutritionCalculator: Unit '$servingUnit'. No specific weight known. Fallback."); }
        return _fallbackForUncertainUnits(baseNutrition);
    }

    if (calculationFactor > 0) { /* ... (calculate and return) ... */
      return CalculatedNutrition(
        calories: (baseNutrition.calories ?? 0.0) * calculationFactor,
        protein: (baseNutrition.protein ?? 0.0) * calculationFactor,
        carbs: (baseNutrition.carbs ?? 0.0) * calculationFactor,
        fat: (baseNutrition.fat ?? 0.0) * calculationFactor,
      );
    }
    return const CalculatedNutrition();
  }

  CalculatedNutrition _fallbackForUncertainUnits(NutritionInfo baseNutrition) {
     if (kDebugMode) { print("NutritionCalculator: Fallback - Returning zero nutrition for uncertain unit."); }
    return const CalculatedNutrition();
  }

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