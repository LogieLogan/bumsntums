// lib/features/workouts/screens/workout_execution_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/theme/color_palette.dart';
import '../providers/workout_execution_provider.dart';
import '../widgets/execution/exercise_completion_animation.dart';
import '../widgets/execution/exercise_content_widget.dart';
import '../widgets/execution/exercise_info_sheet.dart';
import '../widgets/execution/rest_period_widget.dart';
import '../widgets/execution/workout_bottom_controls.dart';
import '../widgets/execution/workout_progress_indicator.dart';
import '../widgets/execution/workout_top_bar.dart';
import 'workout_completion_screen.dart';

class WorkoutExecutionScreen extends ConsumerStatefulWidget {
  const WorkoutExecutionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WorkoutExecutionScreen> createState() =>
      _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState
    extends ConsumerState<WorkoutExecutionScreen> {
  bool _showCompletionAnimation = false;
  final AnalyticsService _analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _analytics.logScreenView(screenName: 'workout_execution');
  }

  @override
  Widget build(BuildContext context) {
    final executionState = ref.watch(workoutExecutionProvider);
    final executionNotifier = ref.read(workoutExecutionProvider.notifier);

    // If we're in the initial state, show a loading indicator
    if (executionState.status == ExecutionStatus.initial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If workout is completed, navigate to completion screen
    if (executionState.status == ExecutionStatus.completed) {
      // Use a post-frame callback to avoid build errors
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (context) => WorkoutCompletionScreen(
                  workout: executionState.workout,
                  elapsedTime: executionState.elapsedTime,
                  exercisesCompleted: executionState.completedExerciseLogs,
                ),
          ),
        );
      });

      // Show loading while transitioning
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Get the current exercise
    final currentExercise = executionState.currentExercise!;
    final isTimeBased = currentExercise.durationSeconds != null;

    return WillPopScope(
      onWillPop: () async {
        _showExitConfirmation();
        return false; // Prevent default back button behavior
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Top bar
                WorkoutTopBar(
                  workoutTitle: executionState.workout.title,
                  onExit: _showExitConfirmation,
                ),

                // Progress indicator
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: WorkoutProgressIndicator(
                    currentExerciseIndex: _getCurrentExerciseOverallIndex(),
                    totalExercises:
                        executionState.workout.getAllExercises().length,
                    progressPercentage: executionState.progressPercentage,
                  ),
                ),

                // Main content area - different based on status
                Expanded(
                  child: _buildMainContent(executionState, executionNotifier),
                ),

                // Bottom controls - only shown during exercise
                if (executionState.status == ExecutionStatus.exerciseInProgress)
                  WorkoutBottomControls(
                    exercise: currentExercise,
                    onCompleteSet: () => executionNotifier.completeSet(),
                    onShowInfo: _showExerciseInfo,
                    isTimeBased: isTimeBased,
                  ),
              ],
            ),

            // Exercise completion animation overlay
            if (_showCompletionAnimation)
              ExerciseCompletionAnimation(
                onAnimationComplete: () {
                  setState(() {
                    _showCompletionAnimation = false;
                  });
                },
              ),

            // Paused overlay
            if (executionState.isPaused) _buildPausedOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(
    WorkoutExecutionState state,
    WorkoutExecutionNotifier notifier,
  ) {
    switch (state.status) {
      case ExecutionStatus.exerciseInProgress:
        return Padding(
          padding: const EdgeInsets.only(
            bottom: 8,
          ), // Add padding at the bottom
          child: ExerciseContentWidget(
            exercise: state.currentExercise!,
            currentSet: state.currentSetIndex,
            onComplete: () => _completeExercise(notifier),
            onInfoTap: _showExerciseInfo,
          ),
        );

      case ExecutionStatus.betweenSets:
        return RestPeriodWidget(
          nextExercise: state.currentExercise!,
          isBetweenSets: true,
          onComplete: () => notifier.skipRest(),
        );

      case ExecutionStatus.restingBetweenExercises:
        return RestPeriodWidget(
          nextExercise: state.currentExercise!,
          isBetweenSets: false,
          onComplete: () => notifier.skipRest(),
        );

      default:
        return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildPausedOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pause_circle_outline,
                size: 64,
                color: AppColors.salmon,
              ),
              const SizedBox(height: 16),
              const Text(
                'Workout Paused',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    () =>
                        ref
                            .read(workoutExecutionProvider.notifier)
                            .resumeWorkout(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.salmon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'RESUME',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to show exercise info
  void _showExerciseInfo() {
    final currentExercise = ref.read(workoutExecutionProvider).currentExercise!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => ExerciseInfoSheet(exercise: currentExercise),
    );
  }

  // Helper to complete an exercise with animation
  void _completeExercise(WorkoutExecutionNotifier notifier) {
    // Show completion animation
    setState(() {
      _showCompletionAnimation = true;
    });

    // Complete the set after a short delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        notifier.completeSet();
      }
    });
  }

  // Helper to show exit confirmation
  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Exit Workout?'),
            content: const Text(
              'Your progress will be lost. Are you sure you want to exit?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CONTINUE WORKOUT'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Log analytics event for abandoned workout
                  _analytics.logEvent(
                    name: 'workout_abandoned',
                    parameters: {
                      'workout_id':
                          ref.read(workoutExecutionProvider).workout.id,
                      'completion_percentage':
                          ref.read(workoutExecutionProvider).progressPercentage,
                    },
                  );

                  // Pop the dialog
                  Navigator.of(context).pop();

                  // Pop the workout screen
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.salmon,
                  foregroundColor: Colors.white,
                ),
                child: const Text('EXIT'),
              ),
            ],
          ),
    );
  }

  // Helper to get the overall index of the current exercise
  int _getCurrentExerciseOverallIndex() {
    final state = ref.read(workoutExecutionProvider);

    if (state.workout.sections.isNotEmpty) {
      // Get the number of exercises in all previous sections
      int previousExercises = 0;
      for (int i = 0; i < state.currentSectionIndex; i++) {
        previousExercises += state.workout.sections[i].exercises.length;
      }

      // Add the current exercise index within its section
      return previousExercises + state.currentExerciseIndex;
    } else {
      // For legacy workouts without sections
      return state.currentExerciseIndex;
    }
  }
}
