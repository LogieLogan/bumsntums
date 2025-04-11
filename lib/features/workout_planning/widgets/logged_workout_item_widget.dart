// File: lib/features/workout_planning/widgets/logged_workout_item_widget.dart
import 'package:bums_n_tums/features/workouts/models/workout_log.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_colors.dart'; // Adjust import path

class LoggedWorkoutItemWidget extends StatelessWidget {
  final WorkoutLog workoutLog;
  final VoidCallback onTap;
  final VoidCallback onDelete; // Optional delete action

  const LoggedWorkoutItemWidget({
    Key? key,
    required this.workoutLog,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final timeFormatter = DateFormat('h:mm a'); // Format time

    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.popGreen.withOpacity(0.5),
        ), // Green border for logged items
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Icon indicating completed/logged
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.popGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.popGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Workout details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workoutLog.workoutName ?? 'Logged Workout',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // Show time completed and duration
                      'Completed ${timeFormatter.format(workoutLog.completedAt)} • ${workoutLog.durationMinutes} min',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.mediumGrey,
                      ),
                    ),
                    // Optionally show category or calories
                    if (workoutLog.workoutCategory != null)
                      Column(
                        // Wrap conditional widgets in a Column or use direct listing
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            'Category: ${workoutLog.workoutCategory}',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.mediumGrey,
                            ),
                          ),
                        ],
                      ), // No spread operator needed here

                    if (workoutLog.caloriesBurned > 0)
                      Column(
                        // Wrap conditional widgets in a Column or use direct listing
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            'Calories: ${workoutLog.caloriesBurned} kcal',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.mediumGrey,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: AppColors.mediumGrey,
                  size: 20,
                ),
                onPressed: onDelete,
                tooltip: 'Delete Log Entry',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
