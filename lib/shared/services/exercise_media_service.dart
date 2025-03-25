// lib/shared/services/exercise_media_service.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/exercise_icon_mapper.dart';
import '../../features/workouts/models/workout.dart';
import '../theme/color_palette.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ExerciseMediaService {
  // SVG Icons by exercise type - these will be from Font Awesome or similar
  static const Map<String, String> exerciseIconMap = {
    // Bums/Glutes exercises
    'glute_bridge': 'assets/icons/exercises/glute_bridge.svg',
    'squat': 'assets/icons/exercises/squat.svg',
    'lunge': 'assets/icons/exercises/lunge.svg',
    'donkey_kick': 'assets/icons/exercises/donkey_kick.svg',
    'fire_hydrant': 'assets/icons/exercises/fire_hydrant.svg',
    'side_leg_lift': 'assets/icons/exercises/side_leg_lift.svg',
    'clamshell': 'assets/icons/exercises/clamshell.svg',
    'deadlift': 'assets/icons/exercises/deadlift.svg',
    'sumo_deadlift': 'assets/icons/exercises/sumo_deadlift.svg',
    'bulgarian_split_squat': 'assets/icons/exercises/bulgarian_split_squat.svg',
    'jump_squat': 'assets/icons/exercises/jump_squat.svg',

    // Tums/Core exercises
    'crunch': 'assets/icons/exercises/crunch.svg',
    'plank': 'assets/icons/exercises/plank.svg',
    'russian_twist': 'assets/icons/exercises/russian_twist.svg',
    'mountain_climber': 'assets/icons/exercises/mountain_climber.svg',
    'leg_raise': 'assets/icons/exercises/leg_raise.svg',
    'bicycle_crunch': 'assets/icons/exercises/bicycle_crunch.svg',
    'dead_bug': 'assets/icons/exercises/dead_bug.svg',

    // Full body exercises
    'burpee': 'assets/icons/exercises/burpee.svg',
    'push_up': 'assets/icons/exercises/push_up.svg',
    'jumping_jack': 'assets/icons/exercises/jumping_jack.svg',

    // Default icon
    'default': 'assets/icons/exercises/default_exercise.svg',
  };

  // Demonstration images from free sources like MuscleWiki or wger
  static const Map<String, String> exerciseDemoImageMap = {
    // Bums/Glutes exercises
    'glute_bridge':
        'https://static.wixstatic.com/media/65a23c_5d6443e494334a35aa10689c513e5266~mv2.gif',
    'squat':
        'https://static.wixstatic.com/media/65a23c_7b672c1e50ed40ed8ecc98c4eac564e1~mv2.gif',
    'lunge':
        'https://static.wixstatic.com/media/65a23c_067696489e8d40f8a5dd58c253dc383e~mv2.gif',
    'donkey_kick':
        'https://static.wixstatic.com/media/65a23c_5616451eff724bc8a10a0bda14fd7e72~mv2.gif',
    'side_leg_lift':
        'https://static.wixstatic.com/media/65a23c_ef8b2f8093bb475f80ff40d728bd5d9e~mv2.gif',
    'clamshell':
        'https://thumbs.gfycat.com/QueasyGlossyAcornwoodpecker-size_restricted.gif',

    // Tums/Core exercises
    'crunch':
        'https://static.wixstatic.com/media/65a23c_001e7022f6034517a0df41a511ecb9cc~mv2.gif',
    'plank':
        'https://static.wixstatic.com/media/65a23c_b94b640d5753496e841eedb9a307dcce~mv2.gif',
    'russian_twist':
        'https://static.wixstatic.com/media/65a23c_ca0f80e357994222b56fb56447257d68~mv2.gif',
    'mountain_climber':
        'https://static.wixstatic.com/media/65a23c_a875417c85a9496096494f9c9a100178~mv2.gif',

    // Full body exercises
    'burpee':
        'https://static.wixstatic.com/media/65a23c_6d306d2ce4d346f1939f8ae953415c37~mv2.gif',
    'push_up':
        'https://static.wixstatic.com/media/65a23c_71fd6e34c0ba44f5a632587d011d91d1~mv2.gif',
  };

  // Backup photos from Unsplash (for when specific demos aren't available)
  static const Map<String, String> exercisePhotoMap = {
    // Bums/Glutes exercises
    'glute_bridge':
        '',
    'squat':
        'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?w=600&auto=format&fit=crop',
    'lunge':
        '',
    'donkey_kick':
        '',
    'side_leg_lift':
        '',

    // Tums/Core exercises
    'crunch':
        'https://images.unsplash.com/photo-1536922246289-88c42f957773?q=80&w=3004&auto=format&fit=crop',
    'plank':
        'https://images.unsplash.com/photo-1599901860904-17e6ed7083a0?w=600&auto=format&fit=crop',
    'russian_twist':
        'https://images.unsplash.com/photo-1550259979-ed79b48d2a30?q=80&w=3168&auto=format&fit=crop',
    // Default exercise
    'default':
        'https://images.unsplash.com/photo-1536922246289-88c42f957773?q=80&w=3004&auto=format&fit=crop',
  };

  // Category images for workout cards
  static const Map<String, String> workoutCategoryImageMap = {
    'bums':
        'https://images.unsplash.com/photo-1536922246289-88c42f957773?q=80&w=3004&auto=format&fit=crop',
    'tums':
        '',
    'fullBody':
        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=600&auto=format&fit=crop',
    'cardio':
        'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=600&auto=format&fit=crop',
    'quickWorkout':
        'https://images.unsplash.com/photo-1534258936925-c58bed479fcb?q=80&w=3131&auto=format&fit=crop',
  };

  // Target area image maps for different body parts
  static const Map<String, String> targetAreaImageMap = {
    'bums':
        '',
    'tums':
        'https://images.unsplash.com/photo-1576678927484-cc907957088c?w=600&auto=format&fit=crop,',
    'legs':
        '',
    'arms':
        '',
    'back':
        'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?q=80&w=2969&auto=format&fit=crop',
    'chest':
        '',
    'shoulders':
        '',
  };

  // Difficulty level images
  static const Map<WorkoutDifficulty, String> difficultyImageMap = {
    WorkoutDifficulty.beginner:
        'https://images.unsplash.com/photo-1518459031867-a89b944bffe4?w=600&auto=format&fit=crop',
    WorkoutDifficulty.intermediate:
        'https://images.unsplash.com/photo-1518458717367-249ba15389d2?q=80&w=2970&auto=format&fit=crop',
    WorkoutDifficulty.advanced:        
        'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=600&auto=format&fit=crop',
  };

  // Extract exercise name from asset path or URL for lookup
  static String _extractExerciseName(String path) {
    // Handle local asset paths
    if (path.startsWith('assets/')) {
      final fileName = path.split('/').last.split('.').first;
      return fileName.toLowerCase();
    }

    // Handle URLs
    if (path.startsWith('http')) {
      final uri = Uri.parse(path);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        final lastSegment = segments.last;
        // Remove file extension if present
        return lastSegment.split('.').first.toLowerCase();
      }
    }

    // If all else fails, return the path itself
    return path.toLowerCase();
  }

  // Get the best available media URL for an exercise
  static String getBestExerciseMedia(
    String exercisePath, {
    MediaType type = MediaType.photo,
  }) {
    final exerciseName = _extractExerciseName(exercisePath);

    // Check specific maps based on media type preference
    switch (type) {
      case MediaType.demo:
        // First try to get a demo GIF
        if (exerciseDemoImageMap.containsKey(exerciseName)) {
          return exerciseDemoImageMap[exerciseName]!;
        }
        // Fall through to photo if no demo available
        continue photo;

      photo:
      case MediaType.photo:
        // Try to get a photo
        if (exercisePhotoMap.containsKey(exerciseName)) {
          return exercisePhotoMap[exerciseName]!;
        }
      // Fall through to default

      case MediaType.icon:
        // Try to get an icon
        if (exerciseIconMap.containsKey(exerciseName)) {
          return exerciseIconMap[exerciseName]!;
        }
      // Fall through to default
    }

    // If specific exercise not found, try to match by partial name
    for (final entry in exercisePhotoMap.entries) {
      if (exerciseName.contains(entry.key) ||
          entry.key.contains(exerciseName)) {
        return entry.value;
      }
    }

    // Return default fallback
    return exercisePhotoMap['default']!;
  }

  // Get a workout category image
  static String getWorkoutCategoryUrl(WorkoutCategory category) {
    return workoutCategoryImageMap[category.name] ??
        'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=600&auto=format&fit=crop';
  }

  // Get target area image        
  static String getTargetAreaUrl(String targetArea) {
    return targetAreaImageMap[targetArea.toLowerCase()] ??
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600&auto=format&fit=crop';
  }

  // Get difficulty image
  static String getDifficultyUrl(WorkoutDifficulty difficulty) {
    return difficultyImageMap[difficulty] ??
        '';
  }

  static Widget exerciseImage({
    required String imageUrl,
    MediaType preferredMediaType = MediaType.photo,
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    final mediaUrl = getBestExerciseMedia(imageUrl, type: preferredMediaType);

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: mediaUrl,
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
                _buildFallbackWidget(height: height, width: width),
      ),
    );
  }

  // Widget to display a workout category image with fallback
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
        imageUrl:
            imageUrl.startsWith('http')
                ? imageUrl
                : getWorkoutCategoryUrl(category),
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
            (context, url, error) => Container(
              color: AppColors.salmon.withOpacity(0.3),
              height: height,
              width: width,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      color: AppColors.salmon,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getCategoryDisplayName(category),
                      style: const TextStyle(
                        color: AppColors.salmon,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  // Build a fallback widget for exercise images
  static Widget _buildFallbackWidget({double? height, double? width}) {
    return Container(
      height: height,
      width: width,
      color: AppColors.salmon.withOpacity(0.3),
      child: Center(
        child: Icon(Icons.fitness_center, color: AppColors.salmon, size: 48),
      ),
    );
  }

  // Helper to get category icon
  static IconData _getCategoryIcon(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.bums:
        return Icons.accessibility_new;
      case WorkoutCategory.tums:
        return Icons.airline_seat_flat;
      case WorkoutCategory.fullBody:
        return Icons.accessibility;
      case WorkoutCategory.cardio:
        return Icons.directions_run;
      case WorkoutCategory.quickWorkout:
        return Icons.timer;
      default:
        return Icons.fitness_center;
    }
  }

  // Helper to get category display name
  static String _getCategoryDisplayName(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.bums:
        return 'Bums';
      case WorkoutCategory.tums:
        return 'Tums';
      case WorkoutCategory.fullBody:
        return 'Full Body';
      case WorkoutCategory.cardio:
        return 'Cardio';
      case WorkoutCategory.quickWorkout:
        return 'Quick Workout';
      default:
        return 'Workout';
    }
  }

  static Widget getExerciseIcon({
    required String targetArea,
    double size = 24.0,
    Color? color,
  }) {
    final iconData = ExerciseIconMapper.getIconForTargetArea(targetArea);

    return FaIcon(iconData, size: size, color: color);
  }
}

enum MediaType { icon, photo, demo }
