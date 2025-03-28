// lib/features/workouts/models/workout_plan.dart
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'plan_color.dart';

class WorkoutPlan extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String goal;
  final List<ScheduledWorkout> scheduledWorkouts;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? colorName;
  final Map<String, int> bodyFocusDistribution;
  final double completionRate;

  const WorkoutPlan({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    required this.goal,
    required this.scheduledWorkouts,
    required this.createdAt,
    required this.updatedAt,
    this.colorName,
    this.bodyFocusDistribution = const {},
    this.completionRate = 0.0,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    description,
    startDate,
    endDate,
    isActive,
    goal,
    scheduledWorkouts,
    createdAt,
    updatedAt,
  ];

  WorkoutPlan copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? goal,
    List<ScheduledWorkout>? scheduledWorkouts,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? colorName,
    Map<String, int>? bodyFocusDistribution,
    double? completionRate,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      goal: goal ?? this.goal,
      scheduledWorkouts: scheduledWorkouts ?? this.scheduledWorkouts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      colorName: colorName ?? this.colorName,
      bodyFocusDistribution:
          bodyFocusDistribution ?? this.bodyFocusDistribution,
      completionRate: completionRate ?? this.completionRate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'goal': goal,
      'scheduledWorkouts': scheduledWorkouts.map((w) => w.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'colorName': colorName,
    };
  }

  factory WorkoutPlan.fromMap(Map<String, dynamic> map) {
    return WorkoutPlan(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate:
          map['endDate'] != null
              ? (map['endDate'] as Timestamp).toDate()
              : null,
      isActive: map['isActive'] ?? true,
      goal: map['goal'] ?? '',
      scheduledWorkouts:
          map['scheduledWorkouts'] != null
              ? List<ScheduledWorkout>.from(
                map['scheduledWorkouts']?.map(
                  (x) => ScheduledWorkout.fromMap(x),
                ),
              )
              : [],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      colorName: map['colorName'],
    );
  }

  List<ScheduledWorkout> getWorkoutsForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return scheduledWorkouts
        .where(
          (w) =>
              w.scheduledDate.year == normalizedDate.year &&
              w.scheduledDate.month == normalizedDate.month &&
              w.scheduledDate.day == normalizedDate.day,
        )
        .toList();
  }

  // Calculate weekly distribution
  Map<int, int> get weeklyDistribution {
    Map<int, int> distribution = {};
    for (final workout in scheduledWorkouts) {
      final weekday = workout.scheduledDate.weekday;
      distribution[weekday] = (distribution[weekday] ?? 0) + 1;
    }
    return distribution;
  }

  // Calculate completion metrics
  int get completedWorkoutsCount =>
      scheduledWorkouts.where((w) => w.isCompleted).length;

  double calculateCompletionRate() {
    if (scheduledWorkouts.isEmpty) return 0.0;
    return completedWorkoutsCount / scheduledWorkouts.length;
  }
}

class ScheduledWorkout extends Equatable {
  final String workoutId;
  final String title;
  final String? workoutImageUrl;
  final DateTime scheduledDate;
  final bool isCompleted;
  final DateTime? completedAt;
  final bool isRecurring;
  final String? recurrencePattern;
  final DateTime? reminderTime;
  final bool reminderEnabled;
  final String? workoutCategory;
  final String? workoutDifficulty;
  final int? durationMinutes;
  final int intensity;
  final List<String> targetAreas;
  final DateTime? lastCompletedDate;
  final bool needsRecovery;

  const ScheduledWorkout({
    required this.workoutId,
    required this.title,
    this.workoutImageUrl,
    required this.scheduledDate,
    this.isCompleted = false,
    this.completedAt,
    this.isRecurring = false,
    this.recurrencePattern,
    this.reminderTime,
    this.reminderEnabled = false,
    this.workoutCategory,
    this.workoutDifficulty,
    this.durationMinutes,
    this.intensity = 3, // Default medium intensity (1-5 scale)
    this.targetAreas = const [],
    this.lastCompletedDate,
    this.needsRecovery = false,
  });

  @override
  List<Object?> get props => [
    workoutId,
    title,
    workoutImageUrl,
    scheduledDate,
    isCompleted,
    completedAt,
    isRecurring,
    recurrencePattern,
    reminderTime,
    reminderEnabled,
  ];

  ScheduledWorkout copyWith({
    String? workoutId,
    String? title,
    String? workoutImageUrl,
    DateTime? scheduledDate,
    bool? isCompleted,
    DateTime? completedAt,
    bool? isRecurring,
    String? recurrencePattern,
    DateTime? reminderTime,
    bool? reminderEnabled,
    String? workoutCategory,
    String? workoutDifficulty,
    int? durationMinutes,
    int? intensity,
    List<String>? targetAreas,
    DateTime? lastCompletedDate,
    bool? needsRecovery,
  }) {
    return ScheduledWorkout(
      workoutId: workoutId ?? this.workoutId,
      title: title ?? this.title,
      workoutImageUrl: workoutImageUrl ?? this.workoutImageUrl,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      workoutCategory: workoutCategory ?? this.workoutCategory,
      workoutDifficulty: workoutDifficulty ?? this.workoutDifficulty,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      intensity: intensity ?? this.intensity,
      targetAreas: targetAreas ?? this.targetAreas,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      needsRecovery: needsRecovery ?? this.needsRecovery,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workoutId': workoutId,
      'title': title,
      'workoutImageUrl': workoutImageUrl,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'isCompleted': isCompleted,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern,
      'reminderTime':
          reminderTime != null ? Timestamp.fromDate(reminderTime!) : null,
      'reminderEnabled': reminderEnabled,
    };
  }

  factory ScheduledWorkout.fromMap(Map<String, dynamic> map) {
    return ScheduledWorkout(
      workoutId: map['workoutId'] ?? '',
      title: map['title'] ?? '',
      workoutImageUrl: map['workoutImageUrl'],
      scheduledDate: (map['scheduledDate'] as Timestamp).toDate(),
      isCompleted: map['isCompleted'] ?? false,
      completedAt:
          map['completedAt'] != null
              ? (map['completedAt'] as Timestamp).toDate()
              : null,
      isRecurring: map['isRecurring'] ?? false,
      recurrencePattern: map['recurrencePattern'],
      reminderTime:
          map['reminderTime'] != null
              ? (map['reminderTime'] as Timestamp).toDate()
              : null,
      reminderEnabled: map['reminderEnabled'] ?? false,
    );
  }
}

extension WorkoutPlanColorExtension on WorkoutPlan {
  Color get color {
    if (colorName != null) {
      final customColor = PlanColor.getColorByName(colorName!);
      if (customColor != null) {
        return customColor;
      }
    }

    // If no color name or invalid, generate one from the plan name
    return PlanColor.generateFromName(name).color;
  }
}
