// lib/features/workouts/screens/workout_detail_screen.dart
import 'package:bums_n_tums/features/workouts/screens/pre_workout_setup_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_editor_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_execution_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../providers/workout_execution_provider.dart';
import '../widgets/exercise_list_item.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/components/buttons/primary_button.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/theme/color_palette.dart';
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
            return const Center(child: Text('Workout not found'));
          }

          ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Customize'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => WorkoutEditorScreen(
                        originalWorkout: workout, // Pass the current workout
                      ),
                ),
              ).then((customizedWorkout) {
                if (customizedWorkout != null) {
                  // Handle refreshing the UI with the customized workout
                  setState(() {
                    // If you're using a provider, you'd refresh the provider state here
                    // For example: ref.refresh(specificWorkoutProvider(workout.id));
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Workout customized successfully!'),
                    ),
                  );
                }
              });
            },
          );
          return _buildWorkoutDetail(workout);
        },
        loading: () => const Center(child: LoadingIndicator()),
        error:
            (error, stack) =>
                Center(child: Text('Error loading workout: $error')),
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

            // Workout description
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      workout.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
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
                      Text(
                        'Equipment Needed',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exercises',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Exercise list items
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
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 4,
              right: 4,
            ),
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

  Widget _buildWorkoutHeader(Workout workout) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Image.asset(
          workout.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.salmon.withOpacity(0.3),
              child: const Center(
                child: Icon(
                  Icons.fitness_center,
                  color: AppColors.salmon,
                  size: 64,
                ),
              ),
            );
          },
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

  void _startWorkout(Workout workout) async {
    // Log analytics event
    _analytics.logWorkoutStarted(
      workoutId: workout.id,
      workoutName: workout.title,
    );

    // Get the latest version of the workout (to include any modifications)
    Workout? latestWorkout = await ref
        .read(workoutServiceProvider)
        .getWorkoutById(workout.id);

    // Use the latest workout if available, otherwise use the provided one
    final workoutToStart = latestWorkout ?? workout;

    // Start workout execution using the provider
    ref.read(workoutExecutionProvider.notifier).startWorkout(workoutToStart);

    // Navigate to workout execution screen
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const WorkoutExecutionScreen()),
    );
  }
}
