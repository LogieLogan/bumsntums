// lib/features/ai/services/context_service.dart
import 'package:flutter/foundation.dart';
import '../models/ai_context.dart';
import '../../auth/services/fitness_profile_service.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

class ContextService {
  final FitnessProfileService _fitnessProfileService;
  final AnalyticsService _analytics;
  
  // Cache for user profile data to avoid frequent fetches
  final Map<String, Map<String, dynamic>> _profileCache = {};
  
  ContextService({
    required FitnessProfileService fitnessProfileService,
    AnalyticsService? analytics,
  }) : _fitnessProfileService = fitnessProfileService,
       _analytics = analytics ?? AnalyticsService();
  
  /// Build a complete context for AI interactions
  Future<AIContext> buildContext({
    required String userId,
    Map<String, dynamic> sessionData = const {},
    Map<String, dynamic> featureData = const {},
  }) async {
    try {
      // Get profile data (from cache if available)
      final profileData = await _getProfileData(userId);
      
      debugPrint('Building AI context with profile data: ${profileData.keys}');
      
      return AIContext(
        profileData: profileData,
        sessionData: sessionData,
        featureData: featureData,
      );
    } catch (e) {
      debugPrint('Error building AI context: $e');
      _analytics.logError(
        error: e.toString(),
        parameters: {'context': 'ContextService.buildContext', 'userId': userId},
      );
      
      // Return empty context as fallback
      return AIContext(
        profileData: {'fitnessLevel': 'beginner'},
        sessionData: sessionData,
        featureData: featureData,
      );
    }
  }
  
  /// Get profile data with caching
  Future<Map<String, dynamic>> _getProfileData(String userId) async {
    // Check cache first (only if less than 5 minutes old)
    if (_profileCache.containsKey(userId)) {
      final cachedData = _profileCache[userId]!;
      final cacheTimestamp = cachedData['_cacheTimestamp'] as int?;
      
      if (cacheTimestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTimestamp;
        if (cacheAge < 5 * 60 * 1000) { // Less than 5 minutes old
          return Map<String, dynamic>.from(cachedData)
            ..remove('_cacheTimestamp');
        }
      }
    }
    
    // Fetch fresh data if not in cache or cache is stale
    final profileData = await _fitnessProfileService.getFitnessProfileForAI(userId);
    
    // Add cache timestamp and store in cache
    final dataWithTimestamp = Map<String, dynamic>.from(profileData)
      ..['_cacheTimestamp'] = DateTime.now().millisecondsSinceEpoch;
    _profileCache[userId] = dataWithTimestamp;
    
    return profileData;
  }
  
  /// Update session data in context
  AIContext updateSessionData(AIContext context, Map<String, dynamic> newData) {
    return context.updateSessionData(newData);
  }
  
  /// Update feature-specific data in context
  AIContext updateFeatureData(AIContext context, Map<String, dynamic> newData) {
    return context.updateFeatureData(newData);
  }
  
  /// Refresh profile data in context (force bypass cache)
  Future<AIContext> refreshProfileData(AIContext context, String userId) async {
    try {
      // Remove from cache to force refresh
      _profileCache.remove(userId);
      
      // Fetch fresh data
      final profileData = await _fitnessProfileService.getFitnessProfileForAI(userId);
      
      // Cache the new data
      final dataWithTimestamp = Map<String, dynamic>.from(profileData)
        ..['_cacheTimestamp'] = DateTime.now().millisecondsSinceEpoch;
      _profileCache[userId] = dataWithTimestamp;
      
      return context.copyWith(profileData: profileData);
    } catch (e) {
      debugPrint('Error refreshing profile data: $e');
      _analytics.logError(
        error: e.toString(),
        parameters: {'context': 'ContextService.refreshProfileData', 'userId': userId},
      );
      return context;
    }
  }
  
  /// Extract context for a specific feature
  Map<String, dynamic> getContextForFeature(
    AIContext context, 
    String featureId,
    {List<String> requiredProfileFields = const []}
  ) {
    final result = <String, dynamic>{};
    
    // Add required profile fields
    for (final field in requiredProfileFields) {
      if (context.profileData.containsKey(field)) {
        result[field] = context.profileData[field];
      }
    }
    
    // Add feature-specific data
    if (context.featureData.containsKey(featureId)) {
      result.addAll(context.featureData[featureId] as Map<String, dynamic>);
    }
    
    // Add session data
    result.addAll(context.sessionData);
    
    return result;
  }
  
  /// Clear cached data for testing or memory management
  void clearCache() {
    _profileCache.clear();
  }
}