// lib/features/workouts/providers/calendar_events_provider.dart
import 'package:bums_n_tums/features/workouts/providers/workout_calendar_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_log.dart';
import '../models/workout_plan.dart';

final Set<String> _loggedRanges = {};

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

// Provider that combines scheduled and completed workouts for calendar display
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
      print(
        '📆 Fetching calendar events for date range: ${params.startDate} to ${params.endDate}',
      );
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

    // Get active workout plan
    final activePlan = await ref.watch(
      activeWorkoutPlanProvider(params.userId).future,
    );

    // Add scheduled workouts from active plan
    if (activePlan != null) {
      for (final scheduled in activePlan.scheduledWorkouts) {
        // Normalize the date (remove time component)
        final date = DateTime(
          scheduled.scheduledDate.year,
          scheduled.scheduledDate.month,
          scheduled.scheduledDate.day,
        );

        // Check if the scheduled date falls within our requested range
        if ((date.isAfter(params.startDate) ||
                date.isAtSameMomentAs(params.startDate)) &&
            (date.isBefore(params.endDate) ||
                date.isAtSameMomentAs(params.endDate))) {
          if (events.containsKey(date)) {
            events[date]!.add(scheduled);
          } else {
            events[date] = [scheduled];
          }
        }
      }
    }

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
        // Simplified check - in a real app would be more sophisticated
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

// Muscle recovery tracking
final muscleRecoveryProvider = FutureProvider.family<Map<String, bool>, String>((ref, userId) async {
  final now = DateTime.now();
  final threeDaysAgo = now.subtract(const Duration(days: 3));
  
  // Get completed workouts in the last 3 days
  final recentCompletedWorkouts = await ref.watch(
    workoutCalendarDataProvider((
      userId: userId,
      startDate: threeDaysAgo,
      endDate: now,
    )).future
  );
  
  // Track which muscle groups need recovery
  Map<String, bool> recoveryStatus = {
    'bums': false,
    'tums': false,
    'arms': false,
    'legs': false,
    'back': false,
    'cardio': false,
  };
  
  // Analyze logs to determine which muscle groups need recovery
  recentCompletedWorkouts.forEach((date, logs) {
    for (final log in logs) {
      // Safe access to targetAreas
      final areas = log.targetAreas;
      
      // Check each area
      if (areas.contains('bums')) {
        recoveryStatus['bums'] = true;
      }
      if (areas.contains('tums')) {
        recoveryStatus['tums'] = true;
      }
      
      // If no specific areas are tracked, try to use workout category from workoutId
      if (areas.isEmpty) {
        // Try to infer workout type
        final workoutType = _inferWorkoutTypeFromLog(log);
        if (workoutType == 'bums') {
          recoveryStatus['bums'] = true;
        } else if (workoutType == 'tums') {
          recoveryStatus['tums'] = true;
        } else if (workoutType == 'fullBody') {
          // If it's a full body workout, mark multiple groups for recovery
          recoveryStatus['bums'] = true;
          recoveryStatus['tums'] = true;
          recoveryStatus['arms'] = true;
          recoveryStatus['legs'] = true;
          recoveryStatus['back'] = true;
        }
      }
    }
  });
  
  return recoveryStatus;
});

// Helper function to infer workout type from log
String _inferWorkoutTypeFromLog(WorkoutLog log) {
  // First check if we have a category field
  if (log.workoutCategory != null) {
    return log.workoutCategory!;
  }
  
  // If not, try to infer from workout name
  final name = log.workoutName?.toLowerCase() ?? '';
  
  if (name.contains('bum') || name.contains('glute') || name.contains('leg')) {
    return 'bums';
  } else if (name.contains('tum') || name.contains('ab') || name.contains('core')) {
    return 'tums';
  } else if (name.contains('full') || name.contains('total')) {
    return 'fullBody';
  } else if (name.contains('arm') || name.contains('upper')) {
    return 'arms';
  } else if (name.contains('cardio') || name.contains('hiit')) {
    return 'cardio';
  }
  
  // Default to full body if we can't determine
  return 'fullBody';
}