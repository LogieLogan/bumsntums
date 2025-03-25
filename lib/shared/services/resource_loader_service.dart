// lib/shared/services/resource_loader_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/color_palette.dart';

class ResourceLoaderService {
  // Load SVG icon with fallback
  static Widget loadSvgIcon({
    required String assetPath,
    double size = 24.0,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: color != null 
          ? ColorFilter.mode(color, BlendMode.srcIn) 
          : null,
      fit: fit,
      placeholderBuilder: (BuildContext context) => Icon(
        Icons.fitness_center,
        size: size,
        color: color ?? AppColors.salmon,
      ),
    );
  }
  
  // Get icon for exercise
  static Widget getExerciseIcon({
    required String exerciseName,
    double size = 24.0,
    Color? color,
  }) {
    final iconPath = _getExerciseIconPath(exerciseName);
    return loadSvgIcon(
      assetPath: iconPath,
      size: size,
      color: color,
    );
  }
  
  // Helper method to determine icon path based on exercise name
  static String _getExerciseIconPath(String exerciseName) {
    // Normalize the exercise name
    final normalized = exerciseName.toLowerCase().replaceAll(' ', '_');
    
    // Common exercise pattern matching
    if (normalized.contains('squat')) {
      return 'assets/icons/exercises/squat.svg';
    } else if (normalized.contains('lunge')) {
      return 'assets/icons/exercises/lunge.svg';
    } else if (normalized.contains('bridge') || normalized.contains('glute')) {
      return 'assets/icons/exercises/glute_bridge.svg';
    } else if (normalized.contains('plank')) {
      return 'assets/icons/exercises/plank.svg';
    } else if (normalized.contains('crunch')) {
      return 'assets/icons/exercises/crunch.svg';
    } else if (normalized.contains('push')) {
      return 'assets/icons/exercises/push_up.svg';
    }
    
    // Default icon
    return 'assets/icons/exercises/default_exercise.svg';
  }
}