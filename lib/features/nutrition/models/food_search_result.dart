// lib/features/nutrition/models/food_search_result.dart
import 'package:equatable/equatable.dart';

class FoodSearchResult extends Equatable {
  final String barcode; // Barcode (or ID) is essential to fetch full details later
  final String name;
  final String? brand;
  final String? imageUrl; // Small thumbnail URL often available

  const FoodSearchResult({
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
  });

  // Factory to parse from OFF search results product list
  factory FoodSearchResult.fromOffSearch(Map<String, dynamic> productJson) {
    return FoodSearchResult(
      // IMPORTANT: OFF Search API uses 'code' or '_id' for barcode
      barcode: productJson['code']?.toString() ?? productJson['_id']?.toString() ?? '',
      name: productJson['product_name']?.toString() ?? 'Unknown Name',
      brand: productJson['brands']?.toString(),
      imageUrl: productJson['image_thumb_url']?.toString(), // Use thumb URL
    );
  }

  @override
  List<Object?> get props => [barcode, name, brand, imageUrl];
}