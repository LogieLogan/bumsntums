// lib/features/workouts/models/workout_section.dart
import 'package:equatable/equatable.dart';
import 'exercise.dart';

enum SectionType { normal, circuit, superset }

class WorkoutSection extends Equatable {
  final String id;
  final String name;
  final List<Exercise> exercises;
  final int restAfterSection;
  final SectionType type;

  const WorkoutSection({
    required this.id,
    required this.name,
    required this.exercises,
    this.restAfterSection = 60,
    this.type = SectionType.normal,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    exercises,
    restAfterSection,
    type,
  ];

  WorkoutSection copyWith({
    String? id,
    String? name,
    List<Exercise>? exercises,
    int? restAfterSection,
    SectionType? type,
  }) {
    return WorkoutSection(
      id: id ?? this.id,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      restAfterSection: restAfterSection ?? this.restAfterSection,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'restAfterSection': restAfterSection,
      'type': type.name,
    };
  }

  factory WorkoutSection.fromMap(Map<String, dynamic> map) {
    return WorkoutSection(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      exercises: map['exercises'] != null
          ? List<Exercise>.from(
              map['exercises']?.map((x) => Exercise.fromMap(x)))
          : [],
      restAfterSection: map['restAfterSection']?.toInt() ?? 60,
      type: SectionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SectionType.normal,
      ),
    );
  }
}