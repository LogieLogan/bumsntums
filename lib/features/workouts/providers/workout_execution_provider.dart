// lib/features/workouts/providers/workout_execution_provider.dart
import 'package:bums_n_tums/features/workouts/models/exercise.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/workout.dart';
import '../models/workout_log.dart';
import '../services/workout_service.dart';
import 'workout_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Workout execution state
class WorkoutExecutionState {
  final Workout workout;
  final int currentExerciseIndex;
  final bool isPaused;
  final DateTime startTime;
  final int elapsedTimeSeconds;
  final Map<int, ExerciseLog> completedExercises; // Maps exercise index to log

  WorkoutExecutionState({
    required this.workout,
    this.currentExerciseIndex = 0,
    this.isPaused = false,
    required this.startTime,
    this.elapsedTimeSeconds = 0,
    this.completedExercises = const {},
  });

  bool get isFirstExercise => currentExerciseIndex == 0;

  bool get isLastExercise =>
      currentExerciseIndex == workout.exercises.length - 1;

  Exercise get currentExercise => workout.exercises[currentExerciseIndex];

  Exercise? get nextExercise =>
      isLastExercise ? null : workout.exercises[currentExerciseIndex + 1];

  int get completedExercisesCount => completedExercises.length;

  double get progressPercentage =>
      workout.exercises.isEmpty
          ? 0
          : completedExercisesCount / workout.exercises.length;

  WorkoutExecutionState copyWith({
    Workout? workout,
    int? currentExerciseIndex,
    bool? isPaused,
    DateTime? startTime,
    int? elapsedTimeSeconds,
    Map<int, ExerciseLog>? completedExercises,
  }) {
    return WorkoutExecutionState(
      workout: workout ?? this.workout,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      isPaused: isPaused ?? this.isPaused,
      startTime: startTime ?? this.startTime,
      elapsedTimeSeconds: elapsedTimeSeconds ?? this.elapsedTimeSeconds,
      completedExercises: completedExercises ?? this.completedExercises,
    );
  }
}

class WorkoutExecutionNotifier extends StateNotifier<WorkoutExecutionState?> {
  final WorkoutService _workoutService;

  WorkoutExecutionNotifier(this._workoutService) : super(null);

  // Start workout
  void startWorkout(Workout workout) {
    state = WorkoutExecutionState(workout: workout, startTime: DateTime.now());
  }

  // Move to next exercise
  void nextExercise() {
    if (state == null || state!.isLastExercise) return;

    state = state!.copyWith(
      currentExerciseIndex: state!.currentExerciseIndex + 1,
    );
  }

  // Previous exercise
  void previousExercise() {
    if (state == null || state!.isFirstExercise) return;

    state = state!.copyWith(
      currentExerciseIndex: state!.currentExerciseIndex - 1,
    );
  }

  // Pause workout
  void pauseWorkout() {
    if (state == null) return;

    state = state!.copyWith(isPaused: true);
  }

  // Resume workout
  void resumeWorkout() {
    if (state == null) return;

    state = state!.copyWith(isPaused: false);
  }

  // Update elapsed time
  void updateElapsedTime(int seconds) {
    if (state == null) return;

    state = state!.copyWith(elapsedTimeSeconds: seconds);
  }

  // Log exercise completion
  void logExerciseCompletion(int exerciseIndex, ExerciseLog log) {
    if (state == null) return;

    final updatedCompleted = Map<int, ExerciseLog>.from(
      state!.completedExercises,
    );
    updatedCompleted[exerciseIndex] = log;

    state = state!.copyWith(completedExercises: updatedCompleted);
  }

  Future<void> completeWorkout({
    required UserFeedback feedback,
    int? estimatedCaloriesBurned, required String userId,
  }) async {
    if (state == null) return;

    // Get the current user ID
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return; // User is not authenticated

    final endTime = DateTime.now();
    final durationMinutes = endTime.difference(state!.startTime).inMinutes;
    final workoutLog = WorkoutLog(
      id: const Uuid().v4(),
      userId: userId, // Use the actual user ID
      workoutId: state!.workout.id,
      startedAt: state!.startTime,
      completedAt: endTime,
      durationMinutes: durationMinutes,
      caloriesBurned:
          estimatedCaloriesBurned ?? state!.workout.estimatedCaloriesBurn,
      exercisesCompleted: state!.completedExercises.values.toList(),
      userFeedback: feedback,
    );

    await _workoutService.logCompletedWorkout(workoutLog);

    // Reset state after completion
    state = null;
  }

  // Cancel workout
  void cancelWorkout() {
    state = null;
  }
}

final workoutExecutionProvider =
    StateNotifierProvider<WorkoutExecutionNotifier, WorkoutExecutionState?>((
      ref,
    ) {
      final workoutService = ref.watch(workoutServiceProvider);
      return WorkoutExecutionNotifier(workoutService);
    });
