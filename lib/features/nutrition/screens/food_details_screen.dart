// lib/features/nutrition/screens/food_details_screen.dart
import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FoodDetailsScreen extends ConsumerWidget {
  final FoodItem foodItem;

  const FoodDetailsScreen({super.key, required this.foodItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Details'),
        backgroundColor: AppColors.pink,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (foodItem.imageUrl != null)
              Container(
                height: 200,
                decoration: BoxDecoration(color: Colors.grey[200]),
                child: Image.network(
                  foodItem.imageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (context, error, stackTrace) => const Center(
                        child: Icon(
                          Icons.no_food,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                ),
              )
            else
              Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.no_food, size: 80, color: Colors.grey),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(foodItem.name, style: AppTextStyles.h2),
                  if (foodItem.brand != null)
                    Text(
                      foodItem.brand!,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.mediumGrey,
                      ),
                    ),
                ],
              ),
            ),

            if (foodItem.nutritionInfo != null)
              _buildNutritionCard(foodItem.nutritionInfo!, context)
            else
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No nutrition information available',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: AppColors.mediumGrey,
                    ),
                  ),
                ),
              ),

            if (foodItem.ingredientsList != null &&
                foodItem.ingredientsList!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: Card(
                  margin: EdgeInsets.zero,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ingredients:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          foodItem.ingredientsList!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.qr_code, color: AppColors.mediumGrey),
                  const SizedBox(width: 8),
                  Text(
                    'Barcode: ${foodItem.barcode}',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.mediumGrey,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Coming soon: Add to food diary'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.popTurquoise,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Add to Food Diary',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard(
    NutritionInfo nutritionInfo,
    BuildContext context,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nutrition Facts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Per 100g / 100ml (Approx.)',
              style: TextStyle(fontSize: 14, color: AppColors.mediumGrey),
            ),
            const SizedBox(height: 16),
            const Divider(),
            _buildNutrientRow(
              'Calories',
              nutritionInfo.calories != null
                  ? '${nutritionInfo.calories!.toStringAsFixed(0)} kcal'
                  : 'N/A',
              context,
              isCalories: true,
            ),
            const Divider(),
            _buildNutrientRow(
              'Fat',
              nutritionInfo.fat != null
                  ? '${nutritionInfo.fat!.toStringAsFixed(1)}g'
                  : 'N/A',
              context,
            ),
            _buildNutrientRow(
              'Carbohydrates',
              nutritionInfo.carbs != null
                  ? '${nutritionInfo.carbs!.toStringAsFixed(1)}g'
                  : 'N/A',
              context,
            ),
            _buildNutrientRow(
              '  of which Sugars',
              nutritionInfo.sugar != null
                  ? '${nutritionInfo.sugar!.toStringAsFixed(1)}g'
                  : 'N/A',
              context,
              isSubItem: true,
            ),
            _buildNutrientRow(
              'Fiber',
              nutritionInfo.fiber != null
                  ? '${nutritionInfo.fiber!.toStringAsFixed(1)}g'
                  : 'N/A',
              context,
            ),
            _buildNutrientRow(
              'Protein',
              nutritionInfo.protein != null
                  ? '${nutritionInfo.protein!.toStringAsFixed(1)}g'
                  : 'N/A',
              context,
            ),
            _buildNutrientRow(
              'Sodium',
              nutritionInfo.sodium != null
                  ? '${(nutritionInfo.sodium! * 1000).toStringAsFixed(0)}mg'
                  : 'N/A',
              context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(
    String label,
    String value,
    BuildContext context, {
    bool isCalories = false,
    bool isSubItem = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSubItem ? FontWeight.normal : FontWeight.w500,
                fontSize: isCalories ? 16 : 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isCalories ? FontWeight.bold : FontWeight.normal,
              fontSize: isCalories ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
