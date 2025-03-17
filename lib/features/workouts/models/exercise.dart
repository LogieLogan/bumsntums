// lib/features/workouts/models/exercise.dart
import 'package:equatable/equatable.dart';

class Exercise extends Equatable {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String? youtubeVideoId;
  final int sets;
  final int reps; // If time-based, this could be 0
  final int? durationSeconds; // For timed exercises
  final int restBetweenSeconds;
  final String targetArea; // bums, tums, etc.
  
  // Accessibility features
  final List<ExerciseModification> modifications;

  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.youtubeVideoId,
    required this.sets,
    required this.reps,
    this.durationSeconds,
    required this.restBetweenSeconds,
    required this.targetArea,
    this.modifications = const [],
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    imageUrl,
    youtubeVideoId,
    sets,
    reps,
    durationSeconds,
    restBetweenSeconds,
    targetArea,
    modifications,
  ];

  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? youtubeVideoId,
    int? sets,
    int? reps,
    int? durationSeconds,
    int? restBetweenSeconds,
    String? targetArea,
    List<ExerciseModification>? modifications,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      restBetweenSeconds: restBetweenSeconds ?? this.restBetweenSeconds,
      targetArea: targetArea ?? this.targetArea,
      modifications: modifications ?? this.modifications,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'youtubeVideoId': youtubeVideoId,
      'sets': sets,
      'reps': reps,
      'durationSeconds': durationSeconds,
      'restBetweenSeconds': restBetweenSeconds,
      'targetArea': targetArea,
      'modifications': modifications.map((m) => m.toMap()).toList(),
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      youtubeVideoId: map['youtubeVideoId'],
      sets: map['sets']?.toInt() ?? 0,
      reps: map['reps']?.toInt() ?? 0,
      durationSeconds: map['durationSeconds']?.toInt(),
      restBetweenSeconds: map['restBetweenSeconds']?.toInt() ?? 0,
      targetArea: map['targetArea'] ?? '',
      modifications: map['modifications'] != null
          ? List<ExerciseModification>.from(
              map['modifications']?.map((x) => ExerciseModification.fromMap(x)))
          : [],
    );
  }
}

class ExerciseModification extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? videoUrl;
  final List<String> forAccessibilityNeeds;
  
  const ExerciseModification({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.videoUrl,
    this.forAccessibilityNeeds = const [],
  });
  
  @override
  List<Object?> get props => [
    id,
    title,
    description,
    imageUrl,
    videoUrl,
    forAccessibilityNeeds,
  ];
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'forAccessibilityNeeds': forAccessibilityNeeds,
    };
  }
  
  factory ExerciseModification.fromMap(Map<String, dynamic> map) {
    return ExerciseModification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      videoUrl: map['videoUrl'],
      forAccessibilityNeeds: List<String>.from(map['forAccessibilityNeeds'] ?? []),
    );
  }
}