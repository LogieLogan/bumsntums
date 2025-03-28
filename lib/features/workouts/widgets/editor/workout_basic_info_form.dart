// lib/features/workouts/widgets/editor/workout_basic_info_form.dart
import 'package:flutter/material.dart';
import '../../models/workout.dart';

class WorkoutBasicInfoForm extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final WorkoutCategory selectedCategory;
  final WorkoutDifficulty selectedDifficulty;
  final Function(WorkoutCategory) onCategoryChanged;
  final Function(WorkoutDifficulty) onDifficultyChanged;

  const WorkoutBasicInfoForm({
    Key? key,
    required this.titleController,
    required this.descriptionController,
    required this.selectedCategory,
    required this.selectedDifficulty,
    required this.onCategoryChanged,
    required this.onDifficultyChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Workout Title',
            hintText: 'e.g., Booty Blast Workout',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Describe what this workout focuses on',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Category selection
        DropdownButtonFormField<WorkoutCategory>(
          value: selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Category',
          ),
          items: WorkoutCategory.values.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(_categoryToString(category)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onCategoryChanged(value);
            }
          },
        ),

        // Difficulty selection
        const SizedBox(height: 16),
        DropdownButtonFormField<WorkoutDifficulty>(
          value: selectedDifficulty,
          decoration: const InputDecoration(
            labelText: 'Difficulty',
          ),
          items: WorkoutDifficulty.values.map((difficulty) {
            return DropdownMenuItem(
              value: difficulty,
              child: Text(_difficultyToString(difficulty)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onDifficultyChanged(value);
            }
          },
        ),
      ],
    );
  }

  String _categoryToString(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.bums:
        return 'Bums';
      case WorkoutCategory.tums:
        return 'Tums';
      case WorkoutCategory.fullBody:
        return 'Full Body';
      case WorkoutCategory.cardio:
        return 'Cardio';
      case WorkoutCategory.quickWorkout:
        return 'Quick Workout';
    }
  }

  String _difficultyToString(WorkoutDifficulty difficulty) {
    switch (difficulty) {
      case WorkoutDifficulty.beginner:
        return 'Beginner';
      case WorkoutDifficulty.intermediate:
        return 'Intermediate';
      case WorkoutDifficulty.advanced:
        return 'Advanced';
    }
  }
}