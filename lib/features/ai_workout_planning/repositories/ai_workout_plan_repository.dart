// lib/features/ai_workout_planning/repositories/ai_workout_plan_repository.dart
import 'package:bums_n_tums/features/workout_planning/providers/workout_planning_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_workout_plan_model.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../workout_planning/repositories/workout_planning_repository.dart';
import '../../workouts/models/workout.dart';
import 'package:uuid/uuid.dart';

class AiWorkoutPlanRepository {
  final FirebaseFirestore _firestore;
  final WorkoutPlanningRepository _planningRepository;
  final AnalyticsService _analytics;
  final _uuid = const Uuid();

  AiWorkoutPlanRepository({
    FirebaseFirestore? firestore,
    WorkoutPlanningRepository? planningRepository,
    AnalyticsService? analytics,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _planningRepository = planningRepository ?? WorkoutPlanningRepository(),
       _analytics = analytics ?? AnalyticsService();

  // Save an AI workout plan
  Future<String> saveAiWorkoutPlan(AiWorkoutPlan plan) async {
    try {
      final planId = plan.id.isEmpty ? _uuid.v4() : plan.id;
      final planWithId =
          plan.id.isEmpty
              ? AiWorkoutPlan(
                id: planId,
                userId: plan.userId,
                name: plan.name,
                description: plan.description,
                createdAt: plan.createdAt,
                durationDays: plan.durationDays,
                daysPerWeek: plan.daysPerWeek,
                focusAreas: plan.focusAreas,
                variationType: plan.variationType,
                fitnessLevel: plan.fitnessLevel,
                targetAreaDistribution: plan.targetAreaDistribution,
                workouts: plan.workouts,
                specialRequest: plan.specialRequest,
              )
              : plan;

      await _firestore
          .collection('ai_workout_plans')
          .doc(planId)
          .set(planWithId.toMap());

      _analytics.logEvent(
        name: 'ai_workout_plan_saved',
        parameters: {'plan_id': planId},
      );

      return planId;
    } catch (e) {
      _analytics.logError(error: 'Error saving AI workout plan: $e');
      throw Exception('Failed to save AI workout plan: $e');
    }
  }

  // Get all AI workout plans for a user
  Future<List<AiWorkoutPlan>> getAiWorkoutPlans(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('ai_workout_plans')
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => AiWorkoutPlan.fromMap(doc.data()))
          .toList();
    } catch (e) {
      _analytics.logError(error: 'Error getting AI workout plans: $e');
      return [];
    }
  }

  // Get a specific AI workout plan
  Future<AiWorkoutPlan?> getAiWorkoutPlan(String planId) async {
    try {
      final docSnapshot =
          await _firestore.collection('ai_workout_plans').doc(planId).get();

      if (!docSnapshot.exists) {
        return null;
      }

      return AiWorkoutPlan.fromMap(docSnapshot.data()!);
    } catch (e) {
      _analytics.logError(error: 'Error getting AI workout plan: $e');
      return null;
    }
  }

  // Delete an AI workout plan
  Future<void> deleteAiWorkoutPlan(String planId) async {
    try {
      await _firestore.collection('ai_workout_plans').doc(planId).delete();

      _analytics.logEvent(
        name: 'ai_workout_plan_deleted',
        parameters: {'plan_id': planId},
      );
    } catch (e) {
      _analytics.logError(error: 'Error deleting AI workout plan: $e');
      throw Exception('Failed to delete AI workout plan: $e');
    }
  }

  Future<void> startAiWorkoutPlan(
    String planId,
    String userId,
    DateTime startDate,
  ) async {
    try {
      _analytics.logEvent(
        name: 'ai_plan_conversion_started',
        parameters: {'plan_id': planId, 'user_id': userId},
      );

      // Get the AI plan
      final aiPlan = await getAiWorkoutPlan(planId);
      if (aiPlan == null) {
        throw Exception('AI workout plan not found');
      }

      // Create a regular workout plan
      final workoutPlan = await _planningRepository.createWorkoutPlan(
        userId,
        aiPlan.name,
        startDate,
        startDate.add(Duration(days: aiPlan.durationDays - 1)),
        description: aiPlan.description,
      );

      // Log the creation of the workout plan
      _analytics.logEvent(
        name: 'workout_plan_created_from_ai',
        parameters: {
          'ai_plan_id': planId,
          'workout_plan_id': workoutPlan.id,
          'user_id': userId,
        },
      );

      // Schedule each workout in the plan
      final scheduledWorkouts = <String>[];
      final failedWorkouts = <String>[];

      for (final planWorkout in aiPlan.workouts) {
        try {
          // Calculate the actual date for this workout based on day index
          final workoutDate = _calculateWorkoutDate(
            startDate,
            planWorkout.dayIndex,
            aiPlan.daysPerWeek,
          );

          // Schedule the workout
          final scheduledWorkout = await _planningRepository.scheduleWorkout(
            workoutPlan.id,
            planWorkout.workoutId,
            userId,
            workoutDate,
          );

          scheduledWorkouts.add(scheduledWorkout.id);

          _analytics.logEvent(
            name: 'workout_scheduled_from_ai_plan',
            parameters: {
              'workout_id': planWorkout.workoutId,
              'plan_id': workoutPlan.id,
              'scheduled_date': workoutDate.toString(),
            },
          );
        } catch (e) {
          _analytics.logError(
            error: 'Failed to schedule workout: $e',
            parameters: {
              'workout_id': planWorkout.workoutId,
              'plan_id': workoutPlan.id,
            },
          );
          failedWorkouts.add(planWorkout.name);
        }
      }

      // Check if any workouts failed to be scheduled
      if (failedWorkouts.isNotEmpty) {
        _analytics.logEvent(
          name: 'ai_plan_partial_conversion',
          parameters: {
            'plan_id': planId,
            'failed_count': failedWorkouts.length,
            'total_count': aiPlan.workouts.length,
          },
        );
        throw Exception(
          'Some workouts could not be scheduled: ${failedWorkouts.join(", ")}',
        );
      }

      _analytics.logEvent(
        name: 'ai_plan_conversion_completed',
        parameters: {
          'plan_id': planId,
          'workout_plan_id': workoutPlan.id,
          'workouts_count': scheduledWorkouts.length,
        },
      );
    } catch (e) {
      _analytics.logError(
        error: 'Error starting AI workout plan: $e',
        parameters: {'plan_id': planId, 'user_id': userId},
      );
      throw Exception('Failed to start AI workout plan: $e');
    }
  }

