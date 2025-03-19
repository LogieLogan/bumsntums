// lib/features/ai/screens/ai_chat_screen.dart
import 'package:bums_n_tums/shared/providers/environment_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../features/auth/providers/user_provider.dart';
import '../providers/ai_chat_provider.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

    // Send message
    await ref
        .read(aiChatProvider.notifier)
        .sendMessage(userProfile: userProfile, message: message);

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
              child: Center(
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _SuggestionChip(
                            label: 'Create a workout for me',
                            onTap: () {
                              _messageController.text =
                                  'Create a workout for me';
                              _sendMessage();
                            },
                          ),
                          _SuggestionChip(
                            label: 'Nutrition tips for my goals',
                            onTap: () {
                              _messageController.text =
                                  'Give me nutrition tips for my fitness goals';
                              _sendMessage();
                            },
                          ),
                          _SuggestionChip(
                            label: 'How to stay motivated?',
                            onTap: () {
                              _messageController.text =
                                  'How can I stay motivated with my workouts?';
                              _sendMessage();
                            },
                          ),
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
                  return _ChatMessageWidget(message: message);
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
}

class _ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;

  const _ChatMessageWidget({required this.message});

  @override
  Widget build(BuildContext context) {
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
            Text(message.content, style: AppTextStyles.body),
            const SizedBox(height: 4),
            Text(_formatTime(message.timestamp), style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.salmon.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.salmon.withOpacity(0.3)),
        ),
        child: Text(label, style: TextStyle(color: AppColors.salmon)),
      ),
    );
  }
}
