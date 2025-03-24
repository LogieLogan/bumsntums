// lib/features/workouts/screens/workout_execution_screen.dart
import 'package:bums_n_tums/features/workouts/models/workout_section.dart';
import 'package:bums_n_tums/features/workouts/providers/workout_calendar_provider.dart';
import 'package:bums_n_tums/features/workouts/widgets/execution/exercise_settings_modal.dart';
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
import '../widgets/execution/exercise_completion_animation.dart';
import '../widgets/execution/rest_timer.dart';
import '../widgets/execution/set_rest_timer.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
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
  bool _showCompletionAnimation = false;
  bool _isMusicPlaying = false;

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

    // Optional: Prevent screen from sleeping during workout
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

  void _startRepCountdownIfNeeded() {
    final state = ref.read(workoutExecutionProvider);
    if (state == null) return;

    // Only start countdown for rep-based exercises (not timed)
    if (state.currentExercise.durationSeconds == null &&
        !state.isInRestPeriod &&
        !state.isInSetRestPeriod) {
      // Cancel existing timer if any
      _repCountdownTimer?.cancel();

      // Reset countdown
      setState(() {
        _repCountdownSeconds = _defaultRepCountdown;
      });

      // Start countdown
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
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child:
                          executionState.isInRestPeriod
                              ? _buildRestTimer(executionState)
                              : executionState.isInSetRestPeriod
                              ? _buildSetRestTimer(executionState)
                              : _buildExerciseContent(
                                executionState,
                                currentExercise,
                                isPaused,
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

  Widget _buildSetRestTimer(WorkoutExecutionState state) {
    final currentExercise = state.currentExercise;

    return SingleChildScrollView(
      child: Column(
        children: [
          SetRestTimer(
            durationSeconds: state.setRestTimeRemaining,
            isPaused: state.isPaused,
            currentSet: state.currentSet,
            totalSets: currentExercise.sets,
            onComplete: () {
              ref.read(workoutExecutionProvider.notifier).endSetRestPeriod();
              _startRepCountdownIfNeeded();
            },
            onAddTime: () {
              // Add 15 seconds to rest time
              ref.read(workoutExecutionProvider.notifier).adjustSetRestTime(15);
            },
            onReduceTime: () {
              // Reduce rest time by 15 seconds, but don't go below 5
              ref
                  .read(workoutExecutionProvider.notifier)
                  .adjustSetRestTime(-15, minimum: 5);
            },
          ),

          const SizedBox(height: 24),

          // Exercise reminder
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
                Text(
                  'Current Exercise',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.salmon,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // Form tips reminder
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.popTurquoise.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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
                            'Remember',
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
                      Text(
                        currentExercise.formTips.isNotEmpty
                            ? currentExercise.formTips.first
                            : _extractFormTips(currentExercise.description),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),

                      const SizedBox(height: 12),

                      // Next set motivation
                      Text(
                        state.currentSet < currentExercise.sets
                            ? 'Next up: Set ${state.currentSet + 1} of ${currentExercise.sets}'
                            : 'This is your last set - give it your all!',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.salmon,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimer(WorkoutExecutionState state) {
    final nextExercise = state.nextExercise;
    final nextExerciseName = nextExercise?.name ?? 'Done';

    return SingleChildScrollView(
      child: Column(
        children: [
          RestTimer(
            durationSeconds: state.restTimeRemaining,
            isPaused: state.isPaused,
            nextExerciseName: nextExerciseName,
            onComplete: () {
              ref.read(workoutExecutionProvider.notifier).endRestPeriod();
              _startRepCountdownIfNeeded();
            },
            onAddTime: () {
              // Add 15 seconds to rest time
              print("Adding 15 seconds to rest time"); // Debug print
              ref.read(workoutExecutionProvider.notifier).adjustRestTime(15);
            },
            onReduceTime: () {
              // Reduce rest time by 15 seconds, but don't go below 5
              print("Reducing rest time by 15 seconds"); // Debug print
              ref
                  .read(workoutExecutionProvider.notifier)
                  .adjustRestTime(-15, minimum: 5);
            },
          ),

          if (nextExercise != null) ...[
            const SizedBox(height: 24),

            // Next exercise preview
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
                  Text(
                    'Coming Up Next',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.salmon,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Exercise image and info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Exercise image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          nextExercise.imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              color: AppColors.paleGrey,
                              child: const Icon(Icons.fitness_center),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Exercise info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nextExercise.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 8),

                            // Exercise stats
                            Row(
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  size: 16,
                                  color: AppColors.mediumGrey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  nextExercise.durationSeconds != null
                                      ? '${nextExercise.durationSeconds} seconds'
                                      : '${nextExercise.sets} sets × ${nextExercise.reps} reps',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            // Target area
                            Row(
                              children: [
                                Icon(
                                  Icons.track_changes,
                                  size: 16,
                                  color: AppColors.mediumGrey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Targets: ${nextExercise.targetArea}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Full instructions
                  Text(
                    'Instructions:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Show full description, not truncated
                  Text(
                    nextExercise.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),

                  // Show all form tips, not just the first one
                  if (nextExercise.formTips.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Form Tips:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.popTurquoise,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...nextExercise.formTips
                        .map(
                          (tip) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                  color: AppColors.popTurquoise,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppColors.darkGrey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ] else ...[
                    // If no specific form tips, show extracted tips
                    const SizedBox(height: 16),
                    Text(
                      'Form Tips:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.popTurquoise,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _extractFormTips(nextExercise.description),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.darkGrey,
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

  Widget _buildExerciseContent(
    WorkoutExecutionState state,
    Exercise currentExercise,
    bool isPaused,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Exercise name and header info
        Text(
          currentExercise.name,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),

        // Set indicator
        Text(
          'Set ${state.currentSet} of ${currentExercise.sets}',
          style: TextStyle(
            color: AppColors.salmon,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),

        const SizedBox(height: 8),

        // Exercise countdown timer / settings row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Time remaining
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.paleGrey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, color: AppColors.popBlue, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    currentExercise.durationSeconds != null
                        ? 'Timed'
                        : _formatTime(_repCountdownSeconds),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.popBlue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Settings button (cog)
            IconButton(
              icon: Icon(Icons.settings, color: AppColors.darkGrey),
              onPressed: isPaused ? () => _showExerciseSettings() : null,
              tooltip: 'Exercise Settings',
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Exercise image
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              currentExercise.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
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
        ),

        const SizedBox(height: 16),

        // Set progress indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(currentExercise.sets, (index) {
            final isCompleted =
                index <
                (state
                        .completedExercises[state.currentExerciseIndex]
                        ?.setsCompleted ??
                    0);
            final isCurrent = index == state.currentSet - 1;

            return Container(
              width: 40,
              height: 40,
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
                        ? Border.all(color: AppColors.salmon, width: 3)
                        : null,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color:
                        isCompleted || isCurrent
                            ? Colors.white
                            : AppColors.darkGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 16),

        // Rep counter or timer based on exercise type
        if (currentExercise.durationSeconds != null)
          ExerciseTimer(
            durationSeconds: currentExercise.durationSeconds!,
            isPaused: isPaused,
            onComplete: _onExerciseComplete,
          )
        else
          Center(
            child: Text(
              '${currentExercise.reps} reps',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),

        const SizedBox(height: 24),

        // Complete set button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _completeSet,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.salmon,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'COMPLETE SET',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // Instructions button - simple and won't cause layout issues
        const SizedBox(height: 8),
        TextButton.icon(
          icon: Icon(Icons.info_outline, size: 18),
          label: Text('View Instructions & Tips'),
          onPressed: () => _showInstructionsDialog(currentExercise),
          style: TextButton.styleFrom(foregroundColor: AppColors.popBlue),
        ),
      ],
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

          // Music and elapsed time row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Elapsed time
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.paleGrey,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: AppColors.salmon),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(_secondsElapsed),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.salmon,
                      ),
                    ),
                  ],
                ),
              ),

              // Music toggle - FIXED VERSION
              GestureDetector(
                onTap: _toggleBackgroundMusic,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _isMusicPlaying
                            ? AppColors.popYellow.withOpacity(0.2)
                            : AppColors.paleGrey,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        _isMusicPlaying
                            ? Border.all(color: AppColors.popYellow)
                            : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isMusicPlaying ? Icons.music_note : Icons.music_off,
                        size: 16,
                        color:
                            _isMusicPlaying
                                ? AppColors.popYellow
                                : AppColors.mediumGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isMusicPlaying ? 'Music On' : 'Music Off',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color:
                              _isMusicPlaying
                                  ? AppColors.popYellow
                                  : AppColors.mediumGrey,
                        ),
                      ),
                    ],
                  ),
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

          // Exercise progress text
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Exercise ${state.currentExerciseIndex + 1} of ${workout.exercises.length}',
              style: TextStyle(color: AppColors.mediumGrey, fontSize: 12),
            ),
          ),

          // Section indicator
          if (workout.sections.isNotEmpty) _buildSectionIndicator(state),
        ],
      ),
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

  void _showExerciseSettings() {
    final state = ref.read(workoutExecutionProvider);
    if (state == null) return;

    final currentExerciseIndex = state.currentExerciseIndex;
    final currentExercise = state.currentExercise;

    print("Opening exercise settings modal for: ${currentExercise.name}");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows for a larger modal
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9, // Takes up 90% of the screen
          child: ExerciseSettingsModal(
            exercise: currentExercise,
            onSave: (updatedExercise) {
              print("Saving updated exercise: ${updatedExercise.name}");
              print(
                "New settings - sets: ${updatedExercise.sets}, reps: ${updatedExercise.reps}, duration: ${updatedExercise.durationSeconds}",
              );

              ref
                  .read(workoutExecutionProvider.notifier)
                  .updateExercise(currentExerciseIndex, updatedExercise);

              // Restart the rep countdown if applicable
              if (updatedExercise.durationSeconds == null) {
                setState(() {
                  _repCountdownSeconds = _defaultRepCountdown;
                });
              }
            },
          ),
        );
      },
    );
  }

  void _showInstructionsDialog(Exercise exercise) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dialog title and close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            exercise.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(),

                    // Instructions
                    Text(
                      'Instructions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exercise.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 16),

                    // Form tips
                    Text(
                      'Form Tips',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.popTurquoise,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exercise.formTips.isNotEmpty
                          ? exercise.formTips.join('\n\n')
                          : _extractFormTips(exercise.description),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 24),

                    // Close button at bottom
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.salmon,
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    ref.read(workoutExecutionProvider.notifier).completeSet();

    // Show completion animation if appropriate
    final state = ref.read(workoutExecutionProvider);
    if (state != null) {
      final currentExercise = state.currentExercise;
      final currentSet = state.currentSet;

      // If this was the last set, show the completion animation
      if (currentSet >= currentExercise.sets) {
        setState(() {
          _showCompletionAnimation = true;
        });

        // Hide the animation after a delay
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

    // Complete the workout in the provider
    await ref
        .read(workoutExecutionProvider.notifier)
        .completeWorkout(
          userId: userId,
          feedback: UserFeedback(
            rating: 4, // Will be updated on the completion screen
          ),
        );

    // Navigate to the completion screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (context) => WorkoutCompletionScreen(
                workout: ref.read(workoutExecutionProvider)!.workout,
                elapsedTimeSeconds: _secondsElapsed,
                // Remove the workoutLog parameter
              ),
        ),
      );
    }

    // Log an analytics event
    _analytics.logWorkoutCompleted(
      workoutId: ref.read(workoutExecutionProvider)!.workout.id,
      workoutName: ref.read(workoutExecutionProvider)!.workout.title,
      durationSeconds: _secondsElapsed,
    );

    ref.refresh(
      combinedCalendarEventsProvider((
        userId: userId,
        startDate: DateTime.now().subtract(const Duration(days: 365)),
        endDate: DateTime.now().add(const Duration(days: 30)),
      )),
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

  ({int sectionIndex, int localExerciseIndex})? _getSectionIndices(
    int globalIndex,
  ) {
    final state = ref.read(workoutExecutionProvider);
    if (state == null || state.workout.sections.isEmpty) return null;

    int exerciseCount = 0;
    for (int i = 0; i < state.workout.sections.length; i++) {
      final section = state.workout.sections[i];
      if (globalIndex < exerciseCount + section.exercises.length) {
        return (
          sectionIndex: i,
          localExerciseIndex: globalIndex - exerciseCount,
        );
      }
      exerciseCount += section.exercises.length;
    }

    return null;
  }

  Widget _buildSectionIndicator(WorkoutExecutionState state) {
    // Get current section if using sections
    if (state.workout.sections.isEmpty) return const SizedBox.shrink();

    // Find current section
    final indices = _getSectionIndices(state.currentExerciseIndex);
    if (indices == null) return const SizedBox.shrink();

    final section = state.workout.sections[indices.sectionIndex];
    final sectionType = section.type;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getSectionColor(sectionType).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getSectionColor(sectionType), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getSectionTypeIcon(sectionType),
            color: _getSectionColor(sectionType),
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            section.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getSectionColor(sectionType),
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getSectionColor(sectionType),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getSectionTypeName(sectionType),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for section styling
  Color _getSectionColor(SectionType type) {
    switch (type) {
      case SectionType.normal:
        return AppColors.popBlue;
      case SectionType.circuit:
        return AppColors.popGreen;
      case SectionType.superset:
        return AppColors.popCoral;
      default:
        return AppColors.popBlue;
    }
  }

  String _getSectionTypeName(SectionType type) {
    switch (type) {
      case SectionType.normal:
        return 'Standard';
      case SectionType.circuit:
        return 'Circuit';
      case SectionType.superset:
        return 'Superset';
      default:
        return 'Standard';
    }
  }

  IconData _getSectionTypeIcon(SectionType type) {
    switch (type) {
      case SectionType.normal:
        return Icons.list;
      case SectionType.circuit:
        return Icons.loop;
      case SectionType.superset:
        return Icons.swap_horiz;
      default:
        return Icons.list;
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
