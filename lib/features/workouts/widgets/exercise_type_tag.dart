// lib/features/workouts/widgets/exercise_type_tag.dart
import 'package:flutter/material.dart';
import '../../../shared/theme/color_palette.dart';

class ExerciseTypeTag extends StatelessWidget {
  final String type;
  
  const ExerciseTypeTag({
    Key? key,
    required this.type,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    Color tagColor;
    IconData tagIcon;
    
    // Assign colors and icons based on exercise type
    switch (type.toLowerCase()) {
      case 'strength':
        tagColor = AppColors.popCoral;
        tagIcon = Icons.fitness_center;
        break;
      case 'endurance':
        tagColor = AppColors.popBlue;
        tagIcon = Icons.timer;
        break;
      case 'stability':
        tagColor = AppColors.popTurquoise;
        tagIcon = Icons.balance;
        break;
      case 'mobility':
        tagColor = AppColors.popYellow;
        tagIcon = Icons.straighten;
        break;
      case 'isometric':
        tagColor = Colors.purple;
        tagIcon = Icons.pause_circle_filled;
        break;
      case 'compound':
        tagColor = AppColors.popGreen;
        tagIcon = Icons.account_tree;
        break;
      case 'isolation':
        tagColor = Colors.amber;
        tagIcon = Icons.center_focus_strong;
        break;
      default:
        tagColor = AppColors.salmon;
        tagIcon = Icons.sports_gymnastics;
    }
    
    return Chip(
      avatar: Icon(tagIcon, color: tagColor, size: 16),
      label: Text(
        type.substring(0, 1).toUpperCase() + type.substring(1),
        style: TextStyle(color: tagColor),
      ),
      backgroundColor: tagColor.withOpacity(0.1),
      side: BorderSide(color: tagColor.withOpacity(0.3)),
    );
  }
}