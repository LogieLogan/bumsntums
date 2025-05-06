// lib/features/nutrition/models/food_log_entry.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// Enum to represent the meal category
enum MealType { breakfast, lunch, dinner, snack }

class FoodLogEntry extends Equatable {
  final String id; // Unique ID for this log entry
  final String userId; // ID of the user
  final String foodItemId; // ID of the referenced FoodItem (custom or OFF)
  final String? foodItemBarcode; // Barcode if scanned
  final String foodItemName; // Denormalized name for display
  final String? foodItemBrand; // Denormalized brand for display
  final DateTime loggedAt; // Timestamp when logged
  final MealType mealType; // Breakfast, Lunch, Dinner, Snack
  final double servingSize; // e.g., 150, 1, 0.5
  final String servingUnit; // e.g., "g", "ml", "serving", "slice", "cup"
  final double calculatedCalories; // Calories for this specific portion
  final double calculatedProtein; // Protein (g) for this portion
  final double calculatedCarbs; // Carbs (g) for this portion
  final double calculatedFat; // Fat (g) for this portion
  // Optional: Could add micronutrients later if needed

  const FoodLogEntry({
    required this.id,
    required this.userId,
    required this.foodItemId,
    this.foodItemBarcode,
    required this.foodItemName,
    this.foodItemBrand,
    required this.loggedAt,
    required this.mealType,
    required this.servingSize,
    required this.servingUnit,
    required this.calculatedCalories,
    required this.calculatedProtein,
    required this.calculatedCarbs,
    required this.calculatedFat,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        foodItemId,
        foodItemBarcode,
        foodItemName,
        foodItemBrand,
        loggedAt,
        mealType,
        servingSize,
        servingUnit,
        calculatedCalories,
        calculatedProtein,
        calculatedCarbs,
        calculatedFat,
      ];

  // Convert MealType enum to String for storage
  String get mealTypeString => mealType.name;

  // Convert String back to MealType enum
  static MealType _mealTypeFromString(String? value) {
    return MealType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MealType.snack, // Default to snack if unknown
    );
  }

  // --- Firestore Serialization ---

  Map<String, dynamic> toMap() {
    return {
      // id is usually the document ID, not stored in the map itself
      'userId': userId,
      'foodItemId': foodItemId,
      'foodItemBarcode': foodItemBarcode,
      'foodItemName': foodItemName,
      'foodItemBrand': foodItemBrand,
      'loggedAt': Timestamp.fromDate(loggedAt), // Use Firestore Timestamp
      'mealType': mealTypeString, // Store enum as string
      'servingSize': servingSize,
      'servingUnit': servingUnit,
      'calculatedCalories': calculatedCalories,
      'calculatedProtein': calculatedProtein,
      'calculatedCarbs': calculatedCarbs,
      'calculatedFat': calculatedFat,
    };
  }

  factory FoodLogEntry.fromMap(Map<String, dynamic> map, String documentId) {
    return FoodLogEntry(
      id: documentId, // Use document ID from Firestore
      userId: map['userId'] ?? '',
      foodItemId: map['foodItemId'] ?? '',
      foodItemBarcode: map['foodItemBarcode'],
      foodItemName: map['foodItemName'] ?? 'Unknown Food',
      foodItemBrand: map['foodItemBrand'],
      loggedAt: (map['loggedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mealType: _mealTypeFromString(map['mealType']),
      servingSize: (map['servingSize'] as num?)?.toDouble() ?? 1.0,
      servingUnit: map['servingUnit'] ?? 'serving',
      calculatedCalories: (map['calculatedCalories'] as num?)?.toDouble() ?? 0.0,
      calculatedProtein: (map['calculatedProtein'] as num?)?.toDouble() ?? 0.0,
      calculatedCarbs: (map['calculatedCarbs'] as num?)?.toDouble() ?? 0.0,
      calculatedFat: (map['calculatedFat'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // --- Convenience Methods (Optional) ---

  // Example: Get a display string for the serving
  String get servingDisplayString {
     // Handle potential non-integer display for size (e.g., 0.5)
     final sizeString = servingSize == servingSize.truncate()
        ? servingSize.toInt().toString()
        : servingSize.toStringAsFixed(1); // Show one decimal if needed

    return '$sizeString $servingUnit';
  }

}