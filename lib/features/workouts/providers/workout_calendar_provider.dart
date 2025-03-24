// lib/features/workouts/providers/workout_calendar_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_log.dart';
import '../models/workout_plan.dart';
import '../models/workout.dart';
import '../services/workout_planning_service.dart';
import '../services/workout_stats_service.dart';
import 'workout_planning_provider.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/providers/analytics_provider.dart';

final Set<String> _loggedRanges = {};

// Provider for workout planning service
final workoutPlanningServiceProvider = Provider<WorkoutPlanningService>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return WorkoutPlanningService(analytics);
});

// Provider for workout stats service
final workoutStatsServiceProvider = Provider<WorkoutStatsService>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return WorkoutStatsService(analytics);
});

// Provider for workout calendar data (completed workouts)
final workoutCalendarDataProvider = FutureProvider.family<
  Map<DateTime, List<WorkoutLog>>,
  ({String userId, DateTime startDate, DateTime endDate})
>((ref, params) async {
  final statsService = ref.watch(workoutStatsServiceProvider);
  return statsService.getWorkoutHistoryByWeek(
    params.userId,
    params.startDate,
    params.endDate,
  );
});

final combinedCalendarEventsProvider = FutureProvider.family<
  Map<DateTime, List<dynamic>>,
  ({String userId, DateTime startDate, DateTime endDate})
>((ref, params) async {
  try {
    // Get completed workouts
    final workoutsByDate = await ref.watch(
      workoutCalendarDataProvider(params).future,
    );

    // Log only once per unique date range
    final rangeKey = '${params.startDate}-${params.endDate}';
    if (!_loggedRanges.contains(rangeKey)) {
      print('📆 Fetching calendar events for date range: ${params.startDate} to ${params.endDate}');
      print('📆 Found ${workoutsByDate.length} dates with completed workouts');
      _loggedRanges.add(rangeKey);
    }

    // Process events from both sources
    final Map<DateTime, List<dynamic>> events = {};

    // Add completed workouts to events
    workoutsByDate.forEach((date, logs) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      events[normalizedDate] = [
        ...logs,
      ]; // Create a new list to avoid type issues
    });
    
        print('📆 Attempting to get active workout plan for user: ${params.userId}');
    

    // Get active workout plan
    final activePlan = await ref.watch(
      activeWorkoutPlanProvider(params.userId).future,
    );

    print(
      "Active plan: ${activePlan?.id}, scheduled workouts: ${activePlan?.scheduledWorkouts.length ?? 0}",
    );

    // Add scheduled workouts from active plan
    if (activePlan != null) {
      print('📆 Scheduled workouts dates:');

      for (final scheduled in activePlan.scheduledWorkouts) {
        // Normalize the date (remove time component)
        final date = DateTime(
          scheduled.scheduledDate.year,
          scheduled.scheduledDate.month,
          scheduled.scheduledDate.day,
        );

        print(
          "Processing scheduled workout: ${scheduled.title} for date: ${date.toString()}",
        );

        // Check if the scheduled date falls within our requested range
        if ((date.isAfter(params.startDate) ||
                date.isAtSameMomentAs(params.startDate)) &&
            (date.isBefore(params.endDate) ||
                date.isAtSameMomentAs(params.endDate))) {
          print(
            "Adding workout to calendar: ${scheduled.title} on ${date.toString()}",
          );

          if (events.containsKey(date)) {
            events[date]!.add(scheduled);
          } else {
            events[date] = [scheduled];
          }
        } else {
          print(
            "Workout date ${date.toString()} outside range: ${params.startDate.toString()} to ${params.endDate.toString()}",
          );
        }
      }
    }

    // Debug log the final events
    print("Combined events: ${events.length} dates with events");
    events.forEach((date, dayEvents) {
      print("Date: ${date.toString()}, events: ${dayEvents.length}");
    });

    return events;
  } catch (e) {
    print("Error in combinedCalendarEventsProvider: $e");
    rethrow;
  }
});

// Provider for rest day recommendations based on workout history
final restDayRecommendationsProvider = FutureProvider.family<
  List<DateTime>,
  String
