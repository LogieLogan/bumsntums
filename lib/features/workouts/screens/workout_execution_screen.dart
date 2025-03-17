// lib/features/workouts/screens/workout_execution_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/workout_log.dart';
import '../providers/workout_execution_provider.dart';
import '../widgets/execution/exercise_timer.dart';
import '../widgets/execution/workout_progress_indicator.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/components/buttons/primary_button.dart';
import '../../../shared/theme/color_palette.dart';
import 'workout_completion_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkoutExecutionScreen extends ConsumerStatefulWidget {
  const WorkoutExecutionScreen({super.key});

  @override
  ConsumerState<WorkoutExecutionScreen> createState() =>
      _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState extends ConsumerState<WorkoutExecutionScreen>
    with WidgetsBindingObserver {
  final AnalyticsService _analytics = AnalyticsService();
  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
    _analytics.logScreenView(
      screenName: 'workout_execution',
      screenClass: 'WorkoutExecutionScreen',
    );

    // Optional: Prevent screen from sleeping during workout
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    // Reset system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-pause workout when app goes to background
    if (state == AppLifecycleState.paused) {
      _pauseWorkout();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final state = ref.read(workoutExecutionProvider);
      if (state != null && !state.isPaused) {
        setState(() {
          _secondsElapsed++;
        });
        ref
            .read(workoutExecutionProvider.notifier)
            .updateElapsedTime(_secondsElapsed);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final executionState = ref.watch(workoutExecutionProvider);

    if (executionState == null) {
      // Workout was cancelled or completed
      // Navigate back immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }

    final currentExercise = executionState.currentExercise;
    final workout = executionState.workout;
    final isPaused = executionState.isPaused;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Top bar with progress and controls
              _buildTopBar(workout, executionState),

              // Exercise content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          currentExercise.name,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Exercise image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            currentExercise.imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                width: double.infinity,
                                color: AppColors.paleGrey,
                                child: Center(
                                  child: Icon(
                                    Icons.fitness_center,
                                    size: 64,
                                    color: AppColors.salmon,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Timer or rep counter
                        if (currentExercise.durationSeconds != null)
                          ExerciseTimer(
                            durationSeconds: currentExercise.durationSeconds!,
                            isPaused: isPaused,
                            onComplete: _onExerciseComplete,
                          )
                        else
                          _buildRepCounter(currentExercise),

                        const SizedBox(height: 16),

                        // Exercise description
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.paleGrey,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Instructions',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currentExercise.description,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Modifications if available
                        if (currentExercise.modifications.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.popGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.popGreen,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Modifications',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.popGreen,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...currentExercise.modifications.map(
                                  (mod) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: AppColors.popGreen,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                mod.title,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              Text(
                                                mod.description,
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom control bar
              _buildBottomControls(executionState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(Workout workout, WorkoutExecutionState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _confirmExit,
              ),

              // Workout title
              Text(
                workout.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              // Elapsed time
              Text(
                _formatTime(_secondsElapsed),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.salmon,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress indicator
          WorkoutProgressIndicator(
            currentExerciseIndex: state.currentExerciseIndex,
            totalExercises: workout.exercises.length,
            progressPercentage: state.progressPercentage,
          ),
        ],
      ),
    );
  }

  Widget _buildRepCounter(Exercise exercise) {
    return Column(
      children: [
        Text(
          '${exercise.sets} sets of ${exercise.reps} reps',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < exercise.sets; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      i <
                              (ref
                                      .watch(workoutExecutionProvider)
                                      ?.completedExercises[ref
                                          .watch(workoutExecutionProvider)!
                                          .currentExerciseIndex]
                                      ?.setsCompleted ??
                                  0)
                          ? AppColors.popGreen
                          : AppColors.paleGrey,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color:
                          i <
                                  (ref
                                          .watch(workoutExecutionProvider)
                                          ?.completedExercises[ref
                                              .watch(workoutExecutionProvider)!
                                              .currentExerciseIndex]
                                          ?.setsCompleted ??
                                      0)
                              ? Colors.white
                              : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        PrimaryButton(text: 'Complete Set', onPressed: _completeSet),
      ],
    );
  }

  Widget _buildBottomControls(WorkoutExecutionState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous exercise button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: state.isFirstExercise ? null : _previousExercise,
            color: state.isFirstExercise ? Colors.grey : AppColors.popBlue,
          ),

          // Pause/play button
          FloatingActionButton(
            heroTag: 'pausePlay',
            backgroundColor:
                state.isPaused ? AppColors.popGreen : AppColors.salmon,
            onPressed: state.isPaused ? _resumeWorkout : _pauseWorkout,
            child: Icon(
              state.isPaused ? Icons.play_arrow : Icons.pause,
              color: Colors.white,
            ),
          ),

          // Next exercise button
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: state.isLastExercise ? null : _nextExercise,
            color: state.isLastExercise ? Colors.grey : AppColors.popBlue,
          ),
        ],
      ),
    );
  }

  void _pauseWorkout() {
    HapticFeedback.mediumImpact();
    ref.read(workoutExecutionProvider.notifier).pauseWorkout();
  }

  void _resumeWorkout() {
    HapticFeedback.mediumImpact();
    ref.read(workoutExecutionProvider.notifier).resumeWorkout();
  }

  void _nextExercise() {
    HapticFeedback.mediumImpact();

    // Add current exercise to completed with default log
    _logCurrentExercise();

    ref.read(workoutExecutionProvider.notifier).nextExercise();
  }

  void _previousExercise() {
    HapticFeedback.mediumImpact();
    ref.read(workoutExecutionProvider.notifier).previousExercise();
  }

  void _completeSet() {
    HapticFeedback.mediumImpact();

    final state = ref.read(workoutExecutionProvider);
    if (state == null) return;

    final currentExercise = state.currentExercise;
    final currentExerciseIndex = state.currentExerciseIndex;

    // Get the existing log or create a new one
    final existingLog = state.completedExercises[currentExerciseIndex];
    final completedSets = (existingLog?.setsCompleted ?? 0) + 1;

    // Update the log
    ref
        .read(workoutExecutionProvider.notifier)
        .logExerciseCompletion(
          currentExerciseIndex,
          ExerciseLog(
            exerciseName: currentExercise.name,
            setsCompleted:
                completedSets > currentExercise.sets
                    ? currentExercise.sets
                    : completedSets,
            repsCompleted: currentExercise.reps,
            difficultyRating: 3, // Default middle difficulty
          ),
        );

    // If all sets are completed, go to next exercise after a delay
    if (completedSets >= currentExercise.sets && !state.isLastExercise) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _nextExercise();
        }
      });
    }

    // If this is the last set of the last exercise, complete the workout
    if (completedSets >= currentExercise.sets && state.isLastExercise) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _completeWorkout();
        }
      });
    }
  }

  void _onExerciseComplete() {
    HapticFeedback.mediumImpact();

    final state = ref.read(workoutExecutionProvider);
    if (state == null) return;

    // Mark the current timed exercise as completed
    _logCurrentExercise();

    // If this is the last exercise, complete the workout
    if (state.isLastExercise) {
      _completeWorkout();
    } else {
      // Otherwise move to the next exercise
      ref.read(workoutExecutionProvider.notifier).nextExercise();
    }
  }

  void _logCurrentExercise() {
    final state = ref.read(workoutExecutionProvider);
    if (state == null) return;

    final currentExercise = state.currentExercise;
    final currentExerciseIndex = state.currentExerciseIndex;

    // Create a log for the current exercise if it doesn't exist
    if (!state.completedExercises.containsKey(currentExerciseIndex)) {
      ref
          .read(workoutExecutionProvider.notifier)
          .logExerciseCompletion(
            currentExerciseIndex,
            ExerciseLog(
              exerciseName: currentExercise.name,
              setsCompleted: currentExercise.sets,
              repsCompleted: currentExercise.reps,
              difficultyRating: 3, // Default middle difficulty
            ),
          );
    }
  }

  Future<void> _completeWorkout() async {
    // Get the current user ID
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      // Handle the case where user is not authenticated
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to save workout progress'),
        ),
      );
      return;
    }

    // Navigate to the completion screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => WorkoutCompletionScreen(
              workout: ref.read(workoutExecutionProvider)!.workout,
              elapsedTimeSeconds: _secondsElapsed,
            ),
      ),
    );

    // Complete the workout in the provider
    await ref
        .read(workoutExecutionProvider.notifier)
        .completeWorkout(
          userId: userId,
          feedback: UserFeedback(
            rating: 4, // Will be updated on the completion screen
          ),
        );
  }

  Future<bool> _onWillPop() async {
    _confirmExit();
    return false; // Prevent automatic pop
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Workout'),
            content: const Text(
              'Are you sure you want to cancel this workout? Your progress will be lost.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(), // Close dialog
                child: const Text('No, Continue'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  ref.read(workoutExecutionProvider.notifier).cancelWorkout();
                  Navigator.of(context).pop(); // Return to previous screen
                },
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
