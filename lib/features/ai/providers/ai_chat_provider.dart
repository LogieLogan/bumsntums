// lib/features/ai/providers/ai_chat_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../services/openai_service.dart';
import 'openai_provider.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// State for chat UI
class AIChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;

  AIChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  AIChatState copyWith({
    List<Message>? messages,
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

class AIChatNotifier extends StateNotifier<AIChatState> {
  final OpenAIService _openAIService;
  final FirebaseFirestore _firestore;
  final AnalyticsService _analytics;
  final Uuid _uuid = const Uuid();

  // Track disposal state
  bool _isDisposed = false;
  bool get mounted => !_isDisposed;

  AIChatNotifier(this._openAIService, this._firestore, this._analytics)
    : super(AIChatState());

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // Load conversation history from Firestore
  Future<void> loadConversation(String userId) async {
    if (_isDisposed) return;

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

      if (_isDisposed) return; // Check again after the async operation

      if (snapshot.docs.isNotEmpty) {
        final messages =
            snapshot.docs
                .map((doc) => Message.fromMap(doc.data()))
                .toList();

        state = state.copyWith(messages: messages, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }

      // Log error even if disposed since this is a backend operation
      _analytics.logError(
        error: e.toString(),
        parameters: {'context': 'loadConversation', 'userId': userId},
      );
    }
  }

  // Save message to Firestore
  Future<void> _saveMessage(String userId, Message message) async {
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
    required String messageId,
    required bool isPositive,
  }) async {
    if (_isDisposed) return;

    try {
      // Find the message in state
      final index = state.messages.indexWhere((msg) => msg.id == messageId);

      if (index == -1) return;

      // Create an updated copy of the message
      final message = state.messages[index];
      final updatedMessage = message.copyWith(
        isPositiveFeedback: isPositive,
        isNegativeFeedback: !isPositive,
      );

      // Update state if not disposed
      if (!_isDisposed) {
        final updatedMessages = List<Message>.from(state.messages);
        updatedMessages[index] = updatedMessage;
        state = state.copyWith(messages: updatedMessages);
      }

      // Update in Firestore (assuming the structure from your existing implementation)
      await _firestore
          .collection('conversations')
          .doc('current')
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
          'message_id': messageId,
          'is_positive': isPositive.toString(),
        },
      );
    } catch (e) {
      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'provideMessageFeedback',
          'messageId': messageId,
        },
      );
    }
  }

  Future<void> sendMessage({
    required String userId,
    required String message,
  }) async {
    if (_isDisposed) return;

    try {
      // Add user message to state
      final userMessage = Message.user(content: message);

      if (!_isDisposed) {
        state = state.copyWith(
          messages: [...state.messages, userMessage],
          isLoading: true,
          error: null,
        );
      }

      // Save user message to Firestore
      await _saveMessage(userId, userMessage);

      // Prepare previous messages for context (limit to last 10 messages)
      final previousMessages =
          state.messages
              .take(state.messages.length > 10 ? 10 : state.messages.length)
              .map((m) => m.toOpenAIFormat())
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

      if (_isDisposed) return; // Check again after the async AI request

      // Detect the category of the response for metrics
      final category = _openAIService.detectMessageCategory(message);

      // Add AI response to state
      final aiMessage = Message.assistant(
        content: response,
        category: category,
      );

      if (!_isDisposed) {
        state = state.copyWith(
          messages: [...state.messages, aiMessage],
          isLoading: false,
        );
      }

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
      if (!_isDisposed) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }

      // Track error for analytics
      _analytics.logError(
        error: e.toString(),
        parameters: {'context': 'sendChatMessage', 'userId': userId},
      );
    }
  }

  void clearChat() {
    if (!_isDisposed) {
      state = AIChatState();
    }
  }
}

// Provider for AI Chat
final aiChatProvider = StateNotifierProvider<AIChatNotifier, AIChatState>((ref) {
  final openAIService = ref.watch(openAIServiceProvider);
  final firestore = FirebaseFirestore.instance;
  final analytics = AnalyticsService();
  return AIChatNotifier(openAIService, firestore, analytics);
});