// lib/shared/services/consent_management_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../analytics/firebase_analytics_service.dart';

class ConsentManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService();
  
  /// Record user consent for data processing
  Future<void> recordConsentGiven(
    String userId,
    Map<String, bool> consentOptions,
    int privacyPolicyVersion,
    int termsVersion
  ) async {
    try {
      await _firestore.collection('user_consents').doc(userId).set({
        'userId': userId,
        'consentOptions': consentOptions,
        'privacyPolicyVersion': privacyPolicyVersion,
        'termsVersion': termsVersion,
        'recordedAt': Timestamp.now(),
        'deviceInfo': await _getDeviceInfo(),
      });
      
      // Store consent status locally for quick access
      final prefs = await SharedPreferences.getInstance();
      for (var option in consentOptions.entries) {
        await prefs.setBool('consent_${option.key}', option.value);
      }
      
      _analytics.logEvent(
        name: 'user_consent_recorded',
        parameters: {
          'user_id': userId,
          'privacy_policy_version': privacyPolicyVersion,
          'terms_version': termsVersion,
        },
      );
    } catch (e) {
      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'recordConsentGiven',
          'userId': userId,
        },
      );
      rethrow;
    }
  }
  
  /// Update a specific consent option
  Future<void> updateConsentOption(
    String userId,
    String consentKey,
    bool value
  ) async {
    try {
      await _firestore.collection('user_consents').doc(userId)
          .update({
            'consentOptions.$consentKey': value,
            'updatedAt': Timestamp.now()
          });
      
      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('consent_$consentKey', value);
      
      _analytics.logEvent(
        name: 'user_consent_updated',
        parameters: {
          'user_id': userId,
          'consent_key': consentKey,
          'value': value,
        },
      );
    } catch (e) {
      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'updateConsentOption',
          'userId': userId,
          'consentKey': consentKey,
        },
      );
      rethrow;
    }
  }
  
  /// Check if a new version of privacy policy or terms requires new consent
  Future<bool> needsNewConsent(String userId, int currentPrivacyVersion, int currentTermsVersion) async {
    try {
      final doc = await _firestore.collection('user_consents').doc(userId).get();
      if (!doc.exists) {
        return true;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      final storedPrivacyVersion = data['privacyPolicyVersion'] as int? ?? 0;
      final storedTermsVersion = data['termsVersion'] as int? ?? 0;
      
      return storedPrivacyVersion < currentPrivacyVersion || 
             storedTermsVersion < currentTermsVersion;
    } catch (e) {
      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'needsNewConsent',
          'userId': userId,
        },
      );
      return true; // On error, request consent to be safe
    }
  }
  
  /// Check if user has given consent for a specific purpose
  Future<bool> hasConsent(String consentKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('consent_$consentKey') ?? false;
    } catch (e) {
      _analytics.logError(
        error: e.toString(),
        parameters: {'context': 'hasConsent', 'consentKey': consentKey},
      );
      return false; // Default to no consent on error
    }
  }
  
  /// Get device information for consent records
  Future<Map<String, String>> _getDeviceInfo() async {
    // This would normally use a device info plugin
    // For now, returning placeholder data
    return {
      'platform': 'iOS',
      'appVersion': '1.0.0',
    };
  }
  
  /// Get default consent options map
  Map<String, bool> getDefaultConsentOptions() {
    return {
      'essential': true, // Essential data processing (cannot be opted out)
      'analytics': false, // Analytics and usage tracking
      'personalization': false, // Personalized recommendations
      'marketing': false, // Marketing communications
    };
  }
}