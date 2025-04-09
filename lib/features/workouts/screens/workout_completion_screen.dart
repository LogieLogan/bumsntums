// lib/features/workouts/screens/workout_completion_screen.dart
import 'package:bums_n_tums/features/auth/providers/auth_provider.dart';
import '../../workout_analytics/providers/workout_stats_provider.dart';
import 'package:bums_n_tums/features/workout_planning/providers/workout_planning_provider.dart';
import 'package:bums_n_tums/features/workouts/providers/workout_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/components/buttons/primary_button.dart';
import '../../../shared/components/buttons/secondary_button.dart';
import '../../../shared/theme/color_palette.dart';
import '../models/workout.dart';
import '../models/workout_log.dart';
import '../../workout_analytics/providers/workout_stats_provider.dart';
import '../../../shared/providers/crash_reporting_provider.dart';

class WorkoutCompletionScreen extends ConsumerStatefulWidget {
  final Workout workout;
  final Duration elapsedTime;
  final List<ExerciseLog> exercisesCompleted;

  const WorkoutCompletionScreen({
    Key? key,
    required this.workout,
    required this.elapsedTime,
    required this.exercisesCompleted,
  }) : super(key: key);

  @override
  ConsumerState<WorkoutCompletionScreen> createState() =>
      _WorkoutCompletionScreenState();
}

