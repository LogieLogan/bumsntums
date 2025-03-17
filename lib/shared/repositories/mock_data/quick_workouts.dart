
import '../../../features/workouts/models/workout.dart';
import '../../../features/workouts/models/exercise.dart';

  // Quick workouts
  List<Workout> getQuickWorkouts() {
    return [
      // Quick Blast
      Workout(
        id: 'quick-001',
        title: 'Morning Energy Boost',
        description:
            'No time? No problem! This 10-minute energizing workout is perfect for busy mornings when you need a quick burst of energy to start your day right.',
        imageUrl: 'assets/images/workouts/morning_energy_boost.jpg',
        category: WorkoutCategory.quickWorkout,
        difficulty: WorkoutDifficulty.beginner,
        durationMinutes: 10,
        estimatedCaloriesBurn: 90,
        featured: true,
        createdAt: DateTime.now().subtract(const Duration(days: 22)),
        createdBy: 'admin',
        equipment: ['none'],
        tags: ['quick', 'energizing', 'no equipment'],
        exercises: [
          Exercise(
            id: 'ex-060',
            name: 'Jumping Jacks',
            description:
                'Start with feet together and arms at your sides. Jump to a position with legs spread and arms overhead, then jump back to starting position.',
            imageUrl: 'assets/images/exercises/jumping_jacks.jpg',
            sets: 1,
            reps: 0,
            durationSeconds: 40,
            restBetweenSeconds: 15,
            targetArea: 'full body',
            modifications: [
              ExerciseModification(
                id: 'mod-030',
                title: 'Step Jacks',
                description:
                    'Instead of jumping, step one foot out at a time while raising arms.',
                forAccessibilityNeeds: ['joint pain', 'low impact'],
              ),
            ],
          ),
          Exercise(
            id: 'ex-061',
            name: 'Bodyweight Squats',
            description: 'A quick set of squats to wake up your lower body.',
            imageUrl: 'assets/images/exercises/bodyweight_squat.jpg',
            sets: 1,
            reps: 12,
            restBetweenSeconds: 15,
            targetArea: 'lower body',
          ),
          Exercise(
            id: 'ex-062',
            name: 'Mountain Climbers',
            description:
                'Start in a plank position. Alternate bringing knees toward chest in a running motion.',
            imageUrl: 'assets/images/exercises/mountain_climbers.jpg',
            sets: 1,
            reps: 0,
            durationSeconds: 30,
            restBetweenSeconds: 15,
            targetArea: 'core',
            modifications: [
              ExerciseModification(
                id: 'mod-031',
                title: 'Slow Mountain Climbers',
                description:
                    'Perform the exercise at a slower pace with controlled movements.',
                forAccessibilityNeeds: ['wrist pain', 'limited mobility'],
              ),
            ],
          ),
          Exercise(
            id: 'ex-063',
            name: 'Push-Up to Plank Rotation',
            description:
                'Perform a push-up, then rotate to a side plank, reaching your top arm toward the ceiling.',
            imageUrl: 'assets/images/exercises/pushup_rotation.jpg',
            sets: 1,
            reps: 8,
            restBetweenSeconds: 15,
            targetArea: 'upper body',
            modifications: [
              ExerciseModification(
                id: 'mod-032',
                title: 'Knee Push-Up with Simplified Rotation',
                description:
                    'Do knee push-ups and just rotate to the side without the full side plank.',
                forAccessibilityNeeds: ['shoulder issues', 'wrist pain'],
              ),
            ],
          ),
          Exercise(
            id: 'ex-064',
            name: 'Standing Side Crunches',
            description:
                'Stand with feet hip-width apart. Place hands behind head and lift one knee while bringing elbow toward it, alternating sides.',
            imageUrl: 'assets/images/exercises/standing_side_crunch.jpg',
            sets: 1,
            reps: 16,
            restBetweenSeconds: 0,
            targetArea: 'core',
          ),
        ],
        hasAccessibilityOptions: true,
        intensityModifications: [
          'Follow along at your own pace',
          'Feel free to take short breaks as needed',
          'Modify any exercise that feels uncomfortable',
        ],
      ),

      // More quick workouts would follow
    ];
  }