>((ref, userId) async {
  final now = DateTime.now();
  final startDate = now.subtract(const Duration(days: 7));
  final endDate = now.add(const Duration(days: 14));

  // Get workout history and scheduled workouts
  final events = await ref.watch(
    combinedCalendarEventsProvider((
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    )).future,
  );

  // Find consecutive workout days to recommend rest
  final List<DateTime> restDays = [];
  final List<DateTime> workoutDays = events.keys.toList()..sort();

  // Simple algorithm: recommend rest after 2 consecutive workout days
  for (int i = 0; i < workoutDays.length - 1; i++) {
    final current = workoutDays[i];
    final next = workoutDays[i + 1];

    // If there are consecutive workout days
    if (next.difference(current).inDays == 1) {
      // If we find a third consecutive day, recommend a rest day after
      if (i + 2 < workoutDays.length &&
          workoutDays[i + 2].difference(next).inDays == 1) {
        final restDay = workoutDays[i + 2].add(const Duration(days: 1));

        // Only add future days and avoid duplicates
        if (restDay.isAfter(now) &&
            !restDays.contains(restDay) &&
            !workoutDays.contains(restDay)) {
          restDays.add(restDay);
        }
      }
    }
  }

  // Add some rest days for recovery from intense workouts
  for (final dateWithEvents in events.entries) {
    // Check if any of the workouts are high intensity
    bool hasIntenseWorkout = false;

    for (final event in dateWithEvents.value) {
      if (event is WorkoutLog && event.userFeedback.feltTooHard) {
        hasIntenseWorkout = true;
        break;
      }

      // For scheduled workouts, we can check workout difficulty if available
      if (event is ScheduledWorkout) {
        // Here we would ideally check the workout difficulty
        // For now, let's assume all scheduled workouts might need recovery
        hasIntenseWorkout = true;
        break;
      }
    }

    if (hasIntenseWorkout) {
      // Recommend rest day after intense workout
      final restDay = dateWithEvents.key.add(const Duration(days: 1));

      // Only add future days and avoid duplicates
      if (restDay.isAfter(now) &&
          !restDays.contains(restDay) &&
          !workoutDays.contains(restDay)) {
        restDays.add(restDay);
      }
    }
  }

  return restDays;
});

// State for calendar interactions (selected day, view mode, etc.)
class CalendarState {
  final DateTime selectedDate;
  final DateTime focusedMonth;
  final String viewMode; // 'month', 'week', 'day'
  final bool isEditing;
  final Map<DateTime, List<dynamic>> cachedEvents;
  final List<DateTime> highlightedDates; // For rest day recommendations, etc.

  CalendarState({
    DateTime? selectedDate,
    DateTime? focusedMonth,
    this.viewMode = 'month',
    this.isEditing = false,
    this.cachedEvents = const {},
    this.highlightedDates = const [],
  }) : selectedDate = selectedDate ?? DateTime.now(),
       focusedMonth = focusedMonth ?? DateTime.now();

  CalendarState copyWith({
    DateTime? selectedDate,
    DateTime? focusedMonth,
    String? viewMode,
    bool? isEditing,
    Map<DateTime, List<dynamic>>? cachedEvents,
    List<DateTime>? highlightedDates,
  }) {
    return CalendarState(
      selectedDate: selectedDate ?? this.selectedDate,
      focusedMonth: focusedMonth ?? this.focusedMonth,
      viewMode: viewMode ?? this.viewMode,
      isEditing: isEditing ?? this.isEditing,
      cachedEvents: cachedEvents ?? this.cachedEvents,
      highlightedDates: highlightedDates ?? this.highlightedDates,
    );
  }
}

// Notifier for calendar interactions
class CalendarStateNotifier extends StateNotifier<CalendarState> {
  final WorkoutPlanningService _planningService;
  final AnalyticsService _analytics;

