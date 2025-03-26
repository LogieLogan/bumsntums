// lib/shared/services/exercise_media_service.dart
import 'package:bums_n_tums/features/workouts/models/exercise.dart';
import 'package:bums_n_tums/features/workouts/models/workout.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:developer' as developer;
import '../theme/color_palette.dart';

class ExerciseMediaService {
  // Asset paths structure
  static const String _exerciseImagesPath = 'assets/images/exercises';
  static const String _exerciseVideosPath = 'assets/videos/exercises';
  static const String _exerciseIconsPath = 'assets/icons/exercises';
  static const String _workoutImagesPath = 'assets/images/workouts';
  
  // Level-based workout images
  static const Map<WorkoutDifficulty, String> levelImageMap = {
    WorkoutDifficulty.beginner: '$_workoutImagesPath/beginner_workout.jpg',
    WorkoutDifficulty.intermediate: '$_workoutImagesPath/intermediate_workout.jpg',
    WorkoutDifficulty.advanced: '$_workoutImagesPath/advanced_workout.jpg',
  };

  // Normalize exercise name for file paths
  static String _normalizeExerciseName(String name) {
    // Convert to lowercase, replace spaces with underscores, remove any special characters,
    // ensure singular form (this assumes your files are all in singular form now)
    return name.trim().toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^\w\s]+'), '');
  }

  // Get image path for an exercise
  static String getExerciseImagePath(String exerciseName) {
    final normalizedName = _normalizeExerciseName(exerciseName);
    return '$_exerciseImagesPath/$normalizedName.jpg';
  }

  // Get video path for an exercise
  static String getExerciseVideoPath(String exerciseName) {
    final normalizedName = _normalizeExerciseName(exerciseName);
    return '$_exerciseVideosPath/$normalizedName.mp4';
  }

  // Get icon path for an exercise
  static String getExerciseIconPath(String exerciseName) {
    final normalizedName = _normalizeExerciseName(exerciseName);
    // Check for common exercise patterns for proper icon mapping
    if (normalizedName.contains('squat')) {
      return '$_exerciseIconsPath/squat.svg';
    } else if (normalizedName.contains('lunge')) {
      return '$_exerciseIconsPath/lunge.svg';
    } else if (normalizedName.contains('bridge') || normalizedName.contains('glute')) {
      return '$_exerciseIconsPath/glute_bridge.svg';
    } else if (normalizedName.contains('plank')) {
      return '$_exerciseIconsPath/plank.svg';
    }
    
    // Default icon
    return '$_exerciseIconsPath/default_exercise.svg';
  }

  // Get image path for workout based on difficulty level
  static String getWorkoutLevelImage(WorkoutDifficulty difficulty) {
    return levelImageMap[difficulty] ?? levelImageMap[WorkoutDifficulty.beginner]!;
  }

  // Widget to display a workout image based on difficulty level with proper error handling
  static Widget workoutImage({
    required WorkoutDifficulty difficulty,
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    final imagePath = getWorkoutLevelImage(difficulty);
    developer.log('Loading workout image: $imagePath');

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: Image.asset(
        imagePath,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          developer.log('Error loading workout image: $imagePath, $error');
          return _buildFallbackWidget(difficulty, height: height, width: width);
        },
      ),
    );
  }

  // Build a fallback widget with level indication
  static Widget _buildFallbackWidget(
    WorkoutDifficulty difficulty, {
    double? height,
    double? width,
  }) {
    final Color bgColor;
    final String levelText;

    switch (difficulty) {
      case WorkoutDifficulty.beginner:
        bgColor = AppColors.popGreen.withOpacity(0.3);
        levelText = 'Beginner';
        break;
      case WorkoutDifficulty.intermediate:
        bgColor = AppColors.popYellow.withOpacity(0.3);
        levelText = 'Intermediate';
        break;
      case WorkoutDifficulty.advanced:
        bgColor = AppColors.popCoral.withOpacity(0.3);
        levelText = 'Advanced';
        break;
      default:
        bgColor = AppColors.salmon.withOpacity(0.3);
        levelText = 'Workout';
    }

    return Container(
      height: height,
      width: width,
      color: bgColor,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fitness_center, color: AppColors.darkGrey, size: 48),
              const SizedBox(height: 8),
              Text(
                levelText,
                style: const TextStyle(
                  color: AppColors.darkGrey,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Display an exercise image with proper fallback
  static Widget exerciseImage({
    required String exerciseName,
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    WorkoutDifficulty difficulty = WorkoutDifficulty.beginner,
  }) {
    final String imagePath = getExerciseImagePath(exerciseName);
    developer.log('Loading exercise image: $imagePath for $exerciseName');

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: Image.asset(
        imagePath,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          developer.log('Error loading exercise image: $imagePath, $error');
          // Fall back to difficulty-based workout image
          return workoutImage(
            difficulty: difficulty,
            height: height,
            width: width,
            fit: fit,
            borderRadius: borderRadius,
          );
        },
      ),
    );
  }

  // Check if a video exists for an exercise by name - signature unchanged for compatibility
  static bool exerciseHasVideo(String exerciseName) {
    // We can't check if the asset exists at runtime without trying to load it
    // So this is a best guess based on the path
    return true; // Assume video exists, error handling will catch if it doesn't
  }

  // Method to check if an exercise has a video - signature unchanged for compatibility
  static bool hasVideo(Exercise exercise) {
    // Check if the exercise has a direct video path
    if (exercise.videoPath != null && exercise.videoPath!.isNotEmpty) {
      return true;
    }

    // Assume based on exercise name
    return true; // Let error handling deal with missing videos at load time
  }

  // Get the appropriate media path for an exercise - signature unchanged for compatibility
  static String getExerciseMediaPath(Exercise exercise) {
    // First check if the exercise has a direct video path
    if (exercise.videoPath != null && exercise.videoPath!.isNotEmpty) {
      return exercise.videoPath!;
    }

    // Generate a video path from the exercise name
    return getExerciseVideoPath(exercise.name);
  }
}