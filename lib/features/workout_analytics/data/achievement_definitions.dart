// lib/features/workout_analytics/data/achievement_definitions.dart
import 'package:flutter/material.dart';
import '../models/workout_achievement.dart';

class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final String category;
  final IconData icon;
  final Map<AchievementTier, int> tierThresholds;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.tierThresholds,
  });

  WorkoutAchievement createInstance({
    required AchievementTier tier,
    required int currentValue,
    DateTime? unlockedAt,
  }) {
    return WorkoutAchievement(
      id: id,
      title: title,
      description: description,
      tier: tier,
      currentValue: currentValue,
      targetValue: tierThresholds[tier] ?? 1,
      category: category,
      unlockedAt: unlockedAt,
      icon: icon,
    );
  }
}

class AchievementDefinitions {
  // Consistency Category
  static final workoutCount = AchievementDefinition(
    id: 'workout_count',
    title: 'Workout Warrior',
    description: 'Complete a total number of workouts',
    category: 'Consistency',
    icon: Icons.fitness_center,
    tierThresholds: {
      AchievementTier.bronze: 10,
      AchievementTier.silver: 25,
      AchievementTier.gold: 50,
      AchievementTier.diamond: 100,
    },
  );

  static final weeklyStreak = AchievementDefinition(
    id: 'weekly_streak',
    title: 'Consistency Queen',
    description: 'Complete workouts for consecutive weeks',
    category: 'Consistency',
    icon: Icons.calendar_today,
    tierThresholds: {
      AchievementTier.bronze: 2,
      AchievementTier.silver: 4,
      AchievementTier.gold: 8,
      AchievementTier.diamond: 12,
    },
  );

  static final dailyStreak = AchievementDefinition(
    id: 'daily_streak',
    title: 'Daily Dedication',
    description: 'Work out for consecutive days',
    category: 'Consistency',
    icon: Icons.local_fire_department,
    tierThresholds: {
      AchievementTier.bronze: 3,
      AchievementTier.silver: 7,
      AchievementTier.gold: 14,
      AchievementTier.diamond: 30,
    },
  );

  static final workoutMinutes = AchievementDefinition(
    id: 'workout_minutes',
    title: 'Fitness Timer',
    description: 'Total minutes spent working out',
    category: 'Consistency',
    icon: Icons.timer,
    tierThresholds: {
      AchievementTier.bronze: 120,
      AchievementTier.silver: 300,
      AchievementTier.gold: 600,
      AchievementTier.diamond: 1200,
    },
  );

  // Category Focus
  static final bumsWorkouts = AchievementDefinition(
    id: 'bums_workouts',
    title: 'Bums Expert',
    description: 'Complete Bums category workouts',
    category: 'Body Focus',
    icon: Icons.accessibility_new,
    tierThresholds: {
      AchievementTier.bronze: 5,
      AchievementTier.silver: 15,
      AchievementTier.gold: 30,
      AchievementTier.diamond: 50,
    },
  );

  static final tumsWorkouts = AchievementDefinition(
    id: 'tums_workouts',
    title: 'Tums Master',
    description: 'Complete Tums category workouts',
    category: 'Body Focus',
    icon: Icons.airline_seat_legroom_extra,
    tierThresholds: {
      AchievementTier.bronze: 5,
      AchievementTier.silver: 15,
      AchievementTier.gold: 30,
      AchievementTier.diamond: 50,
    },
  );

  static final fullBodyWorkouts = AchievementDefinition(
    id: 'full_body_workouts',
    title: 'Total Body Triumph',
    description: 'Complete Full Body category workouts',
    category: 'Body Focus',
    icon: Icons.swap_horizontal_circle,
    tierThresholds: {
      AchievementTier.bronze: 5,
      AchievementTier.silver: 15,
      AchievementTier.gold: 30,
      AchievementTier.diamond: 50,
    },
  );

  static final workoutVariety = AchievementDefinition(
    id: 'workout_variety',
    title: 'Fitness Explorer',
    description: 'Try different types of workouts',
    category: 'Body Focus',
    icon: Icons.explore,
    tierThresholds: {
      AchievementTier.bronze: 3,
      AchievementTier.silver: 5,
      AchievementTier.gold: 8,
      AchievementTier.diamond: 12,
    },
  );

  // Time of Day
  static final morningWorkouts = AchievementDefinition(
    id: 'morning_workouts',
    title: 'Early Bird',
    description: 'Complete workouts in the morning (before 9am)',
    category: 'Time of Day',
    icon: Icons.wb_sunny,
    tierThresholds: {
      AchievementTier.bronze: 3,
      AchievementTier.silver: 7,
      AchievementTier.gold: 15,
      AchievementTier.diamond: 30,
    },
  );

  static final lunchWorkouts = AchievementDefinition(
    id: 'lunch_workouts',
    title: 'Midday Mover',
    description: 'Complete workouts during midday (10am-2pm)',
    category: 'Time of Day',
    icon: Icons.lunch_dining,
    tierThresholds: {
      AchievementTier.bronze: 3,
      AchievementTier.silver: 7,
      AchievementTier.gold: 15,
      AchievementTier.diamond: 30,
    },
  );

