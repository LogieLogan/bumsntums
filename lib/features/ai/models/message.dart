// lib/features/ai/models/message.dart
import 'package:equatable/equatable.dart';

enum MessageRole { system, user, assistant }

class Message extends Equatable {
  final String id;
  final String content;
  final bool isUserMessage; // Keep for backward compatibility
  final MessageRole role; // Add role enum
  final DateTime timestamp;
  final String? category;
  final Map<String, dynamic>? metadata;
  final bool isPositiveFeedback;
  final bool isNegativeFeedback;
  final bool isPinned; // Add isPinned property

  const Message({
    required this.id,
    required this.content,
    required this.isUserMessage,
    required this.role,
    required this.timestamp,
    this.category,
    this.metadata,
    this.isPositiveFeedback = false,
    this.isNegativeFeedback = false,
    this.isPinned = false, // Default to false
  });

  @override
  List<Object?> get props => [
    id,
    content,
    isUserMessage,
    role,
    timestamp,
    category,
    metadata,
    isPositiveFeedback,
    isNegativeFeedback,
    isPinned,
  ];

  Map<String, String> toOpenAIFormat() {
    return {'role': role.name, 'content': content};
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'isUserMessage': isUserMessage,
      'role': role.name,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
      'metadata': metadata,
      'isPositiveFeedback': isPositiveFeedback,
      'isNegativeFeedback': isNegativeFeedback,
      'isPinned': isPinned,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      content: map['content'],
      isUserMessage: map['isUserMessage'],
      role:
          map['role'] != null
              ? MessageRole.values.firstWhere(
                (e) => e.name == map['role'],
                orElse:
                    () =>
                        map['isUserMessage']
                            ? MessageRole.user
                            : MessageRole.assistant,
              )
              : (map['isUserMessage']
                  ? MessageRole.user
                  : MessageRole.assistant),
      timestamp: DateTime.parse(map['timestamp']),
      category: map['category'],
      metadata: map['metadata'],
      isPositiveFeedback: map['isPositiveFeedback'] ?? false,
      isNegativeFeedback: map['isNegativeFeedback'] ?? false,
      isPinned: map['isPinned'] ?? false,
    );
  }

  Message copyWith({
    String? content,
    Map<String, dynamic>? metadata,
    bool? isPositiveFeedback,
    bool? isNegativeFeedback,
    bool? isPinned,
  }) {
    return Message(
      id: id,
      content: content ?? this.content,
      isUserMessage: isUserMessage,
      role: role,
      timestamp: timestamp,
      category: category,
      metadata: metadata ?? this.metadata,
      isPositiveFeedback: isPositiveFeedback ?? this.isPositiveFeedback,
      isNegativeFeedback: isNegativeFeedback ?? this.isNegativeFeedback,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  static Message system({
    required String content,
    Map<String, dynamic>? metadata,
    bool isPinned = false,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUserMessage: false,
      role: MessageRole.system,
      timestamp: DateTime.now(),
      metadata: metadata,
      isPinned: isPinned,
    );
  }

  static Message user({
    required String content,
    Map<String, dynamic>? metadata,
    bool isPinned = false,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUserMessage: true,
      role: MessageRole.user,
      timestamp: DateTime.now(),
      metadata: metadata,
      isPinned: isPinned,
    );
  }

  static Message assistant({
    required String content,
    String? category,
    Map<String, dynamic>? metadata,
    bool isPinned = false,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUserMessage: false,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      category: category,
      metadata: metadata,
      isPinned: isPinned,
    );
  }
}
