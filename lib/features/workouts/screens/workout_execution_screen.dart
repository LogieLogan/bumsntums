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
  late ProviderSubscription<WorkoutExecutionState?> _stateSubscription;
  bool _isNavigatingToCompletion = false;

  // Countdown timer for reps-based exercises
  Timer? _repCountdownTimer;
  int _repCountdownSeconds = 0;
  final int _defaultRepCountdown = 45;

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

    // Setup a listener for state changes
    _stateSubscription = ref.listenManual(workoutExecutionProvider, (
      previous,
      next,
    ) {
      if (next != null &&
          next.isWorkoutComplete &&
          !_isNavigatingToCompletion) {
        print("State listener detected workout completion");
        _navigateToCompletionScreen(next);
      }
    });

    // Prevent screen from sleeping during workout
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
  }

  @override
  void didUpdateWidget(WorkoutExecutionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check for workout completion state
    final state = ref.read(workoutExecutionProvider);
    if (state?.isWorkoutComplete == true && !_isNavigatingToCompletion) {
      // Use Future.microtask to avoid navigation during build
      Future.microtask(() {
        if (mounted) {
          _navigateToCompletionScreen(state!);
        }
      });
    }
  }

  @override
  void dispose() {
    _stateSubscription.close();
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

    // Cancel any existing timer first
    _repCountdownTimer?.cancel();

    // Only start countdown for rep-based exercises (not timed)
    if (state.currentExercise.durationSeconds == null &&
        !state.isInRestPeriod &&
        !state.isInSetRestPeriod) {
      print(
        "Starting rep countdown for ${state.currentExercise.name}, Set ${state.currentSet}/${state.currentExercise.sets}",
      );

      setState(() {
        _repCountdownSeconds = _defaultRepCountdown;
      });

      _repCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        final currentState = ref.read(workoutExecutionProvider);
        if (currentState == null) {
          timer.cancel();
          return;
        }

        if (!currentState.isPaused && _repCountdownSeconds > 0) {
          setState(() {
            _repCountdownSeconds--;
          });
        }

        // Auto-complete when countdown reaches 0, but only if we're not in rest already
        if (_repCountdownSeconds <= 0 &&
            !currentState.isInRestPeriod &&
            !currentState.isInSetRestPeriod) {
          print("Rep countdown reached 0, completing set");
          _completeSet();
          timer.cancel();
        }
      });
    } else {
      print(
        "Not starting rep countdown: timed=${state.currentExercise.durationSeconds != null}, inRest=${state.isInRestPeriod}, inSetRest=${state.isInSetRestPeriod}",
      );
    }
  }

  void _navigateToCompletionScreen(WorkoutExecutionState state) async {
    if (_isNavigatingToCompletion) {
      print("Already navigating to completion screen, ignoring duplicate call");
      return;
    }

    _isNavigatingToCompletion = true;
    print("Initiating navigation to completion screen");

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print("Error: No user ID available");
        _isNavigatingToCompletion = false;
        return;
      }

      // Create feedback object
      final defaultFeedback = UserFeedback(rating: 4);

      // Log workout completion
      _analytics.logWorkoutCompleted(
        workoutId: state.workout.id,
        workoutName: state.workout.title,
        durationSeconds: _secondsElapsed,
      );

      // Save the workout before clearing state
      final completedWorkout = state.workout;
      final totalTimeSeconds = _secondsElapsed;

      // Complete the workout in the provider
      await ref
          .read(workoutExecutionProvider.notifier)
          .completeWorkout(userId: userId, feedback: defaultFeedback);

      if (mounted) {
        print(
          "Successfully completed workout, navigating to completion screen",
        );

        // Use a simpler navigation approach
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (context) => WorkoutCompletionScreen(
                  workout: completedWorkout,
                  elapsedTimeSeconds: totalTimeSeconds,
                ),
          ),
        );
      }
    } catch (e, stackTrace) {
      print("Error during completion navigation: $e");
      print(stackTrace);

      _analytics.logError(error: 'Workout completion navigation error: $e');
      ref
          .read(crashReportingProvider)
          .recordError(
            e,
            stackTrace,
            reason: 'Workout completion navigation error',
          );

      _isNavigatingToCompletion = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final executionState = ref.watch(workoutExecutionProvider);

    if (executionState == null) {
      // Use Future.microtask to avoid navigation during build
      Future.microtask(() {
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      });
      return const SizedBox.shrink();
    }

    // The rest of your build method stays the same
    final currentExercise = executionState.currentExercise;
    final workout = executionState.workout;
    final isPaused = executionState.isPaused;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: SafeArea(
          bottom: true,
          child: Stack(
            children: [
              // Main content
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white,
                child: Column(
                  children: [
                    // Top navigation bar
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

                    // Bottom controls - ensure these have fixed height
                    SizedBox(
                      height: 96, // Provide a fixed height to prevent overflow
                      child: WorkoutBottomControls(
                        state: executionState,
                        onPause: _pauseWorkout,
                        onResume: _resumeWorkout,
                        onNext: _nextExercise,
                        onCompleteSet: _completeSet,
                        onCompleteWorkout:
                            _isLastExerciseAndSetCompleted(executionState)
                                ? () {
                                  print("Manual workout completion requested");
                                  ref
                                      .read(workoutExecutionProvider.notifier)
                                      .markWorkoutAsCompleted();
                                }
                                : null,
                      ),
                    ),
                  ],
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
      ),
    );
  }

  bool _isLastExerciseAndSetCompleted(WorkoutExecutionState state) {
    if (!state.isLastExercise) return false;

    final currentExercise = state.currentExercise;
    final exerciseLog = state.completedExercises[state.currentExerciseIndex];

    // Show completion button when all sets of the last exercise are done
    return exerciseLog != null &&
        exerciseLog.setsCompleted >= currentExercise.sets;
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
    final totalSets = currentExercise.sets;

    // Additional debug logging
    print(
      "UI _completeSet: Exercise: ${currentExercise.name}, Current Set: $currentSet/$totalSets",
    );

    // Track set completion
    _analytics.logEvent(
      name: 'set_completed',
      parameters: {
        'workout_id': state.workout.id,
        'exercise_name': currentExercise.name,
        'exercise_index': state.currentExerciseIndex,
        'set_number': currentSet,
        'total_sets': totalSets,
        'is_last_set':
            (currentSet >= totalSets)
                ? "true"
                : "false", // Convert boolean to string
        'has_next_exercise':
            !state.isLastExercise
                ? "true"
                : "false", // Convert boolean to string
        'exercise_type':
            currentExercise.durationSeconds != null ? 'timed' : 'reps',
      },
    );

    try {
      ref.read(workoutExecutionProvider.notifier).completeSet();

      // Re-check state after completeSet call
      final updatedState = ref.read(workoutExecutionProvider);
      if (updatedState != null) {
        print(
          "After completeSet - Current set: ${updatedState.currentSet}, In rest: ${updatedState.isInRestPeriod}",
        );
      }

      if (currentSet >= totalSets) {
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
    } catch (e, stackTrace) {
      print("Error in _completeSet: $e");
      // Log error to analytics and crash reporting
      _analytics.logError(error: 'Error during set completion: $e');
      ref
          .read(crashReportingProvider)
          .recordError(e, stackTrace, reason: 'Error during set completion');
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
      completeWorkout: () {
        ref.read(workoutExecutionProvider.notifier).markWorkoutAsCompleted();
      },
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
}
