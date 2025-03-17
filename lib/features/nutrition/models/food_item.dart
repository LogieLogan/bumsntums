// lib/features/nutrition/models/food_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  final String id;
  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final NutritionInfo? nutritionInfo;
  final DateTime scannedAt;
  final String? customName;
  final String? userNotes;
  final bool isOfflineCreated;
  final String syncStatus;
  final PersonalizedInfo? personalizedInfo;

  FoodItem({
    required this.id,
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    this.nutritionInfo,
    this.customName,
    this.userNotes,
    DateTime? scannedAt,
    this.isOfflineCreated = false,
    this.syncStatus = 'synced',
    this.personalizedInfo,
  }) : scannedAt = scannedAt ?? DateTime.now();

  // Factory constructor for API data
  factory FoodItem.fromOpenFoodFacts(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] ?? '',
      barcode: json['code'] ?? '',
      name: json['product']['product_name'] ?? 'Unknown Product',
      brand: json['product']['brands'],
      imageUrl: json['product']['image_url'],
      nutritionInfo: json['product']['nutriments'] != null
          ? NutritionInfo.fromOpenFoodFacts(json['product']['nutriments'])
          : null,
    );
  }

  // Factory constructor for Firestore document
  factory FoodItem.fromFirestore(Map<String, dynamic> doc, String id) {
    return FoodItem(
      id: id,
      barcode: doc['productId'] ?? '',
      name: doc['name'] ?? 'Unknown Product',
      brand: doc['brand'],
      imageUrl: doc['imageUrl'],
      customName: doc['customName'],
      userNotes: doc['userNotes'],
      scannedAt: (doc['createdAt'] as Timestamp).toDate(),
      isOfflineCreated: doc['isOfflineCreated'] ?? false,
      syncStatus: doc['syncStatus'] ?? 'synced',
      nutritionInfo: doc['nutritionInfo'] != null
          ? NutritionInfo.fromMap(doc['nutritionInfo'])
          : null,
      personalizedInfo: doc['personalized'] != null
          ? PersonalizedInfo.fromMap(doc['personalized'])
          : null,
    );
  }

  // Convert to Firestore document
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
      'personalized': personalizedInfo?.toMap(),
    };
  }
}

class NutritionInfo {
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? sugar;
  final double? fiber;
  final double? sodium;
  final String? ingredientsList;

  NutritionInfo({
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.sugar,
    this.fiber,
    this.sodium,
    this.ingredientsList,
  });

  factory NutritionInfo.fromOpenFoodFacts(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: _parseDouble(json['energy-kcal_100g']),
      protein: _parseDouble(json['proteins_100g']),
      carbs: _parseDouble(json['carbohydrates_100g']),
      fat: _parseDouble(json['fat_100g']),
      sugar: _parseDouble(json['sugars_100g']),
      fiber: _parseDouble(json['fiber_100g']),
      sodium: _parseDouble(json['sodium_100g']),
      ingredientsList: json['ingredients_text'],
    );
  }

  factory NutritionInfo.fromMap(Map<String, dynamic> map) {
    return NutritionInfo(
      calories: map['calories'],
      protein: map['protein'],
      carbs: map['carbs'],
      fat: map['fat'],
      sugar: map['sugar'],
      fiber: map['fiber'],
      sodium: map['sodium'],
      ingredientsList: map['ingredientsList'],
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
      'ingredientsList': ingredientsList,
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

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
      recommendedServing: map['recommendedServing'],
      dietCompatibility: List<String>.from(map['dietCompatibility'] ?? []),
      alternatives: List<String>.from(map['alternatives'] ?? []),
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