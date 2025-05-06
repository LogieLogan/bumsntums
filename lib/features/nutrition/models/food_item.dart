// lib/features/nutrition/models/food_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

// Keep NutritionInfo definition simple for now, ingredients handled separately
class NutritionInfo {
  final double? calories; // Per 100g/ml
  final double? protein;  // Per 100g/ml
  final double? carbs;    // Per 100g/ml
  final double? fat;      // Per 100g/ml
  final double? sugar;    // Per 100g/ml
  final double? fiber;    // Per 100g/ml
  final double? sodium;   // Per 100g/ml

  NutritionInfo({
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.sugar,
    this.fiber,
    this.sodium,
  });

  // Factory to parse from the 'nutriments' sub-object in OFF response
  factory NutritionInfo.fromOpenFoodFacts(Map<String, dynamic> nutrimentsJson) {
    return NutritionInfo(
      calories: _parseDouble(nutrimentsJson['energy-kcal_100g']),
      protein: _parseDouble(nutrimentsJson['proteins_100g']),
      carbs: _parseDouble(nutrimentsJson['carbohydrates_100g']),
      fat: _parseDouble(nutrimentsJson['fat_100g']),
      sugar: _parseDouble(nutrimentsJson['sugars_100g']),
      fiber: _parseDouble(nutrimentsJson['fiber_100g']),
      sodium: _parseDouble(nutrimentsJson['sodium_100g']),
      // Ingredients are parsed separately in FoodItem now
    );
  }

  // --- fromMap and toMap remain the same ---
  factory NutritionInfo.fromMap(Map<String, dynamic> map) {
    return NutritionInfo(
      calories: (map['calories'] as num?)?.toDouble(),
      protein: (map['protein'] as num?)?.toDouble(),
      carbs: (map['carbs'] as num?)?.toDouble(),
      fat: (map['fat'] as num?)?.toDouble(),
      sugar: (map['sugar'] as num?)?.toDouble(),
      fiber: (map['fiber'] as num?)?.toDouble(),
      sodium: (map['sodium'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'sugar': sugar,
      'fiber': fiber,
      'sodium': sodium,
    };
  }

  // Helper remains the same
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      // Handle potential empty strings from API
      if (value.trim().isEmpty) return null;
      try {
        return double.parse(value);
      } catch (_) {
         if (kDebugMode) {
           print("Warning: Could not parse double from string '$value'");
         }
        return null;
      }
    }
    return null;
  }
}

// --- Updated FoodItem Model ---
class FoodItem {
  final String id;
  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final NutritionInfo? nutritionInfo; // Holds per 100g/ml data
  final String? ingredientsList; // Moved here from NutritionInfo
  final String? servingSizeString; // Added field for OFF "serving_size"
  final DateTime scannedAt;
  // User-specific fields from Firestore (optional)
  final String? customName;
  final String? userNotes;
  final bool isOfflineCreated;
  final String syncStatus;
  final PersonalizedInfo? personalizedInfo; // Kept for potential future use

  FoodItem({
    required this.id,
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    this.nutritionInfo,
    this.ingredientsList, // Added to constructor
    this.servingSizeString, // Added to constructor
    this.customName,
    this.userNotes,
    DateTime? scannedAt,
    this.isOfflineCreated = false,
    this.syncStatus = 'synced',
    this.personalizedInfo,
  }) : scannedAt = scannedAt ?? DateTime.now();

  // Updated factory for API data
  factory FoodItem.fromOpenFoodFacts(Map<String, dynamic> json) {
    // Access the 'product' sub-object
    final productData = json['product'] as Map<String, dynamic>? ?? {};

    return FoodItem(
      id: json['id'] ?? '', // Assuming 'id' is top-level if available, else generate
      barcode: json['code'] ?? '',
      name: productData['product_name'] as String? ?? 'Unknown Product',
      brand: productData['brands'] as String?,
      imageUrl: productData['image_url'] as String?,
      // Parse nutriments if present
      nutritionInfo: productData['nutriments'] != null && productData['nutriments'] is Map
          ? NutritionInfo.fromOpenFoodFacts(productData['nutriments'] as Map<String, dynamic>)
          : null,
      // Get ingredients text directly from product object
      ingredientsList: productData['ingredients_text'] as String?,
      // Get serving size string directly from product object
      servingSizeString: productData['serving_size'] as String?,
    );
  }

  // Updated factory for Firestore document
  factory FoodItem.fromFirestore(Map<String, dynamic> doc, String id) {
    return FoodItem(
      id: id,
      barcode: doc['productId'] ?? '',
      name: doc['name'] ?? 'Unknown Product',
      brand: doc['brand'],
      imageUrl: doc['imageUrl'],
      customName: doc['customName'],
      userNotes: doc['userNotes'],
      scannedAt: (doc['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOfflineCreated: doc['isOfflineCreated'] ?? false,
      syncStatus: doc['syncStatus'] ?? 'synced',
      // Parse nested map for nutrition info
      nutritionInfo: doc['nutritionInfo'] != null && doc['nutritionInfo'] is Map
          ? NutritionInfo.fromMap(doc['nutritionInfo'] as Map<String, dynamic>)
          : null,
      // Parse ingredients and serving size from stored map
      ingredientsList: doc['ingredientsList'],
      servingSizeString: doc['servingSizeString'],
      // Parse personalized info if present
      personalizedInfo: doc['personalized'] != null && doc['personalized'] is Map
          ? PersonalizedInfo.fromMap(doc['personalized'] as Map<String, dynamic>)
          : null,
    );
  }

  // Updated method to convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'productId': barcode,
      'name': name,
      'brand': brand,
      'imageUrl': imageUrl,
      'customName': customName,
      'userNotes': userNotes,
      'createdAt': Timestamp.fromDate(scannedAt),
      'isOfflineCreated': isOfflineCreated,
      'syncStatus': syncStatus,
      'nutritionInfo': nutritionInfo?.toMap(),
      'ingredientsList': ingredientsList, // Store ingredients
      'servingSizeString': servingSizeString, // Store serving size string
      'personalized': personalizedInfo?.toMap(),
    };
  }
}

// PersonalizedInfo remains the same
class PersonalizedInfo {
  final double? recommendedServing;
  final List<String>? dietCompatibility;
  final List<String>? alternatives;

  PersonalizedInfo({
    this.recommendedServing,
    this.dietCompatibility,
    this.alternatives,
  });

   factory PersonalizedInfo.fromMap(Map<String, dynamic> map) {
    return PersonalizedInfo(
      recommendedServing: (map['recommendedServing'] as num?)?.toDouble(),
      dietCompatibility: map['dietCompatibility'] != null ? List<String>.from(map['dietCompatibility']) : null,
      alternatives: map['alternatives'] != null ? List<String>.from(map['alternatives']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recommendedServing': recommendedServing,
      'dietCompatibility': dietCompatibility,
      'alternatives': alternatives,
    };
  }
}