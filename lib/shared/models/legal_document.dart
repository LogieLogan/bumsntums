// lib/shared/models/legal_document.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a legal document like privacy policy or terms & conditions
class LegalDocument {
  final String id;
  final String title;
  final String content;
  final int version;
  final DateTime lastUpdated;
  final bool isActive;

  const LegalDocument({
    required this.id,
    required this.title,
    required this.content,
    required this.version,
    required this.lastUpdated,
    this.isActive = true,
  });

  /// Create a LegalDocument from a Firestore document
  factory LegalDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LegalDocument(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      version: data['version'] ?? 1,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  /// Convert the LegalDocument to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'version': version,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'isActive': isActive,
    };
  }

  @override
  String toString() {
    return 'LegalDocument{id: $id, title: $title, version: $version, lastUpdated: $lastUpdated, isActive: $isActive}';
  }
}

/// Type of legal document
enum LegalDocumentType {
  privacyPolicy,
  termsAndConditions,
}

/// Extension to get the document ID for each type
extension LegalDocumentTypeExtension on LegalDocumentType {
  String get documentId {
    switch (this) {
      case LegalDocumentType.privacyPolicy:
        return 'privacy_policy';
      case LegalDocumentType.termsAndConditions:
        return 'terms_conditions';
    }
  }

  String get title {
    switch (this) {
      case LegalDocumentType.privacyPolicy:
        return 'Privacy Policy';
      case LegalDocumentType.termsAndConditions:
        return 'Terms & Conditions';
    }
  }
}