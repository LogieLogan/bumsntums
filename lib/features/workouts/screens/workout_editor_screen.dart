// lib/features/workouts/screens/workout_editor_screen.dart
import 'package:bums_n_tums/features/workouts/screens/exercise_editor_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/exercise_selector_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../providers/workout_editor_provider.dart';

class WorkoutEditorScreen extends ConsumerStatefulWidget {
  final Workout? originalWorkout; // Null if creating a new workout

  const WorkoutEditorScreen({Key? key, this.originalWorkout}) : super(key: key);

  @override
  ConsumerState<WorkoutEditorScreen> createState() =>
      _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends ConsumerState<WorkoutEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  WorkoutCategory _selectedCategory = WorkoutCategory.fullBody;
  WorkoutDifficulty _selectedDifficulty = WorkoutDifficulty.beginner;
  List<Exercise> _exercises = [];
  List<String> _equipment = [];
  List<String> _tags = [];
  bool _isNewWorkout = true;

  @override
  void initState() {
    super.initState();

    if (widget.originalWorkout != null) {
      _isNewWorkout = false;
      _titleController = TextEditingController(
        text: widget.originalWorkout!.title,
      );
      _descriptionController = TextEditingController(
        text: widget.originalWorkout!.description,
      );
      _selectedCategory = widget.originalWorkout!.category;
      _selectedDifficulty = widget.originalWorkout!.difficulty;
      _exercises = List.from(widget.originalWorkout!.exercises);
      _equipment = List.from(widget.originalWorkout!.equipment);
      _tags = List.from(widget.originalWorkout!.tags);
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewWorkout ? 'Create Workout' : 'Edit Workout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveWorkout, // No parameters needed
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Basic info section
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Workout Title',
                hintText: 'e.g., Booty Blast Workout',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe what this workout focuses on',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Category selection
            DropdownButtonFormField<WorkoutCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items:
                  WorkoutCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(_categoryToString(category)),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),

            // Difficulty selection
            const SizedBox(height: 16),
            DropdownButtonFormField<WorkoutDifficulty>(
              value: _selectedDifficulty,
              decoration: const InputDecoration(labelText: 'Difficulty'),
              items:
                  WorkoutDifficulty.values.map((difficulty) {
                    return DropdownMenuItem(
                      value: difficulty,
                      child: Text(_difficultyToString(difficulty)),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedDifficulty = value;
                  });
                }
              },
            ),

            // Exercises section
            const SizedBox(height: 24),
            const Text(
              'Exercises',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildExerciseList(),

            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
              onPressed: () => _addExercise(), // Also make this explicit
            ),

