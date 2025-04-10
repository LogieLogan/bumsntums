// lib/features/workout_analytics/providers/achievement_provider.dart

import 'package:bums_n_tums/features/workout_analytics/providers/workout_stats_provider.dart';
import 'package:riverpod/riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/achievement_definitions.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

final userAchievementsProvider =
    FutureProvider.autoDispose<List<DisplayAchievement>>((ref) {
      final userId = ref.watch(
        authStateProvider.select((state) => state.value?.uid),
      );

      if (userId == null || userId.isEmpty) {
        print("userAchievementsProvider: No user ID, returning empty list.");
        return Future.value([]);
      }

      final statsService = ref.watch(workoutStatsServiceProvider);

      print("userAchievementsProvider: Fetching achievements for user $userId");

      return statsService.getUnlockedAchievementsWithDefinitions(userId);
    });

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});
