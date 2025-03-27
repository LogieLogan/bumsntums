
import '../../../features/workouts/models/workout.dart';
import '../../../features/workouts/models/exercise.dart';

  // Bums workouts
  List<Workout> getBumsWorkouts() {
    return [
      // Booty Blast Beginner
      Workout(
        id: 'bums-001',
        title: 'Booty Blast Basics',
        description:
            'A gentle introduction to bum-focused exercises perfect for beginners. This workout will wake up those glute muscles and get them working without overwhelming you.',
        imageUrl: 'assets/images/workouts/booty_blast_basics.jpg',
        category: WorkoutCategory.bums,
        difficulty: WorkoutDifficulty.beginner,
        durationMinutes: 20,
        estimatedCaloriesBurn: 150,
        featured: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        createdBy: 'admin',
        equipment: ['mat', 'resistance band (optional)'],
        tags: ['beginner', 'low impact', 'glutes'],
        exercises: [
          Exercise(
            id: 'ex-001',
            name: 'Glute Bridges',
            description:
                'Lie on your back with your knees bent and feet flat on the floor. Lift your hips toward the ceiling, squeezing your glutes at the top, then lower back down.',
            imageUrl: 'assets/images/exercises/glute_bridge.jpg',
            videoPath: 'assets/videos/exercises/glute_bridge.mp4',
            sets: 3,
            reps: 12,
            restBetweenSeconds: 30,
            targetArea: 'bums',
            modifications: [
              ExerciseModification(
                id: 'mod-001',
                title: 'Supported Bridge',
                description:
                    'Place a cushion under your lower back for support if you have back discomfort.',
                forAccessibilityNeeds: ['back pain', 'mobility issues'],
              ),
            ],
          ),
          Exercise(
            id: 'ex-002',
            name: 'Squats',
            description:
                'Stand with feet hip-width apart. Lower your body as if sitting into a chair, keeping your chest up and knees behind toes. Push through heels to return to standing.',
            imageUrl: 'assets/images/exercises/squat.jpg',
            videoPath: 'assets/videos/exercises/squat.mp4',
            sets: 3,
            reps: 10,
            restBetweenSeconds: 40,
            targetArea: 'bums',
            modifications: [
              ExerciseModification(
                id: 'mod-002',
                title: 'Chair Squat',
                description:
                    'Perform the squat movement while holding onto a chair for support.',
                forAccessibilityNeeds: ['balance issues', 'knee pain'],
              ),
            ],
          ),
          Exercise(
            id: 'ex-003',
            name: 'Side-Lying Leg Lifts',
            description:
                'Lie on your side with your legs straight. Lift your top leg up toward the ceiling, keeping it straight, then lower it back down with control.',
            imageUrl: 'assets/images/exercises/side_leg_lift.jpg',
            videoPath: 'assets/videos/exercises/side_leg_lift.mp4',
            sets: 2,
            reps: 15,
            restBetweenSeconds: 30,
            targetArea: 'bums',
          ),
          Exercise(
            id: 'ex-004',
            name: 'Donkey Kicks',
            description:
                'Start on all fours. Keeping your knee bent, lift one leg up behind you until your foot is facing the ceiling, then lower it back down.',
            imageUrl: 'assets/images/exercises/donkey_kick.jpg',
            videoPath: 'assets/videos/exercises/donkey_kick.mp4',
            sets: 2,
            reps: 12,
            restBetweenSeconds: 30,
            targetArea: 'bums',
          ),
          Exercise(
            id: 'ex-005',
            name: 'Lunges',
            description:
                'Stand tall, then step one foot forward and lower your body until both knees are bent at 90 degrees. Push through your front heel to return to standing.',
            imageUrl: 'assets/images/exercises/lunge.jpg',
            videoPath: 'assets/videos/exercises/lunge.mp4',
            sets: 2,
            reps: 10,
            restBetweenSeconds: 40,
            targetArea: 'bums',
            modifications: [
              ExerciseModification(
                id: 'mod-003',
                title: 'Stationary Lunge',
                description:
                    'Perform a smaller range of motion or hold onto a chair for support.',
                forAccessibilityNeeds: ['balance issues', 'knee pain'],
              ),
            ],
          ),
        ],
        hasAccessibilityOptions: true,
        intensityModifications: [
          'Reduce reps by 2-3 per set if needed',
          'Take longer rest periods between sets',
          'Skip the resistance band for now',
        ],
      ),

      // Booty Builder Intermediate
      Workout(
        id: 'bums-002',
        title: 'Booty Builder Blitz',
        description:
            'Take your glute training to the next level with this intermediate workout designed to shape and strengthen your bum through varied resistance exercises.',
        imageUrl: 'assets/images/workouts/booty_builder_blitz.jpg',
        category: WorkoutCategory.bums,
        difficulty: WorkoutDifficulty.intermediate,
        durationMinutes: 30,
        estimatedCaloriesBurn: 220,
        featured: false,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        createdBy: 'admin',
        equipment: ['mat', 'resistance band', 'dumbbells (optional)'],
        tags: ['intermediate', 'resistance', 'glutes'],
        exercises: [
          Exercise(
            id: 'ex-006',
            name: 'Resistance Band Squats',
            description:
                'Place a resistance band just above your knees. Perform a squat while pushing outward against the band to engage your glutes more intensely.',
            imageUrl: 'assets/images/exercises/band_squat.jpg',
            sets: 3,
            reps: 15,
            restBetweenSeconds: 30,
            targetArea: 'bums',
          ),
          Exercise(
            id: 'ex-007',
            name: 'Single-Leg Glute Bridge',
            description:
                'Perform a glute bridge with one leg extended straight out, putting all the work into the grounded leg.',
            imageUrl: 'assets/images/exercises/single_leg_bridge.jpg',
            sets: 3,
            reps: 12,
            restBetweenSeconds: 30,
            targetArea: 'bums',
          ),
          // More exercises would follow
        ],
      ),

      Workout(
        id: 'bums-003',
        title: 'Glute Sculptor',
        description:
            'Take your bum workout to the next level with this intermediate routine that targets all three gluteal muscles with varied resistance patterns.',
        imageUrl: 'assets/images/workouts/glute_sculptor.jpg',
        category: WorkoutCategory.bums,
        difficulty: WorkoutDifficulty.intermediate,
        durationMinutes: 35,
        estimatedCaloriesBurn: 280,
        featured: false,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        createdBy: 'admin',
        equipment: ['mat', 'resistance band', 'dumbbells'],
        tags: ['intermediate', 'resistance', 'toning'],
        exercises: [
          Exercise(
            id: 'ex-010',
            name: 'Banded Squats',
            description:
                'Place a resistance band just above your knees. Stand with feet shoulder-width apart and perform a squat while pressing knees outward against the band.',
            imageUrl: 'assets/images/exercises/banded_squat.jpg',
            sets: 3,
            reps: 15,
            restBetweenSeconds: 45,
            targetArea: 'bums',
          ),
          Exercise(
            id: 'ex-011',
            name: 'Bulgarian Split Squats',
            description:
                'Place one foot on a bench behind you, keeping your front foot about 2 feet from the bench. Lower into a lunge position and push back up.',
            imageUrl: 'assets/images/exercises/bulgarian_split_squat.jpg',
            sets: 3,
            reps: 12,
            restBetweenSeconds: 60,
            targetArea: 'bums',
            modifications: [
              ExerciseModification(
                id: 'mod-011',
                title: 'Shorter Range',
                description:
                    'Don\'t go as deep if you feel strain in your knees.',
                forAccessibilityNeeds: ['knee pain', 'balance issues'],
              ),
            ],
          ),
          Exercise(
            id: 'ex-012',
            name: 'Dumbbell Deadlifts',
            description:
                'Hold dumbbells in front of thighs with feet hip-width apart. Hinge at hips to lower weights toward the floor, then return to standing.',
            imageUrl: 'assets/images/exercises/dumbbell_deadlift.jpg',
            sets: 3,
            reps: 12,
            restBetweenSeconds: 60,
            targetArea: 'bums',
          ),
          Exercise(
            id: 'ex-013',
            name: 'Fire Hydrants',
            description:
                'Start on all fours. Keeping knee bent at 90 degrees, lift one leg out to the side as high as comfortable while keeping hips level.',
            imageUrl: 'assets/images/exercises/fire_hydrant.jpg',
            sets: 3,
            reps: 15,
            restBetweenSeconds: 30,
            targetArea: 'bums',
          ),
          Exercise(
            id: 'ex-014',
            name: 'Banded Clamshells',
            description:
                'Lie on your side with knees bent and a band around your thighs. Keep feet together and open the top knee like a clamshell.',
            imageUrl: 'assets/images/exercises/clamshell.jpg',
            sets: 3,
            reps: 20,
            restBetweenSeconds: 30,
            targetArea: 'bums',
          ),
        ],
      ),

      // Advanced Booty Burner
      Workout(
        id: 'bums-004',
        title: 'Glute Gains Extreme',
        description:
            'An advanced workout for those ready to push their limits. This high-intensity routine combines weighted exercises with plyometrics for maximum glute development.',
        imageUrl: 'assets/images/workouts/glute_gains.jpg',
        category: WorkoutCategory.bums,
        difficulty: WorkoutDifficulty.advanced,
        durationMinutes: 45,
        estimatedCaloriesBurn: 400,
        featured: false,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        createdBy: 'admin',
        equipment: ['mat', 'dumbbells', 'bench'],
        tags: ['advanced', 'strength', 'plyometric'],
        exercises: [
          Exercise(
            id: 'ex-020',
            name: 'Weighted Jump Squats',
            description:
                'Hold light dumbbells at your sides. Perform a squat, then explosively jump upward, landing softly back into the squat position.',
            imageUrl: 'assets/images/exercises/jump_squat.jpg',
            sets: 4,
            reps: 12,
            restBetweenSeconds: 60,
            targetArea: 'bums',
            modifications: [
              ExerciseModification(
                id: 'mod-020',
                title: 'Lower Impact',
                description:
                    'Remove the jump and just perform fast squats if needed.',
                forAccessibilityNeeds: ['joint pain', 'low impact'],
              ),
            ],
          ),
          Exercise(
            id: 'ex-021',
            name: 'Sumo Deadlifts',
            description:
                'Stand with feet wider than shoulder-width, toes pointed outward. Hold dumbbells between legs and perform a deadlift with this wide stance.',
            imageUrl: 'assets/images/exercises/sumo_deadlift.jpg',
            sets: 4,
            reps: 10,
            restBetweenSeconds: 90,
            targetArea: 'bums',
          ),
          // More exercises
        ],
      ),
    ];
  }
