// lib/features/workout_planning/widgets/workout_day_header.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_colors.dart';

class WorkoutDayHeader extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final int workoutCount;

  const WorkoutDayHeader({
    super.key,
    required this.date,
    required this.isToday,
    required this.workoutCount,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dayFormat = DateFormat('EEEE'); // Full day name
    final dateFormat = DateFormat('MMM d'); // Month and day number
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Day indicator
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isToday ? AppColors.pink : AppColors.paleGrey,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                date.day.toString(),
                style: textTheme.titleLarge?.copyWith(
                  color: isToday ? Colors.white : AppColors.darkGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Day info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayFormat.format(date),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? AppColors.pink : AppColors.darkGrey,
                ),
              ),
              Text(
                dateFormat.format(date),
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.mediumGrey,
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Workout count indicator
          if (workoutCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.popTurquoise.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$workoutCount ${workoutCount == 1 ? 'workout' : 'workouts'}',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.popTurquoise,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}