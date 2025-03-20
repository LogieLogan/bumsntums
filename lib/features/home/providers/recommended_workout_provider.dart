// lib/features/home/providers/recommended_workout_provider.dart
import 'package:bums_n_tums/features/workouts/models/exercise.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/workouts/models/workout.dart';
import '../../../features/auth/models/user_profile.dart';

/// Service for fetching and managing recommended workouts
class RecommendedWorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch a recommended workout for a user based on their profile
  Future<Workout?> getRecommendedWorkout(UserProfile profile) async {
    try {
      // In a real implementation, this would fetch a workout recommendation based on:
      // 1. User's profile (fitness level, goals, focus areas)
      // 2. User's workout history (what they haven't done recently)
      // 3. User's available time
      // 4. User's preferred workout types

      // For now, we'll just fetch a random workout that matches their fitness level
      final QuerySnapshot snapshot =
          await _firestore
              .collection('workouts')
              .where(
                'difficulty',
                isEqualTo: profile.fitnessLevel.toString().split('.').last,
              )
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        // If no workout matches their level, fetch any workout
        final fallbackSnapshot =
            await _firestore.collection('workouts').limit(1).get();

        if (fallbackSnapshot.docs.isEmpty) {
          return null;
        }

        return _workoutFromDoc(fallbackSnapshot.docs.first);
      }

      return _workoutFromDoc(snapshot.docs.first);
    } catch (e) {
      print('Error fetching recommended workout: $e');
      return null;
    }
  }

  /// Helper method to convert a Firestore document to a Workout
  Workout _workoutFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convert workout difficulty string to enum
    final difficultyString = data['difficulty'] as String? ?? 'beginner';
    final difficulty = WorkoutDifficulty.values.firstWhere(
      (d) => d.toString().split('.').last == difficultyString,
      orElse: () => WorkoutDifficulty.beginner,
    );

    // Convert workout category string to enum
    final categoryString = data['category'] as String? ?? 'fullBody';
    final category = WorkoutCategory.values.firstWhere(
      (c) => c.toString().split('.').last == categoryString,
      orElse: () => WorkoutCategory.fullBody,
    );

    // Parse exercises - in real implementation this would be more robust
    final List<dynamic> exerciseData = data['exercises'] ?? [];
    final exercises =
        exerciseData.map((e) {
          final exercise = e as Map<String, dynamic>;
          return Exercise(
            id: exercise['id'] ?? '',
            name: exercise['name'] ?? '',
            description: exercise['description'] ?? '',
            imageUrl: exercise['imageUrl'] ?? '',
            sets: exercise['sets'] ?? 3,
            reps: exercise['reps'] ?? 10,
            durationSeconds: exercise['durationSeconds'],
            restBetweenSeconds: exercise['restBetweenSeconds'] ?? 30,
            targetArea: exercise['targetArea'] ?? 'Full Body',
            modifications: [],
          );
        }).toList();

    return Workout(
      id: doc.id,
      title: data['title'] ?? 'Workout',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: category,
      difficulty: difficulty,
      durationMinutes: data['durationMinutes'] ?? 20,
      estimatedCaloriesBurn: data['estimatedCaloriesBurn'] ?? 100,
      featured: data['featured'] ?? false,
      isAiGenerated: data['isAiGenerated'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? 'system',
      exercises: exercises,
      equipment: List<String>.from(data['equipment'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  /// Get a recommended workout for today when there's no data yet
  Workout getFallbackWorkout() {
    // Create a simple fallback workout when no recommendations are available
    return Workout(
      id: 'quick-total-body-blast',
      title: 'Quick Total Body Blast',
      description: 'A full body workout perfect for beginners.',
      imageUrl: 'assets/images/workouts/full_body.jpg',
      category: WorkoutCategory.fullBody,
      difficulty: WorkoutDifficulty.beginner,
      durationMinutes: 15,
      estimatedCaloriesBurn: 85,
      featured: true,
      isAiGenerated: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
      exercises: [
        Exercise(
          id: 'jumping-jacks',
          name: 'Jumping Jacks',
          description:
              'Start with your feet together and arms at your sides, then jump to a position with legs spread and arms raised overhead, then back to starting position.',
          imageUrl: 'assets/images/exercises/jumping_jacks.jpg',
          sets: 1,
          reps: 0,
          durationSeconds: 60,
          restBetweenSeconds: 30,
          targetArea: 'Full Body',
          modifications: [],
        ),
        Exercise(
          id: 'bodyweight-squats',
          name: 'Bodyweight Squats',
          description:
              'Stand with feet shoulder-width apart, lower your body by bending your knees while keeping your back straight, then return to standing position.',
          imageUrl: 'assets/images/exercises/squats.jpg',
          sets: 3,
          reps: 10,
          restBetweenSeconds: 30,
          targetArea: 'Legs',
          modifications: [],
        ),
        Exercise(
          id: 'push-ups',
          name: 'Push-ups',
          description:
              'Start in plank position with hands slightly wider than shoulders, lower your body by bending your elbows, then push back up.',
          imageUrl: 'assets/images/exercises/push_ups.jpg',
          sets: 3,
          reps: 8,
          restBetweenSeconds: 30,
          targetArea: 'Chest',
          modifications: [],
        ),
        Exercise(
          id: 'mountain-climbers',
          name: 'Mountain Climbers',
          description:
              'Start in plank position, alternately bring each knee toward your chest in a running motion.',
          imageUrl: 'assets/images/exercises/mountain_climbers.jpg',
          sets: 1,
          reps: 0,
          durationSeconds: 45,
          restBetweenSeconds: 30,
          targetArea: 'Core',
          modifications: [],
        ),
        Exercise(
          id: 'plank',
          name: 'Plank',
          description:
              'Hold your body in a straight line from head to heels, supporting your weight on your forearms and toes.',
          imageUrl: 'assets/images/exercises/plank.jpg',
          sets: 3,
          reps: 0,
          durationSeconds: 30,
          restBetweenSeconds: 30,
          targetArea: 'Core',
          modifications: [],
        ),
      ],
      equipment: ['None'],
      tags: ['Quick', 'Beginner', 'Full Body'],
    );
  }
}

/// Provider for the RecommendedWorkoutService
final recommendedWorkoutServiceProvider = Provider<RecommendedWorkoutService>((
  ref,
) {
  return RecommendedWorkoutService();
});

/// Provider that fetches a recommended workout for a specific user profile
final recommendedWorkoutProvider = FutureProvider.family<Workout, UserProfile>((
  ref,
  profile,
) async {
  final service = ref.read(recommendedWorkoutServiceProvider);
  final workout = await service.getRecommendedWorkout(profile);
  return workout ?? service.getFallbackWorkout();
});
