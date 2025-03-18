// lib/shared/services/legal_document_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/legal_document.dart';
import '../../shared/analytics/firebase_analytics_service.dart';

class LegalDocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService();

  /// Collection reference for legal documents
  CollectionReference get _legalDocumentsCollection =>
      _firestore.collection('legal_documents');

  Future<LegalDocument> getLegalDocument(LegalDocumentType type) async {
    try {
      final docSnapshot =
          await _legalDocumentsCollection.doc(type.documentId).get();

      if (docSnapshot.exists) {
        // Check if the content is meaningful (not just a placeholder)
        final data = docSnapshot.data() as Map<String, dynamic>;
        final content = data['content'] as String? ?? '';

        // If content is too short or just a placeholder, use default content locally
        // without trying to update Firestore
        if (content.length < 50) {
          // Return a local document with default content
          return LegalDocument(
            id: type.documentId,
            title: type.title,
            content: _getDefaultContent(type),
            version: data['version'] ?? 1,
            lastUpdated:
                (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isActive: data['isActive'] ?? true,
          );
        }

        // If content is substantial, use the Firestore document
        return LegalDocument.fromFirestore(docSnapshot);
      }

      // If document doesn't exist, we can't create it (no admin privileges)
      // Just return a local default document
      return LegalDocument(
        id: type.documentId,
        title: type.title,
        content: _getDefaultContent(type),
        version: 1,
        lastUpdated: DateTime.now(),
        isActive: true,
      );
    } catch (e) {
      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'getLegalDocument',
          'documentType': type.documentId,
        },
      );

      // Return default document even in case of error
      return LegalDocument(
        id: type.documentId,
        title: type.title,
        content: _getDefaultContent(type),
        version: 1,
        lastUpdated: DateTime.now(),
        isActive: true,
      );
    }
  }

  /// Create default legal documents if they don't exist
  Future<void> _createDefaultLegalDocument(LegalDocumentType type) async {
    final defaultDocument = LegalDocument(
      id: type.documentId,
      title: type.title,
      content: _getDefaultContent(type),
      version: 1,
      lastUpdated: DateTime.now(),
    );

    await _legalDocumentsCollection
        .doc(type.documentId)
        .set(defaultDocument.toMap());
  }

  /// Get default content for different document types
  String _getDefaultContent(LegalDocumentType type) {
    switch (type) {
      case LegalDocumentType.privacyPolicy:
        return '''
# Privacy Policy

## Introduction
Welcome to Bums 'n' Tums. We respect your privacy and are committed to protecting your personal data.

## Data We Collect
- Personal information (name, email)
- Fitness data (height, weight, workout history)
- Health-related information (dietary preferences, allergies)
- Usage data (app interactions, workout completion)

## How We Use Your Data
- To provide personalized workout recommendations
- To track your fitness progress
- To improve our app and services

## Your Rights
Under GDPR, you have the right to:
- Access your personal data
- Correct inaccurate data
- Request deletion of your data
- Object to processing of your data
- Request restriction of processing
- Request transfer of your data
- Withdraw consent

## Data Security
We implement appropriate security measures to protect your personal data.

## Third-Party Services
We use Firebase for data storage and authentication. All third parties are required to respect the security of your data.

## Changes to This Policy
We may update this privacy policy from time to time. We will notify you of any changes.

## Contact Us
If you have questions about this privacy policy, please contact us at support@bumsntums.com.

Last updated: ${DateTime.now().toIso8601String().split('T')[0]}
''';
      case LegalDocumentType.termsAndConditions:
        return '''
# Terms & Conditions

## Introduction
These terms and conditions govern your use of the Bums 'n' Tums mobile application.

## Acceptance of Terms
By using our app, you agree to these terms. If you do not agree, please do not use our app.

## User Accounts
- You are responsible for maintaining the confidentiality of your account
- You must provide accurate and complete information
- You must be at least 13 years old to use this app

## User Content
- You retain ownership of content you create in the app
- You grant us a license to use, store, and share your content
- You must not upload illegal or harmful content

## Fitness Disclaimer
- Our app provides general fitness information, not medical advice
- Consult a healthcare professional before starting any fitness program
- We are not responsible for injuries or health issues resulting from use of our app

## Subscription and Billing
- Some features require a paid subscription
- Payments are processed through Apple In-App Purchases
- Subscriptions automatically renew unless canceled

## Termination
We may terminate or suspend your account for violations of these terms.

## Changes to These Terms
We may update these terms from time to time. We will notify you of any changes.

## Contact Us
If you have questions about these terms, please contact us at support@bumsntums.com.

Last updated: ${DateTime.now().toIso8601String().split('T')[0]}
''';
    }
  }

  /// Log user acceptance of a legal document
  Future<void> logUserAcceptance(
    String userId,
    LegalDocumentType type,
    int version,
  ) async {
    try {
      await _firestore.collection('user_document_acceptances').add({
        'userId': userId,
        'documentType': type.documentId,
        'version': version,
        'acceptedAt': Timestamp.now(),
      });

      _analytics.logEvent(
        name: 'document_accepted',
        parameters: {'document_type': type.documentId, 'version': version},
      );
    } catch (e) {
      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'logUserAcceptance',
          'userId': userId,
          'documentType': type.documentId,
          'version': version.toString(),
        },
      );
    }
  }
}
