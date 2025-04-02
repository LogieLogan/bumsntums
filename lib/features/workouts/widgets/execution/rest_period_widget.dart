// lib/features/workouts/widgets/execution/rest_period_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/exercise.dart';
import '../../providers/workout_execution_provider.dart';
import 'rest_timer.dart';
import '../exercise_demo_widget.dart';
import '../../../../shared/theme/color_palette.dart';

// Convert to StatefulWidget
class RestPeriodWidget extends ConsumerStatefulWidget {
  final WorkoutExecutionState state;
  final void Function(Exercise) showExerciseInfoSheet;

  const RestPeriodWidget({
    super.key,
    required this.state,
    required this.showExerciseInfoSheet,
  });

  @override
  ConsumerState<RestPeriodWidget> createState() => _RestPeriodWidgetState();
}

class _RestPeriodWidgetState extends ConsumerState<RestPeriodWidget> {
  // State for sheet visibility
  bool _showSheet = true;

  @override
  Widget build(BuildContext context) {
    final nextExercise = widget.state.nextExercise;
    if (nextExercise == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Rest timer
          RestTimer(
            durationSeconds: widget.state.restTimeRemaining,
            isPaused: widget.state.isPaused,
            nextExerciseName: nextExercise.name,
            onComplete: () {
              ref.read(workoutExecutionProvider.notifier).endRestPeriod();
            },
            onAddTime:
                () => ref
                    .read(workoutExecutionProvider.notifier)
                    .adjustRestTime(15),
            onReduceTime:
                () => ref
                    .read(workoutExecutionProvider.notifier)
                    .adjustRestTime(-15, minimum: 5),
          ),

          const SizedBox(height: 24),

          // Coming Up Next button
          OutlinedButton.icon(
            onPressed: () => widget.showExerciseInfoSheet(nextExercise),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.salmon),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: Icon(Icons.visibility, size: 18, color: AppColors.salmon),
            label: Text(
              'Preview Next Exercise',
              style: TextStyle(
                color: AppColors.salmon,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreparationSteps(BuildContext context, Exercise exercise) {
    if (exercise.preparationSteps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How to Prepare',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.salmon,
          ),
        ),
        const SizedBox(height: 8),
        ...exercise.preparationSteps
            .take(2)
            .map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.play_arrow, size: 16, color: AppColors.salmon),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(step, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
        if (exercise.preparationSteps.length > 2)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GestureDetector(
              onTap:
                  () => widget.showExerciseInfoSheet(
                    exercise,
                  ), // Changed to widget.showExerciseInfoSheet
              child: Text(
                'See more...',
                style: TextStyle(
                  color: AppColors.popBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFormTip(BuildContext context, Exercise exercise) {
    if (exercise.formTips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.popTurquoise.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.popTurquoise.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: AppColors.popTurquoise,
              ),
              const SizedBox(width: 8),
              Text(
                'Form Tip',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.popTurquoise,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(exercise.formTips.first, style: const TextStyle(fontSize: 14)),

          // Show more link if there are additional tips
          if (exercise.formTips.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap:
                    () => widget.showExerciseInfoSheet(
                      exercise,
                    ), // Changed to widget.showExerciseInfoSheet
                child: Text(
                  'More tips...',
                  style: TextStyle(
                    color: AppColors.popBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
