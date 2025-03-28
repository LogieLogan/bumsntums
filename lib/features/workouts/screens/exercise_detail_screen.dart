// lib/features/workouts/screens/exercise_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../providers/exercise_providers.dart';
import '../widgets/exercise_demo_widget.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/theme/color_palette.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  final String exerciseId;

  const ExerciseDetailScreen({Key? key, required this.exerciseId})
    : super(key: key);

  @override
  build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseDetailProvider(exerciseId));

    return Scaffold(
      appBar: AppBar(
        title: exerciseAsync.maybeWhen(
          data: (exercise) => Text(exercise.name),
          orElse: () => const Text('Exercise Details'),
        ),
        actions: [
          // ...
        ],
      ),
      body: exerciseAsync.when(
        data: (exercise) {
          return _buildExerciseDetail(context, exercise, ref);
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
    final similarExercisesAsync = ref.watch(similarExercisesProvider(exercise));

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

                const SizedBox(height: 16),

                // Form tips
                if (exercise.formTips.isNotEmpty) ...[
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

                const SizedBox(height: 16),

                // Common mistakes
                if (exercise.commonMistakes.isNotEmpty) ...[
                  Text(
                    'Common Mistakes',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  ...exercise.commonMistakes.map(
                    (mistake) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(mistake)),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Target muscles
                if (exercise.targetMuscles.isNotEmpty) ...[
                  Text(
                    'Target Muscles',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        exercise.targetMuscles
                            .map(
                              (muscle) => Chip(
                                label: Text(muscle),
                                backgroundColor: AppColors.paleGrey,
                              ),
                            )
                            .toList(),
                  ),
                ],

                const SizedBox(height: 16),

                // Exercise Type
                if (exercise.exerciseType.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Exercise Type',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        exercise.exerciseType
                            .map(
                              (type) => Chip(
                                label: Text(type),
                                backgroundColor: AppColors.popBlue.withOpacity(
                                  0.2,
                                ),
                                labelStyle: TextStyle(color: AppColors.popBlue),
                              ),
                            )
                            .toList(),
                  ),
                ],

                const SizedBox(height: 16),

                // Preparation Steps
                if (exercise.preparationSteps.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Preparation',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  ...exercise.preparationSteps.map(
                    (step) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${exercise.preparationSteps.indexOf(step) + 1}.',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(step)),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Breathing Pattern
                if (exercise.breathingPattern.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Breathing',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.air, color: AppColors.popTurquoise),
                      const SizedBox(width: 12),
                      Expanded(child: Text(exercise.breathingPattern)),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Benefits
                if (exercise.benefits.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Benefits',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  ...exercise.benefits.map(
                    (benefit) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.popYellow,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(benefit)),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Contraindications
                if (exercise.contraindications.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              'Exercise Caution If You Have:',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...exercise.contraindications.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: 4.0,
                              left: 8.0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '•',
                                  style: TextStyle(color: Colors.red),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Equipment options
                if (exercise.equipmentOptions.isNotEmpty) ...[
                  Text(
                    'Equipment Options',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        exercise.equipmentOptions
                            .map(
                              (equipment) => Chip(
                                label: Text(equipment),
                                backgroundColor: AppColors.offWhite,
                              ),
                            )
                            .toList(),
                  ),
                ],

                const SizedBox(height: 24),

                // Similar exercises
                Text(
                  'Similar Exercises',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),

                similarExercisesAsync.when(
                  data: (similarExercises) {
                    if (similarExercises.isEmpty) {
                      return const Text('No similar exercises found');
                    }

                    return SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
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
                            child: Container(
                              width: 150,
                              margin: const EdgeInsets.only(right: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      similarExercise.imageUrl,
                                      height: 80,
                                      width: 150,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          height: 80,
                                          color: AppColors.lightGrey,
                                          child: const Center(
                                            child: Icon(
                                              Icons.image_not_supported,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    similarExercise.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading:
                      () => const SizedBox(
                        height: 100,
                        child: Center(child: LoadingIndicator()),
                      ),
                  error:
                      (error, _) =>
                          Text('Error loading similar exercises: $error'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
