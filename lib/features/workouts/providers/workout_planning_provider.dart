// lib/features/workouts/providers/workout_planning_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_plan.dart';
import '../services/workout_planning_service.dart';
import '../../../shared/providers/analytics_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Provider for the workout planning service
final workoutPlanningServiceProvider = Provider<WorkoutPlanningService>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return WorkoutPlanningService(analytics);
});

// Provider for user's workout plans
final userWorkoutPlansProvider =
    FutureProvider.family<List<WorkoutPlan>, String>((ref, userId) async {
      final planningService = ref.watch(workoutPlanningServiceProvider);
      return await planningService.getUserWorkoutPlans(userId);
    });

// Provider for specific workout plan
final workoutPlanProvider =
    FutureProvider.family<WorkoutPlan?, ({String userId, String planId})>((
      ref,
      params,
    ) async {
      final planningService = ref.watch(workoutPlanningServiceProvider);
      return await planningService.getWorkoutPlan(params.userId, params.planId);
    });

// Notifier for workout plan actions (creating, updating, deleting)
class WorkoutPlanActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WorkoutPlanningService _planningService;

  WorkoutPlanActionsNotifier(this._planningService)
    : super(const AsyncValue.data(null));

  // In the WorkoutPlanActionsNotifier class:

  Future<String?> createWorkoutPlan(WorkoutPlan plan) async {
    try {
      // Save plan to Firestore
      await _firestore
          .collection('workout_plans')
          .doc(plan.userId)
          .collection('plans')
          .doc(plan.id)
          .set(plan.toMap());

      // Mark this plan as active and deactivate others if needed
      if (plan.isActive) {
        await _deactivateOtherPlans(plan.userId, plan.id);
      }

      return plan.id;
    } catch (e) {
      print('Error creating workout plan: $e');
      return null;
    }
  }

  Future<bool> addWorkoutToPlan(
    String userId,
    String planId,
    ScheduledWorkout workout,
  ) async {
    try {
      state = const AsyncValue.loading();

      // Get the current plan
      final docSnapshot =
          await _firestore
              .collection('workout_plans')
              .doc(userId)
              .collection('plans')
              .doc(planId)
              .get();

      if (!docSnapshot.exists) {
        state = const AsyncValue.data(null);
        return false;
      }

      // Parse the plan
      final plan = WorkoutPlan.fromMap({
        'id': docSnapshot.id,
        ...docSnapshot.data()!,
      });

      // Add the workout to the plan
      final updatedScheduledWorkouts = [...plan.scheduledWorkouts, workout];

      // Update the plan
      await _firestore
          .collection('workout_plans')
          .doc(userId)
          .collection('plans')
          .doc(planId)
          .update({
            'scheduledWorkouts':
                updatedScheduledWorkouts.map((w) => w.toMap()).toList(),
            'updatedAt': Timestamp.now(),
          });

      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      print('Error adding workout to plan: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> updateWorkoutPlan(WorkoutPlan plan) async {
    try {
      // Update plan in Firestore
      await _firestore
          .collection('workout_plans')
          .doc(plan.userId)
          .collection('plans')
          .doc(plan.id)
          .update(plan.toMap());

      // Mark this plan as active and deactivate others if needed
      if (plan.isActive) {
        await _deactivateOtherPlans(plan.userId, plan.id);
      }

      return true;
    } catch (e) {
      print('Error updating workout plan: $e');
      return false;
    }
  }

  Future<bool> deleteWorkoutPlan(String userId, String planId) async {
    try {
      await _firestore
          .collection('workout_plans')
          .doc(userId)
          .collection('plans')
          .doc(planId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting workout plan: $e');
      return false;
    }
  }

  Future<bool> savePlan(WorkoutPlan plan) async {
    try {
      state = const AsyncValue.loading();

      // Save the plan to Firestore
      await _firestore
          .collection('workout_plans')
          .doc(plan.userId)
          .collection('plans')
          .doc(plan.id)
          .set(plan.toMap());

      // If this plan is marked as active, deactivate other plans
      if (plan.isActive) {
        await _deactivateOtherPlans(plan.userId, plan.id);
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      print('Error saving workout plan: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<void> _deactivateOtherPlans(
    String userId,
    String currentPlanId,
  ) async {
    final snapshot =
        await _firestore
            .collection('workout_plans')
            .doc(userId)
            .collection('plans')
            .where('isActive', isEqualTo: true)
            .where(FieldPath.documentId, isNotEqualTo: currentPlanId)
            .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isActive': false});
    }
    await batch.commit();
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
final workoutPlanActionsProvider =
    StateNotifierProvider<WorkoutPlanActionsNotifier, AsyncValue<void>>((ref) {
      final planningService = ref.watch(workoutPlanningServiceProvider);
      return WorkoutPlanActionsNotifier(planningService);
    });
