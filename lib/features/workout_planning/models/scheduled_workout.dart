// lib/features/workout_planning/models/scheduled_workout.dart
import 'package:flutter/material.dart';
import '../../../features/workouts/models/workout.dart';

class ScheduledWorkout {
  final String id;
  final String workoutId;
  final String userId;
  final DateTime scheduledDate;
  final TimeOfDay? preferredTime;
  final bool isCompleted;
  final DateTime? completedAt;
  final String planId;
  
  // For UI representation
  final Workout? workout; // The actual workout data

  ScheduledWorkout({
    required this.id,
    required this.workoutId,
    required this.userId,
    required this.scheduledDate,
    this.preferredTime,
    this.isCompleted = false,
    this.completedAt,
    this.workout,
    required this.planId,
  });

  factory ScheduledWorkout.fromMap(Map<String, dynamic> map, {Workout? workout}) {
    return ScheduledWorkout(
      id: map['id'] ?? '',
      workoutId: map['workoutId'] ?? '',
      userId: map['userId'] ?? '',
      planId: map['planId'] ?? '',
      scheduledDate: map['scheduledDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['scheduledDate']) 
          : DateTime.now(),
      preferredTime: map['preferredTimeHour'] != null && map['preferredTimeMinute'] != null
          ? TimeOfDay(hour: map['preferredTimeHour'], minute: map['preferredTimeMinute'])
          : null,
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt']) 
          : null,
      workout: workout,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutId': workoutId,
      'userId': userId,
      'planId': planId,
      'scheduledDate': scheduledDate.millisecondsSinceEpoch,
      'preferredTimeHour': preferredTime?.hour,
      'preferredTimeMinute': preferredTime?.minute,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  ScheduledWorkout copyWith({
    String? id,
    String? workoutId,
    String? userId,
    String? planId,
    DateTime? scheduledDate,
    TimeOfDay? preferredTime,
    bool? isCompleted,
    DateTime? completedAt,
    Workout? workout,
    bool clearCompletedAt = false,
  }) {
    return ScheduledWorkout(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      preferredTime: preferredTime ?? this.preferredTime,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      workout: workout ?? this.workout,
    );
  }
}