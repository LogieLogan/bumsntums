// lib/features/workouts/widgets/execution/exercise_completion_animation.dart
import 'package:flutter/material.dart';
import '../../../../shared/theme/color_palette.dart';

class ExerciseCompletionAnimation extends StatelessWidget {
  final VoidCallback onAnimationComplete;

  const ExerciseCompletionAnimation({
    super.key,
    required this.onAnimationComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Using a simple animation since we're avoiding external assets
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1000),
              onEnd: onAnimationComplete,
              builder: (context, value, child) {
                return Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 100,
                          width: 100,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 8,
                            color: AppColors.popGreen,
                            backgroundColor: Colors.white30,
                          ),
                        ),
                        Icon(
                          Icons.check,
                          size: 64,
                          color: AppColors.popGreen,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Great job!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Opacity(
                      opacity: value,
                      child: Text(
                        'Moving to next exercise...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}