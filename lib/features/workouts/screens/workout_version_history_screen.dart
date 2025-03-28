// lib/features/workouts/screens/workout_version_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/workout.dart';
import '../repositories/custom_workout_repository.dart';
import 'workout_editor_screen.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/components/indicators/loading_indicator.dart';

class WorkoutVersionHistoryScreen extends ConsumerWidget {
  final String workoutId;
  final String userId;

  const WorkoutVersionHistoryScreen({
    Key? key,
    required this.workoutId,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Version History'),
      ),
      body: ref.watch(workoutVersionsStreamProvider((userId: userId, workoutId: workoutId))).when(
        data: (versions) {
          if (versions.isEmpty) {
            return const Center(
              child: Text('No version history available for this workout'),
            );
          }
          
          return ListView.builder(
            itemCount: versions.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final version = versions[index];
              return _buildVersionCard(context, version, index);
            },
          );
        },
        loading: () => const LoadingIndicator(message: 'Loading history...'),
        error: (error, stack) => Center(
          child: Text('Error loading history: $error'),
        ),
      ),
    );
  }
  
  Widget _buildVersionCard(BuildContext context, Workout version, int index) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final isFirst = index == 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isFirst ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isFirst 
          ? BorderSide(color: AppColors.salmon, width: 2) 
          : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Version header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isFirst 
                ? AppColors.salmon.withOpacity(0.1) 
                : AppColors.paleGrey,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Version badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isFirst ? AppColors.salmon : AppColors.mediumGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isFirst ? 'Current Version' : 'Version $index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Date
                Expanded(
                  child: Text(
                    dateFormat.format(version.createdAt),
                    style: TextStyle(
                      color: isFirst ? AppColors.darkGrey : AppColors.mediumGrey,
                    ),
                  ),
                ),
                
                // Action button
                if (!isFirst)
                  TextButton.icon(
                    icon: const Icon(Icons.restore),
                    label: const Text('Restore'),
                    onPressed: () => _restoreVersion(context, version),
                  ),
              ],
            ),
          ),
          
          // Version details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  version.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Version notes if available
                if (version.versionNotes.isNotEmpty) ...[
                  Text(
                    'Changes:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  
                  Container(
                    margin: const EdgeInsets.only(top: 4, bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.paleGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(version.versionNotes),
                  ),
                ],
                
                // Version stats
                Row(
                  children: [
                    _buildVersionStat(
                      'Exercises',
                      version.getAllExercises().length.toString(),
                      Icons.fitness_center,
                    ),
                    const SizedBox(width: 16),
                    _buildVersionStat(
                      'Duration',
                      '${version.durationMinutes} min',
                      Icons.timer,
                    ),
                    const SizedBox(width: 16),
                    _buildVersionStat(
                      'Difficulty',
                      _getDifficultyName(version.difficulty),
                      Icons.speed,
                    ),
                  ],
                ),
                
                // View button
                if (!isFirst)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.visibility),
                      label: const Text('View'),
                      onPressed: () => _viewVersion(context, version),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVersionStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.mediumGrey),
        const SizedBox(width: 4),
        Text('$value', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
  
  void _viewVersion(BuildContext context, Workout version) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutEditorScreen(
          originalWorkout: version,
        ),
      ),
    );
  }
  
  void _restoreVersion(BuildContext context, Workout version) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Version'),
        content: Text(
          'Are you sure you want to restore this version of "${version.title}"? '
          'This will create a new version based on this historical version.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createWorkoutFromVersion(context, version);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.salmon),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
  
  void _createWorkoutFromVersion(BuildContext context, Workout version) {
    // Generate a new ID for this restored version
    final newId = 'workout-${DateTime.now().millisecondsSinceEpoch}';
    
    // Create a new workout based on this version
    final restoredVersion = version.copyWith(
      id: newId,
      createdAt: DateTime.now(),
      previousVersionId: workoutId,
      versionNotes: 'Restored from previous version',
    );
    
    // Open the editor with this restored version
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutEditorScreen(
          originalWorkout: restoredVersion,
        ),
      ),
    );
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
}