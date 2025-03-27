// lib/shared/repositories/mock_data/quick_workouts.dart
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
      targetArea: 'quick',
    );
  }
}

// Quick workouts with async initialization
Future<List<Workout>> getQuickWorkoutsAsync() async {
  await _ensureInitialized();
  return getQuickWorkouts();
}

// Quick workouts
List<Workout> getQuickWorkouts() {
  if (!_initialized) {
    print('Warning: Accessing workouts before initialization is complete');
  }
  return [
    // 10-MINUTE WORKOUTS
    
    // Quick Workout 1: 10-Min Full Body
    Workout(
      id: 'quick-001',
      title: '10-Min Full Body Blast',
      description:
          'A quick but effective full-body workout that targets all major muscle groups in just 10 minutes. Perfect for busy days when you need a quick fitness boost.',
      imageUrl: 'assets/images/workouts/10min_full_body_blast.jpg',
      category: WorkoutCategory.quickWorkout,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 10,
      estimatedCaloriesBurn: 110,
      featured: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      createdBy: 'admin',
      equipment: ['mat', 'light dumbbells (optional)'],
      tags: ['quick', 'full body', 'high intensity', 'time-efficient'],
      exercises: [
        _safeGetExercise('cardio-5'), // Burpee
        _safeGetExercise('bums-13'),  // Squat
        _safeGetExercise('arms-11'),  // Push-Up
        _safeGetExercise('bums-17'),  // Lunge
        _safeGetExercise('tums-2'),   // Bicycle Crunch
        _safeGetExercise('full-2'),   // Mountain Climber
      ],
      sections: [
        WorkoutSection(
          id: 'quick-001-section-1',
          name: 'Quick Warm-up',
          exercises: [
            _safeGetExercise('cardio-5'), // Burpee
          ],
          restAfterSection: 30,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'quick-001-section-2',
          name: '10-Minute Circuit',
          exercises: [
            _safeGetExercise('bums-13'),  // Squat
            _safeGetExercise('arms-11'),  // Push-Up
            _safeGetExercise('bums-17'),  // Lunge
            _safeGetExercise('tums-2'),   // Bicycle Crunch
            _safeGetExercise('full-2'),   // Mountain Climber
          ],
          restAfterSection: 0,
          type: SectionType.circuit,
        ),
      ],
    ),

    // Quick Workout 2: 10-Min Core Focus
    Workout(
      id: 'quick-002',
      title: '10-Min Core Express',
      description:
          'A targeted 10-minute core workout that hits your abs, obliques, and lower back for quick but effective midsection training.',
      imageUrl: 'assets/images/workouts/10min_core_express.jpg',
      category: WorkoutCategory.quickWorkout,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 10,
      estimatedCaloriesBurn: 90,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 28)),
      createdBy: 'admin',
      equipment: ['mat'],
      tags: ['quick', 'core', 'abs', 'no equipment'],
      exercises: [
        _safeGetExercise('tums-2'),  // Bicycle Crunch
        _safeGetExercise('tums-3'),  // Straight Arm Plank
        _safeGetExercise('tums-4'),  // Russian Twist
        _safeGetExercise('tums-9'),  // Sit Up
        _safeGetExercise('tums-13'), // Dead Bug
        _safeGetExercise('full-6'),  // Superman
      ],
      sections: [
        WorkoutSection(
          id: 'quick-002-section-1',
          name: '10-Minute Core Circuit',
          exercises: [
            _safeGetExercise('tums-2'),  // Bicycle Crunch
            _safeGetExercise('tums-3'),  // Straight Arm Plank
            _safeGetExercise('tums-4'),  // Russian Twist
            _safeGetExercise('tums-9'),  // Sit Up
            _safeGetExercise('tums-13'), // Dead Bug
            _safeGetExercise('full-6'),  // Superman
          ],
          restAfterSection: 0,
          type: SectionType.circuit,
        ),
      ],
    ),

    // Quick Workout 3: 10-Min Lower Body
    Workout(
      id: 'quick-003',
      title: '10-Min Lower Body Burn',
      description:
          'Target your glutes, quads, and hamstrings with this quick but effective lower body workout you can do anywhere in just 10 minutes.',
      imageUrl: 'assets/images/workouts/10min_lower_body_burn.jpg',
      category: WorkoutCategory.quickWorkout,
      difficulty: WorkoutDifficulty.beginner,
      durationMinutes: 10,
      estimatedCaloriesBurn: 100,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      createdBy: 'admin',
      equipment: ['mat', 'chair (optional)'],
      tags: ['quick', 'lower body', 'glutes', 'beginner friendly'],
      exercises: [
        _safeGetExercise('bums-13'), // Squat
        _safeGetExercise('bums-17'), // Lunge
        _safeGetExercise('bums-1'),  // Glute Bridge
        _safeGetExercise('bums-6'),  // Fire Hydrant
        _safeGetExercise('bums-21'), // Plie Squat
        _safeGetExercise('bums-19'), // Side Lunge
      ],
      sections: [
        WorkoutSection(
          id: 'quick-003-section-1',
          name: '10-Minute Lower Body Circuit',
          exercises: [
            _safeGetExercise('bums-13'), // Squat
            _safeGetExercise('bums-17'), // Lunge
            _safeGetExercise('bums-1'),  // Glute Bridge
            _safeGetExercise('bums-6'),  // Fire Hydrant
            _safeGetExercise('bums-21'), // Plie Squat
            _safeGetExercise('bums-19'), // Side Lunge
          ],
          restAfterSection: 0,
          type: SectionType.circuit,
        ),
      ],
    ),
    
    // 15-MINUTE WORKOUTS
    
    // Quick Workout 4: 15-Min HIIT
    Workout(
      id: 'quick-004',
      title: '15-Min HIIT Express',
      description:
          'A high-intensity interval training workout that delivers maximum calorie burn and cardiovascular benefits in just 15 minutes.',
      imageUrl: 'assets/images/workouts/15min_hiit_express.jpg',
      category: WorkoutCategory.quickWorkout,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 15,
      estimatedCaloriesBurn: 180,
      featured: true,
      createdAt: DateTime.now().subtract(const Duration(days: 22)),
      createdBy: 'admin',
      equipment: ['mat'],
      tags: ['quick', 'hiit', 'cardio', 'fat burning'],
      exercises: [
        _safeGetExercise('cardio-1'), // Jumping Jacks
        _safeGetExercise('cardio-5'), // Burpee
        _safeGetExercise('cardio-2'), // Jumping Squat
        _safeGetExercise('full-2'),   // Mountain Climber
        _safeGetExercise('cardio-6'), // Jumping Lunge
        _safeGetExercise('cardio-3'), // High Knees
        _safeGetExercise('cardio-7'), // Skater Jumps
      ],
      sections: [
        WorkoutSection(
          id: 'quick-004-section-1',
          name: 'Warm-up',
          exercises: [
            _safeGetExercise('cardio-1'), // Jumping Jacks
          ],
          restAfterSection: 30,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'quick-004-section-2',
          name: 'HIIT Circuit',
          exercises: [
            _safeGetExercise('cardio-5'), // Burpee
            _safeGetExercise('cardio-2'), // Jumping Squat
            _safeGetExercise('full-2'),   // Mountain Climber
            _safeGetExercise('cardio-6'), // Jumping Lunge
            _safeGetExercise('cardio-3'), // High Knees
            _safeGetExercise('cardio-7'), // Skater Jumps
          ],
          restAfterSection: 0,
          type: SectionType.circuit,
        ),
      ],
    ),

    // Quick Workout 5: 15-Min Full Body Strength
    Workout(
      id: 'quick-005',
      title: '15-Min Strength Builder',
      description:
          'A quick but effective strength-focused workout targeting all major muscle groups using just your bodyweight and minimal equipment.',
      imageUrl: 'assets/images/workouts/15min_strength_builder.jpg',
      category: WorkoutCategory.quickWorkout,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 15,
      estimatedCaloriesBurn: 150,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      createdBy: 'admin',
      equipment: ['mat', 'dumbbells'],
      tags: ['quick', 'strength', 'dumbbell', 'full body'],
      exercises: [
        _safeGetExercise('cardio-1'),  // Jumping Jacks
        _safeGetExercise('bums-10'),   // Dumbbell Hip Hinge
        _safeGetExercise('bums-13'),   // Squat
        _safeGetExercise('arms-4'),    // Standing Dumbbell Curl
        _safeGetExercise('arms-11'),   // Push-Up
        _safeGetExercise('arms-2'),    // Dumbbell Tricep Kickback
        _safeGetExercise('tums-3'),    // Straight Arm Plank
      ],
      sections: [
        WorkoutSection(
          id: 'quick-005-section-1',
          name: 'Warm-up',
          exercises: [
            _safeGetExercise('cardio-1'),  // Jumping Jacks
          ],
          restAfterSection: 30,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'quick-005-section-2',
          name: '15-Min Strength Circuit',
          exercises: [
            _safeGetExercise('bums-10'),   // Dumbbell Hip Hinge
            _safeGetExercise('bums-13'),   // Squat
            _safeGetExercise('arms-4'),    // Standing Dumbbell Curl
            _safeGetExercise('arms-11'),   // Push-Up
            _safeGetExercise('arms-2'),    // Dumbbell Tricep Kickback
            _safeGetExercise('tums-3'),    // Straight Arm Plank
          ],
          restAfterSection: 0,
          type: SectionType.circuit,
        ),
      ],
    ),

    // Quick Workout 6: 15-Min Morning Energizer
    Workout(
      id: 'quick-006',
      title: '15-Min Morning Energizer',
      description:
          'Start your day right with this quick but comprehensive morning workout designed to boost energy levels and kickstart your metabolism.',
      imageUrl: 'assets/images/workouts/15min_morning_energizer.jpg',
      category: WorkoutCategory.quickWorkout,
      difficulty: WorkoutDifficulty.beginner,
      durationMinutes: 15,
      estimatedCaloriesBurn: 130,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
      createdBy: 'admin',
      equipment: ['mat'],
      tags: ['quick', 'morning', 'energizing', 'no equipment'],
      exercises: [
        _safeGetExercise('cardio-1'), // Jumping Jacks
        _safeGetExercise('bums-13'),  // Squat
        _safeGetExercise('bums-17'),  // Lunge
        _safeGetExercise('arms-10'),  // Knee Push-Up
        _safeGetExercise('tums-13'),  // Dead Bug
        _safeGetExercise('full-6'),   // Superman
        _safeGetExercise('cardio-3'), // High Knees
      ],
      sections: [
        WorkoutSection(
          id: 'quick-006-section-1',
          name: 'Dynamic Warm-up',
          exercises: [
            _safeGetExercise('cardio-1'), // Jumping Jacks
          ],
          restAfterSection: 30,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'quick-006-section-2',
          name: 'Morning Circuit',
          exercises: [
            _safeGetExercise('bums-13'),  // Squat
            _safeGetExercise('bums-17'),  // Lunge
            _safeGetExercise('arms-10'),  // Knee Push-Up
            _safeGetExercise('tums-13'),  // Dead Bug
            _safeGetExercise('full-6'),   // Superman
            _safeGetExercise('cardio-3'), // High Knees
          ],
          restAfterSection: 0,
          type: SectionType.circuit,
        ),
      ],
    ),
    
    // 20-MINUTE WORKOUTS
    
    // Quick Workout 7: 20-Min Total Body
    Workout(
      id: 'quick-007',
      title: '20-Min Total Body Sculptor',
      description:
          'A comprehensive 20-minute workout that combines strength, cardio, and core exercises for total body conditioning with minimal time investment.',
      imageUrl: 'assets/images/workouts/20min_total_body_sculptor.jpg',
      category: WorkoutCategory.quickWorkout,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 20,
      estimatedCaloriesBurn: 200,
      featured: true,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      createdBy: 'admin',
      equipment: ['mat', 'dumbbells'],
      tags: ['quick', 'total body', 'sculpting', 'strength and cardio'],
      exercises: [
        _safeGetExercise('cardio-5'), // Burpee
        _safeGetExercise('bums-27'),  // Dumbbell Lunge
        _safeGetExercise('bums-10'),  // Dumbbell Hip Hinge
        _safeGetExercise('arms-5'),   // Dumbbell Rear Delt Row
        _safeGetExercise('arms-4'),   // Standing Dumbbell Curl
        _safeGetExercise('tums-2'),   // Bicycle Crunch
        _safeGetExercise('tums-4'),   // Russian Twist
        _safeGetExercise('cardio-2'), // Jumping Squat
      ],
      sections: [
        WorkoutSection(
          id: 'quick-007-section-1',
          name: 'Warm-up',
          exercises: [
            _safeGetExercise('cardio-5'), // Burpee
          ],
          restAfterSection: 30,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'quick-007-section-2',
          name: 'Lower Body',
          exercises: [
            _safeGetExercise('bums-27'),  // Dumbbell Lunge
            _safeGetExercise('bums-10'),  // Dumbbell Hip Hinge
          ],
          restAfterSection: 30,
          type: SectionType.superset,
        ),
        WorkoutSection(
          id: 'quick-007-section-3',
          name: 'Upper Body',
          exercises: [
            _safeGetExercise('arms-5'),   // Dumbbell Rear Delt Row
            _safeGetExercise('arms-4'),   // Standing Dumbbell Curl
          ],
          restAfterSection: 30,
          type: SectionType.superset,
        ),
        WorkoutSection(
          id: 'quick-007-section-4',
          name: 'Core',
          exercises: [
            _safeGetExercise('tums-2'),   // Bicycle Crunch
            _safeGetExercise('tums-4'),   // Russian Twist
          ],
          restAfterSection: 30,
          type: SectionType.superset,
        ),
        WorkoutSection(
          id: 'quick-007-section-5',
          name: 'Cardio Finisher',
          exercises: [
            _safeGetExercise('cardio-2'), // Jumping Squat
          ],
          restAfterSection: 0,
          type: SectionType.normal,
        ),
      ],
    ),

    // Quick Workout 8: 20-Min Booty Blast
    Workout(
      id: 'quick-008',
      title: '20-Min Booty Blast',
      description:
          'A targeted 20-minute workout focused on your glutes and lower body, perfect for when you need an efficient but effective bum-toning session.',
      imageUrl: 'assets/images/workouts/20min_booty_blast.jpg',
      category: WorkoutCategory.quickWorkout,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 20,
      estimatedCaloriesBurn: 190,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      createdBy: 'admin',
      equipment: ['mat', 'resistance band', 'dumbbells (optional)'],
      tags: ['quick', 'glutes', 'lower body', 'toning'],
      exercises: [
        _safeGetExercise('cardio-1'), // Jumping Jacks
        _safeGetExercise('bums-1'),   // Glute Bridge
        _safeGetExercise('bums-13'),  // Squat
        _safeGetExercise('bums-17'),  // Lunge
        _safeGetExercise('bums-21'),  // Plie Squat
        _safeGetExercise('bums-4'),   // Glute Kickback
        _safeGetExercise('bums-6'),   // Fire Hydrant
        _safeGetExercise('bums-7'),   // Side Leg Lift
        _safeGetExercise('bums-9'),   // Dumbbell Donkey Kick
      ],
      sections: [
        WorkoutSection(
          id: 'quick-008-section-1',
          name: 'Warm-up',
          exercises: [
            _safeGetExercise('cardio-1'), // Jumping Jacks
            _safeGetExercise('bums-1'),   // Glute Bridge
          ],
          restAfterSection: 30,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'quick-008-section-2',
          name: 'Standing Glute Circuit',
          exercises: [
            _safeGetExercise('bums-13'),  // Squat
            _safeGetExercise('bums-17'),  // Lunge
            _safeGetExercise('bums-21'),  // Plie Squat
          ],
          restAfterSection: 45,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'quick-008-section-3',
          name: 'Floor Glute Circuit',
          exercises: [
            _safeGetExercise('bums-4'),   // Glute Kickback
            _safeGetExercise('bums-6'),   // Fire Hydrant
            _safeGetExercise('bums-7'),   // Side Leg Lift
          ],
          restAfterSection: 45,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'quick-008-section-4',
          name: 'Finisher',
          exercises: [
            _safeGetExercise('bums-9'),   // Dumbbell Donkey Kick
          ],
          restAfterSection: 0,
          type: SectionType.normal,
        ),
      ],
    ),

    // Quick Workout 9: 20-Min Core Challenge
    Workout(
      id: 'quick-009',
      title: '20-Min Core Challenge',
      description:
          'An intense 20-minute core workout that targets your abs, obliques, and lower back from multiple angles for a complete midsection challenge.',
      imageUrl: 'assets/images/workouts/20min_core_challenge.jpg',
      category: WorkoutCategory.quickWorkout,
      difficulty: WorkoutDifficulty.advanced,
      durationMinutes: 20,
      estimatedCaloriesBurn: 180,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      createdBy: 'admin',
      equipment: ['mat', 'stability ball (optional)'],
      tags: ['quick', 'core', 'abs', 'advanced', 'challenge'],
      exercises: [
        _safeGetExercise('full-2'),   // Mountain Climber
        _safeGetExercise('tums-2'),   // Bicycle Crunch
        _safeGetExercise('tums-3'),   // Straight Arm Plank
        _safeGetExercise('tums-4'),   // Russian Twist
        _safeGetExercise('tums-6'),   // Leg Drop
        _safeGetExercise('tums-7'),   // Leg In and Out
        _safeGetExercise('tums-10'),  // V-Up
        _safeGetExercise('tums-11'),  // V Crunch
        _safeGetExercise('tums-14'),  // Diagonal Plank
        _safeGetExercise('full-7'),   // Swimmer and Superman
      ],
      sections: [
        WorkoutSection(
          id: 'quick-009-section-1',
          name: 'Dynamic Warm-up',
          exercises: [
            _safeGetExercise('full-2'),   // Mountain Climber
          ],
          restAfterSection: 30,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'quick-009-section-2',
          name: 'Core Circuit 1',
          exercises: [
            _safeGetExercise('tums-2'),   // Bicycle Crunch
            _safeGetExercise('tums-3'),   // Straight Arm Plank
            _safeGetExercise('tums-4'),   // Russian Twist
          ],
          restAfterSection: 45,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'quick-009-section-3',
          name: 'Core Circuit 2',
          exercises: [
            _safeGetExercise('tums-6'),   // Leg Drop
            _safeGetExercise('tums-7'),   // Leg In and Out
            _safeGetExercise('tums-10'),  // V-Up
          ],
          restAfterSection: 45,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'quick-009-section-4',
          name: 'Final Circuit',
          exercises: [
            _safeGetExercise('tums-11'),  // V Crunch
            _safeGetExercise('tums-14'),  // Diagonal Plank
            _safeGetExercise('full-7'),   // Swimmer and Superman
          ],
          restAfterSection: 0,
          type: SectionType.circuit,
        ),
      ],
    ),
  ];
}