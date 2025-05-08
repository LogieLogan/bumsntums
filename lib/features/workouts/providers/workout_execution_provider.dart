// lib/features/workouts/providers/workout_execution_provider.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/workout_log.dart';

// Provider for the execution state
final workoutExecutionProvider =
    StateNotifierProvider<WorkoutExecutionNotifier, WorkoutExecutionState>(
      (ref) => WorkoutExecutionNotifier(analyticsService: AnalyticsService()),
    );

// Enum to represent the current state of workout execution
enum ExecutionStatus {
  initial,
  ready,
  exerciseInProgress,
  betweenSets,
  restingBetweenExercises,
  completed,
  paused,
}

// State class that holds all workout execution data
class WorkoutExecutionState {
  final ExecutionStatus status;
  final Workout workout;
  final int currentSectionIndex;
  final int currentExerciseIndex;
  final int currentSetIndex;
  final Exercise? currentExercise;
  final DateTime startTime;
  final Duration elapsedTime;
  final bool voiceGuidanceEnabled;
  final bool showRestTimers;
  final bool showCountdowns;
  final List<ExerciseLog> completedExerciseLogs;
  final bool isPaused;
  final int? remainingRestSeconds;
  final int? remainingExerciseSeconds;

  const WorkoutExecutionState({
    this.status = ExecutionStatus.initial,
    required this.workout,
    this.currentSectionIndex = 0,
    this.currentExerciseIndex = 0,
    this.currentSetIndex = 0,
    this.currentExercise,
    required this.startTime,
    this.elapsedTime = Duration.zero,
    this.voiceGuidanceEnabled = true,
    this.showRestTimers = true,
    this.showCountdowns = true,
    this.completedExerciseLogs = const [],
    this.isPaused = false,
    this.remainingRestSeconds,
    this.remainingExerciseSeconds,
  });

  // Calculate progress percentage through the workout
  double get progressPercentage {
    final totalExercises = workout.getAllExercises().length;
    final totalSets = workout.getAllExercises().fold<int>(
      0,
      (sum, exercise) => sum + exercise.sets,
    );

    int completedSets = 0;

    // Count completed sets from previous exercises
    if (workout.sections.isNotEmpty) {
      for (int s = 0; s < currentSectionIndex; s++) {
        for (final exercise in workout.sections[s].exercises) {
          completedSets += exercise.sets;
        }
      }

      // Count completed sets in current section
      for (int e = 0; e < currentExerciseIndex; e++) {
        completedSets +=
            workout.sections[currentSectionIndex].exercises[e].sets;
      }
    } else {
      // Legacy workout with no sections
      for (int e = 0; e < currentExerciseIndex; e++) {
        completedSets += workout.exercises[e].sets;
      }
    }

    // Add current exercise's completed sets
    completedSets += currentSetIndex;

    return totalSets > 0 ? completedSets / totalSets : 0;
  }

  // Get the next exercise (or null if we're at the end)
  Exercise? get nextExercise {
    if (workout.sections.isNotEmpty) {
      // Workouts with sections
      if (currentExerciseIndex <
          workout.sections[currentSectionIndex].exercises.length - 1) {
        // Next exercise in the same section
        return workout
            .sections[currentSectionIndex]
            .exercises[currentExerciseIndex + 1];
      } else if (currentSectionIndex < workout.sections.length - 1) {
        // First exercise in the next section
        return workout.sections[currentSectionIndex + 1].exercises[0];
      }
    } else {
      // Legacy workouts without sections
      if (currentExerciseIndex < workout.exercises.length - 1) {
        return workout.exercises[currentExerciseIndex + 1];
      }
    }
    return null;
  }

  // Factory method to create the initial state
  factory WorkoutExecutionState.initial(Workout workout) {
    final initialExercise =
        workout.sections.isNotEmpty
            ? workout.sections[0].exercises[0]
            : workout.exercises[0];

    return WorkoutExecutionState(
      status: ExecutionStatus.initial,
      workout: workout,
      currentExercise: initialExercise,
      startTime: DateTime.now(),
    );
  }

