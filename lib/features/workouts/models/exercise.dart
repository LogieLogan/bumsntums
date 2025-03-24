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
  
  // Enhanced personalization fields
  final double? weight; // Weight used for the exercise (kg/lbs)
  final int? resistanceLevel; // For resistance bands (1-5)
  final Map<String, dynamic>? tempo; // Tempo for the exercise (down-hold-up)
  final int difficultyLevel; // More granular difficulty (1-5)
  final List<String> targetMuscles; // Specific muscles targeted
  final List<String> formTips; // Tips for proper form
  final List<String> commonMistakes; // Common mistakes to avoid
  final List<String> progressionExercises; // Harder variations
  final List<String> regressionExercises; // Easier variations
  
  // Accessibility features
  final List<ExerciseModification> modifications;
  
  // Equipment options
  final List<String> equipmentOptions; // Alternative equipment that can be used

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
    this.weight,
    this.resistanceLevel,
    this.tempo,
    this.difficultyLevel = 3, // Default to middle difficulty
    this.targetMuscles = const [],
    this.formTips = const [],
    this.commonMistakes = const [],
    this.progressionExercises = const [],
    this.regressionExercises = const [],
    this.modifications = const [],
    this.equipmentOptions = const [],
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
    weight,
    resistanceLevel,
    tempo,
    difficultyLevel,
    targetMuscles,
    formTips,
    commonMistakes,
    progressionExercises,
    regressionExercises,
    modifications,
    equipmentOptions,
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
    double? weight,
    int? resistanceLevel,
    Map<String, dynamic>? tempo,
    int? difficultyLevel,
    List<String>? targetMuscles,
    List<String>? formTips,
    List<String>? commonMistakes,
    List<String>? progressionExercises,
    List<String>? regressionExercises,
    List<ExerciseModification>? modifications,
    List<String>? equipmentOptions,
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
      weight: weight ?? this.weight,
      resistanceLevel: resistanceLevel ?? this.resistanceLevel,
      tempo: tempo ?? this.tempo,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      formTips: formTips ?? this.formTips,
      commonMistakes: commonMistakes ?? this.commonMistakes,
      progressionExercises: progressionExercises ?? this.progressionExercises,
      regressionExercises: regressionExercises ?? this.regressionExercises,
      modifications: modifications ?? this.modifications,
      equipmentOptions: equipmentOptions ?? this.equipmentOptions,
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
      'weight': weight,
      'resistanceLevel': resistanceLevel,
      'tempo': tempo,
      'difficultyLevel': difficultyLevel,
      'targetMuscles': targetMuscles,
      'formTips': formTips,
      'commonMistakes': commonMistakes,
      'progressionExercises': progressionExercises,
      'regressionExercises': regressionExercises,
      'modifications': modifications.map((m) => m.toMap()).toList(),
      'equipmentOptions': equipmentOptions,
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
      weight: map['weight']?.toDouble(),
      resistanceLevel: map['resistanceLevel']?.toInt(),
      tempo: map['tempo'] != null ? Map<String, dynamic>.from(map['tempo']) : null,
      difficultyLevel: map['difficultyLevel']?.toInt() ?? 3,
      targetMuscles: map['targetMuscles'] != null 
          ? List<String>.from(map['targetMuscles']) 
          : [],
      formTips: map['formTips'] != null 
          ? List<String>.from(map['formTips']) 
          : [],
      commonMistakes: map['commonMistakes'] != null 
          ? List<String>.from(map['commonMistakes']) 
          : [],
      progressionExercises: map['progressionExercises'] != null 
          ? List<String>.from(map['progressionExercises']) 
          : [],
      regressionExercises: map['regressionExercises'] != null 
          ? List<String>.from(map['regressionExercises']) 
          : [],
      modifications: map['modifications'] != null
          ? List<ExerciseModification>.from(
              map['modifications']?.map((x) => ExerciseModification.fromMap(x)))
          : [],
      equipmentOptions: map['equipmentOptions'] != null 
          ? List<String>.from(map['equipmentOptions']) 
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