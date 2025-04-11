// lib/features/workout_planning/widgets/day_schedule_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workout_planning_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import 'logged_workout_item_widget.dart';
import 'scheduled_workout_item.dart';

class DayScheduleCard extends ConsumerWidget {
  final DateTime day;

  final List<PlannerItem> plannerItems;
  final String userId;

  final Function(PlannerItem) onWorkoutTap;
  final VoidCallback onAddWorkout;
  final VoidCallback onLogWorkout;

  const DayScheduleCard({
    Key? key,
    required this.day,
    required this.plannerItems,
    required this.userId,
    required this.onWorkoutTap,
    required this.onAddWorkout,
    required this.onLogWorkout,
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
          if (plannerItems.isNotEmpty)
            ...plannerItems.map((item) {
              if (item is PlannedWorkoutItem) {
                return ScheduledWorkoutItem(
                  scheduledWorkout: item.scheduledWorkout,
                  onTap: () => onWorkoutTap(item),
                  onDelete: () {
                    ref
                        .read(plannerItemsNotifierProvider(userId).notifier)
                        .deletePlannerItem(item);

                    analyticsService.logEvent(
                      name: 'scheduled_workout_deleted',
                    );
                  },

                  onComplete: () {
                    print(
                      "Start workout tapped for planned item: ${item.scheduledWorkout.workout?.title}",
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Start workout: ${item.scheduledWorkout.workout?.title}",
                        ),
                      ),
                    );
                  },
                );
              } else if (item is LoggedWorkoutItem) {
                return LoggedWorkoutItemWidget(
                  workoutLog: item.workoutLog,
                  onTap: () => onWorkoutTap(item),
                  onDelete: () {
                    print(
                      "Attempting to delete logged item: ${item.workoutLog.workoutName}",
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Deleting logs not implemented yet."),
                      ),
                    );
                  },
                );
              } else {
                return const SizedBox.shrink();
              }
            }).toList()
          else
            _buildEmptyState(context),

          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: onAddWorkout,
                  icon: Icon(
                    Icons.add_circle_outline,
                    size: 18,
                    color: AppColors.popBlue,
                  ),
                  label: Text(
                    'Schedule',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.popBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                TextButton.icon(
                  onPressed: onLogWorkout,
                  icon: Icon(
                    Icons.note_add_outlined,
                    size: 18,
                    color: AppColors.popGreen,
                  ),
                  label: Text(
                    'Log',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.popGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
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
            Icons.calendar_today_outlined,
            size: 32,
            color: AppColors.mediumGrey,
          ),
          const SizedBox(height: 8),
          Text(
            'Nothing for today',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.mediumGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Schedule or log a workout',
            style: textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
          ),
        ],
      ),
    );
  }
}
