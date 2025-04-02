// lib/features/workouts/widgets/execution/exercise_info_sheet.dart
import 'package:bums_n_tums/features/workouts/widgets/exercise_demo_widget.dart';
import 'package:flutter/material.dart';
import '../../../../shared/theme/color_palette.dart';
import '../../../../shared/theme/text_styles.dart';
import '../../models/exercise.dart';

class ExerciseInfoSheet extends StatelessWidget {
  final Exercise exercise;

  const ExerciseInfoSheet({
    super.key,
    required this.exercise,
  });

@override
Widget build(BuildContext context) {
  return DraggableScrollableSheet(
    initialChildSize: 0.6,
    minChildSize: 0.3,
    maxChildSize: 0.9,
    expand: false,
    builder: (context, scrollController) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: ListView(
          controller: scrollController,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Exercise name
            Text(
              exercise.name,
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),
            
            // Exercise demo video - NEW ADDITION
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: ExerciseDemoWidget(
                exercise: exercise,
                showControls: true,
                autoPlay: true,
              ),
            ),

            const SizedBox(height: 24),

            // Description
            Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.salmon,
              ),
            ),
            const SizedBox(height: 8),
            Text(exercise.description),

              const SizedBox(height: 24),

              // Form tips
              if (exercise.formTips.isNotEmpty) ...[
                Text(
                  'Form Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.salmon,
                  ),
                ),
                const SizedBox(height: 8),
                ...exercise.formTips.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: AppColors.popGreen,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(tip)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Common mistakes
              if (exercise.commonMistakes.isNotEmpty) ...[
                Text(
                  'Common Mistakes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.salmon,
                  ),
                ),
                const SizedBox(height: 8),
                ...exercise.commonMistakes.map(
                  (mistake) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning,
                          size: 18,
                          color: AppColors.popCoral,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(mistake)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Breathing pattern
              if (exercise.breathingPattern.isNotEmpty) ...[
                Text(
                  'Breathing Pattern',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.salmon,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.air, size: 18, color: AppColors.popBlue),
                    const SizedBox(width: 10),
                    Expanded(child: Text(exercise.breathingPattern)),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Preparation steps
              if (exercise.preparationSteps.isNotEmpty) ...[
                Text(
                  'Preparation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.salmon,
                  ),
                ),
                const SizedBox(height: 8),
                ...exercise.preparationSteps.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.popBlue,
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(entry.value)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Target muscles
              if (exercise.targetMuscles.isNotEmpty) ...[
                Text(
                  'Target Muscles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.salmon,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: exercise.targetMuscles
                      .map(
                        (muscle) => Chip(
                          backgroundColor: AppColors.salmon.withOpacity(0.1),
                          label: Text(
                            muscle,
                            style: TextStyle(color: AppColors.salmon),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],

              const SizedBox(height: 24),

              // Close button
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.salmon,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text('CLOSE'),
              ),
            ],
          ),
        );
      },
    );
  }
}