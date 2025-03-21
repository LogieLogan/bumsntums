// lib/features/workouts/services/workout_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../models/workout.dart';
import '../models/workout_log.dart';
import '../../../shared/repositories/mock_workout_repository.dart';

class WorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics;
  final MockWorkoutRepository _mockRepository = MockWorkoutRepository();

  WorkoutService(this._analytics);

  // Get all workouts
  Future<List<Workout>> getAllWorkouts() async {
    try {
      // For development, use mock data
      if (kDebugMode) {
        return _mockRepository.getAllWorkouts();
      }

      final snapshot = await _firestore.collection('workouts').get();
      return snapshot.docs
          .map((doc) => Workout.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      // Log error
      print('Error fetching workouts: $e');
      // Fall back to mock data in case of error
      return _mockRepository.getAllWorkouts();
    }
  }

  // Get featured workouts
  Future<List<Workout>> getFeaturedWorkouts() async {
    try {
      // For development, use mock data
      if (kDebugMode) {
        return _mockRepository.getFeaturedWorkouts();
      }

      final snapshot =
          await _firestore
              .collection('workouts')
              .where('featured', isEqualTo: true)
              .get();

      return snapshot.docs
          .map((doc) => Workout.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      // Log error
      print('Error fetching featured workouts: $e');
      // Fall back to mock data in case of error
      return _mockRepository.getFeaturedWorkouts();
    }
  }

  // Get workouts by category
  Future<List<Workout>> getWorkoutsByCategory(WorkoutCategory category) async {
    try {
      // For development, use mock data
      if (kDebugMode) {
        return _mockRepository.getWorkoutsByCategory(category);
      }

      final snapshot =
          await _firestore
              .collection('workouts')
              .where('category', isEqualTo: category.name)
              .get();

      return snapshot.docs
          .map((doc) => Workout.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      // Log error
      print('Error fetching workouts by category: $e');
      // Fall back to mock data in case of error
      return _mockRepository.getWorkoutsByCategory(category);
    }
  }

  // Get workout details
  Future<Workout?> getWorkoutById(String workoutId) async {
    try {
      // For development, use mock data
      if (kDebugMode) {
        return _mockRepository.getWorkoutById(workoutId);
      }

      final doc = await _firestore.collection('workouts').doc(workoutId).get();

      if (!doc.exists) {
        return null;
      }

      return Workout.fromMap({'id': doc.id, ...doc.data()!});
    } catch (e) {
      // Log error
      print('Error fetching workout details: $e');
      // Fall back to mock data in case of error
      return _mockRepository.getWorkoutById(workoutId);
    }
  }

  // Get workouts by difficulty
  Future<List<Workout>> getWorkoutsByDifficulty(
    WorkoutDifficulty difficulty,
  ) async {
    try {
      // For development, use mock data
      if (kDebugMode) {
        return _mockRepository
            .getAllWorkouts()
            .where((w) => w.difficulty == difficulty)
            .toList();
      }

      final snapshot =
          await _firestore
              .collection('workouts')
              .where('difficulty', isEqualTo: difficulty.name)
              .get();

      return snapshot.docs
          .map((doc) => Workout.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      // Log error
      print('Error fetching workouts by difficulty: $e');
      // Fall back to mock data in case of error
      return _mockRepository
          .getAllWorkouts()
          .where((w) => w.difficulty == difficulty)
          .toList();
    }
  }

  // Get workouts by duration range
  Future<List<Workout>> getWorkoutsByDuration(
    int minMinutes,
    int maxMinutes,
  ) async {
    try {
      // For development, use mock data
      if (kDebugMode) {
        return _mockRepository
            .getAllWorkouts()
            .where(
              (w) =>
                  w.durationMinutes >= minMinutes &&
                  w.durationMinutes <= maxMinutes,
            )
            .toList();
      }

      final snapshot =
          await _firestore
              .collection('workouts')
              .where('durationMinutes', isGreaterThanOrEqualTo: minMinutes)
              .where('durationMinutes', isLessThanOrEqualTo: maxMinutes)
              .get();

      return snapshot.docs
          .map((doc) => Workout.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      // Log error
      print('Error fetching workouts by duration: $e');
      // Fall back to mock data in case of error
      return _mockRepository
          .getAllWorkouts()
          .where(
            (w) =>
                w.durationMinutes >= minMinutes &&
                w.durationMinutes <= maxMinutes,
          )
          .toList();
    }
  }

  // Log completed workout
  Future<void> logCompletedWorkout(WorkoutLog log) async {
    try {
      print('Attempting to log completed workout for user: ${log.userId}');
      print('Workout ID: ${log.workoutId}');
      print('Completed at: ${log.completedAt}');

      // Save to Firestore
      await _firestore
          .collection('workout_logs')
          .doc(log.userId)
          .collection('logs')
          .doc(log.id)
          .set(log.toMap());

      print('Successfully saved workout log to Firestore');

      // Log analytics event
      await _analytics.logEvent(
        name: 'workout_completed',
        parameters: {
          'workout_id': log.workoutId,
          'duration_minutes': log.durationMinutes,
          'calories_burned': log.caloriesBurned,
          'rating': log.userFeedback.rating,
        },
      );

      // Update user stats - increase completed workouts count
      try {
        await _firestore.collection('fitness_profiles').doc(log.userId).update({
          'stats.workoutsCompleted': FieldValue.increment(1),
        });
        print('Updated workout count in fitness profile');
      } catch (e) {
        // This might fail if the field doesn't exist yet
        print('Error updating fitness profile workout count: $e');
        // Try to set instead of update
        await _firestore.collection('fitness_profiles').doc(log.userId).set({
          'stats': {'workoutsCompleted': 1},
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Log error
      print('Error logging completed workout: $e');
      print('Error stack trace: ${StackTrace.current}');
      // For now, just rethrow - in a real app, we might want to save locally for later sync
      rethrow;
    }
  }

  // Get user's workout history
  Future<List<WorkoutLog>> getUserWorkoutHistory(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('workout_logs')
              .doc(userId)
              .collection('logs')
              .orderBy('completedAt', descending: true)
              .limit(50) // Limit to recent workouts
              .get();

      return snapshot.docs
          .map((doc) => WorkoutLog.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      // Log error
      print('Error fetching workout history: $e');
      // Return empty list in case of error
      return [];
    }
  }

  // Save a workout to user's favorites
  Future<void> saveToFavorites(String userId, String workoutId) async {
    try {
      await _firestore
          .collection('user_workout_favorites')
          .doc(userId)
          .collection('favorites')
          .doc(workoutId)
          .set({'addedAt': Timestamp.now()});

      // Log analytics event
      await _analytics.logEvent(
        name: 'workout_favorited',
        parameters: {'workout_id': workoutId},
      );
    } catch (e) {
      // Log error
      print('Error saving workout to favorites: $e');
      rethrow;
    }
  }

  // Remove a workout from user's favorites
  Future<void> removeFromFavorites(String userId, String workoutId) async {
    try {
      await _firestore
          .collection('user_workout_favorites')
          .doc(userId)
          .collection('favorites')
          .doc(workoutId)
          .delete();

      // Log analytics event
      await _analytics.logEvent(
        name: 'workout_unfavorited',
        parameters: {'workout_id': workoutId},
      );
    } catch (e) {
      // Log error
      print('Error removing workout from favorites: $e');
      rethrow;
    }
  }

  // Get user's favorite workouts
  Future<List<Workout>> getUserFavoriteWorkouts(String userId) async {
    try {
      // Get favorite workout IDs
      final snapshot =
          await _firestore
              .collection('user_workout_favorites')
              .doc(userId)
              .collection('favorites')
              .get();

      final workoutIds = snapshot.docs.map((doc) => doc.id).toList();

      if (workoutIds.isEmpty) {
        return [];
      }

      // For development, use mock data
      if (kDebugMode) {
        return _mockRepository
            .getAllWorkouts()
            .where((workout) => workoutIds.contains(workout.id))
            .toList();
      }

      // Get the full workout details for each ID
      // Note: Firestore doesn't support direct 'where in' for large arrays,
      // so we may need to batch this for large collections
      List<Workout> favorites = [];

      // Batch into groups of 10 (Firestore limit)
      for (int i = 0; i < workoutIds.length; i += 10) {
        final end = (i + 10 < workoutIds.length) ? i + 10 : workoutIds.length;
        final batch = workoutIds.sublist(i, end);

        final workoutsSnapshot =
            await _firestore
                .collection('workouts')
                .where(FieldPath.documentId, whereIn: batch)
                .get();

        favorites.addAll(
          workoutsSnapshot.docs.map(
            (doc) => Workout.fromMap({'id': doc.id, ...doc.data()}),
          ),
        );
      }

      return favorites;
    } catch (e) {
      // Log error
      print('Error fetching favorite workouts: $e');
      return [];
    }
  }

  // Check if a workout is in user's favorites
  Future<bool> isWorkoutFavorited(String userId, String workoutId) async {
    try {
      final doc =
          await _firestore
              .collection('user_workout_favorites')
              .doc(userId)
              .collection('favorites')
              .doc(workoutId)
              .get();

      return doc.exists;
    } catch (e) {
      // Log error
      print('Error checking if workout is favorited: $e');
      return false;
    }
  }

  // Methods for offline support
  Future<void> cacheWorkoutsForOfflineUse(List<String> workoutIds) async {
    // TODO: Implement offline caching
    // This will involve storing workout data in local storage
    // For now, this is a placeholder
    print('Caching workouts for offline use: $workoutIds');
  }

  Future<void> updateWorkoutFeedback(
    String userId,
    String workoutId,
    UserFeedback feedback,
  ) async {
    try {
      // Find the most recent workout log for this workout
      final querySnapshot =
          await _firestore
              .collection('workout_logs')
              .doc(userId)
              .collection('logs')
              .where('workoutId', isEqualTo: workoutId)
              .orderBy('completedAt', descending: true)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        print('No workout log found to update feedback');
        return;
      }

      final logId = querySnapshot.docs.first.id;

      // Update the feedback
      await _firestore
          .collection('workout_logs')
          .doc(userId)
          .collection('logs')
          .doc(logId)
          .update({'userFeedback': feedback.toMap()});

      // Log analytics event
      await _analytics.logEvent(
        name: 'workout_feedback_submitted',
        parameters: {'workout_id': workoutId, 'rating': feedback.rating},
      );
    } catch (e) {
      // Log error
      print('Error updating workout feedback: $e');
      rethrow;
    }
  }
}
