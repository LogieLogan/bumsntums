// lib/features/workouts/screens/workout_browse_screen.dart
import 'package:bums_n_tums/features/workouts/screens/workout_detail_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../widgets/workout_card.dart';
import '../widgets/category_card.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/components/indicators/loading_indicator.dart';

class WorkoutBrowseScreen extends ConsumerStatefulWidget {
  const WorkoutBrowseScreen({super.key});

  @override
  ConsumerState<WorkoutBrowseScreen> createState() =>
      _WorkoutBrowseScreenState();
}

class _WorkoutBrowseScreenState extends ConsumerState<WorkoutBrowseScreen> {
  final AnalyticsService _analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _analytics.logScreenView(screenName: 'workout_browse');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WorkoutSearchScreen(),
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // TODO: Navigate to favorites screen
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh workout data
          ref.refresh(featuredWorkoutsProvider);
          ref.refresh(allWorkoutsProvider);
        },
        child: ListView(
          children: [
            // Categories section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Categories',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),

            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  CategoryCard(
                    category: WorkoutCategory.bums,
                    onTap:
                        () => _navigateToCategoryScreen(WorkoutCategory.bums),
                  ),
                  CategoryCard(
                    category: WorkoutCategory.tums,
                    onTap:
                        () => _navigateToCategoryScreen(WorkoutCategory.tums),
                  ),
                  CategoryCard(
                    category: WorkoutCategory.fullBody,
                    onTap:
                        () =>
                            _navigateToCategoryScreen(WorkoutCategory.fullBody),
                  ),
                  CategoryCard(
                    category: WorkoutCategory.cardio,
                    onTap:
                        () => _navigateToCategoryScreen(WorkoutCategory.cardio),
                  ),
                  CategoryCard(
                    category: WorkoutCategory.quickWorkout,
                    onTap:
                        () => _navigateToCategoryScreen(
                          WorkoutCategory.quickWorkout,
                        ),
                  ),
                ],
              ),
            ),

            // Featured workouts section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Featured Workouts',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to all featured workouts
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),

            _buildFeaturedWorkouts(),

            // Quick workouts section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Workouts',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      _navigateToCategoryScreen(WorkoutCategory.quickWorkout);
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),

            _buildQuickWorkouts(),

            // Beginner friendly section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Beginner Friendly',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to beginner workouts
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),

            _buildBeginnerWorkouts(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedWorkouts() {
    final featuredWorkoutsAsync = ref.watch(featuredWorkoutsProvider);

    return featuredWorkoutsAsync.when(
      data: (workouts) {
        if (workouts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('No featured workouts available.')),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: workouts.length > 3 ? 3 : workouts.length,
          itemBuilder: (context, index) {
            final workout = workouts[index];
            return WorkoutCard(
              workout: workout,
              onTap: () => _navigateToWorkoutDetail(workout),
            );
          },
        );
      },
      loading:
          () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: LoadingIndicator()),
          ),
      error:
          (error, stack) => Padding(
            padding: const EdgeInsets.all(16),
            child: Center(child: Text('Error loading workouts: $error')),
          ),
    );
  }

  Widget _buildQuickWorkouts() {
    final quickWorkoutsAsync = ref.watch(
      workoutsByCategoryProvider(WorkoutCategory.quickWorkout),
    );

    return quickWorkoutsAsync.when(
      data: (workouts) {
        if (workouts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('No quick workouts available.')),
          );
        }

        return SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index];
              return SizedBox(
                width: 280,
                child: WorkoutCard(
                  workout: workout,
                  onTap: () => _navigateToWorkoutDetail(workout),
                  isCompact: true,
                ),
              );
            },
          ),
        );
      },
      loading:
          () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: LoadingIndicator()),
          ),
      error:
          (error, stack) => Padding(
            padding: const EdgeInsets.all(16),
            child: Center(child: Text('Error loading workouts: $error')),
          ),
    );
  }

  Widget _buildBeginnerWorkouts() {
    final allWorkoutsAsync = ref.watch(allWorkoutsProvider);

    return allWorkoutsAsync.when(
      data: (workouts) {
        final beginnerWorkouts =
            workouts
                .where((w) => w.difficulty == WorkoutDifficulty.beginner)
                .toList();

        if (beginnerWorkouts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('No beginner workouts available.')),
          );
        }

        return SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount:
                beginnerWorkouts.length > 5 ? 5 : beginnerWorkouts.length,
            itemBuilder: (context, index) {
              final workout = beginnerWorkouts[index];
              return SizedBox(
                width: 280,
                child: WorkoutCard(
                  workout: workout,
                  onTap: () => _navigateToWorkoutDetail(workout),
                  isCompact: true,
                ),
              );
            },
          ),
        );
      },
      loading:
          () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: LoadingIndicator()),
          ),
      error:
          (error, stack) => Padding(
            padding: const EdgeInsets.all(16),
            child: Center(child: Text('Error loading workouts: $error')),
          ),
    );
  }

  void _navigateToWorkoutDetail(Workout workout) {
    _analytics.logEvent(
      name: 'workout_viewed',
      parameters: {'workout_id': workout.id, 'workout_name': workout.title},
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutDetailScreen(workoutId: workout.id),
      ),
    );
  }

  void _navigateToCategoryScreen(WorkoutCategory category) {
    _analytics.logEvent(
      name: 'category_viewed',
      parameters: {'category': category.name},
    );

    // TODO: Navigate to category screen
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => CategoryWorkoutsScreen(category: category),
    //   ),
    // );
  }
}
