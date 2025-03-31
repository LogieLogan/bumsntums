// lib/features/ai/screens/workout_creation/widgets/category_selection_step.dart
import 'package:flutter/material.dart';
import '../../../../../shared/theme/color_palette.dart';
import '../../../../../shared/theme/text_styles.dart';
import '../../../../../shared/components/buttons/primary_button.dart';
import '../../../../../features/workouts/models/workout.dart';

class CategorySelectionStep extends StatelessWidget {
  final WorkoutCategory selectedCategory;
  final Function(WorkoutCategory) onCategorySelected;

  const CategorySelectionStep({
    Key? key,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What would you like to focus on today?', style: AppTextStyles.h3),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildCategoryCard(
              title: 'Bums',
              icon: Icons.fitness_center,
              color: AppColors.salmon,
              category: WorkoutCategory.bums,
            ),
            _buildCategoryCard(
              title: 'Tums',
              icon: Icons.accessibility_new,
              color: AppColors.popCoral,
              category: WorkoutCategory.tums,
            ),
            _buildCategoryCard(
              title: 'Full Body',
              icon: Icons.sports_gymnastics,
              color: AppColors.popBlue,
              category: WorkoutCategory.fullBody,
            ),
            _buildCategoryCard(
              title: 'Cardio',
              icon: Icons.directions_run,
              color: AppColors.popTurquoise,
              category: WorkoutCategory.cardio,
            ),
            _buildCategoryCard(
              title: 'Quick',
              icon: Icons.timer,
              color: AppColors.popGreen,
              category: WorkoutCategory.quickWorkout,
            ),
          ],
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          text: 'Continue',
          onPressed: () {
            // If nothing is selected yet, select the first option
            if (selectedCategory == null) {
              onCategorySelected(WorkoutCategory.fullBody);
            } else {
              onCategorySelected(selectedCategory);
            }
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required Color color,
    required WorkoutCategory category,
  }) {
    final isSelected = selectedCategory == category;
    return InkWell(
      onTap: () => onCategorySelected(category),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(isSelected ? 0.9 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: isSelected ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}