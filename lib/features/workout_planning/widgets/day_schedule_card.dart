// lib/features/workout_planning/widgets/day_schedule_card.dart
import 'package:bums_n_tums/features/workout_analytics/providers/achievement_provider.dart';
import 'package:bums_n_tums/features/workout_planning/models/scheduled_workout.dart';
import 'package:bums_n_tums/features/workouts/models/workout_log.dart';
import 'package:bums_n_tums/features/workouts/providers/workout_provider.dart';
import 'package:bums_n_tums/features/workouts/screens/pre_workout_setup_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_completion_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_log_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workout_planning_provider.dart';
import '../../../shared/theme/app_colors.dart';
import 'logged_workout_item_widget.dart';
import 'scheduled_workout_item.dart';
import '../../../features/workouts/models/workout.dart';

class DayScheduleCard extends ConsumerWidget {
  final DateTime day;
  final List<PlannerItem> plannerItems;
  final String userId;
  final VoidCallback onAddWorkout;
  final VoidCallback onLogWorkout;
  final DateTime currentWeekStart;

  const DayScheduleCard({
    Key? key,
    required this.day,
    required this.plannerItems,
    required this.userId,
    required this.onAddWorkout,
    required this.onLogWorkout,
    required this.currentWeekStart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plannerItems.isNotEmpty)
            ...plannerItems.map((item) {
              if (item is PlannedWorkoutItem) {
                return ScheduledWorkoutItem(
                  scheduledWorkout: item.scheduledWorkout,
                  onTap: () => _handleItemTap(context, ref, item),
                  onDelete: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          title: const Text('Remove Scheduled Workout?'),
                          content: Text(
                            'Are you sure you want to remove "${item.scheduledWorkout.workout?.title ?? 'this workout'}" from your schedule?',
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                              },
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Remove'),
                              onPressed: () async {
                                Navigator.of(dialogContext).pop();
                                final scaffoldMessenger = ScaffoldMessenger.of(
                                  context,
                                );
                                try {
                                  final planningNotifier = ref.read(
                                    plannerItemsNotifierProvider(
                                      userId,
                                    ).notifier,
                                  );
                                  // Delete call remains the same
                                  await planningNotifier.deletePlannerItem(
                                    item,
                                  );

                                  ref
                                      .read(analyticsServiceProvider)
                                      .logEvent(
                                        name: 'scheduled_workout_deleted',
                                      );

                                  // --- Start of Changed Refresh Logic ---
                                  if (context.mounted) {
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '"${item.scheduledWorkout.workout?.title ?? 'Workout'}" removed.',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                  // --- End of Changed Refresh Logic ---
                                } catch (e) {
                                  print("Error deleting scheduled item: $e");
                                  if (context.mounted) {
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Error removing workout: $e",
                                        ),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onComplete: () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    try {
                      // Call the notifier's method (this part remains the same)
                      await ref
                          .read(plannerItemsNotifierProvider(userId).notifier)
                          .markScheduledItemComplete(item.scheduledWorkout);

                      // --- Start of Changed Refresh Logic ---
                      if (context.mounted) {
                        // Invalidate first

                        if (context.mounted) {
                          // Show success message only after fetch completes
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                "${item.scheduledWorkout.workout?.title ?? 'Workout'} marked as complete!",
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      print(
                        "DayScheduleCard: Error calling markScheduledItemComplete: $e",
                      );
                      if (context.mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text("Failed to mark complete: $e"),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                );
              } else {
                return const SizedBox.shrink();
              }
            }).toList()
          else
            _buildEmptyState(context),
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 32,
              color: AppColors.mediumGrey,
            ),
            const SizedBox(height: 8),
            Text(
              'Nothing planned or logged yet.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.mediumGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleItemTap(
    BuildContext context,
    WidgetRef ref,
    PlannerItem item,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final workoutService = ref.read(workoutServiceProvider);

    if (item is PlannedWorkoutItem) {
      final scheduledWorkout = item.scheduledWorkout;
      Workout? workout = await _fetchWorkoutDetailsIfNeeded(
        context,
        ref,
        scheduledWorkout,
      );

      // Fetch full details if needed (common for both paths)
      if (workout == null || workout.exercises.isEmpty) {
        print(
          "Fetching full workout details for ${scheduledWorkout.workoutId}...",
        );
        try {
          workout = await workoutService.getWorkoutById(
            scheduledWorkout.workoutId,
          );
          if (workout == null) {
            throw Exception(
              "Workout details not found for ID: ${scheduledWorkout.workoutId}",
            );
          }
          print("Fetched full workout details: ${workout.title}");
        } catch (e) {
          print("Error fetching workout details: $e");
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text("Error loading workout details: $e"),
              backgroundColor: AppColors.error,
            ),
          );
          return; // Stop if fetch fails
        }
      }

      // Now 'workout' should be non-null if we reached here
      if (scheduledWorkout.isCompleted) {
        // --- Navigate to WorkoutLogDetailScreen for COMPLETED Scheduled Item ---
        print(
          "Tapped completed scheduled item ${item.id}, navigating to WorkoutLogDetail.",
        );
        final DateTime? completionTime = scheduledWorkout.completedAt;
        if (completionTime != null) {
          // Construct the log representation
          final tempLog = WorkoutLog(
            id: scheduledWorkout.id,
            userId: userId,
            workoutId: workout.id,
            startedAt: completionTime.subtract(
              Duration(minutes: workout.durationMinutes),
            ),
            completedAt: completionTime,
            durationMinutes: workout.durationMinutes,
            caloriesBurned: workout.estimatedCaloriesBurn,
            exercisesCompleted: const [], // Placeholder
            userFeedback: const UserFeedback(rating: 3), // Placeholder
            workoutName: workout.title,
            workoutCategory: workout.category.name,
            targetAreas: workout.tags,
          );
          navigator.push(
            MaterialPageRoute(
              builder:
                  (_) => WorkoutLogDetailScreen(
                    // Navigate to new screen
                    workoutLog: tempLog, // Pass the constructed log
                    workoutContext: workout, // Pass the workout context
                  ),
            ),
          );
        } else {
          /* ... Error handling for missing completion time ... */
        }
        // --- End Navigation Change ---
      } else {
        print(
          "Tapped incomplete scheduled item ${item.id}, navigating to PreWorkoutSetup.",
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (_) => PreWorkoutSetupScreen(
                  workout: workout!,
                  // Pass the IDs needed to mark completion later
                  originPlanId: scheduledWorkout.planId,
                  originScheduledWorkoutId: scheduledWorkout.id,
                ),
          ),
        );
      }
    } else if (item is LoggedWorkoutItem) {
      // --- Navigate to WorkoutLogDetailScreen for LOGGED Item ---
      print("Tapped logged item ${item.id}, navigating to WorkoutLogDetail.");
      Workout? workoutContext;
      try {
        workoutContext = await workoutService.getWorkoutById(
          item.workoutLog.workoutId,
        );
        // No need to throw if context isn't found, screen can handle it
        navigator.push(
          MaterialPageRoute(
            builder:
                (_) => WorkoutLogDetailScreen(
                  // Navigate to new screen
                  workoutLog: item.workoutLog, // Pass the actual log
                  workoutContext: workoutContext, // Pass optional context
                ),
          ),
        );
      } catch (e) {
        // Fallback if fetch itself fails drastically
        print("Error loading workout context for log ${item.id}: $e");
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("Could not load workout details for this log: $e"),
            backgroundColor: AppColors.error,
          ),
        );
      }
      // --- End Navigation Change ---
    }
  }

  Future<Workout?> _fetchWorkoutDetailsIfNeeded(
    BuildContext context,
    WidgetRef ref,
    ScheduledWorkout scheduledWorkout,
  ) async {
    Workout? workout = scheduledWorkout.workout;
    if (workout == null || workout.exercises.isEmpty) {
      print(
        "Fetching full workout details for ${scheduledWorkout.workoutId}...",
      );
      try {
        final workoutService = ref.read(workoutServiceProvider);
        workout = await workoutService.getWorkoutById(
          scheduledWorkout.workoutId,
        );
        if (workout == null) {
          throw Exception(
            "Workout details not found for ID: ${scheduledWorkout.workoutId}",
          );
        }
        print("Fetched full workout details: ${workout.title}");
        return workout;
      } catch (e) {
        print("Error fetching workout details: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading workout details: $e"),
            backgroundColor: AppColors.error,
          ),
        );
        return null; // Indicate failure
      }
    }
    return workout; // Return already loaded or fetched workout
  }
}
