// lib/features/workouts/screens/workout_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/workout_provider.dart';
import '../models/workout_log.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout History')),
        body: const Center(
          child: Text('You must be logged in to view workout history'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Workout History')),
      body: ref
          .watch(userWorkoutHistoryProvider(userId))
          .when(
            data: (logs) {
              if (logs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 64,
                        color: AppColors.lightGrey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No workout history yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete your first workout to start tracking your progress!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Find a Workout'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return _buildWorkoutHistoryItem(context, log);
                },
              );
            },
            loading:
                () => const LoadingIndicator(
                  message: 'Loading workout history...',
                ),
            error:
                (error, stack) =>
                    Center(child: Text('Error loading history: $error')),
          ),
    );
  }

  Widget _buildWorkoutHistoryItem(BuildContext context, WorkoutLog log) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Consumer(
      builder: (context, ref, child) {
        // Fetch the workout details to get the name
        final workoutAsync = ref.watch(workoutDetailsProvider(log.workoutId));

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: workoutAsync.when(
                        data:
                            (workout) => Text(
                              workout?.title ?? 'Unknown Workout',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        loading:
                            () => Text(
                              'Loading...',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                        error:
                            (_, __) => Text(
                              'Workout #${log.workoutId.substring(0, 8)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.popBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${log.durationMinutes} min',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.popBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  dateFormat.format(log.completedAt),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetric(
                      context,
                      'Calories',
                      '${log.caloriesBurned}',
                      Icons.local_fire_department,
                      AppColors.popCoral,
                    ),
                    _buildMetric(
                      context,
                      'Rating',
                      '${log.userFeedback.rating}/5',
                      Icons.star,
                      AppColors.popYellow,
                    ),
                    _buildMetric(
                      context,
                      'Exercises',
                      '${log.exercisesCompleted.length}',
                      Icons.fitness_center,
                      AppColors.popGreen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
        ),
      ],
    );
  }
}
