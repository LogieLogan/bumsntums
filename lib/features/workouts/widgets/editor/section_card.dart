// lib/features/workouts/widgets/editor/section_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workout_section.dart';
import '../../models/exercise.dart';
import '../../providers/workout_editor_provider.dart';
import '../execution/exercise_settings_modal.dart';
import '../../../../shared/theme/app_colors.dart';

class SectionCard extends ConsumerWidget {
  final WorkoutSection section;
  final int sectionIndex;
  final Function(int sectionIndex) onAddExercise;
  final Function(int sectionIndex, String name) onEditSectionName;
  final Function(int sectionIndex) onDeleteSection;
  final Function(int sectionIndex, int oldIndex, int newIndex)
  onReorderExercises;
  final Function(int sectionIndex, Exercise exercise, int index)
  onUpdateExercise;

  const SectionCard({
    super.key,
    required this.section,
    required this.sectionIndex,
    required this.onAddExercise,
    required this.onEditSectionName,
    required this.onDeleteSection,
    required this.onReorderExercises,
    required this.onUpdateExercise,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          _buildSectionHeader(context, ref),

          // Exercise list
          _buildExerciseList(context, ref),

          // Add exercise button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Exercise'),
                onPressed: () => onAddExercise(sectionIndex),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, WidgetRef ref) {
    return Container(
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
                  onTap: () => onEditSectionName(sectionIndex, section.name),
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
                onPressed: () {
                  final editorNotifier = ref.read(
                    workoutEditorProvider.notifier,
                  );
                  final updatedSection = _getNextSectionType(section);
                  editorNotifier.updateSection(updatedSection);
                },
              ),

              // Section settings
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Section settings',
                onPressed: () => _showSectionSettings(context, ref),
              ),

              // Delete section if not the only one
              if ((ref
                          .read(workoutEditorProvider)
                          .activeWorkout
                          ?.sections
                          .length ??
                      0) >
                  1)
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete section',
                  onPressed: () => onDeleteSection(sectionIndex),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(BuildContext context, WidgetRef ref) {
    if (section.exercises.isEmpty) {
      return Padding(
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
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: section.exercises.length,
      itemBuilder: (context, index) {
        final exercise = section.exercises[index];
        return ExerciseListItem(
          key: ValueKey('${section.id}-${exercise.id}'),
          exercise: exercise,
          onEdit: () => _showExerciseSettings(context, ref, index),
          onDelete: () {
            final editorNotifier = ref.read(workoutEditorProvider.notifier);
            final updatedExercises = List<Exercise>.from(section.exercises);
            updatedExercises.removeAt(index);
            final updatedSection = section.copyWith(
              exercises: updatedExercises,
            );
            editorNotifier.updateSection(updatedSection);
          },
        );
      },
      onReorder: (oldIndex, newIndex) {
        onReorderExercises(sectionIndex, oldIndex, newIndex);
      },
    );
  }

  void _showSectionSettings(BuildContext context, WidgetRef ref) {
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
                    final editorNotifier = ref.read(
                      workoutEditorProvider.notifier,
                    );
                    final updatedSection = section.copyWith(type: newType);
                    editorNotifier.updateSection(updatedSection);
                  }
                },
              ),

              const SizedBox(height: 16),

              // Rest time after section
              const Text(
                'Rest After Section (seconds):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                if (restTime > 0) {
                                  restTime -= 15;
                                  if (restTime < 0) restTime = 0;
                                }
                              });
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
                                setState(() {
                                  restTime = value.toInt();
                                });
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                restTime += 15;
                                if (restTime > 300) restTime = 300;
                              });
                            },
                          ),
                        ],
                      ),
                      Text('$restTime seconds', textAlign: TextAlign.center),
                    ],
                  );
                },
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
                final editorNotifier = ref.read(workoutEditorProvider.notifier);
                final updatedSection = section.copyWith(
                  restAfterSection: restTime,
                );
                editorNotifier.updateSection(updatedSection);
                Navigator.pop(context);
              },
              child: const Text('Save Settings'),
            ),
          ],
        );
      },
    );
  }

  void _showExerciseSettings(
    BuildContext context,
    WidgetRef ref,
    int exerciseIndex,
  ) {
    final exercise = section.exercises[exerciseIndex];

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
            exercise: exercise,
            onSave: (updatedExercise) {
              onUpdateExercise(sectionIndex, updatedExercise, exerciseIndex);
            },
          ),
        );
      },
    );
  }

  WorkoutSection _getNextSectionType(WorkoutSection currentSection) {
    SectionType newType;

    switch (currentSection.type) {
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

    return currentSection.copyWith(type: newType);
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
}

// A separate widget for exercise list items
class ExerciseListItem extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExerciseListItem({
    super.key,
    required this.exercise,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
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
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Remove Exercise',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
