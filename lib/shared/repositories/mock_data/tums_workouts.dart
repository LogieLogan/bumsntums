// lib/shared/repositories/mock_data/tums_workouts.dart
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
      targetArea: 'tums',
    );
  }
}

// Tums workouts with async initialization
Future<List<Workout>> getTumsWorkoutsAsync() async {
  await _ensureInitialized();
  return getTumsWorkouts();
}

// Tums workouts
List<Workout> getTumsWorkouts() {
  if (!_initialized) {
    print('Warning: Accessing workouts before initialization is complete');
  }
  return [
    // BEGINNER WORKOUTS
    
    // Beginner Workout 1
    Workout(
      id: 'tums-001',
      title: 'Core Foundations',
      description:
          'A gentle introduction to core training that focuses on proper activation and basic movement patterns for beginners.',
      imageUrl: 'assets/images/workouts/core_foundations.jpg',
      category: WorkoutCategory.tums,
      difficulty: WorkoutDifficulty.beginner,
      durationMinutes: 20,
      estimatedCaloriesBurn: 140,
      featured: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      createdBy: 'admin',
      equipment: ['mat'],
      tags: ['beginner', 'core', 'abdominals', 'foundations'],
      exercises: [
        _safeGetExercise('tums-1'),  // Abdominal Crunch
        _safeGetExercise('tums-8'),  // Side Crunch
        _safeGetExercise('tums-13'), // Dead Bug
        _safeGetExercise('tums-3'),  // Straight Arm Plank
        _safeGetExercise('cardio-1'), // Jumping Jacks
      ],
      hasAccessibilityOptions: true,
      intensityModifications: [
        'Reduce reps by 3-5 per set if needed',
        'Take longer rest periods between exercises',
        'Perform modified versions of exercises as needed',
      ],
      sections: [
        WorkoutSection(
          id: 'tums-001-section-1',
          name: 'Warm-up',
          exercises: [
            _safeGetExercise('cardio-1'), // Jumping Jacks
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'tums-001-section-2',
          name: 'Core Basics',
          exercises: [
            _safeGetExercise('tums-1'),  // Abdominal Crunch
            _safeGetExercise('tums-8'),  // Side Crunch
            _safeGetExercise('tums-13'), // Dead Bug
          ],
          restAfterSection: 90,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'tums-001-section-3',
          name: 'Stability Finisher',
          exercises: [
            _safeGetExercise('tums-3'),  // Straight Arm Plank
          ],
          restAfterSection: 0,
          type: SectionType.normal,
        ),
      ],
    ),

    // Beginner Workout 2
    Workout(
      id: 'tums-002',
      title: 'Abs Awakening',
      description:
          'Activate and engage your core muscles with this beginner-friendly routine designed to build abdominal awareness and endurance.',
      imageUrl: 'assets/images/workouts/abs_awakening.jpg',
      category: WorkoutCategory.tums,
      difficulty: WorkoutDifficulty.beginner,
      durationMinutes: 25,
      estimatedCaloriesBurn: 160,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 28)),
      createdBy: 'admin',
      equipment: ['mat', 'stability ball (optional)'],
      tags: ['beginner', 'core activation', 'endurance'],
      exercises: [
        _safeGetExercise('cardio-1'), // Jumping Jacks
        _safeGetExercise('tums-1'),  // Abdominal Crunch
        _safeGetExercise('tums-9'),  // Sit Up
        _safeGetExercise('tums-13'), // Dead Bug
        _safeGetExercise('tums-20'), // Fitball Alternating Dead Bug
        _safeGetExercise('tums-15'), // Prone Flutter Kick
        _safeGetExercise('full-8'),  // Bird Dog
      ],
      hasAccessibilityOptions: true,
      intensityModifications: [
        'Focus on proper form rather than quantity',
        'Use stability ball only if comfortable',
        'Take extra rest between exercises as needed',
      ],
      sections: [
        WorkoutSection(
          id: 'tums-002-section-1',
          name: 'Warm-up',
          exercises: [
            _safeGetExercise('cardio-1'), // Jumping Jacks
            _safeGetExercise('full-8'),   // Bird Dog
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'tums-002-section-2',
          name: 'Core Activation',
          exercises: [
            _safeGetExercise('tums-1'),  // Abdominal Crunch
            _safeGetExercise('tums-9'),  // Sit Up
            _safeGetExercise('tums-13'), // Dead Bug
          ],
          restAfterSection: 90,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'tums-002-section-3',
          name: 'Equipment Work',
          exercises: [
            _safeGetExercise('tums-20'), // Fitball Alternating Dead Bug
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'tums-002-section-4',
          name: 'Finisher',
          exercises: [
            _safeGetExercise('tums-15'), // Prone Flutter Kick
          ],
          restAfterSection: 0,
          type: SectionType.normal,
        ),
      ],
    ),

    // Beginner Workout 3
    Workout(
      id: 'tums-003',
      title: 'Simple Core Circuit',
      description:
          'A circuit-style core workout for beginners that builds endurance and teaches proper engagement through simple, effective exercises.',
      imageUrl: 'assets/images/workouts/simple_core_circuit.jpg',
      category: WorkoutCategory.tums,
      difficulty: WorkoutDifficulty.beginner,
      durationMinutes: 30,
      estimatedCaloriesBurn: 180,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      createdBy: 'admin',
      equipment: ['mat', 'stability ball (optional)'],
      tags: ['beginner', 'circuit', 'endurance', 'core stability'],
      exercises: [
        _safeGetExercise('full-2'),  // Mountain Climber
        _safeGetExercise('tums-1'),  // Abdominal Crunch
        _safeGetExercise('tums-2'),  // Bicycle Crunch
        _safeGetExercise('tums-3'),  // Straight Arm Plank
        _safeGetExercise('tums-8'),  // Side Crunch
        _safeGetExercise('tums-16'), // Fitball Crunch
        _safeGetExercise('tums-27'), // Fitball Prayer Crunch
      ],
      sections: [
        WorkoutSection(
          id: 'tums-003-section-1',
          name: 'Dynamic Warm-up',
          exercises: [
            _safeGetExercise('full-2'),  // Mountain Climber
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'tums-003-section-2',
          name: 'Basic Core Circuit',
          exercises: [
            _safeGetExercise('tums-1'),  // Abdominal Crunch
            _safeGetExercise('tums-2'),  // Bicycle Crunch
            _safeGetExercise('tums-3'),  // Straight Arm Plank
            _safeGetExercise('tums-8'),  // Side Crunch
          ],
          restAfterSection: 90,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'tums-003-section-3',
          name: 'Stability Ball Work',
          exercises: [
            _safeGetExercise('tums-16'), // Fitball Crunch
            _safeGetExercise('tums-27'), // Fitball Prayer Crunch
          ],
          restAfterSection: 0,
          type: SectionType.normal,
        ),
      ],
    ),
    
    // INTERMEDIATE WORKOUTS
    
    // Intermediate Workout 1
    Workout(
      id: 'tums-004',
      title: 'Core Strength & Stability',
      description:
          'Build core strength and stability with this intermediate workout that challenges your abdominals, obliques, and lower back through varied movement patterns.',
      imageUrl: 'assets/images/workouts/core_strength_stability.jpg',
      category: WorkoutCategory.tums,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 35,
      estimatedCaloriesBurn: 240,
      featured: true,
      createdAt: DateTime.now().subtract(const Duration(days: 22)),
      createdBy: 'admin',
      equipment: ['mat', 'stability ball'],
      tags: ['intermediate', 'core strength', 'stability', 'obliques'],
      exercises: [
        _safeGetExercise('full-2'),  // Mountain Climber
        _safeGetExercise('tums-2'),  // Bicycle Crunch
        _safeGetExercise('tums-4'),  // Russian Twist
        _safeGetExercise('tums-5'),  // Reverse Crunch
        _safeGetExercise('tums-14'), // Diagonal Plank
        _safeGetExercise('tums-17'), // Fitball Plank Hold
        _safeGetExercise('tums-21'), // Fitball Alternating Leg Raise
        _safeGetExercise('tums-29'), // Fitball Tuck
      ],
      sections: [
        WorkoutSection(
          id: 'tums-004-section-1',
          name: 'Dynamic Warm-up',
          exercises: [
            _safeGetExercise('full-2'),  // Mountain Climber
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'tums-004-section-2',
          name: 'Core Strength Circuit',
          exercises: [
            _safeGetExercise('tums-2'),  // Bicycle Crunch
            _safeGetExercise('tums-4'),  // Russian Twist
            _safeGetExercise('tums-5'),  // Reverse Crunch
          ],
          restAfterSection: 90,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'tums-004-section-3',
          name: 'Stability Challenge',
          exercises: [
            _safeGetExercise('tums-14'), // Diagonal Plank
            _safeGetExercise('tums-17'), // Fitball Plank Hold
          ],
          restAfterSection: 90,
          type: SectionType.superset,
        ),
        WorkoutSection(
          id: 'tums-004-section-4',
          name: 'Fitball Finisher',
          exercises: [
            _safeGetExercise('tums-21'), // Fitball Alternating Leg Raise
            _safeGetExercise('tums-29'), // Fitball Tuck
          ],
          restAfterSection: 0,
          type: SectionType.normal,
        ),
      ],
    ),

    // Intermediate Workout 2
    Workout(
      id: 'tums-005',
      title: 'Core Conditioning',
      description:
          'This intermediate core workout combines traditional and functional exercises to build strength, endurance, and stability throughout your midsection.',
      imageUrl: 'assets/images/workouts/core_conditioning.jpg',
      category: WorkoutCategory.tums,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 40,
      estimatedCaloriesBurn: 290,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      createdBy: 'admin',
      equipment: ['mat', 'stability ball', 'dumbbell (optional)'],
      tags: ['intermediate', 'functional core', 'conditioning', 'endurance'],
      exercises: [
        _safeGetExercise('cardio-3'), // High Knees
        _safeGetExercise('tums-2'),  // Bicycle Crunch
        _safeGetExercise('tums-6'),  // Leg Drop
        _safeGetExercise('tums-7'),  // Leg In and Out
        _safeGetExercise('tums-11'), // V Crunch
        _safeGetExercise('tums-12'), // Plank with Leg Lift
        _safeGetExercise('tums-19'), // Fitball Mountain Climber
        _safeGetExercise('tums-24'), // Fitball Double Leg Hold
        _safeGetExercise('tums-28'), // Fitball Reverse Crunch
        _safeGetExercise('tum-30'),  // Dumbbell Crunch and Punch
      ],
      sections: [
        WorkoutSection(
          id: 'tums-005-section-1',
          name: 'Warm-up',
          exercises: [
            _safeGetExercise('cardio-3'), // High Knees
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'tums-005-section-2',
          name: 'Dynamic Core Work',
          exercises: [
            _safeGetExercise('tums-2'),  // Bicycle Crunch
            _safeGetExercise('tums-6'),  // Leg Drop
            _safeGetExercise('tums-7'),  // Leg In and Out
            _safeGetExercise('tums-11'), // V Crunch
          ],
          restAfterSection: 90,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'tums-005-section-3',
          name: 'Stability & Control',
          exercises: [
            _safeGetExercise('tums-12'), // Plank with Leg Lift
            _safeGetExercise('tums-19'), // Fitball Mountain Climber
          ],
          restAfterSection: 90,
          type: SectionType.superset,
        ),
        WorkoutSection(
          id: 'tums-005-section-4',
          name: 'Fitball Challenge',
          exercises: [
            _safeGetExercise('tums-24'), // Fitball Double Leg Hold
            _safeGetExercise('tums-28'), // Fitball Reverse Crunch
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'tums-005-section-5',
          name: 'Weighted Finisher',
          exercises: [
            _safeGetExercise('tum-30'),  // Dumbbell Crunch and Punch
          ],
          restAfterSection: 0,
          type: SectionType.normal,
        ),
      ],
    ),

    // Intermediate Workout 3
    Workout(
      id: 'tums-006',
      title: 'Core Blast Circuit',
      description:
          'A high-intensity circuit-based core workout that targets all areas of your midsection through a variety of dynamic and static exercises.',
      imageUrl: 'assets/images/workouts/core_blast_circuit.jpg',
      category: WorkoutCategory.tums,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 35,
      estimatedCaloriesBurn: 280,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
      createdBy: 'admin',
      equipment: ['mat', 'stability ball'],
      tags: ['intermediate', 'circuit', 'high intensity', 'core'],
      exercises: [
        _safeGetExercise('full-2'),  // Mountain Climber
        _safeGetExercise('tums-2'),  // Bicycle Crunch
        _safeGetExercise('tums-4'),  // Russian Twist
        _safeGetExercise('tums-9'),  // Sit Up
        _safeGetExercise('tums-12'), // Plank with Leg Lift
        _safeGetExercise('tums-15'), // Prone Flutter Kick
        _safeGetExercise('tums-17'), // Fitball Plank Hold
        _safeGetExercise('tums-23'), // Fitball Ball Pass
        _safeGetExercise('tums-25'), // Fitball Leg Lowering
      ],
      sections: [
        WorkoutSection(
          id: 'tums-006-section-1',
          name: 'Dynamic Warm-up',
          exercises: [
            _safeGetExercise('full-2'),  // Mountain Climber
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'tums-006-section-2',
          name: 'Core Circuit 1',
          exercises: [
            _safeGetExercise('tums-2'),  // Bicycle Crunch
            _safeGetExercise('tums-4'),  // Russian Twist
            _safeGetExercise('tums-9'),  // Sit Up
          ],
          restAfterSection: 90,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'tums-006-section-3',
          name: 'Core Circuit 2',
          exercises: [
            _safeGetExercise('tums-12'), // Plank with Leg Lift
            _safeGetExercise('tums-15'), // Prone Flutter Kick
            _safeGetExercise('tums-17'), // Fitball Plank Hold
          ],
          restAfterSection: 90,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'tums-006-section-4',
          name: 'Ball Finishers',
          exercises: [
            _safeGetExercise('tums-23'), // Fitball Ball Pass
            _safeGetExercise('tums-25'), // Fitball Leg Lowering
          ],
          restAfterSection: 0,
          type: SectionType.superset,
        ),
      ],
    ),
    
    // ADVANCED WORKOUTS
    
    // Advanced Workout 1
    Workout(
      id: 'tums-007',
      title: 'Ultimate Core Challenge',
      description:
          'An advanced core workout that pushes your limits with complex movements, stability challenges, and high-intensity exercises for maximum results.',
      imageUrl: 'assets/images/workouts/ultimate_core_challenge.jpg',
      category: WorkoutCategory.tums,
      difficulty: WorkoutDifficulty.advanced,
      durationMinutes: 45,
      estimatedCaloriesBurn: 350,
      featured: true,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      createdBy: 'admin',
      equipment: ['mat', 'stability ball', 'dumbbells'],
      tags: ['advanced', 'high intensity', 'core strength', 'stability challenge'],
      exercises: [
        _safeGetExercise('cardio-5'), // Burpee
        _safeGetExercise('tums-10'), // V-Up
        _safeGetExercise('tums-7'),  // Leg In and Out
        _safeGetExercise('tums-6'),  // Leg Drop
        _safeGetExercise('tums-14'), // Diagonal Plank
        _safeGetExercise('tums-18'), // Fitball Plank to Pike
        _safeGetExercise('tums-19'), // Fitball Mountain Climber
        _safeGetExercise('tums-26'), // Fitball Plank to Tuck
        _safeGetExercise('tums-23'), // Fitball Ball Pass
        _safeGetExercise('tum-30'),  // Dumbbell Crunch and Punch
      ],
      sections: [
        WorkoutSection(
          id: 'tums-007-section-1',
          name: 'Advanced Warm-up',
          exercises: [
            _safeGetExercise('cardio-5'), // Burpee
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'tums-007-section-2',
          name: 'Power Core',
          exercises: [
            _safeGetExercise('tums-10'), // V-Up
            _safeGetExercise('tums-7'),  // Leg In and Out
            _safeGetExercise('tums-6'),  // Leg Drop
          ],
          restAfterSection: 90,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'tums-007-section-3',
          name: 'Stability Challenge',
          exercises: [
            _safeGetExercise('tums-14'), // Diagonal Plank
            _safeGetExercise('tums-18'), // Fitball Plank to Pike
            _safeGetExercise('tums-19'), // Fitball Mountain Climber
          ],
          restAfterSection: 90,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'tums-007-section-4',
          name: 'Advanced Ball Work',
          exercises: [
            _safeGetExercise('tums-26'), // Fitball Plank to Tuck
            _safeGetExercise('tums-23'), // Fitball Ball Pass
          ],
          restAfterSection: 60,
          type: SectionType.superset,
        ),
        WorkoutSection(
          id: 'tums-007-section-5',
          name: 'Weighted Finisher',
          exercises: [
            _safeGetExercise('tum-30'),  // Dumbbell Crunch and Punch
          ],
          restAfterSection: 0,
          type: SectionType.normal,
        ),
      ],
    ),

    // Advanced Workout 2
    Workout(
      id: 'tums-008',
      title: 'Core Power & Stability',
      description:
          'Build exceptional core strength, stability, and power with this advanced workout that combines dynamic and static exercises for complete development.',
      imageUrl: 'assets/images/workouts/core_power_stability.jpg',
      category: WorkoutCategory.tums,
      difficulty: WorkoutDifficulty.advanced,
      durationMinutes: 50,
      estimatedCaloriesBurn: 380,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      createdBy: 'admin',
      equipment: ['mat', 'stability ball', 'dumbbells'],
      tags: ['advanced', 'power', 'stability', 'strength'],
      exercises: [
        _safeGetExercise('full-2'),  // Mountain Climber
        _safeGetExercise('tums-10'), // V-Up
        _safeGetExercise('tums-11'), // V Crunch
        _safeGetExercise('tums-14'), // Diagonal Plank
        _safeGetExercise('tums-7'),  // Leg In and Out
        _safeGetExercise('tums-18'), // Fitball Plank to Pike
        _safeGetExercise('tums-19'), // Fitball Mountain Climber
        _safeGetExercise('tums-23'), // Fitball Ball Pass
        _safeGetExercise('tums-25'), // Fitball Leg Lowering
        _safeGetExercise('tums-26'), // Fitball Plank to Tuck
        _safeGetExercise('full-15'), // Fitball Mountain Climber
      ],
      sections: [
        WorkoutSection(
          id: 'tums-008-section-1',
          name: 'Dynamic Warm-up',
          exercises: [
            _safeGetExercise('full-2'),  // Mountain Climber
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'tums-008-section-2',
          name: 'Intense Core',
          exercises: [
            _safeGetExercise('tums-10'), // V-Up
            _safeGetExercise('tums-11'), // V Crunch
            _safeGetExercise('tums-7'),  // Leg In and Out
          ],
          restAfterSection: 90,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'tums-008-section-3',
          name: 'Stability Work',
          exercises: [
            _safeGetExercise('tums-14'), // Diagonal Plank
            _safeGetExercise('tums-18'), // Fitball Plank to Pike
            _safeGetExercise('tums-19'), // Fitball Mountain Climber
          ],
          restAfterSection: 90,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'tums-008-section-4',
          name: 'Advanced Ball Circuit',
          exercises: [
            _safeGetExercise('tums-23'), // Fitball Ball Pass
            _safeGetExercise('tums-25'), // Fitball Leg Lowering
            _safeGetExercise('tums-26'), // Fitball Plank to Tuck
          ],
          restAfterSection: 60,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'tums-008-section-5',
          name: 'Metabolic Finisher',
          exercises: [
            _safeGetExercise('full-15'), // Fitball Mountain Climber (from full body)
          ],
          restAfterSection: 0,
          type: SectionType.normal,
        ),
      ],
    ),

    // Advanced Workout 3
    Workout(
      id: 'tums-009',
      title: 'Extreme Core Conditioning',
      description:
          'A high-intensity, advanced core workout that combines strength, power, and endurance training to push your abdominals to their limits.',
      imageUrl: 'assets/images/workouts/extreme_core_conditioning.jpg',
      category: WorkoutCategory.tums,
      difficulty: WorkoutDifficulty.advanced,
      durationMinutes: 45,
      estimatedCaloriesBurn: 400,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      createdBy: 'admin',
      equipment: ['mat', 'stability ball', 'dumbbells'],
      tags: ['advanced', 'conditioning', 'high intensity', 'endurance'],
      exercises: [
        _safeGetExercise('cardio-5'), // Burpee
        _safeGetExercise('tums-10'), // V-Up
        _safeGetExercise('tums-4'),  // Russian Twist
        _safeGetExercise('tums-6'),  // Leg Drop
        _safeGetExercise('tums-12'), // Plank with Leg Lift
        _safeGetExercise('tums-18'), // Fitball Plank to Pike
        _safeGetExercise('tums-19'), // Fitball Mountain Climber
        _safeGetExercise('tums-26'), // Fitball Plank to Tuck
        _safeGetExercise('tum-30'),  // Dumbbell Crunch and Punch
        _safeGetExercise('full-1'),  // Burpee (from full body)
      ],
      sections: [
        WorkoutSection(
          id: 'tums-009-section-1',
          name: 'Metabolic Warm-up',
          exercises: [
            _safeGetExercise('cardio-5'), // Burpee
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'tums-009-section-2',
          name: 'Power Core Circuit',
          exercises: [
            _safeGetExercise('tums-10'), // V-Up
            _safeGetExercise('tums-4'),  // Russian Twist
            _safeGetExercise('tums-6'),  // Leg Drop
          ],
         restAfterSection: 90,
         type: SectionType.circuit,
       ),
       WorkoutSection(
         id: 'tums-009-section-3',
         name: 'Plank Variations',
         exercises: [
           _safeGetExercise('tums-12'), // Plank with Leg Lift
           _safeGetExercise('tums-18'), // Fitball Plank to Pike
         ],
         restAfterSection: 90,
         type: SectionType.superset,
       ),
       WorkoutSection(
         id: 'tums-009-section-4',
         name: 'Dynamic Stability',
         exercises: [
           _safeGetExercise('tums-19'), // Fitball Mountain Climber
           _safeGetExercise('tums-26'), // Fitball Plank to Tuck
           _safeGetExercise('tum-30'),  // Dumbbell Crunch and Punch
         ],
         restAfterSection: 60,
         type: SectionType.circuit,
       ),
       WorkoutSection(
         id: 'tums-009-section-5',
         name: 'Explosive Finisher',
         exercises: [
           _safeGetExercise('full-1'),  // Burpee (from full body)
         ],
         restAfterSection: 0,
         type: SectionType.normal,
       ),
     ],
   ),
 ];
}