import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserWorkoutStats extends Equatable {
  final String userId;
  final int totalWorkoutsCompleted;
  final int totalWorkoutMinutes;
  final Map<String, int> workoutsByCategory;

  final List<int> workoutsByDayOfWeek;
  final Map<String, int> workoutsByTimeOfDay;
  final int averageWorkoutDuration;

  final int caloriesBurned;
  final DateTime? lastWorkoutDate;
  final DateTime lastUpdated;

  final Map<String, int> exerciseCompletionCounts;
  final Map<String, int> totalRepsCompleted;
  final Map<String, Duration> totalDuration;

  const UserWorkoutStats({
    required this.userId,
    this.totalWorkoutsCompleted = 0,
    this.totalWorkoutMinutes = 0,
    this.workoutsByCategory = const {},

    this.workoutsByDayOfWeek = const [0, 0, 0, 0, 0, 0, 0],
    this.workoutsByTimeOfDay = const {},
    this.averageWorkoutDuration = 0,
    this.caloriesBurned = 0,
    this.lastWorkoutDate,
    required this.lastUpdated,
    this.exerciseCompletionCounts = const {},
    this.totalRepsCompleted = const {},
    this.totalDuration = const {},
  });

  @override
  List<Object?> get props => [
    userId,
    totalWorkoutsCompleted,
    totalWorkoutMinutes,
    workoutsByCategory,

    workoutsByDayOfWeek,
    workoutsByTimeOfDay,
    averageWorkoutDuration,

    caloriesBurned,
    lastWorkoutDate,
    lastUpdated,
    exerciseCompletionCounts,
    totalRepsCompleted,
    totalDuration,
  ];

  UserWorkoutStats copyWith({
    String? userId,
    int? totalWorkoutsCompleted,
    int? totalWorkoutMinutes,
    Map<String, int>? workoutsByCategory,

    List<int>? workoutsByDayOfWeek,
    Map<String, int>? workoutsByTimeOfDay,
    int? averageWorkoutDuration,

    int? caloriesBurned,
    DateTime? lastWorkoutDate,
    bool setLastWorkoutDateToNull = false,
    DateTime? lastUpdated,
    Map<String, int>? exerciseCompletionCounts,
    Map<String, int>? totalRepsCompleted,
    Map<String, Duration>? totalDuration,
  }) {
    return UserWorkoutStats(
      userId: userId ?? this.userId,
      totalWorkoutsCompleted:
          totalWorkoutsCompleted ?? this.totalWorkoutsCompleted,
      totalWorkoutMinutes: totalWorkoutMinutes ?? this.totalWorkoutMinutes,
      workoutsByCategory: workoutsByCategory ?? this.workoutsByCategory,

      workoutsByDayOfWeek: workoutsByDayOfWeek ?? this.workoutsByDayOfWeek,
      workoutsByTimeOfDay: workoutsByTimeOfDay ?? this.workoutsByTimeOfDay,
      averageWorkoutDuration:
          averageWorkoutDuration ?? this.averageWorkoutDuration,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      lastWorkoutDate:
          setLastWorkoutDateToNull
              ? null
              : (lastWorkoutDate ?? this.lastWorkoutDate),
      lastUpdated: lastUpdated ?? this.lastUpdated,
      exerciseCompletionCounts:
          exerciseCompletionCounts ?? this.exerciseCompletionCounts,
      totalRepsCompleted: totalRepsCompleted ?? this.totalRepsCompleted,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalWorkoutsCompleted': totalWorkoutsCompleted,
      'totalWorkoutMinutes': totalWorkoutMinutes,
      'workoutsByCategory': workoutsByCategory,

      'workoutsByDayOfWeek': workoutsByDayOfWeek,
      'workoutsByTimeOfDay': workoutsByTimeOfDay,
      'averageWorkoutDuration': averageWorkoutDuration,
      'caloriesBurned': caloriesBurned,
      'lastWorkoutDate':
          lastWorkoutDate != null ? Timestamp.fromDate(lastWorkoutDate!) : null,
      'lastUpdated': Timestamp.fromDate(lastUpdated),

      'exerciseCompletionCounts': exerciseCompletionCounts,
      'totalRepsCompleted': totalRepsCompleted,
      'totalDuration': totalDuration.map(
        (k, v) => MapEntry(k, v.inMilliseconds),
      ),
    };
  }

  factory UserWorkoutStats.fromMap(Map<String, dynamic> map) {
    DateTime? parseTimestamp(dynamic timestampData) {
      if (timestampData is Timestamp) {
        return timestampData.toDate();
      } else if (timestampData is int) {
        print("Warning: Date field stored as int (millis). Converting.");
        return DateTime.fromMillisecondsSinceEpoch(timestampData);
      }
      return null;
    }

    return UserWorkoutStats(
      userId: map['userId'] ?? '',
      totalWorkoutsCompleted: map['totalWorkoutsCompleted']?.toInt() ?? 0,
      totalWorkoutMinutes: map['totalWorkoutMinutes']?.toInt() ?? 0,
      workoutsByCategory:
          map['workoutsByCategory'] != null
              ? Map<String, int>.from(map['workoutsByCategory'])
              : {},

      workoutsByDayOfWeek:
          map['workoutsByDayOfWeek'] != null
              ? List<int>.from(map['workoutsByDayOfWeek'])
              : List.filled(7, 0),
      workoutsByTimeOfDay:
          map['workoutsByTimeOfDay'] != null
              ? Map<String, int>.from(map['workoutsByTimeOfDay'])
              : {},
      averageWorkoutDuration: map['averageWorkoutDuration']?.toInt() ?? 0,
      caloriesBurned: map['caloriesBurned']?.toInt() ?? 0,
      lastWorkoutDate: parseTimestamp(map['lastWorkoutDate']),
      lastUpdated: parseTimestamp(map['lastUpdated']) ?? DateTime.now(),

      exerciseCompletionCounts:
          (map['exerciseCompletionCounts'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int? ?? 0),
          ) ??
          const {},
      totalRepsCompleted:
          (map['totalRepsCompleted'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int? ?? 0),
          ) ??
          const {},
      totalDuration:
          (map['totalDuration'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              k,
              v is int ? Duration(milliseconds: v) : Duration.zero,
            ),
          ) ??
          const {},
    );
  }

  factory UserWorkoutStats.empty(String userId) {
    return UserWorkoutStats(
      userId: userId,
      lastUpdated: DateTime.now(),

      workoutsByDayOfWeek: List.filled(7, 0),
    );
  }
}
