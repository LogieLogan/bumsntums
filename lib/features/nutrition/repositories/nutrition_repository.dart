// lib/features/nutrition/repositories/nutrition_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/food_log_entry.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/providers/firebase_providers.dart'; // Provides firestoreProvider, firebaseAuthProvider
import '../../../shared/providers/analytics_provider.dart'; // Provides analyticsServiceProvider

class NutritionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AnalyticsService _analyticsService;

  // Private constructor
  NutritionRepository._({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required AnalyticsService analyticsService,
  })  : _firestore = firestore,
        _auth = auth,
        _analyticsService = analyticsService;

  // Helper to get the current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Helper to get the collection reference for a user's log entries
  CollectionReference<Map<String, dynamic>> _entriesCollectionRef(String userId) {
    return _firestore.collection('food_logs').doc(userId).collection('entries');
  }

  // Add a new food log entry
  Future<void> addFoodLogEntry(FoodLogEntry entry) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');
    // Ensure the entry's userId matches the current user
    if (entry.userId != userId) throw Exception('Entry UserID mismatch');

    try {
      await _entriesCollectionRef(userId).doc(entry.id).set(entry.toMap());
      _analyticsService.logEvent(name: 'food_log_entry_added', parameters: {
        'food_item_id': entry.foodItemId,
        'meal_type': entry.mealTypeString,
        'calories': entry.calculatedCalories,
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error adding food log entry $entry.id: $e");
      }
      _analyticsService.logError(
        error: "Failed to add food log entry: $e",
        // stackTrace: stackTrace, // Assuming logError doesn't take stackTrace
        parameters: {'user_id': userId, 'entry_id': entry.id},
      );
      // Consider using CrashReportingService here as well if available
      // ref.read(crashReportingServiceProvider).recordError(e);
      rethrow; // Rethrow to allow UI to handle error
    }
  }

  // Get all food log entries for a specific day
  Future<List<FoodLogEntry>> getFoodLogEntriesForDay(String userId, DateTime date) async {
    // Ensure the correct user is being queried (optional, depends on access rules)
    final currentUserId = _userId;
    if (currentUserId == null || currentUserId != userId) {
       throw Exception('Authentication error or UserID mismatch');
    }

    // Define the start and end of the day
    final startOfDay = Timestamp.fromDate(DateTime(date.year, date.month, date.day, 0, 0, 0));
    final endOfDay = Timestamp.fromDate(DateTime(date.year, date.month, date.day, 23, 59, 59, 999));

    try {
      final querySnapshot = await _entriesCollectionRef(userId)
          .where('loggedAt', isGreaterThanOrEqualTo: startOfDay)
          .where('loggedAt', isLessThanOrEqualTo: endOfDay)
          .orderBy('loggedAt', descending: false) // Order chronologically for the day
          .get();

      final entries = querySnapshot.docs
          .map((doc) => FoodLogEntry.fromMap(doc.data(), doc.id))
          .toList();

       _analyticsService.logEvent(name: 'food_log_fetched', parameters: {
          'date': DateFormat('yyyy-MM-dd').format(date), // Use intl package if needed
          'entry_count': entries.length,
       });

      return entries;
    } catch (e) {
       if (kDebugMode) {
          print("Error fetching food log entries for $userId on $date: $e");
       }
      _analyticsService.logError(
        error: "Failed to fetch food log entries: $e",
        // stackTrace: stackTrace,
         parameters: {'user_id': userId, 'date': date.toIso8601String()},
      );
       // ref.read(crashReportingServiceProvider).recordError(e);
      rethrow;
    }
  }

  // Update an existing food log entry
  Future<void> updateFoodLogEntry(FoodLogEntry entry) async {
    final userId = _userId;
    if (userId == null) throw Exception('User not authenticated');
    if (entry.userId != userId) throw Exception('Entry UserID mismatch');

    try {
      await _entriesCollectionRef(userId).doc(entry.id).update(entry.toMap());
       _analyticsService.logEvent(name: 'food_log_entry_updated', parameters: {
         'entry_id': entry.id,
         'food_item_id': entry.foodItemId,
       });
    } catch (e) {
       if (kDebugMode) {
          print("Error updating food log entry ${entry.id}: $e");
       }
      _analyticsService.logError(
        error: "Failed to update food log entry: $e",
        // stackTrace: stackTrace,
         parameters: {'user_id': userId, 'entry_id': entry.id},
      );
       // ref.read(crashReportingServiceProvider).recordError(e);
      rethrow;
    }
  }

  // Delete a food log entry by its ID
  Future<void> deleteFoodLogEntry(String userId, String entryId) async {
     // Ensure the correct user is being targeted
    final currentUserId = _userId;
    if (currentUserId == null || currentUserId != userId) {
       throw Exception('Authentication error or UserID mismatch');
    }

    try {
      await _entriesCollectionRef(userId).doc(entryId).delete();
       _analyticsService.logEvent(name: 'food_log_entry_deleted', parameters: {
         'entry_id': entryId,
       });
    } catch (e) {
       if (kDebugMode) {
          print("Error deleting food log entry $entryId: $e");
       }
       _analyticsService.logError(
         error: "Failed to delete food log entry: $e",
         // stackTrace: stackTrace,
         parameters: {'user_id': userId, 'entry_id': entryId},
       );
       // ref.read(crashReportingServiceProvider).recordError(e);
      rethrow;
    }
  }
}

// --- Riverpod Provider ---

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  // Read dependencies from shared providers
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final analytics = ref.watch(analyticsServiceProvider);

  return NutritionRepository._(
    firestore: firestore,
    auth: auth,
    analyticsService: analytics,
  );
});