// lib/features/workouts/providers/workout_stats_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_stats.dart';
import '../models/workout_log.dart';
import '../models/workout_streak.dart';
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

// Provider for simplified stats (used in home tab)
final workoutStatsProvider = FutureProvider.family<WorkoutStats, String>((
  ref,
  userId,
) async {
  final statsService = ref.read(workoutStatsServiceProvider);
  final userStats = await statsService.getUserWorkoutStats(userId);
  final streak = await statsService.getUserWorkoutStreak(userId);

  // Get weekly workout count
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);

  // Query for workouts completed this week
  final firestore = FirebaseFirestore.instance;
  final weeklyLogsSnapshot =
      await firestore
          .collection('user_workout_history')
          .doc(userId)
          .collection('logs')
          .where(
            'completedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekStartDay),
          )
          .where('completedAt', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

  final weeklyCompleted = weeklyLogsSnapshot.docs.length;

  return WorkoutStats(
    totalWorkouts: userStats.totalWorkoutsCompleted,
    totalMinutes: userStats.totalWorkoutMinutes,
    totalCaloriesBurned: userStats.caloriesBurned,
    weeklyGoal: 5, // Default or could be stored in userStats
    weeklyCompleted: weeklyCompleted,
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
  ({String userId, int days})
>((ref, params) async {
  final service = ref.read(workoutStatsServiceProvider);
  return service.getWorkoutFrequencyData(params.userId, params.days);
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
}

// Provider for workout stats actions
final workoutStatsActionsProvider =
    StateNotifierProvider<WorkoutStatsActionsNotifier, AsyncValue<void>>((ref) {
      final statsService = ref.watch(workoutStatsServiceProvider);
      return WorkoutStatsActionsNotifier(statsService);
    });

// final weeklyWorkoutStatsProvider = FutureProvider.family<int, String>((
//   ref,
//   userId,
// ) async {
//   // final statsService = ref.read(workoutStatsServiceProvider);

//   // Get current week start date
//   final now = DateTime.now();
//   final weekStart = now.subtract(Duration(days: now.weekday - 1));
//   final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);

//   // Get workout logs for the current week
//   final firestore = FirebaseFirestore.instance;
//   final weeklyLogsSnapshot =
//       await firestore
//           .collection('user_workout_history')
//           .doc(userId)
//           .collection('logs')
//           .where(
//             'completedAt',
//             isGreaterThanOrEqualTo: Timestamp.fromDate(weekStartDay),
//           )
//           .where('completedAt', isLessThanOrEqualTo: Timestamp.fromDate(now))
//           .get();

//   return weeklyLogsSnapshot.docs.length;
// });
