
import '../../../features/workouts/models/workout.dart';
import '../../../features/workouts/models/exercise.dart';

  // Full body workouts
  List<Workout> getFullBodyWorkouts() {
    return [
      // Total Beginner
      Workout(
        id: 'full-001',
        title: 'Total Body Awakening',
        description:
            'Wake up your entire body with this gentle but effective full-body workout designed for beginners. Youll touch on all major muscle groups in a supportive, accessible way.',
        imageUrl: 'assets/images/workouts/total_body_awakening.jpg',
        category: WorkoutCategory.fullBody,
        difficulty: WorkoutDifficulty.beginner,
        durationMinutes: 25,
        estimatedCaloriesBurn: 180,
        featured: true,
        createdAt: DateTime.now().subtract(const Duration(days: 35)),
        createdBy: 'admin',
        equipment: ['mat', 'light dumbbells (optional)'],
        tags: ['beginner', 'full body', 'introduction'],
        exercises: [
          Exercise(
            id: 'ex-040',
            name: 'Modified Push-Ups',
            description:
                'Start with knee push-ups or wall push-ups to build upper body strength in an accessible way.',
            imageUrl: 'assets/images/exercises/knee_pushup.jpg',
            sets: 2,
            reps: 8,
            restBetweenSeconds: 40,
            targetArea: 'upper body',
            modifications: [
              ExerciseModification(
                id: 'mod-020',
                title: 'Wall Push-Up',
                description:
                    'Stand facing a wall and place your hands on the wall at shoulder height. Perform the push-up against the wall.',
                forAccessibilityNeeds: [
                  'wrist pain',
                  'shoulder issues',
                  'beginner',
                ],
              ),
            ],
          ),
          // More exercises would follow
        ],
      ),

      // More full body workouts would follow
    ];
  }
