// lib/features/workouts/screens/exercise_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../providers/exercise_providers.dart';
import '../widgets/exercise_demo_widget.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/theme/app_colors.dart';

class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final String exerciseId;

  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  ConsumerState<ExerciseDetailScreen> createState() =>
      _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exerciseAsync = ref.watch(exerciseDetailProvider(widget.exerciseId));

    return Scaffold(
      appBar: AppBar(
        title: exerciseAsync.maybeWhen(
          data: (exercise) => Text(exercise.name),
          orElse: () => const Text('Exercise Details'),
        ),
        actions: [
          // ...
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Details'), Tab(text: 'Similar Exercises')],
        ),
      ),
      body: exerciseAsync.when(
        data: (exercise) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildExerciseDetail(context, exercise, ref),
              _buildSimilarExercises(context, exercise, ref),
            ],
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error:
            (error, _) => Center(child: Text('Error loading exercise: $error')),
      ),
    );
  }

  Widget _buildExerciseDetail(
    BuildContext context,
    Exercise exercise,
    WidgetRef ref,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video demonstration
          SizedBox(
            height: 250,
            width: double.infinity,
            child: ExerciseDemoWidget(
              exercise: exercise,
              autoPlay: true,
              showControls: true,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic info
                Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.displayMedium,
                ),

                const SizedBox(height: 8),

                // Target area and difficulty
                Row(
                  children: [
                    Chip(
                      label: Text(exercise.targetArea),
                      backgroundColor: AppColors.salmon.withOpacity(0.2),
                      labelStyle: const TextStyle(color: AppColors.salmon),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('Level ${exercise.difficultyLevel}'),
                      backgroundColor: AppColors.popTurquoise.withOpacity(0.2),
                      labelStyle: const TextStyle(
                        color: AppColors.popTurquoise,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(exercise.description),

                // Form tips
                if (exercise.formTips.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Form Tips',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  ...exercise.formTips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.popGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(tip)),
                        ],
                      ),
                    ),
                  ),
                ],

                // Include all the other sections from the original _buildExerciseDetail method
                // but remove the "Similar Exercises" section which is now in its own tab
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarExercises(
    BuildContext context,
    Exercise exercise,
    WidgetRef ref,
  ) {
    final similarExercisesAsync = ref.watch(similarExercisesProvider(exercise));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: similarExercisesAsync.when(
        data: (similarExercises) {
          if (similarExercises.isEmpty) {
            return const Center(child: Text('No similar exercises found'));
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: similarExercises.length,
            itemBuilder: (context, index) {
              final similarExercise = similarExercises[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ExerciseDetailScreen(
                            exerciseId: similarExercise.id,
                          ),
                    ),
                  );
                },
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Image.asset(
                          similarExercise.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.lightGrey,
                              child: const Center(
                                child: Icon(Icons.image_not_supported),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              similarExercise.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              similarExercise.targetArea,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error:
            (error, _) =>
                Center(child: Text('Error loading similar exercises: $error')),
      ),
    );
  }
}
