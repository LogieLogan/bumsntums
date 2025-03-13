// lib/features/auth/models/user_profile.dart
import 'package:equatable/equatable.dart';

enum FitnessGoal { weightLoss, toning, strength, endurance, flexibility }
enum FitnessLevel { beginner, intermediate, advanced }

class UserProfile extends Equatable {
  final String userId;
  final String? displayName;
  final String? photoUrl;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final List<FitnessGoal> goals;
  final FitnessLevel fitnessLevel;
  final List<String> dietaryPreferences;
  final List<String> bodyFocusAreas;
  final bool onboardingCompleted;

  const UserProfile({
    required this.userId,
    this.displayName,
    this.photoUrl,
    this.age,
    this.heightCm,
    this.weightKg,
    this.goals = const [],
    this.fitnessLevel = FitnessLevel.beginner,
    this.dietaryPreferences = const [],
    this.bodyFocusAreas = const [],
    this.onboardingCompleted = false,
  });

  @override
  List<Object?> get props => [
        userId,
        displayName,
        photoUrl,
        age,
        heightCm,
        weightKg,
        goals,
        fitnessLevel,
        dietaryPreferences,
        bodyFocusAreas,
        onboardingCompleted,
      ];

  UserProfile copyWith({
    String? displayName,
    String? photoUrl,
    int? age,
    double? heightCm,
    double? weightKg,
    List<FitnessGoal>? goals,
    FitnessLevel? fitnessLevel,
    List<String>? dietaryPreferences,
    List<String>? bodyFocusAreas,
    bool? onboardingCompleted,
  }) {
    return UserProfile(
      userId: userId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goals: goals ?? this.goals,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      bodyFocusAreas: bodyFocusAreas ?? this.bodyFocusAreas,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'goals': goals.map((g) => g.name).toList(),
      'fitnessLevel': fitnessLevel.name,
      'dietaryPreferences': dietaryPreferences,
      'bodyFocusAreas': bodyFocusAreas,
      'onboardingCompleted': onboardingCompleted,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      age: map['age'],
      heightCm: map['heightCm'],
      weightKg: map['weightKg'],
      goals: map['goals'] != null
          ? (map['goals'] as List<dynamic>)
              .map((g) => FitnessGoal.values.firstWhere(
                    (e) => e.name == g,
                    orElse: () => FitnessGoal.weightLoss,
                  ))
              .toList()
          : [],
      fitnessLevel: map['fitnessLevel'] != null
          ? FitnessLevel.values.firstWhere(
              (e) => e.name == map['fitnessLevel'],
              orElse: () => FitnessLevel.beginner,
            )
          : FitnessLevel.beginner,
      dietaryPreferences: map['dietaryPreferences'] != null
          ? List<String>.from(map['dietaryPreferences'])
          : [],
      bodyFocusAreas: map['bodyFocusAreas'] != null
          ? List<String>.from(map['bodyFocusAreas'])
          : [],
      onboardingCompleted: map['onboardingCompleted'] ?? false,
    );
  }

  factory UserProfile.empty(String userId) {
    return UserProfile(
      userId: userId,
    );
  }
}