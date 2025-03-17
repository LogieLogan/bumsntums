
import '../../../features/workouts/models/workout.dart';
import '../../../features/workouts/models/exercise.dart';

  // Tums workouts
  List<Workout> getTumsWorkouts() {
    return [
      // Core Beginnings
      Workout(
        id: 'tums-001',
        title: 'Core Confidence',
        description:
            'A gentle introduction to core exercises that will help you build abdominal strength without strain. Perfect for beginners wanting to strengthen their midsection.',
        imageUrl: 'assets/images/workouts/core_confidence.jpg',
        category: WorkoutCategory.tums,
        difficulty: WorkoutDifficulty.beginner,
        durationMinutes: 15,
        estimatedCaloriesBurn: 120,
        featured: true,
        createdAt: DateTime.now().subtract(const Duration(days: 28)),
        createdBy: 'admin',
        equipment: ['mat'],
        tags: ['beginner', 'core', 'posture'],
        exercises: [
          Exercise(
            id: 'ex-020',
            name: 'Modified Curl-Ups',
            description:
                'Lie on your back with knees bent. Place hands behind your head and gently lift your shoulders off the mat, focusing on engaging your core.',
            imageUrl: 'assets/images/exercises/modified_curlup.jpg',
            sets: 3,
            reps: 10,
            restBetweenSeconds: 30,
            targetArea: 'tums',
            modifications: [
              ExerciseModification(
                id: 'mod-010',
                title: 'Head Supported Curl-Up',
                description:
                    'Keep your head on the mat and just focus on tightening your abdominals while breathing out.',
                forAccessibilityNeeds: ['neck pain', 'beginner'],
              ),
            ],
          ),
          // More exercises would follow
        ],
        hasAccessibilityOptions: true,
        intensityModifications: [
          'Focus on form rather than repetitions',
          'Take breaks whenever needed',
          'Use pillows for support if necessary',
        ],
      ),

      // More tums workouts would follow
    ];
  }
