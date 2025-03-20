// lib/features/workouts/providers/workout_execution_provider.dart
import 'package:bums_n_tums/features/workouts/models/exercise.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/workout.dart';
import '../models/workout_log.dart';
import '../services/workout_service.dart';
import 'workout_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/voice_guidance_service.dart';

// Workout execution state
class WorkoutExecutionState {
  final Workout workout;
  final int currentExerciseIndex;
  final bool isPaused;
  final DateTime startTime;
  final int elapsedTimeSeconds;
  final Map<int, ExerciseLog> completedExercises;
  final bool isInRestPeriod;
  final int restTimeRemaining;
  final bool voiceGuidanceEnabled;

  WorkoutExecutionState({
    required this.workout,
    this.currentExerciseIndex = 0,
    this.isPaused = false,
    required this.startTime,
    this.elapsedTimeSeconds = 0,
    this.completedExercises = const {},
    this.isInRestPeriod = false,
    this.restTimeRemaining = 0,
    this.voiceGuidanceEnabled = true,
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
    bool? isInRestPeriod,
    int? restTimeRemaining,
    bool? voiceGuidanceEnabled,
  }) {
    return WorkoutExecutionState(
      workout: workout ?? this.workout,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      isPaused: isPaused ?? this.isPaused,
      startTime: startTime ?? this.startTime,
      elapsedTimeSeconds: elapsedTimeSeconds ?? this.elapsedTimeSeconds,
      completedExercises: completedExercises ?? this.completedExercises,
      isInRestPeriod: isInRestPeriod ?? this.isInRestPeriod,
      restTimeRemaining: restTimeRemaining ?? this.restTimeRemaining,
      voiceGuidanceEnabled: voiceGuidanceEnabled ?? this.voiceGuidanceEnabled,
    );
  }
}

class WorkoutExecutionNotifier extends StateNotifier<WorkoutExecutionState?> {
  final WorkoutService _workoutService;
  final VoiceGuidanceService _voiceGuidance;

  WorkoutExecutionNotifier(this._workoutService, this._voiceGuidance)
    : super(null) {
    _initializeVoiceGuidance();
  }

  Future<void> _initializeVoiceGuidance() async {
    await _voiceGuidance.initialize();
  }

  // Update startWorkout method to announce first exercise
  void startWorkout(Workout workout) {
    state = WorkoutExecutionState(workout: workout, startTime: DateTime.now());

    // Announce first exercise with a small delay to allow UI to build
    Future.delayed(const Duration(milliseconds: 500), () {
      final exercise = workout.exercises.first;
      if (exercise.durationSeconds != null) {
        _voiceGuidance.announceTimedExercise(
          exercise.name,
          exercise.durationSeconds!,
        );
      } else {
        _voiceGuidance.announceExerciseStart(
          exercise.name,
          exercise.sets,
          exercise.reps,
        );
      }
    });
  }

  void updateElapsedTime(int seconds) {
    if (state == null) return;

    state = state!.copyWith(elapsedTimeSeconds: seconds);
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

  // Log exercise completion
  void logExerciseCompletion(int exerciseIndex, ExerciseLog log) {
    if (state == null) return;

    final updatedCompleted = Map<int, ExerciseLog>.from(
      state!.completedExercises,
    );
    updatedCompleted[exerciseIndex] = log;

    state = state!.copyWith(completedExercises: updatedCompleted);
  }

  // Add method to start rest period
  void startRestPeriod(int seconds) {
    if (state == null) return;

    state = state!.copyWith(isInRestPeriod: true, restTimeRemaining: seconds);
  }

  // Add method to end rest period
  void endRestPeriod() {
    if (state == null) return;

    state = state!.copyWith(isInRestPeriod: false, restTimeRemaining: 0);

    // If not the last exercise, move to the next exercise
    if (!state!.isLastExercise) {
      nextExercise();
    }
  }

  // Update next exercise method to announce the exercise
  void nextExercise() {
    if (state == null || state!.isLastExercise) return;

    state = state!.copyWith(
      currentExerciseIndex: state!.currentExerciseIndex + 1,
    );

    // Announce the new exercise
    if (state!.voiceGuidanceEnabled) {
      final exercise = state!.currentExercise;
      if (exercise.durationSeconds != null) {
        _voiceGuidance.announceTimedExercise(
          exercise.name,
          exercise.durationSeconds!,
        );
      } else {
        _voiceGuidance.announceExerciseStart(
          exercise.name,
          exercise.sets,
          exercise.reps,
        );
      }
    }
  }

  // Add method to toggle voice guidance
  void toggleVoiceGuidance(bool enabled) {
    if (state == null) return;

    state = state!.copyWith(voiceGuidanceEnabled: enabled);
    _voiceGuidance.setEnabled(enabled);
  }

  void cancelWorkout() {
    state = null;
  }

  // Update the complete workout method
  Future<void> completeWorkout({
    required UserFeedback feedback,
    int? estimatedCaloriesBurned,
    required String userId,
  }) async {
    if (state == null) return;

    // Announce workout completion if voice guidance is enabled
    if (state!.voiceGuidanceEnabled) {
      await _voiceGuidance.announceWorkoutComplete();
    }

    // (existing implementation)
  }
}

// Update provider
final workoutExecutionProvider =
    StateNotifierProvider<WorkoutExecutionNotifier, WorkoutExecutionState?>((
      ref,
    ) {
      final workoutService = ref.watch(workoutServiceProvider);
      final voiceGuidance = VoiceGuidanceService(); // Create instance
      return WorkoutExecutionNotifier(workoutService, voiceGuidance);
    });

// Add voice guidance provider
final voiceGuidanceProvider = Provider<VoiceGuidanceService>((ref) {
  final voiceGuidance = VoiceGuidanceService();
  voiceGuidance.initialize();
  return voiceGuidance;
});
