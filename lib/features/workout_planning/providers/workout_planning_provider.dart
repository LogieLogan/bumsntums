// lib/features/workout_planning/providers/workout_planning_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../repositories/workout_planning_repository.dart';
import '../models/workout_plan.dart';
import '../models/scheduled_workout.dart';

// Repository provider
final workoutPlanningRepositoryProvider = Provider<WorkoutPlanningRepository>((ref) {
  return WorkoutPlanningRepository();
});

// Provider for the active workout plan
final activeWorkoutPlanProvider = FutureProvider.family<WorkoutPlan?, String>((ref, userId) async {
  final repository = ref.read(workoutPlanningRepositoryProvider);
  return await repository.getActiveWorkoutPlan(userId);
});

// Provider for scheduled workouts by date range
final scheduledWorkoutsProvider = FutureProvider.family<List<ScheduledWorkout>, ({String userId, DateTime start, DateTime end})>((ref, params) async {
  final repository = ref.read(workoutPlanningRepositoryProvider);
  return await repository.getScheduledWorkouts(params.userId, params.start, params.end);
});

// Provider for workout plans
final workoutPlansProvider = FutureProvider.family<List<WorkoutPlan>, String>((ref, userId) async {
  final repository = ref.read(workoutPlanningRepositoryProvider);
  return await repository.getWorkoutPlans(userId);
});

// Notifier for managing the workout planning state
class WorkoutPlanningNotifier extends StateNotifier<AsyncValue<WorkoutPlan?>> {
  final WorkoutPlanningRepository _repository;
  final String _userId;

  WorkoutPlanningNotifier(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    _loadActivePlan();
  }

  Future<void> _loadActivePlan() async {
    try {
      state = const AsyncValue.loading();
      final plan = await _repository.getActiveWorkoutPlan(_userId);
      state = AsyncValue.data(plan);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> createWorkoutPlan(String name, DateTime startDate, DateTime endDate,
      {String? description}) async {
    try {
      state = const AsyncValue.loading();
      final plan = await _repository.createWorkoutPlan(
        _userId, 
        name, 
        startDate, 
        endDate,
        description: description
      );
      state = AsyncValue.data(plan);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> scheduleWorkout(
      String workoutId, DateTime scheduledDate, {TimeOfDay? preferredTime}) async {
    try {
      if (state.value == null) {
        // Create a new plan if none exists
        await createWorkoutPlan(
          'My Workout Plan',
          DateTime.now(),
          DateTime.now().add(const Duration(days: 28)),
        );
      }

      final currentPlan = state.value!;
      final scheduledWorkout = await _repository.scheduleWorkout(
        currentPlan.id,
        workoutId,
        _userId,
        scheduledDate,
        preferredTime: preferredTime,
      );

      // Update local state
      final updatedWorkouts = [...currentPlan.scheduledWorkouts, scheduledWorkout];
      state = AsyncValue.data(currentPlan.copyWith(scheduledWorkouts: updatedWorkouts));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> markWorkoutCompleted(String scheduledWorkoutId) async {
    try {
      if (state.value == null) return;

      final currentPlan = state.value!;
      await _repository.markWorkoutCompleted(currentPlan.id, scheduledWorkoutId);

      // Update local state
      final updatedWorkouts = currentPlan.scheduledWorkouts.map((workout) {
        if (workout.id == scheduledWorkoutId) {
          return workout.copyWith(isCompleted: true, completedAt: DateTime.now());
        }
        return workout;
      }).toList();

      state = AsyncValue.data(currentPlan.copyWith(scheduledWorkouts: updatedWorkouts));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateScheduledWorkout(ScheduledWorkout scheduledWorkout) async {
    try {
      if (state.value == null) return;

      final currentPlan = state.value!;
      await _repository.updateScheduledWorkout(currentPlan.id, scheduledWorkout);

      // Update local state
      final updatedWorkouts = currentPlan.scheduledWorkouts.map((workout) {
        if (workout.id == scheduledWorkout.id) {
          return scheduledWorkout;
        }
        return workout;
      }).toList();

      state = AsyncValue.data(currentPlan.copyWith(scheduledWorkouts: updatedWorkouts));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteScheduledWorkout(String scheduledWorkoutId) async {
    try {
      if (state.value == null) return;

      final currentPlan = state.value!;
      await _repository.deleteScheduledWorkout(currentPlan.id, scheduledWorkoutId);

      // Update local state
      final updatedWorkouts = currentPlan.scheduledWorkouts
          .where((workout) => workout.id != scheduledWorkoutId)
          .toList();

      state = AsyncValue.data(currentPlan.copyWith(scheduledWorkouts: updatedWorkouts));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Get workouts for a specific week
  List<ScheduledWorkout> getWorkoutsForWeek(DateTime weekStart) {
    if (state.value == null) return [];
    return state.value!.getWorkoutsForWeek(weekStart);
  }

  // Get workouts for a specific day
  List<ScheduledWorkout> getWorkoutsForDay(DateTime day) {
    if (state.value == null) return [];
    return state.value!.getWorkoutsForDay(day);
  }
}

// Provider for workout planning notifier
final workoutPlanningNotifierProvider = StateNotifierProvider.family<WorkoutPlanningNotifier, AsyncValue<WorkoutPlan?>, String>((ref, userId) {
  final repository = ref.read(workoutPlanningRepositoryProvider);
  return WorkoutPlanningNotifier(repository, userId);
});

// Helper provider for getting weekly workouts in a grouped format by day
final weeklyWorkoutsProvider = Provider.family<Map<int, List<ScheduledWorkout>>, ({String userId, DateTime weekStart})>((ref, params) {
  final planState = ref.watch(workoutPlanningNotifierProvider(params.userId));
  
  if (planState.value == null) {
    return {};
  }
  
  // Group workouts by weekday (1 = Monday, 7 = Sunday)
  final workouts = planState.value!.getWorkoutsForWeek(params.weekStart);
  return workouts.groupListsBy((workout) => workout.scheduledDate.weekday);
});