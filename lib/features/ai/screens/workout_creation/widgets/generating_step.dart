// lib/features/ai/screens/workout_creation/widgets/generating_step.dart
import 'package:flutter/material.dart';
import '../../../../../shared/theme/color_palette.dart';
import '../../../../../shared/theme/text_styles.dart';
import '../../../../../features/workouts/models/workout.dart';

class GeneratingStep extends StatelessWidget {
  final WorkoutCategory selectedCategory;

  const GeneratingStep({
    Key? key,
    required this.selectedCategory,
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
      children: [
        const SizedBox(height: 40),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Custom animation for workout generation
              SizedBox(
                height: 100,
                width: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer rotating circle
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 2 * 3.14159),
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return Transform.rotate(angle: value, child: child);
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.salmon.withOpacity(0.3),
                            width: 8,
                          ),
                        ),
                      ),
                    ),
                    // Inner pulsing circle
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.2),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: Icon(
                        Icons.fitness_center,
                        color: AppColors.salmon,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Creating Your Personalized Workout',
                style: AppTextStyles.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Designing the perfect ${_getCategoryDisplayName(selectedCategory)} workout just for you...',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}