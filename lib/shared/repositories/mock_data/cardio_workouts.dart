// lib/shared/repositories/mock_data/cardio_workouts.dart
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
      targetArea: 'cardio',
    );
  }
}

// Cardio workouts with async initialization
Future<List<Workout>> getCardioWorkoutsAsync() async {
  await _ensureInitialized();
  return getCardioWorkouts();
}

// Cardio workouts
List<Workout> getCardioWorkouts() {
  if (!_initialized) {
    print('Warning: Accessing workouts before initialization is complete');
  }
  return [
    // BEGINNER WORKOUTS
    
    // Beginner Workout 1
    Workout(
      id: 'cardio-001',
      title: 'Beginner Cardio Kickstart',
      description:
          'A gentle introduction to cardio training with low-impact exercises perfect for beginners looking to improve endurance and heart health.',
      imageUrl: 'assets/images/workouts/beginner_cardio_kickstart.jpg',
      category: WorkoutCategory.cardio,
      difficulty: WorkoutDifficulty.beginner,
      durationMinutes: 20,
      estimatedCaloriesBurn: 150,
      featured: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      createdBy: 'admin',
      equipment: ['none'],
      tags: ['beginner', 'low impact', 'cardio', 'endurance'],
      exercises: [
        _safeGetExercise('cardio-1'), // Jumping Jacks
        _safeGetExercise('full-16'),  // Jumping Jacks (duplicate for circuit)
        _safeGetExercise('bums-13'),  // Squat
        _safeGetExercise('bums-17'),  // Lunge
        _safeGetExercise('full-2'),   // Mountain Climber
        _safeGetExercise('cardio-3'), // High Knees
        _safeGetExercise('arms-10'),  // Knee Push-Up
        _safeGetExercise('bums-1'),   // Glute Bridge
      ],
      hasAccessibilityOptions: true,
      intensityModifications: [
        'Perform all exercises at a comfortable pace',
        'Take additional rest as needed',
        'Reduce impact by stepping instead of jumping',
      ],
      sections: [
        WorkoutSection(
          id: 'cardio-001-section-1',
          name: 'Warm-up',
          exercises: [
            _safeGetExercise('cardio-1'), // Jumping Jacks
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'cardio-001-section-2',
          name: 'Cardio Circuit 1',
          exercises: [
            _safeGetExercise('bums-13'),  // Squat
            _safeGetExercise('bums-17'),  // Lunge
            _safeGetExercise('full-2'),   // Mountain Climber
          ],
          restAfterSection: 90,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'cardio-001-section-3',
          name: 'Cardio Circuit 2',
          exercises: [
            _safeGetExercise('cardio-3'), // High Knees
            _safeGetExercise('arms-10'),  // Knee Push-Up
            _safeGetExercise('bums-1'),   // Glute Bridge
          ],
          restAfterSection: 90,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'cardio-001-section-4',
          name: 'Cool Down',
          exercises: [
            _safeGetExercise('full-16'),  // Jumping Jacks (lighter intensity)
          ],
          restAfterSection: 0,
          type: SectionType.normal,
        ),
      ],
    ),

    // Beginner Workout 2
    Workout(
      id: 'cardio-002',
      title: 'Low-Impact Cardio Burn',
      description:
          'A beginner-friendly cardio workout focusing on low-impact movements that are gentle on the joints while still providing an effective cardiovascular challenge.',
      imageUrl: 'assets/images/workouts/low_impact_cardio_burn.jpg',
      category: WorkoutCategory.cardio,
      difficulty: WorkoutDifficulty.beginner,
      durationMinutes: 25,
      estimatedCaloriesBurn: 180,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 28)),
      createdBy: 'admin',
      equipment: ['mat', 'chair (optional)'],
      tags: ['beginner', 'low impact', 'joint-friendly', 'cardio'],
      exercises: [
        _safeGetExercise('cardio-1'), // Jumping Jacks
        _safeGetExercise('bums-13'),  // Squat
        _safeGetExercise('bums-15'),  // Chair Squat
        _safeGetExercise('full-8'),   // Bird Dog
        _safeGetExercise('full-2'),   // Mountain Climber
        _safeGetExercise('cardio-3'), // High Knees
        _safeGetExercise('tums-15'),  // Prone Flutter Kick
        _safeGetExercise('bums-33'),  // Standing Dumbbell Calf Raise
      ],
      hasAccessibilityOptions: true,
      intensityModifications: [
        'March in place instead of high knees',
        'Step out instead of jumping for jumping jacks',
        'Use a chair for support if needed',
      ],
      sections: [
        WorkoutSection(
          id: 'cardio-002-section-1',
          name: 'Gentle Warm-up',
          exercises: [
            _safeGetExercise('cardio-1'), // Jumping Jacks
            _safeGetExercise('full-8'),   // Bird Dog
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'cardio-002-section-2',
          name: 'Low-Impact Circuit 1',
          exercises: [
            _safeGetExercise('bums-13'),  // Squat
            _safeGetExercise('bums-15'),  // Chair Squat
            _safeGetExercise('full-2'),   // Mountain Climber
          ],
          restAfterSection: 90,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'cardio-002-section-3',
          name: 'Low-Impact Circuit 2',
          exercises: [
            _safeGetExercise('cardio-3'), // High Knees
            _safeGetExercise('tums-15'),  // Prone Flutter Kick
            _safeGetExercise('bums-33'),  // Standing Dumbbell Calf Raise
          ],
          restAfterSection: 0,
          type: SectionType.circuit,
        ),
      ],
    ),

    // Beginner Workout 3
    Workout(
      id: 'cardio-003',
      title: 'Cardio Endurance Builder',
      description:
          'Build cardiovascular endurance with this beginner-friendly workout that gradually introduces more challenging exercises while maintaining manageable intensity.',
      imageUrl: 'assets/images/workouts/cardio_endurance_builder.jpg',
      category: WorkoutCategory.cardio,
      difficulty: WorkoutDifficulty.beginner,
      durationMinutes: 30,
      estimatedCaloriesBurn: 200,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      createdBy: 'admin',
      equipment: ['mat'],
      tags: ['beginner', 'endurance', 'cardio', 'stamina'],
      exercises: [
        _safeGetExercise('cardio-1'), // Jumping Jacks
        _safeGetExercise('full-16'),  // Jumping Jacks (duplicate for sections)
        _safeGetExercise('bums-13'),  // Squat
        _safeGetExercise('full-2'),   // Mountain Climber
        _safeGetExercise('bums-17'),  // Lunge
        _safeGetExercise('cardio-3'), // High Knees
        _safeGetExercise('arms-10'),  // Knee Push-Up
        _safeGetExercise('tums-2'),   // Bicycle Crunch
        _safeGetExercise('bums-1'),   // Glute Bridge
      ],
      sections: [
        WorkoutSection(
          id: 'cardio-003-section-1',
          name: 'Warm-up',
          exercises: [
            _safeGetExercise('cardio-1'), // Jumping Jacks
            _safeGetExercise('bums-13'),  // Squat
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'cardio-003-section-2',
          name: 'Endurance Circuit 1',
          exercises: [
            _safeGetExercise('full-2'),   // Mountain Climber
            _safeGetExercise('bums-17'),  // Lunge
            _safeGetExercise('cardio-3'), // High Knees
          ],
          restAfterSection: 90,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'cardio-003-section-3',
          name: 'Endurance Circuit 2',
          exercises: [
            _safeGetExercise('arms-10'),  // Knee Push-Up
            _safeGetExercise('tums-2'),   // Bicycle Crunch
            _safeGetExercise('bums-1'),   // Glute Bridge
          ],
          restAfterSection: 90,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'cardio-003-section-4',
          name: 'Cool Down',
          exercises: [
            _safeGetExercise('full-16'),  // Jumping Jacks (at lower intensity)
          ],
          restAfterSection: 0,
          type: SectionType.normal,
        ),
      ],
    ),
    
    // INTERMEDIATE WORKOUTS
    
    // Intermediate Workout 1
    Workout(
      id: 'cardio-004',
      title: 'Cardio Blast',
      description:
          'An intermediate cardio workout that combines bodyweight exercises and plyometric movements to boost heart rate and maximize calorie burn.',
      imageUrl: 'assets/images/workouts/cardio_blast.jpg',
      category: WorkoutCategory.cardio,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 30,
      estimatedCaloriesBurn: 300,
      featured: true,
      createdAt: DateTime.now().subtract(const Duration(days: 22)),
      createdBy: 'admin',
      equipment: ['mat'],
      tags: ['intermediate', 'high intensity', 'cardio', 'fat burning'],
      exercises: [
        _safeGetExercise('cardio-1'), // Jumping Jacks
        _safeGetExercise('cardio-5'), // Burpee
        _safeGetExercise('full-2'),   // Mountain Climber
        _safeGetExercise('cardio-2'), // Jumping Squat
        _safeGetExercise('cardio-3'), // High Knees
        _safeGetExercise('bums-17'),  // Lunge
        _safeGetExercise('arms-11'),  // Push-Up
        _safeGetExercise('cardio-7'), // Skater Jumps
        _safeGetExercise('full-1'),   // Burpee (duplicate for sections)
      ],
      sections: [
        WorkoutSection(
          id: 'cardio-004-section-1',
          name: 'Dynamic Warm-up',
          exercises: [
            _safeGetExercise('cardio-1'), // Jumping Jacks
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'cardio-004-section-2',
          name: 'HIIT Circuit 1',
          exercises: [
            _safeGetExercise('cardio-5'), // Burpee
            _safeGetExercise('full-2'),   // Mountain Climber
            _safeGetExercise('cardio-2'), // Jumping Squat
          ],
          restAfterSection: 90,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'cardio-004-section-3',
          name: 'HIIT Circuit 2',
          exercises: [
            _safeGetExercise('cardio-3'), // High Knees
            _safeGetExercise('bums-17'),  // Lunge
            _safeGetExercise('arms-11'),  // Push-Up
          ],
          restAfterSection: 90,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'cardio-004-section-4',
          name: 'Finisher',
          exercises: [
            _safeGetExercise('cardio-7'), // Skater Jumps
            _safeGetExercise('full-1'),   // Burpee
          ],
          restAfterSection: 0,
          type: SectionType.superset,
        ),
      ],
    ),

    // Intermediate Workout 2
    Workout(
      id: 'cardio-005',
      title: 'Tabata Metabolic Booster',
      description:
          'A Tabata-inspired workout featuring 20 seconds of intense work followed by 10 seconds of rest to maximize metabolic impact and calorie burn.',
      imageUrl: 'assets/images/workouts/tabata_metabolic_booster.jpg',
      category: WorkoutCategory.cardio,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 25,
      estimatedCaloriesBurn: 280,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      createdBy: 'admin',
      equipment: ['mat', 'timer'],
      tags: ['intermediate', 'tabata', 'metabolic', 'interval training'],
      exercises: [
        _safeGetExercise('cardio-1'), // Jumping Jacks
        _safeGetExercise('cardio-5'), // Burpee
        _safeGetExercise('cardio-2'), // Jumping Squat
        _safeGetExercise('full-2'),   // Mountain Climber
        _safeGetExercise('cardio-3'), // High Knees
        _safeGetExercise('arms-11'),  // Push-Up
        _safeGetExercise('cardio-7'), // Skater Jumps
        _safeGetExercise('tums-2'),   // Bicycle Crunch
      ],
      sections: [
        WorkoutSection(
          id: 'cardio-005-section-1',
          name: 'Warm-up',
          exercises: [
            _safeGetExercise('cardio-1'), // Jumping Jacks
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'cardio-005-section-2',
          name: 'Tabata Round 1',
          exercises: [
            _safeGetExercise('cardio-5'), // Burpee
            _safeGetExercise('cardio-2'), // Jumping Squat
          ],
          restAfterSection: 60,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'cardio-005-section-3',
          name: 'Tabata Round 2',
          exercises: [
            _safeGetExercise('full-2'),   // Mountain Climber
            _safeGetExercise('cardio-3'), // High Knees
          ],
          restAfterSection: 60,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'cardio-005-section-4',
          name: 'Tabata Round 3',
          exercises: [
            _safeGetExercise('arms-11'),  // Push-Up
            _safeGetExercise('cardio-7'), // Skater Jumps
          ],
          restAfterSection: 60,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'cardio-005-section-5',
          name: 'Final Tabata',
          exercises: [
            _safeGetExercise('tums-2'),   // Bicycle Crunch
            _safeGetExercise('cardio-1'), // Jumping Jacks
          ],
          restAfterSection: 0,
          type: SectionType.circuit,
        ),
      ],
    ),

    // Intermediate Workout 3
    Workout(
      id: 'cardio-006',
      title: 'Cardio Strength Fusion',
      description:
          'Combines cardio intervals with strength movements for a balanced workout that improves both cardiovascular fitness and muscular endurance.',
      imageUrl: 'assets/images/workouts/cardio_strength_fusion.jpg',
      category: WorkoutCategory.cardio,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 35,
      estimatedCaloriesBurn: 320,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
      createdBy: 'admin',
      equipment: ['mat', 'dumbbells'],
      tags: ['intermediate', 'cardio and strength', 'conditioning', 'fusion'],
      exercises: [
        _safeGetExercise('cardio-1'),  // Jumping Jacks
        _safeGetExercise('cardio-5'),  // Burpee
        _safeGetExercise('bums-13'),   // Squat
        _safeGetExercise('bums-26'),   // Dumbbell Jumping Squat
        _safeGetExercise('arms-4'),    // Standing Dumbbell Curl
        _safeGetExercise('full-2'),    // Mountain Climber
        _safeGetExercise('arms-11'),   // Push-Up
        _safeGetExercise('cardio-3'),  // High Knees
        _safeGetExercise('bums-10'),   // Dumbbell Hip Hinge
        _safeGetExercise('cardio-7'),  // Skater Jumps
      ],
      sections: [
        WorkoutSection(
          id: 'cardio-006-section-1',
          name: 'Dynamic Warm-up',
          exercises: [
            _safeGetExercise('cardio-1'),  // Jumping Jacks
            _safeGetExercise('bums-13'),   // Squat
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'cardio-006-section-2',
          name: 'Cardio-Strength Pair 1',
          exercises: [
            _safeGetExercise('cardio-5'),  // Burpee
            _safeGetExercise('bums-26'),   // Dumbbell Jumping Squat
          ],
          restAfterSection: 90,
          type: SectionType.superset,
        ),
        WorkoutSection(
          id: 'cardio-006-section-3',
          name: 'Cardio-Strength Pair 2',
          exercises: [
            _safeGetExercise('full-2'),    // Mountain Climber
            _safeGetExercise('arms-4'),    // Standing Dumbbell Curl
          ],
          restAfterSection: 90,
          type: SectionType.superset,
        ),
        WorkoutSection(
          id: 'cardio-006-section-4',
          name: 'Cardio-Strength Pair 3',
          exercises: [
            _safeGetExercise('cardio-3'),  // High Knees
            _safeGetExercise('arms-11'),   // Push-Up
          ],
          restAfterSection: 90,
          type: SectionType.superset,
        ),
        WorkoutSection(
          id: 'cardio-006-section-5',
          name: 'Cardio-Strength Pair 4',
          exercises: [
            _safeGetExercise('cardio-7'),  // Skater Jumps
            _safeGetExercise('bums-10'),   // Dumbbell Hip Hinge
          ],
          restAfterSection: 0,
          type: SectionType.superset,
        ),
      ],
    ),
    
    // ADVANCED WORKOUTS
    
    // Advanced Workout 1
    Workout(
      id: 'cardio-007',
      title: 'High-Intensity Cardio Challenge',
      description:
          'An advanced, high-intensity cardio workout featuring plyometric exercises and minimal rest periods to maximize calorie burn and cardiovascular conditioning.',
      imageUrl: 'assets/images/workouts/high_intensity_cardio_challenge.jpg',
      category: WorkoutCategory.cardio,
      difficulty: WorkoutDifficulty.advanced,
      durationMinutes: 35,
      estimatedCaloriesBurn: 400,
      featured: true,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      createdBy: 'admin',
      equipment: ['mat'],
      tags: ['advanced', 'high intensity', 'plyometric', 'fat burning'],
      exercises: [
        _safeGetExercise('cardio-5'),  // Burpee
        _safeGetExercise('full-1'),    // Burpee (duplicate for sections)
        _safeGetExercise('cardio-2'),  // Jumping Squat
        _safeGetExercise('bums-16'),   // Jumping Squat (duplicate for sections)
        _safeGetExercise('cardio-6'),  // Jumping Lunge
        _safeGetExercise('full-2'),    // Mountain Climber
        _safeGetExercise('cardio-7'),  // Skater Jumps
        _safeGetExercise('full-15'),   // Fitball Mountain Climber
        _safeGetExercise('cardio-3'),  // High Knees
        _safeGetExercise('arms-11'),   // Push-Up
      ],
      sections: [
        WorkoutSection(
          id: 'cardio-007-section-1',
          name: 'Intense Warm-up',
          exercises: [
            _safeGetExercise('cardio-5'),  // Burpee
            _safeGetExercise('cardio-3'),  // High Knees
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'cardio-007-section-2',
          name: 'Plyometric Circuit 1',
          exercises: [
            _safeGetExercise('cardio-2'),  // Jumping Squat
            _safeGetExercise('cardio-6'),  // Jumping Lunge
            _safeGetExercise('cardio-7'),  // Skater Jumps
          ],
          restAfterSection: 60,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'cardio-007-section-3',
          name: 'Power Endurance Circuit',
          exercises: [
            _safeGetExercise('full-2'),    // Mountain Climber
            _safeGetExercise('arms-11'),   // Push-Up
            _safeGetExercise('full-15'),   // Fitball Mountain Climber
          ],
          restAfterSection: 60,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'cardio-007-section-4',
          name: 'Final Push',
          exercises: [
            _safeGetExercise('full-1'),    // Burpee
            _safeGetExercise('bums-16'),   // Jumping Squat
          ],
          restAfterSection: 0,
          type: SectionType.superset,
        ),
      ],
    ),

    // Advanced Workout 2
    Workout(
      id: 'cardio-008',
      title: 'Metabolic Conditioning Extreme',
      description:
          'An advanced metabolic conditioning workout that pushes your cardiovascular system to its limits while challenging muscular endurance.',
      imageUrl: 'assets/images/workouts/metabolic_conditioning_extreme.jpg',
      category: WorkoutCategory.cardio,
      difficulty: WorkoutDifficulty.advanced,
      durationMinutes: 40,
      estimatedCaloriesBurn: 450,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      createdBy: 'admin',
      equipment: ['mat', 'dumbbells', 'bench'],
      tags: ['advanced', 'metabolic conditioning', 'extreme', 'HIIT'],
      exercises: [
        _safeGetExercise('cardio-5'),  // Burpee
        _safeGetExercise('full-1'),    // Burpee (duplicate for sections)
        _safeGetExercise('bums-26'),   // Dumbbell Jumping Squat
        _safeGetExercise('cardio-6'),  // Jumping Lunge
        _safeGetExercise('full-10'),   // Medicine Ball Slams
        _safeGetExercise('full-2'),    // Mountain Climber
        _safeGetExercise('cardio-7'),  // Skater Jumps
        _safeGetExercise('arms-11'),   // Push-Up
        _safeGetExercise('bums-37'),   // Bulgarian Split Squat
        _safeGetExercise('full-9'),    // One Leg Push-Up
      ],
      sections: [
        WorkoutSection(
          id: 'cardio-008-section-1',
          name: 'Dynamic Warm-up',
          exercises: [
            _safeGetExercise('cardio-5'),  // Burpee
            _safeGetExercise('full-2'),    // Mountain Climber
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'cardio-008-section-2',
          name: 'Power Circuit',
          exercises: [
            _safeGetExercise('bums-26'),   // Dumbbell Jumping Squat
            _safeGetExercise('cardio-6'),  // Jumping Lunge
            _safeGetExercise('full-10'),   // Medicine Ball Slams
          ],
          restAfterSection: 60,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'cardio-008-section-3',
          name: 'Metabolic Circuit',
          exercises: [
            _safeGetExercise('cardio-7'),  // Skater Jumps
            _safeGetExercise('arms-11'),   // Push-Up
            _safeGetExercise('bums-37'),   // Bulgarian Split Squat
          ],
          restAfterSection: 60,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'cardio-008-section-4',
          name: 'Advanced Skills',
          exercises: [
            _safeGetExercise('full-9'),    // One Leg Push-Up
            _safeGetExercise('full-1'),    // Burpee
          ],
          restAfterSection: 0,
          type: SectionType.circuit,
        ),
      ],
    ),

    // Advanced Workout 3
    Workout(
      id: 'cardio-009',
      title: 'Cardio Power Intervals',
      description:
          'An advanced interval-based workout alternating between high-intensity cardio bursts and power movements for maximum calorie burn and performance enhancement.',
      imageUrl: 'assets/images/workouts/cardio_power_intervals.jpg',
      category: WorkoutCategory.cardio,
      difficulty: WorkoutDifficulty.advanced,
      durationMinutes: 45,
      estimatedCaloriesBurn: 500,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      createdBy: 'admin',
      equipment: ['mat', 'dumbbells', 'bench', 'medicine ball'],
      tags: ['advanced', 'interval training', 'power', 'athletic'],
      exercises: [
        _safeGetExercise('cardio-5'),  // Burpee
        _safeGetExercise('full-1'),    // Burpee (duplicate for sections)
        _safeGetExercise('bums-26'),   // Dumbbell Jumping Squat
        _safeGetExercise('bums-22'),   // Pistol Box Squat
        _safeGetExercise('cardio-6'),  // Jumping Lunge
        _safeGetExercise('full-10'),   // Medicine Ball Slams
        _safeGetExercise('cardio-7'),  // Skater Jumps
_safeGetExercise('arms-12'),   // Tiger Bend Push-Up
       _safeGetExercise('bums-37'),   // Bulgarian Split Squat
       _safeGetExercise('full-15'),   // Fitball Mountain Climber
     ],
     sections: [
       WorkoutSection(
         id: 'cardio-009-section-1',
         name: 'Dynamic Warm-up',
         exercises: [
           _safeGetExercise('cardio-5'),  // Burpee
         ],
         restAfterSection: 60,
         type: SectionType.normal,
       ),
       WorkoutSection(
         id: 'cardio-009-section-2',
         name: 'Power Interval 1',
         exercises: [
           _safeGetExercise('cardio-7'),  // Skater Jumps
           _safeGetExercise('bums-26'),   // Dumbbell Jumping Squat
         ],
         restAfterSection: 60,
         type: SectionType.superset,
       ),
       WorkoutSection(
         id: 'cardio-009-section-3',
         name: 'Power Interval 2',
         exercises: [
           _safeGetExercise('cardio-6'),  // Jumping Lunge
           _safeGetExercise('bums-22'),   // Pistol Box Squat
         ],
         restAfterSection: 60,
         type: SectionType.superset,
       ),
       WorkoutSection(
         id: 'cardio-009-section-4',
         name: 'Power Interval 3',
         exercises: [
           _safeGetExercise('full-1'),    // Burpee
           _safeGetExercise('full-10'),   // Medicine Ball Slams
         ],
         restAfterSection: 60,
         type: SectionType.superset,
       ),
       WorkoutSection(
         id: 'cardio-009-section-5',
         name: 'Advanced Skills Circuit',
         exercises: [
           _safeGetExercise('arms-12'),   // Tiger Bend Push-Up
           _safeGetExercise('bums-37'),   // Bulgarian Split Squat
           _safeGetExercise('full-15'),   // Fitball Mountain Climber
         ],
         restAfterSection: 0,
         type: SectionType.circuit,
       ),
     ],
   ),
 ];
}