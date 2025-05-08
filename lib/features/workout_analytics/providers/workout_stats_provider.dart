// lib/features/workout_analytics/providers/workout_stats_provider.dart

import 'package:bums_n_tums/features/auth/providers/user_provider.dart';
import 'package:bums_n_tums/features/workout_analytics/models/workout_analytics_timeframe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_stats.dart';
import '../../workouts/models/workout_log.dart';
import '../../workouts/models/workout_streak.dart';
import '../services/workout_stats_service.dart';
import '../../../shared/providers/analytics_provider.dart';

// Simple stats model for home screen
class WorkoutStats {
  final int totalWorkouts;
  final int totalMinutes;
  final int totalCaloriesBurned;
  final int weeklyGoal;
  final int weeklyCompleted;
  final int currentStreak;
  final DateTime lastWorkoutDate;

  WorkoutStats({
    this.totalWorkouts = 0,
    this.totalMinutes = 0,
    this.totalCaloriesBurned = 0,
    this.weeklyGoal = 5,
    this.weeklyCompleted = 0,
    this.currentStreak = 0,
    DateTime? lastWorkoutDate,
  }) : lastWorkoutDate = lastWorkoutDate ?? DateTime(2000);

  bool get hasWorkedOutToday {
    final now = DateTime.now();
    return lastWorkoutDate.year == now.year &&
        lastWorkoutDate.month == now.month &&
        lastWorkoutDate.day == now.day;
  }

  double get weeklyProgress {
    if (weeklyGoal == 0) return 0.0;
    return weeklyCompleted / weeklyGoal;
  }

  WorkoutStats copyWith({
    int? totalWorkouts,
    int? totalMinutes,
    int? totalCaloriesBurned,
    int? weeklyGoal,
    int? weeklyCompleted,
    int? currentStreak,
    DateTime? lastWorkoutDate,
  }) {
    return WorkoutStats(
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      totalCaloriesBurned: totalCaloriesBurned ?? this.totalCaloriesBurned,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      weeklyCompleted: weeklyCompleted ?? this.weeklyCompleted,
      currentStreak: currentStreak ?? this.currentStreak,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
    );
  }
}

// Provider for the workout stats service
final workoutStatsServiceProvider = Provider<WorkoutStatsService>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return WorkoutStatsService(analytics);
});

final workoutStatsProvider = FutureProvider.family<WorkoutStats, String>((
  ref,
  userId,
) async {
  // Fetch necessary services and data concurrently
  final statsService = ref.read(workoutStatsServiceProvider);
  final userProfileAsync = ref.watch(userProfileProvider); // Watch user profile

  // Fetch stats and streak in parallel
  final statsFutures = Future.wait([
    statsService.getUserWorkoutStats(userId),
    statsService.getUserWorkoutStreak(userId),
  ]);

  // Fetch weekly logs
  final now = DateTime.now();
  // Ensure week starts on Monday consistently
  final weekStart = now.subtract(
    Duration(days: (now.weekday + 6) % 7),
  ); // Handles Sunday edge case
  final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
  // Use end of the week for the query to include Sunday fully
  final weekEnd = weekStart.add(
    const Duration(days: 7),
  ); // Start of next Monday

  final firestore = FirebaseFirestore.instance;
  final weeklyLogsSnapshot =
      await firestore
          .collection('workout_logs')
          .doc(userId)
          .collection('logs')
          .where(
            'completedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekStartDay),
          )
          .where(
            'completedAt',
            isLessThan: Timestamp.fromDate(weekEnd),
          ) // Use exclusive end
          .get();

  final weeklyCompleted = weeklyLogsSnapshot.docs.length;

  // Await stats and streak results
  final statsResults = await statsFutures;
  final userStats = statsResults[0] as UserWorkoutStats;
  final streak = statsResults[1] as WorkoutStreak;

  // --- Get weekly goal from User Profile ---
  // Use the watched user profile state
  final userProfile =
      userProfileAsync.value; // Get the profile data if available
  // Use profile value if available and not null, otherwise default to 3
  final weeklyGoal = userProfile?.weeklyWorkoutDays ?? 3;
  // --- End Get weekly goal ---

  print(
    "Stats Card Provider: weeklyGoal=$weeklyGoal, weeklyCompleted=$weeklyCompleted",
  ); // Add log

  return WorkoutStats(
    totalWorkouts: userStats.totalWorkoutsCompleted,
    totalMinutes: userStats.totalWorkoutMinutes,
    totalCaloriesBurned: userStats.caloriesBurned,
    weeklyGoal: weeklyGoal, // Use fetched/defaulted goal
    weeklyCompleted: weeklyCompleted, // Use calculated completed count
    currentStreak: streak.currentStreak,
    lastWorkoutDate: userStats.lastWorkoutDate,
  );
});