  // Create a copy with updated properties
  WorkoutExecutionState copyWith({
    ExecutionStatus? status,
    Workout? workout,
    int? currentSectionIndex,
    int? currentExerciseIndex,
    int? currentSetIndex,
    Exercise? currentExercise,
    DateTime? startTime,
    Duration? elapsedTime,
    bool? voiceGuidanceEnabled,
    bool? showRestTimers,
    bool? showCountdowns,
    List<ExerciseLog>? completedExerciseLogs,
    bool? isPaused,
    int? remainingRestSeconds,
    int? remainingExerciseSeconds,
  }) {
    return WorkoutExecutionState(
      status: status ?? this.status,
      workout: workout ?? this.workout,
      currentSectionIndex: currentSectionIndex ?? this.currentSectionIndex,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      currentExercise: currentExercise ?? this.currentExercise,
      startTime: startTime ?? this.startTime,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      voiceGuidanceEnabled: voiceGuidanceEnabled ?? this.voiceGuidanceEnabled,
      showRestTimers: showRestTimers ?? this.showRestTimers,
      showCountdowns: showCountdowns ?? this.showCountdowns,
      completedExerciseLogs:
          completedExerciseLogs ?? this.completedExerciseLogs,
      isPaused: isPaused ?? this.isPaused,
      remainingRestSeconds: remainingRestSeconds ?? this.remainingRestSeconds,
      remainingExerciseSeconds:
          remainingExerciseSeconds ?? this.remainingExerciseSeconds,
    );
  }
}

// State notifier that manages the workout execution state
class WorkoutExecutionNotifier extends StateNotifier<WorkoutExecutionState> {
  final AnalyticsService analyticsService;
  Timer? _workoutTimer;
  DateTime? _pauseStartTime;

  WorkoutExecutionNotifier({required this.analyticsService})
    : super(
        WorkoutExecutionState(
          workout: Workout(
            id: '',
            title: '',
            description: '',
            imageUrl: '',
            category: WorkoutCategory.fullBody,
            difficulty: WorkoutDifficulty.beginner,
            durationMinutes: 0,
            estimatedCaloriesBurn: 0,
            createdAt: DateTime.now(),
            createdBy: '',
            exercises: const [],
            equipment: const [],
            tags: const [],
          ),
          startTime: DateTime.now(),
        ),
      );

  // Start a new workout
  void startWorkout(
    Workout workout, {
    bool voiceGuidanceEnabled = true,
    bool showRestTimers = true,
    bool showCountdowns = true,
  }) {
    // Initialize with the first exercise
    final firstExercise =
        workout.sections.isNotEmpty
            ? workout.sections[0].exercises[0]
            : workout.exercises[0];

    // Set the initial state
    state = WorkoutExecutionState(
      status: ExecutionStatus.ready,
      workout: workout,
      currentExercise: firstExercise,
      startTime: DateTime.now(),
      voiceGuidanceEnabled: voiceGuidanceEnabled,
      showRestTimers: showRestTimers,
      showCountdowns: showCountdowns,
    );

    // Log analytics event
    analyticsService.logWorkoutStarted(
      workoutId: workout.id,
      workoutName: workout.title,
    );

    // Start the workout timer
    _startTimer();

    // Start the first exercise
    startExercise();
  }

  // Start the current exercise
  void startExercise() {
    if (state.currentExercise == null) return;

    // Update state to exercise in progress
    state = state.copyWith(
      status: ExecutionStatus.exerciseInProgress,
      remainingExerciseSeconds: state.currentExercise!.durationSeconds,
    );
    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Log analytics
    analyticsService.logEvent(
      name: 'exercise_started',
      parameters: {
        'exercise_name': state.currentExercise!.name,
        'set_number': state.currentSetIndex + 1,
      },
    );
  }

