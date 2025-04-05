// lib/features/workout_planning/repositories/workout_planning_repository.dart
import 'package:bums_n_tums/shared/analytics/firebase_analytics_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/scheduled_workout.dart';
import '../models/workout_plan.dart';
import '../../../features/workouts/models/workout.dart';
import '../../../features/workouts/services/workout_service.dart';

class WorkoutPlanningRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WorkoutService _workoutService;
  final _uuid = const Uuid();

  WorkoutPlanningRepository({WorkoutService? workoutService})
    : _workoutService = workoutService ?? WorkoutService(AnalyticsService());

  Future<WorkoutPlan?> getActiveWorkoutPlan(String userId) async {
    try {
      final planSnapshot =
          await _firestore
              .collection('workout_plans')
              .where('userId', isEqualTo: userId)
              .where('isActive', isEqualTo: true)
              .orderBy('startDate', descending: true)
              .limit(1)
              .get();

      if (planSnapshot.docs.isEmpty) {
        return null;
      }

      final planDoc = planSnapshot.docs.first;
      final planData = planDoc.data();

      // Get scheduled workouts for this plan
      final scheduledWorkoutsSnapshot =
          await _firestore
              .collection('workout_plans')
              .doc(planDoc.id)
              .collection('scheduled_workouts')
              .get();

      final scheduledWorkouts = await Future.wait(
        scheduledWorkoutsSnapshot.docs.map((doc) async {
          final data = doc.data();
          final workoutId = data['workoutId'];

          // Fetch only basic workout info (no exercises)
          Workout? workout;
          try {
            // Get lightweight workout data from "workouts" collection
            final workoutDoc =
                await _firestore.collection('workouts').doc(workoutId).get();
            if (workoutDoc.exists) {
              final workoutData = workoutDoc.data()!;
              // Create a lightweight workout object
              workout = _createLightweightWorkout(workoutId, workoutData);
            }
          } catch (e) {
            print('Error fetching workout basic info: $e');
          }

          return ScheduledWorkout.fromMap({
            ...data,
            'id': doc.id,
          }, workout: workout);
        }).toList(),
      );

      return WorkoutPlan.fromMap({
        ...planData,
        'id': planDoc.id,
      }, scheduledWorkouts);
    } catch (e) {
      print('Error fetching active workout plan: $e');
      return null;
    }
  }

  // Create a new workout plan
  Future<WorkoutPlan> createWorkoutPlan(
    String userId,
    String name,
    DateTime startDate,
    DateTime endDate, {
    String? description,
  }) async {
    final planId = _uuid.v4();
    final planData = {
      'userId': userId,
      'name': name,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'isActive': true,
      'description': description,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };

    await _firestore.collection('workout_plans').doc(planId).set(planData);

    return WorkoutPlan.fromMap({...planData, 'id': planId}, []);
  }

  // Schedule a workout
  Future<ScheduledWorkout> scheduleWorkout(
    String planId,
    String workoutId,
    String userId,
    DateTime scheduledDate, {
    TimeOfDay? preferredTime,
  }) async {
    final scheduledWorkoutId = _uuid.v4();
    final scheduledWorkoutData = {
      'workoutId': workoutId,
      'userId': userId,
      'scheduledDate': scheduledDate.millisecondsSinceEpoch,
      'preferredTimeHour': preferredTime?.hour,
      'preferredTimeMinute': preferredTime?.minute,
      'isCompleted': false,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };

    await _firestore
        .collection('workout_plans')
        .doc(planId)
        .collection('scheduled_workouts')
        .doc(scheduledWorkoutId)
        .set(scheduledWorkoutData);

    // Get the workout details
    Workout? workout;
    try {
      workout = await _workoutService.getWorkoutById(workoutId);
    } catch (e) {
      print('Error fetching workout: $e');
    }

    return ScheduledWorkout.fromMap({
      ...scheduledWorkoutData,
      'id': scheduledWorkoutId,
    }, workout: workout);
  }

  // Mark workout as completed
  Future<void> markWorkoutCompleted(
    String planId,
    String scheduledWorkoutId, {
    DateTime? completedAt,
  }) async {
    await _firestore
        .collection('workout_plans')
        .doc(planId)
        .collection('scheduled_workouts')
        .doc(scheduledWorkoutId)
        .update({
          'isCompleted': true,
          'completedAt': (completedAt ?? DateTime.now()).millisecondsSinceEpoch,
        });
  }

  // Update a scheduled workout
  Future<void> updateScheduledWorkout(
    String planId,
    ScheduledWorkout scheduledWorkout,
  ) async {
    await _firestore
        .collection('workout_plans')
        .doc(planId)
        .collection('scheduled_workouts')
        .doc(scheduledWorkout.id)
        .update(scheduledWorkout.toMap());
  }

  // Delete a scheduled workout
  Future<void> deleteScheduledWorkout(
    String planId,
    String scheduledWorkoutId,
  ) async {
    await _firestore
        .collection('workout_plans')
        .doc(planId)
        .collection('scheduled_workouts')
        .doc(scheduledWorkoutId)
        .delete();
  }

  // Get all workout plans for a user
  Future<List<WorkoutPlan>> getWorkoutPlans(String userId) async {
    try {
      final plansSnapshot =
          await _firestore
              .collection('workout_plans')
              .where('userId', isEqualTo: userId)
              .orderBy('startDate', descending: true)
              .get();

      if (plansSnapshot.docs.isEmpty) {
        return [];
      }

      final plans = await Future.wait(
        plansSnapshot.docs.map((doc) async {
          final planData = doc.data();

          // Get scheduled workouts for this plan
          final scheduledWorkoutsSnapshot =
              await _firestore
                  .collection('workout_plans')
                  .doc(doc.id)
                  .collection('scheduled_workouts')
                  .get();

          final scheduledWorkouts = await Future.wait(
            scheduledWorkoutsSnapshot.docs.map((workoutDoc) async {
              final data = workoutDoc.data();
              final workoutId = data['workoutId'];

              // Fetch the workout details
              Workout? workout;
              try {
                workout = await _workoutService.getWorkoutById(workoutId);
              } catch (e) {
                print('Error fetching workout: $e');
              }

              return ScheduledWorkout.fromMap({
                ...data,
                'id': workoutDoc.id,
              }, workout: workout);
            }).toList(),
          );

          return WorkoutPlan.fromMap({
            ...planData,
            'id': doc.id,
          }, scheduledWorkouts);
        }).toList(),
      );

      return plans;
    } catch (e) {
      print('Error fetching workout plans: $e');
      return [];
    }
  }

  Future<List<ScheduledWorkout>> getScheduledWorkouts(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      // Get all active plans for the user
      final plansSnapshot =
          await _firestore
              .collection('workout_plans')
              .where('userId', isEqualTo: userId)
              .where('isActive', isEqualTo: true)
              .get();

      if (plansSnapshot.docs.isEmpty) {
        return [];
      }

      final allScheduledWorkouts = <ScheduledWorkout>[];

      // For each plan, get scheduled workouts in the date range
      for (final planDoc in plansSnapshot.docs) {
        final scheduledWorkoutsSnapshot =
            await _firestore
                .collection('workout_plans')
                .doc(planDoc.id)
                .collection('scheduled_workouts')
                .where(
                  'scheduledDate',
                  isGreaterThanOrEqualTo: start.millisecondsSinceEpoch,
                )
                .where(
                  'scheduledDate',
                  isLessThanOrEqualTo: end.millisecondsSinceEpoch,
                )
                .get();

        final workouts = await Future.wait(
          scheduledWorkoutsSnapshot.docs.map((doc) async {
            final data = doc.data();
            final workoutId = data['workoutId'];

            // Fetch only basic workout info
            Workout? workout;
            try {
              final workoutDoc =
                  await _firestore.collection('workouts').doc(workoutId).get();
              if (workoutDoc.exists) {
                final workoutData = workoutDoc.data()!;
                workout = _createLightweightWorkout(workoutId, workoutData);
              }
            } catch (e) {
              print('Error fetching workout basic info: $e');
            }

            return ScheduledWorkout.fromMap({
              ...data,
              'id': doc.id,
            }, workout: workout);
          }).toList(),
        );

        allScheduledWorkouts.addAll(workouts);
      }

      return allScheduledWorkouts;
    } catch (e) {
      print('Error fetching scheduled workouts: $e');
      return [];
    }
  }
}

