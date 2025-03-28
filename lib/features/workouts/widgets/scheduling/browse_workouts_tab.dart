// lib/features/workouts/widgets/scheduling/browse_workouts_tab.dart
import 'package:bums_n_tums/features/workouts/models/workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/workout_provider.dart';
import 'selectable_workout_card.dart';
import '../../../../shared/theme/text_styles.dart';
import '../../../../shared/theme/color_palette.dart';
import '../../../../shared/components/indicators/loading_indicator.dart';
import '../../screens/workout_browse_screen.dart';

class BrowseWorkoutsTab extends ConsumerWidget {
  const BrowseWorkoutsTab({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Featured workouts section
    final featuredWorkoutsAsync = ref.watch(featuredWorkoutsProvider);
    
    // Use SingleChildScrollView to prevent overflow
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Featured Workouts', style: AppTextStyles.h3),
          ),

          featuredWorkoutsAsync.when(
            data: (workouts) {
              if (workouts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('No featured workouts available.')),
                );
              }

              return ListView.builder(
                shrinkWrap: true, // Important
                physics: const NeverScrollableScrollPhysics(), // Disable scrolling on this ListView
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  return SelectableWorkoutCard(workout: workouts[index]);
                },
              );
            },
            loading: () => const Center(child: LoadingIndicator()),
            error: (error, stack) => Center(child: Text('Error loading workouts: $error')),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Quick Workouts', style: AppTextStyles.h3),
          ),

          // Quick workouts section
          SizedBox(
            height: 160,
            child: ref.watch(workoutsByCategoryProvider(WorkoutCategory.quickWorkout)).when(
              data: (workouts) {
                if (workouts.isEmpty) {
                  return const Center(
                    child: Text('No quick workouts available.'),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 280,
                      child: SelectableWorkoutCard(
                        workout: workouts[index],
                        isCompact: true,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stack) => Center(child: Text('Error loading workouts: $error')),
            ),
          ),

          const SizedBox(height: 24),

          // Browse all categories button
          Center(
            child: OutlinedButton.icon(
              onPressed: () => _browseAllWorkouts(context),
              icon: const Icon(Icons.search),
              label: const Text('Browse All Categories'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.pink,
                side: const BorderSide(color: AppColors.pink),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  void _browseAllWorkouts(BuildContext context) async {
    // Flag to indicate we're in selection mode
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WorkoutBrowseScreen(),
        // Pass arguments to indicate selection mode
        settings: const RouteSettings(arguments: {'selectionMode': true}),
      ),
    );
  }
}