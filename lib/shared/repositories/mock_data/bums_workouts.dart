// lib/shared/repositories/mock_data/bums_workouts.dart
import '../../../features/workouts/models/workout.dart';
import '../../../features/workouts/models/exercise.dart';
import '../../../features/workouts/models/workout_section.dart';
import '../../utils/exercise_reference_utils.dart';

// Initialize cache to ensure exercises are loaded
bool _initialized = false;

Future<void> _ensureInitialized() async {
  if (!_initialized) {
    await initializeExerciseCache();
    _initialized = true;
  }
}

// Safe version to handle cases where exercise might not be found
Exercise _safeGetExercise(String id, {String fallbackId = ''}) {
  try {
    return getExerciseById(id);
  } catch (e) {
    print('Warning: Could not find exercise with ID $id: $e');
    // If a fallback is provided, try that instead
    if (fallbackId.isNotEmpty) {
      try {
        return getExerciseById(fallbackId);
      } catch (_) {
        // If all else fails, create a placeholder exercise
        print('Fallback exercise $fallbackId also not found');
      }
    }

    // Return a placeholder exercise
    return Exercise(
      id: 'placeholder-$id',
      name: 'Exercise Not Found ($id)',
      description: 'This exercise could not be loaded from the database.',
      imageUrl: 'assets/images/exercises/placeholder.jpg',
      sets: 3,
      reps: 10,
      restBetweenSeconds: 30,
      targetArea: 'bums',
    );
  }
}

// Bums workouts with async initialization
Future<List<Workout>> getBumsWorkoutsAsync() async {
  await _ensureInitialized();
  return getBumsWorkouts();
}

