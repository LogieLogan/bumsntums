// lib/features/workouts/services/workout_service.dart
import 'package:bums_n_tums/shared/repositories/mock_data/bums_workouts.dart';
import 'package:bums_n_tums/shared/repositories/mock_data/cardio_workouts.dart';
import 'package:bums_n_tums/shared/repositories/mock_data/full_body_workouts.dart';
import 'package:bums_n_tums/shared/repositories/mock_data/quick_workouts.dart';
import 'package:bums_n_tums/shared/repositories/mock_data/tums_workouts.dart';
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
  bool _isInitialized = false;

  WorkoutService(this._analytics);

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _isInitialized = true;
      if (kDebugMode) {
        print("Workout service initialization complete");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing workout service: $e");
      }
    }
  }

  Future<List<Workout>> getAllWorkouts() async {
    try {
      final bumsWorkouts = await getBumsWorkoutsAsync();
      final tumsWorkouts = await getTumsWorkoutsAsync();
      final fullBodyWorkouts = await getFullBodyWorkoutsAsync();
      final quickWorkouts = await getQuickWorkoutsAsync();
      final cardioWorkouts = await getCardioWorkoutsAsync();
      return [
        ...bumsWorkouts,
        ...tumsWorkouts,
        ...fullBodyWorkouts,
        ...quickWorkouts,
        ...cardioWorkouts,
      ];
    } catch (e) {
      _analytics.logError(error: 'Error fetching workouts: $e');
      rethrow;
    }
  }

  Future<List<Workout>> getFeaturedWorkouts() async {
    try {
      final allWorkouts = await getAllWorkouts();
      return allWorkouts.where((workout) => workout.featured).toList();
    } catch (e) {
      _analytics.logError(error: 'Error fetching featured workouts: $e');
      rethrow;
    }
  }

  Future<List<Workout>> getWorkoutsByCategory(WorkoutCategory category) async {
    try {
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
      if (kDebugMode) {
        print('Error fetching workouts by category: $e');
      }
      return _mockRepository.getWorkoutsByCategory(category);
    }
  }

  Future<Workout?> getWorkoutById(String workoutId) async {
    try {
      if (kDebugMode) {
        final mockWorkout = _mockRepository.getWorkoutById(workoutId);
        if (mockWorkout != null) return mockWorkout;
      }
      try {
        final doc =
            await _firestore.collection('workouts').doc(workoutId).get();
        if (doc.exists) return Workout.fromMap({'id': doc.id, ...doc.data()!});
      } catch (e) {
        if (kDebugMode) {
          print('Error checking regular workouts: $e');
        }
      }
      try {
        final customWorkoutQuery =
            await _firestore
                .collectionGroup('workouts')
                .where('id', isEqualTo: workoutId)
                .limit(1)
                .get();
        if (customWorkoutQuery.docs.isNotEmpty) {
          return Workout.fromMap(customWorkoutQuery.docs.first.data());
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error in collectionGroup query: $e');
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching workout details: $e');
      }
      return _mockRepository.getWorkoutById(workoutId);
    }
  }

  Future<List<Workout>> getWorkoutsByDifficulty(
    WorkoutDifficulty difficulty,
  ) async {
    try {
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
      if (kDebugMode) {
        print('Error fetching workouts by difficulty: $e');
      }
      return _mockRepository
          .getAllWorkouts()
          .where((w) => w.difficulty == difficulty)
          .toList();
    }
  }

  Future<List<Workout>> getWorkoutsByDuration(
    int minMinutes,
    int maxMinutes,
  ) async {
    try {
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
      if (kDebugMode) {
        print('Error fetching workouts by duration: $e');
      }
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

  Future<void> logCompletedWorkout(WorkoutLog log) async {
    try {
      if (kDebugMode) {
        print('Attempting to log completed workout for user: ${log.userId}');
        print('Workout ID: ${log.workoutId}');
        print('Completed at: ${log.completedAt}');
      }
      await _firestore
          .collection('workout_logs')
          .doc(log.userId)
          .collection('logs')
          .doc(log.id)
          .set(log.toMap());
      if (kDebugMode) {
        print('Successfully saved workout log to Firestore');
      }
      await _analytics.logEvent(
        name: 'workout_completed',
        parameters: {
          'workout_id': log.workoutId,
          'duration_minutes': log.durationMinutes,
          'calories_burned': log.caloriesBurned,
          'rating': log.userFeedback.rating,
        },
      );
      try {
        await _firestore.collection('fitness_profiles').doc(log.userId).update({
          'stats.workoutsCompleted': FieldValue.increment(1),
        });
        if (kDebugMode) {
          print('Updated workout count in fitness profile');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error updating fitness profile workout count: $e');
        }
        await _firestore.collection('fitness_profiles').doc(log.userId).set({
          'stats': {'workoutsCompleted': 1},
        }, SetOptions(merge: true));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error logging completed workout: $e');
        print('Error stack trace: ${StackTrace.current}');
      }
      rethrow;
    }
  }

  Future<void> deleteWorkoutLog(WorkoutLog log) async {
    try {
      if (kDebugMode) {
        print(
          'Attempting to delete workout log: ${log.id} for user: ${log.userId}',
        );
      }
      await _firestore
          .collection('workout_logs')
          .doc(log.userId)
          .collection('logs')
          .doc(log.id)
          .delete();

      if (kDebugMode) {
        print('Successfully deleted workout log from Firestore');
      }

      await _analytics.logEvent(
        name: 'workout_log_deleted',
        parameters: {
          'log_id': log.id,
          'workout_id': log.workoutId,
          'user_id': log.userId,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting workout log ${log.id}: $e');
      }
      _analytics.logError(
        error: 'Failed to delete workout log: $e',
        parameters: {'log_id': log.id, 'user_id': log.userId},
      );
      rethrow;
    }
  }

  Future<List<WorkoutLog>> getUserWorkoutHistory(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('workout_logs')
              .doc(userId)
              .collection('logs')
              .orderBy('completedAt', descending: true)
              .limit(50)
              .get();
      return snapshot.docs
          .map((doc) => WorkoutLog.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching workout history: $e');
      }
      return [];
    }
  }

  Future<void> saveToFavorites(String userId, String workoutId) async {
    try {
      await _firestore
          .collection('user_workout_favorites')
          .doc(userId)
          .collection('favorites')
          .doc(workoutId)
          .set({'addedAt': Timestamp.now()});
      await _analytics.logEvent(
        name: 'workout_favorited',
        parameters: {'workout_id': workoutId},
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving workout to favorites: $e');
      }
      rethrow;
    }
  }

  Future<void> removeFromFavorites(String userId, String workoutId) async {
    try {
      await _firestore
          .collection('user_workout_favorites')
          .doc(userId)
          .collection('favorites')
          .doc(workoutId)
          .delete();
      await _analytics.logEvent(
        name: 'workout_unfavorited',
        parameters: {'workout_id': workoutId},
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error removing workout from favorites: $e');
      }
      rethrow;
    }
  }

  Future<List<Workout>> getUserFavoriteWorkouts(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('user_workout_favorites')
              .doc(userId)
              .collection('favorites')
              .get();
      final workoutIds = snapshot.docs.map((doc) => doc.id).toList();
      if (workoutIds.isEmpty) return [];
      List<Workout> favorites = [];
      if (kDebugMode) {
        favorites =
            _mockRepository
                .getAllWorkouts()
                .where((workout) => workoutIds.contains(workout.id))
                .toList();
      } else {
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
      }
      for (final workoutId in workoutIds) {
        if (!favorites.any((w) => w.id == workoutId)) {
          try {
            final customWorkoutQuery =
                await _firestore
                    .collectionGroup('workouts')
                    .where('id', isEqualTo: workoutId)
                    .limit(1)
                    .get();
            if (customWorkoutQuery.docs.isNotEmpty) {
              favorites.add(
                Workout.fromMap(customWorkoutQuery.docs.first.data()),
              );
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error fetching custom workout: $e');
            }
          }
        }
      }
      return favorites;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching favorite workouts: $e');
      }
      return [];
    }
  }

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
      if (kDebugMode) {
        print('Error checking if workout is favorited: $e');
      }
      return false;
    }
  }

  Future<void> cacheWorkoutsForOfflineUse(List<String> workoutIds) async {
    if (kDebugMode) {
      print('Caching workouts for offline use: $workoutIds');
    }
  }

  Future<void> updateWorkoutFeedback(
    String userId,
    String workoutId,
    UserFeedback feedback,
  ) async {
    try {
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
        if (kDebugMode) {
          print('No workout log found to update feedback');
        }
        return;
      }
      final logId = querySnapshot.docs.first.id;
      await _firestore
          .collection('workout_logs')
          .doc(userId)
          .collection('logs')
          .doc(logId)
          .update({'userFeedback': feedback.toMap()});
      await _analytics.logEvent(
        name: 'workout_feedback_submitted',
        parameters: {'workout_id': workoutId, 'rating': feedback.rating},
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating workout feedback: $e');
      }
      rethrow;
    }
  }
}
