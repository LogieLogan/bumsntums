// lib/features/ai/screens/chat_sessions_list_screen.dart

import 'package:bums_n_tums/features/ai/services/chat_session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

import 'package:bums_n_tums/features/auth/providers/user_provider.dart';
import 'package:bums_n_tums/shared/components/indicators/loading_indicator.dart';
import 'package:bums_n_tums/shared/theme/app_colors.dart';
import 'package:bums_n_tums/shared/theme/app_text_styles.dart';
import 'ai_chat_screen.dart'; // We will navigate to this

// --- Data Model for a Chat Session ---
// Represents the document stored at users/{userId}/chatSessions/{sessionId}
class ChatSession {
  final String id; // Document ID == sessionId
  final String? title; // Optional AI-generated title
  final Timestamp createdAt;
  final Timestamp lastUpdatedAt;

  ChatSession({
    required this.id,
    this.title,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  factory ChatSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatSession(
      id: doc.id,
      title: data['title'] as String?,
      // Provide default timestamps if missing, although they should be set on creation
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      lastUpdatedAt: data['lastUpdatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }
}

// --- Provider to fetch Chat Sessions ---
// Uses .family because we need the userId
// Uses StreamProvider to get real-time updates
final chatSessionsProvider = StreamProvider.autoDispose
    .family<List<ChatSession>, String>((ref, userId) {
      final firestore = FirebaseFirestore.instance;
      try {
        return firestore
            .collection('users')
            .doc(userId)
            .collection('chatSessions')
            .orderBy('lastUpdatedAt', descending: true) // Show newest first
            .snapshots() // Listen for real-time changes
            .map(
              (snapshot) =>
                  snapshot.docs
                      .map((doc) => ChatSession.fromFirestore(doc))
                      .toList(),
            );
      } catch (e) {
        debugPrint("Error fetching chat sessions: $e");
        // Return an empty stream or stream with error if needed
        return Stream.value([]);
      }
    });

// --- Chat Sessions List Screen Widget ---
class ChatSessionsListScreen extends ConsumerWidget {
  const ChatSessionsListScreen({super.key});

  Future<void> _createNewChat(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final now = Timestamp.now();
    try {
      // Create the new session document in Firestore
      final newSessionRef =
          firestore
              .collection('users')
              .doc(userId)
              .collection('chatSessions')
              .doc(); // Auto-generate ID

      await newSessionRef.set({
        'title': 'New Chat', // Default title
        'createdAt': now,
        'lastUpdatedAt': now,
      });

      final newSessionId = newSessionRef.id;
      debugPrint("Created new chat session with ID: $newSessionId");

      // Optional: Add initial welcome message to the subcollection
      // await newSessionRef.collection('messages').add({
      //    'content': "Hi there! How can I help you today?",
      //    'isUserMessage': false,
      //    'timestamp': now,
      //    // Add other Message fields...
      // });

      // Navigate to the AIChatScreen for the new session
      if (context.mounted) {
        // Check context validity before navigation
        Navigator.of(context).push(
          MaterialPageRoute(
            // Pass the new sessionId to AIChatScreen
            // ** We will modify AIChatScreen later to accept this **
            builder: (context) => AIChatScreen(sessionId: newSessionId),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error creating new chat session: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting new chat: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Chat History')),
      body: userProfileAsync.when(
        data: (userProfile) {
          if (userProfile == null) {
            return const Center(child: Text('User profile not loaded.'));
          }
          final userId = userProfile.userId;
          final sessionsAsync = ref.watch(chatSessionsProvider(userId));

          return sessionsAsync.when(
            data: (sessions) {
              if (sessions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 60,
                        color: AppColors.mediumGrey,
                      ),
                      const SizedBox(height: 16),
                      Text('No chat history yet.', style: AppTextStyles.body),
                      const SizedBox(height: 8),
                      Text('Start a new chat!', style: AppTextStyles.body),
                    ],
                  ),
                );
              }
              // Display list of sessions
              return ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return Dismissible(
                    // --- Unique Key is REQUIRED ---
                    key: Key(session.id),

                    // --- Direction: Swipe Left ---
                    direction: DismissDirection.endToStart,

                    // --- Background shown during swipe-left ---
                    background: Container(
                      color: AppColors.error.withOpacity(
                        0.9,
                      ), // Use error color
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerRight,
                      child: const Icon(
                        Icons.delete_sweep_outlined,
                        color: Colors.white,
                      ),
                    ),

                    // --- Confirmation Dialog (Recommended UX) ---
                    confirmDismiss: (direction) async {
                      // Only confirm for the direction we care about
                      if (direction == DismissDirection.endToStart) {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Delete Chat?'),
                              content: Text(
                                'Are you sure you want to permanently delete "${session.title ?? 'this chat'}"?',
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(
                                        false,
                                      ), // Dismiss dialog, return false
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                  ),
                                  onPressed:
                                      () => Navigator.of(context).pop(
                                        true,
                                      ), // Dismiss dialog, return true
                                  child: const Text('Delete'),
                                ),
                              ],
                            );
                          },
                        );
                        // Return the result of the dialog (true if confirmed, false/null otherwise)
                        return confirmed ?? false;
                      }
                      return false; // Should not happen if direction is restricted
                    },

                    // --- Action AFTER successful dismiss ---
                    onDismissed: (direction) {
                      if (direction == DismissDirection.endToStart) {
                        debugPrint(
                          "Dismissible: Deleting session ${session.id}",
                        );
                        // Call the service to delete data
                        ref
                            .read(chatSessionServiceProvider)
                            .deleteChatSession(userId, session.id)
                            .catchError((e) {
                              // Show error if deletion fails (optional but good)
                              debugPrint(
                                "Error deleting session via Dismissible: $e",
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Failed to delete chat: ${e.toString()}",
                                    ),
                                  ),
                                );
                              }
                              // Note: The item is already visually dismissed.
                              // You might need to manually refresh the provider list
                              // if the stream doesn't update automatically on error.
                              // ref.refresh(chatSessionsProvider(userId)); // Example refresh
                            });

                        // Optional: Show a confirmation SnackBar
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   SnackBar(content: Text('"${session.title ?? 'Chat'}" deleted'))
                        // );
                      }
                    },
                    child: ListTile(
                      leading: Icon(Icons.chat_bubble, color: AppColors.salmon),
                      title: Text(
                        session.title ??
                            'Chat Session', // Use default if no title
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        // Format timestamp nicely
                        'Last message: ${DateFormat.yMd().add_jm().format(session.lastUpdatedAt.toDate())}',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.mediumGrey,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        debugPrint("Tapped on session: ${session.id}");
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            // Pass the existing sessionId to AIChatScreen
                            // ** We will modify AIChatScreen later to accept this **
                            builder:
                                (context) =>
                                    AIChatScreen(sessionId: session.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const LoadingIndicator(message: 'Loading chats...'),
            error:
                (err, stack) =>
                    Center(child: Text('Error loading chat history: $err')),
          );
        },
        loading: () => const LoadingIndicator(message: 'Loading user...'),
        error:
            (err, stack) =>
                Center(child: Text('Error loading user profile: $err')),
      ),
      floatingActionButton: userProfileAsync.maybeWhen(
        data:
            (userProfile) =>
                userProfile != null
                    ? FloatingActionButton.extended(
                      onPressed:
                          () =>
                              _createNewChat(context, ref, userProfile.userId),
                      icon: const Icon(Icons.add),
                      label: const Text('New Chat'),
                      backgroundColor: AppColors.salmon,
                    )
                    : null, // Hide FAB if user not loaded
        orElse: () => null, // Hide FAB during loading/error
      ),
    );
  }
}
