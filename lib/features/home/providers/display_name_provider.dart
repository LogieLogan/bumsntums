// lib/features/home/providers/display_name_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to fetch user display name from Firestore
class DisplayNameService {
  /// Fetches the display name for a given user ID from Firestore
  static Future<String?> getDisplayName(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users_personal_info')
          .doc(userId)
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['displayName'];
      }
      return null;
    } catch (e) {
      print('Error fetching display name: $e');
      return null;
    }
  }
}

/// Provider that returns the display name for a given user ID
final displayNameProvider = FutureProvider.family<String, String>((ref, userId) async {
  final displayName = await DisplayNameService.getDisplayName(userId);
  return displayName ?? 'Fitness Friend';
});