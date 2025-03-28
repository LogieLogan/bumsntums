// lib/features/workouts/screens/workout_templates_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout.dart';
import '../providers/workout_editor_provider.dart';
import '../repositories/custom_workout_repository.dart';
import 'workout_editor_screen.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/components/indicators/loading_indicator.dart';

class WorkoutTemplatesScreen extends ConsumerWidget {
  final bool selectionMode;

  const WorkoutTemplatesScreen({Key? key, this.selectionMode = false})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout Templates')),
        body: const Center(
          child: Text('You must be logged in to view templates'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Templates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _createNewTemplate(context),
          ),
        ],
      ),
      body: ref
          .watch(workoutTemplatesStreamProvider(userId))
          .when(
            data: (templates) {
              if (templates.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView.builder(
                itemCount: templates.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return _buildTemplateCard(context, template, ref);
                },
              );
            },
            loading:
                () => const LoadingIndicator(message: 'Loading templates...'),
            error:
                (error, stack) =>
                    Center(child: Text('Error loading templates: $error')),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewTemplate(context),
        child: const Icon(Icons.add),
        tooltip: 'Create New Template',
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 64, color: AppColors.lightGrey),
          const SizedBox(height: 16),
          Text(
            'No workout templates yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first template to save your favorite workouts!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _createNewTemplate(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Template'),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    Workout template,
    WidgetRef ref,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Template header with image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Stack(
              children: [
                // Template image or placeholder
                Image.asset(
                  template.imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      width: double.infinity,
                      color: AppColors.paleGrey,
                      child: Icon(
                        Icons.fitness_center,
                        size: 48,
                        color: AppColors.salmon,
                      ),
                    );
                  },
                ),

                // Template category badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(template.category),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getCategoryName(template.category),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Template details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        template.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
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
                        '${template.durationMinutes} min',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.popBlue,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Template description
                Text(
                  template.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // Exercise count and difficulty
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 16,
                      color: AppColors.mediumGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${template.getAllExercises().length} exercises',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.speed, size: 16, color: AppColors.mediumGrey),
                    const SizedBox(width: 4),
                    Text(
                      _getDifficultyName(template.difficulty),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Usage stats
                Row(
                  children: [
                    Icon(Icons.history, size: 16, color: AppColors.mediumGrey),
                    const SizedBox(width: 4),
                    Text(
                      template.timesUsed > 0
                          ? 'Used ${template.timesUsed} times'
                          : 'Never used',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (template.lastUsed != null) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.mediumGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Last used: ${_formatDate(template.lastUsed!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (selectionMode)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Select Template'),
                        onPressed:
                            () => _selectTemplate(context, template, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.salmon,
                        ),
                      )
                    else ...[
                      // Original buttons for edit and use template
                      TextButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        onPressed: () => _editTemplate(context, template),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Use Template'),
                        onPressed: () => _useTemplate(context, template, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.salmon,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectTemplate(
    BuildContext context,
    Workout template,
    WidgetRef ref,
  ) async {
    final editorNotifier = ref.read(workoutEditorProvider.notifier);
    final newWorkout = await editorNotifier.createFromTemplate(template);

    if (newWorkout != null && context.mounted) {
      Navigator.pop(context); // Close template selection screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => WorkoutEditorScreen(originalWorkout: newWorkout),
        ),
      );
    }
  }

  void _createNewTemplate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutEditorScreen(isTemplate: true),
      ),
    );
  }

  void _editTemplate(BuildContext context, Workout template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => WorkoutEditorScreen(
              originalWorkout: template,
              isTemplate: true,
            ),
      ),
    );
  }

  Future<void> _useTemplate(
    BuildContext context,
    Workout template,
    WidgetRef ref,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Use Template'),
            content: Text('Create a new workout based on "${template.title}"?'),
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
                child: const Text('Create Workout'),
              ),
            ],
          ),
    );

    if (result == true) {
      final editorNotifier = ref.read(workoutEditorProvider.notifier);
      final newWorkout = await editorNotifier.createFromTemplate(template);

      if (newWorkout != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => WorkoutEditorScreen(originalWorkout: newWorkout),
          ),
        );
      }
    }
  }

  Color _getCategoryColor(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.bums:
        return AppColors.salmon;
      case WorkoutCategory.tums:
        return AppColors.popCoral;
      case WorkoutCategory.fullBody:
        return AppColors.popBlue;
      case WorkoutCategory.cardio:
        return AppColors.popGreen;
      case WorkoutCategory.quickWorkout:
        return AppColors.popTurquoise;
    }
  }

  String _getCategoryName(WorkoutCategory category) {
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
        return 'Quick';
    }
  }

  String _getDifficultyName(WorkoutDifficulty difficulty) {
    switch (difficulty) {
      case WorkoutDifficulty.beginner:
        return 'Beginner';
      case WorkoutDifficulty.intermediate:
        return 'Intermediate';
      case WorkoutDifficulty.advanced:
        return 'Advanced';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }
}
