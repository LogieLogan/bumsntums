// features/workout_analytics/data/achievement_definitions.dart

import 'package:bums_n_tums/features/workout_analytics/models/workout_achievement.dart';

enum AchievementCriteriaType {
  totalWorkouts,
  currentStreak,
  longestStreak,
  workoutsInCategory, // e.g., 10 'Core' workouts
  specificExerciseCompletions, // e.g., 100 Squats completed
  // Add more simple, engaging types for the target audience
  // Example: workoutDurationMilestone (e.g., total 1000 minutes)
  // Example: firstWorkoutInCategory (e.g., first 'Lower Body' workout)
}

class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final String iconIdentifier; // Emoji or asset path
  final AchievementCriteriaType criteriaType;
  final num threshold; // Use num for int/double thresholds
  final String? relatedId; // e.g., category name like 'Core', exercise name like 'Squats'

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.iconIdentifier,
    required this.criteriaType,
    required this.threshold,
    this.relatedId,
  });
}

// --- List of All Achievements ---
const List<AchievementDefinition> allAchievements = [
  // Basic Progression
  AchievementDefinition(
    id: 'first_workout',
    title: 'Welcome Aboard!',
    description: 'Complete your very first workout.',
    iconIdentifier: '🎉',
    criteriaType: AchievementCriteriaType.totalWorkouts,
    threshold: 1,
  ),
  AchievementDefinition(
    id: 'five_workouts',
    title: 'Getting Started',
    description: 'Complete 5 workouts.',
    iconIdentifier: '👍',
    criteriaType: AchievementCriteriaType.totalWorkouts,
    threshold: 5,
  ),
  AchievementDefinition(
    id: 'ten_workouts',
    title: 'Making Progress',
    description: 'Complete 10 workouts.',
    iconIdentifier: '💪',
    criteriaType: AchievementCriteriaType.totalWorkouts,
    threshold: 10,
  ),
   AchievementDefinition(
    id: 'twenty_five_workouts',
    title: 'Consistent Effort',
    description: 'Complete 25 workouts.',
    iconIdentifier: '✨',
    criteriaType: AchievementCriteriaType.totalWorkouts,
    threshold: 25,
  ),
   AchievementDefinition(
    id: 'fifty_workouts',
    title: 'Workout Veteran',
    description: 'Complete 50 workouts.',
    iconIdentifier: '🌟',
    criteriaType: AchievementCriteriaType.totalWorkouts,
    threshold: 50,
  ),

  // Streaks
  AchievementDefinition(
    id: 'three_day_streak',
    title: 'On a Roll!',
    description: 'Maintain a 3-day workout streak.',
    iconIdentifier: '🔥',
    criteriaType: AchievementCriteriaType.currentStreak,
    threshold: 3,
  ),
  AchievementDefinition(
    id: 'seven_day_streak',
    title: 'Week Warrior',
    description: 'Maintain a 7-day workout streak.',
    iconIdentifier: '🏆',
    criteriaType: AchievementCriteriaType.currentStreak,
    threshold: 7,
  ),
   AchievementDefinition(
    id: 'fourteen_day_streak',
    title: 'Two Week Power',
    description: 'Maintain a 14-day workout streak.',
    iconIdentifier: '🚀',
    criteriaType: AchievementCriteriaType.currentStreak,
    threshold: 14,
  ),

  // Category Based (using category names from your service logic)
   AchievementDefinition(
    id: 'first_lower_body',
    title: 'Leg Day!',
    description: "Complete your first 'Lower Body' focused workout.",
    iconIdentifier: '🦵', // Example icon
    criteriaType: AchievementCriteriaType.workoutsInCategory,
    threshold: 1,
    relatedId: 'Lower Body',
  ),
   AchievementDefinition(
    id: 'first_core',
    title: 'Core Crusher',
    description: "Complete your first 'Core' focused workout.",
    iconIdentifier: '🔥', // Example icon
    criteriaType: AchievementCriteriaType.workoutsInCategory,
    threshold: 1,
    relatedId: 'Core',
  ),
  AchievementDefinition(
    id: 'ten_lower_body',
    title: 'Lower Body Pro',
    description: "Complete 10 'Lower Body' focused workouts.",
    iconIdentifier: '🍑', // Example icon
    criteriaType: AchievementCriteriaType.workoutsInCategory,
    threshold: 10,
    relatedId: 'Lower Body',
  ),
   AchievementDefinition(
    id: 'ten_core',
    title: 'Abs of Steel',
    description: "Complete 10 'Core' focused workouts.",
    iconIdentifier: '🔩', // Example icon
    criteriaType: AchievementCriteriaType.workoutsInCategory,
    threshold: 10,
    relatedId: 'Core',
  ),

  // Exercise Completions (Add a few popular ones)
  AchievementDefinition(
    id: 'hundred_squats',
    title: 'Squat Master',
    description: 'Perform 100 Squats in total across all workouts.',
    iconIdentifier: '🏋️‍♀️',
    criteriaType: AchievementCriteriaType.specificExerciseCompletions, // Need to map this to totalRepsCompleted
    threshold: 100,
    relatedId: 'Squats', // Ensure this matches exerciseName exactly
  ),
   AchievementDefinition(
    id: 'hundred_lunges',
    title: 'Lunge Legend',
    description: 'Perform 100 Lunges in total across all workouts.',
    iconIdentifier: '🚶‍♀️', // Example icon
    criteriaType: AchievementCriteriaType.specificExerciseCompletions,
    threshold: 100,
    relatedId: 'Lunges',
  ),

  // Add more fun/simple ones...
];

// Helper structure for displaying achievements
class DisplayAchievement {
  final AchievementDefinition definition;
  final WorkoutAchievement? unlockedInfo; // Null if not unlocked

  DisplayAchievement({required this.definition, this.unlockedInfo});

  bool get isUnlocked => unlockedInfo != null;
}