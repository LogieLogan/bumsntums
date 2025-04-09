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

Map<String, int> updatedCategory = Map.from(currentStats.workoutsByCategory);

  // Define your primary body focus categories
  const String lowerBody = 'Lower Body';
  const String upperBody = 'Upper Body';
  const String core = 'Core';
  const String fullBody = 'Full Body'; // Less likely to be derived from muscles
  const String cardio = 'Cardio';     // Less likely to be derived from muscles
  const String other = 'Other';

  // Define muscle-to-category mapping (adjust as needed)
  const Map<String, String> muscleToCategoryMap = {
    // Lower Body
    'gluteus maximus': lowerBody,
    'glutes': lowerBody, // Add aliases
    'gluteus medius': lowerBody,
    'hamstrings': lowerBody,
    'quadriceps': lowerBody,
    'calves': lowerBody,
    'adductors': lowerBody,
    'abductors': lowerBody,
    'hip abductors': lowerBody, // From Jumping Jacks example
    'hip extensors': lowerBody,

    // Upper Body
    'chest': upperBody,
    'shoulders': upperBody,
    'triceps': upperBody,
    'biceps': upperBody,
    'forearms': upperBody,
    'back': upperBody, // General back
    'trapezius': upperBody,
    'rhomboids': upperBody,
    'latissimus dorsi': upperBody,
    'upper back': upperBody,

    // Core
    'core': core,
    'rectus abdominis': core,
    'obliques': core,
    'transverse abdominis': core,
    'lower back': core, // Often considered core
    'erector spinae': core,
    'hip flexors': core, // Often grouped with core work
  };

  // Keep track of categories incremented for this specific log
  // to avoid double-counting if multiple exercises hit the same category
  Set<String> categoriesIncrementedThisLog = {};

  // Iterate through completed exercises in the log
  for (final exerciseLog in log.exercisesCompleted) {
    bool exerciseCategoryAssigned = false;
    // Iterate through the muscles targeted by this exercise
    for (final muscle in exerciseLog.targetMuscles) {
      final category = muscleToCategoryMap[muscle.toLowerCase()];
      if (category != null && !categoriesIncrementedThisLog.contains(category)) {
        updatedCategory[category] = (updatedCategory[category] ?? 0) + 1;
        categoriesIncrementedThisLog.add(category);
        exerciseCategoryAssigned = true;
        // Optional: break here if you only want to count the category once per exercise
        // break;
      }
    }
     // If no specific muscle mapped, maybe use the overall workout category as fallback?
     // This part needs careful consideration based on your desired logic.
     // Example fallback (might still lead to 'Full Body' if that's the workout category)
     if (!exerciseCategoryAssigned) {
         final String fallbackCategory = log.workoutCategory == WorkoutCategory.bums.name ? lowerBody :
                                        log.workoutCategory == WorkoutCategory.tums.name ? core :
                                        log.workoutCategory == WorkoutCategory.arms.name ? upperBody :
                                        log.workoutCategory == WorkoutCategory.cardio.name ? cardio :
                                        log.workoutCategory == WorkoutCategory.fullBody.name ? fullBody : other;

         if (!categoriesIncrementedThisLog.contains(fallbackCategory)) {
            updatedCategory[fallbackCategory] = (updatedCategory[fallbackCategory] ?? 0) + 1;
            categoriesIncrementedThisLog.add(fallbackCategory);
         }
         print("Warning: Exercise '${exerciseLog.exerciseName}' muscles (${exerciseLog.targetMuscles}) didn't map directly. Used fallback: $fallbackCategory");
     }

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

  // lib/features/workout_analytics/services/workout_stats_service.dart

  // ... inside WorkoutStatsService class ...

  Future<List<Map<String, dynamic>>> getWorkoutFrequencyData(
    String userId,
    int days,
  ) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      final int startMillis = startDate.millisecondsSinceEpoch;
      final int endMillis = endDate.millisecondsSinceEpoch;
      print(
        "WorkoutFrequencyDataProvider: Fetching for user $userId, days $days, from: $startDate (millis: $startMillis) to: $endDate (millis: $endMillis)", // Updated print
      );

      final snapshot =
          await _userLogsCollection(userId)
              .where(
                'completedAt', // Field is NUMBER
                isGreaterThanOrEqualTo: startMillis, // Compare with NUMBER
              )
              .where(
                'completedAt', // Field is NUMBER
                isLessThanOrEqualTo: endMillis, // Compare with NUMBER
              )
              .orderBy('completedAt') // Ordering still works on numbers
              .get();
      print(
        "WorkoutFrequencyDataProvider: Firestore query returned ${snapshot.docs.length} logs in range.",
      ); // Add print

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
          // *** IMPORTANT: Ensure WorkoutLog.fromMap handles completedAt being a number ***
          final log = WorkoutLog.fromMap({'id': doc.id, ...doc.data()});

          // Check if parsing worked - log.completedAt should be a DateTime object here
          if (log.completedAt == null) {
            print(
              "WorkoutFrequencyDataProvider: Warning - could not parse completedAt for log ${doc.id}. Skipping.",
            );
            continue;
          }

          // Convert the parsed DateTime back to string for map key
          final dateString =
              '${log.completedAt.year}-${log.completedAt.month.toString().padLeft(2, '0')}-${log.completedAt.day.toString().padLeft(2, '0')}';

          print(
            "WorkoutFrequencyDataProvider: Processing log completed on $dateString (Log ID: ${log.id})",
          );

          // Increment count using the date string key
          dateCountMap[dateString] = (dateCountMap[dateString] ?? 0) + 1;

          print(
            "WorkoutFrequencyDataProvider: Count for $dateString is now ${dateCountMap[dateString]}",
          );
        } catch (e, stackTrace) {
          // Catch specific parsing errors
          if (_debugMode) {
            print(
              'Error parsing WorkoutLog with id ${doc.id} in getWorkoutFrequencyData: $e\n$stackTrace',
            );
          }
          // Log to crash reporting service here if desired
        }
      }

      // Convert to list of maps for chart data
      List<Map<String, dynamic>> result =
          dateCountMap.entries.map((entry) {
            // --->>> ADD CONDITIONAL PRINT FOR NON-ZERO COUNTS <<<---
            if (entry.value > 0) {
              print(
                "WorkoutFrequencyDataProvider: Final map includes ${entry.key} with count ${entry.value}",
              );
            }
            return {'date': entry.key, 'count': entry.value};
          }).toList();

      // Sort by date
      result.sort((a, b) => a['date'].compareTo(b['date']));

      print(
        // Keep this print
        "WorkoutFrequencyDataProvider: Fetched ${result.length} frequency data points total.",
      );
      return result;
    } catch (e, stackTrace) {
      // Added stackTrace
      debugPrint('Error getting workout frequency data for user $userId: $e');
      debugPrint('Stack trace: $stackTrace'); // Print stack trace
      // Log to crash reporting service
      // ref.read(crashReportingServiceProvider).recordError(e, stackTrace, reason: 'Error in getWorkoutFrequencyData');
      return []; // Return empty on error
    }
  }
}
