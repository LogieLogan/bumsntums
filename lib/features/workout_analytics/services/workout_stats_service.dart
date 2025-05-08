// lib/features/workout_analytics/services/workout_stats_service.dart

import 'package:bums_n_tums/features/workout_analytics/models/workout_analytics_timeframe.dart';
import 'package:bums_n_tums/features/workouts/models/workout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../workouts/models/workout_log.dart';
import '../models/workout_stats.dart';
import '../../workouts/models/workout_streak.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../models/workout_achievement.dart';
import '../data/achievement_definitions.dart';

class WorkoutStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics;

  final bool _debugMode = kDebugMode;

  static const String _userAnalyticsCollection = 'user_workout_analytics';
  static const String _userStreaksCollection = 'user_streaks';
  static const String _userLogsBaseCollection = 'workout_logs';
  static const String _logsSubcollection = 'logs';
  static const String _usersCollection = 'users_personal_info';
  static const String _unlockedAchievementsSubcollection =
      'unlocked_achievements';

  WorkoutStatsService(this._analytics);

  DocumentReference<Map<String, dynamic>> _userAnalyticsDoc(String userId) =>
      _firestore.collection(_userAnalyticsCollection).doc(userId);

  DocumentReference<Map<String, dynamic>> _userStreakDoc(String userId) =>
      _firestore.collection(_userStreaksCollection).doc(userId);

  CollectionReference<Map<String, dynamic>> _userLogsCollection(
    String userId,
  ) => _firestore
      .collection(_userLogsBaseCollection)
      .doc(userId)
      .collection(_logsSubcollection);

  CollectionReference<Map<String, dynamic>> _userAchievementsCollection(
    String userId,
  ) => _firestore
      .collection(_usersCollection)
      .doc(userId)
      .collection(_unlockedAchievementsSubcollection);

  Future<UserWorkoutStats> getUserWorkoutStats(String userId) async {
    try {
      final doc = await _userAnalyticsDoc(userId).get();
      if (!doc.exists) {
        if (kDebugMode) {
          print(
            "No existing workout stats found for $userId, returning empty.",
          );
        }
        return UserWorkoutStats.empty(userId);
      }

      return UserWorkoutStats.fromMap({'userId': userId, ...doc.data()!});
    } catch (e, s) {
      debugPrint('Error getting user workout stats for $userId: $e\n$s');

      return UserWorkoutStats.empty(userId);
    }
  }

  Future<WorkoutStreak> getUserWorkoutStreak(String userId) async {
    try {
      final doc = await _userStreakDoc(userId).get();
      if (!doc.exists) {
        if (kDebugMode) {
          print("No existing streak found for $userId, returning empty.");
        }
        return WorkoutStreak.empty(userId);
      }

      return WorkoutStreak.fromMap({'userId': userId, ...doc.data()!});
    } catch (e, s) {
      debugPrint('Error getting user workout streak for $userId: $e\n$s');

      return WorkoutStreak.empty(userId);
    }
  }

  Future<List<WorkoutAchievement>> updateStatsFromWorkoutLog(
    WorkoutLog log,
  ) async {
    if (log.userId.isEmpty) {
      debugPrint("Error: Cannot update stats, WorkoutLog has empty userId.");
      return [];
    }

    List<WorkoutAchievement> newlyUnlocked = [];
    try {
      final Set<String> initiallyUnlockedIds = await _getUnlockedAchievementIds(
        log.userId,
      );

      await _firestore.runTransaction((transaction) async {
        final statsDocRef = _userAnalyticsDoc(log.userId);
        final streakDocRef = _userStreakDoc(log.userId);

        final statsSnapshot = await transaction.get(statsDocRef);
        final streakSnapshot = await transaction.get(streakDocRef);

        UserWorkoutStats newStats;
        if (statsSnapshot.exists) {
          final currentStats = UserWorkoutStats.fromMap({
            'userId': log.userId,
            ...statsSnapshot.data()!,
          });
          newStats = _calculateUpdatedStats(currentStats, log);
        } else {
          newStats = _createInitialStats(log);
        }

        WorkoutStreak newStreak;
        final workoutDate = DateTime(
          log.completedAt.year,
          log.completedAt.month,
          log.completedAt.day,
        );
        if (streakSnapshot.exists) {
          final currentStreak = WorkoutStreak.fromMap({
            'userId': log.userId,
            ...streakSnapshot.data()!,
          });
          newStreak = _calculateUpdatedStreak(currentStreak, workoutDate);
        } else {
          newStreak = WorkoutStreak(
            /* ... initial streak data ... */
            userId: log.userId,
            currentStreak: 1,
            longestStreak: 1,
            lastWorkoutDate: workoutDate,
            streakProtectionsRemaining: 1,
          );
        }

        transaction.set(statsDocRef, newStats.toMap());
        transaction.set(streakDocRef, newStreak.toMap());

        newlyUnlocked = await _checkAndAwardAchievements(
          userId: log.userId,
          currentStats: newStats,
          currentStreak: newStreak,
          initiallyUnlockedIds: initiallyUnlockedIds,
          firestore: _firestore,
          transaction: transaction,
        );
      });

      await _analytics.logEvent(name: 'workout_stats_updated');
      if (_debugMode) {
        print(
          "Successfully completed transaction for user ${log.userId}. Newly unlocked: ${newlyUnlocked.length}",
        );
      }

      // *** Return the captured list ***
      return newlyUnlocked;
    } catch (e, s) {
      debugPrint(
        'Error in updateStatsFromWorkoutLog for user ${log.userId}: $e\n$s',
      );
      // Return empty list on error to avoid breaking calling code
      return [];
    }
  }

  Future<Set<String>> _getUnlockedAchievementIds(String userId) async {
    if (userId.isEmpty) return {};
    try {
      final snapshot = await _userAchievementsCollection(userId).get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e, s) {
      debugPrint(
        "Warning: Could not pre-fetch unlocked achievement IDs for $userId (permissions?): $e\n$s",
      );
      return {};
    }
  }

  UserWorkoutStats _calculateUpdatedStats(
    UserWorkoutStats currentStats,
    WorkoutLog log,
  ) {
    final totalWorkouts = currentStats.totalWorkoutsCompleted + 1;
    final totalMinutes = currentStats.totalWorkoutMinutes + log.durationMinutes;
    final newAverageDuration =
        totalWorkouts > 0 ? (totalMinutes ~/ totalWorkouts) : 0;
    final totalCalories = currentStats.caloriesBurned + log.caloriesBurned;

    final dayOfWeek = log.completedAt.weekday % 7;
    List<int> updatedDayOfWeek = List.from(currentStats.workoutsByDayOfWeek);
    if (updatedDayOfWeek.length != 7) {
      updatedDayOfWeek = List.filled(7, 0);
    }
    updatedDayOfWeek[dayOfWeek]++;

    final hour = log.completedAt.hour;
    String timeOfDay = 'morning';
    if (hour >= 12 && hour < 17) {
      timeOfDay = 'afternoon';
    } else if (hour >= 17)
      timeOfDay = 'evening';
    Map<String, int> updatedTimeOfDay = Map.from(
      currentStats.workoutsByTimeOfDay,
    );
    updatedTimeOfDay[timeOfDay] = (updatedTimeOfDay[timeOfDay] ?? 0) + 1;

    Map<String, int> updatedCategory = Map.from(
      currentStats.workoutsByCategory,
    );
    Set<String> categoriesIncrementedThisLog = {};
    _updateCategoriesFromLog(
      log,
      updatedCategory,
      categoriesIncrementedThisLog,
    );

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
      if (exerciseName.isEmpty) continue;

      updatedExerciseCompletionCounts[exerciseName] =
          (updatedExerciseCompletionCounts[exerciseName] ?? 0) + 1;

      int repsSum = exerciseLog.repsCompleted
          .where((r) => r != null && r > 0)
          .fold(0, (sum, r) => sum + r!);
      if (repsSum > 0) {
        updatedTotalRepsCompleted[exerciseName] =
            (updatedTotalRepsCompleted[exerciseName] ?? 0) + repsSum;
      }

      Duration durationSum = exerciseLog.duration
          .where((d) => d != null && d.inMilliseconds > 0)
          .fold(Duration.zero, (sum, d) => sum + d!);
      if (durationSum > Duration.zero) {
        updatedTotalDuration[exerciseName] =
            (updatedTotalDuration[exerciseName] ?? Duration.zero) + durationSum;
      }
    }

    return currentStats.copyWith(
      totalWorkoutsCompleted: totalWorkouts,
      totalWorkoutMinutes: totalMinutes,
      averageWorkoutDuration: newAverageDuration,
      caloriesBurned: totalCalories,
      workoutsByCategory: updatedCategory,
      workoutsByDayOfWeek: updatedDayOfWeek,
      workoutsByTimeOfDay: updatedTimeOfDay,
      exerciseCompletionCounts: updatedExerciseCompletionCounts,
      totalRepsCompleted: updatedTotalRepsCompleted,
      totalDuration: updatedTotalDuration,
      lastWorkoutDate: log.completedAt,
      lastUpdated: DateTime.now(),
    );
  }

  void _updateCategoriesFromLog(
    WorkoutLog log,
    Map<String, int> updatedCategoryMap,
    Set<String> categoriesIncrementedThisLog,
  ) {
    const String lowerBody = 'Lower Body';
    const String upperBody = 'Upper Body';
    const String core = 'Core';
    const String fullBody = 'Full Body';
    const String cardio = 'Cardio';
    const String otherCategory = 'Other';

    const Map<String, String> muscleToCategoryMap = {
      /* ... your map ... */
      'gluteus maximus': lowerBody,
      'glutes': lowerBody,
      'gluteus medius': lowerBody,
      'hamstrings': lowerBody,
      'quadriceps': lowerBody,
      'calves': lowerBody,
      'adductors': lowerBody,
      'abductors': lowerBody,
      'hip abductors': lowerBody,
      'hip extensors': lowerBody,
      'chest': upperBody,
      'shoulders': upperBody,
      'triceps': upperBody,
      'biceps': upperBody,
      'forearms': upperBody,
      'back': upperBody,
      'trapezius': upperBody,
      'rhomboids': upperBody,
      'latissimus dorsi': upperBody,
      'upper back': upperBody,
      'core': core,
      'rectus abdominis': core,
      'obliques': core,
      'transverse abdominis': core,
      'lower back': core,
      'erector spinae': core,
      'hip flexors': core,
    };

    for (final exerciseLog in log.exercisesCompleted) {
      bool exerciseCategoryAssigned = false;
      for (final muscle in exerciseLog.targetMuscles) {
        final category = muscleToCategoryMap[muscle.toLowerCase().trim()];
        if (category != null &&
            !categoriesIncrementedThisLog.contains(category)) {
          updatedCategoryMap[category] =
              (updatedCategoryMap[category] ?? 0) + 1;
          categoriesIncrementedThisLog.add(category);
          exerciseCategoryAssigned = true;
        }
      }

      if (!exerciseCategoryAssigned &&
          log.workoutCategory != null &&
          log.workoutCategory!.isNotEmpty) {
        String fallbackCategory;
        try {
          WorkoutCategory wcEnum = WorkoutCategory.values.firstWhere(
            (e) => e.name == log.workoutCategory,

            orElse: () => throw Exception("Category name not in enum"),
          );
          switch (wcEnum) {
            case WorkoutCategory.bums:
              fallbackCategory = lowerBody;
              break;
            case WorkoutCategory.tums:
              fallbackCategory = core;
              break;
            case WorkoutCategory.arms:
              fallbackCategory = upperBody;
              break;
            case WorkoutCategory.cardio:
              fallbackCategory = cardio;
              break;
            case WorkoutCategory.fullBody:
              fallbackCategory = fullBody;
              break;

            default:
              fallbackCategory = otherCategory;
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              "Warning: WorkoutCategory string '${log.workoutCategory}' not found in enum. Using '$otherCategory'. Error: $e",
            );
          }
          fallbackCategory = otherCategory;
        }

        if (!categoriesIncrementedThisLog.contains(fallbackCategory)) {
          updatedCategoryMap[fallbackCategory] =
              (updatedCategoryMap[fallbackCategory] ?? 0) + 1;
          categoriesIncrementedThisLog.add(fallbackCategory);
          if (kDebugMode) {
            print(
              "Info: Exercise '${exerciseLog.exerciseName}' muscles (${exerciseLog.targetMuscles}) didn't map. Used workout category fallback: $fallbackCategory",
            );
          }
        }
      } else if (!exerciseCategoryAssigned &&
          (log.workoutCategory == null || log.workoutCategory!.isEmpty)) {
        if (!categoriesIncrementedThisLog.contains(otherCategory)) {
          updatedCategoryMap[otherCategory] =
              (updatedCategoryMap[otherCategory] ?? 0) + 1;
          categoriesIncrementedThisLog.add(otherCategory);
          if (kDebugMode) {
            print(
              "Warning: Exercise '${exerciseLog.exerciseName}' has no target muscles or workout category. Assigned to '$otherCategory'.",
            );
          }
        }
      }
    }
  }

  UserWorkoutStats _createInitialStats(WorkoutLog log) {
    UserWorkoutStats initialStats = UserWorkoutStats.empty(log.userId);

    return _calculateUpdatedStats(initialStats, log);
  }

  WorkoutStreak _calculateUpdatedStreak(
    WorkoutStreak currentStreak,
    DateTime workoutDate,
  ) {
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

    if (currentWorkoutDay.isAtSameMomentAs(lastWorkoutDay)) {
      return currentStreak;
    }

    final difference = currentWorkoutDay.difference(lastWorkoutDay).inDays;

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
    } else if (difference == 2 &&
        currentStreak.streakProtectionsRemaining > 0) {
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
    } else {
      return currentStreak.copyWith(
        currentStreak: 1,
        lastWorkoutDate: currentWorkoutDay,
      );
    }
  }

  Future<bool> useStreakProtection(String userId) async {
    try {
      final docRef = _userStreakDoc(userId);
      final doc = await docRef.get();

      if (!doc.exists) return false;
      final streak = WorkoutStreak.fromMap({'userId': userId, ...doc.data()!});
      if (streak.streakProtectionsRemaining <= 0) return false;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await docRef.update({
        'lastWorkoutDate': Timestamp.fromDate(today),
        'streakProtectionsRemaining': FieldValue.increment(-1),
      });

      await _analytics.logEvent(
        name: 'streak_protection_used',
        parameters: {'user_id': userId},
      );
      return true;
    } catch (e, s) {
      debugPrint('Error using streak protection for $userId: $e\n$s');
      return false;
    }
  }

  Future<void> renewStreakProtections(String userId, int protections) async {
    if (protections <= 0) return;
    try {
      await _userStreakDoc(userId).update({
        'streakProtectionsRemaining': FieldValue.increment(protections),
        'streakProtectionLastRenewed': Timestamp.fromDate(DateTime.now()),
      });
      await _analytics.logEvent(
        name: 'streak_protections_renewed',
        parameters: {'user_id': userId, 'protections_added': protections},
      );
    } catch (e, s) {
      debugPrint('Error renewing streak protections for $userId: $e\n$s');
      rethrow;
    }
  }

  Future<List<WorkoutAchievement>> _checkAndAwardAchievements({
    required String userId,
    required UserWorkoutStats currentStats,
    required WorkoutStreak currentStreak,
    required Set<String> initiallyUnlockedIds,
    required FirebaseFirestore firestore,
    required Transaction transaction,
  }) async {
    List<WorkoutAchievement> newlyUnlocked = [];
    if (userId.isEmpty) return newlyUnlocked;

    try {
      final definitions = allAchievements;
      final achievementsCollectionRef = _userAchievementsCollection(userId);

      if (_debugMode) {
        print(
          "Checking achievements for $userId against ${initiallyUnlockedIds.length} pre-fetched unlocked IDs.",
        );
      }

      for (final definition in definitions) {
        if (initiallyUnlockedIds.contains(definition.id)) {
          continue;
        }

        bool criteriaMet = false;

        switch (definition.criteriaType) {
          case AchievementCriteriaType.totalWorkouts:
            criteriaMet =
                currentStats.totalWorkoutsCompleted >= definition.threshold;
            break;
          case AchievementCriteriaType.currentStreak:
            criteriaMet = currentStreak.currentStreak >= definition.threshold;
            break;
          case AchievementCriteriaType.longestStreak:
            criteriaMet = currentStreak.longestStreak >= definition.threshold;
            break;
          case AchievementCriteriaType.workoutsInCategory:
            if (definition.relatedId != null) {
              criteriaMet =
                  (currentStats.workoutsByCategory[definition.relatedId!] ??
                      0) >=
                  definition.threshold;
            }
            break;
          case AchievementCriteriaType.specificExerciseCompletions:
            if (definition.relatedId != null) {
              criteriaMet =
                  (currentStats.totalRepsCompleted[definition.relatedId!] ??
                      0) >=
                  definition.threshold;
            }
            break;
        }

        if (criteriaMet) {
          final now = DateTime.now();
          final newAchievement = WorkoutAchievement(
            achievementId: definition.id,
            userId: userId,
            unlockedDate: now,
          );
          newlyUnlocked.add(newAchievement);

          final docRef = achievementsCollectionRef.doc(definition.id);
          transaction.set(docRef, newAchievement.toMap());

          if (kDebugMode) {
            print(
              ">>> Awarding Achievement via Transaction for $userId: ${definition.title} (ID: ${definition.id})",
            );
          }
        }
      }
    } catch (e, s) {
      debugPrint(
        "Error during achievement check/write phase for user $userId: $e\n$s",
      );
    }
    return newlyUnlocked;
  }

  Future<List<DisplayAchievement>> getUnlockedAchievementsWithDefinitions(
    String userId,
  ) async {
    if (userId.isEmpty) return [];
    try {
      final definitions = allAchievements;
      final unlockedSnapshot = await _userAchievementsCollection(userId).get();

      final Map<String, WorkoutAchievement> unlockedMap = {
        for (var doc in unlockedSnapshot.docs)
          doc.id: WorkoutAchievement.fromMap(doc.data(), doc.id),
      };

      if (kDebugMode) {
        print(
          "Fetched ${unlockedMap.length} unlocked achievements for $userId",
        );
      }

      List<DisplayAchievement> displayList =
          definitions.map((def) {
            return DisplayAchievement(
              definition: def,
              unlockedInfo: unlockedMap[def.id],
            );
          }).toList();

      displayList.sort((a, b) {
        if (a.isUnlocked && !b.isUnlocked) return -1;
        if (!a.isUnlocked && b.isUnlocked) return 1;

        return a.definition.title.compareTo(b.definition.title);
      });

      return displayList;
    } catch (e, s) {
      debugPrint("Error fetching display achievements for $userId: $e\n$s");

      return [];
    }
  }

  Future<Map<DateTime, List<WorkoutLog>>> getWorkoutHistoryByWeek(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (userId.isEmpty) return {};

    final startMillis = startDate.millisecondsSinceEpoch;
    final endMillis = endDate.millisecondsSinceEpoch;

    if (kDebugMode) {
      print('Fetching workout logs for $userId');
      print('Path: $_userLogsBaseCollection/$userId/$_logsSubcollection');
      print('Date range (ms): $startMillis to $endMillis');
    }

    try {
      final snapshot =
          await _userLogsCollection(userId)
              .where('completedAt', isGreaterThanOrEqualTo: startMillis)
              .where('completedAt', isLessThanOrEqualTo: endMillis)
              .orderBy('completedAt', descending: true)
              .get();

      if (kDebugMode) {
        print('Retrieved ${snapshot.docs.length} workout logs for history');
      }

      Map<DateTime, List<WorkoutLog>> workoutsByDate = {};
      for (final doc in snapshot.docs) {
        try {
          final log = WorkoutLog.fromMap({'id': doc.id, ...doc.data()});
          final dateKey = DateTime(
            log.completedAt.year,
            log.completedAt.month,
            log.completedAt.day,
          );

          (workoutsByDate[dateKey] ??= []).add(log);
        } catch (e, s) {
          if (kDebugMode) {
            print(
              'Error parsing WorkoutLog ${doc.id} in getWorkoutHistoryByWeek: $e\n$s',
            );
          }
        }
      }

      if (kDebugMode && workoutsByDate.isEmpty) {
        if (kDebugMode) {
          print(
            'No real workout logs found, returning sample data for development',
          );
        }

        return {};
      }

      return workoutsByDate;
    } catch (e, s) {
      if (kDebugMode) {
        print('Error getting workout history by week for $userId: $e\n$s');
      }
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getWorkoutFrequencyData(
    String userId,
    int days,
  ) async {
    if (userId.isEmpty) return [];

    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      final startMillis = startDate.millisecondsSinceEpoch;
      final endMillis = endDate.millisecondsSinceEpoch;

      if (kDebugMode) {
        print(
          "Fetching frequency data for $userId, days $days ($startMillis to $endMillis)",
        );
      }

      final snapshot =
          await _userLogsCollection(userId)
              .where('completedAt', isGreaterThanOrEqualTo: startMillis)
              .where('completedAt', isLessThanOrEqualTo: endMillis)
              .orderBy('completedAt')
              .get();

      if (kDebugMode) {
        print(
          "Firestore query returned ${snapshot.docs.length} logs for frequency data.",
        );
      }

      Map<String, int> dateCountMap = {};
      for (int i = 0; i < days; i++) {
        final date = startDate.add(Duration(days: i));
        final dateString = DateFormat('yyyy-MM-dd').format(date);
        dateCountMap[dateString] = 0;
      }

      for (final doc in snapshot.docs) {
        try {
          final log = WorkoutLog.fromMap({'id': doc.id, ...doc.data()});

          final dateString = DateFormat('yyyy-MM-dd').format(log.completedAt);

          if (dateCountMap.containsKey(dateString)) {
            dateCountMap[dateString] = dateCountMap[dateString]! + 1;
          } else {
            if (kDebugMode) {
              print(
                "Warning: Log date $dateString not in initial map, adding.",
              );
            }
            dateCountMap[dateString] = 1;
          }
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print(
              'Error parsing WorkoutLog ${doc.id} in getWorkoutFrequencyData: $e\n$stackTrace',
            );
          }
        }
      }

      List<Map<String, dynamic>> result =
          dateCountMap.entries.map((entry) {
            return {'date': entry.key, 'count': entry.value};
          }).toList();

      result.sort((a, b) => a['date'].compareTo(b['date']));

      if (kDebugMode) {
        print("Processed ${result.length} frequency data points.");
      }
      return result;
    } catch (e, stackTrace) {
      debugPrint(
        'Error getting workout frequency data for $userId: $e\n$stackTrace',
      );
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getWorkoutProgressData({
    required String userId,
    required AnalyticsTimeframe timeframe,
    // Removed periods parameter, it will be determined internally
  }) async {
    if (userId.isEmpty) return [];

    try {
      final now = DateTime.now();
      DateTime startDate;
      String Function(WorkoutLog) groupByFn;
      DateFormat groupFormat;
      int numberOfDataPoints; // To generate placeholders for empty periods

      if (kDebugMode) {
        print(
          "Getting progress data for $userId, timeframe: ${timeframe.name}",
        );
      }

      // Determine date range, grouping function, and format based on timeframe
      switch (timeframe) {
        case AnalyticsTimeframe.weekly:
          // Show last 7 days (daily aggregation)
          numberOfDataPoints = 7;
          startDate = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: numberOfDataPoints - 1));
          groupFormat = DateFormat('yyyy-MM-dd'); // Group by day
          groupByFn = (log) => groupFormat.format(log.completedAt);
          break;
        case AnalyticsTimeframe.monthly:
          // Show last 5 weeks (weekly aggregation)
          numberOfDataPoints = 5; // Show ~1 month as weeks
          final currentWeekStart = _getStartOfWeek(now);
          startDate = currentWeekStart.subtract(
            Duration(days: (numberOfDataPoints - 1) * 7),
          );
          groupFormat = DateFormat(
            'yyyy-MM-dd',
          ); // Group key is week start date
          groupByFn = (log) {
            final weekStart = _getStartOfWeek(log.completedAt);
            return groupFormat.format(weekStart);
          };
          break;
        case AnalyticsTimeframe.yearly:
          // Show last 12 months (monthly aggregation)
          numberOfDataPoints = 12;
          int year = now.year;
          int month = now.month - (numberOfDataPoints - 1);
          while (month <= 0) {
            month += 12;
            year -= 1;
          }
          startDate = DateTime(year, month, 1);
          groupFormat = DateFormat('yyyy-MM'); // Group by month
          groupByFn = (log) => groupFormat.format(log.completedAt);
          break;
      }

      final endDate = now;
      // Fetch slightly earlier to ensure logs on the exact start date are included
      final queryStartDate = startDate.subtract(const Duration(seconds: 1));
      final startMillis = queryStartDate.millisecondsSinceEpoch;
      final endMillis = endDate.millisecondsSinceEpoch;

      if (kDebugMode) print("  - Date Range (ms): $startMillis to $endMillis");

      final snapshot =
          await _userLogsCollection(userId)
              .where(
                'completedAt',
                isGreaterThan: startMillis,
              ) // Use isGreaterThan
              .where('completedAt', isLessThanOrEqualTo: endMillis)
              .orderBy('completedAt')
              .get();

      List<WorkoutLog> logs =
          snapshot.docs
              .map((doc) {
                try {
                  return WorkoutLog.fromMap({'id': doc.id, ...doc.data()});
                } catch (e) {
                  if (kDebugMode) {
                    print(
                      "Error parsing log ${doc.id} in getWorkoutProgressData: $e",
                    );
                  }
                  return null;
                }
              })
              .whereType<WorkoutLog>()
              .toList();

      if (kDebugMode) print("  - Fetched ${logs.length} logs in range.");

      // --- Aggregation Logic ---
      Map<String, Map<String, dynamic>> aggregatedData = {};

      // Initialize placeholder data for all expected periods in the range
      for (int i = 0; i < numberOfDataPoints; i++) {
        String periodKey;
        switch (timeframe) {
          case AnalyticsTimeframe.weekly: // Daily keys
            periodKey = groupFormat.format(startDate.add(Duration(days: i)));
            break;
          case AnalyticsTimeframe.monthly: // Weekly start date keys
            periodKey = groupFormat.format(
              startDate.add(Duration(days: i * 7)),
            );
            break;
          case AnalyticsTimeframe.yearly: // Monthly keys
            DateTime monthDate = DateTime(
              startDate.year,
              startDate.month + i,
              1,
            );
            periodKey = groupFormat.format(monthDate);
            break;
        }
        aggregatedData[periodKey] = {
          'period': periodKey,
          'workouts': 0,
          'minutes': 0,
          'calories': 0,
        };
      }

      // Group fetched logs
      final groupedLogs = groupBy<WorkoutLog, String>(logs, groupByFn);

      // Populate aggregatedData with actual log data
      groupedLogs.forEach((periodKey, periodLogs) {
        // Only update if the key exists (it should due to initialization)
        if (aggregatedData.containsKey(periodKey)) {
          aggregatedData[periodKey] = {
            'period': periodKey,
            'workouts': periodLogs.length,
            'minutes': periodLogs.fold<int>(
              0,
              (sum, log) => sum + log.durationMinutes,
            ),
            'calories': periodLogs.fold<int>(
              0,
              (sum, log) => sum + log.caloriesBurned,
            ),
          };
        } else {
          // This case might happen if a log's date falls slightly outside the calculated range
          // due to timezone differences or edge cases. Log it if necessary.
          if (kDebugMode) {
            print(
              "Warning: Log group key '$periodKey' not found in initialized periods.",
            );
          }
        }
      });

      // Sort by period key and convert to list
      final sortedPeriods = aggregatedData.keys.toList()..sort();
      final result =
          sortedPeriods.map((periodKey) => aggregatedData[periodKey]!).toList();

      if (kDebugMode) {
        print("  - Aggregated progress data points: ${result.length}");
      }
      return result;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Error in getWorkoutProgressData for $userId: $e\n$stackTrace");
      }
      return []; // Return empty list on error
    }
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }
}
