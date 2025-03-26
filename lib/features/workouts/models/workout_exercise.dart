// lib/features/workouts/models/workout_exercise.dart
import 'package:equatable/equatable.dart';
import '../services/exercise_db_service.dart';
import 'exercise.dart';

class WorkoutExercise extends Equatable {
  final String exerciseId;  // Reference to the base exercise
  final int sets;
  final int reps;
  final int? durationSeconds; 
  final int restBetweenSeconds;
  final double? weight;
  final int? resistanceLevel;
  final Map<String, dynamic>? tempo;

  const WorkoutExercise({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    this.durationSeconds,
    required this.restBetweenSeconds,
    this.weight,
    this.resistanceLevel,
    this.tempo,
  });

  @override
  List<Object?> get props => [
    exerciseId,
    sets,
    reps,
    durationSeconds,
    restBetweenSeconds,
    weight,
    resistanceLevel,
    tempo,
  ];

  // Method to resolve the full exercise data
  Future<Exercise> resolveExercise(ExerciseDBService exerciseService) async {
    final baseExercise = await exerciseService.getExerciseById(exerciseId);
    // Override the base exercise with workout-specific parameters
    return baseExercise.copyWith(
      sets: sets,
      reps: reps,
      durationSeconds: durationSeconds,
      restBetweenSeconds: restBetweenSeconds,
      weight: weight,
      resistanceLevel: resistanceLevel,
      tempo: tempo,
    );
  }

  WorkoutExercise copyWith({
    String? exerciseId,
    int? sets,
    int? reps,
    int? durationSeconds,
    int? restBetweenSeconds,
    double? weight,
    int? resistanceLevel,
    Map<String, dynamic>? tempo,
  }) {
    return WorkoutExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      restBetweenSeconds: restBetweenSeconds ?? this.restBetweenSeconds,
      weight: weight ?? this.weight,
      resistanceLevel: resistanceLevel ?? this.resistanceLevel,
      tempo: tempo ?? this.tempo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'sets': sets,
      'reps': reps,
      'durationSeconds': durationSeconds,
      'restBetweenSeconds': restBetweenSeconds,
      'weight': weight,
      'resistanceLevel': resistanceLevel,
      'tempo': tempo,
    };
  }

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      exerciseId: map['exerciseId'] ?? '',
      sets: map['sets']?.toInt() ?? 0,
      reps: map['reps']?.toInt() ?? 0,
      durationSeconds: map['durationSeconds']?.toInt(),
      restBetweenSeconds: map['restBetweenSeconds']?.toInt() ?? 0,
      weight: map['weight']?.toDouble(),
      resistanceLevel: map['resistanceLevel']?.toInt(),
      tempo: map['tempo'] != null ? Map<String, dynamic>.from(map['tempo']) : null,
    );
  }
}