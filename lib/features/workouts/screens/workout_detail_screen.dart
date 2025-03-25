// lib/features/workouts/screens/workout_detail_screen.dart
import 'package:bums_n_tums/features/workouts/repositories/custom_workout_repository.dart';
import 'package:bums_n_tums/features/workouts/screens/pre_workout_setup_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_editor_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_templates_screen.dart';
import 'package:bums_n_tums/shared/services/exercise_media_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../models/workout_section.dart';
import '../providers/workout_provider.dart';
import '../widgets/exercise_list_item.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkoutDetailScreen extends ConsumerStatefulWidget {
  final String workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutDetailScreen> createState() =>
      _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  final AnalyticsService _analytics = AnalyticsService();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _analytics.logScreenView(
      screenName: 'workout_detail',
      screenClass: 'WorkoutDetailScreen',
    );
    // Check if workout is favorited
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    // Get the current user ID
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return; // User is not authenticated, can't have favorites
    }

    final isFavorited = await ref
        .read(workoutServiceProvider)
        .isWorkoutFavorited(userId, widget.workoutId);

    if (mounted) {
      setState(() {
        _isFavorite = isFavorited;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutAsync = ref.watch(workoutDetailsProvider(widget.workoutId));

    return Scaffold(
      body: workoutAsync.when(
        data: (workout) {
          if (workout == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.lightGrey,
                  ),
                  const SizedBox(height: 16),
                  Text('Workout not found', style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }
          return _buildWorkoutDetail(workout);
        },
        loading: () => const Center(child: LoadingIndicator()),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Error loading workout', style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.mediumGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildWorkoutDetail(Workout workout) {
    return Stack(
      children: [
        // Scrollable content
        CustomScrollView(
          slivers: [
            // Workout image and basic info
            _buildWorkoutHeader(workout),

            // Action buttons - Customize, Save as Template
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Customize'),
                        onPressed: () => _customizeWorkout(workout),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save_alt),
                        label: const Text('Save as Template'),
                        onPressed: () => _saveAsTemplate(workout),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.popBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Workout description
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Description', style: AppTextStyles.h3),
                    const SizedBox(height: 8),
                    Text(workout.description, style: AppTextStyles.body),
                  ],
                ),
              ),
            ),

            // Equipment needed
            if (workout.equipment.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Equipment Needed', style: AppTextStyles.h3),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            workout.equipment.map((item) {
                              return Chip(
                                label: Text(item),
                                backgroundColor: AppColors.paleGrey,
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

            // Exercises list
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text('Exercises', style: AppTextStyles.h3),
              ),
            ),

            // If workout has sections, show them
            if (workout.sections.isNotEmpty)
              _buildSectionsList(workout)
            else
              // Otherwise show the flat exercise list
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final exercise = workout.exercises[index];
                  return ExerciseListItem(
                    exercise: exercise,
                    index: index,
                    onTap: () {
                      // TODO: Show exercise detail or preview
                    },
                  );
                }, childCount: workout.exercises.length),
              ),

            // Bottom space for the floating button
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),

        // App bar with back button and favorite
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? AppColors.salmon : Colors.white,
                      ),
                    ),
                    onPressed: () => _toggleFavorite(workout),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Fixed START WORKOUT button at the bottom
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: SafeArea(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PreWorkoutSetupScreen(workout: workout),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.salmon,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 3,
              ),
              child: const Text(
                'START WORKOUT',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionsList(Workout workout) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, sectionIndex) {
        final section = workout.sections[sectionIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Container(
              margin: const EdgeInsets.only(top: 16, bottom: 8),
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
            ...List.generate(
              section.exercises.length,
              (exerciseIndex) => ExerciseListItem(
                exercise: section.exercises[exerciseIndex],
                index: exerciseIndex,
                onTap: () {
                  // TODO: Show exercise detail or preview
                },
              ),
            ),
          ],
        );
      }, childCount: workout.sections.length),
    );
  }

  Widget _buildWorkoutHeader(Workout workout) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: ExerciseMediaService.workoutImage(
          difficulty: workout.difficulty,
          fit: BoxFit.cover,
        ),
        title: Text(
          workout.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        collapseMode: CollapseMode.pin,
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn(
                  Icons.timer,
                  '${workout.durationMinutes} min',
                  'Duration',
                ),
                _buildInfoColumn(
                  Icons.whatshot,
                  '${workout.estimatedCaloriesBurn}',
                  'Calories',
                ),
                _buildInfoColumn(
                  getDifficultyIcon(workout.difficulty),
                  getDifficultyText(workout.difficulty),
                  'Level',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.salmon),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  IconData getDifficultyIcon(WorkoutDifficulty difficulty) {
    switch (difficulty) {
      case WorkoutDifficulty.beginner:
        return Icons.sentiment_satisfied;
      case WorkoutDifficulty.intermediate:
        return Icons.sentiment_neutral;
      case WorkoutDifficulty.advanced:
        return Icons.sentiment_very_dissatisfied;
    }
  }

  String getDifficultyText(WorkoutDifficulty difficulty) {
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
      default:
        return AppColors.popBlue;
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
      default:
        return 'Standard';
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
      default:
        return Icons.list;
    }
  }

  void _toggleFavorite(Workout workout) async {
    // Get the current user ID
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      // Show error if user is not authenticated
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to save favorites'),
        ),
      );
      return;
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });

    try {
      if (_isFavorite) {
        await ref
            .read(workoutServiceProvider)
            .saveToFavorites(userId, workout.id);
      } else {
        await ref
            .read(workoutServiceProvider)
            .removeFromFavorites(userId, workout.id);
      }
    } catch (e) {
      // Revert state if operation fails
      setState(() {
        _isFavorite = !_isFavorite;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to ${_isFavorite ? 'add to' : 'remove from'} favorites: ${e.toString()}',
          ),
        ),
      );
    }
  }

  void _customizeWorkout(Workout workout) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutEditorScreen(originalWorkout: workout),
      ),
    ).then((customizedWorkout) {
      if (customizedWorkout != null) {
        // Handle refreshing the UI with the customized workout
        setState(() {
          // If you're using a provider, you'd refresh the provider state here
          ref.refresh(workoutDetailsProvider(workout.id));
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout customized successfully!')),
        );
      }
    });
  }

  Future<void> _saveAsTemplate(Workout workout) async {
    // First confirm with the user
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Save as Template'),
            content: Text(
              'Do you want to save "${workout.title}" as a template?\n\n'
              'This will allow you to create your own workouts based on this one.',
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

    if (confirm != true) return;

    // Prepare the workout as a template
    final templateWorkout = workout.copyWith(
      id: 'template-${DateTime.now().millisecondsSinceEpoch}',
      isTemplate: true,
      createdAt: DateTime.now(),
      createdBy: FirebaseAuth.instance.currentUser?.uid ?? 'user',
    );

    try {
      // Save to user_custom_workouts collection as a workaround
      // until the user_workout_templates security rules are updated
      final repository = CustomWorkoutRepository();
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to save templates'),
          ),
        );
        return;
      }

      // Use saveCustomWorkout instead of saveWorkoutTemplate
      // This will save it to user_custom_workouts collection which has proper permissions
      final customWorkout = templateWorkout.copyWith(isTemplate: true);
      final success = await repository.saveCustomWorkout(userId, customWorkout);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved as template successfully'),
            duration: Duration(seconds: 2),
          ),
        );

        // Optionally, ask if they want to view their custom workouts
        _showViewTemplatesDialog();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save template')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving template: ${e.toString()}')),
        );
      }
    }
  }

  void _showViewTemplatesDialog() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('View Templates'),
              content: const Text('Would you like to view your templates now?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Not Now'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    // Navigate to templates screen using MaterialPageRoute instead of named route
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WorkoutTemplatesScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.salmon,
                  ),
                  child: const Text('View Templates'),
                ),
              ],
            ),
      );
    });
  }
}
