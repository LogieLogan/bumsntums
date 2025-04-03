// lib/features/ai_workout_planning/models/ai_workout_plan_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../workouts/models/workout.dart';

class AiWorkoutPlan {
  final String id;
  final String userId;
  final String name;
  final String description;
  final DateTime createdAt;
  final int durationDays;
  final int daysPerWeek;
  final List<String> focusAreas;
  final String variationType;
  final String fitnessLevel;
  final Map<String, double>? targetAreaDistribution;
  final List<PlanWorkout> workouts;
  final String? specialRequest;

  const AiWorkoutPlan({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.durationDays,
    required this.daysPerWeek, 
    required this.focusAreas,
    required this.variationType,
    required this.fitnessLevel,
    this.targetAreaDistribution,
    required this.workouts,
    this.specialRequest,
  });

  factory AiWorkoutPlan.fromMap(Map<String, dynamic> map) {
    return AiWorkoutPlan(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      durationDays: map['durationDays'] as int,
      daysPerWeek: map['daysPerWeek'] as int,
      focusAreas: List<String>.from(map['focusAreas'] ?? []),
      variationType: map['variationType'] as String,
      fitnessLevel: map['fitnessLevel'] as String,
      targetAreaDistribution: map['targetAreaDistribution'] != null 
          ? Map<String, double>.from(map['targetAreaDistribution'])
          : null,
      workouts: (map['workouts'] as List?)
          ?.map((w) => PlanWorkout.fromMap(w as Map<String, dynamic>))
          .toList() ?? [],
      specialRequest: map['specialRequest'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'durationDays': durationDays,
      'daysPerWeek': daysPerWeek,
      'focusAreas': focusAreas,
      'variationType': variationType,
      'fitnessLevel': fitnessLevel,
      'targetAreaDistribution': targetAreaDistribution,
      'workouts': workouts.map((w) => w.toMap()).toList(),
      'specialRequest': specialRequest,
    };
  }
}

class PlanWorkout {
  final String id;
  final String workoutId;
  final String name;
  final String? description;
  final WorkoutCategory category;
  final WorkoutDifficulty difficulty;
  final int dayIndex; // Which day of the plan this workout is for
  
  const PlanWorkout({
    required this.id,
    required this.workoutId,
    required this.name,
    this.description,
    required this.category,
    required this.difficulty,
    required this.dayIndex,
  });
  
  factory PlanWorkout.fromMap(Map<String, dynamic> map) {
    return PlanWorkout(
      id: map['id'] as String,
      workoutId: map['workoutId'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      category: _categoryFromString(map['category'] as String),
      difficulty: _difficultyFromString(map['difficulty'] as String),
      dayIndex: map['dayIndex'] as int,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutId': workoutId,
      'name': name,
      'description': description,
      'category': category.name,
      'difficulty': difficulty.name,
      'dayIndex': dayIndex,
    };
  }
  
  static WorkoutCategory _categoryFromString(String value) {
    return WorkoutCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WorkoutCategory.fullBody,
    );
  }
  
  static WorkoutDifficulty _difficultyFromString(String value) {
    return WorkoutDifficulty.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WorkoutDifficulty.beginner,
    );
  }
}