  DateTime _calculateWorkoutDate(
    DateTime startDate,
    int dayIndex,
    int daysPerWeek,
  ) {
    final daysInterval = (7 / daysPerWeek).floor();
    final weekNumber = (dayIndex / daysPerWeek).floor();
    final dayInWeek = dayIndex % daysPerWeek;

    return startDate.add(
      Duration(days: (weekNumber * 7) + (dayInWeek * daysInterval)),
    );
  }

  // Create an AI workout plan from the plan data generated by OpenAI
  Future<String> createAiWorkoutPlanFromData({
    required String userId,
    required Map<String, dynamic> planData,
    required int durationDays,
    required int daysPerWeek,
    required List<String> focusAreas,
    required String variationType,
    required String fitnessLevel,
    String? specialRequest,
  }) async {
    try {
      // Extract plan details from the data
      final name = planData['name'] as String? ?? 'AI Workout Plan';
      final description =
          planData['description'] as String? ??
          'Personalized workout plan created by AI';

      // Extract workouts
      final workoutsData = planData['workouts'] as List<dynamic>? ?? [];
      final workouts =
          workoutsData.asMap().entries.map((entry) {
            final index = entry.key;
            final workout = entry.value as Map<String, dynamic>;

            return PlanWorkout(
              id: _uuid.v4(),
              workoutId: workout['workoutId'] as String? ?? '',
              name: workout['name'] as String? ?? 'Workout ${index + 1}',
              description: workout['description'] as String?,
              category: _categoryFromString(
                workout['category'] as String? ?? 'fullBody',
              ),
              difficulty: _difficultyFromString(
                workout['difficulty'] as String? ?? fitnessLevel,
              ),
              dayIndex: index,
            );
          }).toList();

      // Extract target area distribution if available
      Map<String, double>? targetAreaDistribution;
      if (planData['targetAreaDistribution'] != null) {
        targetAreaDistribution = Map<String, double>.from(
          (planData['targetAreaDistribution'] as Map).map(
            (key, value) => MapEntry(
              key.toString(),
              (value is double) ? value : (value as num).toDouble(),
            ),
          ),
        );
      }

      // Create the AI plan
      final plan = AiWorkoutPlan(
        id: _uuid.v4(),
        userId: userId,
        name: name,
        description: description,
        createdAt: DateTime.now(),
        durationDays: durationDays,
        daysPerWeek: daysPerWeek,
        focusAreas: focusAreas,
        variationType: variationType,
        fitnessLevel: fitnessLevel,
        targetAreaDistribution: targetAreaDistribution,
        workouts: workouts,
        specialRequest: specialRequest,
      );

      // Save the plan
      return await saveAiWorkoutPlan(plan);
    } catch (e) {
      _analytics.logError(
        error: 'Error creating AI workout plan from data: $e',
      );
      throw Exception('Failed to create AI workout plan: $e');
    }
  }

  // Helper methods for category and difficulty conversion
  static WorkoutCategory _categoryFromString(String value) {
    return WorkoutCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WorkoutCategory.fullBody,
    );
  }

  static WorkoutDifficulty _difficultyFromString(String value) {
    return WorkoutDifficulty.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WorkoutDifficulty.beginner,
    );
  }
}

// Provider for the AI Workout Plan Repository
final aiWorkoutPlanRepositoryProvider = Provider<AiWorkoutPlanRepository>((
  ref,
) {
  final planningRepository = ref.read(workoutPlanningRepositoryProvider);
  return AiWorkoutPlanRepository(planningRepository: planningRepository);
});
