// lib/features/workout_analytics/models/workout_achievement.dart
import 'package:flutter/material.dart';
import '../../../shared/theme/color_palette.dart';

enum AchievementTier {
  bronze,
  silver,
  gold,
  diamond
}

class WorkoutAchievement {
  final String id;
  final String title;
  final String description;
  final AchievementTier tier;
  final int currentValue;
  final int targetValue;
  final String category;
  final DateTime? unlockedAt;
  final IconData icon;

  const WorkoutAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.tier,
    required this.currentValue,
    required this.targetValue,
    required this.category,
    this.unlockedAt,
    required this.icon,
  });

  bool get isUnlocked => unlockedAt != null;
  
  double get progress => currentValue / targetValue;
  
  Color get tierColor {
    switch (tier) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32); // Bronze color
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0); // Silver color
      case AchievementTier.gold:
        return const Color(0xFFFFD700); // Gold color
      case AchievementTier.diamond:
        return const Color(0xFFB9F2FF); // Diamond color
    }
  }
  
  String get tierName {
    switch (tier) {
      case AchievementTier.bronze:
        return 'Bronze';
      case AchievementTier.silver:
        return 'Silver';
      case AchievementTier.gold:
        return 'Gold';
      case AchievementTier.diamond:
        return 'Diamond';
    }
  }
  
  factory WorkoutAchievement.fromMap(Map<String, dynamic> map) {
    return WorkoutAchievement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      tier: AchievementTier.values[map['tier'] ?? 0],
      currentValue: map['currentValue'] ?? 0,
      targetValue: map['targetValue'] ?? 1,
      category: map['category'] ?? 'General',
      unlockedAt: map['unlockedAt'] != null ? DateTime.parse(map['unlockedAt']) : null,
      icon: IconData(map['iconCodePoint'] ?? 0xe158, fontFamily: 'MaterialIcons'),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'tier': tier.index,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'category': category,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'iconCodePoint': icon.codePoint,
    };
  }
}