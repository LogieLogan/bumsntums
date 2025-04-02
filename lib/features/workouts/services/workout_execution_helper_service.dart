// lib/features/workouts/services/workout_execution_helper_service.dart
// Update the typedef and methods that use it

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../models/workout_log.dart';
import '../providers/workout_execution_provider.dart';
import '../widgets/execution/exercise_info_sheet.dart';
import '../widgets/execution/exit_confirmation_dialog.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

class WorkoutExecutionHelperService {
  final AnalyticsService _analytics = AnalyticsService();
  
  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  void showExerciseInfoSheet(BuildContext context, Exercise exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return ExerciseInfoSheet(exercise: exercise);
      },
    );
  }
  
  void confirmExit(
    BuildContext context, 
    WidgetRef ref,
    VoidCallback onExit,
  ) {
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      builder: (context) => ExitConfirmationDialog(
        onContinue: () => Navigator.of(context).pop(),
        onExit: () {
          Navigator.of(context).pop();
          ref.read(workoutExecutionProvider.notifier).cancelWorkout();
          onExit();
        },
      ),
    );
    
    _analytics.logEvent(
      name: 'workout_exit_dialog_shown',
      parameters: {
        'workout_id': ref.read(workoutExecutionProvider)?.workout.id ?? '',
      },
    );
  }
  
  void logExerciseCompletion({
    required WidgetRef ref,
    required int elapsedTimeSeconds,
    required bool showAnimation,
    required Function(bool) setShowAnimation,
    required VoidCallback completeWorkout,
  }) {
    HapticFeedback.mediumImpact();

    final state = ref.read(workoutExecutionProvider);
    if (state == null) return;

    final currentExercise = state.currentExercise;
    final currentExerciseIndex = state.currentExerciseIndex;

    if (!state.completedExercises.containsKey(currentExerciseIndex)) {
      ref
          .read(workoutExecutionProvider.notifier)
          .logExerciseCompletion(
            currentExerciseIndex,
            ExerciseLog(
              exerciseName: currentExercise.name,
              setsCompleted: currentExercise.sets,
              repsCompleted: currentExercise.reps,
              difficultyRating: 3,
            ),
          );
          
      _analytics.logEvent(
        name: 'exercise_completed',
        parameters: {
          'workout_id': state.workout.id,
          'exercise_name': currentExercise.name,
          'exercise_index': currentExerciseIndex,
          'elapsed_time': elapsedTimeSeconds,
        },
      );
    }

    setShowAnimation(true);

    Future.delayed(const Duration(seconds: 2), () {
      setShowAnimation(false);

      if (state.isLastExercise) {
        completeWorkout();
      } else {
        ref
            .read(workoutExecutionProvider.notifier)
            .startRestPeriod(
              state.currentExercise.restBetweenSeconds > 0
                  ? state.currentExercise.restBetweenSeconds
                  : 30,
            );
      }
    });
  }
}

// Remove the specialized typedef since we're using the standard WidgetRef now
final workoutExecutionHelperProvider = Provider<WorkoutExecutionHelperService>((ref) {
  return WorkoutExecutionHelperService();
});