            // Equipment section
            const SizedBox(height: 24),
            const Text(
              'Equipment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ..._equipment.map(
                  (item) => Chip(
                    label: Text(item),
                    onDeleted: () {
                      setState(() {
                        _equipment.remove(item);
                      });
                    },
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  onPressed: () => _addEquipment(), // Explicit function call
                ),
              ],
            ),

            // Tags section
            const SizedBox(height: 24),
            const Text(
              'Tags',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ..._tags.map(
                  (tag) => Chip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() {
                        _tags.remove(tag);
                      });
                    },
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  onPressed: () => _addTag(), // Explicit function call
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseList() {
    if (_exercises.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'No exercises added yet. Add some exercises to your workout!',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _exercises.length,
      itemBuilder: (context, index) {
        final exercise = _exercises[index];
        return ListTile(
          key: ValueKey(exercise.id),
          leading:
              exercise.imageUrl.startsWith('http')
                  ? Image.network(
                    exercise.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, e, s) => const Icon(Icons.fitness_center),
                  )
                  : Image.asset(
                    exercise.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, e, s) => const Icon(Icons.fitness_center),
                  ),
          title: Text(exercise.name),
          subtitle: Text('${exercise.sets} sets x ${exercise.reps} reps'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editExercise(index),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _exercises.removeAt(index);
                  });
                },
              ),
            ],
          ),
        );
      },
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = _exercises.removeAt(oldIndex);
          _exercises.insert(newIndex, item);
        });
      },
    );
  }

  Future<void> _addExercise() async {
    // This will be handled by the exercise selector screen
    final exercise = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(builder: (context) => const ExerciseSelectorScreen()),
    );

    if (exercise != null) {
      setState(() {
        _exercises.add(exercise);
      });
    }
  }

  Future<void> _editExercise(int index) async {
    // Navigate to exercise editor
    final exercise = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseEditorScreen(exercise: _exercises[index]),
      ),
    );

    if (exercise != null) {
      setState(() {
        _exercises[index] = exercise;
      });
    }
  }

  Future<void> _addEquipment() async {
    // Show a dialog to add equipment
    final TextEditingController controller = TextEditingController();

    final String? equipment = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Equipment'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g., dumbbells, mat, resistance band',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Add'),
              ),
            ],
          ),
    );

    if (equipment != null && equipment.isNotEmpty) {
      setState(() {
        _equipment.add(equipment);
      });
    }
  }

  Future<void> _addTag() async {
    // Show a dialog to add a tag
    final TextEditingController controller = TextEditingController();

    final String? tag = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Tag'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g., beginner, strength, cardio',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Add'),
              ),
            ],
          ),
    );

    if (tag != null && tag.isNotEmpty) {
      setState(() {
        _tags.add(tag);
      });
    }
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
      default:
        return 'Unknown';
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
      default:
        return 'Unknown';
    }
  }

  void _saveWorkout() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a workout title')),
      );
      return;
    }

    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one exercise')),
      );
      return;
    }

    // Calculate estimated duration based on exercises
    int totalDuration = 0;
    for (final exercise in _exercises) {
      // Calculate time for sets, reps, and rest
      int exerciseTime = 0;

      if (exercise.durationSeconds != null) {
        exerciseTime += exercise.durationSeconds! * exercise.sets;
      } else {
        // Estimate 3 seconds per rep
        exerciseTime += exercise.sets * exercise.reps * 3;
      }

      // Add rest time between sets
      exerciseTime += exercise.restBetweenSeconds * (exercise.sets - 1);

      totalDuration += exerciseTime;
    }

    // Convert to minutes and round up
    int durationMinutes = (totalDuration / 60).ceil();

    // Create the workout object
    final workout = Workout(
      id: widget.originalWorkout?.id ?? 'custom-${const Uuid().v4()}',
      title: _titleController.text,
      description: _descriptionController.text,
      imageUrl:
          widget.originalWorkout?.imageUrl ??
          'assets/images/workouts/custom_workout.jpg',
      category: _selectedCategory,
      difficulty: _selectedDifficulty,
      durationMinutes: durationMinutes,
      estimatedCaloriesBurn: _calculateEstimatedCalories(
        durationMinutes,
        _selectedDifficulty,
      ),
      featured: false,
      isAiGenerated: false,
      createdAt: widget.originalWorkout?.createdAt ?? DateTime.now(),
      createdBy: 'user', // This should be the actual user ID
      exercises: _exercises,
      equipment: _equipment,
      tags: _tags,
    );

    // Save the workout using the provider
    ref.read(workoutEditorProvider.notifier).saveWorkout(workout);

    // Close the screen and return the workout
    Navigator.pop(context, workout);
  }

  int _calculateEstimatedCalories(
    int durationMinutes,
    WorkoutDifficulty difficulty,
  ) {
    // Simple calculation - can be made more sophisticated
    int baseCaloriesPerMinute = 5; // Base calories burned per minute

    // Adjust based on difficulty
    switch (difficulty) {
      case WorkoutDifficulty.beginner:
        baseCaloriesPerMinute = 5;
        break;
      case WorkoutDifficulty.intermediate:
        baseCaloriesPerMinute = 7;
        break;
      case WorkoutDifficulty.advanced:
        baseCaloriesPerMinute = 10;
        break;
    }

    return durationMinutes * baseCaloriesPerMinute;
  }
}
