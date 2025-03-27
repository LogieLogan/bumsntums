// lib/shared/repositories/mock_data/full_body_workouts.dart
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
      targetArea: 'full',
    );
  }
}

// Full body workouts with async initialization
Future<List<Workout>> getFullBodyWorkoutsAsync() async {
  await _ensureInitialized();
  return getFullBodyWorkouts();
}

// Full body workouts
List<Workout> getFullBodyWorkouts() {
  if (!_initialized) {
    print('Warning: Accessing workouts before initialization is complete');
  }
  return [
    // BEGINNER WORKOUTS
    
    // Beginner Workout 1
    Workout(
      id: 'full-001',
      title: 'Total Body Essentials',
      description:
          'A beginner-friendly total body workout that teaches fundamental movement patterns while building strength and endurance in all major muscle groups.',
      imageUrl: 'assets/images/workouts/total_body_essentials.jpg',
      category: WorkoutCategory.fullBody,
      difficulty: WorkoutDifficulty.beginner,
      durationMinutes: 30,
      estimatedCaloriesBurn: 200,
      featured: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      createdBy: 'admin',
      equipment: ['mat', 'light dumbbells (optional)'],
      tags: ['beginner', 'total body', 'fundamentals', 'strength'],
      exercises: [
        _safeGetExercise('cardio-1'), // Jumping Jacks
        _safeGetExercise('full-8'),  // Bird Dog
        _safeGetExercise('bums-13'), // Squat
        _safeGetExercise('bums-15'), // Chair Squat
        _safeGetExercise('arms-13'), // Wall Push-Up
        _safeGetExercise('tums-1'),  // Abdominal Crunch
        _safeGetExercise('bums-1'),  // Glute Bridge
        _safeGetExercise('bums-17'), // Lunge
        _safeGetExercise('full-6'),  // Superman
      ],
      hasAccessibilityOptions: true,
      intensityModifications: [
        'Reduce reps or sets as needed',
        'Take longer rest periods between exercises',
        'Use chair or wall for support when needed',
      ],
      sections: [
        WorkoutSection(
          id: 'full-001-section-1',
          name: 'Warm-up',
          exercises: [
            _safeGetExercise('cardio-1'), // Jumping Jacks
            _safeGetExercise('full-8'),  // Bird Dog
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'full-001-section-2',
          name: 'Lower Body',
          exercises: [
            _safeGetExercise('bums-15'), // Chair Squat
            _safeGetExercise('bums-1'),  // Glute Bridge
            _safeGetExercise('bums-17'), // Lunge
          ],
          restAfterSection: 90,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'full-001-section-3',
          name: 'Upper Body & Core',
          exercises: [
            _safeGetExercise('arms-13'), // Wall Push-Up
            _safeGetExercise('tums-1'),  // Abdominal Crunch
            _safeGetExercise('full-6'),  // Superman
          ],
          restAfterSection: 0,
          type: SectionType.normal,
        ),
      ],
    ),

    // Beginner Workout 2
    Workout(
      id: 'full-002',
      title: 'Functional Foundations',
      description:
          'Build functional fitness with this beginner-friendly full body workout that emphasizes movement quality and core stability.',
      imageUrl: 'assets/images/workouts/functional_foundations.jpg',
      category: WorkoutCategory.fullBody,
      difficulty: WorkoutDifficulty.beginner,
      durationMinutes: 35,
      estimatedCaloriesBurn: 230,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 28)),
      createdBy: 'admin',
      equipment: ['mat', 'light dumbbells', 'chair'],
      tags: ['beginner', 'functional', 'movement patterns', 'core stability'],
      exercises: [
        _safeGetExercise('cardio-1'), // Jumping Jacks
        _safeGetExercise('full-16'), // Jumping Jacks (duplicate for warm-up)
        _safeGetExercise('bums-13'), // Squat
        _safeGetExercise('arms-12'), // Box Push-Up
        _safeGetExercise('arms-10'), // Knee Push-Up
        _safeGetExercise('tums-3'),  // Straight Arm Plank
        _safeGetExercise('bums-17'), // Lunge
        _safeGetExercise('arms-4'),  // Standing Dumbbell Curl
        _safeGetExercise('full-7'),  // Swimmer and Superman
        _safeGetExercise('tums-13'), // Dead Bug
      ],
      hasAccessibilityOptions: true,
      intensityModifications: [
        'Modify exercises as needed for comfort',
        'Use lighter weights or bodyweight only',
        'Focus on form rather than repetitions',
      ],
      sections: [
        WorkoutSection(
          id: 'full-002-section-1',
          name: 'Dynamic Warm-up',
          exercises: [
            _safeGetExercise('cardio-1'), // Jumping Jacks
            _safeGetExercise('tums-13'), // Dead Bug
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'full-002-section-2',
          name: 'Lower Body Focus',
          exercises: [
            _safeGetExercise('bums-13'), // Squat
            _safeGetExercise('bums-17'), // Lunge
          ],
          restAfterSection: 90,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'full-002-section-3',
          name: 'Upper Body Focus',
          exercises: [
            _safeGetExercise('arms-12'), // Box Push-Up
            _safeGetExercise('arms-4'),  // Standing Dumbbell Curl
          ],
          restAfterSection: 90,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'full-002-section-4',
          name: 'Core & Stability',
          exercises: [
            _safeGetExercise('tums-3'),  // Straight Arm Plank
            _safeGetExercise('full-7'),  // Swimmer and Superman
          ],
          restAfterSection: 0,
          type: SectionType.normal,
        ),
      ],
    ),

    // Beginner Workout 3
    Workout(
      id: 'full-003',
      title: 'Simple Circuit Training',
      description:
          'A beginner-friendly circuit workout that builds strength and endurance while keeping your heart rate elevated for improved fitness.',
      imageUrl: 'assets/images/workouts/simple_circuit_training.jpg',
      category: WorkoutCategory.fullBody,
      difficulty: WorkoutDifficulty.beginner,
      durationMinutes: 30,
      estimatedCaloriesBurn: 220,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      createdBy: 'admin',
      equipment: ['mat', 'light dumbbells'],
      tags: ['beginner', 'circuit', 'endurance', 'full body'],
      exercises: [
        _safeGetExercise('cardio-1'), // Jumping Jacks
        _safeGetExercise('bums-15'), // Chair Squat
        _safeGetExercise('arms-13'), // Wall Push-Up
        _safeGetExercise('tums-13'), // Dead Bug
        _safeGetExercise('bums-33'), // Standing Dumbbell Calf Raise
        _safeGetExercise('arms-4'),  // Standing Dumbbell Curl
        _safeGetExercise('tums-1'),  // Abdominal Crunch
        _safeGetExercise('full-6'),  // Superman
        _safeGetExercise('bums-1'),  // Glute Bridge
      ],
      sections: [
        WorkoutSection(
          id: 'full-003-section-1',
          name: 'Warm-up',
          exercises: [
            _safeGetExercise('cardio-1'), // Jumping Jacks
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'full-003-section-2',
          name: 'Full Body Circuit',
          exercises: [
            _safeGetExercise('bums-15'), // Chair Squat
            _safeGetExercise('arms-13'), // Wall Push-Up
            _safeGetExercise('tums-13'), // Dead Bug
            _safeGetExercise('bums-33'), // Standing Dumbbell Calf Raise
            _safeGetExercise('arms-4'),  // Standing Dumbbell Curl
          ],
          restAfterSection: 90,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'full-003-section-3',
          name: 'Core & Stability Finisher',
          exercises: [
            _safeGetExercise('tums-1'),  // Abdominal Crunch
            _safeGetExercise('full-6'),  // Superman
            _safeGetExercise('bums-1'),  // Glute Bridge
          ],
          restAfterSection: 0,
          type: SectionType.normal,
        ),
      ],
    ),
    
    // INTERMEDIATE WORKOUTS
    
    // Intermediate Workout 1
    Workout(
      id: 'full-004',
      title: 'Total Body Conditioning',
      description:
          'Build strength, endurance, and definition throughout your entire body with this comprehensive intermediate workout.',
      imageUrl: 'assets/images/workouts/total_body_conditioning.jpg',
      category: WorkoutCategory.fullBody,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 45,
      estimatedCaloriesBurn: 320,
      featured: true,
      createdAt: DateTime.now().subtract(const Duration(days: 22)),
      createdBy: 'admin',
      equipment: ['mat', 'dumbbells', 'stability ball (optional)'],
      tags: ['intermediate', 'strength', 'conditioning', 'full body'],
      exercises: [
        _safeGetExercise('full-2'),   // Mountain Climber
        _safeGetExercise('bums-13'),  // Squat
        _safeGetExercise('bums-21'),  // Plie Squat
        _safeGetExercise('bums-27'),  // Dumbbell Lunge
        _safeGetExercise('arms-11'),  // Push-Up
        _safeGetExercise('arms-5'),   // Dumbbell Rear Delt Row
        _safeGetExercise('tums-2'),   // Bicycle Crunch
        _safeGetExercise('tums-3'),   // Straight Arm Plank
        _safeGetExercise('bums-10'),  // Dumbbell Hip Hinge
        _safeGetExercise('full-11'),  // Box Push-Up
        _safeGetExercise('cardio-3'), // High Knees
      ],
      sections: [
        WorkoutSection(
          id: 'full-004-section-1',
          name: 'Dynamic Warm-up',
          exercises: [
            _safeGetExercise('full-2'),   // Mountain Climber
            _safeGetExercise('cardio-3'), // High Knees
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'full-004-section-2',
          name: 'Lower Body',
          exercises: [
            _safeGetExercise('bums-13'),  // Squat
            _safeGetExercise('bums-21'),  // Plie Squat
            _safeGetExercise('bums-27'),  // Dumbbell Lunge
          ],
          restAfterSection: 90,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'full-004-section-3',
          name: 'Upper Body',
          exercises: [
            _safeGetExercise('arms-11'),  // Push-Up
            _safeGetExercise('arms-5'),   // Dumbbell Rear Delt Row
          ],
          restAfterSection: 90,
          type: SectionType.superset,
        ),
        WorkoutSection(
          id: 'full-004-section-4',
          name: 'Core',
          exercises: [
            _safeGetExercise('tums-2'),   // Bicycle Crunch
            _safeGetExercise('tums-3'),   // Straight Arm Plank
          ],
          restAfterSection: 90,
          type: SectionType.superset,
        ),
        WorkoutSection(
          id: 'full-004-section-5',
          name: 'Finisher',
          exercises: [
            _safeGetExercise('bums-10'),  // Dumbbell Hip Hinge
          ],
          restAfterSection: 0,
          type: SectionType.normal,
        ),
      ],
    ),

    // Intermediate Workout 2
    Workout(
      id: 'full-005',
      title: 'Strength & Power Circuit',
      description:
          'Develop functional strength and power with this circuit-based workout that keeps your heart rate elevated while building total-body muscle.',
      imageUrl: 'assets/images/workouts/strength_power_circuit.jpg',
      category: WorkoutCategory.fullBody,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 40,
      estimatedCaloriesBurn: 350,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      createdBy: 'admin',
      equipment: ['mat', 'dumbbells', 'bench or step'],
      tags: ['intermediate', 'circuit', 'power', 'strength'],
      exercises: [
        _safeGetExercise('cardio-5'), // Burpee
        _safeGetExercise('bums-26'),  // Dumbbell Jumping Squat
        _safeGetExercise('bums-29'),  // Dumbbell Single Leg Deadlift
        _safeGetExercise('full-12'),  // Plank and Reach
        _safeGetExercise('arms-1'),   // Dumbbell Bench Press
        _safeGetExercise('arms-4'),   // Standing Dumbbell Curl
        _safeGetExercise('tums-10'),  // V-Up
        _safeGetExercise('full-7'),   // Swimmer and Superman
        _safeGetExercise('bums-23'),  // Step Up Exercise
        _safeGetExercise('tums-4'),   // Russian Twist
      ],
      sections: [
        WorkoutSection(
          id: 'full-005-section-1',
          name: 'Metabolic Warm-up',
          exercises: [
            _safeGetExercise('cardio-5'), // Burpee
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'full-005-section-2',
          name: 'Lower Body Power',
          exercises: [
            _safeGetExercise('bums-26'),  // Dumbbell Jumping Squat
            _safeGetExercise('bums-29'),  // Dumbbell Single Leg Deadlift
            _safeGetExercise('bums-23'),  // Step Up Exercise
          ],
          restAfterSection: 90,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'full-005-section-3',
          name: 'Upper Body Strength',
          exercises: [
            _safeGetExercise('arms-1'),   // Dumbbell Bench Press
            _safeGetExercise('arms-4'),   // Standing Dumbbell Curl
          ],
          restAfterSection: 90,
          type: SectionType.superset,
        ),
        WorkoutSection(
          id: 'full-005-section-4',
          name: 'Core & Stability',
          exercises: [
            _safeGetExercise('full-12'),  // Plank and Reach
            _safeGetExercise('tums-10'),  // V-Up
            _safeGetExercise('tums-4'),   // Russian Twist
            _safeGetExercise('full-7'),   // Swimmer and Superman
          ],
          restAfterSection: 0,
          type: SectionType.circuit,
        ),
      ],
    ),

    // Intermediate Workout 3
    Workout(
      id: 'full-006',
      title: 'Balanced Body Blast',
      description:
          'A balanced full-body workout that targets all major muscle groups while improving cardiovascular fitness through strategic exercise pairings.',
      imageUrl: 'assets/images/workouts/balanced_body_blast.jpg',
      category: WorkoutCategory.fullBody,
      difficulty: WorkoutDifficulty.intermediate,
      durationMinutes: 45,
      estimatedCaloriesBurn: 340,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
      createdBy: 'admin',
      equipment: ['mat', 'dumbbells', 'stability ball'],
      tags: ['intermediate', 'balanced', 'cardio', 'strength'],
      exercises: [
        _safeGetExercise('full-2'),   // Mountain Climber
        _safeGetExercise('bums-10'),  // Dumbbell Hip Hinge
        _safeGetExercise('bums-28'),  // Dumbbell Plie Squat
        _safeGetExercise('arms-5'),   // Dumbbell Rear Delt Row
        _safeGetExercise('arms-2'),   // Dumbbell Tricep Kickback
        _safeGetExercise('tums-16'),  // Fitball Crunch
        _safeGetExercise('full-14'),  // Fitball Pushup
        _safeGetExercise('tums-17'),  // Fitball Plank Hold
        _safeGetExercise('bums-32'),  // Fitball Single Leg Roll
        _safeGetExercise('cardio-2'), // Jumping Squat
      ],
      sections: [
        WorkoutSection(
          id: 'full-006-section-1',
          name: 'Dynamic Warm-up',
          exercises: [
            _safeGetExercise('full-2'),   // Mountain Climber
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'full-006-section-2',
          name: 'Lower Body Strength',
          exercises: [
            _safeGetExercise('bums-10'),  // Dumbbell Hip Hinge
            _safeGetExercise('bums-28'),  // Dumbbell Plie Squat
          ],
          restAfterSection: 90,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'full-006-section-3',
          name: 'Upper Body Strength',
          exercises: [
            _safeGetExercise('arms-5'),   // Dumbbell Rear Delt Row
            _safeGetExercise('arms-2'),   // Dumbbell Tricep Kickback
          ],
          restAfterSection: 90,
          type: SectionType.superset,
        ),
        WorkoutSection(
          id: 'full-006-section-4',
          name: 'Core & Stability',
          exercises: [
            _safeGetExercise('tums-16'),  // Fitball Crunch
            _safeGetExercise('full-14'),  // Fitball Pushup
            _safeGetExercise('tums-17'),  // Fitball Plank Hold
            _safeGetExercise('bums-32'),  // Fitball Single Leg Roll
          ],
          restAfterSection: 90,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'full-006-section-5',
          name: 'Metabolic Finisher',
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
      id: 'full-007',
      title: 'Total Body Transformation',
      description:
          'A high-intensity, advanced full body workout designed to build strength, power, and endurance while maximizing calorie burn.',
      imageUrl: 'assets/images/workouts/total_body_transformation.jpg',
      category: WorkoutCategory.fullBody,
      difficulty: WorkoutDifficulty.advanced,
      durationMinutes: 50,
      estimatedCaloriesBurn: 450,
      featured: true,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      createdBy: 'admin',
      equipment: ['mat', 'heavy dumbbells', 'bench', 'stability ball'],
      tags: ['advanced', 'high intensity', 'strength', 'power', 'endurance'],
      exercises: [
        _safeGetExercise('cardio-5'),  // Burpee
        _safeGetExercise('bums-35'),   // Barbell Back Squat
        _safeGetExercise('bums-36'),   // Barbell Romanian Deadlift
        _safeGetExercise('bums-37'),   // Bulgarian Split Squat
        _safeGetExercise('arms-1'),    // Dumbbell Bench Press
        _safeGetExercise('arms-11'),   // Push-Up
        _safeGetExercise('arms-3'),    // Dumbbell Tricep Lying Extension
        _safeGetExercise('tums-10'),   // V-Up
        _safeGetExercise('tums-7'),    // Leg In and Out
        _safeGetExercise('bums-16'),   // Jumping Squat
        _safeGetExercise('full-1'),    // Burpee
      ],
      sections: [
        WorkoutSection(
          id: 'full-007-section-1',
          name: 'Intense Warm-up',
          exercises: [
            _safeGetExercise('cardio-5'),  // Burpee
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'full-007-section-2',
          name: 'Lower Body Power',
          exercises: [
            _safeGetExercise('bums-35'),   // Barbell Back Squat
            _safeGetExercise('bums-36'),   // Barbell Romanian Deadlift
            _safeGetExercise('bums-37'),   // Bulgarian Split Squat
          ],
          restAfterSection: 120,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'full-007-section-3',
          name: 'Upper Body Strength',
          exercises: [
            _safeGetExercise('arms-1'),    // Dumbbell Bench Press
            _safeGetExercise('arms-11'),   // Push-Up
            _safeGetExercise('arms-3'),    // Dumbbell Tricep Lying Extension
          ],
          restAfterSection: 90,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'full-007-section-4',
          name: 'Core Power',
          exercises: [
            _safeGetExercise('tums-10'),   // V-Up
            _safeGetExercise('tums-7'),    // Leg In and Out
          ],
          restAfterSection: 90,
          type: SectionType.superset,
        ),
        WorkoutSection(
          id: 'full-007-section-5',
          name: 'Metabolic Finisher',
          exercises: [
            _safeGetExercise('bums-16'),   // Jumping Squat
            _safeGetExercise('full-1'),    // Burpee
          ],
          restAfterSection: 0,
          type: SectionType.superset,
        ),
      ],
    ),

    // Advanced Workout 2
    Workout(
      id: 'full-008',
      title: 'Athletic Performance',
      description:
          'Build athletic power, speed, and functional strength with this advanced workout designed to enhance overall physical performance.',
      imageUrl: 'assets/images/workouts/athletic_performance.jpg',
      category: WorkoutCategory.fullBody,
      difficulty: WorkoutDifficulty.advanced,
      durationMinutes: 55,
      estimatedCaloriesBurn: 480,
      featured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      createdBy: 'admin',
      equipment: ['mat', 'dumbbells', 'bench', 'medicine ball'],
      tags: ['advanced', 'athletic', 'explosive', 'functional'],
      exercises: [
        _safeGetExercise('cardio-5'),  // Burpee
        _safeGetExercise('cardio-2'),  // Jumping Squat
        _safeGetExercise('bums-26'),   // Dumbbell Jumping Squat
        _safeGetExercise('bums-29'),   // Dumbbell Single Leg Deadlift
        _safeGetExercise('full-9'),    // One Leg Push-Up
        _safeGetExercise('full-10'),   // Medicine Ball Slams
        _safeGetExercise('arms-12'),   // Tiger Bend Push-Up
        _safeGetExercise('full-13'),   // Plank Leg Up
        _safeGetExercise('bums-22'),   // Pistol Box Squat
        _safeGetExercise('full-15'),   // Fitball Mountain Climber
        _safeGetExercise('tums-18'),   // Fitball Plank to Pike
        _safeGetExercise('cardio-6'),  // Jumping Lunge
      ],
      sections: [
        WorkoutSection(
          id: 'full-008-section-1',
          name: 'Dynamic Warm-up',
          exercises: [
            _safeGetExercise('cardio-5'),  // Burpee
            _safeGetExercise('cardio-2'),  // Jumping Squat
          ],
          restAfterSection: 60,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'full-008-section-2',
          name: 'Lower Body Power',
          exercises: [
            _safeGetExercise('bums-26'),   // Dumbbell Jumping Squat
            _safeGetExercise('bums-29'),   // Dumbbell Single Leg Deadlift
            _safeGetExercise('bums-22'),   // Pistol Box Squat
          ],
          restAfterSection: 90,
          type: SectionType.normal,
        ),
        WorkoutSection(
          id: 'full-008-section-3',
          name: 'Upper Body Power',
          exercises: [
            _safeGetExercise('full-9'),    // One Leg Push-Up
            _safeGetExercise('full-10'),   // Medicine Ball Slams
            _safeGetExercise('arms-12'),   // Tiger Bend Push-Up
          ],
          restAfterSection: 90,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'full-008-section-4',
          name: 'Core & Stability',
          exercises: [
            _safeGetExercise('full-13'),   // Plank Leg Up
            _safeGetExercise('full-15'),   // Fitball Mountain Climber
            _safeGetExercise('tums-18'),   // Fitball Plank to Pike
          ],
          restAfterSection: 60,
          type: SectionType.circuit,
        ),
        WorkoutSection(
          id: 'full-008-section-5',
          name: 'Explosive Finisher',
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
      id: 'full-009',
      title: 'Ultimate HIIT Circuit',
      description: 'A high-intensity circuit training workout that combines strength, power, and cardio exercises for maximum calorie burn and total body conditioning.',
     imageUrl: 'assets/images/workouts/ultimate_hiit_circuit.jpg',
     category: WorkoutCategory.fullBody,
     difficulty: WorkoutDifficulty.advanced,
     durationMinutes: 45,
     estimatedCaloriesBurn: 500,
     featured: false,
     createdAt: DateTime.now().subtract(const Duration(days: 10)),
     createdBy: 'admin',
     equipment: ['mat', 'dumbbells', 'medicine ball', 'kettlebell (optional)'],
     tags: ['advanced', 'hiit', 'circuit', 'fat burning', 'conditioning'],
     exercises: [
       _safeGetExercise('cardio-5'),  // Burpee
       _safeGetExercise('full-1'),    // Burpee (duplicate for circuit)
       _safeGetExercise('cardio-2'),  // Jumping Squat
       _safeGetExercise('bums-27'),   // Dumbbell Lunge
       _safeGetExercise('full-10'),   // Medicine Ball Slams
       _safeGetExercise('arms-11'),   // Push-Up
       _safeGetExercise('tums-11'),   // V Crunch
       _safeGetExercise('tums-4'),    // Russian Twist
       _safeGetExercise('full-2'),    // Mountain Climber
       _safeGetExercise('cardio-7'),  // Skater Jumps
       _safeGetExercise('cardio-6'),  // Jumping Lunge
     ],
     sections: [
       WorkoutSection(
         id: 'full-009-section-1',
         name: 'Dynamic Warm-up',
         exercises: [
           _safeGetExercise('cardio-5'),  // Burpee
           _safeGetExercise('full-2'),    // Mountain Climber
         ],
         restAfterSection: 60,
         type: SectionType.normal,
       ),
       WorkoutSection(
         id: 'full-009-section-2',
         name: 'HIIT Circuit 1',
         exercises: [
           _safeGetExercise('cardio-2'),  // Jumping Squat
           _safeGetExercise('bums-27'),   // Dumbbell Lunge
           _safeGetExercise('arms-11'),   // Push-Up
         ],
         restAfterSection: 90,
         type: SectionType.circuit,
       ),
       WorkoutSection(
         id: 'full-009-section-3',
         name: 'HIIT Circuit 2',
         exercises: [
           _safeGetExercise('full-10'),   // Medicine Ball Slams
           _safeGetExercise('tums-11'),   // V Crunch
           _safeGetExercise('tums-4'),    // Russian Twist
         ],
         restAfterSection: 90,
         type: SectionType.circuit,
       ),
       WorkoutSection(
         id: 'full-009-section-4',
         name: 'HIIT Circuit 3',
         exercises: [
           _safeGetExercise('full-1'),    // Burpee
           _safeGetExercise('cardio-7'),  // Skater Jumps
         ],
         restAfterSection: 60,
         type: SectionType.circuit,
       ),
       WorkoutSection(
         id: 'full-009-section-5',
         name: 'Finisher',
         exercises: [
           _safeGetExercise('cardio-6'),  // Jumping Lunge
         ],
         restAfterSection: 0,
         type: SectionType.normal,
       ),
     ],
   ),
 ];
}