// lib/features/workouts/providers/workout_stats_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_stats.dart';
import '../models/workout_streak.dart';
import '../models/workout_log.dart';
import '../services/workout_stats_service.dart';
import '../../../shared/providers/analytics_provider.dart';

// Provider for the workout stats service
final workoutStatsServiceProvider = Provider<WorkoutStatsService>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return WorkoutStatsService(analytics);
});

// Provider for user's workout stats
final userWorkoutStatsProvider = FutureProvider.family<UserWorkoutStats, String>((ref, userId) async {
  final statsService = ref.watch(workoutStatsServiceProvider);
  return await statsService.getUserWorkoutStats(userId);
});

// Provider for user's workout streak
final userWorkoutStreakProvider = FutureProvider.family<WorkoutStreak, String>((ref, userId) async {
  final statsService = ref.watch(workoutStatsServiceProvider);
  return await statsService.getUserWorkoutStreak(userId);
});

// Provider for workout frequency data
final workoutFrequencyDataProvider = FutureProvider.family<List<Map<String, dynamic>>, ({String userId, int days})>((ref, params) async {
  final statsService = ref.watch(workoutStatsServiceProvider);
  return await statsService.getWorkoutFrequencyData(params.userId, params.days);
});

// Provider for workout calendar data
final workoutCalendarDataProvider = FutureProvider.family<Map<DateTime, List<WorkoutLog>>, ({String userId, DateTime startDate, DateTime endDate})>((ref, params) async {
  final statsService = ref.watch(workoutStatsServiceProvider);
  return await statsService.getWorkoutHistoryByWeek(
    params.userId,
    params.startDate,
    params.endDate,
  );
});

// Notifier for workout stats actions
class WorkoutStatsActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final WorkoutStatsService _statsService;
  
  WorkoutStatsActionsNotifier(this._statsService) : super(const AsyncValue.data(null));
  
  Future<bool> updateStatsFromWorkoutLog(WorkoutLog log) async {
    state = const AsyncValue.loading();
    try {
      await _statsService.updateStatsFromWorkoutLog(log);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
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
  
  Future<bool> renewStreakProtections(String userId, int protections) async {
    state = const AsyncValue.loading();
    try {
      await _statsService.renewStreakProtections(userId, protections);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }
}

// Provider for workout stats actions
final workoutStatsActionsProvider = StateNotifierProvider<WorkoutStatsActionsNotifier, AsyncValue<void>>((ref) {
  final statsService = ref.watch(workoutStatsServiceProvider);
  return WorkoutStatsActionsNotifier(statsService);
});