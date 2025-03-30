// lib/features/workouts/widgets/workout_progress_chart.dart
import 'package:flutter/material.dart';
import '../../workout_planning/models/workout_plan.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';

class WorkoutProgressChart extends StatelessWidget {
  final WorkoutPlan plan;
  
  const WorkoutProgressChart({Key? key, required this.plan}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate statistics for visualization
    final totalWorkouts = plan.scheduledWorkouts.length;
    final completedWorkouts = plan.scheduledWorkouts
        .where((workout) => workout.isCompleted)
        .length;
    final completionPercentage = totalWorkouts > 0 
        ? (completedWorkouts / totalWorkouts * 100).round() 
        : 0;
    
    // Count workouts by status
    final todayWorkouts = plan.scheduledWorkouts
        .where((workout) => 
            _isToday(workout.scheduledDate) && !workout.isCompleted)
        .length;
    final upcomingWorkouts = plan.scheduledWorkouts
        .where((workout) => 
            workout.scheduledDate.isAfter(DateTime.now()) && !workout.isCompleted)
        .length;
    final missedWorkouts = plan.scheduledWorkouts
        .where((workout) =>
            _isPast(workout.scheduledDate) && 
            !_isToday(workout.scheduledDate) && 
            !workout.isCompleted)
        .length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paleGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Overview',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 16),
          
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$completedWorkouts/$totalWorkouts completed',
                    style: AppTextStyles.body,
                  ),
                  Text(
                    '$completionPercentage%',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getCompletionColor(completionPercentage),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: totalWorkouts > 0 ? completedWorkouts / totalWorkouts : 0,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getCompletionColor(completionPercentage),
                  ),
                  minHeight: 10,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Status squares
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusSquare(
                'Today',
                todayWorkouts,
                AppColors.popCoral,
              ),
              _buildStatusSquare(
                'Upcoming',
                upcomingWorkouts,
                AppColors.popBlue,
              ),
              _buildStatusSquare(
                'Completed',
                completedWorkouts,
                AppColors.popGreen,
              ),
              _buildStatusSquare(
                'Missed',
                missedWorkouts,
                Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusSquare(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.small.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Color _getCompletionColor(int percentage) {
    if (percentage >= 75) {
      return AppColors.popGreen;
    } else if (percentage >= 50) {
      return AppColors.popYellow;
    } else if (percentage >= 25) {
      return AppColors.popCoral;
    } else {
      return Colors.grey;
    }
  }
  
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
  
  bool _isPast(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate = DateTime(date.year, date.month, date.day);
    return compareDate.isBefore(today);
  }
}