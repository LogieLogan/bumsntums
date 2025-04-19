// lib/features/ai/services/chat_session_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bums_n_tums/shared/providers/firebase_providers.dart'; // Assuming firestoreProvider is here

class ChatSessionService {
  final FirebaseFirestore _firestore;

  ChatSessionService(this._firestore);

  /// Deletes a chat session and all its messages.
  Future<void> deleteChatSession(String userId, String sessionId) async {
    debugPrint("ChatSessionService: Deleting session $sessionId for user $userId");

    final sessionDocRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('chatSessions')
        .doc(sessionId);

    final messagesCollectionRef = sessionDocRef.collection('messages');

    try {
      // 1. Delete all messages in the subcollection (using batch delete)
      const batchSize = 100; // Firestore batch limit is 500, use smaller batches
      QuerySnapshot messagesSnapshot;
      do {
         messagesSnapshot = await messagesCollectionRef.limit(batchSize).get();
         if (messagesSnapshot.docs.isEmpty) {
            break; // No more messages
         }
         final batch = _firestore.batch();
         for (final doc in messagesSnapshot.docs) {
           batch.delete(doc.reference);
         }
         await batch.commit();
         debugPrint("ChatSessionService: Deleted batch of ${messagesSnapshot.docs.length} messages for session $sessionId.");
      } while (messagesSnapshot.docs.length >= batchSize); // Continue if batch was full

      // 2. Delete the main session document itself
      await sessionDocRef.delete();

      debugPrint("ChatSessionService: Successfully deleted session document $sessionId.");

    } catch (e) {
      debugPrint("ChatSessionService: Error deleting session $sessionId: $e");
      // Re-throw the error so the UI can potentially handle it (e.g., show SnackBar)
      throw Exception("Failed to delete chat session: ${e.toString()}");
    }
  }
}

// Provider for the service
final chatSessionServiceProvider = Provider<ChatSessionService>((ref) {
  final firestore = ref.watch(firestoreProvider); // Get Firestore instance
  return ChatSessionService(firestore);
});