// Provider for complete user workout stats
final userWorkoutStatsProvider =
    FutureProvider.family<UserWorkoutStats, String>((ref, userId) async {
      final service = ref.read(workoutStatsServiceProvider);
      return service.getUserWorkoutStats(userId);
    });

// Provider for workout streak
final userWorkoutStreakProvider = FutureProvider.family<WorkoutStreak, String>((
  ref,
  userId,
) async {
  final service = ref.read(workoutStatsServiceProvider);
  return service.getUserWorkoutStreak(userId);
});

// Provider for workout frequency data
final workoutFrequencyDataProvider = FutureProvider.family<
  List<Map<String, dynamic>>,
  ({String userId, int days}) // <<< Check the parameter type here
>((ref, params) async {
  // <<< params contains userId and days
  // Ensure user ID is handled correctly, especially if potentially null initially
  final userId = params.userId;
  if (userId.isEmpty) {
    print(
      "WorkoutFrequencyDataProvider: No user ID provided, returning empty list.",
    );
    return []; // Return empty if no user ID
  }
  final days = params.days;
  print(
    "WorkoutFrequencyDataProvider: Fetching for user $userId, days $days",
  ); // Add print
  final service = ref.read(workoutStatsServiceProvider);
  try {
    final result = await service.getWorkoutFrequencyData(userId, days);
    print(
      "WorkoutFrequencyDataProvider: Fetched ${result.length} frequency data points.",
    ); // Add print
    return result;
  } catch (e) {
    print("Error in workoutFrequencyDataProvider for user $userId: $e");
    // Consider logging to crash reporting service
    // ref.read(crashReportingServiceProvider).recordError(e, stackTrace);
    rethrow; // Re-throw error so the .when clause catches it
  }
});

final workoutProgressDataProvider = FutureProvider.family<
  List<Map<String, dynamic>>,
  ({String userId, AnalyticsTimeframe timeframe}) // Parameters needed
>((ref, params) async {
  final userId = params.userId;
  final timeframe = params.timeframe;

  if (userId.isEmpty) {
    print("workoutProgressDataProvider: No user ID provided.");
    return [];
  }

  print(
    "workoutProgressDataProvider: Fetching for user $userId, timeframe ${timeframe.name}",
  );
  final service = ref.read(workoutStatsServiceProvider);
  try {
    // REMOVE periods calculation
    // Let the service determine the range and aggregation based on timeframe
    final result = await service.getWorkoutProgressData(
      userId: userId,
      timeframe: timeframe,
      // Removed periods parameter
    );
    print(
      "workoutProgressDataProvider: Successfully fetched ${result.length} progress points.",
    );
    return result;
  } catch (e) {
    print("Error in workoutProgressDataProvider for user $userId: $e");
    // Log error
    // ref.read(crashReportingServiceProvider)...
    rethrow; // Allow the UI to handle the error state
  }
});

// Actions notifier for workout stats
class WorkoutStatsActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final WorkoutStatsService _statsService;

  WorkoutStatsActionsNotifier(this._statsService)
    : super(const AsyncValue.data(null));

  Future<void> updateStatsFromWorkoutLog(WorkoutLog log) async {
    state = const AsyncValue.loading();
    try {
      await _statsService.updateStatsFromWorkoutLog(log);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> useStreakProtection(String userId) async {
    state = const AsyncValue.loading();
    try {
      final success = await _statsService.useStreakProtection(userId);
      state = const AsyncValue.data(null);
      return success;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  void initializeAchievements(String userId) {}
}

// Provider for workout stats actions
final workoutStatsActionsProvider =
    StateNotifierProvider<WorkoutStatsActionsNotifier, AsyncValue<void>>((ref) {
      final statsService = ref.watch(workoutStatsServiceProvider);
      return WorkoutStatsActionsNotifier(statsService);
    });