  // Complete the current set
  void completeSet() {
    final exercise = state.currentExercise!;
    final isLastSet = state.currentSetIndex >= exercise.sets - 1;

    if (isLastSet) {
      _completeExercise();
    } else {
      // Move to the next set
      state = state.copyWith(
        status: ExecutionStatus.betweenSets,
        currentSetIndex: state.currentSetIndex + 1,
        remainingRestSeconds: exercise.restBetweenSeconds,
      );

      // Haptic feedback
      HapticFeedback.mediumImpact();

      // Log analytics
      analyticsService.logEvent(
        name: 'set_completed',
        parameters: {
          'exercise_name': exercise.name,
          'set_number': state.currentSetIndex,
          'is_last_set': false,
        },
      );
    }
  }

  // Complete the current exercise and move to the next
  void _completeExercise() {
    final currentExercise = state.currentExercise!;

    final exerciseLog = ExerciseLog(
      exerciseName: currentExercise.name,
      setsCompleted: state.currentSetIndex + 1,
      repsCompleted: List.filled(
        state.currentSetIndex + 1,
        currentExercise.reps,
      ),
      weightUsed: List.filled(
        state.currentSetIndex + 1,
        currentExercise.weight,
      ),
      duration:
          currentExercise.durationSeconds != null
              ? List.filled(
                state.currentSetIndex + 1,
                Duration(seconds: currentExercise.durationSeconds!),
              )
              : [],
      distance: currentExercise.tempo?['distance'] as double?,
      speed: currentExercise.tempo?['speed'] as double?,
      difficultyRating: currentExercise.difficultyLevel,
      targetMuscles: currentExercise.targetMuscles,
    );

    final updatedLogs = List<ExerciseLog>.from(state.completedExerciseLogs)
      ..add(exerciseLog);

    bool isLastExercise = false;
    int nextSectionIndex = state.currentSectionIndex;
    int nextExerciseIndex = state.currentExerciseIndex;

    if (state.workout.sections.isNotEmpty) {
      final currentSection = state.workout.sections[state.currentSectionIndex];

      if (state.currentExerciseIndex < currentSection.exercises.length - 1) {
        nextExerciseIndex = state.currentExerciseIndex + 1;
      } else if (state.currentSectionIndex <
          state.workout.sections.length - 1) {
        nextSectionIndex = state.currentSectionIndex + 1;
        nextExerciseIndex = 0;
      } else {
        isLastExercise = true;
      }
    } else {
      if (state.currentExerciseIndex < state.workout.exercises.length - 1) {
        nextExerciseIndex = state.currentExerciseIndex + 1;
      } else {
        isLastExercise = true;
      }
    }

    if (isLastExercise) {
      _completeWorkout(updatedLogs);
    } else {
      final nextExercise =
          state.workout.sections.isNotEmpty
              ? state
                  .workout
                  .sections[nextSectionIndex]
                  .exercises[nextExerciseIndex]
              : state.workout.exercises[nextExerciseIndex];

      state = state.copyWith(
        status: ExecutionStatus.restingBetweenExercises,
        completedExerciseLogs: updatedLogs,
        currentSectionIndex: nextSectionIndex,
        currentExerciseIndex: nextExerciseIndex,
        currentSetIndex: 0,
        currentExercise: nextExercise,
        remainingRestSeconds: 30,
      );

      HapticFeedback.heavyImpact();

      analyticsService.logEvent(
        name: 'exercise_completed',
        parameters: {
          'exercise_name': currentExercise.name,
          'next_exercise': nextExercise.name,
        },
      );
    }
  }

  // Complete the entire workout
  void _completeWorkout(List<ExerciseLog> exerciseLogs) {
    // Calculate total duration
    final endTime = DateTime.now();
    final durationMinutes = endTime.difference(state.startTime).inMinutes;

    // Update state
    state = state.copyWith(
      status: ExecutionStatus.completed,
      completedExerciseLogs: exerciseLogs,
      elapsedTime: endTime.difference(state.startTime),
    );

    // Haptic feedback
    HapticFeedback.heavyImpact();

    // Stop the timer
    _workoutTimer?.cancel();

    // Log analytics
    analyticsService.logWorkoutCompleted(
      workoutId: state.workout.id,
      workoutName: state.workout.title,
      durationSeconds: state.elapsedTime.inSeconds,
    );
  }

