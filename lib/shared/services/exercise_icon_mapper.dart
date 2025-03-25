// lib/shared/services/exercise_icon_mapper.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ExerciseIconMapper {
  // Get icon for a target area
  static IconData getIconForTargetArea(String targetArea) {
    switch (targetArea.toLowerCase()) {
      case 'bums':
        return FontAwesomeIcons.personWalking; // Glutes/lower body
      case 'tums':
        return FontAwesomeIcons.personDress; // Core/abs
      case 'arms':
        return FontAwesomeIcons.dumbbell; // Arms (more weight-related)
      case 'legs':
        return FontAwesomeIcons.personRunning; // Legs
      case 'back':
        return FontAwesomeIcons.personSwimming; // Back (better representation)
      case 'chest':
        return FontAwesomeIcons.heartPulse; // Chest (more workout-focused)
      case 'shoulders':
        return FontAwesomeIcons.personArrowUpFromLine; // Shoulders
      case 'fullbody':
        return FontAwesomeIcons.personRays; // Full body
      default:
        return FontAwesomeIcons.personCircleCheck; // Generic default
    }
  }
}