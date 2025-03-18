// lib/features/auth/models/user_profile.dart
import 'package:equatable/equatable.dart';

enum FitnessGoal { weightLoss, toning, strength, endurance, flexibility }
enum FitnessLevel { beginner, intermediate, advanced }
enum WorkoutLocation { home, gym, outdoors, anywhere }
enum MotivationType { appearance, health, energy, stress, confidence, other }

class UserProfile extends Equatable {
  final String userId;
  final DateTime? dateOfBirth;
  final double? heightCm;
  final double? weightKg;
  final List<FitnessGoal> goals;
  final FitnessLevel fitnessLevel;
  final List<String> dietaryPreferences;
  final List<String> bodyFocusAreas;
  final bool onboardingCompleted;
  
  // Existing fields
  final WorkoutLocation? preferredLocation;
  final List<String> availableEquipment;
  final int? weeklyWorkoutDays;
  final int? workoutDurationMinutes;
  
  // Health and allergies
  final List<String> healthConditions;
  final List<String> allergies;
  
  // Updated to support multiple motivations
  final List<MotivationType> motivations;
  final String? customMotivation; // For "other" motivation type
  
  // Legal documents acceptance
  // Map of document type -> {version, acceptedAt}
  final Map<String, Map<String, dynamic>> acceptedDocuments;

  const UserProfile({
    required this.userId,
    this.dateOfBirth,
    this.heightCm,
    this.weightKg,
    this.goals = const [],
    this.fitnessLevel = FitnessLevel.beginner,
    this.dietaryPreferences = const [],
    this.bodyFocusAreas = const [],
    this.onboardingCompleted = false,
    this.preferredLocation,
    this.availableEquipment = const [],
    this.weeklyWorkoutDays,
    this.workoutDurationMinutes,
    this.healthConditions = const [],
    this.allergies = const [],
    this.motivations = const [],
    this.customMotivation,
    this.acceptedDocuments = const {},
  });

  @override
  List<Object?> get props => [
        userId,
        dateOfBirth,
        heightCm,
        weightKg,
        goals,
        fitnessLevel,
        dietaryPreferences,
        bodyFocusAreas,
        onboardingCompleted,
        preferredLocation,
        availableEquipment,
        weeklyWorkoutDays,
        workoutDurationMinutes,
        healthConditions,
        allergies,
        motivations,
        customMotivation,
        acceptedDocuments,
      ];

  UserProfile copyWith({
    DateTime? dateOfBirth,
    double? heightCm,
    double? weightKg,
    List<FitnessGoal>? goals,
    FitnessLevel? fitnessLevel,
    List<String>? dietaryPreferences,
    List<String>? bodyFocusAreas,
    bool? onboardingCompleted,
    WorkoutLocation? preferredLocation,
    List<String>? availableEquipment,
    int? weeklyWorkoutDays,
    int? workoutDurationMinutes,
    List<String>? healthConditions,
    List<String>? allergies,
    List<MotivationType>? motivations,
    String? customMotivation,
    Map<String, Map<String, dynamic>>? acceptedDocuments,
  }) {
    return UserProfile(
      userId: userId,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goals: goals ?? this.goals,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      bodyFocusAreas: bodyFocusAreas ?? this.bodyFocusAreas,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      weeklyWorkoutDays: weeklyWorkoutDays ?? this.weeklyWorkoutDays,
      workoutDurationMinutes: workoutDurationMinutes ?? this.workoutDurationMinutes,
      healthConditions: healthConditions ?? this.healthConditions,
      allergies: allergies ?? this.allergies,
      motivations: motivations ?? this.motivations,
      customMotivation: customMotivation ?? this.customMotivation,
      acceptedDocuments: acceptedDocuments ?? this.acceptedDocuments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'dateOfBirth': dateOfBirth?.millisecondsSinceEpoch,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'goals': goals.map((g) => g.name).toList(),
      'fitnessLevel': fitnessLevel.name,
      'dietaryPreferences': dietaryPreferences,
      'bodyFocusAreas': bodyFocusAreas,
      'onboardingCompleted': onboardingCompleted,
      'preferredLocation': preferredLocation?.name,
      'availableEquipment': availableEquipment,
      'weeklyWorkoutDays': weeklyWorkoutDays,
      'workoutDurationMinutes': workoutDurationMinutes,
      'healthConditions': healthConditions,
      'allergies': allergies,
      'motivations': motivations.map((m) => m.name).toList(),
      'customMotivation': customMotivation,
      'acceptedDocuments': acceptedDocuments,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'] ?? '',
      dateOfBirth: map['dateOfBirth'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dateOfBirth']) 
          : null,
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
      preferredLocation: map['preferredLocation'] != null
          ? WorkoutLocation.values.firstWhere(
              (e) => e.name == map['preferredLocation'],
              orElse: () => WorkoutLocation.anywhere,
            )
          : null,
      availableEquipment: map['availableEquipment'] != null
          ? List<String>.from(map['availableEquipment'])
          : [],
      weeklyWorkoutDays: map['weeklyWorkoutDays'],
      workoutDurationMinutes: map['workoutDurationMinutes'],
      healthConditions: map['healthConditions'] != null
          ? List<String>.from(map['healthConditions'])
          : [],
      allergies: map['allergies'] != null
          ? List<String>.from(map['allergies'])
          : [],
      motivations: map['motivations'] != null
          ? (map['motivations'] as List<dynamic>)
              .map((m) => MotivationType.values.firstWhere(
                    (e) => e.name == m,
                    orElse: () => MotivationType.health,
                  ))
              .toList()
          : [],
      customMotivation: map['customMotivation'],
      acceptedDocuments: map['acceptedDocuments'] != null
          ? Map<String, Map<String, dynamic>>.from(map['acceptedDocuments'])
          : {},
    );
  }

  factory UserProfile.empty(String userId) {
    return UserProfile(
      userId: userId,
    );
  }
  
  // Helper method to calculate age from dateOfBirth
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int calculatedAge = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month || 
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      calculatedAge--;
    }
    return calculatedAge;
  }
  
  // Check if a specific document has been accepted
  bool hasAcceptedDocument(String documentId) {
    return acceptedDocuments.containsKey(documentId);
  }
  
  // Helper to check if privacy policy is accepted (for backward compatibility)
  bool get hasAcceptedPrivacyPolicy {
    return hasAcceptedDocument('privacy_policy');
  }
}