// lib/features/ai/models/conversation.dart
import 'package:equatable/equatable.dart';
import 'message.dart';

enum ConversationCategory {
  general,
  workoutCreation,
  planCreation,
  nutritionAdvice,
  motivationalSupport,
  formGuidance
}

class Conversation extends Equatable {
  final String id;
  final String title;
  final ConversationCategory category;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final List<Message> messages;
  final Map<String, dynamic> metadata;
  final String userId;
  
  const Conversation({
    required this.id,
    required this.title,
    required this.category,
    required this.createdAt,
    required this.lastMessageAt,
    required this.messages,
    required this.userId,
    this.metadata = const {},
  });

  @override
  List<Object?> get props => [
    id, title, category, createdAt, lastMessageAt, messages, metadata, userId
  ];

  int get messageCount => messages.length;

  Conversation copyWith({
    String? title,
    DateTime? lastMessageAt,
    List<Message>? messages,
    Map<String, dynamic>? metadata,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      category: category,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messages: messages ?? this.messages,
      userId: userId,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastMessageAt': lastMessageAt.millisecondsSinceEpoch,
      'messageCount': messages.length,
      'metadata': metadata,
      'userId': userId,
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map, List<Message> messages) {
    return Conversation(
      id: map['id'],
      title: map['title'],
      category: ConversationCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ConversationCategory.general,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      lastMessageAt: DateTime.fromMillisecondsSinceEpoch(map['lastMessageAt']),
      messages: messages,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      userId: map['userId'],
    );
  }

  static Conversation create({
    required String userId,
    required String title,
    required ConversationCategory category,
    List<Message> messages = const [],
    Map<String, dynamic> metadata = const {},
  }) {
    final now = DateTime.now();
    return Conversation(
      id: 'conv-${now.millisecondsSinceEpoch}',
      title: title,
      category: category,
      createdAt: now,
      lastMessageAt: now,
      messages: messages,
      userId: userId,
      metadata: metadata,
    );
  }
}