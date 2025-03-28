// lib/features/workouts/providers/workout_calendar_provider.dart
export 'calendar_events_provider.dart';
export 'calendar_state_provider.dart';
export 'workout_actions_provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_plan.dart';
import '../services/workout_planning_service.dart';
import '../services/workout_stats_service.dart';
import '../../../shared/providers/analytics_provider.dart';

// Provider for workout planning service
final workoutPlanningServiceProvider = Provider<WorkoutPlanningService>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return WorkoutPlanningService(analytics);
});

// Provider for workout stats service
final workoutStatsServiceProvider = Provider<WorkoutStatsService>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return WorkoutStatsService(analytics);
});

// Provider for active workout plan
final activeWorkoutPlanProvider = FutureProvider.family<WorkoutPlan?, String>((
  ref,
  userId,
) async {
  final firestore = FirebaseFirestore.instance;

  try {
    print("Fetching active workout plan for user: $userId");

    final userPlansRef = firestore
        .collection('workout_plans')
        .doc(userId)
        .collection('plans');

    final planQuerySnapshot =
        await userPlansRef.where('isActive', isEqualTo: true).limit(1).get();

    print("Found ${planQuerySnapshot.docs.length} active plans");

    if (planQuerySnapshot.docs.isEmpty) {
      print("No active workout plan found for user: $userId");
      return null;
    }

    final planDoc = planQuerySnapshot.docs.first;
    print("Active plan ID: ${planDoc.id}");

    final planData = planDoc.data();
    print("Plan data: ${planData.keys.toList()}");
    print(
      "Scheduled workouts count: ${planData['scheduledWorkouts']?.length ?? 'null'}",
    );

    // Parse the workout plan
    final plan = WorkoutPlan.fromMap({'id': planDoc.id, ...planData});

    print(
      "Successfully parsed workout plan with ${plan.scheduledWorkouts.length} scheduled workouts",
    );
    return plan;
  } catch (e, stackTrace) {
    print('Error fetching active workout plan: $e');
    print('Stack trace: $stackTrace');
    return null;
  }
});

// Workout balance analysis provider
final workoutBalanceProvider = 
    FutureProvider.family<Map<String, double>, String>((ref, userId) async {
  final activePlanAsync = await ref.watch(
    activeWorkoutPlanProvider(userId).future,
  );

  if (activePlanAsync == null) return {};

  final total = activePlanAsync.scheduledWorkouts.length;
  if (total == 0) return {};

  final Map<String, double> balance = {};

  activePlanAsync.bodyFocusDistribution.forEach((key, value) {
    balance[key] = value / total;
  });

  return balance;
});