Workout _createLightweightWorkout(String workoutId, Map<String, dynamic> data) {
  return Workout(
    id: workoutId,
    title: data['title'] ?? 'Unknown Workout',
    description: data['description'] ?? '',
    imageUrl: data['imageUrl'] ?? '',
    category: _parseCategory(data['category']),
    difficulty: _parseDifficulty(data['difficulty']),
    durationMinutes: data['durationMinutes'] ?? 30,
    estimatedCaloriesBurn: data['estimatedCaloriesBurn'] ?? 0,
    createdAt:
        data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : (data['createdAt'] is int
                ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
                : DateTime.now()),
    createdBy: data['createdBy'] ?? 'system',
    exercises: [], // No exercises loaded
    equipment: List<String>.from(data['equipment'] ?? []),
    tags: List<String>.from(data['tags'] ?? []),
  );
}

// Helper methods to parse category and difficulty
WorkoutCategory _parseCategory(String? categoryStr) {
  switch (categoryStr) {
    case 'bums':
      return WorkoutCategory.bums;
    case 'tums':
      return WorkoutCategory.tums;
    case 'fullBody':
      return WorkoutCategory.fullBody;
    case 'cardio':
      return WorkoutCategory.cardio;
    case 'quickWorkout':
      return WorkoutCategory.quickWorkout;
    default:
      return WorkoutCategory.fullBody;
  }
}

WorkoutDifficulty _parseDifficulty(String? difficultyStr) {
  switch (difficultyStr) {
    case 'beginner':
      return WorkoutDifficulty.beginner;
    case 'intermediate':
      return WorkoutDifficulty.intermediate;
    case 'advanced':
      return WorkoutDifficulty.advanced;
    default:
      return WorkoutDifficulty.beginner;
  }
}
