// lib/features/ai/providers/ai_chat_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/models/user_profile.dart';
import 'openai_provider.dart';
import '../services/openai_service.dart';

// Chat message model
class ChatMessage {
  final String id;
  final String content;
  final bool isUserMessage;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUserMessage,
    required this.timestamp,
  });

  Map<String, String> toAPIFormat() {
    return {
      'role': isUserMessage ? 'user' : 'assistant',
      'content': content,
    };
  }
}

// Chat state
class AIChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  AIChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

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

  AIChatNotifier(this._openAIService) : super(AIChatState());

  Future<void> sendMessage({
    required UserProfile userProfile,
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

      // Prepare previous messages for context (limit to last 10 messages)
      final previousMessages = state.messages
          .take(state.messages.length > 10 ? 10 : state.messages.length)
          .map((msg) => msg.toAPIFormat())
          .toList();

      // Get AI response
      final response = await _openAIService.chat(
        userProfile: userProfile,
        message: message,
        previousMessages: previousMessages,
      );

      // Add AI response to state
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUserMessage: false,
        timestamp: DateTime.now(),
      );
      
      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
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
  return AIChatNotifier(openAIService);
});