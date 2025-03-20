// lib/features/workouts/models/workout_stats.dart
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserWorkoutStats extends Equatable {
  final String userId;
  final int totalWorkoutsCompleted;
  final int totalWorkoutMinutes;
  final Map<String, int> workoutsByCategory;
  final Map<String, int> workoutsByDifficulty;
  final List<int> workoutsByDayOfWeek; // index 0 = Sunday
  final Map<String, int> workoutsByTimeOfDay;
  final int averageWorkoutDuration;
  final int longestStreak;
  final int currentStreak;
  final int caloriesBurned;
  final DateTime lastWorkoutDate;
  final DateTime lastUpdated;
  final int weeklyAverage;
  final List<int> monthlyTrend; // Workouts per month for last 6 months
  final double completionRate; // Percentage of started workouts that were completed

  const UserWorkoutStats({
    required this.userId,
    this.totalWorkoutsCompleted = 0,
    this.totalWorkoutMinutes = 0,
    this.workoutsByCategory = const {},
    this.workoutsByDifficulty = const {},
    this.workoutsByDayOfWeek = const [0, 0, 0, 0, 0, 0, 0],
    this.workoutsByTimeOfDay = const {},
    this.averageWorkoutDuration = 0,
    this.longestStreak = 0,
    this.currentStreak = 0,
    this.caloriesBurned = 0,
    required this.lastWorkoutDate,
    required this.lastUpdated,
    this.weeklyAverage = 0,
    this.monthlyTrend = const [],
    this.completionRate = 0.0,
  });

  @override
  List<Object?> get props => [
    userId,
    totalWorkoutsCompleted,
    totalWorkoutMinutes,
    workoutsByCategory,
    workoutsByDifficulty,
    workoutsByDayOfWeek,
    workoutsByTimeOfDay,
    averageWorkoutDuration,
    longestStreak,
    currentStreak,
    caloriesBurned,
    lastWorkoutDate,
    lastUpdated,
    weeklyAverage,
    monthlyTrend,
    completionRate,
  ];

  UserWorkoutStats copyWith({
    String? userId,
    int? totalWorkoutsCompleted,
    int? totalWorkoutMinutes,
    Map<String, int>? workoutsByCategory,
    Map<String, int>? workoutsByDifficulty,
    List<int>? workoutsByDayOfWeek,
    Map<String, int>? workoutsByTimeOfDay,
    int? averageWorkoutDuration,
    int? longestStreak,
    int? currentStreak,
    int? caloriesBurned,
    DateTime? lastWorkoutDate,
    DateTime? lastUpdated,
    int? weeklyAverage,
    List<int>? monthlyTrend,
    double? completionRate,
  }) {
    return UserWorkoutStats(
      userId: userId ?? this.userId,
      totalWorkoutsCompleted: totalWorkoutsCompleted ?? this.totalWorkoutsCompleted,
      totalWorkoutMinutes: totalWorkoutMinutes ?? this.totalWorkoutMinutes,
      workoutsByCategory: workoutsByCategory ?? this.workoutsByCategory,
      workoutsByDifficulty: workoutsByDifficulty ?? this.workoutsByDifficulty,
      workoutsByDayOfWeek: workoutsByDayOfWeek ?? this.workoutsByDayOfWeek,
      workoutsByTimeOfDay: workoutsByTimeOfDay ?? this.workoutsByTimeOfDay,
      averageWorkoutDuration: averageWorkoutDuration ?? this.averageWorkoutDuration,
      longestStreak: longestStreak ?? this.longestStreak,
      currentStreak: currentStreak ?? this.currentStreak,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      weeklyAverage: weeklyAverage ?? this.weeklyAverage,
      monthlyTrend: monthlyTrend ?? this.monthlyTrend,
      completionRate: completionRate ?? this.completionRate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalWorkoutsCompleted': totalWorkoutsCompleted,
      'totalWorkoutMinutes': totalWorkoutMinutes,
      'workoutsByCategory': workoutsByCategory,
      'workoutsByDifficulty': workoutsByDifficulty,
      'workoutsByDayOfWeek': workoutsByDayOfWeek,
      'workoutsByTimeOfDay': workoutsByTimeOfDay,
      'averageWorkoutDuration': averageWorkoutDuration,
      'longestStreak': longestStreak,
      'currentStreak': currentStreak,
      'caloriesBurned': caloriesBurned,
      'lastWorkoutDate': Timestamp.fromDate(lastWorkoutDate),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'weeklyAverage': weeklyAverage,
      'monthlyTrend': monthlyTrend,
      'completionRate': completionRate,
    };
  }

  factory UserWorkoutStats.fromMap(Map<String, dynamic> map) {
    return UserWorkoutStats(
      userId: map['userId'] ?? '',
      totalWorkoutsCompleted: map['totalWorkoutsCompleted']?.toInt() ?? 0,
      totalWorkoutMinutes: map['totalWorkoutMinutes']?.toInt() ?? 0,
      workoutsByCategory: map['workoutsByCategory'] != null
          ? Map<String, int>.from(map['workoutsByCategory'])
          : {},
      workoutsByDifficulty: map['workoutsByDifficulty'] != null
          ? Map<String, int>.from(map['workoutsByDifficulty'])
          : {},
      workoutsByDayOfWeek: map['workoutsByDayOfWeek'] != null
          ? List<int>.from(map['workoutsByDayOfWeek'])
          : [0, 0, 0, 0, 0, 0, 0],
      workoutsByTimeOfDay: map['workoutsByTimeOfDay'] != null
          ? Map<String, int>.from(map['workoutsByTimeOfDay'])
          : {},
      averageWorkoutDuration: map['averageWorkoutDuration']?.toInt() ?? 0,
      longestStreak: map['longestStreak']?.toInt() ?? 0,
      currentStreak: map['currentStreak']?.toInt() ?? 0,
      caloriesBurned: map['caloriesBurned']?.toInt() ?? 0,
      lastWorkoutDate: map['lastWorkoutDate'] != null
          ? (map['lastWorkoutDate'] as Timestamp).toDate()
          : DateTime.now(),
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
      weeklyAverage: map['weeklyAverage']?.toInt() ?? 0,
      monthlyTrend: map['monthlyTrend'] != null
          ? List<int>.from(map['monthlyTrend'])
          : [],
      completionRate: map['completionRate']?.toDouble() ?? 0.0,
    );
  }

  factory UserWorkoutStats.empty(String userId) {
    return UserWorkoutStats(
      userId: userId,
      lastWorkoutDate: DateTime.now(),
      lastUpdated: DateTime.now(),
      workoutsByDayOfWeek: [0, 0, 0, 0, 0, 0, 0],
      monthlyTrend: [0, 0, 0, 0, 0, 0],
    );
  }
}