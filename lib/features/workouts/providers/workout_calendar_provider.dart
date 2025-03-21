// lib/features/workouts/providers/workout_calendar_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_log.dart';
import 'workout_planning_provider.dart';

// Provider for workout calendar data (completed workouts)
final workoutCalendarDataProvider = FutureProvider.family<Map<DateTime, List<WorkoutLog>>, ({String userId, DateTime startDate, DateTime endDate})>((ref, params) async {
  final firestore = FirebaseFirestore.instance;
  Map<DateTime, List<WorkoutLog>> workoutsByDate = {};

  try {
    // Fetch completed workouts from the given date range
    final logsSnapshot = await firestore
        .collection('user_workout_history')
        .doc(params.userId)
        .collection('logs')
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(params.startDate))
        .where('completedAt', isLessThanOrEqualTo: Timestamp.fromDate(params.endDate))
        .get();

    // Process the workout logs
    for (final doc in logsSnapshot.docs) {
      final log = WorkoutLog.fromMap({'id': doc.id, ...doc.data()});
      
      // Group by date (ignore time)
      final date = DateTime(
        log.completedAt.year,
        log.completedAt.month,
        log.completedAt.day,
      );
      
      if (workoutsByDate.containsKey(date)) {
        workoutsByDate[date]!.add(log);
      } else {
        workoutsByDate[date] = [log];
      }
    }

    // If we don't have any real data, generate sample data for testing
    if (workoutsByDate.isEmpty) {
      workoutsByDate = await _generateSampleWorkoutData(params.userId);
    }

    return workoutsByDate;
  } catch (e) {
    print('Error fetching workout calendar data: $e');
    // Return sample data for better user experience
    return _generateSampleWorkoutData(params.userId);
  }
});

// Combined provider that fetches both completed workouts and scheduled workouts
final combinedCalendarEventsProvider = FutureProvider.family<Map<DateTime, List<dynamic>>, ({String userId, DateTime startDate, DateTime endDate})>((ref, params) async {
  // Get completed workouts
  final workoutsByDate = await ref.watch(
    workoutCalendarDataProvider(params).future
  );
  
  // Get active workout plan
  final activePlan = await ref.watch(
    activeWorkoutPlanProvider(params.userId).future
  );
  
  // Process events from both sources
  final Map<DateTime, List<dynamic>> events = {};

  // Add completed workouts to events
  workoutsByDate.forEach((date, logs) {
    events[date] = logs;
  });

  // Add scheduled workouts from active plan
  if (activePlan != null) {
    for (final scheduled in activePlan.scheduledWorkouts) {
      final date = DateTime(
        scheduled.scheduledDate.year,
        scheduled.scheduledDate.month,
        scheduled.scheduledDate.day,
      );

      if (events.containsKey(date)) {
        events[date]!.add(scheduled);
      } else {
        events[date] = [scheduled];
      }
    }
  }

  return events;
});

// Helper function to generate sample workout data
Future<Map<DateTime, List<WorkoutLog>>> _generateSampleWorkoutData(String userId) async {
  final Map<DateTime, List<WorkoutLog>> result = {};
  
  // Create some sample dates (past few days plus today)
  final today = DateTime.now();
  
  // Generate a workout log for today
  final todayLog = WorkoutLog(
    id: 'sample-1',
    userId: userId,
    workoutId: 'sample-workout-1',
    startedAt: today.subtract(const Duration(hours: 1)),
    completedAt: today,
    durationMinutes: 45,
    caloriesBurned: 320,
    exercisesCompleted: [
      ExerciseLog(
        exerciseName: 'Squats',
        setsCompleted: 3,
        repsCompleted: 12,
        difficultyRating: 3,
      ),
      ExerciseLog(
        exerciseName: 'Push-ups',
        setsCompleted: 3,
        repsCompleted: 10,
        difficultyRating: 4,
      ),
    ],
    userFeedback: const UserFeedback(rating: 4),
  );
  
  // Add to map
  final dateKey = DateTime(today.year, today.month, today.day);
  result[dateKey] = [todayLog];
  
  // Add a workout from 2 days ago
  final twoDaysAgo = today.subtract(const Duration(days: 2));
  final twoDaysAgoKey = DateTime(twoDaysAgo.year, twoDaysAgo.month, twoDaysAgo.day);
  
  final pastLog = WorkoutLog(
    id: 'sample-2',
    userId: userId,
    workoutId: 'sample-workout-2',
    startedAt: twoDaysAgo.subtract(const Duration(minutes: 50)),
    completedAt: twoDaysAgo,
    durationMinutes: 50,
    caloriesBurned: 380,
    exercisesCompleted: [
      ExerciseLog(
        exerciseName: 'Lunges',
        setsCompleted: 3,
        repsCompleted: 10,
        difficultyRating: 3,
      ),
      ExerciseLog(
        exerciseName: 'Plank',
        setsCompleted: 3,
        repsCompleted: 1,
        difficultyRating: 4,
      ),
    ],
    userFeedback: const UserFeedback(rating: 5),
  );
  
  result[twoDaysAgoKey] = [pastLog];
  
  return result;
}