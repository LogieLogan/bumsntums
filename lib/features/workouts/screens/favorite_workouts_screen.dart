// Create a new file: lib/features/workouts/screens/favorite_workouts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../widgets/workout_card.dart';
import 'workout_detail_screen.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';

class FavoriteWorkoutsScreen extends ConsumerStatefulWidget {
  const FavoriteWorkoutsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FavoriteWorkoutsScreen> createState() => _FavoriteWorkoutsScreenState();
}

class _FavoriteWorkoutsScreenState extends ConsumerState<FavoriteWorkoutsScreen> {
  final AnalyticsService _analytics = AnalyticsService();
  
  @override
  void initState() {
    super.initState();
    _analytics.logScreenView(
      screenName: 'favorite_workouts',
      screenClass: 'FavoriteWorkoutsScreen',
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favorite Workouts')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Please log in to view your favorites',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Navigate to login screen
                  Navigator.pop(context);
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    
    final favoritesAsync = ref.watch(userFavoriteWorkoutsProvider(currentUser.uid));
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorite Workouts', style: AppTextStyles.h2),
        backgroundColor: AppColors.pink,
      ),
      body: favoritesAsync.when(
        data: (workouts) {
          if (workouts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'You haven\'t added any favorites yet',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the heart icon on any workout to add it here',
                    style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey),
                    textAlign: TextAlign.center,
                  ),
                ],
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Error loading favorites',
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
                onPressed: () => ref.refresh(userFavoriteWorkoutsProvider(currentUser.uid)),
                child: const Text('Try Again'),
              ),
            ],
          ),
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