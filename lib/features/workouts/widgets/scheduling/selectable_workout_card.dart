// lib/features/workouts/widgets/scheduling/selectable_workout_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workout.dart';
import '../../providers/workout_scheduling_provider.dart';
import '../workout_card.dart';
import '../../../../shared/theme/color_palette.dart';

class SelectableWorkoutCard extends ConsumerWidget {
  final Workout workout;
  final bool isCompact;
  
  const SelectableWorkoutCard({
    Key? key, 
    required this.workout,
    this.isCompact = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(workoutSchedulingProvider.notifier)
                          .isWorkoutSelected(workout.id);
    
    return Stack(
      children: [
        WorkoutCard(
          workout: workout,
          isCompact: isCompact,
          onTap: () {
            ref.read(workoutSchedulingProvider.notifier)
               .addWorkout(workout);
               
            if (!isSelected) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${workout.title} added to selection'),
                  duration: const Duration(seconds: 1),
                  backgroundColor: AppColors.popGreen,
                ),
              );
            }
          },
        ),
        if (isSelected)
          Positioned(
            top: 16,
            right: isCompact ? 12 : 24,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.pink,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.check, size: 16, color: Colors.white),
            ),
          ),
      ],
    );
  }
}