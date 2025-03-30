// lib/features/workout_planning/screens/workout_scheduling_screen.dart
import 'package:bums_n_tums/features/workouts/models/workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workout_planning_provider.dart';
import '../../../features/workouts/providers/workout_provider.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/components/buttons/primary_button.dart';
import 'package:intl/intl.dart';

class WorkoutSchedulingScreen extends ConsumerStatefulWidget {
  final String userId;
  final DateTime scheduledDate;

  const WorkoutSchedulingScreen({
    Key? key,
    required this.userId,
    required this.scheduledDate,
  }) : super(key: key);

  @override
  ConsumerState<WorkoutSchedulingScreen> createState() =>
      _WorkoutSchedulingScreenState();
}

class _WorkoutSchedulingScreenState
    extends ConsumerState<WorkoutSchedulingScreen> {
  TimeOfDay? _selectedTime;
  String? _selectedWorkoutId;

  @override
  Widget build(BuildContext context) {
    final workoutsAsync = ref.watch(allWorkoutsProvider);
    final dateFormatter = DateFormat('EEEE, MMMM d');

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Workout')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date selection
            Text(
              'Date: ${dateFormatter.format(widget.scheduledDate)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 16),

            // Time picker
            InkWell(
              onTap: () async {
                final selectedTime = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime ?? TimeOfDay.now(),
                );

                if (selectedTime != null) {
                  setState(() {
                    _selectedTime = selectedTime;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.lightGrey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: AppColors.mediumGrey),
                    const SizedBox(width: 8),
                    Text(
                      _selectedTime != null
                          ? 'Time: ${_selectedTime!.format(context)}'
                          : 'Select a time (optional)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: AppColors.mediumGrey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Select a workout:',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 8),

            // Workout list
            // lib/features/workout_planning/screens/workout_scheduling_screen.dart (continued)
            // Workout list
            Expanded(
              child: workoutsAsync.when(
                data: (workouts) {
                  if (workouts.isEmpty) {
                    return Center(
                      child: Text(
                        'No workouts available.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: workouts.length,
                    itemBuilder: (context, index) {
                      final workout = workouts[index];
                      final isSelected = _selectedWorkoutId == workout.id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side:
                              isSelected
                                  ? BorderSide(color: AppColors.pink, width: 2)
                                  : BorderSide.none,
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedWorkoutId = workout.id;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                // Workout info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        workout.title,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(
                                            workout.category,
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          _getCategoryName(workout.category),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            color: _getCategoryColor(
                                              workout.category,
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_getDifficultyName(workout.difficulty)} · ${workout.durationMinutes} min',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),

                                // Selection indicator
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColors.pink,
                                  )
                                else
                                  Icon(
                                    Icons.radio_button_unchecked,
                                    color: AppColors.lightGrey,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading:
                    () =>
                        const LoadingIndicator(message: 'Loading workouts...'),
                error:
                    (error, stack) =>
                        Center(child: Text('Error loading workouts: $error')),
              ),
            ),

            // Schedule button
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
              child: PrimaryButton(
                text: 'Schedule Workout',
                onPressed:
                    _selectedWorkoutId == null
                        ? null
                        : () => _scheduleWorkout(context),
                isEnabled: _selectedWorkoutId != null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleWorkout(BuildContext context) async {
    if (_selectedWorkoutId == null) return;

    try {
      // Get the planning notifier
      final planningNotifier = ref.read(
        workoutPlanningNotifierProvider(widget.userId).notifier,
      );

      // Schedule the workout
      await planningNotifier.scheduleWorkout(
        _selectedWorkoutId!,
        widget.scheduledDate,
        preferredTime: _selectedTime,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Workout scheduled successfully!'),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule workout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Color _getCategoryColor(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.bums:
        return AppColors.pink;
      case WorkoutCategory.tums:
        return AppColors.popCoral;
      case WorkoutCategory.fullBody:
        return AppColors.popBlue;
      case WorkoutCategory.cardio:
        return AppColors.popGreen;
      case WorkoutCategory.quickWorkout:
        return AppColors.popYellow;
    }
  }

  String _getCategoryName(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.bums:
        return 'Bums';
      case WorkoutCategory.tums:
        return 'Tums';
      case WorkoutCategory.fullBody:
        return 'Full Body';
      case WorkoutCategory.cardio:
        return 'Cardio';
      case WorkoutCategory.quickWorkout:
        return 'Quick';
    }
  }

  String _getDifficultyName(WorkoutDifficulty difficulty) {
    switch (difficulty) {
      case WorkoutDifficulty.beginner:
        return 'Beginner';
      case WorkoutDifficulty.intermediate:
        return 'Intermediate';
      case WorkoutDifficulty.advanced:
        return 'Advanced';
    }
  }
}
