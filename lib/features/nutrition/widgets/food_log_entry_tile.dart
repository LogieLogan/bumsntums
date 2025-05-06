// lib/features/nutrition/widgets/food_log_entry_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For number formatting

import '../models/food_log_entry.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';

class FoodLogEntryTile extends StatelessWidget {
  final FoodLogEntry entry;
  final VoidCallback? onTap; // For potential editing later
  final VoidCallback? onDelete; // For swipe-to-delete later

  const FoodLogEntryTile({
    super.key,
    required this.entry,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat("#,##0"); // Format calories

    return ListTile(
       // TODO: Implement onTap for editing
       onTap: onTap,
       // TODO: Wrap with Dismissible for swipe-to-delete using onDelete
       leading: CircleAvatar( // Simple indicator for now
         backgroundColor: AppColors.offWhite.withAlpha(50),
         child: Icon(_getMealIcon(entry.mealType), size: 20, color: AppColors.offWhite),
       ),
       title: Text(
         entry.foodItemName,
         style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
         maxLines: 1,
         overflow: TextOverflow.ellipsis,
       ),
       subtitle: Text(
         entry.servingDisplayString + (entry.foodItemBrand != null ? ' (${entry.foodItemBrand})' : ''),
         style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey),
         maxLines: 1,
         overflow: TextOverflow.ellipsis,
       ),
       trailing: Text(
         '${numberFormat.format(entry.calculatedCalories)} kcal',
         style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, color: AppColors.salmon),
       ),
    );
  }

  IconData _getMealIcon(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast: return Icons.free_breakfast_outlined;
      case MealType.lunch: return Icons.lunch_dining_outlined;
      case MealType.dinner: return Icons.dinner_dining_outlined;
      case MealType.snack: return Icons.fastfood_outlined; // Or Icons.cake_outlined etc.
    }
  }
}