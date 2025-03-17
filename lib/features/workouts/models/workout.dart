// lib/features/workouts/models/workout.dart
import 'package:equatable/equatable.dart';
import 'exercise.dart';

enum WorkoutDifficulty { beginner, intermediate, advanced }
enum WorkoutCategory { bums, tums, fullBody, cardio, quickWorkout }

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
  final String createdBy; // admin, ai, userId
  final List<Exercise> exercises;
  final List<String> equipment; // none, mat, dumbbells, etc.
  final List<String> tags; // quick, intense, recovery, etc.
  final bool downloadsAvailable; // for offline access
  
  // Accessibility and personalization
  final bool hasAccessibilityOptions;
  final List<String> intensityModifications; // options to modify intensity

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
  ];

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
      estimatedCaloriesBurn: estimatedCaloriesBurn ?? this.estimatedCaloriesBurn,
      featured: featured ?? this.featured,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      exercises: exercises ?? this.exercises,
      equipment: equipment ?? this.equipment,
      tags: tags ?? this.tags,
      downloadsAvailable: downloadsAvailable ?? this.downloadsAvailable,
      hasAccessibilityOptions: hasAccessibilityOptions ?? this.hasAccessibilityOptions,
      intensityModifications: intensityModifications ?? this.intensityModifications,
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
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      createdBy: map['createdBy'] ?? '',
      exercises: map['exercises'] != null
          ? List<Exercise>.from(
              map['exercises']?.map((x) => Exercise.fromMap(x)))
          : [],
      equipment: List<String>.from(map['equipment'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      downloadsAvailable: map['downloadsAvailable'] ?? false,
      hasAccessibilityOptions: map['hasAccessibilityOptions'] ?? false,
      intensityModifications: List<String>.from(map['intensityModifications'] ?? []),
    );
  }
}