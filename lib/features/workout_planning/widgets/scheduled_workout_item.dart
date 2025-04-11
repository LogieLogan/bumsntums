// lib/features/workout_planning/widgets/scheduled_workout_item.dart
import 'package:bums_n_tums/features/workouts/models/workout.dart';
import 'package:flutter/material.dart';
import '../models/scheduled_workout.dart';
import '../../../shared/theme/app_colors.dart';

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
                  // Left column with time and workout badge
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getCategoryColorFromId(
                        workout?.category,
                        scheduledWorkout.workoutId,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getCategoryIconFromId(
                              workout?.category,
                              scheduledWorkout.workoutId,
                            ),
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getCategoryNameFromId(
                              workout?.category,
                              scheduledWorkout.workoutId,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                workout?.title ??
                                    _getWorkoutNameFromId(
                                      scheduledWorkout.workoutId,
                                    ),
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (scheduledWorkout.preferredTime != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.paleGrey,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getTimeLabel(
                                    scheduledWorkout.preferredTime!,
                                  ),
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Duration and difficulty badges
                        Row(
                          children: [
                            if (workout != null) ...[
                              Icon(
                                Icons.timer,
                                size: 14,
                                color: AppColors.mediumGrey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${workout.durationMinutes} min',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.mediumGrey,
                                ),
                              ),
                              const SizedBox(width: 12),
                              _buildDifficultyBadge(workout.difficulty),
                            ],
                          ],
                        ),
                        if (workout?.description != null &&
                            workout!.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            workout.description,
                            style: textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // Action buttons at the bottom
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Complete button
                    OutlinedButton.icon(
                      onPressed:
                          scheduledWorkout.isCompleted ? null : onComplete,
                      icon: Icon(
                        scheduledWorkout.isCompleted
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        size: 16,
                      ),
                      label: Text(
                        scheduledWorkout.isCompleted ? 'Completed' : 'Complete',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            scheduledWorkout.isCompleted
                                ? AppColors.success
                                : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        visualDensity: VisualDensity.compact,
                        side:
                            scheduledWorkout.isCompleted
                                ? BorderSide(color: AppColors.success)
                                : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete button
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      visualDensity: VisualDensity.compact,
                      color: AppColors.mediumGrey,
                      tooltip: 'Remove workout',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getWorkoutNameFromId(String workoutId) {
    final parts = workoutId.split('-');
    if (parts.length >= 2) {
      final category = parts[0];
      String categoryName =
          category.substring(0, 1).toUpperCase() + category.substring(1);

      // Try to extract more descriptive name if available
      if (parts.length > 2) {
        final descriptor = parts[1];
        if (descriptor.isNotEmpty) {
          String descriptorName =
              descriptor.substring(0, 1).toUpperCase() +
              descriptor.substring(1);
          return '$categoryName $descriptorName Workout';
        }
      }

      return '$categoryName Workout';
    }
    return 'Workout';
  }

  // Helper method to get category from workout ID
  WorkoutCategory _getCategoryFromId(String workoutId) {
    final parts = workoutId.split('-');
    if (parts.isNotEmpty) {
      final category = parts[0].toLowerCase();

      switch (category) {
        case 'bums':
          return WorkoutCategory.bums;
        case 'tums':
          return WorkoutCategory.tums;
        case 'full':
        case 'fullbody':
          return WorkoutCategory.fullBody;
        case 'cardio':
          return WorkoutCategory.cardio;
        case 'quick':
          return WorkoutCategory.quickWorkout;
      }
    }
    return WorkoutCategory.fullBody;
  }

  // Get category color based on ID if no workout is available
  Color _getCategoryColorFromId(WorkoutCategory? category, String workoutId) {
    if (category != null) {
      return _getBackgroundColor(category);
    }

    return _getBackgroundColor(_getCategoryFromId(workoutId));
  }

  // Get category icon based on ID if no workout is available
  IconData _getCategoryIconFromId(WorkoutCategory? category, String workoutId) {
    if (category != null) {
      return _getCategoryIcon(category);
    }

    return _getCategoryIcon(_getCategoryFromId(workoutId));
  }

  // Get category name based on ID if no workout is available
  String _getCategoryNameFromId(WorkoutCategory? category, String workoutId) {
    if (category != null) {
      return _getCategoryShortName(category);
    }

    return _getCategoryShortName(_getCategoryFromId(workoutId));
  }

  // Helper method to get background color based on category
  Color _getBackgroundColor(WorkoutCategory? category) {
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
      default:
        return AppColors.salmon;
    }
  }

  // Helper method to get category icon
  IconData _getCategoryIcon(WorkoutCategory? category) {
    switch (category) {
      case WorkoutCategory.bums:
        return Icons.fitness_center;
      case WorkoutCategory.tums:
        return Icons.straighten;
      case WorkoutCategory.fullBody:
        return Icons.person;
      case WorkoutCategory.cardio:
        return Icons.directions_run;
      case WorkoutCategory.quickWorkout:
        return Icons.timer;
      default:
        return Icons.fitness_center;
    }
  }

  // Helper method to get short name for category
  String _getCategoryShortName(WorkoutCategory? category) {
    switch (category) {
      case WorkoutCategory.bums:
        return 'Bums';
      case WorkoutCategory.tums:
        return 'Tums';
      case WorkoutCategory.fullBody:
        return 'Full';
      case WorkoutCategory.cardio:
        return 'Cardio';
      case WorkoutCategory.quickWorkout:
        return 'Quick';
      default:
        return 'Workout';
    }
  }
  // Build difficulty badge
  Widget _buildDifficultyBadge(WorkoutDifficulty difficulty) {
    final Color color;
    final String label;

    switch (difficulty) {
      case WorkoutDifficulty.beginner:
        color = Colors.green;
        label = 'Beginner';
        break;
      case WorkoutDifficulty.intermediate:
        color = Colors.orange;
        label = 'Medium';
        break;
      case WorkoutDifficulty.advanced:
        color = Colors.red;
        label = 'Advanced';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getTimeLabel(TimeOfDay time) {
    if (time.hour < 10) return 'Morning';
    if (time.hour < 15) return 'Lunch';
    return 'Evening';
  }
}

// Add this helper extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
