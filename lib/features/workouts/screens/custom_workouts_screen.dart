// lib/features/workouts/screens/custom_workouts_screen.dart
import 'package:bums_n_tums/features/ai/screens/ai_workout_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_templates_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout.dart';
import '../repositories/custom_workout_repository.dart';
import '../screens/workout_editor_screen.dart';
import '../screens/workout_detail_screen.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

final customWorkoutsStreamProvider = StreamProvider.autoDispose
    .family<List<Workout>, String>((ref, userId) {
      return FirebaseFirestore.instance
          .collection('user_custom_workouts')
          .doc(userId)
          .collection('workouts')
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => Workout.fromMap(doc.data()))
                    .toList(),
          );
    });

class CustomWorkoutsScreen extends ConsumerStatefulWidget {
  final String userId;

  const CustomWorkoutsScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  ConsumerState<CustomWorkoutsScreen> createState() =>
      _CustomWorkoutsScreenState();
}

class _CustomWorkoutsScreenState extends ConsumerState<CustomWorkoutsScreen> {
  final AnalyticsService _analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _analytics.logScreenView(screenName: 'custom_workouts');
  }

  @override
  Widget build(BuildContext context) {
    final workoutsAsync = ref.watch(
      customWorkoutsStreamProvider(widget.userId),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.pink,
        title: const Text(
          'My Custom Workouts',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Create workout button
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              _showWorkoutCreationOptions(context);
            },
          ),
        ],
      ),
      body: workoutsAsync.when(
        data: (workouts) {
          if (workouts.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildWorkoutsList(context, workouts);
        },
        loading:
            () => const LoadingIndicator(message: 'Loading your workouts...'),
        error: (error, stackTrace) => _buildErrorState(context, error, ref),
      ),
    );
  }

  void _showWorkoutCreationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Create Workout',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.create, color: AppColors.pink),
                  title: const Text('Create from Scratch'),
                  subtitle: const Text('Start with a blank workout'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WorkoutEditorScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.copy, color: AppColors.popBlue),
                  title: const Text('Use Template'),
                  subtitle: const Text(
                    'Start with one of your saved templates',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => const WorkoutTemplatesScreen(
                              selectionMode: true,
                            ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.psychology, color: AppColors.popGreen),
                  title: const Text('Create with AI'),
                  subtitle: const Text(
                    'Let AI generate a personalized workout',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AIWorkoutScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 64, color: AppColors.mediumGrey),
            const SizedBox(height: 16),
            Text(
              'You haven\'t created any custom workouts yet',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your own workout routines tailored to your preferences',
              style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create First Workout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.salmon,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkoutEditorScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Error loading workouts',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed:
                () => ref.refresh(customWorkoutsStreamProvider(widget.userId)),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutsList(BuildContext context, List<Workout> workouts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return Dismissible(
          key: Key(workout.id),
          background: Container(
            color: AppColors.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Delete Workout'),
                    content: Text(
                      'Are you sure you want to delete "${workout.title}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
            );
          },
          onDismissed: (direction) async {
            // Delete the workout
            final repository = CustomWorkoutRepository();
            await repository.deleteCustomWorkout(widget.userId, workout.id);

            // Show snackbar with undo option
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${workout.title} deleted'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () async {
                    // Re-add the workout
                    await repository.saveCustomWorkout(widget.userId, workout);
                  },
                ),
              ),
            );
          },
          child: _buildWorkoutCard(context, workout),
        );
      },
    );
  }

  Widget _buildWorkoutCard(BuildContext context, Workout workout) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with image and title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workout icon/image
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.fitness_center,
                      size: 32,
                      color: AppColors.pink,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Title and basic info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.title,
                        style: AppTextStyles.h3,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Workout stats
                      Row(
                        children: [
                          Icon(
                            Icons.timer,
                            size: 16,
                            color: AppColors.mediumGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${workout.durationMinutes} min',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.mediumGrey,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.fitness_center,
                            size: 16,
                            color: AppColors.mediumGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${workout.exercises.length} exercises',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.mediumGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Description
            if (workout.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                workout.description,
                style: AppTextStyles.small.copyWith(color: AppColors.darkGrey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // Action buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  onPressed: () => _navigateToWorkoutEditor(workout),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.popBlue,
                  ),
                ),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Start'),
                  onPressed: () => _navigateToWorkoutDetail(workout),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToWorkoutDetail(Workout workout) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailScreen(workoutId: workout.id),
      ),
    );
  }

  void _navigateToWorkoutEditor(Workout workout) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutEditorScreen(originalWorkout: workout),
      ),
    );
  }
}
