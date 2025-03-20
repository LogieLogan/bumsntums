// lib/features/home/providers/workout_stats_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model to store user workout statistics
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
  }) : lastWorkoutDate =
           lastWorkoutDate ??
           DateTime(2000); // Default to a past date // Default to a past date

  /// Check if the user has worked out today
  bool get hasWorkedOutToday {
    final now = DateTime.now();
    return lastWorkoutDate.year == now.year &&
        lastWorkoutDate.month == now.month &&
        lastWorkoutDate.day == now.day;
  }

  /// Calculate weekly goal progress percentage
  double get weeklyProgress {
    if (weeklyGoal == 0) return 0.0;
    return weeklyCompleted / weeklyGoal;
  }

  /// Create a copy of this WorkoutStats with the given fields replaced with new values
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

/// Service to fetch and manage workout statistics
class WorkoutStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch user workout statistics from Firestore
  Future<WorkoutStats> getUserWorkoutStats(String userId) async {
    try {
      // Attempt to get user workout analytics from Firebase
      final doc =
          await _firestore
              .collection('user_workout_analytics')
              .doc(userId)
              .get();

      if (!doc.exists || doc.data() == null) {
        return WorkoutStats();
      }

      final data = doc.data()!;

      // Get weekly workout count for current week
      final DateTime now = DateTime.now();
      final DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));

      // Convert to start of day
      final DateTime weekStartDay = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day,
      );

      // Calculate completed workouts this week
      // In a real implementation, you would query for workouts completed since weekStartDay
      int weeklyCompleted = 0;

      // For now, we'll return default values
      return WorkoutStats(
        totalWorkouts: data['totalWorkoutsCompleted'] ?? 0,
        totalMinutes: data['totalWorkoutMinutes'] ?? 0,
        totalCaloriesBurned: data['caloriesBurned'] ?? 0,
        weeklyGoal: 5, // Default weekly goal
        weeklyCompleted: weeklyCompleted,
        currentStreak: data['currentStreak'] ?? 0,
        lastWorkoutDate:
            data['lastWorkoutDate'] != null
                ? (data['lastWorkoutDate'] as Timestamp).toDate()
                : null,
      );
    } catch (e) {
      print('Error fetching workout stats: $e');
      return WorkoutStats();
    }
  }
}

/// Provider for the WorkoutStatsService
final workoutStatsServiceProvider = Provider<WorkoutStatsService>((ref) {
  return WorkoutStatsService();
});

/// Provider that fetches workout stats for a specific user
final workoutStatsProvider = FutureProvider.family<WorkoutStats, String>((
  ref,
  userId,
) async {
  final service = ref.read(workoutStatsServiceProvider);
  return service.getUserWorkoutStats(userId);
});
