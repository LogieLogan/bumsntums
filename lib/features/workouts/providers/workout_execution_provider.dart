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
  final bool showRestTimers;
  final bool showCountdowns;
  final int currentSet;
  final bool isInSetRestPeriod;
  final int setRestTimeRemaining;

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
    this.showRestTimers = true,
    this.showCountdowns = true,
    this.currentSet = 1,
    this.isInSetRestPeriod = false,
    this.setRestTimeRemaining = 0,
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
    bool? showRestTimers,
    bool? showCountdowns,
    int? currentSet,
    bool? isInSetRestPeriod,
    int? setRestTimeRemaining,
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
      showRestTimers: showRestTimers ?? this.showRestTimers,
      showCountdowns: showCountdowns ?? this.showCountdowns,
      currentSet: currentSet ?? this.currentSet,
      isInSetRestPeriod: isInSetRestPeriod ?? this.isInSetRestPeriod,
      setRestTimeRemaining: setRestTimeRemaining ?? this.setRestTimeRemaining,
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

  void startWorkout(
    Workout workout, {
    bool voiceGuidanceEnabled = false,
    bool showRestTimers = true,
    bool showCountdowns = true,
  }) {
    // Make sure we get exercises in the right order
    final exercises = workout.getAllExercises();

    state = WorkoutExecutionState(
      workout: workout.copyWith(
        exercises: exercises,
      ), // Ensure we have the right order
      startTime: DateTime.now(),
      voiceGuidanceEnabled: voiceGuidanceEnabled,
      showRestTimers: showRestTimers,
      showCountdowns: showCountdowns,
      currentExerciseIndex: 0,
    );

    // Announce first exercise with a small delay to allow UI to build
    if (voiceGuidanceEnabled) {
      Future.delayed(const Duration(milliseconds: 500), () {
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
      });
    }
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

  void adjustRestTime(int seconds, {int minimum = 0}) {
    if (state == null || !state!.isInRestPeriod) return;

    print(
      "Adjusting rest time by $seconds seconds. Current: ${state!.restTimeRemaining}",
    );

    int newRestTime = state!.restTimeRemaining + seconds;

    // Ensure rest time doesn't go below minimum
    if (newRestTime < minimum) newRestTime = minimum;

    print("New rest time: $newRestTime seconds");

    state = state!.copyWith(restTimeRemaining: newRestTime);
  }

  void adjustSetRestTime(int seconds, {int minimum = 0}) {
    if (state == null || !state!.isInSetRestPeriod) return;

    print(
      "Adjusting set rest time by $seconds seconds. Current: ${state!.setRestTimeRemaining}",
    );

    int newRestTime = state!.setRestTimeRemaining + seconds;

    // Ensure rest time doesn't go below minimum
    if (newRestTime < minimum) newRestTime = minimum;

    print("New set rest time: $newRestTime seconds");

    state = state!.copyWith(setRestTimeRemaining: newRestTime);
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

    print(
      "Starting rest period for ${seconds} seconds. Current exercise: ${state!.currentExercise.name}, index: ${state!.currentExerciseIndex}",
    );

    // Sanity check to ensure we don't accidentally skip exercises
    if (state!.completedExercises.length >= state!.workout.exercises.length) {
      print(
        "WARNING: All exercises appear to be completed already. This may indicate a bug.",
      );
    }

    state = state!.copyWith(isInRestPeriod: true, restTimeRemaining: seconds);

    print(
      "Rest period started. isInRestPeriod=${state!.isInRestPeriod}, restTimeRemaining=${state!.restTimeRemaining}",
    );
  }

  void endRestPeriod() {
    if (state == null) return;

    print(
      "Ending rest period. Current exercise: ${state!.currentExercise.name}, index: ${state!.currentExerciseIndex}",
    );

    // This flag will help us prevent recursive rest periods
    final wasInRestPeriod = state!.isInRestPeriod;

    // First set the rest period to false and reset rest time
    state = state!.copyWith(
      isInRestPeriod: false,
      restTimeRemaining: 0,
      currentSet: 1, // Reset to first set for the next exercise
    );

    print("Rest period ended. Moving to next exercise if not last");

    // If not the last exercise, move to the next exercise
    if (!state!.isLastExercise && wasInRestPeriod) {
      final nextIndex = state!.currentExerciseIndex + 1;
      print("Moving to next exercise index: $nextIndex");

      // Update the current exercise index
      state = state!.copyWith(currentExerciseIndex: nextIndex);

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

      print(
        "Moved to next exercise: ${state!.currentExercise.name}, index: ${state!.currentExerciseIndex}",
      );
    }
  }

  void nextExercise() {
    if (state == null || state!.isLastExercise) return;

    state = state!.copyWith(
      currentExerciseIndex: state!.currentExerciseIndex + 1,
      currentSet: 1, // Reset to the first set when moving to a new exercise
      isInSetRestPeriod: false,
      setRestTimeRemaining: 0,
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

  void completeSet() {
    if (state == null) return;

    try {
      final currentExercise = state!.currentExercise;
      final currentExerciseIndex = state!.currentExerciseIndex;
      final currentSet = state!.currentSet;

      print(
        "CompleteSet called: Exercise: ${currentExercise.name}, Set: $currentSet/${currentExercise.sets}",
      );

      // Edge case check - don't proceed if somehow already completed all sets
      if (currentSet > currentExercise.sets) {
        print(
          "Warning: Attempted to complete set beyond maximum (${currentExercise.sets})",
        );
        return;
      }

      // Update the completed sets in the exercise log
      final existingLog = state!.completedExercises[currentExerciseIndex];
      final completedSets = (existingLog?.setsCompleted ?? 0) + 1;

      logExerciseCompletion(
        currentExerciseIndex,
        ExerciseLog(
          exerciseName: currentExercise.name,
          setsCompleted:
              completedSets > currentExercise.sets
                  ? currentExercise.sets
                  : completedSets,
          repsCompleted: currentExercise.reps,
          difficultyRating: existingLog?.difficultyRating ?? 3,
          notes: existingLog?.notes ?? '',
        ),
      );

      // If there are more sets to do
      if (currentSet < currentExercise.sets) {
        // Start rest between sets if rest time > 0
        if (currentExercise.restBetweenSeconds > 0) {
          startSetRestPeriod(currentExercise.restBetweenSeconds);
        } else {
          // No rest between sets, just increment the set counter
          state = state!.copyWith(currentSet: currentSet + 1);

          // Announce next set if voice guidance is enabled
          if (state!.voiceGuidanceEnabled) {
            _voiceGuidance.speak(
              "Set ${currentSet + 1} of ${currentExercise.sets}",
            );
          }
        }
      } else {
        // All sets completed for this exercise
        print("All sets completed for ${currentExercise.name}");

        // If this is the last exercise, complete the workout
        if (state!.isLastExercise) {
          print("Last exercise completed - workout finished");
          // The completion will be handled by the UI layer
        } else {
          // Add some CRITICAL checks to prevent multiple rest periods
          if (state!.isInRestPeriod) {
            print("WARNING: Already in rest period, not starting another one");
            return;
          }

          // Start rest period before next exercise
          print("Starting rest period before next exercise");
          int restTime =
              currentExercise.restBetweenSeconds > 0
                  ? currentExercise.restBetweenSeconds
                  : 30; // Default rest period if not specified

          startRestPeriod(restTime);
        }
      }
    } catch (e, stackTrace) {
      print("Error in completeSet: $e");
      print(stackTrace);
      // Prevent crashing and ensure we can continue with the workout
    }
  }

  // Start rest period between sets
  void startSetRestPeriod(int seconds) {
    if (state == null) return;

    state = state!.copyWith(
      isInSetRestPeriod: true,
      setRestTimeRemaining: seconds,
    );

    // Announce rest period if voice guidance is enabled
    if (state!.voiceGuidanceEnabled) {
      final currentSet = state!.currentSet;
      final totalSets = state!.currentExercise.sets;
      _voiceGuidance.speak(
        "Rest for $seconds seconds. Next is set ${currentSet + 1} of $totalSets",
      );
    }
  }

  // End rest period between sets
  void endSetRestPeriod() {
    if (state == null) return;

    state = state!.copyWith(
      isInSetRestPeriod: false,
      setRestTimeRemaining: 0,
      currentSet: state!.currentSet + 1,
    );

    // Announce the next set if voice guidance is enabled
    if (state!.voiceGuidanceEnabled) {
      final currentSet = state!.currentSet;
      final totalSets = state!.currentExercise.sets;
      _voiceGuidance.speak("Set $currentSet of $totalSets");
    }
  }

  void updateExercise(int exerciseIndex, Exercise updatedExercise) {
    if (state == null) return;

    print("Updating exercise at index $exerciseIndex");
    print("Original exercise: ${state!.workout.exercises[exerciseIndex].name}");
    print(
      "Original sets: ${state!.workout.exercises[exerciseIndex].sets}, reps: ${state!.workout.exercises[exerciseIndex].reps}, duration: ${state!.workout.exercises[exerciseIndex].durationSeconds}",
    );
    print("Updated exercise: ${updatedExercise.name}");
    print(
      "Updated sets: ${updatedExercise.sets}, reps: ${updatedExercise.reps}, duration: ${updatedExercise.durationSeconds}",
    );

    // Create a new list of exercises
    final updatedExercises = List<Exercise>.from(state!.workout.exercises);
    updatedExercises[exerciseIndex] = updatedExercise;

    // Create updated workout
    final updatedWorkout = state!.workout.copyWith(exercises: updatedExercises);

    // Update state with the updated workout
    state = state!.copyWith(workout: updatedWorkout);

    print(
      "State updated. Current exercise is now: ${state!.currentExercise.name}",
    );
    print(
      "Current sets: ${state!.currentExercise.sets}, reps: ${state!.currentExercise.reps}, duration: ${state!.currentExercise.durationSeconds}",
    );
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

  Future<void> completeWorkout({
    required UserFeedback feedback,
    int? estimatedCaloriesBurned,
    required String userId,
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
