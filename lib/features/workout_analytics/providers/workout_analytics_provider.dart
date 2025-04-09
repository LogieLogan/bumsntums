// lib/features/workout_analytics/providers/workout_analytics_provider.dart
import 'package:bums_n_tums/features/workout_analytics/data/achievement_definitions.dart';
import 'package:bums_n_tums/features/workout_analytics/models/workout_achievement.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_stats.dart';
import '../../workouts/models/workout_streak.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

Future<void> initializeUserAchievements(String userId) async {
  try {
    // Check if achievements already exist
    final snapshot =
        await FirebaseFirestore.instance
            .collection('user_achievements')
            .doc(userId)
            .collection('achievements')
            .limit(1)
            .get();

    // If achievements already exist, don't reinitialize
    if (snapshot.docs.isNotEmpty) {
      return;
    }

    // Initialize with bronze tier for all achievements with 0 progress
    final batch = FirebaseFirestore.instance.batch();
    final achievements = AchievementDefinitions.all;

    for (final achievement in achievements) {
      final docRef = FirebaseFirestore.instance
          .collection('user_achievements')
          .doc(userId)
          .collection('achievements')
          .doc(achievement.id);

      // Create a bronze tier achievement with 0 progress
      final data =
          achievement
              .createInstance(tier: AchievementTier.bronze, currentValue: 0)
              .toMap();

      batch.set(docRef, data);
    }

    await batch.commit();
  } catch (e) {
    print('Error initializing achievements: $e');
    // Log the error but don't rethrow - this is a background operation
  }
}

class WorkoutStatsActions extends StateNotifier<bool> {
  final Ref _ref;

  WorkoutStatsActions(this._ref) : super(false);

  Future<bool> useStreakProtection(String userId) async {
    state = true;

    try {
      final analytics = _ref.read(analyticsServiceProvider);
      analytics.logEvent(
        name: 'use_streak_protection',
        parameters: {'user_id': userId},
      );

      final streakDoc =
          await FirebaseFirestore.instance
              .collection('workout_streaks')
              .doc(userId)
              .get();

      if (!streakDoc.exists) {
        state = false;
        return false;
      }

      final streak = WorkoutStreak.fromMap({
        'userId': userId,
        ...streakDoc.data()!,
      });

      if (streak.streakProtectionsRemaining <= 0) {
        state = false;
        return false;
      }

      // Apply streak protection
      await FirebaseFirestore.instance
          .collection('workout_streaks')
          .doc(userId)
          .update({
            'streakProtectionsRemaining': streak.streakProtectionsRemaining - 1,
            'lastWorkoutDate': Timestamp.fromDate(DateTime.now()),
            'streakProtectionLastRenewed': Timestamp.fromDate(DateTime.now()),
          });

      state = false;
      return true;
    } catch (e) {
      _ref
          .read(analyticsServiceProvider)
          .logError(error: 'Error using streak protection: $e');
      state = false;
      return false;
    }
  }

  Future<void> initializeAchievements(String userId) async {
    state = true;
    try {
      await initializeUserAchievements(userId);
    } finally {
      state = false;
    }
  }
}
