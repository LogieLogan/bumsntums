// lib/shared/services/gdpr_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../analytics/firebase_analytics_service.dart';

class GdprService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AnalyticsService _analytics = AnalyticsService();

  /// Export all user data as a JSON file
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      _analytics.logEvent(
        name: 'user_data_export_requested',
        parameters: {'user_id': userId},
      );

      // Map to store all user data
      final Map<String, dynamic> userData = {};

      // Get personal information
      final personalInfo = await _firestore
          .collection('users_personal_info')
          .doc(userId)
          .get();
      if (personalInfo.exists) {
        userData['personalInfo'] = personalInfo.data();
      }

      // Get fitness profile
      final fitnessProfile = await _firestore
          .collection('fitness_profiles')
          .doc(userId)
          .get();
      if (fitnessProfile.exists) {
        userData['fitnessProfile'] = fitnessProfile.data();
      }

      // Get public profile
      final publicProfile = await _firestore
          .collection('user_profiles_public')
          .doc(userId)
          .get();
      if (publicProfile.exists) {
        userData['publicProfile'] = publicProfile.data();
      }

      // Get food scans
      final foodScans = await _firestore
          .collection('food_scans')
          .doc(userId)
          .collection('scans')
          .get();
      userData['foodScans'] = foodScans.docs.map((doc) => doc.data()).toList();

      // Get food diary entries
      final foodDiaryQuery = await _firestore
          .collection('food_diary')
          .doc(userId)
          .collection('entries')
          .get();
      userData['foodDiary'] = foodDiaryQuery.docs.map((doc) => doc.data()).toList();

      // Get workout logs
      final workoutLogs = await _firestore
          .collection('workout_logs')
          .doc(userId)
          .collection('logs')
          .get();
      userData['workoutLogs'] = workoutLogs.docs.map((doc) => doc.data()).toList();

      // Get document acceptances
      final acceptances = await _firestore
          .collection('user_document_acceptances')
          .where('userId', isEqualTo: userId)
          .get();
      userData['documentAcceptances'] = acceptances.docs.map((doc) => doc.data()).toList();

      _analytics.logEvent(
        name: 'user_data_export_completed',
        parameters: {'user_id': userId},
      );

      return userData;
    } catch (e) {
      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'exportUserData',
          'userId': userId,
        },
      );
      rethrow;
    }
  }

  /// Delete all user data (GDPR right to be forgotten)
  Future<void> deleteUserData(String userId) async {
    try {
      _analytics.logEvent(
        name: 'user_data_deletion_requested',
        parameters: {'user_id': userId},
      );

      // Delete personal info
      await _firestore.collection('users_personal_info').doc(userId).delete();

      // Delete fitness profile
      await _firestore.collection('fitness_profiles').doc(userId).delete();

      // Delete public profile
      await _firestore.collection('user_profiles_public').doc(userId).delete();

      // Delete food scans
      final foodScansRef = _firestore.collection('food_scans').doc(userId).collection('scans');
      await _deleteCollection(foodScansRef);

      // Delete food diary entries
      final foodDiaryRef = _firestore.collection('food_diary').doc(userId).collection('entries');
      await _deleteCollection(foodDiaryRef);

      // Delete workout logs
      final workoutLogsRef = _firestore.collection('workout_logs').doc(userId).collection('logs');
      await _deleteCollection(workoutLogsRef);

      // Delete document acceptances
      final acceptancesQuery = await _firestore
          .collection('user_document_acceptances')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in acceptancesQuery.docs) {
        await doc.reference.delete();
      }

      // Delete storage files
      final storageRef = _storage.ref().child('user_assets/$userId');
      try {
        final listResult = await storageRef.listAll();
        for (var item in listResult.items) {
          await item.delete();
        }
        for (var prefix in listResult.prefixes) {
          await _deleteStorageFolder(prefix);
        }
      } catch (e) {
        // Storage might not exist, continue
      }

      // Finally, delete the Auth account
      final user = _auth.currentUser;
      if (user != null && user.uid == userId) {
        await user.delete();
      }

      _analytics.logEvent(
        name: 'user_data_deletion_completed',
        parameters: {'user_id': userId},
      );
    } catch (e) {
      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'deleteUserData',
          'userId': userId,
        },
      );
      rethrow;
    }
  }

  /// Helper method to delete a collection
  Future<void> _deleteCollection(CollectionReference collectionRef) async {
    final snapshot = await collectionRef.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// Helper method to recursively delete a storage folder
  Future<void> _deleteStorageFolder(Reference reference) async {
    final listResult = await reference.listAll();
    for (var item in listResult.items) {
      await item.delete();
    }
    for (var prefix in listResult.prefixes) {
      await _deleteStorageFolder(prefix);
    }
  }
}