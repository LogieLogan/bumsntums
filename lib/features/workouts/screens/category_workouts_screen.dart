// Create a new file: lib/features/workouts/screens/category_workouts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../widgets/workout_card.dart';
import 'workout_detail_screen.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';

class CategoryWorkoutsScreen extends ConsumerStatefulWidget {
  final WorkoutCategory category;

  const CategoryWorkoutsScreen({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  ConsumerState<CategoryWorkoutsScreen> createState() => _CategoryWorkoutsScreenState();
}

class _CategoryWorkoutsScreenState extends ConsumerState<CategoryWorkoutsScreen> {
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
    final workoutsAsync = ref.watch(workoutsByCategoryProvider(widget.category));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getCategoryTitle(widget.category),
          style: AppTextStyles.h2,
        ),
        backgroundColor: _getCategoryColor(widget.category),
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
        error: (error, stack) => Center(
          child: Text('Error loading workouts: $error'),
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

  String _getCategoryTitle(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.bums:
        return 'Bums Workouts';
      case WorkoutCategory.tums:
        return 'Tums Workouts';
      case WorkoutCategory.fullBody:
        return 'Full Body Workouts';
      case WorkoutCategory.cardio:
        return 'Cardio Workouts';
      case WorkoutCategory.quickWorkout:
        return 'Quick Workouts';
    }
  }

  Color _getCategoryColor(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.bums:
        return AppColors.salmon;
      case WorkoutCategory.tums:
        return AppColors.popTurquoise;
      case WorkoutCategory.fullBody:
        return AppColors.popBlue;
      case WorkoutCategory.cardio:
        return AppColors.popCoral;
      case WorkoutCategory.quickWorkout:
        return AppColors.popYellow;
    }
  }
}