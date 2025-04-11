// lib/features/workouts/screens/workout_browse_screen.dart
import 'package:bums_n_tums/features/ai_workout_creation/screens/ai_workout_screen.dart';
import 'package:bums_n_tums/features/auth/providers/auth_provider.dart';
import 'package:bums_n_tums/features/workouts/screens/all_featured_workouts_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/beginner_workouts_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/category_workouts_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/custom_workouts_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/favorite_workouts_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_detail_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_editor_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_search_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_templates_screen.dart';
import 'package:bums_n_tums/shared/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../widgets/workout_card.dart';
import '../widgets/category_card.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import 'package:go_router/go_router.dart';

class WorkoutBrowseScreen extends ConsumerStatefulWidget {
  const WorkoutBrowseScreen({super.key});

  @override
  ConsumerState<WorkoutBrowseScreen> createState() =>
      _WorkoutBrowseScreenState();
}

class _WorkoutBrowseScreenState extends ConsumerState<WorkoutBrowseScreen> {
  final AnalyticsService _analytics = AnalyticsService();
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _analytics.logScreenView(screenName: 'workout_browse');

    // Check if we're in selection mode from arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['selectionMode'] == true) {
        setState(() {
          _isSelectionMode = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showWorkoutCreationOptions(context),
            ),
            const Text('Workouts'),
          ],
        ),
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
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please log in to view your favorites'),
                  ),
                );
                return;
              }

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FavoriteWorkoutsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh workout data
          final _ =  ref.refresh(featuredWorkoutsProvider);
          final _ =  ref.refresh(allWorkoutsProvider);
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const AllFeaturedWorkoutsScreen(),
                        ),
                      );
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BeginnerWorkoutsScreen(),
                        ),
                      );
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),

            _buildBeginnerWorkouts(),

            const SizedBox(height: 24),

            _buildMyWorkoutsSection(),

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
    if (_isSelectionMode) {
      // If in selection mode, return the workout to the calling screen
      Navigator.of(context).pop(workout);
      return;
    }

    // Normal flow
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

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryWorkoutsScreen(category: category),
      ),
    );
  }

  Widget _buildMyWorkoutsSection() {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.uid;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Custom Workouts',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  if (userId != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (context) => CustomWorkoutsScreen(userId: userId),
                      ),
                    );
                  }
                },
                child: const Text('See All'),
              ),
            ],
          ),
          if (userId != null)
            _buildCustomWorkoutsList(userId)
          else
            _buildCreateWorkoutCard(),
        ],
      ),
    );
  }

  Widget _buildCustomWorkoutsList(String userId) {
    return Consumer(
      builder: (context, ref, child) {
        final workoutsAsync = ref.watch(customWorkoutsStreamProvider(userId));

        return workoutsAsync.when(
          data: (workouts) {
            if (workouts.isEmpty) {
              return _buildCreateWorkoutCard();
            }

            return Column(
              children: [
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: workouts.length > 3 ? 3 : workouts.length,
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
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.fitness_center,
                      color: AppColors.salmon,
                    ),
                    title: const Text('Exercise Library'),
                    subtitle: const Text(
                      'Browse all exercises with form tips and videos',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      context.push('/exercise-library');
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildCreateWorkoutCard(),
        );
      },
    );
  }

  Widget _buildCreateWorkoutCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.deepPurple,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Create Your Custom Workout",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Design workouts tailored to your preferences",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => _showWorkoutCreationOptions(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add, size: 18),
                SizedBox(width: 8),
                Text("Create New Workout"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Add this method to the _WorkoutBrowseScreenState class
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
}
