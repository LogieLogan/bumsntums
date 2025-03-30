// lib/features/workouts/widgets/scheduling/scheduled_workout_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/workout_scheduling_provider.dart';
import '../../../../shared/theme/color_palette.dart';
import '../../../../shared/theme/text_styles.dart';

class ScheduledWorkoutItemWidget extends ConsumerWidget {
  final int index;
  
  const ScheduledWorkoutItemWidget({Key? key, required this.index}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduledItems = ref.watch(workoutSchedulingProvider);
    if (index >= scheduledItems.length) return const SizedBox();
    
    final item = scheduledItems[index];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Small workout image or icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.popCoral.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.fitness_center,
              size: 16,
              color: AppColors.popCoral,
            ),
          ),
          const SizedBox(width: 12),
          
          // Workout title
          Expanded(
            child: Text(
              item.workout.title,
              style: AppTextStyles.small.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Time slot dropdown
          DropdownButton<TimeSlot>(
            value: item.timeSlot,
            isDense: true,
            underline: Container(height: 0),
            onChanged: (newValue) {
              if (newValue != null) {
                ref.read(workoutSchedulingProvider.notifier)
                   .updateTimeSlot(index, newValue);
              }
            },
            items: _buildTimeSlotItems(),
          ),
          
          // Remove button
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              ref.read(workoutSchedulingProvider.notifier)
                 .removeWorkout(index);
            },
          ),
        ],
      ),
    );
  }
  
  List<DropdownMenuItem<TimeSlot>> _buildTimeSlotItems() {
    return [
      DropdownMenuItem(
        value: TimeSlot.morning,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wb_sunny,
              size: 12,
              color: AppColors.popYellow,
            ),
            const SizedBox(width: 4),
            Text(
              'AM',
              style: AppTextStyles.small,
            ),
          ],
        ),
      ),
      DropdownMenuItem(
        value: TimeSlot.lunch,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.restaurant,
              size: 12,
              color: AppColors.popBlue,
            ),
            const SizedBox(width: 4),
            Text(
              'Lunch',
              style: AppTextStyles.small,
            ),
          ],
        ),
      ),
      DropdownMenuItem(
        value: TimeSlot.evening,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.nightlight_round,
              size: 12,
              color: AppColors.darkGrey,
            ),
            const SizedBox(width: 4),
            Text(
              'PM',
              style: AppTextStyles.small,
            ),
          ],
        ),
      ),
    ];
  }
}