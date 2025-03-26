// lib/features/workouts/widgets/exercise_image_widget.dart
import 'package:flutter/material.dart';
import '../../../shared/services/exercise_media_service.dart';
import '../../../shared/theme/color_palette.dart';
import '../models/exercise.dart';
import '../models/workout.dart';

class ExerciseImageWidget extends StatelessWidget {
  final Exercise exercise;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool showName;
  final WorkoutDifficulty difficulty;

  const ExerciseImageWidget({
    super.key,
    required this.exercise,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.difficulty = WorkoutDifficulty.beginner,
    this.showName = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ExerciseMediaService.exerciseImage(
          exerciseName: exercise.name,
          height: height,
          width: width,
          fit: fit,
          borderRadius: borderRadius,
          difficulty: difficulty,
        ),

        // Optional exercise name overlay
        if (showName)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: Text(
                exercise.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

        // Target area badge
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getTargetAreaColor(exercise.targetArea).withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              exercise.targetArea.capitalize(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getTargetAreaColor(String targetArea) {
    switch (targetArea.toLowerCase()) {
      case 'bums':
        return AppColors.popCoral;
      case 'tums':
        return AppColors.popTurquoise;
      case 'arms':
        return AppColors.popBlue;
      case 'legs':
        return AppColors.popYellow;
      case 'back':
        return AppColors.popGreen;
      case 'chest':
        return AppColors.salmon;
      default:
        return AppColors.salmon;
    }
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
