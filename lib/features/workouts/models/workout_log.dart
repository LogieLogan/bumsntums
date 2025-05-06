// lib/features/workouts/models/workout_log.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum WorkoutLogSource { scheduled, logged, manual, imported }

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
  final String privacy;
  final bool isOfflineCreated;
  final String syncStatus;
  final String? workoutCategory;
  final String? workoutName;
  final List<String> targetAreas;
  final WorkoutLogSource source;

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
    this.workoutCategory,
    this.workoutName,
    this.targetAreas = const [],
    this.source = WorkoutLogSource.manual,
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
    workoutCategory,
    workoutName,
    targetAreas,
    source,
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
    String? workoutCategory,
    String? workoutName,
    List<String>? targetAreas,
    WorkoutLogSource? source,
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
      workoutCategory: workoutCategory ?? this.workoutCategory,
      workoutName: workoutName ?? this.workoutName,
      targetAreas: targetAreas ?? this.targetAreas,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'workoutId': workoutId,

      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': Timestamp.fromDate(completedAt),
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'exercisesCompleted': exercisesCompleted.map((e) => e.toMap()).toList(),
      'userFeedback': userFeedback.toMap(),
      'isShared': isShared,
      'privacy': privacy,
      'isOfflineCreated': isOfflineCreated,
      'syncStatus': syncStatus,
      'workoutCategory': workoutCategory,
      'workoutName': workoutName,
      'targetAreas': targetAreas,
      'source': source.name,
    };
  }

  factory WorkoutLog.fromMap(Map<String, dynamic> map) {
    DateTime _dateTimeFromTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }

      return DateTime.now();
    }

    return WorkoutLog(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      workoutId: map['workoutId'] ?? '',
      startedAt: _dateTimeFromTimestamp(map['startedAt']),
      completedAt: _dateTimeFromTimestamp(map['completedAt']),
      durationMinutes: map['durationMinutes']?.toInt() ?? 0,
      caloriesBurned: map['caloriesBurned']?.toInt() ?? 0,
      exercisesCompleted:
          map['exercisesCompleted'] != null
              ? List<ExerciseLog>.from(
                map['exercisesCompleted']?.map((x) => ExerciseLog.fromMap(x)),
              )
              : [],
      userFeedback: UserFeedback.fromMap(map['userFeedback'] ?? {}),
      isShared: map['isShared'] ?? false,
      privacy: map['privacy'] ?? 'private',
      isOfflineCreated: map['isOfflineCreated'] ?? false,
      syncStatus: map['syncStatus'] ?? 'synced',
      workoutCategory: map['workoutCategory'],
      workoutName: map['workoutName'],
      targetAreas:
          map['targetAreas'] != null
              ? List<String>.from(map['targetAreas'])
              : [],

      source: WorkoutLogSource.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => WorkoutLogSource.manual,
      ),
    );
  }
}

class ExerciseLog extends Equatable {
  final String exerciseName;
  final int setsCompleted;
  final List<int?> repsCompleted;
  final List<double?> weightUsed;
  final List<Duration?> duration;
  final double? distance;
  final double? speed;
  final int difficultyRating;
  final String? notes;
  final List<String> targetMuscles;

  const ExerciseLog({
    required this.exerciseName,
    required this.setsCompleted,
    required this.repsCompleted,
    required this.weightUsed,
    required this.duration,
    this.distance,
    this.speed,
    required this.difficultyRating,
    this.notes,
    this.targetMuscles = const [],
  });

  @override
  List<Object?> get props => [
    exerciseName,
    setsCompleted,
    repsCompleted,
    weightUsed,
    duration,
    distance,
    speed,
    difficultyRating,
    notes,
    targetMuscles,
  ];

  Map<String, dynamic> toMap() {
    return {
      'exerciseName': exerciseName,
      'setsCompleted': setsCompleted,
      'repsCompleted': repsCompleted.map((r) => r).toList(),
      'weightUsed': weightUsed.map((w) => w).toList(),
      'duration': duration.map((d) => d?.inMilliseconds).toList(),
      'distance': distance,
      'speed': speed,
      'difficultyRating': difficultyRating,
      'notes': notes,
      'targetMuscles': targetMuscles,
    };
  }

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      exerciseName: map['exerciseName'] ?? '',
      setsCompleted: map['setsCompleted']?.toInt() ?? 0,
      repsCompleted:
          (map['repsCompleted'] as List<dynamic>?)
              ?.map((r) => r as int?)
              .toList() ??
          [],
      weightUsed:
          (map['weightUsed'] as List<dynamic>?)
              ?.map((w) => (w as num?)?.toDouble())
              .toList() ??
          [],
      duration:
          (map['duration'] as List<dynamic>?)
              ?.map((d) => d != null ? Duration(milliseconds: d as int) : null)
              .toList() ??
          [],
      distance: (map['distance'] as num?)?.toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      difficultyRating: map['difficultyRating']?.toInt() ?? 3,
      notes: map['notes'],
      targetMuscles:
          map['targetMuscles'] != null
              ? List<String>.from(map['targetMuscles'])
              : [],
    );
  }
}

class UserFeedback extends Equatable {
  final int rating;
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
  List<Object?> get props => [rating, feltEasy, feltTooHard, comments];

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
