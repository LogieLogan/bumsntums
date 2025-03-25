// lib/shared/services/exercise_media_service.dart
import 'package:bums_n_tums/features/workouts/models/exercise.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../features/workouts/models/workout.dart';
import '../theme/color_palette.dart';

class ExerciseMediaService {
  // Level-based workout images - these will be loaded from assets
  static const Map<WorkoutDifficulty, String> levelImageMap = {
    WorkoutDifficulty.beginner: 'assets/images/workouts/beginner_workout.jpg',
    WorkoutDifficulty.intermediate:
        'assets/images/workouts/intermediate_workout.jpg',
    WorkoutDifficulty.advanced: 'assets/images/workouts/advanced_workout.jpg',
  };

  // Get image path for workout based on difficulty level
  static String getWorkoutLevelImage(WorkoutDifficulty difficulty) {
    return levelImageMap[difficulty] ??
        levelImageMap[WorkoutDifficulty.beginner]!;
  }

  // Widget to display a workout image based on difficulty level
  static Widget workoutImage({
    required WorkoutDifficulty difficulty,
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    final imagePath = getWorkoutLevelImage(difficulty);

    // For asset images
    if (imagePath.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: Image.asset(
          imagePath,
          height: height,
          width: width,
          fit: fit,
          errorBuilder:
              (context, error, stackTrace) => _buildFallbackWidget(
                difficulty,
                height: height,
                width: width,
              ),
        ),
      );
    }

    // For network images (if any in the future)
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: imagePath,
        height: height,
        width: width,
        fit: fit,
        placeholder:
            (context, url) => Container(
              color: AppColors.paleGrey,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.salmon),
              ),
            ),
        errorWidget:
            (context, url, error) =>
                _buildFallbackWidget(difficulty, height: height, width: width),
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
          // Add SingleChildScrollView to handle overflow
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // Make sure column takes minimum space
            children: [
              Icon(Icons.fitness_center, color: AppColors.darkGrey, size: 48),
              const SizedBox(height: 8),
              Text(
                levelText,
                style: const TextStyle(
                  color: AppColors.darkGrey,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center, // Center text to avoid overflow
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String? getVideoPathForExercise(String exerciseName) {
    // Convert the exercise name to match the filename pattern
    final formattedName =
        exerciseName
            .trim()
            .replaceAll(RegExp(r'\s+'), '_')
            .replaceAll(RegExp(r'[^\w]'), '') // Remove non-alphanumeric chars
            .toLowerCase();

    return 'assets/videos/exercises/$formattedName.mp4';
  }

  // Check if a video exists for an exercise
  static bool hasVideo(Exercise exercise) {
    return exercise.videoPath != null && exercise.videoPath!.isNotEmpty;
  }

  // Get the appropriate media for an exercise (video or image)
  static String getExerciseMediaPath(Exercise exercise) {
    // First check if the exercise has a direct video path
    if (exercise.videoPath != null && exercise.videoPath!.isNotEmpty) {
      return exercise.videoPath!;
    }

    // Try to derive a video path from the exercise name
    final derivedVideoPath = getVideoPathForExercise(exercise.name);
    if (derivedVideoPath != null) {
      return derivedVideoPath;
    }

    // Fall back to difficulty-based image
    final difficulty =
        exercise.difficultyLevel <= 2
            ? WorkoutDifficulty.beginner
            : (exercise.difficultyLevel <= 4
                ? WorkoutDifficulty.intermediate
                : WorkoutDifficulty.advanced);

    return getWorkoutLevelImage(difficulty);
  }
}
