// lib/features/workout_planning/widgets/day_schedule_card.dart

import 'package:flutter/foundation.dart';
import 'package:bums_n_tums/features/workout_analytics/providers/achievement_provider.dart';
import 'package:bums_n_tums/features/workout_planning/models/scheduled_workout.dart';
import 'package:bums_n_tums/features/workouts/models/workout_log.dart';
import 'package:bums_n_tums/features/workouts/providers/workout_provider.dart';
import 'package:bums_n_tums/features/workouts/screens/pre_workout_setup_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_log_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/workout_planning_provider.dart';
import '../../../shared/theme/app_colors.dart';
import 'logged_workout_item_widget.dart';
import 'scheduled_workout_item.dart';
import '../../../features/workouts/models/workout.dart';
import '../models/planner_item.dart';
import '../../../shared/providers/analytics_provider.dart';


// Class definition and build method remain the same
class DayScheduleCard extends ConsumerWidget {
  final DateTime day;
  final List<PlannerItem> plannerItems;
  final String userId; // userId is still available if needed elsewhere
  final VoidCallback onAddWorkout;
  final VoidCallback onLogWorkout;
  final DateTime currentWeekStart;

  const DayScheduleCard({
    super.key,
    required this.day,
    required this.plannerItems,
    required this.userId,
    required this.onAddWorkout,
    required this.onLogWorkout,
    required this.currentWeekStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    final sortedItems = List<PlannerItem>.from(plannerItems)..sort((a, b) {
      if (a is PlannedWorkoutItem && b is LoggedWorkoutItem) return -1;
      if (a is LoggedWorkoutItem && b is PlannedWorkoutItem) return 1;
      return a.itemDate.compareTo(b.itemDate);
    });

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((255 * 0.1).round()),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sortedItems.isNotEmpty)
            ...sortedItems.map((item) {
              if (item is PlannedWorkoutItem) {
                return ScheduledWorkoutItem(
                  scheduledWorkout: item.scheduledWorkout,
                  onTap: () => _handleItemTap(context, ref, item),
                  onDelete: () => _showDeleteConfirmation(context, ref, item),
                  onComplete: () => _markScheduledComplete(context, ref, item),
                );
              } else if (item is LoggedWorkoutItem) {
                return LoggedWorkoutItemWidget(
                   workoutLog: item.workoutLog,
                   onTap: () => _handleItemTap(context, ref, item),
                   onDelete: () => _showDeleteLogConfirmation(context, ref, item),
                );
              }
              else {
                return const SizedBox.shrink();
              }
            })
          else
            _buildEmptyState(context),
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: onAddWorkout,
                  icon: Icon( Icons.add_circle_outline, size: 18, color: AppColors.popBlue,),
                  label: Text('Schedule', style: textTheme.bodyMedium?.copyWith(color: AppColors.popBlue, fontWeight: FontWeight.w500, ),),
                  style: TextButton.styleFrom( padding: const EdgeInsets.symmetric( horizontal: 10, vertical: 6,), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(16),),),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onLogWorkout,
                  icon: Icon( Icons.note_add_outlined, size: 18, color: AppColors.popGreen,),
                  label: Text('Log', style: textTheme.bodyMedium?.copyWith( color: AppColors.popGreen, fontWeight: FontWeight.w500,),),
                  style: TextButton.styleFrom( padding: const EdgeInsets.symmetric( horizontal: 10, vertical: 6, ), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(16), ),),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // --- Helper Methods ---

  // _showDeleteConfirmation, _showDeleteLogConfirmation, _buildEmptyState remain the same
  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, PlannedWorkoutItem item) {
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
               onPressed: () { Navigator.of(dialogContext).pop(); },
             ),
             TextButton(
               style: TextButton.styleFrom( foregroundColor: Colors.red, ),
               child: const Text('Remove'),
               onPressed: () async {
                 Navigator.of(dialogContext).pop();
                 final scaffoldMessenger = ScaffoldMessenger.of(context);
                 final analytics = ref.read(analyticsServiceProvider);
                 try {
                   final planningNotifier = ref.read(
                     plannerItemsNotifierProvider(userId).notifier,
                   );
                   await planningNotifier.deletePlannerItem(item);
                   analytics.logEvent(name: 'scheduled_workout_deleted', parameters: {
                      'workout_id': item.scheduledWorkout.workoutId,
                      'workout_name': item.scheduledWorkout.workout?.title ?? 'Unknown',
                   });
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
                 } catch (e) {
                    if (kDebugMode) {
                      print("Error deleting scheduled item: $e");
                    }
                   analytics.logError(error: "Failed to delete scheduled workout: $e", parameters: {'item_id': item.scheduledWorkout.id});
                   if (context.mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text("Error removing workout: $e"),
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
   }

  void _showDeleteLogConfirmation(BuildContext context, WidgetRef ref, LoggedWorkoutItem item) {
     showDialog(
       context: context,
       builder: (BuildContext dialogContext) {
         return AlertDialog(
           title: const Text('Delete Workout Log?'),
           content: Text(
             'Are you sure you want to permanently delete the log for "${item.workoutLog.workoutName ?? 'this workout'}" completed on ${DateFormat.yMd().add_jm().format(item.itemDate)}?',
           ),
           actions: <Widget>[
             TextButton(
               child: const Text('Cancel'),
               onPressed: () { Navigator.of(dialogContext).pop(); },
             ),
             TextButton(
               style: TextButton.styleFrom( foregroundColor: Colors.red, ),
               child: const Text('Delete'),
               onPressed: () async {
                 Navigator.of(dialogContext).pop();
                 final scaffoldMessenger = ScaffoldMessenger.of(context);
                 final analytics = ref.read(analyticsServiceProvider);
                 try {
                   final planningNotifier = ref.read(
                     plannerItemsNotifierProvider(userId).notifier,
                   );
                   await planningNotifier.deletePlannerItem(item);
                   analytics.logEvent(name: 'workout_log_deleted_from_plan', parameters: {
                      'log_id': item.workoutLog.id,
                      'workout_id': item.workoutLog.workoutId,
                      'workout_name': item.workoutLog.workoutName ?? 'Unknown',
                   });
                   if (context.mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Workout log deleted.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                   }
                 } catch (e) {
                    if (kDebugMode) {
                      print("Error deleting logged item: $e");
                    }
                   analytics.logError(error: "Failed to delete workout log: $e", parameters: {'log_id': item.workoutLog.id});
                   if (context.mounted) {
                     scaffoldMessenger.showSnackBar(
                       SnackBar(
                         content: Text("Error deleting log: $e"),
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
   }

   // --- Method with Corrected Provider Invalidation ---
   Future<void> _markScheduledComplete(BuildContext context, WidgetRef ref, PlannedWorkoutItem item) async {
     final scaffoldMessenger = ScaffoldMessenger.of(context);
     final analytics = ref.read(analyticsServiceProvider);
     try {
       await ref.read(plannerItemsNotifierProvider(userId).notifier)
           .markScheduledItemComplete(item.scheduledWorkout);

        analytics.logEvent(name: 'scheduled_workout_marked_complete', parameters: {
             'workout_id': item.scheduledWorkout.workoutId,
             'workout_name': item.scheduledWorkout.workout?.title ?? 'Unknown',
          });

       // Invalidate the base provider WITHOUT family argument
       ref.invalidate(userAchievementsProvider);

       if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text("${item.scheduledWorkout.workout?.title ?? 'Workout'} marked as complete!"),
              backgroundColor: AppColors.success,
            ),
          );
       }

     } catch (e) {
        if (kDebugMode) {
          print("DayScheduleCard: Error calling markScheduledItemComplete: $e");
        }
       analytics.logError(error: "Failed to mark scheduled complete: $e", parameters: {'item_id': item.scheduledWorkout.id});
       if (context.mounted) {
         scaffoldMessenger.showSnackBar(
           SnackBar(
             content: Text("Failed to mark complete: $e"),
             backgroundColor: AppColors.error,
           ),
         );
       }
     }
   }
   // --- End Corrected Method ---

   Widget _buildEmptyState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Column(
          children: [
            Icon( Icons.event_note_outlined, size: 32, color: AppColors.mediumGrey,),
            const SizedBox(height: 8),
            Text( 'Nothing planned or logged yet.', style: textTheme.bodyMedium?.copyWith( color: AppColors.mediumGrey, ),),
          ],
        ),
      ),
    );
  }

  // _handleItemTap, _fetchWorkoutDetailsIfNeeded remain the same
  Future<void> _handleItemTap( BuildContext context, WidgetRef ref, PlannerItem item) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final workoutService = ref.read(workoutServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);

    if (item is PlannedWorkoutItem) {
      final scheduledWorkout = item.scheduledWorkout;
      analytics.logEvent(name: 'plan_item_tapped', parameters: {
        'item_type': 'planned',
        'item_id': scheduledWorkout.id,
        'workout_id': scheduledWorkout.workoutId,
        'is_completed': scheduledWorkout.isCompleted,
      });

      Workout? workout = await _fetchWorkoutDetailsIfNeeded(context, ref, scheduledWorkout);
      if (workout == null) { return; }

      if (scheduledWorkout.isCompleted) {
         if (kDebugMode) {
           print("Tapped completed scheduled item ${scheduledWorkout.id}, navigating to WorkoutLogDetail.");
         }
        final DateTime? completionTime = scheduledWorkout.completedAt;
        if (completionTime != null) {
          final tempLog = WorkoutLog(
            id: 'scheduled-${scheduledWorkout.id}', userId: userId, workoutId: workout.id,
            startedAt: completionTime.subtract(Duration(minutes: workout.durationMinutes)),
            completedAt: completionTime, durationMinutes: workout.durationMinutes,
            caloriesBurned: workout.estimatedCaloriesBurn, exercisesCompleted: const [],
            userFeedback: const UserFeedback(rating: 3), workoutName: workout.title,
            workoutCategory: workout.category.name, targetAreas: workout.tags,
            source: WorkoutLogSource.scheduled,
          );
          navigator.push( MaterialPageRoute( builder: (_) => WorkoutLogDetailScreen( workoutLog: tempLog, workoutContext: workout,),),);
        } else {
          analytics.logError(error: "Completed scheduled workout missing completion time", parameters: {'item_id': scheduledWorkout.id});
           if (context.mounted) {
              scaffoldMessenger.showSnackBar( SnackBar( content: Text("Error: Completion time missing for this completed workout."), backgroundColor: AppColors.error, ),);
           }
        }
      } else {
         if (kDebugMode) {
           print("Tapped incomplete scheduled item ${scheduledWorkout.id}, navigating to PreWorkoutSetup.");
         }
        navigator.push( MaterialPageRoute( builder: (_) => PreWorkoutSetupScreen( workout: workout, originPlanId: scheduledWorkout.planId, originScheduledWorkoutId: scheduledWorkout.id,),),);
      }
    } else if (item is LoggedWorkoutItem) {
       analytics.logEvent(name: 'plan_item_tapped', parameters: {
         'item_type': 'logged',
         'item_id': item.workoutLog.id,
         'workout_id': item.workoutLog.workoutId,
       });
        if (kDebugMode) {
          print("Tapped logged item ${item.workoutLog.id}, navigating to WorkoutLogDetail.");
        }
      Workout? workoutContext;
      try {
        workoutContext = await workoutService.getWorkoutById(item.workoutLog.workoutId);
        navigator.push( MaterialPageRoute( builder: (_) => WorkoutLogDetailScreen( workoutLog: item.workoutLog, workoutContext: workoutContext,),),);
      } catch (e) {
         analytics.logError(error: "Failed to fetch workout context for log: $e", parameters: {'log_id': item.workoutLog.id, 'workout_id': item.workoutLog.workoutId});
         if (kDebugMode) {
           print("Error loading workout context for log ${item.workoutLog.id}: $e");
         }
         navigator.push( MaterialPageRoute( builder: (_) => WorkoutLogDetailScreen( workoutLog: item.workoutLog, workoutContext: null,),),);
          if (context.mounted) {
            scaffoldMessenger.showSnackBar( SnackBar( content: Text("Could not load full workout details for this log."), backgroundColor: Colors.orange, ),);
          }
      }
    }
  }

  Future<Workout?> _fetchWorkoutDetailsIfNeeded( BuildContext context, WidgetRef ref, ScheduledWorkout scheduledWorkout,) async {
    Workout? workout = scheduledWorkout.workout;
    final analytics = ref.read(analyticsServiceProvider);

    if (workout == null || (workout.exercises.isEmpty && workout.sections.isEmpty) ) {
       if (kDebugMode) {
         print("Fetching full workout details for ${scheduledWorkout.workoutId}...");
       }
      analytics.logEvent(name: 'plan_fetch_workout_details', parameters: {'workout_id': scheduledWorkout.workoutId});
      try {
        final workoutService = ref.read(workoutServiceProvider);
        workout = await workoutService.getWorkoutById(scheduledWorkout.workoutId);
        if (workout == null) {
          throw Exception("Workout details not found for ID: ${scheduledWorkout.workoutId}");
        }
         if (kDebugMode) {
           print("Fetched full workout details: ${workout.title}");
         }
        return workout;
      } catch (e) {
         if (kDebugMode) {
           print("Error fetching workout details: $e");
         }
        analytics.logError(error: "Failed fetching workout details: $e", parameters: {'workout_id': scheduledWorkout.workoutId});
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: Text("Error loading workout details: $e"), backgroundColor: AppColors.error,),);
        }
        return null;
      }
    }
     if (kDebugMode) {
       print("Using pre-loaded/cached workout details for ${workout.title}");
     }
    return workout;
  }

} // End of DayScheduleCard class