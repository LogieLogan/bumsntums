// lib/features/workouts/models/workout_log.dart
import 'package:equatable/equatable.dart';

class WorkoutLog extends Equatable {
  final String id;
  final String userId;
  final String workoutId;
  final DateTime startedAt;
  final DateTime completedAt;
  final int durationMinutes;
  final int caloriesBurned;
  final List<ExerciseLog> exercisesCompleted;
  final UserFeedback userFeedback;
  final bool isShared;
  final String privacy; // 'private', 'followers', 'public'
  final bool isOfflineCreated;
  final String syncStatus; // 'synced', 'pending'

  const WorkoutLog({
    required this.id,
    required this.userId,
    required this.workoutId,
    required this.startedAt,
    required this.completedAt,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.exercisesCompleted,
    required this.userFeedback,
    this.isShared = false,
    this.privacy = 'private',
    this.isOfflineCreated = false,
    this.syncStatus = 'synced',
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    workoutId,
    startedAt,
    completedAt,
    durationMinutes,
    caloriesBurned,
    exercisesCompleted,
    userFeedback,
    isShared,
    privacy,
    isOfflineCreated,
    syncStatus,
  ];

  WorkoutLog copyWith({
    String? id,
    String? userId,
    String? workoutId,
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationMinutes,
    int? caloriesBurned,
    List<ExerciseLog>? exercisesCompleted,
    UserFeedback? userFeedback,
    bool? isShared,
    String? privacy,
    bool? isOfflineCreated,
    String? syncStatus,
  }) {
    return WorkoutLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workoutId: workoutId ?? this.workoutId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      exercisesCompleted: exercisesCompleted ?? this.exercisesCompleted,
      userFeedback: userFeedback ?? this.userFeedback,
      isShared: isShared ?? this.isShared,
      privacy: privacy ?? this.privacy,
      isOfflineCreated: isOfflineCreated ?? this.isOfflineCreated,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'workoutId': workoutId,
      'startedAt': startedAt.millisecondsSinceEpoch,
      'completedAt': completedAt.millisecondsSinceEpoch,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'exercisesCompleted': exercisesCompleted.map((e) => e.toMap()).toList(),
      'userFeedback': userFeedback.toMap(),
      'isShared': isShared,
      'privacy': privacy,
      'isOfflineCreated': isOfflineCreated,
      'syncStatus': syncStatus,
    };
  }

  factory WorkoutLog.fromMap(Map<String, dynamic> map) {
    return WorkoutLog(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      workoutId: map['workoutId'] ?? '',
      startedAt: DateTime.fromMillisecondsSinceEpoch(map['startedAt']),
      completedAt: DateTime.fromMillisecondsSinceEpoch(map['completedAt']),
      durationMinutes: map['durationMinutes']?.toInt() ?? 0,
      caloriesBurned: map['caloriesBurned']?.toInt() ?? 0,
      exercisesCompleted: map['exercisesCompleted'] != null
          ? List<ExerciseLog>.from(
              map['exercisesCompleted']?.map((x) => ExerciseLog.fromMap(x)))
          : [],
      userFeedback: UserFeedback.fromMap(map['userFeedback'] ?? {}),
      isShared: map['isShared'] ?? false,
      privacy: map['privacy'] ?? 'private',
      isOfflineCreated: map['isOfflineCreated'] ?? false,
      syncStatus: map['syncStatus'] ?? 'synced',
    );
  }
}

class ExerciseLog extends Equatable {
  final String exerciseName;
  final int setsCompleted;
  final int repsCompleted;
  final int difficultyRating;
  final String? notes; 

  const ExerciseLog({
    required this.exerciseName,
    required this.setsCompleted,
    required this.repsCompleted,
    required this.difficultyRating,
    this.notes,
  });

  @override
  List<Object?> get props => [
    exerciseName,
    setsCompleted,
    repsCompleted,
    difficultyRating,
  ];

  Map<String, dynamic> toMap() {
    return {
      'exerciseName': exerciseName,
      'setsCompleted': setsCompleted,
      'repsCompleted': repsCompleted,
      'difficultyRating': difficultyRating,
    };
  }

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      exerciseName: map['exerciseName'] ?? '',
      setsCompleted: map['setsCompleted']?.toInt() ?? 0,
      repsCompleted: map['repsCompleted']?.toInt() ?? 0,
      difficultyRating: map['difficultyRating']?.toInt() ?? 3,
    );
  }
}

class UserFeedback extends Equatable {
  final int rating; // 1-5
  final bool feltEasy;
  final bool feltTooHard;
  final String? comments;

  const UserFeedback({
    required this.rating,
    this.feltEasy = false,
    this.feltTooHard = false,
    this.comments,
  });

  @override
  List<Object?> get props => [
    rating,
    feltEasy,
    feltTooHard,
    comments,
  ];

  Map<String, dynamic> toMap() {
    return {
      'rating': rating,
      'feltEasy': feltEasy,
      'feltTooHard': feltTooHard,
      'comments': comments,
    };
  }

  factory UserFeedback.fromMap(Map<String, dynamic> map) {
    return UserFeedback(
      rating: map['rating']?.toInt() ?? 3,
      feltEasy: map['feltEasy'] ?? false,
      feltTooHard: map['feltTooHard'] ?? false,
      comments: map['comments'],
    );
  }
}