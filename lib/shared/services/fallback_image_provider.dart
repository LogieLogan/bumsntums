// lib/shared/services/fallback_image_provider.dart
import 'package:bums_n_tums/features/workouts/models/workout.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/color_palette.dart';

class FallbackImageProvider {
  // Free exercise images from Unsplash or similar sources
  static const Map<String, String> exerciseImageMap = {
    'glute_bridge': 'https://images.unsplash.com/photo-1648737963503-b3eafbc3f49a?w=600&auto=format&fit=crop',
    'squat': 'https://images.unsplash.com/photo-1597452485669-2c7bb5fef90d?w=600&auto=format&fit=crop',
    'side_leg_lift': 'https://images.unsplash.com/photo-1598971639058-afc664523d3d?w=600&auto=format&fit=crop',
    'donkey_kick': 'https://images.unsplash.com/photo-1598266663439-2056e6900338?w=600&auto=format&fit=crop',
    'reverse_lunge': 'https://images.unsplash.com/photo-1603287681836-b174ce5074c2?w=600&auto=format&fit=crop',
    // Add more exercises as needed
  };

  // Free workout category images
  static const Map<String, String> workoutCategoryImageMap = {
    'bums': 'https://images.unsplash.com/photo-1517344884509-a0c97ec11bcc?w=600&auto=format&fit=crop',
    'tums': 'https://images.unsplash.com/photo-1576678927484-cc907957088c?w=600&auto=format&fit=crop,',
    'fullBody': 'https://images.unsplash.com/photo-1576678927484-cc907957088c?w=600&auto=format&fit=crop',
    'cardio': 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=600&auto=format&fit=crop',
    'quickWorkout': 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=600&auto=format&fit=crop',
  };

  // Get a network URL for an exercise based on its asset path or name
  static String getExerciseUrl(String assetPath) {
    // Extract the base name from the asset path (e.g., 'glute_bridge' from 'assets/images/exercises/glute_bridge.jpg')
    final fileName = assetPath.split('/').last.split('.').first;
    
    return exerciseImageMap[fileName] ?? 
           'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=600&auto=format&fit=crop'; // Default fitness image
  }

  // Get a network URL for a workout category
  static String getWorkoutCategoryUrl(String category) {
    return workoutCategoryImageMap[category] ?? 
           'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=600&auto=format&fit=crop'; // Default fitness image
  }

  // Widget to display an exercise image with fallback
  static Widget exerciseImage({
    required String imageUrl,
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: getExerciseUrl(imageUrl),
        height: height,
        width: width,
        fit: fit,
        placeholder: (context, url) => Container(
          color: AppColors.paleGrey,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.salmon),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppColors.salmon.withOpacity(0.3),
          child: Center(
            child: Icon(
              Icons.fitness_center,
              color: AppColors.salmon,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }

  // Widget to display a workout image with fallback
  static Widget workoutImage({
    required String imageUrl,
    required WorkoutCategory category,
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: getExerciseUrl(imageUrl), // Try the exercise URL first
        height: height,
        width: width,
        fit: fit,
        placeholder: (context, url) => Container(
          color: AppColors.paleGrey,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.salmon),
          ),
        ),
        errorWidget: (context, url, error) => CachedNetworkImage(
          // Fall back to category image if the specific image fails
          imageUrl: getWorkoutCategoryUrl(category.name),
          height: height,
          width: width,
          fit: fit,
          placeholder: (context, url) => Container(
            color: AppColors.paleGrey,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.salmon),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: AppColors.salmon.withOpacity(0.3),
            child: Center(
              child: Icon(
                Icons.fitness_center,
                color: AppColors.salmon,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}