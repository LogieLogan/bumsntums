// lib/features/workouts/widgets/execution/rest_period_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/exercise.dart';
import '../../providers/workout_execution_provider.dart';
import 'rest_timer.dart';
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

  @override
  Widget build(BuildContext context) {
    final nextExercise = widget.state.nextExercise;

    print(
      "RestPeriodWidget build: isInRestPeriod=${widget.state.isInRestPeriod}, " +
          "currentExercise=${widget.state.currentExercise.name}, " +
          "nextExercise=${nextExercise?.name ?? 'None'}",
    );

    if (nextExercise == null) {
      print("RestPeriodWidget warning: nextExercise is null!");
      return const SizedBox.shrink();
    }

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
}
