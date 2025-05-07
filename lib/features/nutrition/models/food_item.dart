// lib/features/nutrition/models/food_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// --- NutritionInfo Class (No changes needed here from last correct version) ---
class NutritionInfo {
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? sugar;
  final double? fiber;
  final double? sodium;

  NutritionInfo({
    this.calories, this.protein, this.carbs, this.fat,
    this.sugar, this.fiber, this.sodium,
  });

  factory NutritionInfo.fromOpenFoodFacts(Map<String, dynamic> nutrimentsJson) {
    return NutritionInfo(
      calories: _parseDouble(nutrimentsJson['energy-kcal_100g']),
      protein: _parseDouble(nutrimentsJson['proteins_100g']),
      carbs: _parseDouble(nutrimentsJson['carbohydrates_100g']),
      fat: _parseDouble(nutrimentsJson['fat_100g']),
      sugar: _parseDouble(nutrimentsJson['sugars_100g']),
      fiber: _parseDouble(nutrimentsJson['fiber_100g']),
      sodium: _parseDouble(nutrimentsJson['sodium_100g']),
    );
  }

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
      'calories': calories, 'protein': protein, 'carbs': carbs, 'fat': fat,
      'sugar': sugar, 'fiber': fiber, 'sodium': sodium,
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      if (value.trim().isEmpty) return null;
      try { return double.parse(value); } catch (_) {
        if (kDebugMode) { print("Warning: Could not parse double from string '$value'");}
        return null;
      }
    }
    return null;
  }
}
// --- End NutritionInfo Class ---


// --- Updated FoodItem Model ---
class FoodItem {
  final String id;
  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final NutritionInfo? nutritionInfo; // Per 100g/ml
  final String? ingredientsList;

  // --- New fields for serving and quantity info from API ---
  final String? apiServingSizeString; // Raw string from OFF "serving_size", e.g., "30 g (1 piece)"
  final String? apiServingUnitDescription; // Parsed e.g., "piece", "slice", "cup", "serving" (if available)
  final double? apiServingWeightGrams; // Parsed e.g., 30 (from "30 g")
  final double? apiServingVolumeMl;    // Parsed e.g., 250 (from "250 ml")

