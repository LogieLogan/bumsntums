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

  /// Get default content for different document types
  String _getDefaultContent(LegalDocumentType type) {
    switch (type) {
      case LegalDocumentType.privacyPolicy:
        return '''
# Privacy Policy

## Introduction
Welcome to Bums 'n' Tums ("we," "our," or "us"). We respect your privacy and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.

## Last Updated
This privacy policy was last updated on March 18, 2025.

## Data We Collect
We collect the following types of information:

**Personal Information:**
- Name and email address
- Date of birth (to verify age requirements)
- Profile information (optional)

**Health and Fitness Data:**
- Basic body measurements (height, weight) 
- Fitness goals and preferences
- Body focus areas
- Dietary preferences and restrictions
- Workout history and favorites
- Food scans and nutrition information

**Device and Usage Data:**
- Device information (model, operating system)
- App usage statistics
- Analytics data (how you interact with the app)
- Error reports and crash logs

## How We Use Your Data
We use your data for the following purposes:

- **Service Provision:** To create and manage your account, provide personalized workout recommendations, and enable food scanning functionality
- **User Experience:** To understand how you use our app and improve our features and user interface
- **Progress Tracking:** To help you track your fitness journey and achievements
- **Technical Support:** To diagnose problems, address issues, and provide customer support
- **Communication:** To respond to your inquiries and send important service-related notifications
- **Legal Compliance:** To fulfill our legal obligations and enforce our terms

## Legal Basis for Processing
We process your data on the following legal grounds:

- **Contract Performance:** Processing necessary to provide you with our services as outlined in our Terms & Conditions
- **Legitimate Interests:** Improving our services, ensuring app security, and analyzing user behavior to enhance the app
- **Consent:** When you explicitly agree to specific data processing activities
- **Legal Obligations:** When processing is required by applicable laws

## Data Sharing and Third-Party Services
We share data with the following third-party service providers:

- **Firebase:** For secure user authentication, data storage, and app analytics
- **Open Food Facts API:** To retrieve nutritional information for scanned food items
- **Apple App Store:** For processing in-app purchases and subscriptions
- **Error Monitoring Services:** To identify and fix app crashes and technical issues

All third-party providers are required to respect the security and privacy of your personal data.

## Data Security
We implement appropriate technical and organizational security measures to protect your personal data including:

- Secure data storage with Firebase
- Encryption for sensitive data
- Access controls and authentication measures
- Regular security assessments
- Separation of personally identifiable information (PII) from fitness data

## Your Rights Under GDPR
If you are in the European Economic Area (EEA), you have the following rights:

- **Right to Access:** Request access to your personal data
- **Right to Rectification:** Request correction of inaccurate data
- **Right to Erasure:** Request deletion of your data ("right to be forgotten")
- **Right to Restrict Processing:** Request restriction of processing of your data
- **Right to Data Portability:** Request transfer of your data
- **Right to Object:** Object to processing of your data
- **Right to Withdraw Consent:** Withdraw consent at any time

To exercise these rights, please contact us at support@bumsntums.com.

## Children's Privacy
Our services are not intended for individuals under the age of 13.

## Changes to This Policy
We may update this Privacy Policy from time to time. We will notify you of any significant changes through the app or by email.

## Contact Us
If you have questions about this Privacy Policy, please contact us at:

Email: support@bumsntums.com

Last updated: ${DateTime.now().toIso8601String().split('T')[0]}
''';
      case LegalDocumentType.termsAndConditions:
        return '''
# Terms & Conditions

## Introduction
These Terms & Conditions ("Terms") govern your use of the Bums 'n' Tums mobile application ("App") operated by Bums 'n' Tums ("we," "our," or "us"). Please read these Terms carefully before using our App.

## Last Updated
These Terms were last updated on March 18, 2025.

## Acceptance of Terms
By downloading, installing, or using our App, you agree to be bound by these Terms. If you do not agree to these Terms, please do not use our App.

## Eligibility
You must be at least 13 years of age to use our App. By using the App, you represent and warrant that you meet this requirement. If you are between the ages of 13 and 18, you represent that you have your parent's or legal guardian's permission to use the App.

## User Accounts
To use certain features of the App, you must create an account. When creating your account:
- You must provide accurate, current, and complete information
- You are responsible for maintaining the confidentiality of your account credentials
- You are responsible for all activities that occur under your account
- You must notify us immediately of any unauthorized use of your account

## User Content and Data
- You retain ownership of any content or data you submit through the App
- You grant us a non-exclusive, transferable, sublicensable, royalty-free license to use, store, display, reproduce, and modify any content you submit
- You represent that you have all necessary rights to grant this license
- You are solely responsible for the accuracy and appropriateness of your content

## Acceptable Use
You agree not to:
- Use the App for any illegal purpose
- Violate any applicable laws or regulations
- Impersonate any person or entity
- Interfere with or disrupt the App or servers
- Attempt to gain unauthorized access to any part of the App
- Use the App to transmit harmful code or materials
- Engage in any activity that could damage, disable, or impair the App

## Fitness and Health Disclaimer
- Our App provides general fitness and nutrition information for educational purposes only
- Our App is not intended to provide medical advice, diagnosis, or treatment
- Always consult with a healthcare professional before starting any fitness program or making significant changes to your diet
- We are not responsible for any injuries, health problems, or adverse outcomes that may result from using our App

## Intellectual Property
- The App, including its content, features, and functionality, is owned by us and is protected by copyright, trademark, and other intellectual property laws
- You may not reproduce, distribute, modify, create derivative works of, publicly display, or exploit any content from our App without our express written permission

## Subscription and Billing
- Some features of our App may require a paid subscription
- All payments are processed through Apple In-App Purchases
- Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period
- You can manage and cancel subscriptions through your Apple App Store account settings
- No refunds will be issued for partial subscription periods

## Termination
We reserve the right to suspend or terminate your access to the App at any time, with or without notice, for any reason, including if you violate these Terms.

## Limitation of Liability
- To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, special, consequential, or punitive damages
- Our total liability for any claims arising under these Terms shall not exceed the amount you paid to us in the past 12 months

## Indemnification
You agree to indemnify and hold us harmless from any claims, damages, liabilities, costs, or expenses arising from your use of the App or violation of these Terms.

## Changes to These Terms
We may update these Terms from time to time. We will notify you of any significant changes through the App or by email. Your continued use of the App after such modifications constitutes your acceptance of the updated Terms.

## Governing Law
These Terms shall be governed by and construed in accordance with the laws of the UK, without regard to its conflict of law principles.

## Contact Us
If you have any questions about these Terms, please contact us at support@bumsntums.com.

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
