// lib/features/ai/services/conversation_manager.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

class ConversationManager {
  final FirebaseFirestore _firestore;
  final AnalyticsService _analytics;
  
  // Maximum number of messages to keep in context
  static const int _maxContextMessages = 10;
  
  ConversationManager({
    FirebaseFirestore? firestore,
    AnalyticsService? analytics,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _analytics = analytics ?? AnalyticsService();
       
  Future<Conversation?> getConversation(String conversationId) async {
    try {
      final docSnapshot = await _firestore.collection('conversations').doc(conversationId).get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      final messageSnapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp')
          .get();
          
      final messages = messageSnapshot.docs
          .map((doc) => Message.fromMap(doc.data()))
          .toList();
          
      return Conversation.fromMap(docSnapshot.data()!, messages);
    } catch (e) {
      debugPrint('Error getting conversation: $e');
      _analytics.logError(
        error: e.toString(),
        parameters: {'context': 'ConversationManager.getConversation', 'conversationId': conversationId},
      );
      return null;
    }
  }
  
  Future<List<Conversation>> getUserConversations(String userId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('conversations')
          .where('userId', isEqualTo: userId)
          .orderBy('lastMessageAt', descending: true)
          .limit(limit)
          .get();
          
      // Get conversation headers only, without messages
      return snapshot.docs.map((doc) {
        return Conversation.fromMap(doc.data(), []);
      }).toList();
    } catch (e) {
      debugPrint('Error getting user conversations: $e');
      _analytics.logError(
        error: e.toString(),
        parameters: {'context': 'ConversationManager.getUserConversations', 'userId': userId},
      );
      return [];
    }
  }
  
  Future<Conversation> createConversation({
    required String userId,
    required String title,
    required ConversationCategory category,
    Message? initialSystemMessage,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final conversation = Conversation.create(
        userId: userId,
        title: title,
        category: category,
        messages: initialSystemMessage != null ? [initialSystemMessage] : [],
        metadata: metadata,
      );
      
      // Save to Firestore
      await _firestore
          .collection('conversations')
          .doc(conversation.id)
          .set(conversation.toMap());
          
      // Add initial system message if provided
      if (initialSystemMessage != null) {
        await _firestore
            .collection('conversations')
            .doc(conversation.id)
            .collection('messages')
            .doc(initialSystemMessage.id)
            .set(initialSystemMessage.toMap());
      }
      
      _analytics.logEvent(
        name: 'conversation_created',
        parameters: {
          'user_id': userId,
          'conversation_id': conversation.id,
          'category': category.name,
        },
      );
      
      return conversation;
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      _analytics.logError(
        error: e.toString(),
        parameters: {'context': 'ConversationManager.createConversation', 'userId': userId},
      );
      rethrow;
    }
  }
  
  Future<Message> addMessage({
    required String conversationId,
    required Message message,
  }) async {
    try {
      // lib/features/ai/services/conversation_manager.dart (continued)
      
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(message.id)
          .set(message.toMap());
      
      // Update conversation's lastMessageAt and messageCount
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update({
            'lastMessageAt': FieldValue.serverTimestamp(),
            'messageCount': FieldValue.increment(1),
          });
          
      _analytics.logEvent(
        name: 'message_added',
        parameters: {
          'conversation_id': conversationId,
          'message_role': message.role.name,
        },
      );
      
      return message;
    } catch (e) {
      debugPrint('Error adding message: $e');
      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'ConversationManager.addMessage', 
          'conversationId': conversationId,
        },
      );
      rethrow;
    }
  }
  
  Future<void> pinMessage({
    required String conversationId,
    required String messageId,
    required bool isPinned,
  }) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({'isPinned': isPinned});
          
      _analytics.logEvent(
        name: 'message_pin_status_changed',
        parameters: {
          'conversation_id': conversationId,
          'message_id': messageId,
          'is_pinned': isPinned,
        },
      );
    } catch (e) {
      debugPrint('Error pinning message: $e');
      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'ConversationManager.pinMessage', 
          'conversationId': conversationId,
          'messageId': messageId,
        },
      );
      rethrow;
    }
  }
  
  Future<void> updateConversationMetadata({
    required String conversationId,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update({'metadata': metadata});
          
      _analytics.logEvent(
        name: 'conversation_metadata_updated',
        parameters: {
          'conversation_id': conversationId,
        },
      );
    } catch (e) {
      debugPrint('Error updating conversation metadata: $e');
      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'ConversationManager.updateConversationMetadata', 
          'conversationId': conversationId,
        },
      );
      rethrow;
    }
  }
  
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Delete messages subcollection first
      final messagesSnapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .get();
          
      final batch = _firestore.batch();
      
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the conversation document
      batch.delete(_firestore.collection('conversations').doc(conversationId));
      
      await batch.commit();
      
      _analytics.logEvent(
        name: 'conversation_deleted',
        parameters: {
          'conversation_id': conversationId,
        },
      );
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'ConversationManager.deleteConversation', 
          'conversationId': conversationId,
        },
      );
      rethrow;
    }
  }
  
  /// Get messages for context - optimized for token usage
  List<Message> getMessagesForContext(Conversation conversation) {
    final allMessages = conversation.messages;
    if (allMessages.isEmpty) return [];
    
    // Always include system messages
    final systemMessages = allMessages
        .where((msg) => msg.role == MessageRole.system)
        .toList();
    
    // Always include pinned messages
    final pinnedMessages = allMessages
        .where((msg) => msg.isPinned && msg.role != MessageRole.system)
        .toList();
    
    // Get most recent messages
    final recentMessages = allMessages
        .where((msg) => msg.role != MessageRole.system && !msg.isPinned)
        .toList();
    
    // Sort by timestamp
    recentMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Take only the most recent messages up to limit
    final messagesToInclude = recentMessages.take(_maxContextMessages - systemMessages.length - pinnedMessages.length).toList();
    
    // Combine all messages and sort by timestamp
    final result = [...systemMessages, ...pinnedMessages, ...messagesToInclude];
    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    return result;
  }
  
  /// Summarize the conversation for tokens optimization
  Future<Message> summarizeConversation(Conversation conversation, String apiKey) async {
    // This would be implemented using OpenAI to create a summary
    // For now, return a placeholder
    return Message.system(
      content: "This is a conversation about fitness with key points about the user's goals and limitations.",
    );
  }
}