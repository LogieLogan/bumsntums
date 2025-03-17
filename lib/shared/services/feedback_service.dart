// lib/shared/services/feedback_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../analytics/firebase_analytics_service.dart';

class FeedbackService {
  // Singleton pattern
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService();
  
  /// Submit user feedback to Firestore and log with Analytics
  Future<bool> submitFeedback({
    required String userId,
    required String type, // 'bug', 'feature', 'satisfaction'
    required String content,
    int? rating,
    String? category,
    String? screenName,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Create feedback document
      final feedback = {
        'userId': userId,
        'type': type,
        'content': content,
        'rating': rating,
        'category': category,
        'screenName': screenName,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': {
          'platform': defaultTargetPlatform.toString(),
        },
        'additionalData': additionalData,
      };
      
      // Remove null values
      feedback.removeWhere((key, value) => value == null);
      
      // Submit to Firestore
      await _firestore.collection('feedback').add(feedback);
      
      // Log event to Analytics
      await _analytics.logEvent(
        name: 'feedback_submitted',
        parameters: {
          'feedback_type': type,
          'screen_name': screenName ?? 'unknown',
          if (rating != null) 'rating': rating,
        },
      );
      
      return true;
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      return false;
    }
  }
  
  /// Submit a bug report with optional screenshot
  Future<bool> submitBugReport({
    required String userId,
    required String description,
    String? screenName,
    String? screenshotUrl,
    Map<String, dynamic>? technicalDetails,
  }) async {
    try {
      final additionalData = {
        'screenshot': screenshotUrl,
        'technical': technicalDetails,
      };
      
      return await submitFeedback(
        userId: userId,
        type: 'bug',
        content: description,
        screenName: screenName,
        additionalData: additionalData,
      );
    } catch (e) {
      debugPrint('Error submitting bug report: $e');
      return false;
    }
  }
  
  /// Submit user satisfaction rating (1-5)
  Future<bool> submitSatisfactionRating({
    required String userId,
    required int rating, // 1-5
    String? comment,
    String? featureName,
  }) async {
    assert(rating >= 1 && rating <= 5, 'Rating must be between 1 and 5');
    
    try {
      return await submitFeedback(
        userId: userId,
        type: 'satisfaction',
        content: comment ?? '',
        rating: rating,
        category: featureName,
      );
    } catch (e) {
      debugPrint('Error submitting satisfaction rating: $e');
      return false;
    }
  }
  
  /// Submit feature request
  Future<bool> submitFeatureRequest({
    required String userId,
    required String featureDescription,
  }) async {
    try {
      return await submitFeedback(
        userId: userId,
        type: 'feature',
        content: featureDescription,
      );
    } catch (e) {
      debugPrint('Error submitting feature request: $e');
      return false;
    }
  }
}