  static final eveningWorkouts = AchievementDefinition(
    id: 'evening_workouts',
    title: 'Night Owl',
    description: 'Complete workouts in the evening (after 5pm)',
    category: 'Time of Day',
    icon: Icons.nightlight_round,
    tierThresholds: {
      AchievementTier.bronze: 3,
      AchievementTier.silver: 7,
      AchievementTier.gold: 15,
      AchievementTier.diamond: 30,
    },
  );

  static final weekendWarrior = AchievementDefinition(
    id: 'weekend_warrior',
    title: 'Weekend Warrior',
    description: 'Complete workouts on weekends',
    category: 'Time of Day',
    icon: Icons.weekend,
    tierThresholds: {
      AchievementTier.bronze: 2,
      AchievementTier.silver: 5,
      AchievementTier.gold: 10,
      AchievementTier.diamond: 20,
    },
  );

  // Progress Milestones
  static final beginnerGraduate = AchievementDefinition(
    id: 'beginner_graduate',
    title: 'Beginner Graduate',
    description: 'Complete beginner level workouts',
    category: 'Progress',
    icon: Icons.school,
    tierThresholds: {
      AchievementTier.bronze: 5,
      AchievementTier.silver: 10,
      AchievementTier.gold: 20,
      AchievementTier.diamond: 30,
    },
  );

  static final intermediateChallenger = AchievementDefinition(
    id: 'intermediate_challenger',
    title: 'Intermediate Challenger',
    description: 'Complete intermediate level workouts',
    category: 'Progress',
    icon: Icons.trending_up,
    tierThresholds: {
      AchievementTier.bronze: 3,
      AchievementTier.silver: 8,
      AchievementTier.gold: 15,
      AchievementTier.diamond: 25,
    },
  );

  static final longerWorkouts = AchievementDefinition(
    id: 'longer_workouts',
    title: 'Endurance Builder',
    description: 'Complete workouts over 30 minutes',
    category: 'Progress',
    icon: Icons.hourglass_bottom,
    tierThresholds: {
      AchievementTier.bronze: 3,
      AchievementTier.silver: 7,
      AchievementTier.gold: 15,
      AchievementTier.diamond: 30,
    },
  );

  static final perfectWeek = AchievementDefinition(
    id: 'perfect_week',
    title: 'Perfect Week',
    description: 'Complete all scheduled workouts in a week',
    category: 'Progress',
    icon: Icons.check_circle,
    tierThresholds: {
      AchievementTier.bronze: 1,
      AchievementTier.silver: 3,
      AchievementTier.gold: 5,
      AchievementTier.diamond: 10,
    },
  );

  // Social & Community
  static final socialSharer = AchievementDefinition(
    id: 'social_sharer',
    title: 'Fitness Influencer',
    description: 'Share your workouts on social media',
    category: 'Community',
    icon: Icons.share,
    tierThresholds: {
      AchievementTier.bronze: 1,
      AchievementTier.silver: 5,
      AchievementTier.gold: 10,
      AchievementTier.diamond: 25,
    },
  );

  static final challengeParticipant = AchievementDefinition(
    id: 'challenge_participant',
    title: 'Challenge Conquerer',
    description: 'Participate in community fitness challenges',
    category: 'Community',
    icon: Icons.emoji_events,
    tierThresholds: {
      AchievementTier.bronze: 1,
      AchievementTier.silver: 3,
      AchievementTier.gold: 5,
      AchievementTier.diamond: 10,
    },
  );

  static final feedbackProvider = AchievementDefinition(
    id: 'feedback_provider',
    title: 'Feedback Friend',
    description: 'Provide feedback after completing workouts',
    category: 'Community',
    icon: Icons.rate_review,
    tierThresholds: {
      AchievementTier.bronze: 3,
      AchievementTier.silver: 10,
      AchievementTier.gold: 25,
      AchievementTier.diamond: 50,
    },
  );

  static final workoutCreator = AchievementDefinition(
    id: 'workout_creator',
    title: 'Workout Designer',
    description: 'Create custom workouts',
    category: 'Community',
    icon: Icons.create,
    tierThresholds: {
      AchievementTier.bronze: 1,
      AchievementTier.silver: 3,
      AchievementTier.gold: 7,
      AchievementTier.diamond: 15,
    },
  );

  // Get all achievements as a list
  static List<AchievementDefinition> get all => [
    workoutCount,
    weeklyStreak,
    dailyStreak,
    workoutMinutes,
    bumsWorkouts,
    tumsWorkouts,
    fullBodyWorkouts,
    workoutVariety,
    morningWorkouts,
    lunchWorkouts,
    eveningWorkouts,
    weekendWarrior,
    beginnerGraduate,
    intermediateChallenger,
    longerWorkouts,
    perfectWeek,
    socialSharer,
    challengeParticipant,
    feedbackProvider,
    workoutCreator,
  ];
}