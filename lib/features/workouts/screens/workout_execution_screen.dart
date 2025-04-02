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
import '../../../shared/theme/text_styles.dart';
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
                    _buildTopBar(workout, executionState),

                    // Progress bar
                    _buildProgressBar(executionState, workout),

                    // Main content - Expanded to fill available space
                    Expanded(
                      child:
                          executionState.isInRestPeriod
                              ? _buildRestPeriod(executionState)
                              : executionState.isInSetRestPeriod
                              ? _buildSetRestPeriod(executionState)
                              : _buildExerciseContent(
                                executionState,
                                currentExercise,
                                isPaused,
                              ),
                    ),

                    // Bottom controls
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
      ),
    );
  }

  Widget _buildTopBar(Workout workout, WorkoutExecutionState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back/close button
          GestureDetector(
            onTap: _confirmExit,
            child: const Icon(Icons.close, color: Colors.black, size: 24),
          ),

          // Workout title - with limited width to prevent overflow
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth:
                    MediaQuery.of(context).size.width *
                    0.6, // Limit to 60% of screen width
              ),
              child: Text(
                workout.title,
                style: AppTextStyles.h3,
                overflow: TextOverflow.ellipsis, // Add ellipsis for long titles
                maxLines: 1, // Ensure single line
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Right side controls
          Row(
            mainAxisSize: MainAxisSize.min, // Prevent these from expanding
            children: [
              // Timer display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.salmon.withOpacity(0.1),
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

              const SizedBox(width: 8),

              // Voice toggle
              GestureDetector(
                onTap: () {
                  ref
                      .read(workoutExecutionProvider.notifier)
                      .toggleVoiceGuidance(!state.voiceGuidanceEnabled);
                },
                child: Icon(
                  state.voiceGuidanceEnabled
                      ? Icons.volume_up
                      : Icons.volume_off,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Progress indicator
  Widget _buildProgressBar(WorkoutExecutionState state, Workout workout) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise count text
          Text(
            'Exercise ${state.currentExerciseIndex + 1} of ${workout.exercises.length}',
            style: TextStyle(fontSize: 12, color: AppColors.mediumGrey),
          ),

          const SizedBox(height: 4),

          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.progressPercentage,
              backgroundColor: AppColors.paleGrey,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.salmon),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseContent(
    WorkoutExecutionState state,
    Exercise exercise,
    bool isPaused,
  ) {
    // Check if this is a timed exercise
    final bool isTimedExercise = exercise.durationSeconds != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise name and set indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Exercise name and info button
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        exercise.name,
                        style: AppTextStyles.h2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Info button
                    GestureDetector(
                      onTap: () => _showExerciseInfoSheet(exercise),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.salmon.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: AppColors.salmon,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Set indicator pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.salmon,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Set ${state.currentSet}/${exercise.sets}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Exercise demo video - in a container with fixed height
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.paleGrey,
            ),
            clipBehavior: Clip.hardEdge,
            child: ExerciseDemoWidget(
              exercise: exercise,
              showControls: false,
              autoPlay: !isPaused,
            ),
          ),

          // Form tip (if available)
          if (exercise.formTips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.popTurquoise.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.popTurquoise.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: AppColors.popTurquoise,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exercise.formTips.first,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Timer or rep counter in a scrollable view if needed
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Exercise information based on type
                  if (isTimedExercise)
                    _buildTimedExerciseContent(exercise, isPaused)
                  else
                    _buildRepBasedExerciseContent(exercise),

                  const SizedBox(height: 16),

                  // Set progress indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(exercise.sets, (index) {
                      final isCompleted =
                          index <
                          (state
                                  .completedExercises[state
                                      .currentExerciseIndex]
                                  ?.setsCompleted ??
                              0);
                      final isCurrent = index == state.currentSet - 1;

                      return Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
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
                                  ? Border.all(
                                    color: AppColors.salmon,
                                    width: 2,
                                  )
                                  : null,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Complete set button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _completeSet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.salmon,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'COMPLETE SET',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimedExerciseContent(Exercise exercise, bool isPaused) {
    return SizedBox(
      height: 160, // Fixed height instead of constraints
      child: ExerciseTimer(
        durationSeconds: exercise.durationSeconds!,
        isPaused: isPaused,
        onComplete: _onExerciseComplete,
      ),
    );
  }

  // New helper method for rep-based exercises
  Widget _buildRepBasedExerciseContent(Exercise exercise) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rep count
        Text(
          '${exercise.reps} reps',
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 4),

        // Time remaining
        Text(
          'Time remaining: ${_formatTime(_repCountdownSeconds)}',
          style: TextStyle(fontSize: 14, color: AppColors.mediumGrey),
        ),
      ],
    );
  }

  // Rest period between exercises
  Widget _buildRestPeriod(WorkoutExecutionState state) {
    final nextExercise = state.nextExercise;
    if (nextExercise == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rest timer
            RestTimer(
              durationSeconds: state.restTimeRemaining,
              isPaused: state.isPaused,
              nextExerciseName: nextExercise.name,
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

            const SizedBox(height: 24),

            // Coming up next header with info button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Coming Up Next',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.salmon,
                  ),
                ),

                // Info button
                GestureDetector(
                  onTap: () => _showExerciseInfoSheet(nextExercise),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.salmon.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: AppColors.salmon,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Exercise name
            Text(
              nextExercise.name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGrey,
              ),
            ),

            const SizedBox(height: 12),

            // Exercise metrics
            Row(
              children: [
                // Sets & Reps/Duration
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.popBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    nextExercise.durationSeconds != null
                        ? '${nextExercise.sets} sets × ${nextExercise.durationSeconds} sec'
                        : '${nextExercise.sets} sets × ${nextExercise.reps} reps',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.popBlue,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Target area
                if (nextExercise.targetArea.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.popGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      nextExercise.targetArea,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.popGreen,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Next exercise preview
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: ExerciseDemoWidget(
                exercise: nextExercise,
                showControls: false,
                autoPlay: true,
              ),
            ),

            const SizedBox(height: 16),

            // Preparation steps
            if (nextExercise.preparationSteps.isNotEmpty) ...[
              Text(
                'How to Prepare',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.salmon,
                ),
              ),
              const SizedBox(height: 8),
              ...nextExercise.preparationSteps
                  .take(2)
                  .map(
                    (step) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.play_arrow,
                            size: 16,
                            color: AppColors.salmon,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (nextExercise.preparationSteps.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: GestureDetector(
                    onTap: () => _showExerciseInfoSheet(nextExercise),
                    child: Text(
                      'See more...',
                      style: TextStyle(
                        color: AppColors.popBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 16),

            // Form tip for next exercise
            if (nextExercise.formTips.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.popTurquoise.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.popTurquoise.withOpacity(0.3),
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
                          size: 16,
                          color: AppColors.popTurquoise,
                        ),
                        const SizedBox(width: 8),
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
                      style: const TextStyle(fontSize: 14),
                    ),

                    // Show more link if there are additional tips
                    if (nextExercise.formTips.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: GestureDetector(
                          onTap: () => _showExerciseInfoSheet(nextExercise),
                          child: Text(
                            'More tips...',
                            style: TextStyle(
                              color: AppColors.popBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
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
        ],
      ),
    );
  }

  // Minimal bottom controls
  Widget _buildBottomControls(WorkoutExecutionState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Play/Pause button (no background)
          GestureDetector(
            onTap: state.isPaused ? _resumeWorkout : _pauseWorkout,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                state.isPaused ? Icons.play_arrow : Icons.pause,
                color: Colors.black,
                size: 32,
              ),
            ),
          ),

          // Next button if not the last exercise
          if (!state.isLastExercise)
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: GestureDetector(
                onTap: _nextExercise,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.popBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.popBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.skip_next,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
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

    setState(() {
      _showCompletionAnimation = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showCompletionAnimation = false;
        });

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
    });
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
    } catch (e) {
      print('Error completing workout: $e');
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

  Future<bool> _onWillPop() async {
    _confirmExit();
    return false;
  }

  void _showExerciseInfoSheet(Exercise exercise) {
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
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Exercise name
                  Text(
                    exercise.name,
                    style: AppTextStyles.h2,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.salmon,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(exercise.description),

                  const SizedBox(height: 24),

                  // Form tips
                  if (exercise.formTips.isNotEmpty) ...[
                    Text(
                      'Form Tips',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.salmon,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...exercise.formTips.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: AppColors.popGreen,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(tip)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Common mistakes
                  if (exercise.commonMistakes.isNotEmpty) ...[
                    Text(
                      'Common Mistakes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.salmon,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...exercise.commonMistakes.map(
                      (mistake) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning,
                              size: 18,
                              color: AppColors.popCoral,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(mistake)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Breathing pattern
                  if (exercise.breathingPattern.isNotEmpty) ...[
                    Text(
                      'Breathing Pattern',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.salmon,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.air, size: 18, color: AppColors.popBlue),
                        const SizedBox(width: 10),
                        Expanded(child: Text(exercise.breathingPattern)),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Preparation steps
                  if (exercise.preparationSteps.isNotEmpty) ...[
                    Text(
                      'Preparation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.salmon,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...exercise.preparationSteps.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.popBlue,
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(entry.value)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Target muscles
                  if (exercise.targetMuscles.isNotEmpty) ...[
                    Text(
                      'Target Muscles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.salmon,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          exercise.targetMuscles
                              .map(
                                (muscle) => Chip(
                                  backgroundColor: AppColors.salmon.withOpacity(
                                    0.1,
                                  ),
                                  label: Text(
                                    muscle,
                                    style: TextStyle(color: AppColors.salmon),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Close button
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.salmon,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text('CLOSE'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Cancel Workout?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Are you sure you want to cancel this workout? Your progress will be lost.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Continue'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ref
                              .read(workoutExecutionProvider.notifier)
                              .cancelWorkout();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.salmon,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Cancel Workout'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
