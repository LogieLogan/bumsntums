// lib/features/ai/screens/ai_chat_screen.dart
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
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
    if (!mounted) return; // Check if widget is still mounted

    final userProfile = await ref.read(userProfileProvider.future);
    if (!mounted) return; // Check again after the await

    if (userProfile != null) {
      await ref
          .read(aiChatProvider.notifier)
          .loadConversation(userProfile.userId);
    }
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
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final userProfile = await ref.read(userProfileProvider.future);
    if (userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load user profile')),
      );
      return;
    }

    _messageController.clear();

    // Send message with userId instead of userProfile
    await ref
        .read(aiChatProvider.notifier)
        .sendMessage(userId: userProfile.userId, message: message);

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    // Add this at the start of your build method to handle environment initialization
    final envInitState = ref.watch(environmentServiceInitProvider);

    if (envInitState is AsyncLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Fitness Coach')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (envInitState is AsyncError) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Fitness Coach')),
        body: Center(
          child: Text(
            'Error initializing chat: ${envInitState.error}',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      );
    }

    // Continue with your original build code for when environment is initialized
    final chatState = ref.watch(aiChatProvider);

    if (chatState.error != null) {
      String errorMessage = chatState.error!;

      // Handle rate limit errors with more user-friendly message
      if (chatState.error!.contains('Rate limit exceeded')) {
        errorMessage = chatState.error!;
      } else {
        errorMessage = 'Something went wrong. Please try again later.';
      }

      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(errorMessage, style: TextStyle(color: AppColors.error)),
        ),
      );
    }

    // Auto-scroll when new messages arrive
    if (chatState.messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Fitness Coach'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              ref.read(aiChatProvider.notifier).clearChat();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Welcome message if no messages
          if (chatState.messages.isEmpty)
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 64,
                        color: AppColors.salmon.withOpacity(0.5),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Your AI Fitness Coach',
                        style: AppTextStyles.h2,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ask me anything about workouts, nutrition, or fitness advice tailored to your goals!',
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Workouts category
                      _buildSuggestionCategory(
                        title: 'Workout Ideas',
                        icon: Icons.fitness_center,
                        color: AppColors.salmon,
                        suggestions: [
                          'Create a quick bums workout',
                          'What\'s a good full-body stretch routine?',
                          'How do I do a proper squat?',
                          'Suggest exercises without equipment',
                        ],
                        showWorkoutGeneratorLink: true,
                      ),

                      const SizedBox(height: 20),

                      // Nutrition category
                      _buildSuggestionCategory(
                        title: 'Nutrition Advice',
                        icon: Icons.restaurant,
                        color: AppColors.popGreen,
                        suggestions: [
                          'What should I eat before a workout?',
                          'How much protein do I need?',
                          'Quick post-workout meal ideas',
                          'How can I reduce sugar cravings?',
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Motivation category
                      _buildSuggestionCategory(
                        title: 'Motivation & Tips',
                        icon: Icons.psychology,
                        color: AppColors.popBlue,
                        suggestions: [
                          'How to stay consistent with workouts?',
                          'I feel discouraged, what should I do?',
                          'Tips for morning workout routine',
                          'How long until I see results?',
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Chat messages
          if (chatState.messages.isNotEmpty)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: chatState.messages.length,
                itemBuilder: (context, index) {
                  final message = chatState.messages[index];
                  return _ChatMessageWidget(
                    message: message,
                    onFeedback:
                        !message.isUserMessage
                            ? (isPositive) async {
                              await ref
                                  .read(aiChatProvider.notifier)
                                  .provideMessageFeedback(
                                    messageId: message.id,
                                    isPositive: isPositive,
                                  );
                            }
                            : null,
                    onActionLink: (action) {
                      // Handle special links/actions
                      if (action == 'workout_generator') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AIWorkoutScreen(),
                          ),
                        );
                      }
                      // Add other action handlers as needed
                    },
                  );
                },
              ),
            ),

          // Loading indicator
          if (chatState.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),

          // Error message
          if (chatState.error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Error: ${chatState.error}',
                style: TextStyle(color: AppColors.error),
              ),
            ),

          // Input area
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: chatState.isLoading ? null : _sendMessage,
                  backgroundColor: AppColors.salmon,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCategory({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> suggestions,
    bool showWorkoutGeneratorLink = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.h3.copyWith(color: color, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                suggestions.map((suggestion) {
                  return _SuggestionChip(
                    label: suggestion,
                    color: color,
                    onTap: () {
                      _messageController.text = suggestion;
                      _sendMessage();
                    },
                  );
                }).toList(),
          ),
          // Add workout generator button if requested
          if (showWorkoutGeneratorLink) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AIWorkoutScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.salmon,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Create Custom Workout',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
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
    // Process content to detect and extract action links
    String displayContent = message.content;
    Map<String, String> actionLinks = {};

    // Look for pattern [Text](action_name)
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
            // Build rich text with action links
            _buildRichText(context, displayContent, actionLinks),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: AppTextStyles.caption,
                ),

                // Only show feedback options for AI messages
                if (!message.isUserMessage && onFeedback != null) ...[
                  const Spacer(),
                  // Thumbs up button
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
                  // Thumbs down button
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
      // Add normal text
      if (part.isNotEmpty) {
        spans.add(TextSpan(text: part));
      }

      // Add action link if there is one
      if (i < parts.length - 1) {
        String placeholder = '---ACTION_LINK_$i---';
        String? action = actionLinks[placeholder];

        if (action != null) {
          String linkText = '';

          // Extract the original link text from the content
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
