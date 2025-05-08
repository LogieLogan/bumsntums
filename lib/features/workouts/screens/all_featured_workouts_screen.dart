// Create a new file: lib/features/workouts/screens/all_featured_workouts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../widgets/workout_card.dart';
import 'workout_detail_screen.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';

class AllFeaturedWorkoutsScreen extends ConsumerStatefulWidget {
  const AllFeaturedWorkoutsScreen({super.key});

  @override
  ConsumerState<AllFeaturedWorkoutsScreen> createState() => _AllFeaturedWorkoutsScreenState();
}

class _AllFeaturedWorkoutsScreenState extends ConsumerState<AllFeaturedWorkoutsScreen> {
  final AnalyticsService _analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _analytics.logScreenView(
      screenName: 'all_featured_workouts',
      screenClass: 'AllFeaturedWorkoutsScreen',
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutsAsync = ref.watch(featuredWorkoutsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Featured Workouts', style: AppTextStyles.h2),
        backgroundColor: AppColors.pink,
      ),
      body: workoutsAsync.when(
        data: (workouts) {
          if (workouts.isEmpty) {
            return Center(
              child: Text(
                'No featured workouts available',
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
}