  // Pause the workout
  void pauseWorkout() {
    if (state.isPaused) return;

    _pauseStartTime = DateTime.now();
    _workoutTimer?.cancel();

    state = state.copyWith(isPaused: true, status: ExecutionStatus.paused);

    // Log analytics
    analyticsService.logEvent(
      name: 'workout_paused',
      parameters: {
        'elapsed_time': state.elapsedTime.inSeconds,
        'current_exercise': state.currentExercise?.name ?? 'unknown',
      },
    );
  }

  // Resume the workout
  void resumeWorkout() {
    if (!state.isPaused) return;

    final pauseDuration = DateTime.now().difference(_pauseStartTime!);
    _pauseStartTime = null;

    // Adjust the start time to account for the pause
    final adjustedStartTime = state.startTime.add(pauseDuration);

    state = state.copyWith(
      isPaused: false,
      startTime: adjustedStartTime,
      status:
          state.status == ExecutionStatus.paused
              ? ExecutionStatus.exerciseInProgress
              : state.status,
    );

    // Restart the timer
    _startTimer();

    // Log analytics
    analyticsService.logEvent(
      name: 'workout_resumed',
      parameters: {'pause_duration_seconds': pauseDuration.inSeconds},
    );
  }

  // Skip the current rest period
  void skipRest() {
    if (state.status == ExecutionStatus.betweenSets) {
      // If between sets, start the next set
      startExercise();
    } else if (state.status == ExecutionStatus.restingBetweenExercises) {
      // If between exercises, start the next exercise
      startExercise();
    }

    // Log analytics
    analyticsService.logEvent(
      name: 'rest_skipped',
      parameters: {
        'rest_type':
            state.status == ExecutionStatus.betweenSets
                ? 'between_sets'
                : 'between_exercises',
      },
    );
  }

  // Adjust the rest time
  void adjustRestTime(int seconds) {
    if (state.status != ExecutionStatus.betweenSets &&
        state.status != ExecutionStatus.restingBetweenExercises) {
      return;
    }

    int newRestTime = (state.remainingRestSeconds ?? 0) + seconds;

    // Ensure rest time is at least 0
    newRestTime = newRestTime < 0 ? 0 : newRestTime;

    state = state.copyWith(remainingRestSeconds: newRestTime);

    // Log analytics
    analyticsService.logEvent(
      name: 'rest_time_adjusted',
      parameters: {'adjustment_seconds': seconds, 'new_rest_time': newRestTime},
    );
  }

  // Start the workout timer
  void _startTimer() {
    _workoutTimer?.cancel();
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Skip if paused
      if (state.isPaused) return;

      // Update the elapsed time
      final newElapsedTime = DateTime.now().difference(state.startTime);

      // Handle timed exercises
      int? updatedExerciseSeconds;
      if (state.status == ExecutionStatus.exerciseInProgress &&
          state.currentExercise?.durationSeconds != null &&
          state.remainingExerciseSeconds != null) {
        updatedExerciseSeconds = state.remainingExerciseSeconds! - 1;

        // If exercise timer reaches zero, complete the set
        if (updatedExerciseSeconds <= 0) {
          timer.cancel();
          completeSet();
          return;
        }
      }

      // Handle rest periods
      int? updatedRestSeconds;
      if ((state.status == ExecutionStatus.betweenSets ||
              state.status == ExecutionStatus.restingBetweenExercises) &&
          state.remainingRestSeconds != null) {
        updatedRestSeconds = state.remainingRestSeconds! - 1;

        // If rest timer reaches zero, move to the next exercise/set
        if (updatedRestSeconds <= 0) {
          timer.cancel();
          startExercise();
          return;
        }
      }

      // Update the state
      state = state.copyWith(
        elapsedTime: newElapsedTime,
        remainingExerciseSeconds: updatedExerciseSeconds,
        remainingRestSeconds: updatedRestSeconds,
      );
    });
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    super.dispose();
  }
}