  final String? apiPackageQuantityString; // Raw string from OFF "quantity", e.g., "500g" or "1L"
  final double? apiPackageTotalWeightGrams; // Parsed total grams if applicable
  final double? apiPackageTotalVolumeMl;    // Parsed total ml if applicable
  // --- End New fields ---

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
    this.ingredientsList,
    this.apiServingSizeString,      // Add to constructor
    this.apiServingUnitDescription, // Add to constructor
    this.apiServingWeightGrams,     // Add to constructor
    this.apiServingVolumeMl,        // Add to constructor
    this.apiPackageQuantityString,  // Add to constructor
    this.apiPackageTotalWeightGrams,// Add to constructor
    this.apiPackageTotalVolumeMl,   // Add to constructor
    this.customName,
    this.userNotes,
    DateTime? scannedAt,
    this.isOfflineCreated = false,
    this.syncStatus = 'synced',
    this.personalizedInfo,
  }) : scannedAt = scannedAt ?? DateTime.now();


  // Updated factory for API data
  factory FoodItem.fromOpenFoodFacts(Map<String, dynamic> json) {
    final productData = json['product'] as Map<String, dynamic>? ?? {};

    String? servingSizeStr = productData['serving_size'] as String?;
    String? servingUnitDesc;
    double? servingWeightG;
    double? servingVolumeMl;

    if (servingSizeStr != null && servingSizeStr.isNotEmpty) {
      // Attempt to parse: "30 g (1 piece)" or "1 piece (30g)" or "100ml" or "1 serving"
      final servingRegex = RegExp(r'^(?:([\d\.]+)\s*([a-zA-Z]+(?:[\s-][a-zA-Z]+)*))?\s*(?:\(\s*([\d\.]+)\s*([gml]+)\s*\))?$|^(?:([\d\.]+)\s*([gml]+))\s*(?:\((.+)\))?$|^([\d\.]+)\s*([a-zA-Z]+(?:[\s-][a-zA-Z]+)*)$|^([a-zA-Z]+(?:[\s-][a-zA-Z]+)*)$');
      // This complex regex tries to capture different formats.
      // Group 1: Count (e.g., "1"), Group 2: Unit Description (e.g., "piece")
      // Group 3: Weight/Volume in parens (e.g., "30"), Group 4: Unit in parens (e.g., "g")
      // OR
      // Group 5: Weight/Volume direct (e.g., "100"), Group 6: Unit direct (e.g., "ml")
      // Group 7: Description in parens (e.g., "1 serving")
      // OR (fallback to just count + unit desc)
      // Group 8: Count, Group 9: Unit Desc
      // OR (fallback to just unit desc)
      // Group 10: Unit Desc

      final match = servingRegex.firstMatch(servingSizeStr.toLowerCase().trim());

      if (match != null) {
        String? potentialDesc;
        String? potentialWeightValStr;
        String? potentialWeightUnitStr;

        if (match.group(2) != null) potentialDesc = match.group(2)?.trim(); // "piece"
        if (match.group(3) != null) potentialWeightValStr = match.group(3); // "30"
        if (match.group(4) != null) potentialWeightUnitStr = match.group(4); // "g"

        if (potentialDesc == null && match.group(7) != null) potentialDesc = match.group(7)?.trim(); // "1 serving" from parens
        if (potentialWeightValStr == null && match.group(5) != null) potentialWeightValStr = match.group(5); // "100"
        if (potentialWeightUnitStr == null && match.group(6) != null) potentialWeightUnitStr = match.group(6); // "ml"

        if (potentialDesc == null && match.group(9) != null) potentialDesc = match.group(9)?.trim();
        if (potentialDesc == null && match.group(10) != null) potentialDesc = match.group(10)?.trim();


        if (potentialDesc != null) {
           // Normalize "grams", "gram" to "g", etc.
           if (potentialDesc == "grams" || potentialDesc == "gram") potentialDesc = "g";
           if (potentialDesc == "milliliters" || potentialDesc == "milliliter") potentialDesc = "ml";
           servingUnitDesc = potentialDesc;
        }


        if (potentialWeightValStr != null && potentialWeightUnitStr != null) {
          final double? parsedVal = double.tryParse(potentialWeightValStr);
          if (parsedVal != null) {
            if (potentialWeightUnitStr == 'g') servingWeightG = parsedVal;
            if (potentialWeightUnitStr == 'ml') servingVolumeMl = parsedVal;
          }
        }
         // If the main unit desc itself is g or ml and we don't have weight from parens
        if (servingWeightG == null && servingVolumeMl == null && (servingUnitDesc == 'g' || servingUnitDesc == 'ml')) {
            final countStr = match.group(1) ?? match.group(8);
            final double? parsedCount = double.tryParse(countStr ?? "");
            if(parsedCount != null) {
                if(servingUnitDesc == 'g') servingWeightG = parsedCount;
                if(servingUnitDesc == 'ml') servingVolumeMl = parsedCount;
                 // If the description became 'g' or 'ml', clear it as it's now a direct weight/volume
                servingUnitDesc = (match.group(7) ?? match.group(9) ?? match.group(10))?.trim(); // Try to get non-g/ml part
            }
        }


        // If servingUnitDesc is now 'g' or 'ml' due to parsing, but we have a weight, it implies the description was about the weight itself.
        // Prefer a more descriptive unit if possible (e.g., from parens or if it wasn't g/ml initially).
        if ((servingUnitDesc == 'g' && servingWeightG != null) || (servingUnitDesc == 'ml' && servingVolumeMl != null)){
            // If description became 'g' or 'ml', and we have a weight, use "serving" or try from parens
            servingUnitDesc = (match.group(7) ?? "serving") ; // default to "serving" if nothing better
        }


        if (kDebugMode) {
          print("Parsed Serving: Desc='$servingUnitDesc', WeightG='$servingWeightG', VolumeMl='$servingVolumeMl' from '$servingSizeStr'");
        }
      } else {
         if (kDebugMode) {print("Could not parse serving_size: '$servingSizeStr'");}
         // If no regex match but string is not empty, use it as description
         if(servingSizeStr.isNotEmpty) servingUnitDesc = servingSizeStr;
      }
    }

    String? packageQuantityStr = productData['quantity'] as String?;
    double? packageWeightG;
    double? packageVolumeMl;

    if (packageQuantityStr != null && packageQuantityStr.isNotEmpty) {
        // Basic parsing for "500g", "1L", "750ml"
        final quantityMatch = RegExp(r'([\d\.]+)\s*(g|kg|ml|l|cl|oz|floz)\b', caseSensitive: false).firstMatch(packageQuantityStr);
        if (quantityMatch != null) {
            final double? value = double.tryParse(quantityMatch.group(1)!);
            final String unit = quantityMatch.group(2)!.toLowerCase();
            if (value != null) {
                if (unit == 'g') packageWeightG = value;
                else if (unit == 'kg') packageWeightG = value * 1000;
                else if (unit == 'ml') packageVolumeMl = value;
                else if (unit == 'l') packageVolumeMl = value * 1000;
                else if (unit == 'cl') packageVolumeMl = value * 10;
                // Could add oz/floz conversions if needed
            }
        }
         if (kDebugMode) {print("Parsed Package Quantity: WeightG='$packageWeightG', VolumeMl='$packageVolumeMl' from '$packageQuantityStr'");}
    }


    return FoodItem(
      id: productData['_id'] as String? ?? productData['code'] as String? ?? json['code'] ?? '', // Prioritize _id, then code
      barcode: json['code'] ?? '',
      name: productData['product_name'] as String? ?? 'Unknown Product',
      brand: productData['brands'] as String?,
      imageUrl: productData['image_url'] as String?,
      nutritionInfo: productData['nutriments'] != null && productData['nutriments'] is Map
          ? NutritionInfo.fromOpenFoodFacts(productData['nutriments'] as Map<String, dynamic>)
          : null,
      ingredientsList: productData['ingredients_text'] as String?,
      apiServingSizeString: servingSizeStr,
      apiServingUnitDescription: servingUnitDesc,
      apiServingWeightGrams: servingWeightG,
      apiServingVolumeMl: servingVolumeMl,
      apiPackageQuantityString: packageQuantityStr,
      apiPackageTotalWeightGrams: packageWeightG,
      apiPackageTotalVolumeMl: packageVolumeMl,
    );
  }

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
      nutritionInfo: doc['nutritionInfo'] != null && doc['nutritionInfo'] is Map
          ? NutritionInfo.fromMap(doc['nutritionInfo'] as Map<String, dynamic>)
          : null,
      ingredientsList: doc['ingredientsList'],
      apiServingSizeString: doc['apiServingSizeString'],
      apiServingUnitDescription: doc['apiServingUnitDescription'],
      apiServingWeightGrams: (doc['apiServingWeightGrams'] as num?)?.toDouble(),
      apiServingVolumeMl: (doc['apiServingVolumeMl'] as num?)?.toDouble(),
      apiPackageQuantityString: doc['apiPackageQuantityString'],
      apiPackageTotalWeightGrams: (doc['apiPackageTotalWeightGrams'] as num?)?.toDouble(),
      apiPackageTotalVolumeMl: (doc['apiPackageTotalVolumeMl'] as num?)?.toDouble(),
      personalizedInfo: doc['personalized'] != null && doc['personalized'] is Map
          ? PersonalizedInfo.fromMap(doc['personalized'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': barcode, 'name': name, 'brand': brand, 'imageUrl': imageUrl,
      'customName': customName, 'userNotes': userNotes,
      'createdAt': Timestamp.fromDate(scannedAt),
      'isOfflineCreated': isOfflineCreated, 'syncStatus': syncStatus,
      'nutritionInfo': nutritionInfo?.toMap(),
      'ingredientsList': ingredientsList,
      'apiServingSizeString': apiServingSizeString,
      'apiServingUnitDescription': apiServingUnitDescription,
      'apiServingWeightGrams': apiServingWeightGrams,
      'apiServingVolumeMl': apiServingVolumeMl,
      'apiPackageQuantityString': apiPackageQuantityString,
      'apiPackageTotalWeightGrams': apiPackageTotalWeightGrams,
      'apiPackageTotalVolumeMl': apiPackageTotalVolumeMl,
      'personalized': personalizedInfo?.toMap(),
    };
  }
}

// PersonalizedInfo remains the same
class PersonalizedInfo {
  final double? recommendedServing;
  final List<String>? dietCompatibility;
  final List<String>? alternatives;

  PersonalizedInfo({ this.recommendedServing, this.dietCompatibility, this.alternatives,});

   factory PersonalizedInfo.fromMap(Map<String, dynamic> map) {
    return PersonalizedInfo(
      recommendedServing: (map['recommendedServing'] as num?)?.toDouble(),
      dietCompatibility: map['dietCompatibility'] != null ? List<String>.from(map['dietCompatibility']) : null,
      alternatives: map['alternatives'] != null ? List<String>.from(map['alternatives']) : null,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'recommendedServing': recommendedServing, 'dietCompatibility': dietCompatibility, 'alternatives': alternatives,
    };
  }
}