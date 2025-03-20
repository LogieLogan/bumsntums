// lib/features/workouts/screens/workout_execution_screen.dart
import 'package:bums_n_tums/features/workouts/widgets/execution/exercise_completion_animation.dart';
import 'package:bums_n_tums/shared/services/fallback_image_provider.dart';
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
import '../widgets/execution/rest_timer.dart';

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
  bool _showRestTimer = false;
  bool _showCompletionAnimation = false;
  bool _isMusicPlaying = false;

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

  void _toggleBackgroundMusic() {
    setState(() {
      _isMusicPlaying = !_isMusicPlaying;
    });
    // In a real implementation, you would play/pause the music here
    // This is just a UI placeholder for now

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isMusicPlaying
              ? 'Background music turned on'
              : 'Background music turned off',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
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
      child: Stack(
        children: [
          Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  // Top bar with progress and controls
                  _buildTopBar(workout, executionState),

                  // Exercise content or rest timer
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child:
                            executionState.isInRestPeriod
                                ? _buildRestTimer(executionState)
                                : _buildExerciseContent(
                                  executionState,
                                  currentExercise,
                                  isPaused,
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
          // The completion animation overlay - sits on top of everything when active
          if (_showCompletionAnimation)
            ExerciseCompletionAnimation(
              onAnimationComplete: () {
                setState(() {
                  _showCompletionAnimation = false;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRestTimer(WorkoutExecutionState state) {
    final nextExercise = state.nextExercise;
    final nextExerciseName = nextExercise?.name ?? 'Done';

    return RestTimer(
      durationSeconds: state.restTimeRemaining,
      isPaused: state.isPaused,
      nextExerciseName: nextExerciseName,
      onComplete: () {
        ref.read(workoutExecutionProvider.notifier).endRestPeriod();
      },
    );
  }

  Widget _buildExerciseContent(
    WorkoutExecutionState state,
    Exercise currentExercise,
    bool isPaused,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          currentExercise.name,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
              border: Border.all(color: AppColors.popGreen, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.popGreen,
                  ),
                ),
                const SizedBox(height: 8),
                ...currentExercise.modifications.map(
                  (mod) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.popGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mod.title,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                mod.description,
                                style: Theme.of(context).textTheme.bodySmall,
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

        // Form tips section
        if (currentExercise.description.contains("keeping") ||
            currentExercise.description.length > 100)
          Column(
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.popTurquoise.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.popTurquoise, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.popTurquoise,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Form Tips',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.popTurquoise,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Extract form tips from description
                    Text(
                      _extractFormTips(currentExercise.description),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _extractFormTips(String description) {
    final sentences = description.split('. ');
    final tips =
        sentences
            .where(
              (sentence) =>
                  sentence.toLowerCase().contains('keep') ||
                  sentence.toLowerCase().contains('maintain') ||
                  sentence.toLowerCase().contains('ensure') ||
                  sentence.toLowerCase().contains('focus on'),
            )
            .toList();

    return tips.isNotEmpty
        ? tips.join('. ') + '.'
        : "Focus on proper form and controlled movements.";
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

              // Voice guidance toggle
              IconButton(
                icon: Icon(
                  state.voiceGuidanceEnabled
                      ? Icons.volume_up
                      : Icons.volume_off,
                  color:
                      state.voiceGuidanceEnabled
                          ? AppColors.popBlue
                          : AppColors.mediumGrey,
                ),
                onPressed: () {
                  ref
                      .read(workoutExecutionProvider.notifier)
                      .toggleVoiceGuidance(!state.voiceGuidanceEnabled);
                },
                tooltip:
                    state.voiceGuidanceEnabled
                        ? 'Disable voice guidance'
                        : 'Enable voice guidance',
              ),
            ],
          ),

          IconButton(
            icon: Icon(
              _isMusicPlaying ? Icons.music_note : Icons.music_off,
              color:
                  _isMusicPlaying ? AppColors.popYellow : AppColors.mediumGrey,
            ),
            onPressed: _toggleBackgroundMusic,
            tooltip:
                _isMusicPlaying
                    ? 'Turn off background music'
                    : 'Turn on background music',
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Elapsed time
              Text(
                _formatTime(_secondsElapsed),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.salmon,
                ),
              ),

              if (!state.isInRestPeriod &&
                  state.currentExercise.durationSeconds == null)
                Text(
                  'Sets: ${state.completedExercises[state.currentExerciseIndex]?.setsCompleted ?? 0}/${state.currentExercise.sets}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
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
        PrimaryButton(
          text: 'Complete Set',
          onPressed: () {
            HapticFeedback.mediumImpact();
            _completeSet();
          },
        ),
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

    // Stop the timer
    _timer?.cancel();

    // If voice guidance is enabled, announce the pause
    final state = ref.read(workoutExecutionProvider);
    if (state != null && state.voiceGuidanceEnabled) {
      ref.read(voiceGuidanceProvider).speak('Workout paused');
    }
  }

  // resumeWorkout - This is already implemented, but let's enhance it
  void _resumeWorkout() {
    HapticFeedback.mediumImpact();
    ref.read(workoutExecutionProvider.notifier).resumeWorkout();

    // Resume the timer
    _startTimer();

    // If voice guidance is enabled, announce the resume
    final state = ref.read(workoutExecutionProvider);
    if (state != null && state.voiceGuidanceEnabled) {
      ref.read(voiceGuidanceProvider).speak('Workout resumed');
    }
  }

  void _nextExercise() {
    HapticFeedback.mediumImpact();

    // Add current exercise to completed with default log
    _logCurrentExercise();

    ref.read(workoutExecutionProvider.notifier).nextExercise();
  }

  void _previousExercise() {
    HapticFeedback.mediumImpact();
    ref.read(workoutExecutionProvider.notifier).resumeWorkout();
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

    // If all sets are completed
    if (completedSets >= currentExercise.sets) {
      // Show completion animation
      setState(() {
        _showCompletionAnimation = true;
      });

      // If voice guidance is enabled, announce completion
      if (state.voiceGuidanceEnabled) {
        ref.read(voiceGuidanceProvider).announceComplete();
      }

      // If this is the last exercise, complete workout after animation
      if (state.isLastExercise) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showCompletionAnimation = false;
            });
            _completeWorkout();
          }
        });
      } else {
        // Otherwise, start rest period after animation
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showCompletionAnimation = false;
            });
            ref
                .read(workoutExecutionProvider.notifier)
                .startRestPeriod(
                  currentExercise.restBetweenSeconds > 0
                      ? currentExercise.restBetweenSeconds
                      : 30, // Default rest period if not specified
                );
          }
        });
      }
    }
  }

  void _logExerciseCompletion(int exerciseIndex, int difficultyRating) {
    final state = ref.read(workoutExecutionProvider);
    if (state == null) return;

    final exercise = state.workout.exercises[exerciseIndex];

    ref
        .read(workoutExecutionProvider.notifier)
        .logExerciseCompletion(
          exerciseIndex,
          ExerciseLog(
            exerciseName: exercise.name,
            setsCompleted: exercise.sets,
            repsCompleted: exercise.reps,
            difficultyRating: difficultyRating,
            notes: '', // Optional note field
          ),
        );

    // Update analytics if available
    _analytics.logEvent(
      name: 'exercise_completed',
      parameters: {
        'exercise_name': exercise.name,
        'difficulty_rating': difficultyRating,
      },
    );
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
      // Otherwise start rest period before next exercise
      ref
          .read(workoutExecutionProvider.notifier)
          .startRestPeriod(
            state.currentExercise.restBetweenSeconds > 0
                ? state.currentExercise.restBetweenSeconds
                : 30, // Default rest period if not specified
          );
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
