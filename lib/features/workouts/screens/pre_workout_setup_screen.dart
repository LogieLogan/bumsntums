// lib/features/workouts/screens/pre_workout_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/workout_section.dart';
import '../providers/workout_execution_provider.dart';
import '../widgets/execution/exercise_settings_modal.dart';
import '../screens/workout_execution_screen.dart';
import '../../../shared/theme/app_colors.dart';

class PreWorkoutSetupScreen extends ConsumerStatefulWidget {
  final Workout workout;
  // Add optional origin identifiers
  final String? originPlanId;
  final String? originScheduledWorkoutId;

  const PreWorkoutSetupScreen({
    Key? key,
    required this.workout,
    this.originPlanId, // Make optional
    this.originScheduledWorkoutId, // Make optional
  }) : super(key: key);

  @override
  ConsumerState<PreWorkoutSetupScreen> createState() =>
      _PreWorkoutSetupScreenState();
}

class _PreWorkoutSetupScreenState extends ConsumerState<PreWorkoutSetupScreen> {
  late Workout _workout;
  bool _voiceGuidanceEnabled = true;
  bool _showRestTimers = true;
  bool _showCountdowns = true;

  @override
  void initState() {
    super.initState();
    _workout = widget.workout;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Setup'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('START'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: _startWorkout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workout header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _workout.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_workout.description),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildWorkoutStat(
                          'Duration',
                          '${_workout.durationMinutes} min',
                          Icons.timer,
                        ),
                        _buildWorkoutStat(
                          'Exercises',
                          _workout.getAllExercises().length.toString(),
                          Icons.fitness_center,
                        ),
                        _buildWorkoutStat(
                          'Difficulty',
                          _difficultyToString(_workout.difficulty),
                          Icons.speed,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Workout settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Workout Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SwitchListTile(
                      title: const Text('Voice Guidance'),
                      subtitle: const Text('Audio cues and instructions'),
                      value: _voiceGuidanceEnabled,
                      onChanged: (value) {
                        setState(() {
                          _voiceGuidanceEnabled = value;
                        });
                      },
                    ),

                    SwitchListTile(
                      title: const Text('Rest Timers'),
                      subtitle: const Text('Countdown between exercises'),
                      value: _showRestTimers,
                      onChanged: (value) {
                        setState(() {
                          _showRestTimers = value;
                        });
                      },
                    ),

                    SwitchListTile(
                      title: const Text('Exercise Countdowns'),
                      subtitle: const Text('Countdown for timed exercises'),
                      value: _showCountdowns,
                      onChanged: (value) {
                        setState(() {
                          _showCountdowns = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Exercise list
            const Text(
              'Exercise Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            _buildExerciseList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.salmon),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(color: AppColors.mediumGrey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildExerciseList() {
    if (_workout.sections.isEmpty) {
      // For backward compatibility - handle workouts without sections
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _workout.exercises.length,
        itemBuilder: (context, index) {
          return _buildExerciseItem(
            _workout.exercises[index],
            index,
            sectionIndex: null,
          );
        },
      );
    }

    // Build sectioned exercise list
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _workout.sections.length,
      itemBuilder: (context, sectionIndex) {
        final section = _workout.sections[sectionIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Container(
              margin: const EdgeInsets.only(bottom: 8, top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getSectionColor(section.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getSectionColor(section.type),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getSectionTypeIcon(section.type),
                    color: _getSectionColor(section.type),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    section.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getSectionColor(section.type),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getSectionTypeName(section.type),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getSectionColor(section.type),
                    ),
                  ),
                ],
              ),
            ),

            // Section exercises
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: section.exercises.length,
              itemBuilder: (context, exerciseIndex) {
                return _buildExerciseItem(
                  section.exercises[exerciseIndex],
                  exerciseIndex,
                  sectionIndex: sectionIndex,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildExerciseItem(
    Exercise exercise,
    int exerciseIndex, {
    int? sectionIndex,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.salmon.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              Icons.fitness_center,
              color: AppColors.salmon,
              size: 24,
            ),
          ),
        ),
        title: Text(exercise.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.durationSeconds != null
                  ? '${exercise.sets} sets × ${exercise.durationSeconds}s'
                  : '${exercise.sets} sets × ${exercise.reps} reps',
            ),
            if (exercise.weight != null)
              Text(
                'Weight: ${exercise.weight}kg',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Exercise Settings',
          onPressed:
              () =>
                  _showExerciseSettings(exercise, exerciseIndex, sectionIndex),
        ),
        onTap:
            () => _showExerciseSettings(exercise, exerciseIndex, sectionIndex),
      ),
    );
  }

  void _showExerciseSettings(
    Exercise exercise,
    int exerciseIndex,
    int? sectionIndex,
  ) {
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
              setState(() {
                if (sectionIndex != null) {
                  // Update in sections
                  final sections = List<WorkoutSection>.from(_workout.sections);
                  final exercises = List<Exercise>.from(
                    sections[sectionIndex].exercises,
                  );
                  exercises[exerciseIndex] = updatedExercise;

                  sections[sectionIndex] = sections[sectionIndex].copyWith(
                    exercises: exercises,
                  );

                  _workout = _workout.copyWith(sections: sections);
                } else {
                  // Update in legacy exercises list
                  final exercises = List<Exercise>.from(_workout.exercises);
                  exercises[exerciseIndex] = updatedExercise;
                  _workout = _workout.copyWith(exercises: exercises);
                }
              });
            },
          ),
        );
      },
    );
  }

  void _startWorkout() {
    // Initialize the workout execution provider
    ref
        .read(workoutExecutionProvider.notifier)
        .startWorkout(
          _workout, // Use potentially modified workout state
          voiceGuidanceEnabled: _voiceGuidanceEnabled,
          showRestTimers: _showRestTimers,
          showCountdowns: _showCountdowns,
        );

    // Navigate to the execution screen, passing the origin IDs
    Navigator.pushReplacement(
      // Use pushReplacement if setup screen shouldn't be in back stack
      context,
      MaterialPageRoute(
        builder:
            (context) => WorkoutExecutionScreen(
              // Pass the origin IDs along
              originPlanId: widget.originPlanId,
              originScheduledWorkoutId: widget.originScheduledWorkoutId,
            ),
      ),
    );
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
}
