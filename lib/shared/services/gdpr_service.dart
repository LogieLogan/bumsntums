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

  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      _analytics.logEvent(
        name: 'user_data_export_requested',
        parameters: {'user_id': userId},
      );

      // Map to store all user data
      final Map<String, dynamic> userData = {};

      // Use a transaction to ensure consistent read
      await _firestore.runTransaction((transaction) async {
        // Get personal information
        final personalInfoDoc = await transaction.get(
          _firestore.collection('users_personal_info').doc(userId),
        );
        if (personalInfoDoc.exists) {
          userData['personalInfo'] = _convertToSerializable(
            personalInfoDoc.data(),
          );
        }

        // Get fitness profile
        final fitnessProfileDoc = await transaction.get(
          _firestore.collection('fitness_profiles').doc(userId),
        );
        if (fitnessProfileDoc.exists) {
          userData['fitnessProfile'] = _convertToSerializable(
            fitnessProfileDoc.data(),
          );
        }

        // Get public profile
        final publicProfileDoc = await transaction.get(
          _firestore.collection('user_profiles_public').doc(userId),
        );
        if (publicProfileDoc.exists) {
          userData['publicProfile'] = _convertToSerializable(
            publicProfileDoc.data(),
          );
        }

        // For collections, we need to get them outside the transaction
        return;
      });

      // Get collections outside the transaction
      try {
        // Get food scans
        final foodScans =
            await _firestore
                .collection('food_scans')
                .doc(userId)
                .collection('scans')
                .get();
        userData['foodScans'] =
            foodScans.docs
                .map((doc) => _convertToSerializable(doc.data()))
                .toList();
      } catch (e) {
        _analytics.logError(
          error: e.toString(),
          parameters: {
            'context': 'exportUserData - foodScans',
            'userId': userId,
          },
        );
        userData['foodScans'] = [];
      }

      try {
        // Get food diary entries
        final foodDiaryQuery =
            await _firestore
                .collection('food_diary')
                .doc(userId)
                .collection('entries')
                .get();
        userData['foodDiary'] =
            foodDiaryQuery.docs
                .map((doc) => _convertToSerializable(doc.data()))
                .toList();
      } catch (e) {
        _analytics.logError(
          error: e.toString(),
          parameters: {
            'context': 'exportUserData - foodDiary',
            'userId': userId,
          },
        );
        userData['foodDiary'] = [];
      }

      try {
        // Get workout logs
        final workoutLogs =
            await _firestore
                .collection('workout_logs')
                .doc(userId)
                .collection('logs')
                .get();
        userData['workoutLogs'] =
            workoutLogs.docs
                .map((doc) => _convertToSerializable(doc.data()))
                .toList();
      } catch (e) {
        _analytics.logError(
          error: e.toString(),
          parameters: {
            'context': 'exportUserData - workoutLogs',
            'userId': userId,
          },
        );
        userData['workoutLogs'] = [];
      }

      try {
        // Get document acceptances
        final acceptances =
            await _firestore
                .collection('user_document_acceptances')
                .where('userId', isEqualTo: userId)
                .get();
        userData['documentAcceptances'] =
            acceptances.docs
                .map((doc) => _convertToSerializable(doc.data()))
                .toList();
      } catch (e) {
        _analytics.logError(
          error: e.toString(),
          parameters: {
            'context': 'exportUserData - acceptances',
            'userId': userId,
          },
        );
        userData['documentAcceptances'] = [];
      }

      _analytics.logEvent(
        name: 'user_data_export_completed',
        parameters: {'user_id': userId},
      );

      // Add metadata
      userData['metadata'] = {
        'exportDate': DateTime.now().toIso8601String(),
        'userId': userId,
        'appVersion': '1.0.0',
      };

      return userData;
    } catch (e) {
      _analytics.logError(
        error: e.toString(),
        parameters: {'context': 'exportUserData', 'userId': userId},
      );
      throw Exception('Error exporting data: ${e.toString()}');
    }
  }

  /// Delete all user data (GDPR right to be forgotten)
  Future<void> deleteUserData(String userId) async {
    try {
      _analytics.logEvent(
        name: 'user_data_deletion_requested',
        parameters: {'user_id': userId},
      );

      // Map of collections to delete with error handling for each
      final collectionsToDelete = {
        'users_personal_info': _firestore
            .collection('users_personal_info')
            .doc(userId),
        'fitness_profiles': _firestore
            .collection('fitness_profiles')
            .doc(userId),
        'user_profiles_public': _firestore
            .collection('user_profiles_public')
            .doc(userId),
      };

      // Delete each document, with individual error handling
      for (var entry in collectionsToDelete.entries) {
        try {
          await entry.value.delete();
        } catch (e) {
          _analytics.logError(
            error: e.toString(),
            parameters: {
              'context': 'deleteUserData',
              'userId': userId,
              'collection': entry.key,
            },
          );
          // Continue with other deletions even if one fails
        }
      }

      // Collections with subcollections that need batch deletion
      final subCollectionsToDelete = {
        'food_scans': _firestore
            .collection('food_scans')
            .doc(userId)
            .collection('scans'),
        'food_diary': _firestore
            .collection('food_diary')
            .doc(userId)
            .collection('entries'),
        'workout_logs': _firestore
            .collection('workout_logs')
            .doc(userId)
            .collection('logs'),
      };

      // Delete subcollections with individual error handling
      for (var entry in subCollectionsToDelete.entries) {
        try {
          await _deleteCollection(entry.value);
        } catch (e) {
          _analytics.logError(
            error: e.toString(),
            parameters: {
              'context': 'deleteUserData',
              'userId': userId,
              'subCollection': entry.key,
            },
          );
          // Continue with other deletions even if one fails
        }
      }

      // Delete document acceptances
      try {
        final acceptancesQuery =
            await _firestore
                .collection('user_document_acceptances')
                .where('userId', isEqualTo: userId)
                .get();

        for (var doc in acceptancesQuery.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        _analytics.logError(
          error: e.toString(),
          parameters: {
            'context': 'deleteUserData - acceptances',
            'userId': userId,
          },
        );
      }

      // Delete user consents if they exist
      try {
        await _firestore.collection('user_consents').doc(userId).delete();
      } catch (e) {
        _analytics.logError(
          error: e.toString(),
          parameters: {
            'context': 'deleteUserData - consents',
            'userId': userId,
          },
        );
      }

      // Delete storage files
      try {
        final storageRef = _storage.ref().child('user_assets/$userId');
        final listResult = await storageRef.listAll();
        for (var item in listResult.items) {
          await item.delete();
        }
        for (var prefix in listResult.prefixes) {
          await _deleteStorageFolder(prefix);
        }
      } catch (e) {
        // Storage might not exist, continue
        _analytics.logError(
          error: e.toString(),
          parameters: {'context': 'deleteUserData - storage', 'userId': userId},
        );
      }

      // Finally, delete the Auth account
      try {
        final user = _auth.currentUser;
        if (user != null && user.uid == userId) {
          await user.delete();
        }
      } catch (e) {
        _analytics.logError(
          error: e.toString(),
          parameters: {
            'context': 'deleteUserData - auth account',
            'userId': userId,
          },
        );
        rethrow; // Only rethrow for auth deletion, as this is critical
      }

      _analytics.logEvent(
        name: 'user_data_deletion_completed',
        parameters: {'user_id': userId},
      );
    } catch (e) {
      _analytics.logError(
        error: e.toString(),
        parameters: {'context': 'deleteUserData', 'userId': userId},
      );
      rethrow;
    }
  }

  /// Delete all user data except authentication
  Future<void> deleteUserDataWithoutAuth(String userId) async {
    try {
      _analytics.logEvent(
        name: 'user_data_deletion_requested',
        parameters: {'user_id': userId},
      );

      // Delete personal info
      try {
        await _firestore.collection('users_personal_info').doc(userId).delete();
      } catch (e) {
        _analytics.logError(
          error: e.toString(),
          parameters: {
            'context': 'deleteUserData - personal info',
            'userId': userId,
          },
        );
      }

      // Delete fitness profile
      try {
        await _firestore.collection('fitness_profiles').doc(userId).delete();
      } catch (e) {
        _analytics.logError(
          error: e.toString(),
          parameters: {
            'context': 'deleteUserData - fitness profile',
            'userId': userId,
          },
        );
      }

      // Delete public profile
      try {
        await _firestore
            .collection('user_profiles_public')
            .doc(userId)
            .delete();
      } catch (e) {
        _analytics.logError(
          error: e.toString(),
          parameters: {
            'context': 'deleteUserData - public profile',
            'userId': userId,
          },
        );
      }

      // Delete food scans
      try {
        final foodScansRef = _firestore
            .collection('food_scans')
            .doc(userId)
            .collection('scans');
        await _deleteCollection(foodScansRef);
      } catch (e) {
        _analytics.logError(
          error: e.toString(),
          parameters: {
            'context': 'deleteUserData - food scans',
            'userId': userId,
          },
        );
      }

      // Delete food diary entries
      try {
        final foodDiaryRef = _firestore
            .collection('food_diary')
            .doc(userId)
            .collection('entries');
        await _deleteCollection(foodDiaryRef);
      } catch (e) {
        _analytics.logError(
          error: e.toString(),
          parameters: {
            'context': 'deleteUserData - food diary',
            'userId': userId,
          },
        );
      }

      // Delete workout logs
      try {
        final workoutLogsRef = _firestore
            .collection('workout_logs')
            .doc(userId)
            .collection('logs');
        await _deleteCollection(workoutLogsRef);
      } catch (e) {
        _analytics.logError(
          error: e.toString(),
          parameters: {
            'context': 'deleteUserData - workout logs',
            'userId': userId,
          },
        );
      }

      // Delete document acceptances
      try {
        final acceptancesQuery =
            await _firestore
                .collection('user_document_acceptances')
                .where('userId', isEqualTo: userId)
                .get();

        for (var doc in acceptancesQuery.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        _analytics.logError(
          error: e.toString(),
          parameters: {
            'context': 'deleteUserData - acceptances',
            'userId': userId,
          },
        );
      }

      // Delete storage files
      try {
        final storageRef = _storage.ref().child('user_assets/$userId');
        final listResult = await storageRef.listAll();
        for (var item in listResult.items) {
          await item.delete();
        }
        for (var prefix in listResult.prefixes) {
          await _deleteStorageFolder(prefix);
        }
      } catch (e) {
        // Storage might not exist, continue
        _analytics.logError(
          error: e.toString(),
          parameters: {'context': 'deleteUserData - storage', 'userId': userId},
        );
      }

      _analytics.logEvent(
        name: 'user_data_deletion_completed',
        parameters: {'user_id': userId},
      );
    } catch (e) {
      _analytics.logError(
        error: e.toString(),
        parameters: {'context': 'deleteUserDataWithoutAuth', 'userId': userId},
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

  Map<String, dynamic> _convertToSerializable(Map<String, dynamic>? data) {
    if (data == null) return {};

    final result = Map<String, dynamic>.from(data);

    // Recursively process the map to convert timestamps and other non-serializable types
    result.forEach((key, value) {
      if (value is Timestamp) {
        // Convert Timestamp to ISO string
        result[key] = value.toDate().toIso8601String();
      } else if (value is Map) {
        // Recursively convert nested maps
        result[key] = _convertToSerializable(Map<String, dynamic>.from(value));
      } else if (value is List) {
        // Convert lists that might contain timestamps
        result[key] = _convertList(value);
      }
    });

    return result;
  }

  /// Convert List items to serializable format
  List _convertList(List items) {
    return items.map((item) {
      if (item is Timestamp) {
        return item.toDate().toIso8601String();
      } else if (item is Map) {
        return _convertToSerializable(Map<String, dynamic>.from(item));
      } else if (item is List) {
        return _convertList(item);
      } else {
        return item;
      }
    }).toList();
  }
}
