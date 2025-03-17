// lib/features/workouts/widgets/category_card.dart
import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../../../shared/theme/color_palette.dart';

class CategoryCard extends StatelessWidget {
  final WorkoutCategory category;
  final VoidCallback onTap;
  
  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 120,
        decoration: BoxDecoration(
          color: getCategoryColor(category),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              getCategoryIcon(category),
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              getCategoryText(category),
              style: textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData getCategoryIcon(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.bums:
        return Icons.accessibility_new;
      case WorkoutCategory.tums:
        return Icons.fitness_center;
      case WorkoutCategory.fullBody:
        return Icons.model_training;
      case WorkoutCategory.cardio:
        return Icons.directions_run;
      case WorkoutCategory.quickWorkout:
        return Icons.timer;
    }
  }

  String getCategoryText(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.bums:
        return 'Bums';
      case WorkoutCategory.tums:
        return 'Tums';
      case WorkoutCategory.fullBody:
        return 'Full Body';
      case WorkoutCategory.cardio:
        return 'Cardio';
      case WorkoutCategory.quickWorkout:
        return 'Quick';
    }
  }

  Color getCategoryColor(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.bums:
        return AppColors.salmon;
      case WorkoutCategory.tums:
        return AppColors.popTurquoise;
      case WorkoutCategory.fullBody:
        return AppColors.popBlue;
      case WorkoutCategory.cardio:
        return AppColors.popCoral;
      case WorkoutCategory.quickWorkout:
        return AppColors.popYellow.withOpacity(0.8);
    }
  }
}