// lib/features/workouts/models/workout.dart (updated)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'exercise.dart';
import 'workout_section.dart';

enum WorkoutDifficulty { beginner, intermediate, advanced }

enum WorkoutCategory { bums, tums, arms, fullBody, cardio, quickWorkout }

class Workout extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String? youtubeVideoId;
  final WorkoutCategory category;
  final WorkoutDifficulty difficulty;
  final int durationMinutes;
  final int estimatedCaloriesBurn;
  final bool featured;
  final bool isAiGenerated;
  final DateTime createdAt;
  final String createdBy;
  final List<Exercise> exercises;
  final List<String> equipment;
  final List<String> tags;
  final bool downloadsAvailable;

  final String? parentTemplateId;
  final String? previousVersionId;
  final String versionNotes;
  final bool isTemplate;
  final List<WorkoutSection> sections;
  final int timesUsed;
  final DateTime? lastUsed;

  final bool hasAccessibilityOptions;
  final List<String> intensityModifications;

  const Workout({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.youtubeVideoId,
    required this.category,
    required this.difficulty,
    required this.durationMinutes,
    required this.estimatedCaloriesBurn,
    this.featured = false,
    this.isAiGenerated = false,
    required this.createdAt,
    required this.createdBy,
    required this.exercises,
    required this.equipment,
    required this.tags,
    this.downloadsAvailable = false,
    this.hasAccessibilityOptions = false,
    this.intensityModifications = const [],
    this.parentTemplateId,
    this.previousVersionId,
    this.versionNotes = '',
    this.isTemplate = false,
    this.sections = const [],
    this.timesUsed = 0,
    this.lastUsed,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    imageUrl,
    youtubeVideoId,
    category,
    difficulty,
    durationMinutes,
    estimatedCaloriesBurn,
    featured,
    isAiGenerated,
    createdAt,
    createdBy,
    exercises,
    equipment,
    tags,
    downloadsAvailable,
    hasAccessibilityOptions,
    intensityModifications,
    parentTemplateId,
    previousVersionId,
    versionNotes,
    isTemplate,
    sections,
    timesUsed,
    lastUsed,
  ];

  // Method to get all exercises, either from sections or the exercises list
  List<Exercise> getAllExercises() {
    if (sections.isNotEmpty) {
      return sections.expand((section) => section.exercises).toList();
    }
    return exercises;
  }

  Workout copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? youtubeVideoId,
    WorkoutCategory? category,
    WorkoutDifficulty? difficulty,
    int? durationMinutes,
    int? estimatedCaloriesBurn,
    bool? featured,
    bool? isAiGenerated,
    DateTime? createdAt,
    String? createdBy,
    List<Exercise>? exercises,
    List<String>? equipment,
    List<String>? tags,
    bool? downloadsAvailable,
    bool? hasAccessibilityOptions,
    List<String>? intensityModifications,
    String? parentTemplateId,
    String? previousVersionId,
    String? versionNotes,
    bool? isTemplate,
    List<WorkoutSection>? sections,
    int? timesUsed,
    DateTime? lastUsed,
  }) {
    return Workout(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      estimatedCaloriesBurn:
          estimatedCaloriesBurn ?? this.estimatedCaloriesBurn,
      featured: featured ?? this.featured,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      exercises: exercises ?? this.exercises,
      equipment: equipment ?? this.equipment,
      tags: tags ?? this.tags,
      downloadsAvailable: downloadsAvailable ?? this.downloadsAvailable,
      hasAccessibilityOptions:
          hasAccessibilityOptions ?? this.hasAccessibilityOptions,
      intensityModifications:
          intensityModifications ?? this.intensityModifications,
      parentTemplateId: parentTemplateId ?? this.parentTemplateId,
      previousVersionId: previousVersionId ?? this.previousVersionId,
      versionNotes: versionNotes ?? this.versionNotes,
      isTemplate: isTemplate ?? this.isTemplate,
      sections: sections ?? this.sections,
      timesUsed: timesUsed ?? this.timesUsed,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'youtubeVideoId': youtubeVideoId,
      'category': category.name,
      'difficulty': difficulty.name,
      'durationMinutes': durationMinutes,
      'estimatedCaloriesBurn': estimatedCaloriesBurn,
      'featured': featured,
      'isAiGenerated': isAiGenerated,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'equipment': equipment,
      'tags': tags,
      'downloadsAvailable': downloadsAvailable,
      'hasAccessibilityOptions': hasAccessibilityOptions,
      'intensityModifications': intensityModifications,
      'parentTemplateId': parentTemplateId,
      'previousVersionId': previousVersionId,
      'versionNotes': versionNotes,
      'isTemplate': isTemplate,
      'sections': sections.map((s) => s.toMap()).toList(),
      'timesUsed': timesUsed,
      'lastUsed': lastUsed?.millisecondsSinceEpoch,
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      youtubeVideoId: map['youtubeVideoId'],
      category: WorkoutCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => WorkoutCategory.fullBody,
      ),
      difficulty: WorkoutDifficulty.values.firstWhere(
        (e) => e.name == map['difficulty'],
        orElse: () => WorkoutDifficulty.beginner,
      ),
      durationMinutes: map['durationMinutes']?.toInt() ?? 0,
      estimatedCaloriesBurn: map['estimatedCaloriesBurn']?.toInt() ?? 0,
      featured: map['featured'] ?? false,
      isAiGenerated: map['isAiGenerated'] ?? false,
      createdAt:
          map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : (map['createdAt'] is int
                  ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
                  : DateTime.now()),
      createdBy: map['createdBy'] ?? '',
      exercises:
          map['exercises'] != null
              ? List<Exercise>.from(
                map['exercises']?.map((x) => Exercise.fromMap(x)),
              )
              : [],
      equipment: List<String>.from(map['equipment'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      downloadsAvailable: map['downloadsAvailable'] ?? false,
      hasAccessibilityOptions: map['hasAccessibilityOptions'] ?? false,
      intensityModifications: List<String>.from(
        map['intensityModifications'] ?? [],
      ),
      parentTemplateId: map['parentTemplateId'],
      previousVersionId: map['previousVersionId'],
      versionNotes: map['versionNotes'] ?? '',
      isTemplate: map['isTemplate'] ?? false,
      sections:
          map['sections'] != null
              ? List<WorkoutSection>.from(
                map['sections']?.map((x) => WorkoutSection.fromMap(x)),
              )
              : [],
      timesUsed: map['timesUsed']?.toInt() ?? 0,
      lastUsed:
          map['lastUsed'] != null
              ? (map['lastUsed'] is Timestamp
                  ? (map['lastUsed'] as Timestamp).toDate()
                  : (map['lastUsed'] is int
                      ? DateTime.fromMillisecondsSinceEpoch(map['lastUsed'])
                      : null))
              : null,
    );
  }

  // Create a copy as a template
  Workout asTemplate() {
    return copyWith(
      id: 'template-${id.split('-').last}',
      isTemplate: true,
      timesUsed: 0,
      lastUsed: null,
    );
  }

  // Create a new version with a reference to this one as previous
  Workout createNewVersion({
    required String newVersionId,
    String? versionNotes,
  }) {
    return copyWith(
      id: newVersionId,
      previousVersionId: id,
      versionNotes: versionNotes ?? 'Updated version',
      createdAt: DateTime.now(),
    );
  }

  // Convert sections to exercises for backward compatibility
  List<Exercise> getSectionsAsExercises() {
    if (sections.isEmpty) {
      return exercises;
    }
    return sections.expand((section) => section.exercises).toList();
  }

  // Create sections from exercises (for upgrading old workouts)
  static List<WorkoutSection> createSectionsFromExercises(
    List<Exercise> exercises,
  ) {
    if (exercises.isEmpty) {
      return [];
    }

    return [
      WorkoutSection(
        id: 'section-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Main Workout',
        exercises: exercises,
      ),
    ];
  }
}