class _WorkoutCompletionScreenState
    extends ConsumerState<WorkoutCompletionScreen> {
  final _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );
  final _analyticsService = AnalyticsService();
  int _rating = 3;
  bool _feltEasy = false;
  bool _feltTooHard = false;
  final _commentsController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Start the confetti animation
    _confettiController.play();

    // Log screen view
    _analyticsService.logScreenView(screenName: 'workout_completion');
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = widget.elapsedTime.inMinutes;
    final seconds = widget.elapsedTime.inSeconds % 60;
    final formattedTime = '$minutes:${seconds.toString().padLeft(2, '0')}';

    // Calculate estimated calories burned
    final calorieMultiplier = _getCalorieMultiplier(widget.workout.difficulty);
    final estimatedCalories =
        (widget.elapsedTime.inMinutes * calorieMultiplier).round();

    return Scaffold(
      body: Stack(
        children: [
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: const [
                AppColors.salmon,
                AppColors.popCoral,
                AppColors.popBlue,
                AppColors.popGreen,
                AppColors.popYellow,
                AppColors.popTurquoise,
              ],
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // Celebration heading
                    const Text(
                      'Workout Complete!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      widget.workout.title,
                      style: TextStyle(
                        fontSize: 20,
                        color: AppColors.salmon,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Stats cards
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(
                          'Time',
                          formattedTime,
                          Icons.timer,
                          AppColors.popBlue,
                        ),
                        _buildStatCard(
                          'Exercises',
                          widget.exercisesCompleted.length.toString(),
                          Icons.fitness_center,
                          AppColors.popGreen,
                        ),
                        _buildStatCard(
                          'Calories',
                          estimatedCalories.toString(),
                          Icons.local_fire_department,
                          AppColors.popCoral,
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Feedback section
                    const Text(
                      'How was your workout?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGrey,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () => setState(() => _rating = index + 1),
                          child: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color:
                                index < _rating
                                    ? AppColors.popYellow
                                    : AppColors.lightGrey,
                            size: 36,
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 24),

                    // Difficulty feedback
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFeedbackChip(
                          'Too Easy',
                          _feltEasy,
                          AppColors.popGreen,
                          () => setState(() {
                            _feltEasy = !_feltEasy;
                            if (_feltEasy) _feltTooHard = false;
                          }),
                        ),
                        const SizedBox(width: 16),
                        _buildFeedbackChip(
                          'Too Hard',
                          _feltTooHard,
                          AppColors.popCoral,
                          () => setState(() {
                            _feltTooHard = !_feltTooHard;
                            if (_feltTooHard) _feltEasy = false;
                          }),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Comments field
                    TextField(
                      controller: _commentsController,
                      decoration: InputDecoration(
                        hintText: 'Any comments about the workout?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: AppColors.paleGrey,
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),

                    // Save button
                    _isSaving
                        ? const CircularProgressIndicator(
                          color: AppColors.salmon,
                        )
                        : PrimaryButton(
                          text: 'Save & Continue',
                          onPressed: _saveWorkoutLog,
                          width: double.infinity,
                        ),

                    const SizedBox(height: 16),

                    // Skip button
                    if (!_isSaving)
                      SecondaryButton(
                        text: 'Skip Feedback',
                        onPressed: _navigateHome,
                        width: double.infinity,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGrey,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.mediumGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackChip(
    String label,
    bool isSelected,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppColors.paleGrey,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.lightGrey,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.mediumGrey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  double _getCalorieMultiplier(WorkoutDifficulty difficulty) {
    switch (difficulty) {
      case WorkoutDifficulty.beginner:
        return 4.0;
      case WorkoutDifficulty.intermediate:
        return 6.0;
      case WorkoutDifficulty.advanced:
        return 8.0;
    }
  }

  Future<void> _saveWorkoutLog() async {
    // Prevent double taps
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final userId = ref.read(authStateProvider).value?.uid;

    // --- 1. Validate User ---
    if (userId == null) {
      print("Error: User not logged in.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: You must be logged in to save workouts.'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isSaving = false);
      }
      return;
    }

    try {
      final userFeedback = UserFeedback(
        rating: _rating,
        feltEasy: _feltEasy,
        feltTooHard: _feltTooHard,
        comments:
            _commentsController.text.trim().isNotEmpty
                ? _commentsController.text.trim()
                : null,
      );

      final caloriesBurned =
          (widget.elapsedTime.inMinutes *
                  _getCalorieMultiplier(widget.workout.difficulty))
              .round();

      const uuid = Uuid();
      final logId = 'log_${DateTime.now().millisecondsSinceEpoch}_${uuid.v4()}';

      final workoutLog = WorkoutLog(
        id: logId,
        userId: userId,
        workoutId: widget.workout.id,
        startedAt: DateTime.now().subtract(widget.elapsedTime),
        completedAt: DateTime.now(),
        durationMinutes: widget.elapsedTime.inMinutes,
        caloriesBurned: caloriesBurned,
        exercisesCompleted: widget.exercisesCompleted,
        userFeedback: userFeedback,
        workoutCategory: widget.workout.category.name,
        workoutName: widget.workout.title,
        targetAreas: widget.workout.tags,
        isShared: false,
        privacy: 'private',
        isOfflineCreated: false,
        syncStatus: 'syncing',
      );

      final workoutService = ref.read(workoutServiceProvider);
      await workoutService.logCompletedWorkout(workoutLog);
      print(
        "Workout log saved successfully via WorkoutService (ID: ${workoutLog.id}).",
      );

      final statsActionsNotifier = ref.read(workoutStatsActionsProvider.notifier);
      await statsActionsNotifier.updateStatsFromWorkoutLog(workoutLog);
      print("Aggregated stats update triggered successfully.");

      print("Invalidating relevant providers...");
      ref.invalidate(workoutStatsProvider(userId));
      ref.invalidate(userWorkoutStatsProvider(userId));
      ref.invalidate(userWorkoutStreakProvider(userId));
      ref.invalidate(plannerItemsNotifierProvider(userId));
      ref.invalidate(workoutFrequencyDataProvider((userId: userId, days: 90)));

      print("Providers invalidated.");

      _analyticsService.logEvent(
        name: 'workout_log_saved',
        parameters: {
          'workout_id': workoutLog.workoutId,
          'workout_name': workoutLog.workoutName ?? 'N/A',
          'duration_minutes': workoutLog.durationMinutes,
          'calories_burned': workoutLog.caloriesBurned,
          'rating': workoutLog.userFeedback.rating,
          'category': workoutLog.workoutCategory ?? 'N/A',
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout saved successfully!'),
          backgroundColor: AppColors.popGreen,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      _navigateHome();
    } catch (e, stackTrace) {
      print("Error saving workout log: $e");
      print(stackTrace);

      try {
        final crashReporter = ref.read(crashReportingServiceProvider);
        await crashReporter.recordError(
          e,
          stackTrace,
          reason: 'Error saving workout log in WorkoutCompletionScreen',
          fatal: false,
        );
        print("Error reported to Crash Reporting Service.");
      } catch (reportError) {
        print(
          "Failed to report error to Crash Reporting Service: $reportError",
        );
      }

      _analyticsService.logEvent(
        name: 'workout_save_failed',
        parameters: {'error_type': e.runtimeType.toString()},
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save workout: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _navigateHome() {
    // Pop to home screen
    Navigator.of(context).popUntil((route) => route.isFirst);

    // Log analytics event
    _analyticsService.logEvent(
      name: 'workout_completion_exit',
      parameters: {'workout_id': widget.workout.id},
    );
  }
}
