// lib/features/workout_analytics/providers/achievement_provider.dart

import 'package:bums_n_tums/features/workout_analytics/providers/workout_stats_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/achievement_definitions.dart';

final userAchievementsProvider = FutureProvider.autoDispose<
  List<DisplayAchievement>
>((ref) async {
  final userId = ref.watch(
    authStateProvider.select((state) => state.value?.uid),
  );

  if (userId == null || userId.isEmpty) {
    if (kDebugMode) {
      print("userAchievementsProvider: No user ID, returning empty list.");
    }
    return [];
  }

  final statsService = ref.watch(workoutStatsServiceProvider);

  if (kDebugMode) {
    print("userAchievementsProvider: Fetching achievements for user $userId");
  }

  try {
    final achievements = await statsService
        .getUnlockedAchievementsWithDefinitions(userId);
    if (kDebugMode) {
      print(
        "userAchievementsProvider: Fetched ${achievements.length} achievements for user $userId",
      );
    }
    return achievements;
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print(
        "userAchievementsProvider: Error fetching achievements for user $userId: $e",
      );
    }

    throw Exception('Failed to load achievements: $e');
  }
});
