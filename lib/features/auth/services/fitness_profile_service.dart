// lib/features/auth/services/fitness_profile_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

class FitnessProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService();
  
  /// Get fitness profile data from Firestore
  /// Only fetches non-PII data that's safe to use with AI
  Future<Map<String, dynamic>> getFitnessProfileForAI(String userId) async {
    try {
      final docSnapshot = await _firestore.collection('fitness_profiles').doc(userId).get();
      
      if (!docSnapshot.exists) {
        throw Exception('Fitness profile not found');
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      
      // Extract only the fields that are safe for AI use
      final safeProfileData = {
        'fitnessLevel': data['fitnessLevel'],
        'goals': data['goals'],
        'bodyFocusAreas': data['bodyFocusAreas'] ?? [],
        'availableEquipment': data['availableEquipment'] ?? [],
        'preferredLocation': data['preferredLocation'],
        'workoutDurationMinutes': data['workoutDurationMinutes'],
        'weeklyWorkoutDays': data['weeklyWorkoutDays'],
        'healthConditions': data['healthConditions'] ?? [],
        'dietaryPreferences': data['dietaryPreferences'] ?? [],
      };
      
      _analytics.logEvent(
        name: 'ai_fetch_fitness_profile',
        parameters: {'user_id': userId},
      );
      
      return safeProfileData;
    } catch (e) {
      _analytics.logError(
        error: e.toString(),
        parameters: {'context': 'getFitnessProfileForAI', 'userId': userId},
      );
      rethrow;
    }
  }
}