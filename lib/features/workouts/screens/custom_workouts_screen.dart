// features/workouts/screens/custom_workouts_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../repositories/custom_workout_repository.dart';
import '../widgets/workout_card.dart';
import '../screens/workout_editor_screen.dart';
import '../screens/workout_detail_screen.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';

final customWorkoutsProvider = FutureProvider.autoDispose
    .family<List<Workout>, String>((ref, userId) async {
      final repository = CustomWorkoutRepository();
      return repository.getUserWorkouts(userId);
    });

class CustomWorkoutsScreen extends ConsumerWidget {
  final String userId;

  const CustomWorkoutsScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(customWorkoutsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Custom Workouts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create New Workout',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorkoutEditorScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: workoutsAsync.when(
        data: (workouts) {
          if (workouts.isEmpty) {
            return _buildEmptyState(context);
          }

          Consumer(
            builder: (context, ref, child) {
              return _buildWorkoutsList(context, ref, workouts);
            },
          );
        },
        loading:
            () => const LoadingIndicator(message: 'Loading your workouts...'),
        error:
            (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading workouts',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.mediumGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed:
                        () => ref.refresh(customWorkoutsProvider(userId)),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WorkoutEditorScreen(),
            ),
          );
        },
        backgroundColor: AppColors.salmon,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 64, color: AppColors.mediumGrey),
          const SizedBox(height: 16),
          Text(
            'You haven\'t created any custom workouts yet',
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your own workout routines tailored to your preferences',
            style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create First Workout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.salmon,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorkoutEditorScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutsList(
    BuildContext context,
    WidgetRef ref,
    List<Workout> workouts,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return Dismissible(
          key: Key(workout.id),
          background: Container(
            color: AppColors.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Delete Workout'),
                    content: Text(
                      'Are you sure you want to delete "${workout.title}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
            );
          },
          onDismissed: (direction) async {
            // Delete the workout
            final repository = CustomWorkoutRepository();
            await repository.deleteCustomWorkout(userId, workout.id);

            // Show snackbar with undo option
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${workout.title} deleted'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () async {
                    // Re-add the workout
                    await repository.saveCustomWorkout(userId, workout);
                    ref.refresh(customWorkoutsProvider(userId));
                  },
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildWorkoutCard(context, workout),
          ),
        );
      },
    );
  }

  Widget _buildWorkoutCard(BuildContext context, Workout workout) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutDetailScreen(workoutId: workout.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workout image or placeholder
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.salmon.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.fitness_center,
                  size: 48,
                  color: AppColors.salmon,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Workout title
                  Text(
                    workout.title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Workout stats
                  Row(
                    children: [
                      Icon(Icons.timer, size: 16, color: AppColors.mediumGrey),
                      const SizedBox(width: 4),
                      Text(
                        '${workout.durationMinutes} min',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.mediumGrey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.fitness_center,
                        size: 16,
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

                  const SizedBox(height: 8),

                  // Workout category and difficulty
                  Row(
                    children: [
                      _buildChip(
                        workout.category.name,
                        AppColors.salmon.withOpacity(0.1),
                        AppColors.salmon,
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        workout.difficulty.name,
                        AppColors.popBlue.withOpacity(0.1),
                        AppColors.popBlue,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => WorkoutEditorScreen(
                                      originalWorkout: workout,
                                    ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.salmon,
                            side: BorderSide(color: AppColors.salmon),
                          ),
                          child: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => WorkoutDetailScreen(
                                      workoutId: workout.id,
                                    ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.salmon,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Start'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.substring(0, 1).toUpperCase() + label.substring(1),
        style: AppTextStyles.caption.copyWith(color: textColor),
      ),
    );
  }
}
