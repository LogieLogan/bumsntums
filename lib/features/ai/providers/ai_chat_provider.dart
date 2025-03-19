// lib/features/ai/providers/ai_chat_provider.dart
import 'package:bums_n_tums/shared/analytics/firebase_analytics_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'openai_provider.dart';
import '../services/openai_service.dart';

// Chat message model
class ChatMessage {
  final String id;
  final String content;
  final bool isUserMessage;
  final DateTime timestamp;
  final String? category; // Add category for tracking
  final Map<String, dynamic>? metadata; // For additional info like token usage
  bool isPositiveFeedback; // User feedback on AI messages
  bool isNegativeFeedback;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUserMessage,
    required this.timestamp,
    this.category,
    this.metadata,
    this.isPositiveFeedback = false,
    this.isNegativeFeedback = false,
  });

  Map<String, String> toAPIFormat() {
    return {'role': isUserMessage ? 'user' : 'assistant', 'content': content};
  }

  // For Firestore serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'isUserMessage': isUserMessage,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
      'metadata': metadata,
      'isPositiveFeedback': isPositiveFeedback,
      'isNegativeFeedback': isNegativeFeedback,
    };
  }

  // Factory constructor from Firestore data
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      content: map['content'],
      isUserMessage: map['isUserMessage'],
      timestamp: DateTime.parse(map['timestamp']),
      category: map['category'],
      metadata: map['metadata'],
      isPositiveFeedback: map['isPositiveFeedback'] ?? false,
      isNegativeFeedback: map['isNegativeFeedback'] ?? false,
    );
  }
}

// Chat state
class AIChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  AIChatState({this.messages = const [], this.isLoading = false, this.error});

  AIChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return AIChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// AI Chat Notifier
class AIChatNotifier extends StateNotifier<AIChatState> {
  final OpenAIService _openAIService;
  final FirebaseFirestore _firestore;
  final AnalyticsService _analytics;

  AIChatNotifier(this._openAIService, this._firestore, this._analytics)
    : super(AIChatState());

  // Load conversation history from Firestore
  Future<void> loadConversation(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final snapshot =
          await _firestore
              .collection('conversations')
              .doc(userId)
              .collection('messages')
              .orderBy('timestamp')
              .limit(50) // Reasonable limit for chat history
              .get();

      if (snapshot.docs.isNotEmpty) {
        final messages =
            snapshot.docs
                .map((doc) => ChatMessage.fromMap(doc.data()))
                .toList();

        state = state.copyWith(messages: messages, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Save message to Firestore
  Future<void> _saveMessage(String userId, ChatMessage message) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(userId)
          .collection('messages')
          .doc(message.id)
          .set(message.toMap());
    } catch (e) {
      // Log error but don't disrupt the user experience
      _analytics.logError(
        error: e.toString(),
        parameters: {'context': 'saveChatMessage', 'userId': userId},
      );
    }
  }

  // Provide feedback on AI responses
  Future<void> provideMessageFeedback({
    required String userId,
    required String messageId,
    required bool isPositive,
  }) async {
    try {
      // Find the message in state
      final index = state.messages.indexWhere((msg) => msg.id == messageId);

      if (index == -1) return;

      // Create an updated copy of the message
      final updatedMessage = ChatMessage(
        id: state.messages[index].id,
        content: state.messages[index].content,
        isUserMessage: state.messages[index].isUserMessage,
        timestamp: state.messages[index].timestamp,
        category: state.messages[index].category,
        metadata: state.messages[index].metadata,
        isPositiveFeedback: isPositive,
        isNegativeFeedback: !isPositive,
      );

      // Update state
      final updatedMessages = List<ChatMessage>.from(state.messages);
      updatedMessages[index] = updatedMessage;

      state = state.copyWith(messages: updatedMessages);

      // Update in Firestore
      await _firestore
          .collection('conversations')
          .doc(userId)
          .collection('messages')
          .doc(messageId)
          .update({
            'isPositiveFeedback': isPositive,
            'isNegativeFeedback': !isPositive,
          });

      // Track feedback for analytics
      _analytics.logEvent(
        name: 'ai_message_feedback',
        parameters: {
          'user_id': userId,
          'message_id': messageId,
          'is_positive': isPositive.toString(),
        },
      );
    } catch (e) {
      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'provideMessageFeedback',
          'userId': userId,
          'messageId': messageId,
        },
      );
    }
  }

  Future<void> sendMessage({
    required String userId,
    required String message,
  }) async {
    try {
      // Add user message to state
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: message,
        isUserMessage: true,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, userMessage],
        isLoading: true,
        error: null,
      );

      // Save user message to Firestore
      await _saveMessage(userId, userMessage);

      // Prepare previous messages for context (limit to last 10 messages)
      final previousMessages =
          state.messages
              .take(state.messages.length > 10 ? 10 : state.messages.length)
              .map((msg) => msg.toAPIFormat())
              .toList();

      // Track user message for analytics
      _analytics.logEvent(
        name: 'ai_chat_message_sent',
        parameters: {'user_id': userId, 'message_length': message.length},
      );

      // Get AI response using enhanced chat
      final response = await _openAIService.enhancedChat(
        userId: userId,
        message: message,
        previousMessages: previousMessages,
      );

      // Detect the category of the response for metrics
      final category = _openAIService.detectMessageCategory(message);

      // Add AI response to state
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUserMessage: false,
        timestamp: DateTime.now(),
        category: category,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );

      // Save AI message to Firestore
      await _saveMessage(userId, aiMessage);

      // Track AI response for analytics
      _analytics.logEvent(
        name: 'ai_chat_response_received',
        parameters: {
          'user_id': userId,
          'category': category,
          'response_length': response.length,
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());

      // Track error for analytics
      _analytics.logError(
        error: e.toString(),
        parameters: {'context': 'sendChatMessage', 'userId': userId},
      );
    }
  }

  void clearChat() {
    state = AIChatState();
  }
}

// Provider for AI Chat
final aiChatProvider = StateNotifierProvider<AIChatNotifier, AIChatState>((ref) {
  final openAIService = ref.watch(openAIServiceProvider);
  final firestore = FirebaseFirestore.instance;
  final analytics = AnalyticsService();
  return AIChatNotifier(openAIService, firestore, analytics);
});