  CalendarStateNotifier(this._planningService, this._analytics)
    : super(CalendarState());

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
    _analytics.logEvent(
      name: 'calendar_date_selected',
      parameters: {'date': date.toIso8601String()},
    );
  }

  void changeViewMode(String mode) {
    if (['month', 'week', 'day'].contains(mode)) {
      state = state.copyWith(viewMode: mode);
      _analytics.logEvent(
        name: 'calendar_view_changed',
        parameters: {'mode': mode},
      );
    }
  }

  void changeFocusedMonth(DateTime month) {
    state = state.copyWith(focusedMonth: DateTime(month.year, month.month, 1));
  }

  void toggleEditMode() {
    state = state.copyWith(isEditing: !state.isEditing);
  }

  void updateEvents(Map<DateTime, List<dynamic>> events) {
    state = state.copyWith(cachedEvents: events);
  }

  void updateHighlightedDates(List<DateTime> dates) {
    state = state.copyWith(highlightedDates: dates);
  }

  Future<bool> scheduleWorkout({
    required String userId,
    required String planId,
    required Workout workout,
    required DateTime date,
    bool reminderEnabled = true,
    DateTime? reminderTime,
  }) async {
    try {
      print(
        '⭐ Attempting to schedule workout: ${workout.title} on ${date.toString()}',
      );
      print('⭐ Using planId: $planId for user: $userId');

      // Get current plan
      final plan = await _planningService.getWorkoutPlan(userId, planId);
      if (plan == null) {
        print('❌ Plan not found with ID: $planId');
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
      );

      print('✅ Created scheduled workout object: ${scheduledWorkout.toMap()}');

      // Add to plan's scheduled workouts
      final updatedScheduled = [...plan.scheduledWorkouts, scheduledWorkout];
      final updatedPlan = plan.copyWith(
        scheduledWorkouts: updatedScheduled,
        updatedAt: DateTime.now(),
      );

      print(
        '✅ Updated plan now has ${updatedPlan.scheduledWorkouts.length} workouts',
      );

      // Update plan in database
      await _planningService.updateWorkoutPlan(updatedPlan);
      print('✅ Plan successfully updated in database');

      // Log analytics
      _analytics.logEvent(
        name: 'workout_scheduled',
        parameters: {
          'workout_id': workout.id,
          'plan_id': planId,
          'date': date.toIso8601String(),
        },
      );

      return true;
    } catch (e) {
      print('❌ Error scheduling workout: $e');
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
      // Get current plan
      final plan = await _planningService.getWorkoutPlan(userId, planId);
      if (plan == null) return false;

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
            // This would require more complex logic in a full implementation
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

      if (!found) return false;

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

      return true;
    } catch (e) {
      print('Error rescheduling workout: $e');
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
      // Get current plan
      final plan = await _planningService.getWorkoutPlan(userId, planId);
      if (plan == null) return false;

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

      if (targetWorkout == null) return false;

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

      return true;
    } catch (e) {
      print('Error setting recurring workout: $e');
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
      // Get current plan
      final plan = await _planningService.getWorkoutPlan(userId, planId);
      if (plan == null) return false;

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

      return true;
    } catch (e) {
      print('Error deleting scheduled workout: $e');
      return false;
    }
  }
}

// Provider for calendar state
final calendarStateProvider =
    StateNotifierProvider<CalendarStateNotifier, CalendarState>((ref) {
      final planningService = ref.watch(workoutPlanningServiceProvider);
      final analytics = ref.watch(analyticsServiceProvider);
      return CalendarStateNotifier(planningService, analytics);
    });

// Provider to check for scheduling conflicts
final scheduleConflictsProvider = FutureProvider.family<
  List<DateTime>,
  ({
    String userId,
    DateTime startDate,
    DateTime endDate,
    List<DateTime> proposedDates,
  })
>((ref, params) async {
  final events = await ref.watch(
    combinedCalendarEventsProvider((
      userId: params.userId,
      startDate: params.startDate,
      endDate: params.endDate,
    )).future,
  );

  final List<DateTime> conflicts = [];

  // Check each proposed date for conflicts
  for (final proposedDate in params.proposedDates) {
    final date = DateTime(
      proposedDate.year,
      proposedDate.month,
      proposedDate.day,
    );

    if (events.containsKey(date)) {
      conflicts.add(date);
    }
  }

  return conflicts;
});
