// lib/features/ai/models/personality_settings.dart
import 'package:equatable/equatable.dart';

enum ToneLevel { formal, balanced, casual }
enum DetailLevel { minimal, balanced, detailed }
enum HumorLevel { none, occasional, frequent }
enum EncouragementLevel { minimal, moderate, supportive }

class PersonalitySettings extends Equatable {
  final String id;
  final String name;
  final String description;
  final ToneLevel tone;
  final DetailLevel detailLevel;
  final HumorLevel humorLevel;
  final EncouragementLevel encouragementLevel;
  final Map<String, dynamic> additionalTraits;
  
  const PersonalitySettings({
    required this.id,
    required this.name,
    required this.description,
    this.tone = ToneLevel.balanced,
    this.detailLevel = DetailLevel.balanced,
    this.humorLevel = HumorLevel.occasional,
    this.encouragementLevel = EncouragementLevel.moderate,
    this.additionalTraits = const {},
  });

  @override
  List<Object?> get props => [
    id, name, description, tone, detailLevel, humorLevel, encouragementLevel, additionalTraits
  ];

  PersonalitySettings copyWith({
    String? name,
    String? description,
    ToneLevel? tone,
    DetailLevel? detailLevel,
    HumorLevel? humorLevel,
    EncouragementLevel? encouragementLevel,
    Map<String, dynamic>? additionalTraits,
  }) {
    return PersonalitySettings(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      tone: tone ?? this.tone,
      detailLevel: detailLevel ?? this.detailLevel,
      humorLevel: humorLevel ?? this.humorLevel,
      encouragementLevel: encouragementLevel ?? this.encouragementLevel,
      additionalTraits: additionalTraits ?? this.additionalTraits,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'tone': tone.name,
      'detailLevel': detailLevel.name,
      'humorLevel': humorLevel.name,
      'encouragementLevel': encouragementLevel.name,
      'additionalTraits': additionalTraits,
    };
  }

  factory PersonalitySettings.fromMap(Map<String, dynamic> map) {
    return PersonalitySettings(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      tone: ToneLevel.values.firstWhere(
        (e) => e.name == map['tone'],
        orElse: () => ToneLevel.balanced,
      ),
      detailLevel: DetailLevel.values.firstWhere(
        (e) => e.name == map['detailLevel'],
        orElse: () => DetailLevel.balanced,
      ),
      humorLevel: HumorLevel.values.firstWhere(
        (e) => e.name == map['humorLevel'],
        orElse: () => HumorLevel.occasional,
      ),
      encouragementLevel: EncouragementLevel.values.firstWhere(
        (e) => e.name == map['encouragementLevel'],
        orElse: () => EncouragementLevel.moderate,
      ),
      additionalTraits: Map<String, dynamic>.from(map['additionalTraits'] ?? {}),
    );
  }

  static PersonalitySettings defaultPersonality() {
    return PersonalitySettings(
      id: 'default',
      name: 'Friendly Coach',
      description: 'Encouraging and friendly fitness coach with occasional humor.',
      tone: ToneLevel.balanced,
      detailLevel: DetailLevel.balanced,
      humorLevel: HumorLevel.occasional,
      encouragementLevel: EncouragementLevel.supportive,
    );
  }

  String getPromptModifier() {
    final modifiers = <String>[];
    
    // Tone modifiers
    switch (tone) {
      case ToneLevel.formal:
        modifiers.add("Maintain a professional, formal tone");
        break;
      case ToneLevel.balanced:
        modifiers.add("Use a balanced, friendly tone");
        break;
      case ToneLevel.casual:
        modifiers.add("Use a casual, conversational tone");
        break;
    }
    
    // Detail modifiers
    switch (detailLevel) {
      case DetailLevel.minimal:
        modifiers.add("Keep explanations brief and concise");
        break;
      case DetailLevel.balanced:
        modifiers.add("Provide balanced level of detail in explanations");
        break;
      case DetailLevel.detailed:
        modifiers.add("Offer thorough explanations and context");
        break;
    }
    
    // Humor modifiers
    switch (humorLevel) {
      case HumorLevel.none:
        modifiers.add("Maintain a serious tone without humor");
        break;
      case HumorLevel.occasional:
        modifiers.add("Use occasional light humor");
        break;
      case HumorLevel.frequent:
        modifiers.add("Incorporate frequent humor and lightheartedness");
        break;
    }
    
    // Encouragement modifiers
    switch (encouragementLevel) {
      case EncouragementLevel.minimal:
        modifiers.add("Focus on facts with minimal encouragement");
        break;
      case EncouragementLevel.moderate:
        modifiers.add("Provide moderate encouragement");
        break;
      case EncouragementLevel.supportive:
        modifiers.add("Be highly encouraging and supportive");
        break;
    }
    
    return modifiers.join(". ") + ".";
  }
}