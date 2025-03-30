// lib/features/workouts/models/workout_streak.dart
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutStreak extends Equatable {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastWorkoutDate;
  final int streakProtectionsRemaining;
  final DateTime? streakProtectionLastRenewed;

  const WorkoutStreak({
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.lastWorkoutDate,
    this.streakProtectionsRemaining = 0,
    this.streakProtectionLastRenewed,
  });

  @override
  List<Object?> get props => [
    userId,
    currentStreak,
    longestStreak,
    lastWorkoutDate,
    streakProtectionsRemaining,
    streakProtectionLastRenewed,
  ];

  WorkoutStreak copyWith({
    String? userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastWorkoutDate,
    int? streakProtectionsRemaining,
    DateTime? streakProtectionLastRenewed,
  }) {
    return WorkoutStreak(
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
      streakProtectionsRemaining: streakProtectionsRemaining ?? this.streakProtectionsRemaining,
      streakProtectionLastRenewed: streakProtectionLastRenewed ?? this.streakProtectionLastRenewed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastWorkoutDate': Timestamp.fromDate(lastWorkoutDate),
      'streakProtectionsRemaining': streakProtectionsRemaining,
      'streakProtectionLastRenewed': streakProtectionLastRenewed != null
          ? Timestamp.fromDate(streakProtectionLastRenewed!)
          : null,
    };
  }

  factory WorkoutStreak.fromMap(Map<String, dynamic> map) {
    return WorkoutStreak(
      userId: map['userId'] ?? '',
      currentStreak: map['currentStreak']?.toInt() ?? 0,
      longestStreak: map['longestStreak']?.toInt() ?? 0,
      lastWorkoutDate: (map['lastWorkoutDate'] as Timestamp).toDate(),
      streakProtectionsRemaining: map['streakProtectionsRemaining']?.toInt() ?? 0,
      streakProtectionLastRenewed: map['streakProtectionLastRenewed'] != null
          ? (map['streakProtectionLastRenewed'] as Timestamp).toDate()
          : null,
    );
  }

  factory WorkoutStreak.empty(String userId) {
    return WorkoutStreak(
      userId: userId,
      lastWorkoutDate: DateTime.now(),
    );
  }

  // Check if the streak is still active based on the last workout date
  bool get isStreakActive {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final lastWorkoutDay = DateTime(
      lastWorkoutDate.year,
      lastWorkoutDate.month,
      lastWorkoutDate.day,
    );
    
    return lastWorkoutDay.isAtSameMomentAs(yesterday) ||
           lastWorkoutDay.isAtSameMomentAs(DateTime(now.year, now.month, now.day));
  }
}