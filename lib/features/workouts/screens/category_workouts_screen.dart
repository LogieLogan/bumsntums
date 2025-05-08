// Create a new file: lib/features/workouts/screens/category_workouts_screen.dart

import 'package:bums_n_tums/features/workouts/models/workout_category_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../widgets/workout_card.dart';
import 'workout_detail_screen.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/theme/app_text_styles.dart';

class CategoryWorkoutsScreen extends ConsumerStatefulWidget {
  final WorkoutCategory category;

  const CategoryWorkoutsScreen({super.key, required this.category});

  @override
  ConsumerState<CategoryWorkoutsScreen> createState() =>
      _CategoryWorkoutsScreenState();
}

class _CategoryWorkoutsScreenState
    extends ConsumerState<CategoryWorkoutsScreen> {
  final AnalyticsService _analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _analytics.logScreenView(
      screenName: 'category_workouts',
      screenClass: 'CategoryWorkoutsScreen',
    );
    _analytics.logEvent(
      name: 'view_category',
      parameters: {'category': widget.category.name},
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutsAsync = ref.watch(
      workoutsByCategoryProvider(widget.category),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.displayName, style: AppTextStyles.h2),
        backgroundColor: widget.category.displayColor,
      ),
      body: workoutsAsync.when(
        data: (workouts) {
          if (workouts.isEmpty) {
            return Center(
              child: Text(
                'No workouts available for this category',
                style: AppTextStyles.body,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index];
              return WorkoutCard(
                workout: workout,
                onTap: () => _navigateToWorkoutDetail(workout),
              );
            },
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error:
            (error, stack) =>
                Center(child: Text('Error loading workouts: $error')),
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

}
