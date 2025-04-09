// Define this conceptually, maybe in a new models file like 'planner_item.dart'
// or directly within the provider file for now.

import 'package:bums_n_tums/features/workout_planning/models/scheduled_workout.dart';
import 'package:bums_n_tums/features/workouts/models/workout_log.dart';
import 'package:equatable/equatable.dart';

abstract class PlannerItem extends Equatable {
  DateTime get itemDate; // Common property for sorting/grouping
}

class PlannedWorkoutItem extends PlannerItem {
  final ScheduledWorkout scheduledWorkout;

  PlannedWorkoutItem(this.scheduledWorkout);

  @override
  DateTime get itemDate => scheduledWorkout.scheduledDate;

  @override
  List<Object?> get props => [scheduledWorkout];
}

class LoggedWorkoutItem extends PlannerItem {
  final WorkoutLog workoutLog;

  LoggedWorkoutItem(this.workoutLog);

  @override
  DateTime get itemDate => workoutLog.completedAt; // Use completedAt for logged items

  @override
  List<Object?> get props => [workoutLog];
}