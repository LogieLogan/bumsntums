// lib/features/workouts/screens/workout_execution_screen.dart
import 'dart:async';
import 'package:bums_n_tums/features/workouts/widgets/execution/between_sets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/exercise.dart';
import '../models/workout_log.dart';
import '../providers/workout_execution_provider.dart';
import '../widgets/execution/exercise_completion_animation.dart';
import '../widgets/execution/workout_top_bar.dart';
import '../widgets/execution/exercise_content_widget.dart';
import '../widgets/execution/rest_period_widget.dart';
import '../widgets/execution/workout_bottom_controls.dart';
import '../widgets/execution/workout_progress_indicator.dart';
import '../services/workout_execution_helper_service.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/providers/crash_reporting_provider.dart';
import 'workout_completion_screen.dart';

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
  bool _showCompletionAnimation = false;

  // Countdown timer for reps-based exercises
  Timer? _repCountdownTimer;
  int _repCountdownSeconds = 0;
  final int _defaultRepCountdown = 45; // Default 45 seconds per set

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
    _startRepCountdownIfNeeded();
    _analytics.logScreenView(
      screenName: 'workout_execution',
      screenClass: 'WorkoutExecutionScreen',
    );

    // Prevent screen from sleeping during workout
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _repCountdownTimer?.cancel();
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

  void _startRepCountdownIfNeeded() {
    final state = ref.read(workoutExecutionProvider);
    if (state == null) return;

    // Only start countdown for rep-based exercises (not timed)
    if (state.currentExercise.durationSeconds == null &&
        !state.isInRestPeriod &&
        !state.isInSetRestPeriod) {
      _repCountdownTimer?.cancel();

      setState(() {
        _repCountdownSeconds = _defaultRepCountdown;
      });

      _repCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final currentState = ref.read(workoutExecutionProvider);
        if (currentState == null) return;

        if (!currentState.isPaused && _repCountdownSeconds > 0) {
          setState(() {
            _repCountdownSeconds--;
          });
        }

        // Auto-complete when countdown reaches 0
        if (_repCountdownSeconds <= 0) {
          _completeSet();
          timer.cancel();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final executionState = ref.watch(workoutExecutionProvider);

    if (executionState == null) {
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
        body: Stack(
          children: [
            // Main content
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
              child: SafeArea(
                child: Column(
                  children: [
                    // Top navigation bar
                    // lib/features/workouts/screens/workout_execution_screen.dart (continued)
                    WorkoutTopBar(
                      workout: workout,
                      state: executionState,
                      formattedTime: _formatTime(_secondsElapsed),
                      onClose: _confirmExit,
                      onToggleVoice: () {
                        ref
                            .read(workoutExecutionProvider.notifier)
                            .toggleVoiceGuidance(
                              !executionState.voiceGuidanceEnabled,
                            );
                      },
                    ),

                    // Progress bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: WorkoutProgressIndicator(
                        currentExerciseIndex:
                            executionState.currentExerciseIndex,
                        totalExercises: workout.exercises.length,
                        progressPercentage: executionState.progressPercentage,
                      ),
                    ),

                    // Main content - Expanded to fill available space
                    Expanded(
                      child:
                          executionState.isInRestPeriod
                              ? RestPeriodWidget(
                                state: executionState,
                                showExerciseInfoSheet: _showExerciseInfoSheet,
                              )
                              : executionState.isInSetRestPeriod
                              ? BetweenSetsScreen(state: executionState)
                              : ExerciseContentWidget(
                                exercise: currentExercise,
                                isPaused: isPaused,
                                state: executionState,
                                completeSet: _completeSet,
                                onExerciseComplete: _onExerciseComplete,
                                showExerciseInfoSheet: _showExerciseInfoSheet,
                                repCountdownSeconds: _repCountdownSeconds,
                                showCompleteButton: false,
                              ),
                    ),

                    // Bottom controls
                    WorkoutBottomControls(
                      state: executionState,
                      onPause: _pauseWorkout,
                      onResume: _resumeWorkout,
                      onNext: _nextExercise,
                      onCompleteSet: _completeSet,
                    ),
                  ],
                ),
              ),
            ),

            // Completion animation overlay
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
      ),
    );
  }

  // Helper methods
  String _formatTime(int seconds) {
    final helper = ref.read(workoutExecutionHelperProvider);
    return helper.formatTime(seconds);
  }

  void _showExerciseInfoSheet(Exercise exercise) {
    final helper = ref.read(workoutExecutionHelperProvider);
    helper.showExerciseInfoSheet(context, exercise);
  }

  Future<bool> _onWillPop() async {
    _confirmExit();
    return false;
  }

  void _confirmExit() {
    final helper = ref.read(workoutExecutionHelperProvider);
    helper.confirmExit(context, ref, () {
      Navigator.of(context).pop();
    });
  }

  void _pauseWorkout() {
    HapticFeedback.mediumImpact();
    ref.read(workoutExecutionProvider.notifier).pauseWorkout();
    _timer?.cancel();

    final state = ref.read(workoutExecutionProvider);
    if (state != null && state.voiceGuidanceEnabled) {
      ref.read(voiceGuidanceProvider).speak('Workout paused');
    }

    // Track workout pause event
    _analytics.logEvent(
      name: 'workout_paused',
      parameters: {
        'workout_id': state?.workout.id ?? '',
        'elapsed_time': _secondsElapsed,
      },
    );
  }

  void _resumeWorkout() {
    HapticFeedback.mediumImpact();
    ref.read(workoutExecutionProvider.notifier).resumeWorkout();
    _startTimer();

    final state = ref.read(workoutExecutionProvider);
    if (state != null && state.voiceGuidanceEnabled) {
      ref.read(voiceGuidanceProvider).speak('Workout resumed');
    }

    // Track workout resume event
    _analytics.logEvent(
      name: 'workout_resumed',
      parameters: {
        'workout_id': state?.workout.id ?? '',
        'elapsed_time': _secondsElapsed,
      },
    );
  }

  void _nextExercise() {
    HapticFeedback.mediumImpact();

    final state = ref.read(workoutExecutionProvider);
    if (state == null) return;

    _logCurrentExercise();
    ref.read(workoutExecutionProvider.notifier).nextExercise();
    _startRepCountdownIfNeeded();

    _analytics.logEvent(
      name: 'exercise_skipped',
      parameters: {
        'workout_id': state.workout.id,
        'exercise_name': state.currentExercise.name,
        'exercise_index': state.currentExerciseIndex,
      },
    );
  }

  void _completeSet() {
    HapticFeedback.mediumImpact();

    final state = ref.read(workoutExecutionProvider);
    if (state == null) return;

    final currentExercise = state.currentExercise;
    final currentSet = state.currentSet;

    // Track set completion
    _analytics.logEvent(
      name: 'set_completed',
      parameters: {
        'workout_id': state.workout.id,
        'exercise_name': currentExercise.name,
        'exercise_index': state.currentExerciseIndex,
        'set_number': currentSet,
        'total_sets': currentExercise.sets,
      },
    );

    ref.read(workoutExecutionProvider.notifier).completeSet();

    if (currentSet >= currentExercise.sets) {
      setState(() {
        _showCompletionAnimation = true;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showCompletionAnimation = false;
          });
        }
      });
    }
  }

  void _onExerciseComplete() {
    final helper = ref.read(workoutExecutionHelperProvider);
    helper.logExerciseCompletion(
      ref: ref, // Change from providerRef to ref
      elapsedTimeSeconds: _secondsElapsed,
      showAnimation: _showCompletionAnimation,
      setShowAnimation: (value) {
        setState(() {
          _showCompletionAnimation = value;
        });
      },
      completeWorkout: _completeWorkout,
    );
  }

  void _logCurrentExercise() {
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
    }
  }

  Future<void> _completeWorkout() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to save workout progress'),
        ),
      );
      return;
    }

    try {
      await ref
          .read(workoutExecutionProvider.notifier)
          .completeWorkout(userId: userId, feedback: UserFeedback(rating: 4));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (context) => WorkoutCompletionScreen(
                  workout: ref.read(workoutExecutionProvider)!.workout,
                  elapsedTimeSeconds: _secondsElapsed,
                ),
          ),
        );
      }

      _analytics.logWorkoutCompleted(
        workoutId: ref.read(workoutExecutionProvider)!.workout.id,
        workoutName: ref.read(workoutExecutionProvider)!.workout.title,
        durationSeconds: _secondsElapsed,
      );
    } catch (e, stackTrace) {
      print('Error completing workout: $e');

      // Log error to analytics
      _analytics.logError(error: 'Failed to complete workout: ${e.toString()}');

      // Log error to crash reporting
      ref
          .read(crashReportingProvider)
          .recordError(
            e,
            stackTrace,
            reason: 'Error during workout completion',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save workout progress'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
