// lib/features/ai/screens/workout_creation/widgets/duration_selection_step.dart
import 'package:flutter/material.dart';
import '../../../../../shared/theme/color_palette.dart';
import '../../../../../shared/theme/text_styles.dart';
import '../../../../../shared/components/buttons/primary_button.dart';
import '../../../../../shared/components/buttons/secondary_button.dart';
import '../../../../../features/workouts/models/workout.dart';

class DurationSelectionStep extends StatelessWidget {
  final int selectedDuration;
  final WorkoutCategory selectedCategory;
  final Function(int) onDurationSelected;
  final VoidCallback onBack;

  const DurationSelectionStep({
    Key? key,
    required this.selectedDuration,
    required this.selectedCategory,
    required this.onDurationSelected,
    required this.onBack,
  }) : super(key: key);

  String _getCategoryDisplayName(WorkoutCategory category) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Great choice! How long should your ${_getCategoryDisplayName(selectedCategory)} workout be?',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 20),
        Text('Select workout duration in minutes:', style: AppTextStyles.body),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [10, 15, 20, 30, 45, 60].map((duration) {
            final isSelected = selectedDuration == duration;
            return InkWell(
              onTap: () => onDurationSelected(duration),
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.salmon : Colors.grey.withOpacity(0.1),
                  border: Border.all(
                    color: isSelected ? AppColors.salmon : Colors.grey.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$duration',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.darkGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                text: 'Back',
                onPressed: onBack,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                text: 'Continue',
                onPressed: () => onDurationSelected(selectedDuration),
              ),
            ),
          ],
        ),
      ],
    );
  }
}