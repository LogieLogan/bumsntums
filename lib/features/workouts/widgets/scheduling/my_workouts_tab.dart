// lib/features/workouts/widgets/scheduling/my_workouts_tab.dart
import 'package:bums_n_tums/features/workouts/models/workout.dart';
import 'package:bums_n_tums/features/workouts/screens/custom_workouts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/workout_scheduling_provider.dart';
import '../../screens/workout_editor_screen.dart';
import '../../../ai/screens/ai_workout_screen.dart';
import '../../../../shared/theme/color_palette.dart';
import '../../../../shared/theme/text_styles.dart';
import '../../../../shared/components/indicators/loading_indicator.dart';

class MyWorkoutsTab extends ConsumerWidget {
  final String userId;
  
  const MyWorkoutsTab({Key? key, required this.userId}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the existing custom workouts provider to get user's workouts
    final customWorkoutsAsync = ref.watch(customWorkoutsStreamProvider(userId));

    return customWorkoutsAsync.when(
      data: (workouts) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Creation options at the top
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Create custom workout
                    Expanded(
                      child: _buildCreationOption(
                        context: context,
                        icon: Icons.add_circle_outline,
                        title: 'Custom Workout',
                        subtitle: 'Build from scratch',
                        onTap: () => _createCustomWorkout(context, ref),
                        color: AppColors.popTurquoise,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Create with AI
                    Expanded(
                      child: _buildCreationOption(
                        context: context,
                        icon: Icons.smart_toy,
                        title: 'AI Workout',
                        subtitle: 'Let AI create for you',
                        onTap: () => _createAIWorkout(context, ref),
                        color: AppColors.popCoral,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Saved workouts section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Your Saved Workouts', style: AppTextStyles.h3),
              ),

              // Display custom workouts or empty state
              workouts.isEmpty
                  ? _buildEmptyWorkoutsState()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(8),
                      itemCount: workouts.length,
                      itemBuilder: (context, index) {
                        return _buildWorkoutListItem(context, ref, workouts[index]);
                      },
                    ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Failed to load your workouts'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.refresh(customWorkoutsStreamProvider(userId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyWorkoutsState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.fitness_center,
              size: 48,
              color: AppColors.lightGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'No saved workouts yet',
              style: AppTextStyles.body.copyWith(
                color: AppColors.mediumGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create custom workouts or generate with AI',
              style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWorkoutListItem(BuildContext context, WidgetRef ref, Workout workout) {
    final isSelected = ref.watch(workoutSchedulingProvider.notifier)
                         .isWorkoutSelected(workout.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          ref.read(workoutSchedulingProvider.notifier).addWorkout(workout);
          
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
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Selection indicator
              isSelected
                  ? Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.pink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    )
                  : Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.paleGrey,
                        shape: BoxShape.circle,
                      ),
                    ),
              const SizedBox(width: 12),

              // Workout icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: workout.isAiGenerated
                      ? AppColors.popCoral.withOpacity(0.2)
                      : AppColors.popTurquoise.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  workout.isAiGenerated ? Icons.smart_toy : Icons.fitness_center,
                  color: workout.isAiGenerated ? AppColors.popCoral : AppColors.popTurquoise,
                ),
              ),
              const SizedBox(width: 12),

              // Workout details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 12,
                          color: AppColors.mediumGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${workout.durationMinutes} min',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.mediumGrey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.fitness_center,
                          size: 12,
                          color: AppColors.mediumGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${workout.exercises.length} exercises',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.mediumGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Type indicator
              if (workout.isAiGenerated)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.popCoral.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.smart_toy,
                        size: 12,
                        color: AppColors.popCoral,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AI',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.popCoral,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper method to build creation options
  Widget _buildCreationOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  // Method to handle custom workout creation
  void _createCustomWorkout(BuildContext context, WidgetRef ref) {
    // Navigate to workout editor screen
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const WorkoutEditorScreen()),
        )
        .then((_) {
          // Refresh the custom workouts list
          final _ = ref.refresh(customWorkoutsStreamProvider(userId));
        });
  }

  // Updated AI workout creation method
  void _createAIWorkout(BuildContext context, WidgetRef ref) {
    // Navigate to AI workout generation screen with flag
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const AIWorkoutScreen(),
            // Pass argument to indicate we're in scheduling mode
            settings: const RouteSettings(arguments: true),
          ),
        )
        .then((workout) {
          if (workout != null && workout is Workout) {
            ref.read(workoutSchedulingProvider.notifier).addWorkout(workout);
          }
          // Refresh the custom workouts list either way
          final _ = ref.refresh(customWorkoutsStreamProvider(userId));
        });
  }
}