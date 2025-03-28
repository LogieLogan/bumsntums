// lib/features/workouts/screens/workout_editor_screen.dart
import 'package:bums_n_tums/features/workouts/screens/exercise_selector_screen.dart';
import 'package:bums_n_tums/shared/theme/color_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/workout_section.dart';
import '../providers/workout_editor_provider.dart';
import '../widgets/execution/exercise_settings_modal.dart';

class WorkoutEditorScreen extends ConsumerStatefulWidget {
  final Workout? originalWorkout; // Null if creating a new workout
  final bool isTemplate;

  const WorkoutEditorScreen({
    Key? key,
    this.originalWorkout,
    this.isTemplate = false,
  }) : super(key: key);

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
      if (!_isNewWorkout) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(workoutEditorProvider.notifier)
              .updateActiveWorkout(widget.originalWorkout!);
        });
      }
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
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
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
                        decoration: const InputDecoration(
                          labelText: 'Difficulty',
                        ),
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

                      // Sections
                      const SizedBox(height: 24),
                      _buildSectionsArea(),

                      // Equipment section
                      const SizedBox(height: 24),
                      const Text(
                        'Equipment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                            onPressed: _addEquipment,
                          ),
                        ],
                      ),

                      // Tags section
                      const SizedBox(height: 24),
                      const Text(
                        'Tags',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                            onPressed: _addTag,
                          ),
                        ],
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
            final section = _sections[sectionIndex];
            return _buildSectionCard(section, sectionIndex);
          },
        ),
      ],
    );
  }

  Widget _buildSectionCard(WorkoutSection section, int sectionIndex) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _getSectionColor(section.type), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getSectionColor(section.type).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                // Section title and type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section name with inline edit
                      GestureDetector(
                        onTap: () => _editSectionName(section, sectionIndex),
                        child: Row(
                          children: [
                            Text(
                              section.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit, size: 16),
                          ],
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Section type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getSectionColor(section.type),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getSectionTypeName(section.type),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Section actions
                Row(
                  children: [
                    // Toggle section type
                    IconButton(
                      icon: Icon(
                        _getSectionTypeIcon(section.type),
                        color: _getSectionColor(section.type),
                      ),
                      tooltip: 'Change section type',
                      onPressed:
                          () => _toggleSectionType(section, sectionIndex),
                    ),

                    // Section settings
                    IconButton(
                      icon: const Icon(Icons.settings),
                      tooltip: 'Section settings',
                      onPressed:
                          () => _showSectionSettings(section, sectionIndex),
                    ),

                    // Delete section if not the only one
                    if (_sections.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Delete section',
                        onPressed: () => _deleteSection(sectionIndex),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Exercise list
          if (section.exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No exercises in this section yet',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppColors.mediumGrey,
                  ),
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: section.exercises.length,
              itemBuilder: (context, index) {
                final exercise = section.exercises[index];
                return ListTile(
                  key: ValueKey('${section.id}-${exercise.id}'),
                  leading:
                      exercise.imageUrl.startsWith('http')
                          ? Image.network(
                            exercise.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, e, s) =>
                                    const Icon(Icons.fitness_center),
                          )
                          : Image.asset(
                            exercise.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, e, s) =>
                                    const Icon(Icons.fitness_center),
                          ),
                  title: Text(exercise.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${exercise.sets} sets × ${exercise.reps} reps'),
                      if (exercise.weight != null)
                        Text(
                          'Weight: ${exercise.weight}kg',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings),
                        tooltip: 'Exercise Settings',
                        onPressed:
                            () => _showExerciseSettings(sectionIndex, index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Remove Exercise',
                        onPressed: () => _removeExercise(sectionIndex, index),
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
                  final item = section.exercises.removeAt(oldIndex);
                  section.exercises.insert(newIndex, item);

                  // Update the section
                  _sections[sectionIndex] = section;
                });
              },
            ),

          // Add exercise button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Exercise'),
                onPressed: () => _addExerciseToSection(sectionIndex),
              ),
            ),
          ),
        ],
      ),
    );
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

  void _editSectionName(WorkoutSection section, int sectionIndex) {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController(text: section.name);
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
                    _sections[sectionIndex] = section.copyWith(
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

  void _toggleSectionType(WorkoutSection section, int sectionIndex) {
    // Cycle through the section types
    SectionType newType;

    switch (section.type) {
      case SectionType.normal:
        newType = SectionType.circuit;
        break;
      case SectionType.circuit:
        newType = SectionType.superset;
        break;
      case SectionType.superset:
      newType = SectionType.normal;
        break;
    }

    setState(() {
      _sections[sectionIndex] = section.copyWith(type: newType);
    });
  }

  void _showSectionSettings(WorkoutSection section, int sectionIndex) {
    showDialog(
      context: context,
      builder: (context) {
        int restTime = section.restAfterSection;

        return AlertDialog(
          title: Text('${section.name} Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section type
              const Text(
                'Section Type:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButton<SectionType>(
                value: section.type,
                isExpanded: true,
                items:
                    SectionType.values.map((type) {
                      return DropdownMenuItem<SectionType>(
                        value: type,
                        child: Row(
                          children: [
                            Icon(
                              _getSectionTypeIcon(type),
                              color: _getSectionColor(type),
                            ),
                            const SizedBox(width: 8),
                            Text(_getSectionTypeName(type)),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (newType) {
                  if (newType != null) {
                    Navigator.pop(context);
                    setState(() {
                      _sections[sectionIndex] = section.copyWith(type: newType);
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Rest time after section
              const Text(
                'Rest After Section (seconds):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (restTime > 0) {
                        restTime -= 15;
                        if (restTime < 0) restTime = 0;
                      }
                    },
                  ),
                  Expanded(
                    child: Slider(
                      value: restTime.toDouble(),
                      min: 0,
                      max: 300,
                      divisions: 20,
                      label: '$restTime sec',
                      onChanged: (value) {
                        restTime = value.toInt();
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      restTime += 15;
                      if (restTime > 300) restTime = 300;
                    },
                  ),
                ],
              ),

              Text('$restTime seconds', textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _sections[sectionIndex] = section.copyWith(
                    restAfterSection: restTime,
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('Save Settings'),
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

  void _removeExercise(int sectionIndex, int exerciseIndex) {
    setState(() {
      final exercises = List<Exercise>.from(_sections[sectionIndex].exercises);
      exercises.removeAt(exerciseIndex);

      _sections[sectionIndex] = _sections[sectionIndex].copyWith(
        exercises: exercises,
      );
    });
  }

  void _showExerciseSettings(int sectionIndex, int exerciseIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: ExerciseSettingsModal(
            exercise: _sections[sectionIndex].exercises[exerciseIndex],
            onSave: (updatedExercise) {
              setState(() {
                final exercises = List<Exercise>.from(
                  _sections[sectionIndex].exercises,
                );
                exercises[exerciseIndex] = updatedExercise;

                _sections[sectionIndex] = _sections[sectionIndex].copyWith(
                  exercises: exercises,
                );
              });
            },
          ),
        );
      },
    );
  }

  Future<void> _addEquipment() async {
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

  Color _getSectionColor(SectionType type) {
    switch (type) {
      case SectionType.normal:
        return AppColors.popBlue;
      case SectionType.circuit:
        return AppColors.popGreen;
      case SectionType.superset:
        return AppColors.popCoral;
    }
  }

  String _getSectionTypeName(SectionType type) {
    switch (type) {
      case SectionType.normal:
        return 'Standard';
      case SectionType.circuit:
        return 'Circuit';
      case SectionType.superset:
        return 'Superset';
    }
  }

  IconData _getSectionTypeIcon(SectionType type) {
    switch (type) {
      case SectionType.normal:
        return Icons.list;
      case SectionType.circuit:
        return Icons.loop;
      case SectionType.superset:
        return Icons.swap_horiz;
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
