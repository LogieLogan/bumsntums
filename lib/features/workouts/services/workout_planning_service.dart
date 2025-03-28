// lib/features/workouts/services/workout_planning_service.dart
import 'package:bums_n_tums/features/workouts/models/exercise.dart';
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

  Future<bool> updateWorkoutPlan(WorkoutPlan plan) async {
    try {
      // First check if the document exists
      final docRef = _firestore
          .collection('workout_plans')
          .doc(plan.userId)
          .collection('plans')
          .doc(plan.id);

      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        print('Plan document does not exist: ${docRef.path}');
        // Instead of failing, create the document
        await docRef.set(plan.toMap());

        // If this plan is active, deactivate others
        if (plan.isActive) {
          await _deactivateOtherPlans(plan.userId, plan.id);
        }

        return true;
      }

      // Document exists, perform update
      await docRef.update(plan.toMap());

      // If this plan is active, deactivate others
      if (plan.isActive) {
        await _deactivateOtherPlans(plan.userId, plan.id);
      }

      return true;
    } catch (e) {
      print('Error updating workout plan: $e');
      return false;
    }
  }

  // Add this method to WorkoutPlanningService
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

  Future<List<Workout>> _getRecommendedWorkoutsForUser(
    String userId,
    List<String> focusAreas,
    String fitnessLevel,
  ) async {
    try {
      final difficulty = _mapFitnessLevelToDifficulty(fitnessLevel);
      List<Workout> matchingWorkouts = [];

      // Try to find workouts that match the user's focus areas
      for (final area in focusAreas) {
        try {
          final snapshot =
              await _firestore
                  .collection('workouts')
                  .where('difficulty', isEqualTo: difficulty.name)
                  .where(
                    'category',
                    isEqualTo: _mapFocusAreaToCategory(area).name,
                  )
                  .limit(5)
                  .get();

          final workouts =
              snapshot.docs
                  .map((doc) => Workout.fromMap({'id': doc.id, ...doc.data()}))
                  .toList();

          matchingWorkouts.addAll(workouts);
        } catch (e) {
          debugPrint('Error fetching workouts for area $area: $e');
        }
      }

      // If we didn't find any workouts matching the focus areas, try just the difficulty
      if (matchingWorkouts.isEmpty) {
        try {
          final snapshot =
              await _firestore
                  .collection('workouts')
                  .where('difficulty', isEqualTo: difficulty.name)
                  .limit(10)
                  .get();

          matchingWorkouts =
              snapshot.docs
                  .map((doc) => Workout.fromMap({'id': doc.id, ...doc.data()}))
                  .toList();
        } catch (e) {
          debugPrint('Error fetching workouts by difficulty: $e');
        }
      }

      // If we still don't have any workouts, try to get any workouts at all
      if (matchingWorkouts.isEmpty) {
        try {
          final snapshot =
              await _firestore.collection('workouts').limit(10).get();

          matchingWorkouts =
              snapshot.docs
                  .map((doc) => Workout.fromMap({'id': doc.id, ...doc.data()}))
                  .toList();
        } catch (e) {
          debugPrint('Error fetching any workouts: $e');
        }
      }

      // If we still don't have any workouts, create sample ones
      if (matchingWorkouts.isEmpty) {
        matchingWorkouts = _createSampleWorkouts(focusAreas, difficulty);
      }

      return matchingWorkouts;
    } catch (e) {
      debugPrint('Error getting recommended workouts: $e');
      // Return sample workouts in case of error
      return _createSampleWorkouts(
        focusAreas,
        _mapFitnessLevelToDifficulty(fitnessLevel),
      );
    }
  }

  List<Workout> _createSampleWorkouts(
    List<String> focusAreas,
    WorkoutDifficulty difficulty,
  ) {
    final now = DateTime.now();
    final List<Workout> sampleWorkouts = [];

    // Create a workout for each focus area
    for (final area in focusAreas) {
      final workout = Workout(
        id: 'sample-${area.toLowerCase()}-${now.millisecondsSinceEpoch}',
        title:
            '${area.substring(0, 1).toUpperCase()}${area.substring(1)} Workout',
        description: 'A sample workout focused on ${area.toLowerCase()}.',
        imageUrl: '',
        category: _mapFocusAreaToCategory(area),
        difficulty: difficulty,
        durationMinutes: 30,
        estimatedCaloriesBurn: 200,
        createdAt: now,
        createdBy: 'system',
        exercises: _createSampleExercises(_mapFocusAreaToCategory(area)),
        equipment: const ['No equipment needed'],
        tags: [area.toLowerCase(), 'sample', 'generated'],
      );
      sampleWorkouts.add(workout);
    }

    // Add a full body workout for variety
    sampleWorkouts.add(
      Workout(
        id: 'sample-fullbody-${now.millisecondsSinceEpoch}',
        title: 'Full Body Workout',
        description: 'A complete workout targeting all major muscle groups.',
        imageUrl: '',
        category: WorkoutCategory.fullBody,
        difficulty: difficulty,
        durationMinutes: 45,
        estimatedCaloriesBurn: 300,
        createdAt: now,
        createdBy: 'system',
        exercises: _createSampleExercises(WorkoutCategory.fullBody),
        equipment: const ['No equipment needed'],
        tags: ['full body', 'sample', 'generated'],
      ),
    );

    return sampleWorkouts;
  }

  List<Exercise> _createSampleExercises(WorkoutCategory category) {
    final List<Exercise> exercises = [];

    // Define some basic exercises based on the category
    switch (category) {
      case WorkoutCategory.bums:
        exercises.addAll([
          Exercise(
            id: 'sample-squats',
            name: 'Squats',
            description:
                'Stand with feet shoulder-width apart. Lower your body by bending your knees and pushing your hips back, as if sitting in a chair. Keep your chest up and back straight. Return to standing.',
            imageUrl: '', // Empty string for sample
            sets: 3,
            reps: 12,
            restBetweenSeconds: 30,
            targetArea: 'bums',
            modifications: [],
          ),
          Exercise(
            id: 'sample-lunges',
            name: 'Lunges',
            description:
                'Step forward with one leg and lower your body until both knees are bent at 90-degree angles. Push through your front heel to return to starting position. Repeat with the other leg.',
            imageUrl: '', // Empty string for sample
            sets: 3,
            reps: 10,
            restBetweenSeconds: 30,
            targetArea: 'bums',
            modifications: [],
          ),
        ]);
        break;
      case WorkoutCategory.tums:
        exercises.addAll([
          Exercise(
            id: 'sample-crunches',
            name: 'Crunches',
            description:
                'Lie on your back with knees bent and feet flat on the floor. Place hands behind your head. Lift your shoulders off the ground using your abdominal muscles, then lower back down with control.',
            imageUrl: '', // Empty string for sample
            sets: 3,
            reps: 15,
            restBetweenSeconds: 30,
            targetArea: 'tums',
            modifications: [],
          ),
          Exercise(
            id: 'sample-plank',
            name: 'Plank',
            description:
                'Start in a push-up position with your forearms on the ground. Keep your body in a straight line from head to heels. Engage your core and hold the position.',
            imageUrl: '', // Empty string for sample
            sets: 3,
            reps: 1, // For timed exercise
            durationSeconds: 30,
            restBetweenSeconds: 30,
            targetArea: 'tums',
            modifications: [],
          ),
        ]);
        break;
      case WorkoutCategory.fullBody:
      default:
        exercises.addAll([
          Exercise(
            id: 'sample-pushups',
            name: 'Push-ups',
            description:
                'Start in a plank position with hands shoulder-width apart. Lower your body by bending your elbows, keeping your back straight. Push back up to the starting position.',
            imageUrl: '', // Empty string for sample
            sets: 3,
            reps: 10,
            restBetweenSeconds: 30,
            targetArea: 'upper body',
            modifications: [],
          ),
          Exercise(
            id: 'sample-squats-fb',
            name: 'Squats',
            description:
                'Stand with feet shoulder-width apart. Lower your body by bending your knees and pushing your hips back, as if sitting in a chair. Keep your chest up and back straight. Return to standing.',
            imageUrl: '', // Empty string for sample
            sets: 3,
            reps: 12,
            restBetweenSeconds: 30,
            targetArea: 'lower body',
            modifications: [],
          ),
          Exercise(
            id: 'sample-plank-fb',
            name: 'Plank',
            description:
                'Start in a push-up position with your forearms on the ground. Keep your body in a straight line from head to heels. Engage your core and hold the position.',
            imageUrl: '', // Empty string for sample
            sets: 3,
            reps: 1, // For timed exercise
            durationSeconds: 30,
            restBetweenSeconds: 30,
            targetArea: 'core',
            modifications: [],
          ),
        ]);
        break;
    }

    return exercises;
  }

  WorkoutCategory _mapFocusAreaToCategory(String area) {
    switch (area.toLowerCase()) {
      case 'bums':
        return WorkoutCategory.bums;
      case 'tums':
        return WorkoutCategory.tums;
      // Since arms, legs, back aren't in the enum, map them to appropriate categories
      case 'arms':
      case 'legs':
      case 'back':
      case 'upper body':
      case 'lower body':
        return WorkoutCategory.fullBody; // Default to full body if not in enum
      default:
        return WorkoutCategory.fullBody;
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
