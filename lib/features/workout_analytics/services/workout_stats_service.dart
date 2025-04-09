// lib/features/workout_analytics/services/workout_stats_service.dart
import 'package:bums_n_tums/features/workouts/models/workout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../workouts/models/workout_log.dart';
import '../models/workout_stats.dart';
import '../../workouts/models/workout_streak.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

class WorkoutStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics;
  final bool _debugMode = kDebugMode;

  WorkoutStatsService(this._analytics);

  static const String _logsCollectionPath = 'logs';
  CollectionReference<Map<String, dynamic>> _userLogsCollection(String userId) {
    return _firestore
        .collection('workout_logs')
        .doc(userId)
        .collection(_logsCollectionPath);
  }

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

    Map<String, int> updatedCategory = Map.from(
      currentStats.workoutsByCategory,
    );
    final List<String> tags =
        log.targetAreas; // Use the tags saved in the log
    final String? workoutCategoryName =
        log.workoutCategory; // Use category as fallback

    // Define your primary body focus categories
    const String lowerBody = 'Lower Body';
    const String upperBody = 'Upper Body';
    const String core = 'Core';
    const String fullBody = 'Full Body';
    const String cardio = 'Cardio';
    const String other = 'Other'; // Default/fallback

    bool categoryAssigned = false;

    // Map tags to categories (adjust these tags based on your actual workout tags)
    if (tags.any(
      (tag) =>
          ['legs', 'glutes', 'bums', 'lower body'].contains(tag.toLowerCase()),
    )) {
      updatedCategory[lowerBody] = (updatedCategory[lowerBody] ?? 0) + 1;
      categoryAssigned = true;
    } else if (tags.any(
      (tag) => [
        'arms',
        'chest',
        'back',
        'shoulders',
        'upper body',
      ].contains(tag.toLowerCase()),
    )) {
      updatedCategory[upperBody] = (updatedCategory[upperBody] ?? 0) + 1;
      categoryAssigned = true;
    } else if (tags.any(
      (tag) => ['core', 'abs', 'tums', 'obliques'].contains(tag.toLowerCase()),
    )) {
      updatedCategory[core] = (updatedCategory[core] ?? 0) + 1;
      categoryAssigned = true;
    } else if (tags.any(
          (tag) => ['full body', 'total body'].contains(tag.toLowerCase()),
        ) ||
        workoutCategoryName == WorkoutCategory.fullBody.name) {
      // Use category name as fallback for full body if needed
      updatedCategory[fullBody] = (updatedCategory[fullBody] ?? 0) + 1;
      categoryAssigned = true;
    } else if (tags.any(
          (tag) => [
            'cardio',
            'hiit',
            'running',
            'cycling',
          ].contains(tag.toLowerCase()),
        ) ||
        workoutCategoryName == WorkoutCategory.cardio.name) {
      updatedCategory[cardio] = (updatedCategory[cardio] ?? 0) + 1;
      categoryAssigned = true;
    }

    // If no specific category was assigned based on tags/primary category name, use a default
    if (!categoryAssigned) {
      updatedCategory[other] = (updatedCategory[other] ?? 0) + 1;
      print(
        "Warning: Workout '${log.workoutName ?? log.workoutId}' (Tags: $tags, Category: $workoutCategoryName) assigned to '$other'",
      );
    }
    // --- End of Body Focus Category Logic ---

    // Calculate new average duration
    final totalWorkouts = currentStats.totalWorkoutsCompleted + 1;
    final totalMinutes = currentStats.totalWorkoutMinutes + log.durationMinutes;
    // Use double division for potentially more accurate average, though floor division (~) is fine if int is required
    final newAverage = totalMinutes ~/ totalWorkouts;

    // Update monthly trend (last 6 months)
    List<int> updatedMonthlyTrend = List.from(currentStats.monthlyTrend);
    if (updatedMonthlyTrend.isEmpty || updatedMonthlyTrend.length < 6) {
      updatedMonthlyTrend = List.filled(6, 0); // Ensure it has 6 elements
    }
    // Increment the count for the current month (last element)
    updatedMonthlyTrend[updatedMonthlyTrend.length - 1]++;

    // --- Exercise specific stats update (Keep this logic as is) ---
    Map<String, int> updatedExerciseCompletionCounts = Map.from(
      currentStats.exerciseCompletionCounts,
    );
    Map<String, int> updatedTotalRepsCompleted = Map.from(
      currentStats.totalRepsCompleted,
    );
    Map<String, Duration> updatedTotalDuration = Map.from(
      currentStats.totalDuration,
    );

    for (final exerciseLog in log.exercisesCompleted) {
      final exerciseName = exerciseLog.exerciseName;

      // Update completion count
      updatedExerciseCompletionCounts[exerciseName] =
          (updatedExerciseCompletionCounts[exerciseName] ?? 0) + 1;

      // Update total reps (if applicable)
      if (exerciseLog.repsCompleted.isNotEmpty) {
        final latestReps = exerciseLog.repsCompleted.last;
        if (latestReps != null) {
          updatedTotalRepsCompleted[exerciseName] =
              (updatedTotalRepsCompleted[exerciseName] ?? 0) +
              latestReps *
                  exerciseLog
                      .setsCompleted; // Assuming all sets had the same reps for simplicity
        }
      }

      // Update total duration (if applicable)
      if (exerciseLog.duration.isNotEmpty) {
        final latestDuration = exerciseLog.duration.last;
        if (latestDuration != null) {
          updatedTotalDuration[exerciseName] =
              (updatedTotalDuration[exerciseName] ?? Duration.zero) +
              latestDuration * exerciseLog.setsCompleted; // Accumulate duration
        }
      }
    }

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
      exerciseCompletionCounts: updatedExerciseCompletionCounts,
      totalRepsCompleted: updatedTotalRepsCompleted,
      totalDuration: updatedTotalDuration,
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
      if (_debugMode) {
        print('Attempting to fetch workout logs for user: $userId');
        // Construct the full path for logging clarity
        print(
          'Path: workout_logs/$userId/$_logsCollectionPath',
        ); // <<< UPDATED DEBUG LOG PATH
        print('Date range: $startDate to $endDate');
      }

      final snapshot =
          await _userLogsCollection(userId) // <<< USE HELPER METHOD
              .where(
                'completedAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .where(
                'completedAt',
                isLessThanOrEqualTo: Timestamp.fromDate(endDate),
              )
              .orderBy(
                'completedAt',
                descending: true,
              ) // Keep ordering consistent if needed elsewhere
              .get();

      if (_debugMode) {
        print('Successfully retrieved ${snapshot.docs.length} workout logs');
      }

      // Group logs by date (ignoring time)
      Map<DateTime, List<WorkoutLog>> workoutsByDate = {};

      for (final doc in snapshot.docs) {
        try {
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
        } catch (e) {
          if (_debugMode) {
            print('Error parsing WorkoutLog with id ${doc.id}: $e');
            // Optionally skip this log or handle error differently
          }
        }
      }

      // Sample data logic can remain for debugging
      if (kDebugMode && workoutsByDate.isEmpty) {
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
          repsCompleted: [12],
          difficultyRating: 3,
          weightUsed: [0],
          duration: [const Duration(seconds: 1)], // Wrapped in Duration()
        ),
        ExerciseLog(
          exerciseName: 'Push-ups',
          setsCompleted: 3,
          repsCompleted: [10],
          difficultyRating: 4,
          weightUsed: [40],
          duration: [const Duration(seconds: 12)], // Wrapped in Duration()
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
          repsCompleted: [10], // Make sure this is a list
          difficultyRating: 3,
          weightUsed: [0], // Add weightUsed for consistency
          duration: [], // Can be an empty list if no duration
        ),
        ExerciseLog(
          exerciseName: 'Plank',
          setsCompleted: 3,
          repsCompleted: [1], // Make sure this is a list
          difficultyRating: 4,
          weightUsed: [0], // Add weightUsed for consistency
          duration: [
            const Duration(seconds: 30),
          ], // Let's add a duration for plank
        ),
      ],
      userFeedback: const UserFeedback(rating: 5),
    );

    result[twoDaysAgoKey] = [pastLog];

    return result;
  }

  Future<List<Map<String, dynamic>>> getWorkoutFrequencyData(
    String userId,
    int days,
  ) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final snapshot =
          await _userLogsCollection(userId) // <<< USE HELPER METHOD
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

      // ... (rest of the method remains the same - processing the snapshot)
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
        try {
          final log = WorkoutLog.fromMap({'id': doc.id, ...doc.data()});
          final dateString =
              '${log.completedAt.year}-${log.completedAt.month.toString().padLeft(2, '0')}-${log.completedAt.day.toString().padLeft(2, '0')}';

          dateCountMap[dateString] = (dateCountMap[dateString] ?? 0) + 1;
        } catch (e) {
          if (_debugMode) {
            print(
              'Error parsing WorkoutLog with id ${doc.id} in getWorkoutFrequencyData: $e',
            );
          }
        }
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
