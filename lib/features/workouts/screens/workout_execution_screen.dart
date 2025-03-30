// lib/features/workouts/screens/workout_execution_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/workout_log.dart';
import '../providers/workout_execution_provider.dart';
import '../widgets/execution/exercise_completion_animation.dart';
import '../widgets/execution/exercise_timer.dart';
import '../widgets/execution/rest_timer.dart';
import '../widgets/execution/set_rest_timer.dart';
import '../widgets/exercise_demo_widget.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/theme/color_palette.dart';
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
        if (!state.isPaused && _repCountdownSeconds > 0) {
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
      child: Stack(
        children: [
          Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  // Minimalist header with progress indicator
                  _buildHeader(workout, executionState),

                  // Main content area (expands to fill available space)
                  Expanded(
                    child:
                        executionState.isInRestPeriod
                            ? _buildRestPeriod(executionState)
                            : executionState.isInSetRestPeriod
                            ? _buildSetRestPeriod(executionState)
                            : _buildWorkoutContent(
                              executionState,
                              currentExercise,
                              isPaused,
                            ),
                  ),

                  // Bottom control bar
                  _buildBottomControls(executionState),
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
    );
  }

  // Streamlined header with minimal information
  Widget _buildHeader(Workout workout, WorkoutExecutionState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Title row with controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _confirmExit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              Text(
                workout.title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Elapsed time
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paleGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatTime(_secondsElapsed),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.salmon,
                      ),
                    ),
                  ),

                  // Voice guidance toggle
                  IconButton(
                    icon: Icon(
                      state.voiceGuidanceEnabled
                          ? Icons.volume_up
                          : Icons.volume_off,
                      size: 20,
                    ),
                    onPressed: () {
                      ref
                          .read(workoutExecutionProvider.notifier)
                          .toggleVoiceGuidance(!state.voiceGuidanceEnabled);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise count
              Text(
                'Exercise ${state.currentExerciseIndex + 1} of ${workout.exercises.length}',
                style: TextStyle(fontSize: 12, color: AppColors.mediumGrey),
              ),

              const SizedBox(height: 4),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: state.progressPercentage,
                  backgroundColor: AppColors.paleGrey,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.salmon),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Rest period between exercises
  Widget _buildRestPeriod(WorkoutExecutionState state) {
    final nextExercise = state.nextExercise;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Rest timer
          Expanded(
            flex: 1,
            child: RestTimer(
              durationSeconds: state.restTimeRemaining,
              isPaused: state.isPaused,
              nextExerciseName: nextExercise?.name ?? 'Done',
              onComplete: () {
                ref.read(workoutExecutionProvider.notifier).endRestPeriod();
                _startRepCountdownIfNeeded();
              },
              onAddTime:
                  () => ref
                      .read(workoutExecutionProvider.notifier)
                      .adjustRestTime(15),
              onReduceTime:
                  () => ref
                      .read(workoutExecutionProvider.notifier)
                      .adjustRestTime(-15, minimum: 5),
            ),
          ),

          if (nextExercise != null) ...[
            // Next exercise preview
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coming Up Next',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.salmon,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Next exercise demo
                  Expanded(
                    child: ExerciseDemoWidget(
                      exercise: nextExercise,
                      showControls: true,
                      autoPlay: true,
                    ),
                  ),

                  // Exercise details
                  const SizedBox(height: 8),
                  Text(
                    nextExercise.durationSeconds != null
                        ? '${nextExercise.sets} sets × ${nextExercise.durationSeconds} seconds'
                        : '${nextExercise.sets} sets × ${nextExercise.reps} reps',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  if (nextExercise.formTips.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.popTurquoise.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.popTurquoise,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 14,
                                color: AppColors.popTurquoise,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Form Tip',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.popTurquoise,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nextExercise.formTips.first,
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Rest period between sets
  Widget _buildSetRestPeriod(WorkoutExecutionState state) {
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
                _startRepCountdownIfNeeded();
              },
              onAddTime:
                  () => ref
                      .read(workoutExecutionProvider.notifier)
                      .adjustSetRestTime(15),
              onReduceTime:
                  () => ref
                      .read(workoutExecutionProvider.notifier)
                      .adjustSetRestTime(-15, minimum: 5),
            ),
          ),

          // Progress indicators
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentExercise.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    // Set indicator
                    Text(
                      state.currentSet < currentExercise.sets
                          ? 'Next: Set ${state.currentSet + 1}/${currentExercise.sets}'
                          : 'Final Set!',
                      style: TextStyle(
                        color: AppColors.salmon,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Form tip
                if (currentExercise.formTips.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.popTurquoise.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.popTurquoise,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      currentExercise.formTips.first,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Main workout content (exercise execution)
  Widget _buildWorkoutContent(
    WorkoutExecutionState state,
    Exercise exercise,
    bool isPaused,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Exercise name and set indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.salmon,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Set ${state.currentSet}/${exercise.sets}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Exercise video demonstration (takes most of the space)
          Expanded(
            flex: 3,
            child: ExerciseDemoWidget(
              exercise: exercise,
              showControls: exercise.durationSeconds == null,
              autoPlay: exercise.durationSeconds != null && !isPaused,
            ),
          ),

          const SizedBox(height: 16),

          // Timer or rep display
          Expanded(
            flex: 1,
            child:
                exercise.durationSeconds != null
                    ? ExerciseTimer(
                      durationSeconds: exercise.durationSeconds!,
                      isPaused: isPaused,
                      onComplete: _onExerciseComplete,
                    )
                    : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Rep count
                        Text(
                          '${exercise.reps} reps',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Time left counter for rep-based exercises
                        Text(
                          'Time remaining: ${_formatTime(_repCountdownSeconds)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.mediumGrey,
                          ),
                        ),
                      ],
                    ),
          ),

          // Set progress dots - more compact
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(exercise.sets, (index) {
              final isCompleted =
                  index <
                  (state
                          .completedExercises[state.currentExerciseIndex]
                          ?.setsCompleted ??
                      0);
              final isCurrent = index == state.currentSet - 1;

              return Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isCompleted
                          ? AppColors.popGreen
                          : isCurrent
                          ? AppColors.salmon
                          : AppColors.paleGrey,
                  border:
                      isCurrent
                          ? Border.all(color: AppColors.salmon, width: 2)
                          : null,
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          // Complete Set button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _completeSet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.salmon,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'COMPLETE SET',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Small space at bottom
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Bottom control bar
  Widget _buildBottomControls(WorkoutExecutionState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
          // Play/Pause button (centered)
          FloatingActionButton(
            heroTag: 'pausePlay',
            mini: false,
            backgroundColor:
                state.isPaused ? AppColors.popGreen : AppColors.salmon,
            onPressed: state.isPaused ? _resumeWorkout : _pauseWorkout,
            child: Icon(
              state.isPaused ? Icons.play_arrow : Icons.pause,
              color: Colors.white,
            ),
          ),

          // Next button (only show if not the last exercise)
          if (!state.isLastExercise)
            ElevatedButton.icon(
              onPressed: _nextExercise,
              icon: const Icon(Icons.skip_next),
              label: const Text('Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.popBlue,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  // Helper methods
  void _pauseWorkout() {
    HapticFeedback.mediumImpact();
    ref.read(workoutExecutionProvider.notifier).pauseWorkout();
    _timer?.cancel();

    final state = ref.read(workoutExecutionProvider);
    if (state != null && state.voiceGuidanceEnabled) {
      ref.read(voiceGuidanceProvider).speak('Workout paused');
    }
  }

  void _resumeWorkout() {
    HapticFeedback.mediumImpact();
    ref.read(workoutExecutionProvider.notifier).resumeWorkout();
    _startTimer();

    final state = ref.read(workoutExecutionProvider);
    if (state != null && state.voiceGuidanceEnabled) {
      ref.read(voiceGuidanceProvider).speak('Workout resumed');
    }
  }

  void _nextExercise() {
    HapticFeedback.mediumImpact();
    _logCurrentExercise();
    ref.read(workoutExecutionProvider.notifier).nextExercise();
  }

  // void _previousExercise() {
  //   HapticFeedback.mediumImpact();
  //   ref.read(workoutExecutionProvider.notifier).previousExercise();
  // }

  void _completeSet() {
    HapticFeedback.mediumImpact();
    ref.read(workoutExecutionProvider.notifier).completeSet();

    final state = ref.read(workoutExecutionProvider);
    if (state != null) {
      final currentExercise = state.currentExercise;
      final currentSet = state.currentSet;

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
  }

  void _onExerciseComplete() {
    HapticFeedback.mediumImpact();

    final state = ref.read(workoutExecutionProvider);
    if (state == null) return;

    _logCurrentExercise();

    if (state.isLastExercise) {
      _completeWorkout();
    } else {
      ref
          .read(workoutExecutionProvider.notifier)
          .startRestPeriod(
            state.currentExercise.restBetweenSeconds > 0
                ? state.currentExercise.restBetweenSeconds
                : 30,
          );
    }
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
  }

  Future<bool> _onWillPop() async {
    _confirmExit();
    return false;
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
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('No, Continue'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(workoutExecutionProvider.notifier).cancelWorkout();
                  Navigator.of(context).pop();
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
