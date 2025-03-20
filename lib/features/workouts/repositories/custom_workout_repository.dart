// lib/features/workouts/repositories/custom_workout_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout.dart';

class CustomWorkoutRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Save a custom workout to the user's collection
  Future<bool> saveCustomWorkout(String userId, Workout workout) async {
    try {
      print('Saving workout: ${workout.title} for user: $userId');
      
      // Save to user_custom_workouts/{userId}/workouts/{workoutId}
      await _firestore
          .collection('user_custom_workouts')
          .doc(userId)
          .collection('workouts')
          .doc(workout.id)
          .set(workout.toMap());
      
      print('Custom workout saved successfully');
      return true;
    } catch (e) {
      print('Error saving custom workout: $e');
      return false;
    }
  }
  
  // Delete a custom workout
  Future<bool> deleteCustomWorkout(String userId, String workoutId) async {
    try {
      // Delete from user_custom_workouts/{userId}/workouts/{workoutId}
      await _firestore
          .collection('user_custom_workouts')
          .doc(userId)
          .collection('workouts')
          .doc(workoutId)
          .delete();
      
      return true;
    } catch (e) {
      print('Error deleting custom workout: $e');
      return false;
    }
  }
  
  // Get a user's custom workouts
  Future<List<Workout>> getUserWorkouts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('user_custom_workouts')
          .doc(userId)
          .collection('workouts')
          .get();
      
      return snapshot.docs
          .map((doc) => Workout.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting user workouts: $e');
      return [];
    }
  }
}