// lib/features/workouts/widgets/execution/workout_progress_indicator.dart
import 'package:flutter/material.dart';
import '../../../../shared/theme/color_palette.dart';

class WorkoutProgressIndicator extends StatelessWidget {
  final int currentExerciseIndex;
  final int totalExercises;
  final double progressPercentage;

  const WorkoutProgressIndicator({
    super.key,
    required this.currentExerciseIndex,
    required this.totalExercises,
    required this.progressPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Text progress indicator
        Text(
          'Exercise ${currentExerciseIndex + 1} of $totalExercises',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        
        // Linear progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressPercentage,
            backgroundColor: AppColors.paleGrey,
            color: AppColors.salmon,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}