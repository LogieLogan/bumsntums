// lib/features/workout_planning/models/workout_plan.dart
import 'scheduled_workout.dart';

class WorkoutPlan {
  final String id;
  final String userId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final List<ScheduledWorkout> scheduledWorkouts;
  final Map<String, double>? targetAreaDistribution;
  final String? aiSuggestionRationale;

  // Additional metadata
  final String? description;
  final Map<String, dynamic>? metadata;

  WorkoutPlan({
    required this.id,
    required this.userId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.scheduledWorkouts = const [],
    this.description,
    this.metadata,
    this.targetAreaDistribution,
    this.aiSuggestionRationale,
  });

  factory WorkoutPlan.fromMap(
    Map<String, dynamic> map,
    List<ScheduledWorkout> workouts,
  ) {
    Map<String, double>? targetDistribution;
    if (map['targetAreaDistribution'] != null) {
      targetDistribution = Map<String, double>.from(
        (map['targetAreaDistribution'] as Map).map(
          (key, value) => MapEntry(key as String, value as double),
        ),
      );
    }

    return WorkoutPlan(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? 'My Workout Plan',
      startDate:
          map['startDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['startDate'])
              : DateTime.now(),
      endDate:
          map['endDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['endDate'])
              : DateTime.now().add(const Duration(days: 28)),
      isActive: map['isActive'] ?? true,
      scheduledWorkouts: workouts,
      description: map['description'],
      metadata: map['metadata'],
      targetAreaDistribution: targetDistribution,
      aiSuggestionRationale: map['aiSuggestionRationale'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'isActive': isActive,
      'description': description,
      'metadata': metadata,
      'targetAreaDistribution': targetAreaDistribution,
      'aiSuggestionRationale': aiSuggestionRationale,
    };
  }

  WorkoutPlan copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    List<ScheduledWorkout>? scheduledWorkouts,
    String? description,
    Map<String, dynamic>? metadata,
    Map<String, double>? targetAreaDistribution,
    String? aiSuggestionRationale,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      scheduledWorkouts: scheduledWorkouts ?? this.scheduledWorkouts,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      targetAreaDistribution:
          targetAreaDistribution ?? this.targetAreaDistribution,
      aiSuggestionRationale:
          aiSuggestionRationale ?? this.aiSuggestionRationale,
    );
  }

  // Helper to get workouts for a specific week
  List<ScheduledWorkout> getWorkoutsForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return scheduledWorkouts.where((workout) {
      return workout.scheduledDate.isAfter(
            weekStart.subtract(const Duration(days: 1)),
          ) &&
          workout.scheduledDate.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();
  }

  // Helper to get workouts for a specific day
  List<ScheduledWorkout> getWorkoutsForDay(DateTime day) {
    return scheduledWorkouts.where((workout) {
      return workout.scheduledDate.year == day.year &&
          workout.scheduledDate.month == day.month &&
          workout.scheduledDate.day == day.day;
    }).toList();
  }
}
