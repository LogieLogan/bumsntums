// lib/features/ai/screens/ai_chat_screen.dart
import 'dart:math';

import 'package:bums_n_tums/features/ai_workout_creation/screens/ai_workout_screen.dart';
import 'package:bums_n_tums/shared/providers/environment_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../features/auth/providers/user_provider.dart';
import '../providers/ai_chat_provider.dart';
import '../models/message.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const AIChatScreen({required this.sessionId, Key? key}) : super(key: key);

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const String _initialWelcomeMessage =
      "Hi there! How can I help you with your fitness journey today?";
  static const String _clearedChatMessage = "Chat cleared. How can I help?";

  @override
  void initState() {
    super.initState();
    _loadConversationHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversationHistory() async {
    debugPrint(
      "AIChatScreen: Loading conversation for session ID: ${widget.sessionId}",
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    debugPrint(
      "AIChatScreen: _sendMessage called for session ${widget.sessionId}",
    );
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // --- TARGETED FIX: Ensure profile and map are handled ---
    final userProfile = ref.read(userProfileProvider).value;
    if (userProfile == null) {
      debugPrint(
        "AIChatScreen: Failed to send message - User profile is null.",
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User profile not loaded')),
        );
      }
      return;
    }

    Map<String, dynamic>?
    profileMap; // Keep as nullable initially for error handling
    try {
      profileMap = userProfile.toMap(); // Call the method
      if (profileMap == null) {
        // Explicitly check if toMap returned null
        throw Exception("toMap() method returned null");
      }
      debugPrint(
        "AIChatScreen: Successfully created profileMap: ${profileMap.toString().substring(0, min(profileMap.toString().length, 100))}...",
      ); // Log part of the map
    } catch (e) {
      debugPrint(
        "AIChatScreen: Error converting profile to map or profile incomplete: $e",
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error processing profile data')),
        );
      }
      profileMap = null; // Ensure it's null on error
    }

    // Only proceed if profileMap is NOT null
    if (profileMap != null) {
      debugPrint(
        "AIChatScreen: Calling notifier sendMessage with profile map...",
      );
      _messageController.clear();

      // --- TARGETED FIX: Pass the required profile map ---
      await ref
          .read(aiChatProviderFamily(widget.sessionId).notifier)
          .sendMessage(
            message: message,
            userProfileDataMap: profileMap, // Pass the NON-NULL map
          );

      debugPrint(
        "AIChatScreen: sendMessage notifier call completed for session ${widget.sessionId}",
      );
      _scrollToBottom();
    } else {
      // Handle the case where profileMap could not be created
      debugPrint(
        "AIChatScreen: Cannot send message, profile map creation failed.",
      );
      // Optionally show a snackbar message here too
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not process profile for AI context.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProviderFamily(widget.sessionId));

    final userProfileAsync = ref.watch(userProfileProvider);

    ref.listen<
      AsyncValue<AIChatState>
    >(aiChatProviderFamily(widget.sessionId), (previousState, nextState) {
      // Check if the next state is data and has more messages than the previous data state
      final previousData =
          previousState?.valueOrNull; // Safely get previous data
      final nextData = nextState.valueOrNull; // Safely get next data

      // Only scroll if both states have data and the new one has more messages
      if (previousData != null &&
          nextData != null &&
          nextData.messages.length > previousData.messages.length) {
        debugPrint(
          "AIChatScreen: New message detected via ref.listen, scrolling.",
        );
        _scrollToBottom();
      }
      // Optional: Handle transitions to error or loading states if needed
    });

    return PopScope(
      // canPop defaults to true, allowing back navigation
      onPopInvoked: (didPop) {
        // This is called AFTER the pop has happened or been prevented
        if (didPop) {
          // If the screen successfully popped, trigger title generation
          debugPrint(
            "AIChatScreen (Session: ${widget.sessionId}): Popped. Triggering title generation.",
          );
          // Call the notifier method (fire-and-forget is acceptable)
          ref
              .read(aiChatProviderFamily(widget.sessionId).notifier)
              .generateAndSaveTitle();
        } else {
          debugPrint(
            "AIChatScreen (Session: ${widget.sessionId}): Pop prevented.",
          );
        }
      },

      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI Fitness Coach'),
          actions: [
            if (userProfileAsync is AsyncData && userProfileAsync.value != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear This Chat',
                onPressed: () {
                  // final userId = userProfileAsync.value!.userId; // No longer needed here
                  // Corrected call: No arguments needed for notifier's clearChat
                  ref
                      .read(aiChatProviderFamily(widget.sessionId).notifier)
                      .clearChat();
                  debugPrint(
                    "AIChatScreen: Clear Chat button pressed for session ${widget.sessionId}",
                  );
                  // Optionally navigate back after clearing?
                  // Navigator.pop(context);
                },
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: chatState.when(
                // Use .when to handle AsyncValue states
                data: (stateData) {
                  // stateData is the actual AIChatState here
                  // --- Access messages from stateData ---
                  if (stateData.messages.isEmpty) {
                    // Optional: Show a message if the loaded chat is empty
                    // (Shouldn't happen often with welcome message logic)
                    return const Center(
                      child: Text("Send a message to start!"),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount:
                        stateData.messages.length, // Access via stateData
                    itemBuilder: (context, index) {
                      final message =
                          stateData.messages[index]; // Access via stateData
                      return _ChatMessageWidget(
                        message: message,
                        onFeedback:
                            !message.isUserMessage
                                ? (isPositive) async {
                                  final userProfile = userProfileAsync.value;
                                  if (userProfile != null) {
                                    // --- TARGETED FIX ---
                                    await ref
                                        .read(
                                          aiChatProviderFamily(
                                            widget.sessionId,
                                          ).notifier,
                                        )
                                        .provideMessageFeedback(
                                          // REMOVE userId parameter from this call
                                          // userId: userProfile.userId,
                                          messageId: message.id,
                                          isPositive: isPositive,
                                        );
                                    // --- END FIX ---
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Cannot submit feedback: User profile not loaded.',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                                : null,
                        onActionLink: (action) {
                          if (action == 'workout_generator') {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AIWorkoutScreen(),
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, stack) =>
                        Center(child: Text("Error loading chat: $error")),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(/* ... */),
                      textInputAction: TextInputAction.send,
                      // --- TARGETED FIX for onSubmitted ---
                      // Disable submit if AsyncValue itself is loading OR if the data state indicates loading
                      onSubmitted:
                          (_) =>
                              (chatState.isLoading ||
                                      (chatState.valueOrNull?.isLoading ??
                                          false))
                                  ? null // Do nothing if loading
                                  : _sendMessage(), // Otherwise send
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    // --- TARGETED FIX for onPressed ---
                    // Disable button if AsyncValue itself is loading OR if the data state indicates loading
                    onPressed:
                        (chatState.isLoading ||
                                (chatState.valueOrNull?.isLoading ?? false))
                            ? null // Disable if loading
                            : _sendMessage, // Otherwise allow send
                    backgroundColor: AppColors.salmon,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessageWidget extends StatelessWidget {
  final Message message;
  final Function(bool isPositive)? onFeedback;
  final Function(String action)? onActionLink;

  const _ChatMessageWidget({
    required this.message,
    this.onFeedback,
    this.onActionLink,
  });

  @override
  Widget build(BuildContext context) {
    String displayContent = message.content;
    Map<String, String> actionLinks = {};

    final linkPattern = RegExp(r'\[(.*?)\]\((.*?)\)');
    final matches = linkPattern.allMatches(message.content);

    for (final match in matches) {
      if (match.groupCount >= 2) {
        final action = match.group(2)!;
        final placeholder = '---ACTION_LINK_${actionLinks.length}---';

        actionLinks[placeholder] = action;
        displayContent = displayContent.replaceFirst(
          match.group(0)!,
          placeholder,
        );
      }
    }

    return Align(
      alignment:
          message.isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color:
              message.isUserMessage
                  ? AppColors.salmon.withOpacity(0.1)
                  : AppColors.popTurquoise.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRichText(context, displayContent, actionLinks),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: AppTextStyles.caption,
                ),

                if (!message.isUserMessage && onFeedback != null) ...[
                  const Spacer(),

                  IconButton(
                    icon: Icon(
                      Icons.thumb_up,
                      size: 16,
                      color:
                          message.isPositiveFeedback
                              ? AppColors.popGreen
                              : AppColors.lightGrey,
                    ),
                    onPressed: () => onFeedback!(true),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),

                  IconButton(
                    icon: Icon(
                      Icons.thumb_down,
                      size: 16,
                      color:
                          message.isNegativeFeedback
                              ? AppColors.error
                              : AppColors.lightGrey,
                    ),
                    onPressed: () => onFeedback!(false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRichText(
    BuildContext context,
    String content,
    Map<String, String> actionLinks,
  ) {
    if (actionLinks.isEmpty) {
      return Text(content, style: AppTextStyles.body);
    }

    List<TextSpan> spans = [];
    List<String> parts = content.split(RegExp(r'---ACTION_LINK_\d+---'));

    int i = 0;
    for (var part in parts) {
      if (part.isNotEmpty) {
        spans.add(TextSpan(text: part));
      }

      if (i < parts.length - 1) {
        String placeholder = '---ACTION_LINK_$i---';
        String? action = actionLinks[placeholder];

        if (action != null) {
          String linkText = '';

          final match = RegExp(
            r'\[(.*?)\]\(' + action + r'\)',
          ).firstMatch(message.content);
          if (match != null && match.groupCount >= 1) {
            linkText = match.group(1)!;
          } else {
            linkText = 'Take Action';
          }

          spans.add(
            TextSpan(
              text: linkText,
              style: AppTextStyles.body.copyWith(
                color: AppColors.salmon,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
              recognizer:
                  TapGestureRecognizer()
                    ..onTap = () {
                      if (onActionLink != null) {
                        onActionLink!(action);
                      }
                    },
            ),
          );
        }
      }

      i++;
    }

    return RichText(text: TextSpan(style: AppTextStyles.body, children: spans));
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _SuggestionChip({
    required this.label,
    required this.onTap,
    this.color = AppColors.salmon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(label, style: TextStyle(color: color)),
      ),
    );
  }
}
