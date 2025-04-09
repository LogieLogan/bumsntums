import 'package:flutter/material.dart';
import 'workout.dart';
import '../../../shared/theme/color_palette.dart';

extension WorkoutCategoryDisplay on WorkoutCategory {
  String get displayName {
    switch (this) {
      case WorkoutCategory.bums:
        return 'Bums';
      case WorkoutCategory.tums:
        return 'Tums';
      case WorkoutCategory.arms:
        return 'Arms';
      case WorkoutCategory.fullBody:
        return 'Full Body';
      case WorkoutCategory.cardio:
        return 'Cardio';
      case WorkoutCategory.quickWorkout:
        return 'Quick';
    }
  }

  Color get displayColor {
    switch (this) {
      case WorkoutCategory.bums:
        return AppColors.salmon;
      case WorkoutCategory.tums:
        return AppColors.popTurquoise;

      case WorkoutCategory.arms:
        return AppColors.popGreen;
      case WorkoutCategory.fullBody:
        return AppColors.popBlue;
      case WorkoutCategory.cardio:
        return AppColors.popCoral;

      case WorkoutCategory.quickWorkout:
        return AppColors.popYellow;
    }
  }

  IconData get displayIcon {
    switch (this) {
      case WorkoutCategory.bums:
        return Icons.accessibility_new;
      case WorkoutCategory.tums:
        return Icons.fitness_center;
      case WorkoutCategory.arms:
        return Icons.fitness_center;
      case WorkoutCategory.fullBody:
        return Icons.accessibility;
      case WorkoutCategory.cardio:
        return Icons.directions_run;
      case WorkoutCategory.quickWorkout:
        return Icons.timer;
    }
  }
}

extension WorkoutDifficultyDisplay on WorkoutDifficulty {
  String get displayName {
    switch (this) {
      case WorkoutDifficulty.beginner:
        return 'Beginner';
      case WorkoutDifficulty.intermediate:
        return 'Intermediate';
      case WorkoutDifficulty.advanced:
        return 'Advanced';
    }
  }
}
