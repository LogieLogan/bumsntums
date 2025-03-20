// lib/features/workouts/providers/workout_planning_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_plan.dart';
import '../services/workout_planning_service.dart';
import '../../../shared/providers/analytics_provider.dart';
import '../../../shared/models/app_user.dart';

// Provider for the workout planning service
final workoutPlanningServiceProvider = Provider<WorkoutPlanningService>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return WorkoutPlanningService(analytics);
});

// Provider for user's workout plans
final userWorkoutPlansProvider = FutureProvider.family<List<WorkoutPlan>, String>((ref, userId) async {
  final planningService = ref.watch(workoutPlanningServiceProvider);
  return await planningService.getUserWorkoutPlans(userId);
});

// Provider for active workout plan
final activeWorkoutPlanProvider = FutureProvider.family<WorkoutPlan?, String>((ref, userId) async {
  final planningService = ref.watch(workoutPlanningServiceProvider);
  return await planningService.getActiveWorkoutPlan(userId);
});

// Provider for specific workout plan
final workoutPlanProvider = FutureProvider.family<WorkoutPlan?, ({String userId, String planId})>((ref, params) async {
  final planningService = ref.watch(workoutPlanningServiceProvider);
  return await planningService.getWorkoutPlan(params.userId, params.planId);
});

// Notifier for workout plan actions (creating, updating, deleting)
class WorkoutPlanActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final WorkoutPlanningService _planningService;
  
  WorkoutPlanActionsNotifier(this._planningService) : super(const AsyncValue.data(null));
  
  Future<String?> createWorkoutPlan(WorkoutPlan plan) async {
    state = const AsyncValue.loading();
    try {
      final planId = await _planningService.createWorkoutPlan(plan);
      state = const AsyncValue.data(null);
      return planId;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }
  
  Future<bool> updateWorkoutPlan(WorkoutPlan plan) async {
    state = const AsyncValue.loading();
    try {
      await _planningService.updateWorkoutPlan(plan);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }
  
  Future<bool> deleteWorkoutPlan(String userId, String planId) async {
    state = const AsyncValue.loading();
    try {
      await _planningService.deleteWorkoutPlan(userId, planId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }
  
  Future<bool> markWorkoutCompleted(
    String userId,
    String planId,
    String workoutId,
    DateTime completedAt,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _planningService.markWorkoutCompleted(
        userId,
        planId,
        workoutId,
        completedAt,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }
  
  Future<WorkoutPlan?> generateRecommendedPlan(
    String userId,
    List<String> focusAreas,
    int weeklyWorkoutDays,
    String fitnessLevel,
  ) async {
    state = const AsyncValue.loading();
    try {
      final plan = await _planningService.generateRecommendedPlan(
        userId,
        focusAreas,
        weeklyWorkoutDays,
        fitnessLevel,
      );
      state = const AsyncValue.data(null);
      return plan;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }
}

// Provider for workout plan actions
final workoutPlanActionsProvider = StateNotifierProvider<WorkoutPlanActionsNotifier, AsyncValue<void>>((ref) {
  final planningService = ref.watch(workoutPlanningServiceProvider);
  return WorkoutPlanActionsNotifier(planningService);
});