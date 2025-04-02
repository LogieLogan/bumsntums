// lib/features/ai_workout_planning/widgets/visualization/plan_calendar_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/theme/color_palette.dart';

class PlanCalendarView extends StatelessWidget {
  final List<dynamic> scheduledWorkouts;

  const PlanCalendarView({
    Key? key,
    required this.scheduledWorkouts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Group workouts by day for easier rendering
    final workoutsByDay = <int, List<dynamic>>{};
    
    for (final workout in scheduledWorkouts) {
      final dayNumber = workout['dayNumber'] as int? ?? 1;
      
      if (!workoutsByDay.containsKey(dayNumber)) {
        workoutsByDay[dayNumber] = [];
      }
      
      workoutsByDay[dayNumber]!.add(workout);
    }
    
    // Sort days
    final sortedDays = workoutsByDay.keys.toList()..sort();
    
    return ListView.builder(
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final dayNumber = sortedDays[index];
        final dayWorkouts = workoutsByDay[dayNumber]!;
        
        return _buildDayCard(context, dayNumber, dayWorkouts);
      },
    );
  }

  Widget _buildDayCard(BuildContext context, int dayNumber, List<dynamic> workouts) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.pink,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      dayNumber.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Day $dayNumber',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            const Divider(),
            
            // Workouts for this day
            ...workouts.map((workout) => _buildWorkoutItem(context, workout)),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutItem(BuildContext context, dynamic workout) {
    final isRestDay = workout['isRestDay'] as bool? ?? false;
    final workoutName = workout['workoutName'] as String? ?? 'Workout';
    final category = workout['category'] as String? ?? 'fullBody';
    final difficulty = workout['difficulty'] as String? ?? 'beginner';
    final durationMinutes = workout['durationMinutes'] as int? ?? 30;
    final description = workout['description'] as String? ?? '';
    
    // Skip if there's no workout for a rest day
    if (isRestDay) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.paleGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.hotel,
                color: AppColors.mediumGrey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rest Day',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Take time to recover and recharge',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mediumGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // Get color based on category
    Color categoryColor;
    IconData categoryIcon;
    
    switch (category.toLowerCase()) {
      case 'bums':
        categoryColor = AppColors.pink;
        categoryIcon = Icons.fitness_center;
        break;
      case 'tums':
        categoryColor = AppColors.popCoral;
        categoryIcon = Icons.accessibility;
        break;
      case 'fullbody':
        categoryColor = AppColors.popBlue;
        categoryIcon = Icons.accessibility_new;
        break;
      case 'cardio':
        categoryColor = AppColors.popGreen;
        categoryIcon = Icons.directions_run;
        break;
      default:
        categoryColor = AppColors.popBlue;
        categoryIcon = Icons.accessibility_new;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              categoryIcon,
              color: categoryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workoutName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category.toLowerCase() == 'fullbody'
                            ? 'Full Body'
                            : category,
                        style: TextStyle(
                          color: categoryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        difficulty,
                        style: TextStyle(
                          color: AppColors.darkGrey,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$durationMinutes min',
                      style: TextStyle(
                        color: AppColors.mediumGrey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mediumGrey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}