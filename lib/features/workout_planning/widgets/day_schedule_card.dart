// lib/features/workout_planning/widgets/day_schedule_card.dart
import 'package:bums_n_tums/features/workouts/models/workout_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scheduled_workout.dart'; // Keep for PlannedWorkoutItem
import '../providers/workout_planning_provider.dart'; // Keep for PlannerItem definition and provider
import '../../../shared/theme/color_palette.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import 'logged_workout_item_widget.dart'; // --- Import new widget for logged items ---
import 'scheduled_workout_item.dart'; // Keep for planned items

class DayScheduleCard extends ConsumerWidget {
  final DateTime day;
  // --- Change input parameter ---
  final List<PlannerItem> plannerItems;
  final String userId;
  // --- Update callback signature ---
  final Function(PlannerItem) onWorkoutTap;
  final VoidCallback onAddWorkout; // To schedule a new workout
  final VoidCallback onLogWorkout; // --- Add callback for logging ---


  const DayScheduleCard({
    Key? key,
    required this.day,
    required this.plannerItems, // Use new parameter name
    required this.userId,
    required this.onWorkoutTap,
    required this.onAddWorkout,
    required this.onLogWorkout, // Add required callback
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final analyticsService = AnalyticsService();

    // --- Sort items maybe? (e.g., planned before logged, or by time if available) ---
    // plannerItems.sort((a, b) => ... ); // Optional sorting logic

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Render items based on type ---
          if (plannerItems.isNotEmpty)
            ...plannerItems.map((item) {
              if (item is PlannedWorkoutItem) {
                // Render Planned Workout
                return ScheduledWorkoutItem(
                  scheduledWorkout: item.scheduledWorkout,
                  onTap: () => onWorkoutTap(item), // Pass the PlannerItem
                  onDelete: () {
                    // Delete the planned workout
                    ref
                        .read(plannerItemsNotifierProvider(userId).notifier)
                        .deletePlannerItem(item); // Use new delete method

                    analyticsService.logEvent(
                      name: 'scheduled_workout_deleted', // Keep or adjust event name
                    );
                  },
                  // Decide what 'onComplete' means now. Maybe 'Start Workout'?
                  onComplete: () {
                    // Maybe navigate to start the workout?
                    print("Start workout tapped for planned item: ${item.scheduledWorkout.workout?.title}");
                     ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Start workout: ${item.scheduledWorkout.workout?.title}"))
                      );
                    // Original completion logic is removed as logs handle completion state
                  },
                );
              } else if (item is LoggedWorkoutItem) {
                // Render Logged Workout (Using a new dedicated widget)
                return LoggedWorkoutItemWidget( // --- Use new widget ---
                  workoutLog: item.workoutLog,
                  onTap: () => onWorkoutTap(item), // Pass the PlannerItem
                   onDelete: () {
                     // Optionally allow deleting logs (implement in notifier first)
                     print("Attempting to delete logged item: ${item.workoutLog.workoutName}");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Deleting logs not implemented yet."))
                      );
                     // ref.read(plannerItemsNotifierProvider(userId).notifier).deletePlannerItem(item);
                   },
                );
              } else {
                // Handle unknown item types if necessary
                return const SizedBox.shrink();
              }
            }).toList()
          else
            _buildEmptyState(context), // Show empty state if list is empty

          // Buttons Row
          Padding(
             padding: const EdgeInsets.only(top: 8.0),
             child: Row(
               children: [
                 // Add workout button (to schedule)
                 TextButton.icon(
                   onPressed: onAddWorkout,
                   icon: Icon(Icons.add_circle_outline, size: 18, color: AppColors.popBlue),
                   label: Text(
                     'Schedule', // Changed label for clarity
                     style: textTheme.bodyMedium?.copyWith(
                       color: AppColors.popBlue,
                       fontWeight: FontWeight.w500,
                     ),
                   ),
                   style: TextButton.styleFrom(
                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     // visualDensity: VisualDensity.compact,
                   ),
                 ),
                 const SizedBox(width: 8),
                 // Log workout button (manual log)
                 TextButton.icon(
                   onPressed: onLogWorkout, // Use the new callback
                   icon: Icon(Icons.note_add_outlined, size: 18, color: AppColors.popGreen),
                   label: Text(
                     'Log', // Label for logging
                     style: textTheme.bodyMedium?.copyWith(
                       color: AppColors.popGreen,
                       fontWeight: FontWeight.w500,
                     ),
                   ),
                    style: TextButton.styleFrom(
                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     // visualDensity: VisualDensity.compact,
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
     // (Empty state code remains the same)
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
            Icons.calendar_today_outlined, // Changed icon slightly
            size: 32,
            color: AppColors.mediumGrey,
          ),
          const SizedBox(height: 8),
          Text(
            'Nothing for today', // Updated text
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.mediumGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Schedule or log a workout', // Updated text
            style: textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
          ),
        ],
      ),
    );
  }
}