// lib/features/workout_planning/widgets/scheduled_workout_item.dart
import 'package:bums_n_tums/features/workouts/models/workout.dart';
import 'package:flutter/material.dart';
import '../models/scheduled_workout.dart';
import '../../../shared/theme/color_palette.dart';
import 'package:intl/intl.dart';

class ScheduledWorkoutItem extends StatelessWidget {
  final ScheduledWorkout scheduledWorkout;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onComplete;

  const ScheduledWorkoutItem({
    Key? key,
    required this.scheduledWorkout,
    required this.onTap,
    required this.onDelete,
    required this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final workout = scheduledWorkout.workout;
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            scheduledWorkout.isCompleted
                ? BorderSide(color: AppColors.success, width: 1.5)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column with time and duration
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (scheduledWorkout.preferredTime != null)
                        Text(
                          _getTimeLabel(scheduledWorkout.preferredTime!),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (workout != null)
                        Text(
                          '${workout.durationMinutes} min',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.mediumGrey,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(width: 16),

                  // Right column with workout details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout?.title ?? 'Unknown Workout',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (workout != null)
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
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getCategoryName(workout.category),
                              style: textTheme.bodySmall?.copyWith(
                                color: _getCategoryColor(workout.category),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (workout != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _getDifficultyName(workout.difficulty),
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.mediumGrey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Status indicator and actions
                  Column(
                    children: [
                      if (scheduledWorkout.isCompleted)
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 20,
                        )
                      else
                        InkWell(
                          onTap: onComplete,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.check_circle_outline,
                              color: AppColors.mediumGrey,
                              size: 20,
                            ),
                          ),
                        ),

                      const SizedBox(height: 8),

                      InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.delete_outline,
                            color: AppColors.mediumGrey,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeLabel(TimeOfDay time) {
    if (time.hour < 10) return 'Morning';
    if (time.hour < 15) return 'Lunch';
    return 'Evening';
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
