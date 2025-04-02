// lib/features/workouts/widgets/execution/set_rest_period_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/workout_execution_provider.dart';
import 'set_rest_timer.dart';

class SetRestPeriodWidget extends ConsumerWidget {
  final WorkoutExecutionState state;

  const SetRestPeriodWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentExercise = state.currentExercise;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Rest timer
          Expanded(
            child: SetRestTimer(
              durationSeconds: state.setRestTimeRemaining,
              isPaused: state.isPaused,
              currentSet: state.currentSet,
              totalSets: currentExercise.sets,
              onComplete: () {
                ref.read(workoutExecutionProvider.notifier).endSetRestPeriod();
              },
              onAddTime: () => ref.read(workoutExecutionProvider.notifier).adjustSetRestTime(15),
              onReduceTime: () => ref.read(workoutExecutionProvider.notifier).adjustSetRestTime(-15, minimum: 5),
            ),
          ),
        ],
      ),
    );
  }
}