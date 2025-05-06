// lib/features/nutrition/widgets/food_log_entry_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/food_log_entry.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';

class FoodLogEntryTile extends StatelessWidget {
  final FoodLogEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onDelete; // Callback for when item is dismissed

  const FoodLogEntryTile({
    super.key,
    required this.entry,
    this.onTap,
    this.onDelete, // Accept the onDelete callback
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat("#,##0");

    // --- Wrap ListTile with Dismissible ---
    return Dismissible(
      key: Key(entry.id), // Unique key for each item
      direction: DismissDirection.endToStart, // Swipe from right to left
      onDismissed: (direction) {
        // Call the onDelete callback when dismissed
        onDelete?.call();
      },
      background: Container(
        color: AppColors.error.withOpacity(0.8), // Or a suitable red color
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
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
      ),
    );
    // --- End Dismissible Wrapper ---
  }

  IconData _getMealIcon(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast: return Icons.free_breakfast_outlined;
      case MealType.lunch: return Icons.lunch_dining_outlined;
      case MealType.dinner: return Icons.dinner_dining_outlined;
      case MealType.snack: return Icons.fastfood_outlined;
    }
  }
}