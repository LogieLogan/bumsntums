// lib/features/workouts/services/workout_stats_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../workouts/models/workout_log.dart';
import '../models/workout_stats.dart';
import '../../workouts/models/workout_streak.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

class WorkoutStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics;
  final bool _debugMode = true;

  WorkoutStatsService(this._analytics);

  // Get user's workout stats
  Future<UserWorkoutStats> getUserWorkoutStats(String userId) async {
    try {
      final doc =
          await _firestore
              .collection('user_workout_analytics')
              .doc(userId)
              .get();

      if (!doc.exists) {
        return UserWorkoutStats.empty(userId);
      }

      return UserWorkoutStats.fromMap({'userId': userId, ...doc.data()!});
    } catch (e) {
      debugPrint('Error getting user workout stats: $e');
      return UserWorkoutStats.empty(userId);
    }
  }

  // Get user's workout streak
  Future<WorkoutStreak> getUserWorkoutStreak(String userId) async {
    try {
      final doc = await _firestore.collection('user_streaks').doc(userId).get();

      if (!doc.exists) {
        return WorkoutStreak.empty(userId);
      }

      return WorkoutStreak.fromMap({'userId': userId, ...doc.data()!});
    } catch (e) {
      debugPrint('Error getting user workout streak: $e');
      return WorkoutStreak.empty(userId);
    }
  }

  // Update user's workout stats based on completed workout
  Future<void> updateStatsFromWorkoutLog(WorkoutLog log) async {
    try {
      // Get current stats
      final statsDoc =
          await _firestore
              .collection('user_workout_analytics')
              .doc(log.userId)
              .get();

      // Get current streak info
      final streakDoc =
          await _firestore.collection('user_streaks').doc(log.userId).get();

      // Process the workout stats update
      await _firestore.runTransaction((transaction) async {
        // Update stats
        if (statsDoc.exists) {
          final currentStats = UserWorkoutStats.fromMap({
            'userId': log.userId,
            ...statsDoc.data()!,
          });

          // Calculate new stats
          final newStats = _calculateUpdatedStats(currentStats, log);

          transaction.update(
            _firestore.collection('user_workout_analytics').doc(log.userId),
            newStats.toMap(),
          );
        } else {
          // Create new stats
          final newStats = _createInitialStats(log);

          transaction.set(
            _firestore.collection('user_workout_analytics').doc(log.userId),
            newStats.toMap(),
          );
        }

        // Update streak
        final currentDate = DateTime(
          log.completedAt.year,
          log.completedAt.month,
          log.completedAt.day,
        );

        if (streakDoc.exists) {
          final currentStreak = WorkoutStreak.fromMap({
            'userId': log.userId,
            ...streakDoc.data()!,
          });

          // Calculate new streak
          final newStreak = _calculateUpdatedStreak(currentStreak, currentDate);

          transaction.update(
            _firestore.collection('user_streaks').doc(log.userId),
            newStreak.toMap(),
          );
        } else {
          // Create new streak
          final newStreak = WorkoutStreak(
            userId: log.userId,
            currentStreak: 1,
            longestStreak: 1,
            lastWorkoutDate: currentDate,
            streakProtectionsRemaining: 1, // Give new users one free protection
          );

          transaction.set(
            _firestore.collection('user_streaks').doc(log.userId),
            newStreak.toMap(),
          );
        }
      });

      // Log analytics event
      await _analytics.logEvent(
        name: 'workout_stats_updated',
        parameters: {'workout_log_id': log.id},
      );
    } catch (e) {
      debugPrint('Error updating stats from workout log: $e');
      rethrow;
    }
  }

  // Calculate updated stats based on a new workout log
  UserWorkoutStats _calculateUpdatedStats(
    UserWorkoutStats currentStats,
    WorkoutLog log,
  ) {
    // Extract day of week (0 = Sunday)
    final dayOfWeek = log.completedAt.weekday % 7;

    // Extract time of day
    final hour = log.completedAt.hour;
    String timeOfDay = 'morning';
    if (hour >= 12 && hour < 17) {
      timeOfDay = 'afternoon';
    } else if (hour >= 17) {
      timeOfDay = 'evening';
    }

    // Update workouts by day of week
    List<int> updatedDayOfWeek = List.from(currentStats.workoutsByDayOfWeek);
    updatedDayOfWeek[dayOfWeek]++;

    // Update workouts by time of day
    Map<String, int> updatedTimeOfDay = Map.from(
      currentStats.workoutsByTimeOfDay,
    );
    updatedTimeOfDay[timeOfDay] = (updatedTimeOfDay[timeOfDay] ?? 0) + 1;

    // Update workouts by category
    Map<String, int> updatedCategory = Map.from(
      currentStats.workoutsByCategory,
    );
    // We would need the workout category here - assume we get it from the workout ID
    // For now, just use 'unknown' as placeholder
    updatedCategory['unknown'] = (updatedCategory['unknown'] ?? 0) + 1;

    // Calculate new average duration
    final totalWorkouts = currentStats.totalWorkoutsCompleted + 1;
    final totalMinutes = currentStats.totalWorkoutMinutes + log.durationMinutes;
    final newAverage = totalMinutes ~/ totalWorkouts;

    // Update monthly trend (last 6 months)
    List<int> updatedMonthlyTrend = List.from(currentStats.monthlyTrend);
    if (updatedMonthlyTrend.isEmpty) {
      updatedMonthlyTrend = List.filled(6, 0);
    }

    // Current month is the last element in the list
    updatedMonthlyTrend[updatedMonthlyTrend.length - 1]++;

    return currentStats.copyWith(
      totalWorkoutsCompleted: totalWorkouts,
      totalWorkoutMinutes: totalMinutes,
      workoutsByCategory: updatedCategory,
      workoutsByDayOfWeek: updatedDayOfWeek,
      workoutsByTimeOfDay: updatedTimeOfDay,
      averageWorkoutDuration: newAverage,
      caloriesBurned: currentStats.caloriesBurned + log.caloriesBurned,
      lastWorkoutDate: log.completedAt,
      lastUpdated: DateTime.now(),
      monthlyTrend: updatedMonthlyTrend,
    );
  }

  // Create initial stats from first workout log
  UserWorkoutStats _createInitialStats(WorkoutLog log) {
    // Extract day of week (0 = Sunday)
    final dayOfWeek = log.completedAt.weekday % 7;

    // Extract time of day
    final hour = log.completedAt.hour;
    String timeOfDay = 'morning';
    if (hour >= 12 && hour < 17) {
      timeOfDay = 'afternoon';
    } else if (hour >= 17) {
      timeOfDay = 'evening';
    }

    // Initialize arrays for stats
    List<int> workoutsByDayOfWeek = List.filled(7, 0);
    workoutsByDayOfWeek[dayOfWeek]++;

    Map<String, int> workoutsByTimeOfDay = {timeOfDay: 1};

    Map<String, int> workoutsByCategory = {'unknown': 1};

    List<int> monthlyTrend = List.filled(6, 0);
    monthlyTrend[5] = 1; // Current month is the last element

    return UserWorkoutStats(
      userId: log.userId,
      totalWorkoutsCompleted: 1,
      totalWorkoutMinutes: log.durationMinutes,
      workoutsByCategory: workoutsByCategory,
      workoutsByDayOfWeek: workoutsByDayOfWeek,
      workoutsByTimeOfDay: workoutsByTimeOfDay,
      averageWorkoutDuration: log.durationMinutes,
      longestStreak: 1,
      currentStreak: 1,
      caloriesBurned: log.caloriesBurned,
      lastWorkoutDate: log.completedAt,
      lastUpdated: DateTime.now(),
      weeklyAverage: 1,
      monthlyTrend: monthlyTrend,
      completionRate: 100.0,
    );
  }

  // Calculate updated streak based on a new workout date
  WorkoutStreak _calculateUpdatedStreak(
    WorkoutStreak currentStreak,
    DateTime workoutDate,
  ) {
    // Clean dates (remove time component)
    final currentWorkoutDay = DateTime(
      workoutDate.year,
      workoutDate.month,
      workoutDate.day,
    );

    final lastWorkoutDay = DateTime(
      currentStreak.lastWorkoutDate.year,
      currentStreak.lastWorkoutDate.month,
      currentStreak.lastWorkoutDate.day,
    );

    // Case 1: Same day workout - no change to streak
    if (currentWorkoutDay.isAtSameMomentAs(lastWorkoutDay)) {
      return currentStreak;
    }

    // Calculate days between workouts
    final difference = currentWorkoutDay.difference(lastWorkoutDay).inDays;

    // Case 2: Next day workout - streak continues
    if (difference == 1) {
      final newCurrentStreak = currentStreak.currentStreak + 1;
      final newLongestStreak =
          newCurrentStreak > currentStreak.longestStreak
              ? newCurrentStreak
              : currentStreak.longestStreak;

      return currentStreak.copyWith(
        currentStreak: newCurrentStreak,
        longestStreak: newLongestStreak,
        lastWorkoutDate: currentWorkoutDay,
      );
    }

    // Case 3: Missed a day but can use streak protection
    if (difference == 2 && currentStreak.streakProtectionsRemaining > 0) {
      final newCurrentStreak = currentStreak.currentStreak + 1;
      final newLongestStreak =
          newCurrentStreak > currentStreak.longestStreak
              ? newCurrentStreak
              : currentStreak.longestStreak;

      return currentStreak.copyWith(
        currentStreak: newCurrentStreak,
        longestStreak: newLongestStreak,
        lastWorkoutDate: currentWorkoutDay,
        streakProtectionsRemaining:
            currentStreak.streakProtectionsRemaining - 1,
      );
    }

    // Case 4: Streak broken - start new streak
    return currentStreak.copyWith(
      currentStreak: 1,
      lastWorkoutDate: currentWorkoutDay,
    );
  }

  // Use a streak protection to save current streak
  Future<bool> useStreakProtection(String userId) async {
    try {
      final doc = await _firestore.collection('user_streaks').doc(userId).get();

      if (!doc.exists) {
        return false;
      }

      final streak = WorkoutStreak.fromMap({'userId': userId, ...doc.data()!});

      if (streak.streakProtectionsRemaining <= 0) {
        return false;
      }

      // Update streak date to today and use a protection
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await _firestore.collection('user_streaks').doc(userId).update({
        'lastWorkoutDate': Timestamp.fromDate(today),
        'streakProtectionsRemaining': FieldValue.increment(-1),
      });

      // Log analytics event
      await _analytics.logEvent(
        name: 'streak_protection_used',
        parameters: {'user_id': userId},
      );

      return true;
    } catch (e) {
      debugPrint('Error using streak protection: $e');
      return false;
    }
  }

  // Renew streak protections (e.g., monthly subscription benefit)
  Future<void> renewStreakProtections(String userId, int protections) async {
    try {
      await _firestore.collection('user_streaks').doc(userId).update({
        'streakProtectionsRemaining': FieldValue.increment(protections),
        'streakProtectionLastRenewed': Timestamp.fromDate(DateTime.now()),
      });

      // Log analytics event
      await _analytics.logEvent(
        name: 'streak_protections_renewed',
        parameters: {'user_id': userId, 'protections_added': protections},
      );
    } catch (e) {
      debugPrint('Error renewing streak protections: $e');
      rethrow;
    }
  }

  Future<Map<DateTime, List<WorkoutLog>>> getWorkoutHistoryByWeek(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Only print debug logs when in debug mode
      if (_debugMode) {
        print('Attempting to fetch workout logs for user: $userId');
        print('Path: user_workout_history/$userId/logs'); // Updated path
        print('Date range: $startDate to $endDate');
      }

      final snapshot =
          await _firestore
              .collection('user_workout_history') // Updated path
              .doc(userId)
              .collection('logs')
              .where(
                'completedAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .where(
                'completedAt',
                isLessThanOrEqualTo: Timestamp.fromDate(endDate),
              )
              .get();

      if (_debugMode) {
        print('Successfully retrieved ${snapshot.docs.length} workout logs');
      }

      // Group logs by date (ignoring time)
      Map<DateTime, List<WorkoutLog>> workoutsByDate = {};

      for (final doc in snapshot.docs) {
        final log = WorkoutLog.fromMap({'id': doc.id, ...doc.data()});
        final dateKey = DateTime(
          log.completedAt.year,
          log.completedAt.month,
          log.completedAt.day,
        );

        if (workoutsByDate.containsKey(dateKey)) {
          workoutsByDate[dateKey]!.add(log);
        } else {
          workoutsByDate[dateKey] = [log];
        }
      }

      // If we're in debug mode and there's no data, return sample data
      if (kDebugMode && workoutsByDate.isEmpty) {
        // Generate and return sample workout data for development
        if (_debugMode) {
          print(
            'No real workout logs found, returning sample data for development',
          );
        }

        return await _generateSampleWorkoutData(userId);
      }

      if (kDebugMode && workoutsByDate.isEmpty) {
        // Generate and return sample workout data for development
        if (_debugMode) {
          print(
            'No real workout logs found, returning sample data for development',
          );
        }

        return await _generateSampleWorkoutData(userId);
      }
      return workoutsByDate;
    } catch (e) {
      if (_debugMode) {
        print('Error getting workout history by week: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      return {};
    }
  }

  Future<Map<DateTime, List<WorkoutLog>>> _generateSampleWorkoutData(
    String userId,
  ) async {
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
    final twoDaysAgoKey = DateTime(
      twoDaysAgo.year,
      twoDaysAgo.month,
      twoDaysAgo.day,
    );

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

  // Get workout frequency data for visualization
  Future<List<Map<String, dynamic>>> getWorkoutFrequencyData(
    String userId,
    int days,
  ) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final snapshot =
          await _firestore
              .collection(
                'user_workout_history',
              ) // Updated path to be consistent
              .doc(userId)
              .collection('logs')
              .where(
                'completedAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .where(
                'completedAt',
                isLessThanOrEqualTo: Timestamp.fromDate(endDate),
              )
              .orderBy('completedAt')
              .get();

      // Create a map of dates to count
      Map<String, int> dateCountMap = {};

      // Initialize all dates in the range with 0
      for (int i = 0; i < days; i++) {
        final date = startDate.add(Duration(days: i));
        final dateString =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dateCountMap[dateString] = 0;
      }

      // Count workouts per day
      for (final doc in snapshot.docs) {
        final log = WorkoutLog.fromMap({'id': doc.id, ...doc.data()});
        final dateString =
            '${log.completedAt.year}-${log.completedAt.month.toString().padLeft(2, '0')}-${log.completedAt.day.toString().padLeft(2, '0')}';

        dateCountMap[dateString] = (dateCountMap[dateString] ?? 0) + 1;
      }

      // Convert to list of maps for chart data
      List<Map<String, dynamic>> result =
          dateCountMap.entries.map((entry) {
            return {'date': entry.key, 'count': entry.value};
          }).toList();

      // Sort by date
      result.sort((a, b) => a['date'].compareTo(b['date']));

      return result;
    } catch (e) {
      debugPrint('Error getting workout frequency data: $e');
      return [];
    }
  }
}