// Bums workouts
List<Workout> getBumsWorkouts() {
  if (!_initialized) {
    print('Warning: Accessing workouts before initialization is complete');
  }
  return [
    // BEGINNER WORKOUTS
    
    // Beginner Workout 1
    Workout(
      id: 'bums-001',
      title: 'Booty Blast Basics',
      description:
          'A gentle introduction to bum-focused exercises perfect for beginners. This workout wakes up glute muscles and builds foundational strength without overwhelming you.',
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
        _safeGetExercise('bums-1'),  // Glute Bridge
        _safeGetExercise('bums-2'),  // Donkey Kick
        _safeGetExercise('bums-6'),  // Fire Hydrant
        _safeGetExercise('bums-15'), // Chair Squat
        _safeGetExercise('bums-7'),  // Side Leg Lift
        _safeGetExercise('cardio-1'), // Jumping Jacks
      ],
      hasAccessibilityOptions: true,
      intensityModifications: [
        'Reduce reps by 2-3 per set if needed',
        'Take longer rest periods between sets',
        'Skip the resistance band for now',
      ],
      sections: [
        WorkoutSection(
          id: 'bums-001-section-1',
          name: 'Warm-up',
          exercises: [
            _safeGetExercise('cardio-1'), // Jumping Jacks
            _safeGetExercise('bums-1'),  // Glute Bridge
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'bums-001-section-2',
          name: 'Main Workout',
          exercises: [
            _safeGetExercise('bums-15'), // Chair Squat
            _safeGetExercise('bums-2'),  // Donkey Kick
            _safeGetExercise('bums-6'),  // Fire Hydrant
            _safeGetExercise('bums-7'),  // Side Leg Lift
          ],
          restAfterSection: 90,
          type: SectionType.normal,
        ),
      ],
    ),

    // Beginner Workout 2
    Workout(
      id: 'bums-002',
      title: 'Glute Activation Essentials',
      description:
          'Focus on proper glute activation with this beginner-friendly routine that teaches you how to effectively engage your glute muscles for better results.',
      imageUrl: 'assets/images/workouts/glute_activation_essentials.jpg',
      category: WorkoutCategory.bums,
      difficulty: WorkoutDifficulty.beginner,
      durationMinutes: 25,
      estimatedCaloriesBurn: 180,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 28)),
      createdBy: 'admin',
      equipment: ['mat', 'chair (optional)'],
      tags: ['beginner', 'activation', 'glutes', 'technique'],
      exercises: [
        _safeGetExercise('bums-1'),  // Glute Bridge
        _safeGetExercise('bums-6'),  // Fire Hydrant
        _safeGetExercise('bums-7'),  // Side Leg Lift
        _safeGetExercise('bums-4'),  // Glute Kickback
        _safeGetExercise('bums-15'), // Chair Squat
        _safeGetExercise('bums-17'), // Lunge
        _safeGetExercise('full-8'),  // Bird Dog
      ],
      hasAccessibilityOptions: true,
      intensityModifications: [
        'Focus on form rather than repetitions',
        'Use a chair for support if needed',
        'Take ample rest between exercises',
      ],
      sections: [
        WorkoutSection(
          id: 'bums-002-section-1',
          name: 'Activation Warm-up',
          exercises: [
            _safeGetExercise('bums-1'),  // Glute Bridge
            _safeGetExercise('full-8'),  // Bird Dog
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'bums-002-section-2',
          name: 'Form Practice',
          exercises: [
            _safeGetExercise('bums-15'), // Chair Squat
            _safeGetExercise('bums-6'),  // Fire Hydrant
            _safeGetExercise('bums-7'),  // Side Leg Lift
            _safeGetExercise('bums-4'),  // Glute Kickback
          ],
          restAfterSection: 90,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'bums-002-section-3',
          name: 'Final Practice',
          exercises: [
            _safeGetExercise('bums-17'), // Lunge
          ],
          restAfterSection: 0,
          type: SectionType.normal,
        ),
      ],
    ),

    // Beginner Workout 3
    Workout(
      id: 'bums-003',
      title: 'Booty Foundations',
      description:
          'Build a solid foundation for glute strength and shape with this beginner routine focusing on proper form and full range of motion.',
      imageUrl: 'assets/images/workouts/booty_foundations.jpg',
      category: WorkoutCategory.bums,
      difficulty: WorkoutDifficulty.beginner,
      durationMinutes: 30,
      estimatedCaloriesBurn: 200,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      createdBy: 'admin',
      equipment: ['mat', 'resistance band (optional)'],
      tags: ['beginner', 'foundation', 'glutes', 'mobility'],
      exercises: [
        _safeGetExercise('cardio-1'), // Jumping Jacks
        _safeGetExercise('bums-1'),  // Glute Bridge
        _safeGetExercise('bums-2'),  // Donkey Kick
        _safeGetExercise('bums-6'),  // Fire Hydrant
        _safeGetExercise('bums-17'), // Lunge
        _safeGetExercise('bums-13'), // Squat
        _safeGetExercise('bums-7'),  // Side Leg Lift
        _safeGetExercise('bums-33'), // Standing Dumbbell Calf Raise
      ],
      sections: [
        WorkoutSection(
          id: 'bums-003-section-1',
          name: 'Mobility Warm-up',
          exercises: [
            _safeGetExercise('cardio-1'), // Jumping Jacks
            _safeGetExercise('bums-1'),  // Glute Bridge
            _safeGetExercise('bums-6'),  // Fire Hydrant
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'bums-003-section-2',
          name: 'Strength Circuit',
          exercises: [
            _safeGetExercise('bums-13'), // Squat
            _safeGetExercise('bums-2'),  // Donkey Kick
            _safeGetExercise('bums-17'), // Lunge
            _safeGetExercise('bums-7'),  // Side Leg Lift
          ],
          restAfterSection: 90,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'bums-003-section-3',
          name: 'Finisher',
          exercises: [
            _safeGetExercise('bums-33'), // Standing Dumbbell Calf Raise
          ],
          restAfterSection: 0,
          type: SectionType.normal,
        ),
      ],
    ),
    
    // INTERMEDIATE WORKOUTS
    
    // Intermediate Workout 1
    Workout(
      id: 'bums-004',
      title: 'Booty Builder Blitz',
      description:
          'Take your glute training to the next level with this intermediate workout designed to shape and strengthen your glutes through varied resistance exercises.',
      imageUrl: 'assets/images/workouts/booty_builder_blitz.jpg',
      category: WorkoutCategory.bums,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 35,
      estimatedCaloriesBurn: 260,
      featured: true,
      createdAt: DateTime.now().subtract(const Duration(days: 22)),
      createdBy: 'admin',
      equipment: ['mat', 'resistance band', 'dumbbells (optional)'],
      tags: ['intermediate', 'resistance', 'glutes', 'strength'],
      exercises: [
        _safeGetExercise('cardio-1'), // Jumping Jacks
        _safeGetExercise('bums-1'),  // Glute Bridge
        _safeGetExercise('bums-38'), // Banded Hip Abduction
        _safeGetExercise('bums-11'), // Dumbbell Hip Thrust
        _safeGetExercise('bums-13'), // Squat
        _safeGetExercise('bums-9'),  // Dumbbell Donkey Kick
        _safeGetExercise('bums-10'), // Dumbbell Hip Hinge
        _safeGetExercise('bums-4'),  // Glute Kickback
        _safeGetExercise('bums-5'),  // Glute Kickback Pulse
      ],
      sections: [
        WorkoutSection(
          id: 'bums-004-section-1',
          name: 'Warm-up',
          exercises: [
            _safeGetExercise('cardio-1'), // Jumping Jacks
            _safeGetExercise('bums-1'),  // Glute Bridge
            _safeGetExercise('bums-38'), // Banded Hip Abduction
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'bums-004-section-2',
          name: 'Strength Focus',
          exercises: [
            _safeGetExercise('bums-11'), // Dumbbell Hip Thrust
            _safeGetExercise('bums-13'), // Squat
            _safeGetExercise('bums-10'), // Dumbbell Hip Hinge
          ],
          restAfterSection: 90,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'bums-004-section-3',
          name: 'Isolation Circuit',
          exercises: [
            _safeGetExercise('bums-9'),  // Dumbbell Donkey Kick
            _safeGetExercise('bums-4'),  // Glute Kickback
          ],
          restAfterSection: 90,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'bums-004-section-4',
          name: 'Burnout',
          exercises: [
            _safeGetExercise('bums-5'),  // Glute Kickback Pulse
          ],
          restAfterSection: 0,
          type: SectionType.normal,
        ),
      ],
    ),

    // Intermediate Workout 2
    Workout(
      id: 'bums-005',
      title: 'Glute Sculptor',
      description:
          'Sculpt and define your glutes with this intermediate routine that targets all three gluteal muscles through varied movement patterns and resistance.',
      imageUrl: 'assets/images/workouts/glute_sculptor.jpg',
      category: WorkoutCategory.bums,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 40,
      estimatedCaloriesBurn: 300,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      createdBy: 'admin',
      equipment: ['mat', 'resistance band', 'dumbbells'],
      tags: ['intermediate', 'toning', 'sculpting', 'glutes'],
      exercises: [
        _safeGetExercise('cardio-1'), // Jumping Jacks
        _safeGetExercise('bums-1'),  // Glute Bridge
        _safeGetExercise('bums-11'), // Dumbbell Hip Thrust
        _safeGetExercise('bums-37'), // Bulgarian Split Squat
        _safeGetExercise('bums-6'),  // Fire Hydrant
        _safeGetExercise('bums-10'), // Dumbbell Hip Hinge
        _safeGetExercise('bums-9'),  // Dumbbell Donkey Kick
        _safeGetExercise('bums-5'),  // Glute Kickback Pulse
        _safeGetExercise('full-2'),  // Mountain Climber
      ],
      sections: [
        WorkoutSection(
          id: 'bums-005-section-1',
          name: 'Dynamic Warm-up',
          exercises: [
            _safeGetExercise('cardio-1'), // Jumping Jacks
            _safeGetExercise('bums-1'),  // Glute Bridge
            _safeGetExercise('bums-6'),  // Fire Hydrant
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'bums-005-section-2',
          name: 'Heavy Lifts',
          exercises: [
            _safeGetExercise('bums-11'), // Dumbbell Hip Thrust
            _safeGetExercise('bums-10'), // Dumbbell Hip Hinge
            _safeGetExercise('bums-37'), // Bulgarian Split Squat
          ],
          restAfterSection: 90,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'bums-005-section-3',
          name: 'Targeted Work',
          exercises: [
            _safeGetExercise('bums-9'),  // Dumbbell Donkey Kick
            _safeGetExercise('bums-5'),  // Glute Kickback Pulse
          ],
          restAfterSection: 60,
          type: SectionType.superset,
        ),
        WorkoutSection(
          id: 'bums-005-section-4',
          name: 'Cardio Finisher',
          exercises: [
            _safeGetExercise('full-2'),  // Mountain Climber
          ],
          restAfterSection: 0,
          type: SectionType.normal,
        ),
      ],
    ),

    // Intermediate Workout 3
    Workout(
      id: 'bums-006',
      title: 'Glute Gain Circuit',
      description:
          'Maximize your glute development with this circuit-style intermediate workout that combines strength training with metabolic conditioning.',
      imageUrl: 'assets/images/workouts/glute_gain_circuit.jpg',
      category: WorkoutCategory.bums,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 35,
      estimatedCaloriesBurn: 320,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
      createdBy: 'admin',
      equipment: ['mat', 'dumbbells', 'resistance band'],
      tags: ['intermediate', 'circuit', 'metabolic', 'glutes'],
      exercises: [
        _safeGetExercise('cardio-1'), // Jumping Jacks
        _safeGetExercise('bums-1'),  // Glute Bridge
        _safeGetExercise('bums-38'), // Banded Hip Abduction
        _safeGetExercise('bums-10'), // Dumbbell Hip Hinge
        _safeGetExercise('bums-27'), // Dumbbell Lunge
        _safeGetExercise('bums-9'),  // Dumbbell Donkey Kick
        _safeGetExercise('bums-4'),  // Glute Kickback
        _safeGetExercise('bums-7'),  // Side Leg Lift
        _safeGetExercise('bums-8'),  // Side Leg Lift Pulse
        _safeGetExercise('cardio-2'), // Jumping Squat
      ],
      sections: [
        WorkoutSection(
          id: 'bums-006-section-1',
          name: 'Activation',
          exercises: [
            _safeGetExercise('cardio-1'), // Jumping Jacks
            _safeGetExercise('bums-1'),  // Glute Bridge
            _safeGetExercise('bums-38'), // Banded Hip Abduction
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'bums-006-section-2',
          name: 'Strength Circuit',
          exercises: [
            _safeGetExercise('bums-10'), // Dumbbell Hip Hinge
            _safeGetExercise('bums-27'), // Dumbbell Lunge
            _safeGetExercise('bums-9'),  // Dumbbell Donkey Kick
            _safeGetExercise('bums-4'),  // Glute Kickback
          ],
          restAfterSection: 90,
          type: SectionType.circuit,
       ),
       WorkoutSection(
         id: 'bums-006-section-3',
         name: 'Lateral Focus',
         exercises: [
           _safeGetExercise('bums-7'),  // Side Leg Lift
           _safeGetExercise('bums-8'),  // Side Leg Lift Pulse
         ],
         restAfterSection: 60,
         type: SectionType.superset,
       ),
       WorkoutSection(
         id: 'bums-006-section-4',
         name: 'Cardio Finisher',
         exercises: [
           _safeGetExercise('cardio-2'), // Jumping Squat
         ],
         restAfterSection: 0,
         type: SectionType.normal,
       ),
     ],
   ),
   
   // ADVANCED WORKOUTS
   
   // Advanced Workout 1
   Workout(
     id: 'bums-007',
     title: 'Glute Gains Extreme',
     description:
         'An advanced workout designed to push your glutes to their limits. This high-intensity routine combines weighted exercises with plyometrics for maximum glute development.',
     imageUrl: 'assets/images/workouts/glute_gains_extreme.jpg',
     category: WorkoutCategory.bums,
     difficulty: WorkoutDifficulty.advanced,
     durationMinutes: 45,
     estimatedCaloriesBurn: 400,
     featured: true,
     createdAt: DateTime.now().subtract(const Duration(days: 15)),
     createdBy: 'admin',
     equipment: ['mat', 'dumbbells', 'bench', 'barbell (optional)'],
     tags: ['advanced', 'strength', 'plyometric', 'high intensity'],
     exercises: [
       _safeGetExercise('cardio-1'), // Jumping Jacks
       _safeGetExercise('bums-1'),  // Glute Bridge
       _safeGetExercise('bums-34'), // Barbell Hip Thrust
       _safeGetExercise('bums-36'), // Barbell Romanian Deadlift
       _safeGetExercise('bums-16'), // Jumping Squat
       _safeGetExercise('bums-37'), // Bulgarian Split Squat
       _safeGetExercise('bums-12'), // Fitball Prone Kickup
       _safeGetExercise('bums-9'),  // Dumbbell Donkey Kick
       _safeGetExercise('bums-5'),  // Glute Kickback Pulse
       _safeGetExercise('cardio-5'), // Burpee
     ],
     sections: [
       WorkoutSection(
         id: 'bums-007-section-1',
         name: 'Dynamic Warm-up',
         exercises: [
           _safeGetExercise('cardio-1'), // Jumping Jacks
           _safeGetExercise('bums-1'),  // Glute Bridge
         ],
         restAfterSection: 60,
         type: SectionType.normal,
       ),
       WorkoutSection(
         id: 'bums-007-section-2',
         name: 'Heavy Compound Lifts',
         exercises: [
           _safeGetExercise('bums-34'), // Barbell Hip Thrust
           _safeGetExercise('bums-36'), // Barbell Romanian Deadlift
           _safeGetExercise('bums-37'), // Bulgarian Split Squat
         ],
         restAfterSection: 120,
         type: SectionType.normal,
       ),
       WorkoutSection(
         id: 'bums-007-section-3',
         name: 'Plyometric Work',
         exercises: [
           _safeGetExercise('bums-16'), // Jumping Squat
         ],
         restAfterSection: 90,
         type: SectionType.normal,
       ),
       WorkoutSection(
         id: 'bums-007-section-4',
         name: 'Stability & Isolation',
         exercises: [
           _safeGetExercise('bums-12'), // Fitball Prone Kickup
           _safeGetExercise('bums-9'),  // Dumbbell Donkey Kick
           _safeGetExercise('bums-5'),  // Glute Kickback Pulse
         ],
         restAfterSection: 60,
         type: SectionType.circuit,
       ),
       WorkoutSection(
         id: 'bums-007-section-5',
         name: 'Metabolic Finisher',
         exercises: [
           _safeGetExercise('cardio-5'),  // Burpee
         ],
         restAfterSection: 0,
         type: SectionType.normal,
       ),
     ],
   ),

   // Advanced Workout 2
   Workout(
     id: 'bums-008',
     title: 'Booty Builder Elite',
     description:
         'An advanced routine that pushes your glutes to new levels with complex movement patterns, heavy resistance, and stability challenges.',
     imageUrl: 'assets/images/workouts/booty_builder_elite.jpg',
     category: WorkoutCategory.bums,
     difficulty: WorkoutDifficulty.advanced,
     durationMinutes: 50,
     estimatedCaloriesBurn: 450,
     featured: false,
     createdAt: DateTime.now().subtract(const Duration(days: 12)),
     createdBy: 'admin',
     equipment: ['mat', 'heavy dumbbells', 'bench', 'stability ball', 'barbell'],
     tags: ['advanced', 'heavy', 'complex', 'progressive'],
     exercises: [
       _safeGetExercise('cardio-3'), // High Knees
       _safeGetExercise('bums-1'),  // Glute Bridge
       _safeGetExercise('bums-35'), // Barbell Back Squat
       _safeGetExercise('bums-34'), // Barbell Hip Thrust
       _safeGetExercise('bums-36'), // Barbell Romanian Deadlift
       _safeGetExercise('bums-29'), // Dumbbell Single Leg Deadlift
       _safeGetExercise('bums-9'),  // Dumbbell Donkey Kick
       _safeGetExercise('bums-12'), // Fitball Prone Kickup
       _safeGetExercise('bums-32'), // Fitball Single Leg Roll
       _safeGetExercise('cardio-6'), // Jumping Lunge
     ],
     sections: [
       WorkoutSection(
         id: 'bums-008-section-1',
         name: 'Activation Complex',
         exercises: [
           _safeGetExercise('cardio-3'), // High Knees
           _safeGetExercise('bums-1'),  // Glute Bridge
         ],
         restAfterSection: 60,
         type: SectionType.normal,
       ),
       WorkoutSection(
         id: 'bums-008-section-2',
         name: 'Heavy Compound Work',
         exercises: [
           _safeGetExercise('bums-35'), // Barbell Back Squat
           _safeGetExercise('bums-34'), // Barbell Hip Thrust
           _safeGetExercise('bums-36'), // Barbell Romanian Deadlift
         ],
         restAfterSection: 120,
         type: SectionType.normal,
       ),
       WorkoutSection(
         id: 'bums-008-section-3',
         name: 'Unilateral Strength',
         exercises: [
           _safeGetExercise('bums-29'), // Dumbbell Single Leg Deadlift
           _safeGetExercise('bums-9'),  // Dumbbell Donkey Kick
         ],
         restAfterSection: 90,
         type: SectionType.normal,
       ),
       WorkoutSection(
         id: 'bums-008-section-4',
         name: 'Stability Challenge',
         exercises: [
           _safeGetExercise('bums-12'), // Fitball Prone Kickup
           _safeGetExercise('bums-32'), // Fitball Single Leg Roll
         ],
         restAfterSection: 60,
         type: SectionType.superset,
       ),
       WorkoutSection(
         id: 'bums-008-section-5',
         name: 'Metabolic Finisher',
         exercises: [
           _safeGetExercise('cardio-6'),  // Jumping Lunge
         ],
         restAfterSection: 0,
         type: SectionType.normal,
       ),
     ],
   ),

   // Advanced Workout 3
   Workout(
     id: 'bums-009',
     title: 'Maximum Glute Overload',
     description:
         'An intense advanced workout using principles of progressive overload, time under tension, and compound movements to maximize glute hypertrophy.',
     imageUrl: 'assets/images/workouts/maximum_glute_overload.jpg',
     category: WorkoutCategory.bums,
     difficulty: WorkoutDifficulty.advanced,
     durationMinutes: 55,
     estimatedCaloriesBurn: 480,
     featured: false,
     createdAt: DateTime.now().subtract(const Duration(days: 10)),
     createdBy: 'admin',
     equipment: ['mat', 'heavy dumbbells', 'stability ball', 'bench', 'barbell'],
     tags: ['advanced', 'hypertrophy', 'progressive overload', 'compound'],
     exercises: [
       _safeGetExercise('full-2'),  // Mountain Climber
       _safeGetExercise('bums-1'),  // Glute Bridge
       _safeGetExercise('bums-38'), // Banded Hip Abduction
       _safeGetExercise('bums-34'), // Barbell Hip Thrust
       _safeGetExercise('bums-35'), // Barbell Back Squat
       _safeGetExercise('bums-36'), // Barbell Romanian Deadlift
       _safeGetExercise('bums-37'), // Bulgarian Split Squat
       _safeGetExercise('bums-22'), // Pistol Box Squat
       _safeGetExercise('bums-12'), // Fitball Prone Kickup
       _safeGetExercise('bums-9'),  // Dumbbell Donkey Kick
       _safeGetExercise('bums-8'),  // Side Leg Lift Pulse
       _safeGetExercise('cardio-7'), // Skater Jumps
     ],
     sections: [
       WorkoutSection(
         id: 'bums-009-section-1',
         name: 'Progressive Activation',
         exercises: [
           _safeGetExercise('full-2'),  // Mountain Climber
           _safeGetExercise('bums-1'),  // Glute Bridge
           _safeGetExercise('bums-38'), // Banded Hip Abduction
         ],
         restAfterSection: 60,
         type: SectionType.normal,
       ),
       WorkoutSection(
         id: 'bums-009-section-2',
         name: 'Heavy Compound Lifts',
         exercises: [
           _safeGetExercise('bums-34'), // Barbell Hip Thrust
           _safeGetExercise('bums-35'), // Barbell Back Squat
           _safeGetExercise('bums-36'), // Barbell Romanian Deadlift
         ],
         restAfterSection: 120,
         type: SectionType.normal,
       ),
       WorkoutSection(
         id: 'bums-009-section-3',
         name: 'Advanced Unilateral Work',
         exercises: [
           _safeGetExercise('bums-37'), // Bulgarian Split Squat
           _safeGetExercise('bums-22'), // Pistol Box Squat
         ],
         restAfterSection: 90,
         type: SectionType.normal,
       ),
       WorkoutSection(
         id: 'bums-009-section-4',
         name: 'Isolation & Stability',
         exercises: [
           _safeGetExercise('bums-12'), // Fitball Prone Kickup
           _safeGetExercise('bums-9'),  // Dumbbell Donkey Kick
           _safeGetExercise('bums-8'),  // Side Leg Lift Pulse
         ],
         restAfterSection: 60,
         type: SectionType.circuit,
       ),
       WorkoutSection(
         id: 'bums-009-section-5',
         name: 'Metabolic Finisher',
         exercises: [
           _safeGetExercise('cardio-7'),  // Skater Jumps
         ],
         restAfterSection: 0,
         type: SectionType.normal,
       ),
     ],
   ),
 ];
}