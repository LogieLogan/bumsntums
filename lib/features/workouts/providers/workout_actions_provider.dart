// lib/features/workouts/providers/workout_actions_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../models/workout_plan.dart';
import '../services/workout_planning_service.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/providers/analytics_provider.dart';
import 'workout_planning_provider.dart';

class WorkoutActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final WorkoutPlanningService _planningService;
  final AnalyticsService _analytics;

  WorkoutActionsNotifier(this._planningService, this._analytics)
      : super(const AsyncValue.data(null));

  Future<bool> scheduleWorkout({
    required String userId,
    required String planId,
    required Workout workout,
    required DateTime date,
    bool reminderEnabled = true,
    DateTime? reminderTime,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      print(
        '⭐ Attempting to schedule workout: ${workout.title} on ${date.toString()}',
      );
      print('⭐ Using planId: $planId for user: $userId');

      // Get current plan
      final plan = await _planningService.getWorkoutPlan(userId, planId);
      if (plan == null) {
        print('❌ Plan not found with ID: $planId');
        state = const AsyncValue.data(null);
        return false;
      }

      print(
        '✅ Found plan: ${plan.name} with ${plan.scheduledWorkouts.length} existing workouts',
      );

      // Create scheduled workout
      final scheduledWorkout = ScheduledWorkout(
        workoutId: workout.id,
        title: workout.title,
        workoutImageUrl: workout.imageUrl,
        scheduledDate: date,
        reminderEnabled: reminderEnabled,
        reminderTime:
            reminderTime ??
            DateTime(
              date.year,
              date.month,
              date.day,
              18, // Default 6 PM reminder
              0,
            ),
        workoutCategory: workout.category.name,
        workoutDifficulty: workout.difficulty.name,
        durationMinutes: workout.durationMinutes,
        // Add more fields as needed
      );

      // Add to plan's scheduled workouts
      final updatedScheduled = [...plan.scheduledWorkouts, scheduledWorkout];
      final updatedPlan = plan.copyWith(
        scheduledWorkouts: updatedScheduled,
        updatedAt: DateTime.now(),
      );

      // Update plan in database
      await _planningService.updateWorkoutPlan(updatedPlan);

      // Log analytics
      _analytics.logEvent(
        name: 'workout_scheduled',
        parameters: {
          'workout_id': workout.id,
          'plan_id': planId,
          'date': date.toIso8601String(),
        },
      );

      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      print('❌ Error scheduling workout: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  // Reschedule a workout to a new date
  Future<bool> rescheduleWorkout({
    required String userId,
    required String planId,
    required String workoutId,
    required DateTime oldDate,
    required DateTime newDate,
    required bool applyToSeries,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      // Get current plan
      final plan = await _planningService.getWorkoutPlan(userId, planId);
      if (plan == null) {
        state = const AsyncValue.data(null);
        return false;
      }

      // Find the specific workout to reschedule
      final List<ScheduledWorkout> updatedScheduled = [];
      bool found = false;

      for (final scheduled in plan.scheduledWorkouts) {
        if (scheduled.workoutId == workoutId &&
            scheduled.scheduledDate.year == oldDate.year &&
            scheduled.scheduledDate.month == oldDate.month &&
            scheduled.scheduledDate.day == oldDate.day) {
          // Found the workout to reschedule
          found = true;

          if (applyToSeries && scheduled.isRecurring) {
            // If applying to series and this is a recurring workout,
            // handle recurrence pattern adjustment
            // For now, just update this instance
            updatedScheduled.add(scheduled.copyWith(scheduledDate: newDate));
          } else {
            // Just update this specific instance
            updatedScheduled.add(scheduled.copyWith(scheduledDate: newDate));
          }
        } else {
          // Keep other workouts as they are
          updatedScheduled.add(scheduled);
        }
      }

      if (!found) {
        state = const AsyncValue.data(null);
        return false;
      }

      // Update plan with rescheduled workouts
      final updatedPlan = plan.copyWith(
        scheduledWorkouts: updatedScheduled,
        updatedAt: DateTime.now(),
      );

      // Update plan in database
      await _planningService.updateWorkoutPlan(updatedPlan);

      // Log analytics
      _analytics.logEvent(
        name: 'workout_rescheduled',
        parameters: {
          'workout_id': workoutId,
          'plan_id': planId,
          'old_date': oldDate.toIso8601String(),
          'new_date': newDate.toIso8601String(),
          'apply_to_series': applyToSeries,
        },
      );

      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      print('Error rescheduling workout: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  // Set up recurring workout
  Future<bool> setRecurringWorkout({
    required String userId,
    required String planId,
    required String workoutId,
    required DateTime startDate,
    required String recurrencePattern,
    required int occurrences,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      // Get current plan
      final plan = await _planningService.getWorkoutPlan(userId, planId);
      if (plan == null) {
        state = const AsyncValue.data(null);
        return false;
      }

      // Find the specific workout to make recurring
      final List<ScheduledWorkout> updatedScheduled = [];
      ScheduledWorkout? targetWorkout;

      for (final scheduled in plan.scheduledWorkouts) {
        if (scheduled.workoutId == workoutId &&
            scheduled.scheduledDate.year == startDate.year &&
            scheduled.scheduledDate.month == startDate.month &&
            scheduled.scheduledDate.day == startDate.day) {
          // Found the workout to make recurring
          targetWorkout = scheduled;
          // Add the updated version to the list
          updatedScheduled.add(
            scheduled.copyWith(
              isRecurring: true,
              recurrencePattern: recurrencePattern,
            ),
          );
        } else {
          // Keep other workouts as they are
          updatedScheduled.add(scheduled);
        }
      }

      if (targetWorkout == null) {
        state = const AsyncValue.data(null);
        return false;
      }

      // Now add the recurring instances
      // Pattern can be 'daily', 'weekly', 'monthly', etc.
      if (recurrencePattern == 'daily') {
        for (int i = 1; i < occurrences; i++) {
          final newDate = startDate.add(Duration(days: i));
          updatedScheduled.add(
            targetWorkout.copyWith(
              scheduledDate: newDate,
              isRecurring: true,
              recurrencePattern: recurrencePattern,
            ),
          );
        }
      } else if (recurrencePattern == 'weekly') {
        for (int i = 1; i < occurrences; i++) {
          final newDate = startDate.add(Duration(days: i * 7));
          updatedScheduled.add(
            targetWorkout.copyWith(
              scheduledDate: newDate,
              isRecurring: true,
              recurrencePattern: recurrencePattern,
            ),
          );
        }
      } else if (recurrencePattern == 'monthly') {
        for (int i = 1; i < occurrences; i++) {
          // Simple implementation - more robust would handle month lengths
          final newDate = DateTime(
            startDate.year,
            startDate.month + i,
            startDate.day,
          );
          updatedScheduled.add(
            targetWorkout.copyWith(
              scheduledDate: newDate,
              isRecurring: true,
              recurrencePattern: recurrencePattern,
            ),
          );
        }
      }

      // Update plan with recurring workouts
      final updatedPlan = plan.copyWith(
        scheduledWorkouts: updatedScheduled,
        updatedAt: DateTime.now(),
      );

      // Update plan in database
      await _planningService.updateWorkoutPlan(updatedPlan);

      // Log analytics
      _analytics.logEvent(
        name: 'recurring_workout_set',
        parameters: {
          'workout_id': workoutId,
          'plan_id': planId,
          'pattern': recurrencePattern,
          'occurrences': occurrences,
        },
      );

      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      print('Error setting recurring workout: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  // Delete a scheduled workout
  Future<bool> deleteScheduledWorkout({
    required String userId,
    required String planId,
    required String workoutId,
    required DateTime date,
    required bool deleteAllRecurring,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      // Get current plan
      final plan = await _planningService.getWorkoutPlan(userId, planId);
      if (plan == null) {
        state = const AsyncValue.data(null);
        return false;
      }

      // Filter out the workouts to delete
      final List<ScheduledWorkout> updatedScheduled = [];

      for (final scheduled in plan.scheduledWorkouts) {
        // If this is the workout to delete
        if (scheduled.workoutId == workoutId &&
            scheduled.scheduledDate.year == date.year &&
            scheduled.scheduledDate.month == date.month &&
            scheduled.scheduledDate.day == date.day) {
          // Skip this workout (don't add to updated list)
          continue;
        }

        // If deleting all recurring instances
        if (deleteAllRecurring &&
            scheduled.workoutId == workoutId &&
            scheduled.isRecurring &&
            scheduled.recurrencePattern ==
                plan.scheduledWorkouts
                    .firstWhere(
                      (s) =>
                          s.workoutId == workoutId &&
                          s.scheduledDate.year == date.year &&
                          s.scheduledDate.month == date.month &&
                          s.scheduledDate.day == date.day,
                    )
                    .recurrencePattern) {
          // Skip this recurring workout
          continue;
        }

        // Keep all other workouts
        updatedScheduled.add(scheduled);
      }

      // Update plan with filtered workouts
      final updatedPlan = plan.copyWith(
        scheduledWorkouts: updatedScheduled,
        updatedAt: DateTime.now(),
      );

      // Update plan in database
      await _planningService.updateWorkoutPlan(updatedPlan);

      // Log analytics
      _analytics.logEvent(
        name: 'scheduled_workout_deleted',
        parameters: {
          'workout_id': workoutId,
          'plan_id': planId,
          'date': date.toIso8601String(),
          'delete_all_recurring': deleteAllRecurring,
        },
      );

      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      print('Error deleting scheduled workout: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

// Provider for workout actions
final workoutActionsProvider = 
    StateNotifierProvider<WorkoutActionsNotifier, AsyncValue<void>>((ref) {
      final planningService = ref.watch(workoutPlanningServiceProvider);
      final analytics = ref.watch(analyticsServiceProvider);
      return WorkoutActionsNotifier(planningService, analytics);
    });