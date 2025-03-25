// lib/features/workouts/repositories/custom_workout_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

class CustomWorkoutRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService();

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

      // Log the save event
      _analytics.logEvent(
        name: 'custom_workout_saved',
        parameters: {
          'workout_id': workout.id,
          'is_template': workout.isTemplate ? '1' : '0',
        },
      );

      print('Custom workout saved successfully');
      return true;
    } catch (e) {
      print('Error saving custom workout: $e');
      return false;
    }
  }

  // Save a workout template
  Future<bool> saveWorkoutTemplate(String userId, Workout template) async {
    try {
      // Ensure the template flag is set
      final workoutTemplate = template.copyWith(isTemplate: true);

      // Save to user_workout_templates/{userId}/templates/{templateId}
      await _firestore
          .collection('user_workout_templates')
          .doc(userId)
          .collection('templates')
          .doc(workoutTemplate.id)
          .set(workoutTemplate.toMap());

      // Log the template save event
      _analytics.logEvent(
        name: 'workout_template_saved',
        parameters: {'template_id': workoutTemplate.id},
      );

      return true;
    } catch (e) {
      print('Error saving workout template: $e');
      return false;
    }
  }

  // Save a new version of a workout
  Future<bool> saveWorkoutVersion(
    String userId,
    Workout workout,
    String versionNotes,
  ) async {
    try {
      // Create a timestamp for the version
      final now = DateTime.now();
      final versionId = '${workout.id}-v${now.millisecondsSinceEpoch}';

      // Create the new version with reference to previous version
      final newVersion = workout.copyWith(
        id: versionId,
        previousVersionId: workout.id,
        versionNotes: versionNotes,
        createdAt: now,
      );

      // Save to user_workout_versions/{userId}/workouts/{workoutId}/versions/{versionId}
      await _firestore
          .collection('user_workout_versions')
          .doc(userId)
          .collection('workouts')
          .doc(workout.id)
          .collection('versions')
          .doc(versionId)
          .set(newVersion.toMap());

      // Log the version save event
      _analytics.logEvent(
        name: 'workout_version_saved',
        parameters: {'workout_id': workout.id, 'version_id': versionId},
      );

      return true;
    } catch (e) {
      print('Error saving workout version: $e');
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

      // Also delete from favorites if it exists
      try {
        await _firestore
            .collection('user_workout_favorites')
            .doc(userId)
            .collection('favorites')
            .doc(workoutId)
            .delete();
      } catch (e) {
        // It's ok if this fails (not in favorites)
        print('Workout was not in favorites or error: $e');
      }

      // Log the delete event
      _analytics.logEvent(
        name: 'custom_workout_deleted',
        parameters: {'workout_id': workoutId},
      );

      return true;
    } catch (e) {
      print('Error deleting custom workout: $e');
      return false;
    }
  }

  // Delete a workout template
  Future<bool> deleteWorkoutTemplate(String userId, String templateId) async {
    try {
      // Delete from user_workout_templates/{userId}/templates/{templateId}
      await _firestore
          .collection('user_workout_templates')
          .doc(userId)
          .collection('templates')
          .doc(templateId)
          .delete();

      // Log the template delete event
      _analytics.logEvent(
        name: 'workout_template_deleted',
        parameters: {'template_id': templateId},
      );

      return true;
    } catch (e) {
      print('Error deleting workout template: $e');
      return false;
    }
  }

  // Get a user's custom workouts
  Future<List<Workout>> getUserWorkouts(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('user_custom_workouts')
              .doc(userId)
              .collection('workouts')
              .where('isTemplate', isEqualTo: false)
              .get();

      return snapshot.docs.map((doc) => Workout.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error getting user workouts: $e');
      return [];
    }
  }

  // Get a user's workout templates
  Future<List<Workout>> getUserWorkoutTemplates(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('user_workout_templates')
              .doc(userId)
              .collection('templates')
              .get();

      return snapshot.docs.map((doc) => Workout.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error getting user workout templates: $e');
      return [];
    }
  }

  // Get versions of a specific workout
  Future<List<Workout>> getWorkoutVersions(
    String userId,
    String workoutId,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection('user_workout_versions')
              .doc(userId)
              .collection('workouts')
              .doc(workoutId)
              .collection('versions')
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) => Workout.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error getting workout versions: $e');
      return [];
    }
  }

  // Increment the "used" count for a template
  Future<bool> incrementTemplateUsage(String userId, String templateId) async {
    try {
      await _firestore
          .collection('user_workout_templates')
          .doc(userId)
          .collection('templates')
          .doc(templateId)
          .update({
            'timesUsed': FieldValue.increment(1),
            'lastUsed': FieldValue.serverTimestamp(),
          });

      return true;
    } catch (e) {
      print('Error incrementing template usage: $e');
      return false;
    }
  }

  // Convert a regular workout to a template
  Future<bool> convertWorkoutToTemplate(String userId, Workout workout) async {
    try {
      // Create template version of the workout
      final template = workout.asTemplate();

      // Save as template
      final success = await saveWorkoutTemplate(userId, template);

      // Log the conversion
      _analytics.logEvent(
        name: 'workout_converted_to_template',
        parameters: {'workout_id': workout.id, 'template_id': template.id},
      );

      return success;
    } catch (e) {
      print('Error converting workout to template: $e');
      return false;
    }
  }

  // Create a workout from a template
  Future<Workout?> createWorkoutFromTemplate(
    String userId,
    Workout template,
  ) async {
    try {
      // Generate a new ID for the workout
      final newId = 'workout-${DateTime.now().millisecondsSinceEpoch}';

      // Create a new workout from the template
      final newWorkout = template.copyWith(
        id: newId,
        isTemplate: false,
        parentTemplateId: template.id,
        createdAt: DateTime.now(),
      );

      // Save the new workout
      final success = await saveCustomWorkout(userId, newWorkout);

      // Increment template usage count
      if (success) {
        await incrementTemplateUsage(userId, template.id);

        // Log the creation
        _analytics.logEvent(
          name: 'workout_created_from_template',
          parameters: {'template_id': template.id, 'workout_id': newId},
        );

        return newWorkout;
      }

      return null;
    } catch (e) {
      print('Error creating workout from template: $e');
      return null;
    }
  }
}

// Providers
final customWorkoutsStreamProvider =
    StreamProvider.family<List<Workout>, String>((ref, userId) {
      return FirebaseFirestore.instance
          .collection('user_custom_workouts')
          .doc(userId)
          .collection('workouts')
          .where('isTemplate', isEqualTo: false)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => Workout.fromMap(doc.data()))
                    .toList(),
          );
    });

// Provider for workout templates
final workoutTemplatesStreamProvider =
    StreamProvider.family<List<Workout>, String>((ref, userId) {
      return FirebaseFirestore.instance
          .collection('user_workout_templates')
          .doc(userId)
          .collection('templates')
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => Workout.fromMap(doc.data()))
                    .toList(),
          );
    });

// Provider for workout versions
final workoutVersionsStreamProvider = StreamProvider.family<
  List<Workout>,
  ({String userId, String workoutId})
>((ref, params) {
  return FirebaseFirestore.instance
      .collection('user_workout_versions')
      .doc(params.userId)
      .collection('workouts')
      .doc(params.workoutId)
      .collection('versions')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => Workout.fromMap(doc.data())).toList(),
      );
});
