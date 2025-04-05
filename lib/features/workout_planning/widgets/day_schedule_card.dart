// lib/features/workout_planning/widgets/day_schedule_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scheduled_workout.dart';
import '../providers/workout_planning_provider.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import 'scheduled_workout_item.dart';

class DayScheduleCard extends ConsumerWidget {
  final DateTime day;
  final List<ScheduledWorkout> workouts;
  final String userId;
  final Function(ScheduledWorkout) onWorkoutTap;
  final VoidCallback onAddWorkout;

  const DayScheduleCard({
    Key? key,
    required this.day,
    required this.workouts,
    required this.userId,
    required this.onWorkoutTap,
    required this.onAddWorkout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final analyticsService = AnalyticsService();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scheduled workouts
          if (workouts.isNotEmpty)
            ...workouts
                .map(
                  (workout) => ScheduledWorkoutItem(
                    scheduledWorkout: workout,
                    onTap: () => onWorkoutTap(workout),
                    onDelete: () {
                      // Delete the workout
                      ref
                          .read(
                            workoutPlanningNotifierProvider(userId).notifier,
                          )
                          .deleteScheduledWorkout(workout.id);

                      analyticsService.logEvent(
                        name: 'scheduled_workout_deleted',
                      );
                    },
                    onComplete: () {
                      // Mark as completed
                      ref
                          .read(
                            workoutPlanningNotifierProvider(userId).notifier,
                          )
                          .markWorkoutCompleted(workout.id);

                      analyticsService.logEvent(
                        name: 'scheduled_workout_completed',
                      );
                    },
                  ),
                )
                .toList()
          else
            _buildEmptyState(context),

          // Add workout button
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton.icon(
              onPressed: onAddWorkout,
              icon: Icon(Icons.add_circle, size: 16, color: AppColors.popBlue),
              label: Text(
                'Add Workout',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.popBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.paleGrey),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 32,
            color: AppColors.mediumGrey,
          ),
          const SizedBox(height: 8),
          Text(
            'No workouts scheduled',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.mediumGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add a workout to your schedule',
            style: textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
          ),
        ],
      ),
    );
  }
}
