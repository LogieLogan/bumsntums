// lib/features/workouts/screens/workout_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/workout_section.dart';
import '../providers/workout_editor_provider.dart';
import '../widgets/editor/section_card.dart';
import '../widgets/editor/workout_basic_info_form.dart';
import '../widgets/editor/equipment_and_tags_section.dart';
import '../screens/exercise_selector_screen.dart';
import '../../../shared/theme/app_colors.dart';

class WorkoutEditorScreen extends ConsumerStatefulWidget {
  final Workout? originalWorkout; // Null if creating a new workout
  final bool isTemplate;

  const WorkoutEditorScreen({
    super.key,
    this.originalWorkout,
    this.isTemplate = false,
  });

  @override
  ConsumerState<WorkoutEditorScreen> createState() =>
      _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends ConsumerState<WorkoutEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  WorkoutCategory _selectedCategory = WorkoutCategory.fullBody;
  WorkoutDifficulty _selectedDifficulty = WorkoutDifficulty.beginner;
  List<WorkoutSection> _sections = [];
  List<String> _equipment = [];
  List<String> _tags = [];
  bool _isNewWorkout = true;
  String? _versionNotes;

  @override
  void initState() {
    super.initState();
    _initializeWorkout();
  }

  void _initializeWorkout() {
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

      // Handle sections
      if (widget.originalWorkout!.sections.isNotEmpty) {
        _sections = List.from(widget.originalWorkout!.sections);
      } else {
        // Convert legacy exercises to a section
        _sections = [
          WorkoutSection(
            id: 'section-${const Uuid().v4()}',
            name: 'Main Workout',
            exercises: List.from(widget.originalWorkout!.exercises),
          ),
        ];
      }

      _equipment = List.from(widget.originalWorkout!.equipment);
      _tags = List.from(widget.originalWorkout!.tags);

      // Update the active workout in the provider
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(workoutEditorProvider.notifier)
            .updateActiveWorkout(widget.originalWorkout!);
      });
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();

      // Create a default empty section
      _sections = [
        WorkoutSection(
          id: 'section-${const Uuid().v4()}',
          name: 'Main Workout',
          exercises: [],
        ),
      ];
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
    final editorState = ref.watch(workoutEditorProvider);
    final isSaving = editorState.isSaving;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getAppBarTitle()),
          actions: [
            if (!_isNewWorkout && !widget.isTemplate)
              IconButton(
                icon: const Icon(Icons.save_as),
                tooltip: 'Save as Template',
                onPressed: isSaving ? null : _saveAsTemplate,
              ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: isSaving ? null : _saveWorkout,
            ),
          ],
        ),
        body:
            isSaving
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Basic info section
                      WorkoutBasicInfoForm(
                        titleController: _titleController,
                        descriptionController: _descriptionController,
                        selectedCategory: _selectedCategory,
                        selectedDifficulty: _selectedDifficulty,
                        onCategoryChanged: (category) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        onDifficultyChanged: (difficulty) {
                          setState(() {
                            _selectedDifficulty = difficulty;
                          });
                        },
                      ),

                      // Sections
                      const SizedBox(height: 24),
                      _buildSectionsArea(),

                      // Equipment and tags
                      const SizedBox(height: 24),
                      EquipmentAndTagsSection(
                        equipment: _equipment,
                        tags: _tags,
                        onAddEquipment: (item) {
                          setState(() {
                            _equipment.add(item);
                          });
                        },
                        onRemoveEquipment: (item) {
                          setState(() {
                            _equipment.remove(item);
                          });
                        },
                        onAddTag: (tag) {
                          setState(() {
                            _tags.add(tag);
                          });
                        },
                        onRemoveTag: (tag) {
                          setState(() {
                            _tags.remove(tag);
                          });
                        },
                      ),

                      // Version notes (if not a new workout)
                      if (!_isNewWorkout && !widget.isTemplate) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Version Notes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: const InputDecoration(
                            hintText: 'Describe what changed in this version',
                            helperText:
                                'Optional - helps track your changes over time',
                          ),
                          onChanged: (value) {
                            _versionNotes = value;
                          },
                        ),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        floatingActionButton: FloatingActionButton(
          onPressed: _saveWorkout,
          tooltip: 'Save Workout',
          child: const Icon(Icons.save),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    if (widget.isTemplate) {
      return _isNewWorkout ? 'Create Template' : 'Edit Template';
    } else {
      return _isNewWorkout ? 'Create Workout' : 'Edit Workout';
    }
  }

  Widget _buildSectionsArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Workout Sections',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Section'),
              onPressed: _addSection,
            ),
          ],
        ),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _sections.length,
          itemBuilder: (context, sectionIndex) {
            return SectionCard(
              section: _sections[sectionIndex],
              sectionIndex: sectionIndex,
              onAddExercise: _addExerciseToSection,
              onEditSectionName: _editSectionName,
              onDeleteSection: _deleteSection,
              onReorderExercises: _reorderExercises,
              onUpdateExercise: _updateExercise,
            );
          },
        ),
      ],
    );
  }

  // Handlers for section actions
  void _addSection() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Section'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Section Name',
                  hintText: 'e.g., Warm-up, Main Workout, Cool-down',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _sections.add(
                      WorkoutSection(
                        id: 'section-${const Uuid().v4()}',
                        name: nameController.text,
                        exercises: [],
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add Section'),
            ),
          ],
        );
      },
    );
  }

  void _editSectionName(int sectionIndex, String currentName) {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController(text: currentName);
        return AlertDialog(
          title: const Text('Edit Section Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Section Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _sections[sectionIndex] = _sections[sectionIndex].copyWith(
                      name: nameController.text,
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteSection(int sectionIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Section'),
          content: Text(
            'Are you sure you want to delete "${_sections[sectionIndex].name}"? '
            'All exercises in this section will be removed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _sections.removeAt(sectionIndex);
                });
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addExerciseToSection(int sectionIndex) async {
    final exercise = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(builder: (context) => const ExerciseSelectorScreen()),
    );

    if (exercise != null) {
      setState(() {
        final updatedSection = _sections[sectionIndex].copyWith(
          exercises: [..._sections[sectionIndex].exercises, exercise],
        );
        _sections[sectionIndex] = updatedSection;
      });
    }
  }

  void _reorderExercises(int sectionIndex, int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _sections[sectionIndex].exercises.removeAt(oldIndex);
      _sections[sectionIndex].exercises.insert(newIndex, item);

      // Update the section
      _sections[sectionIndex] = _sections[sectionIndex].copyWith(
        exercises: _sections[sectionIndex].exercises,
      );
    });
  }

  void _updateExercise(
    int sectionIndex,
    Exercise updatedExercise,
    int exerciseIndex,
  ) {
    setState(() {
      final exercises = List<Exercise>.from(_sections[sectionIndex].exercises);
      exercises[exerciseIndex] = updatedExercise;

      _sections[sectionIndex] = _sections[sectionIndex].copyWith(
        exercises: exercises,
      );
    });
  }

  Future<bool> _onWillPop() async {
    // Check if there are unsaved changes
    bool hasUnsavedChanges = false;

    // For new workouts, check if any fields have been filled
    if (_isNewWorkout) {
      hasUnsavedChanges =
          _titleController.text.isNotEmpty ||
          _descriptionController.text.isNotEmpty ||
          _sections.any((s) => s.exercises.isNotEmpty) ||
          _equipment.isNotEmpty ||
          _tags.isNotEmpty;
    } else {
      // For editing existing workouts, check if anything changed
      final originalWorkout = widget.originalWorkout!;

      hasUnsavedChanges =
          _titleController.text != originalWorkout.title ||
          _descriptionController.text != originalWorkout.description ||
          _selectedCategory != originalWorkout.category ||
          _selectedDifficulty != originalWorkout.difficulty ||
          _sections.length !=
              (originalWorkout.sections.isEmpty
                  ? 1
                  : originalWorkout.sections.length) ||
          _equipment.length != originalWorkout.equipment.length ||
          _tags.length != originalWorkout.tags.length;
    }

    if (!hasUnsavedChanges) {
      return true; // No changes, allow pop
    }

    // Show confirmation dialog
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Don't discard
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Discard
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Discard'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Don't discard yet
                _saveWorkout(); // Save the workout
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.salmon,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    return shouldPop ?? false;
  }

  void _saveAsTemplate() async {
    final workout = _buildWorkoutObject();

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Save as Template'),
            content: const Text(
              'Do you want to save this workout as a reusable template? '
              'Templates can be used to quickly create new workouts with the same structure.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.salmon,
                ),
                child: const Text('Save as Template'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final editorNotifier = ref.read(workoutEditorProvider.notifier);
      final success = await editorNotifier.convertToTemplate(workout);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved as template successfully')),
        );
      }
    }
  }

  Future<void> _saveWorkout() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a workout title')),
      );
      return;
    }

    if (_sections.every((section) => section.exercises.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one exercise')),
      );
      return;
    }

    // Build the workout object
    final workout = _buildWorkoutObject();

    // Save the workout using the provider
    final editorNotifier = ref.read(workoutEditorProvider.notifier);

    bool success;
    if (_isNewWorkout || widget.isTemplate) {
      // Save as a new workout or template
      success = await editorNotifier.saveWorkout(workout);
    } else {
      // Save as a new version if version notes are provided
      if (_versionNotes != null && _versionNotes!.isNotEmpty) {
        success = await editorNotifier.saveWorkoutVersion(
          workout,
          _versionNotes!,
        );
      } else {
        // Just update the existing workout
        success = await editorNotifier.saveWorkout(workout);
      }
    }

    if (success && mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout saved successfully')),
      );

      // Close the screen and return the workout
      Navigator.pop(context, workout);
    }
  }

  Workout _buildWorkoutObject() {
    // Calculate estimated duration based on exercises
    int totalDuration = 0;
    for (final section in _sections) {
      for (final exercise in section.exercises) {
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

      // Add rest time after section
      totalDuration += section.restAfterSection;
    }

    // Convert to minutes and round up
    int durationMinutes = (totalDuration / 60).ceil();

    // Create the workout object
    return Workout(
      id: widget.originalWorkout?.id ?? 'workout-${const Uuid().v4()}',
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
      exercises: _getAllExercises(), // For backward compatibility
      equipment: _equipment,
      tags: _tags,
      isTemplate: widget.isTemplate,
      sections: _sections,
      parentTemplateId: widget.originalWorkout?.parentTemplateId,
      previousVersionId: _isNewWorkout ? null : widget.originalWorkout?.id,
      versionNotes: _versionNotes ?? '',
      timesUsed: widget.originalWorkout?.timesUsed ?? 0,
      lastUsed: widget.originalWorkout?.lastUsed,
    );
  }

  // Get all exercises from all sections for backward compatibility
  List<Exercise> _getAllExercises() {
    return _sections.expand((section) => section.exercises).toList();
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
