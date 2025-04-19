// lib/features/ai/providers/ai_chat_provider.dart

import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:bums_n_tums/features/ai/models/message.dart';
import 'package:bums_n_tums/features/ai/services/ai_service.dart';
import 'package:bums_n_tums/features/ai/providers/ai_service_provider.dart';
import 'package:bums_n_tums/shared/providers/firebase_providers.dart';
import 'package:bums_n_tums/shared/providers/analytics_provider.dart';
import 'package:bums_n_tums/shared/analytics/firebase_analytics_service.dart';
import 'package:bums_n_tums/features/auth/providers/user_provider.dart';

class AIChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;

  const AIChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  AIChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AIChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AIChatNotifier extends StateNotifier<AsyncValue<AIChatState>> {
  final AIService _aiService;
  final FirebaseFirestore _firestore;
  final AnalyticsService _analytics;
  final String _userId;
  final String _sessionId;

  static const String _initialWelcomeMessage =
      "Hi there! How can I help you with your fitness journey today?";

  AIChatNotifier(
    this._aiService,
    this._firestore,
    this._analytics,
    this._userId,
    this._sessionId,
  ) : super(const AsyncValue.loading()) {
    _loadConversation();
  }

  CollectionReference<Map<String, dynamic>> _messagesCollectionRef() {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('chatSessions')
        .doc(_sessionId)
        .collection('messages');
  }

  Future<void> _loadConversation() async {
    debugPrint("AIChatNotifier(Session: $_sessionId): Loading conversation...");
    try {
      final snapshot =
          await _messagesCollectionRef()
              .orderBy('timestamp', descending: false)
              .limit(100)
              .get();

      final List<Message> messages;
      if (snapshot.docs.isNotEmpty) {
        messages =
            snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList();
        debugPrint(
          "AIChatNotifier(Session: $_sessionId): Loaded ${messages.length} messages.",
        );
      } else {
        messages = [Message.assistant(content: _initialWelcomeMessage)];
        debugPrint(
          "AIChatNotifier(Session: $_sessionId): No messages found, adding welcome.",
        );
      }

      state = AsyncValue.data(
        AIChatState(messages: messages, isLoading: false),
      );
    } catch (e, stackTrace) {
      debugPrint(
        "AIChatNotifier(Session: $_sessionId): Error loading conversation: $e",
      );
      final errorMessage = 'Failed to load conversation: $e';

      state = AsyncValue.error(errorMessage, stackTrace);
      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'loadConversation',
          'userId': _userId,
          'sessionId': _sessionId,
        },
      );
    }
  }

  Future<void> _saveMessage(Message message) async {
    try {
      await _messagesCollectionRef().doc(message.id).set(message.toMap());

      await _messagesCollectionRef().parent?.set({
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, stackTrace) {
      debugPrint(
        "AIChatNotifier(Session: $_sessionId): Error saving message: $e",
      );
      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'saveChatMessage',
          'userId': _userId,
          'sessionId': _sessionId,
        },
      );
    }
  }

  Future<void> provideMessageFeedback({
    required String messageId,
    required bool isPositive,
  }) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    try {
      final index = currentState.messages.indexWhere(
        (msg) => msg.id == messageId,
      );
      if (index == -1) return;

      final message = currentState.messages[index];
      if ((isPositive && message.isPositiveFeedback == true) ||
          (!isPositive && message.isNegativeFeedback == true)) {
        return;
      }

      final updatedMessage = message.copyWith(
        isPositiveFeedback: isPositive,
        isNegativeFeedback: !isPositive,
      );

      final updatedMessages = List<Message>.from(currentState.messages);
      updatedMessages[index] = updatedMessage;

      state = AsyncValue.data(currentState.copyWith(messages: updatedMessages));

      await _messagesCollectionRef().doc(messageId).update({
        'isPositiveFeedback': isPositive,
        'isNegativeFeedback': !isPositive,
      });

      _analytics.logEvent(
        name: 'ai_message_feedback',
        parameters: {
          'message_id': messageId,
          'is_positive': isPositive.toString(),
          'user_id': _userId,
          'session_id': _sessionId,
        },
      );
    } catch (e, stackTrace) {
      debugPrint(
        "AIChatNotifier(Session: $_sessionId): Error providing feedback: $e",
      );

      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'provideMessageFeedback',
          'messageId': messageId,
          'userId': _userId,
          'sessionId': _sessionId,
        },
      );
    }
  }

  Future<void> sendMessage({
    required String message,
    required Map<String, dynamic> userProfileDataMap,
  }) async {
    if (message.trim().isEmpty) return;

    final currentState = state.valueOrNull;
    if (currentState == null) {
      debugPrint(
        "AIChatNotifier(Session: $_sessionId): Cannot send message, state not loaded.",
      );
      return;
    }

    final userMessage = Message.user(content: message);
    List<Message> currentMessages = List.from(currentState.messages);

    if (currentMessages.length == 1 &&
        !currentMessages[0].isUserMessage &&
        currentMessages[0].content == _initialWelcomeMessage) {
      currentMessages = [userMessage];
    } else {
      currentMessages.add(userMessage);
    }

    state = AsyncValue.data(
      currentState.copyWith(
        messages: currentMessages,
        isLoading: true,
        clearError: true,
      ),
    );

    await _saveMessage(userMessage);

    try {
      const historyLimit = 10;
      final messagesForHistory = List<Message>.from(currentMessages);
      final userMessageIndex = messagesForHistory.lastIndexWhere(
        (m) => m.id == userMessage.id,
      );
      final historyStartIndex = max(0, userMessageIndex - historyLimit);
      final previousMessages =
          messagesForHistory
              .sublist(historyStartIndex, userMessageIndex)
              .map((m) => m.toOpenAIFormat())
              .toList();

      _analytics.logEvent(
        name: 'ai_chat_message_sent',
        parameters: {
          'user_id': _userId,
          'message_length': message.length,
          'session_id': _sessionId,
        },
      );
      debugPrint(
        "AIChatNotifier(Session: $_sessionId): Calling _aiService.enhancedChat with ${previousMessages.length} history messages.",
      );

      final response = await _aiService.enhancedChat(
        userId: _userId,
        message: message,
        previousMessages: previousMessages,
        userProfileData: userProfileDataMap,
      );

      final category = _aiService.detectMessageCategory(response);
      final aiMessage = Message.assistant(
        content: response,
        category: category,
      );

      final latestState = state.valueOrNull;
      if (latestState != null) {
        state = AsyncValue.data(
          latestState.copyWith(
            messages: [...latestState.messages, aiMessage],
            isLoading: false,
          ),
        );
      } else {
        debugPrint(
          "AIChatNotifier(Session: $_sessionId): State became null before updating with AI response.",
        );
      }

      await _saveMessage(aiMessage);

      _analytics.logEvent(
        name: 'ai_chat_response_received',
        parameters: {
          'user_id': _userId,
          'category': category,
          'response_length': response.length,
          'ai_service': _aiService.runtimeType.toString(),
          'session_id': _sessionId,
        },
      );
    } catch (e, stackTrace) {
      debugPrint(
        "AIChatNotifier(Session: $_sessionId): Error sending message: $e",
      );
      final errorMessage = 'Failed to get response: ${e.toString()}';

      final latestState = state.valueOrNull;
      if (latestState != null) {
        final errorMessageForUser = Message.assistant(
          content: "Sorry, I encountered an error. Please try again.",
        );
        state = AsyncValue.data(
          latestState.copyWith(
            messages: [...latestState.messages, errorMessageForUser],
            isLoading: false,
            error: errorMessage,
          ),
        );
      } else {
        state = AsyncValue.error(errorMessage, stackTrace);
      }

      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'sendChatMessage',
          'userId': _userId,
          'sessionId': _sessionId,
          'ai_service': _aiService.runtimeType.toString(),
        },
      );
    }
  }

  Future<void> clearChat(/* Removed userId, use stored _userId */) async {
    state = AsyncValue.data(AIChatState(messages: [], isLoading: true));
    debugPrint(
      "AIChatNotifier(Session: $_sessionId): Clearing chat messages locally and in Firestore.",
    );
    _analytics.logEvent(
      name: 'ai_chat_cleared',
      parameters: {'user_id': _userId, 'session_id': _sessionId},
    );

    try {
      final messagesRef = _messagesCollectionRef();
      final snapshot = await messagesRef.get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint(
        "AIChatNotifier(Session: $_sessionId): Deleted ${snapshot.docs.length} messages from Firestore.",
      );

      state = AsyncValue.data(
        AIChatState(
          messages: [Message.assistant(content: _initialWelcomeMessage)],
        ),
      );
    } catch (e, stackTrace) {
      debugPrint(
        "AIChatNotifier(Session: $_sessionId): Error deleting Firestore history: $e",
      );
      _analytics.logError(
        error: "Error deleting chat history: ${e.toString()}",
        parameters: {
          'context': 'clearChatFirestore',
          'userId': _userId,
          'sessionId': _sessionId,
        },
      );

      state = AsyncValue.error("Failed to clear chat history.", stackTrace);
    }
  }

  Future<void> generateAndSaveTitle() async {
    // Get current messages from state
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.messages.length < 3) {
      // Don't generate title for very short chats or if state is not loaded
      debugPrint(
        "AIChatNotifier(Session: $_sessionId): Skipping title generation (not enough messages or state not ready).",
      );
      return;
    }

    // Check if a title already exists (optional, prevents regeneration)
    // final sessionDoc = await _messagesCollectionRef().parent!.get();
    // if (sessionDoc.exists && (sessionDoc.data()?['title'] as String?) != 'New Chat') {
    //   debugPrint("AIChatNotifier(Session: $_sessionId): Title already exists, skipping generation.");
    //   return;
    // }

    debugPrint(
      "AIChatNotifier(Session: $_sessionId): Attempting to generate title...",
    );

    // Prepare recent history for context (e.g., last 6 messages)
    // Exclude the initial welcome message if present
    final relevantMessages =
        currentState.messages
            .where((m) => m.content != _initialWelcomeMessage)
            .toList();
    final historyForTitle = relevantMessages.sublist(
      max(0, relevantMessages.length - 6),
    ); // Get last 6 relevant messages

    if (historyForTitle.isEmpty) {
      debugPrint(
        "AIChatNotifier(Session: $_sessionId): No relevant messages for title generation.",
      );
      return; // No content to base title on
    }

    // Construct the prompt specifically for title generation
    final promptMessages = historyForTitle
        .map((m) => "${m.isUserMessage ? 'User' : 'AI'}: ${m.content}")
        .join('\n');
    final titlePrompt = """
Based on the following conversation excerpt:
---
$promptMessages
---
Generate a very concise title (3-6 words maximum) that accurately summarizes the main topic of this chat session. Respond ONLY with the title text itself, no labels, no introduction, no quotation marks. Example valid responses: 'Squat Form Check', 'Post-Workout Meal Ideas', 'Workout Consistency Tips'.
""";

    try {
      // Use enhancedChat with a low maxTokens setting for efficiency
      // Note: We are NOT modifying the actual chat history here, just using it for context
      final generatedTitle = await _aiService.enhancedChat(
        userId:
            _userId, // Pass userId for the AI call context if needed by service
        message: titlePrompt, // The prompt asking for a title
        // Pass an empty list or minimal context; the main context is in the message itself
        previousMessages: [],
        // We could potentially configure lower temperature or specific generation settings here if supported by AIService enhanceChat
        // maxTokens: 15 // Example: Limit response length server-side if possible
      );

      final cleanTitle = generatedTitle.trim().replaceAll(
        '"',
        '',
      ); // Clean up quotes

      if (cleanTitle.isNotEmpty && cleanTitle.toLowerCase() != 'new chat') {
        debugPrint(
          "AIChatNotifier(Session: $_sessionId): Generated title: '$cleanTitle'",
        );
        // Update the session document in Firestore
        await _messagesCollectionRef().parent?.set(
          // Use set with merge to update or create fields
          {'title': cleanTitle, 'lastUpdatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
        debugPrint(
          "AIChatNotifier(Session: $_sessionId): Saved generated title to Firestore.",
        );
      } else {
        debugPrint(
          "AIChatNotifier(Session: $_sessionId): AI did not return a valid title.",
        );
      }
    } catch (e, stackTrace) {
      debugPrint(
        "AIChatNotifier(Session: $_sessionId): Error generating title: $e",
      );
      _analytics.logError(
        error: "Error generating chat title: ${e.toString()}",
        parameters: {
          'context': 'generateAndSaveTitle',
          'userId': _userId,
          'sessionId': _sessionId,
        },
      );
      // Don't throw, failure to generate title is not critical
    }
  }
}

final aiChatProviderFamily = StateNotifierProvider.autoDispose.family<
  AIChatNotifier,
  AsyncValue<AIChatState>,
  String
>((ref, sessionId) {
  final aiService = ref.watch(aiServiceProvider);
  final firestore = ref.watch(firestoreProvider);
  final analytics = ref.watch(analyticsServiceProvider);

  final userId = ref.watch(userProfileProvider).value?.userId;

  if (userId == null) {
    debugPrint(
      "aiChatProviderFamily: User ID is null, cannot create notifier for session $sessionId.",
    );

    return AIChatNotifier(aiService, firestore, analytics, '', sessionId)
      ..state = AsyncValue.error("User not authenticated", StackTrace.current);
  }

  debugPrint(
    "aiChatProviderFamily: Creating notifier for session $sessionId and user $userId.",
  );

  return AIChatNotifier(aiService, firestore, analytics, userId, sessionId);
});
