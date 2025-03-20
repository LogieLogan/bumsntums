// lib/features/workouts/services/workout_planning_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/workout_plan.dart';
import '../models/workout.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

class WorkoutPlanningService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics;

  WorkoutPlanningService(this._analytics);

  // Create a new workout plan
  Future<String> createWorkoutPlan(WorkoutPlan plan) async {
    try {
      // If ID is empty, generate one
      final String planId =
          plan.id.isEmpty
              ? _firestore.collection('workout_plans').doc().id
              : plan.id;

      final planWithId = plan.copyWith(
        id: planId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('workout_plans')
          .doc(plan.userId)
          .collection('plans')
          .doc(planId)
          .set(planWithId.toMap());

      // Log analytics event
      await _analytics.logEvent(
        name: 'workout_plan_created',
        parameters: {
          'plan_id': planId,
          'num_workouts': plan.scheduledWorkouts.length,
        },
      );

      return planId;
    } catch (e) {
      debugPrint('Error creating workout plan: $e');
      rethrow;
    }
  }

  // Update an existing workout plan
  Future<void> updateWorkoutPlan(WorkoutPlan plan) async {
    try {
      final updatedPlan = plan.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection('workout_plans')
          .doc(plan.userId)
          .collection('plans')
          .doc(plan.id)
          .update(updatedPlan.toMap());

      // Log analytics event
      await _analytics.logEvent(
        name: 'workout_plan_updated',
        parameters: {'plan_id': plan.id},
      );
    } catch (e) {
      debugPrint('Error updating workout plan: $e');
      rethrow;
    }
  }

  // Get all workout plans for a user
  Future<List<WorkoutPlan>> getUserWorkoutPlans(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('workout_plans')
              .doc(userId)
              .collection('plans')
              .orderBy('startDate', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => WorkoutPlan.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      debugPrint('Error getting user workout plans: $e');
      return [];
    }
  }

  // Get active workout plan for a user
  Future<WorkoutPlan?> getActiveWorkoutPlan(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('workout_plans')
              .doc(userId)
              .collection('plans')
              .where('isActive', isEqualTo: true)
              .orderBy('startDate', descending: true)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return WorkoutPlan.fromMap({
        'id': snapshot.docs.first.id,
        ...snapshot.docs.first.data(),
      });
    } catch (e) {
      debugPrint('Error getting active workout plan: $e');
      return null;
    }
  }

  // Get a specific workout plan
  Future<WorkoutPlan?> getWorkoutPlan(String userId, String planId) async {
    try {
      final doc =
          await _firestore
              .collection('workout_plans')
              .doc(userId)
              .collection('plans')
              .doc(planId)
              .get();

      if (!doc.exists) {
        return null;
      }

      return WorkoutPlan.fromMap({'id': doc.id, ...doc.data()!});
    } catch (e) {
      debugPrint('Error getting workout plan: $e');
      return null;
    }
  }

  // Delete a workout plan
  Future<void> deleteWorkoutPlan(String userId, String planId) async {
    try {
      await _firestore
          .collection('workout_plans')
          .doc(userId)
          .collection('plans')
          .doc(planId)
          .delete();

      // Log analytics event
      await _analytics.logEvent(
        name: 'workout_plan_deleted',
        parameters: {'plan_id': planId},
      );
    } catch (e) {
      debugPrint('Error deleting workout plan: $e');
      rethrow;
    }
  }

  // Mark a scheduled workout as completed
  Future<void> markWorkoutCompleted(
    String userId,
    String planId,
    String workoutId,
    DateTime completedAt,
  ) async {
    try {
      // Get the current plan
      final doc =
          await _firestore
              .collection('workout_plans')
              .doc(userId)
              .collection('plans')
              .doc(planId)
              .get();

      if (!doc.exists) {
        throw Exception('Workout plan not found');
      }

      final plan = WorkoutPlan.fromMap({'id': doc.id, ...doc.data()!});

      // Find the scheduled workout and mark it as completed
      final updatedScheduled =
          plan.scheduledWorkouts.map((scheduled) {
            if (scheduled.workoutId == workoutId) {
              return scheduled.copyWith(
                isCompleted: true,
                completedAt: completedAt,
              );
            }
            return scheduled;
          }).toList();

      // Update the plan
      final updatedPlan = plan.copyWith(
        scheduledWorkouts: updatedScheduled,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('workout_plans')
          .doc(userId)
          .collection('plans')
          .doc(planId)
          .update(updatedPlan.toMap());

      // Log analytics event
      await _analytics.logEvent(
        name: 'planned_workout_completed',
        parameters: {'plan_id': planId, 'workout_id': workoutId},
      );
    } catch (e) {
      debugPrint('Error marking workout as completed: $e');
      rethrow;
    }
  }

  // Generate a recommended workout plan based on user profile and history
  Future<WorkoutPlan> generateRecommendedPlan(
    String userId,
    List<String> focusAreas,
    int weeklyWorkoutDays,
    String fitnessLevel,
  ) async {
    try {
      // This would be a more complex algorithm in production
      // For now, we'll create a simple plan with some variety

      // Get user's favorite or commonly used workouts
      // This is a placeholder - in production, we would analyze workout history
      final workouts = await _getRecommendedWorkoutsForUser(
        userId,
        focusAreas,
        fitnessLevel,
      );

      // Create scheduled workouts for the next 4 weeks
      final List<ScheduledWorkout> scheduledWorkouts = [];
      final now = DateTime.now();
      final startOfWeek = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday % 7));

      // Distribute workouts across days of the week
      for (int week = 0; week < 4; week++) {
        // Determine which days of the week to schedule workouts
        final daysToSchedule = _getScheduleDays(weeklyWorkoutDays);

        for (final day in daysToSchedule) {
          // Get a workout for this day, ensuring variety
          final workout = workouts[scheduledWorkouts.length % workouts.length];

          // Calculate the date for this workout
          final workoutDate = startOfWeek.add(Duration(days: 7 * week + day));

          scheduledWorkouts.add(
            ScheduledWorkout(
              workoutId: workout.id,
              title: workout.title,
              workoutImageUrl: workout.imageUrl,
              scheduledDate: workoutDate,
              reminderEnabled: true,
              reminderTime: DateTime(
                workoutDate.year,
                workoutDate.month,
                workoutDate.day,
                18, // 6 PM default reminder
                0,
              ),
            ),
          );
        }
      }

      // Create the plan
      final planId = _firestore.collection('workout_plans').doc().id;
      final plan = WorkoutPlan(
        id: planId,
        userId: userId,
        name: 'Recommended 4-Week Plan',
        description:
            'A balanced plan based on your preferences and fitness level',
        startDate: startOfWeek,
        endDate: startOfWeek.add(const Duration(days: 28)),
        isActive: true,
        goal: 'Improve overall fitness with focus on ${focusAreas.join(", ")}',
        scheduledWorkouts: scheduledWorkouts,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Log analytics event
      await _analytics.logEvent(
        name: 'workout_plan_generated',
        parameters: {
          'focus_areas': focusAreas.join(','),
          'weekly_days': weeklyWorkoutDays,
        },
      );

      return plan;
    } catch (e) {
      debugPrint('Error generating recommended plan: $e');
      throw Exception('Failed to generate plan: $e');
    }
  }

  // Helper method to get recommended workouts for the user
  Future<List<Workout>> _getRecommendedWorkoutsForUser(
    String userId,
    List<String> focusAreas,
    String fitnessLevel,
  ) async {
    // In a production app, this would use more sophisticated recommendation logic
    // For now, we'll just get a mix of workouts that match the focus areas

    // Convert fitnessLevel string to enum
    final difficulty = _mapFitnessLevelToDifficulty(fitnessLevel);

    try {
      final snapshot =
          await _firestore
              .collection('workouts')
              .where('difficulty', isEqualTo: difficulty.name)
              .limit(20)
              .get();

      List<Workout> allWorkouts =
          snapshot.docs
              .map((doc) => Workout.fromMap({'id': doc.id, ...doc.data()}))
              .toList();

      // Filter for workouts that match at least one focus area
      final matchingWorkouts =
          allWorkouts.where((workout) {
            final category = workout.category.name.toLowerCase();
            return focusAreas.any(
              (area) => category.contains(area.toLowerCase()),
            );
          }).toList();

      // If we don't have enough matching workouts, add some other ones
      if (matchingWorkouts.length < 10) {
        matchingWorkouts.addAll(
          allWorkouts
              .where((w) => !matchingWorkouts.contains(w))
              .take(10 - matchingWorkouts.length),
        );
      }

      return matchingWorkouts;
    } catch (e) {
      debugPrint('Error getting recommended workouts: $e');
      // Return empty list in case of error
      return [];
    }
  }

  // Helper method to map fitness level to workout difficulty
  WorkoutDifficulty _mapFitnessLevelToDifficulty(String fitnessLevel) {
    switch (fitnessLevel.toLowerCase()) {
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

  // Helper method to determine which days of the week to schedule workouts
  List<int> _getScheduleDays(int weeklyWorkoutDays) {
    // This is a simple algorithm that spaces workouts throughout the week
    // A more advanced algorithm would consider user preferences and rest days

    if (weeklyWorkoutDays >= 7) {
      return [0, 1, 2, 3, 4, 5, 6]; // Every day
    }

    List<int> days = [];

    // Calculate step size to distribute workouts evenly
    final stepSize = 7 / weeklyWorkoutDays;

    for (int i = 0; i < weeklyWorkoutDays; i++) {
      // Round to nearest day
      final day = (i * stepSize).round();
      days.add(day);
    }

    return days;
  }
}
