// lib/features/workouts/services/exercise_db_service.dart
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';

class ExerciseDBService {
  final http.Client _client;
  List<Exercise> _localExercises = [];
  bool _isInitialized = false;

  // Simplified constructor without API key dependency
  ExerciseDBService({http.Client? client}) : _client = client ?? http.Client();

  // Initialize the local exercise database
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadMockExercises();
    _isInitialized = true;
  }

  // Load mock exercises from the database
  Future<void> _loadMockExercises() async {
    _localExercises = _getMockExercises();
  }

  // Get all local exercises
  Future<List<Exercise>> getAllExercises() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _localExercises;
  }

  // Get exercises by target area
  Future<List<Exercise>> getExercisesByTargetArea(String targetArea) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (targetArea.isEmpty) {
      return _localExercises;
    }

    return _localExercises
        .where(
          (exercise) =>
              exercise.targetArea.toLowerCase() == targetArea.toLowerCase(),
        )
        .toList();
  }

  // Search exercises by name or description
  Future<List<Exercise>> searchExercises(String query) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (query.isEmpty) {
      return _localExercises;
    }

    return _localExercises
        .where(
          (exercise) =>
              exercise.name.toLowerCase().contains(query.toLowerCase()) ||
              exercise.description.toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              exercise.targetMuscles.any(
                (muscle) => muscle.toLowerCase().contains(query.toLowerCase()),
              ),
        )
        .toList();
  }

  // Get exercises by difficulty level
  Future<List<Exercise>> getExercisesByDifficulty(int difficultyLevel) async {
    if (!_isInitialized) {
      await initialize();
    }

    return _localExercises
        .where((exercise) => exercise.difficultyLevel == difficultyLevel)
        .toList();
  }

  // Get exercises that can be performed with specific equipment
  Future<List<Exercise>> getExercisesByEquipment(String equipment) async {
    if (!_isInitialized) {
      await initialize();
    }

    return _localExercises
        .where(
          (exercise) => exercise.equipmentOptions.any(
            (option) => option.toLowerCase() == equipment.toLowerCase(),
          ),
        )
        .toList();
  }

  // Save a custom exercise
  Future<Exercise> saveCustomExercise(Exercise exercise) async {
    // In a real app, this would save to a database
    // For now, we'll just add it to our in-memory list
    final newExercise = exercise.copyWith(
      id: exercise.id.isNotEmpty ? exercise.id : 'custom-${const Uuid().v4()}',
    );

    // Add to our local list if it's a new exercise
    if (!_localExercises.any((e) => e.id == newExercise.id)) {
      _localExercises.add(newExercise);
    } else {
      // Replace existing exercise
      final index = _localExercises.indexWhere((e) => e.id == newExercise.id);
      _localExercises[index] = newExercise;
    }

    return newExercise;
  }

  List<Exercise> _getMockExercises() {
    return [
      // Bums exercises
      Exercise(
        id: 'bums-1',
        name: 'Glute Bridge',
        description:
            'Lie on your back with knees bent and feet flat on the floor. Lift your hips off the ground, squeezing your glutes at the top, then lower back down.',
        imageUrl: 'assets/images/exercises/glute_bridge.jpg',
        videoPath: 'assets/videos/exercises/glute_bridge.mp4',
        sets: 3,
        reps: 15,
        restBetweenSeconds: 60,
        targetArea: 'bums',
        difficultyLevel: 1,
        targetMuscles: ['gluteus maximus', 'hamstrings', 'lower back'],
        formTips: [
          'Keep your core engaged throughout the movement',
          'Push through your heels to engage your glutes fully',
          'At the top, your body should form a straight line from shoulders to knees',
        ],
        commonMistakes: [
          'Arching the lower back excessively',
          'Not squeezing glutes at the top',
          'Pushing through toes instead of heels',
        ],
        progressionExercises: [
          'single-leg glute bridge',
          'weighted glute bridge',
        ],
        regressionExercises: ['partial range glute bridge'],
        equipmentOptions: ['none', 'resistance band', 'dumbbell', 'barbell'],
      ),

      Exercise(
        id: 'bums-2',
        name: 'Squats',
        description:
            'Stand with feet shoulder-width apart. Bend knees and lower your body as if sitting in a chair. Keep chest up and knees over toes. Return to standing.',
        imageUrl: 'assets/images/exercises/squats.jpg',
        videoPath: 'assets/videos/exercises/squats.mp4',
        sets: 3,
        reps: 12,
        restBetweenSeconds: 60,
        targetArea: 'bums',
        difficultyLevel: 2,
        targetMuscles: [
          'gluteus maximus',
          'quadriceps',
          'hamstrings',
          'calves',
        ],
        formTips: [
          'Keep weight in your heels',
          'Maintain a neutral spine throughout the movement',
          'Aim to get thighs parallel to the ground or lower',
        ],
        commonMistakes: [
          'Knees caving inward',
          'Rounding the lower back',
          'Rising onto toes instead of keeping heels down',
        ],
        progressionExercises: [
          'goblet squat',
          'barbell squat',
          'single-leg squat',
        ],
        regressionExercises: ['wall squat', 'box squat'],
        equipmentOptions: ['none', 'dumbbell', 'kettlebell', 'barbell'],
      ),

      Exercise(
        id: 'bums-3',
        name: 'Lunges',
        description:
            'Stand tall, then step forward with one leg and lower your body until both knees form 90-degree angles. Push back to the starting position and repeat with the other leg.',
        imageUrl: 'assets/images/exercises/lunges.jpg',
        videoPath: 'assets/videos/exercises/lunges.mp4',
        sets: 3,
        reps: 10,
        restBetweenSeconds: 60,
        targetArea: 'bums',
        difficultyLevel: 2,
        targetMuscles: [
          'gluteus maximus',
          'quadriceps',
          'hamstrings',
          'calves',
        ],
        formTips: [
          'Keep your upper body straight with shoulders back and relaxed',
          'Step forward far enough that your front knee stays above your ankle',
          'Lower your hips toward the floor by bending both knees',
        ],
        commonMistakes: [
          'Front knee extending beyond toes',
          'Leaning forward too much',
          'Not stepping far enough forward',
        ],
        progressionExercises: [
          'walking lunges',
          'reverse lunges',
          'weighted lunges',
        ],
        regressionExercises: ['static lunges', 'assisted lunges'],
        equipmentOptions: ['none', 'dumbbells', 'kettlebells'],
      ),

      // Tums exercises
      Exercise(
        id: 'tums-1',
        name: 'Crunches',
        description:
            'Lie on your back with knees bent and feet flat on the floor. Place hands behind your head and lift your shoulders off the ground, contracting your abs. Lower back down with control.',
        imageUrl: 'assets/images/exercises/crunches.jpg',
        videoPath: 'assets/videos/exercises/abdominal_crunches.mp4',
        sets: 3,
        reps: 15,
        restBetweenSeconds: 45,
        targetArea: 'tums',
        difficultyLevel: 1,
        targetMuscles: ['rectus abdominis', 'obliques'],
        formTips: [
          'Focus on the contraction of your abdominals',
          'Keep your neck neutral - don\'t pull on your head',
          'Exhale as you lift, inhale as you lower',
        ],
        commonMistakes: [
          'Pulling on the neck',
          'Using momentum instead of muscle control',
          'Lifting too high off the ground',
        ],
        progressionExercises: [
          'bicycle crunches',
          'reverse crunches',
          'weighted crunches',
        ],
        regressionExercises: ['partial crunches'],
        equipmentOptions: ['none', 'exercise mat', 'stability ball'],
      ),

      Exercise(
        id: 'tums-2',
        name: 'Plank',
        description:
            'Get into a push-up position, but with weight on your forearms. Keep your body in a straight line from head to heels, engaging your core. Hold this position.',
        imageUrl: 'assets/images/exercises/plank.jpg',
        videoPath:
            'assets/videos/exercises/plank_leg_up.mp4',
        sets: 3,
        durationSeconds: 30,
        restBetweenSeconds: 60,
        reps: 0,
        targetArea: 'tums',
        difficultyLevel: 2,
        targetMuscles: [
          'transverse abdominis',
          'rectus abdominis',
          'obliques',
          'lower back',
        ],
        formTips: [
          'Keep your body in a straight line - don\'t let hips sag or pike',
          'Engage your core by pulling your navel toward your spine',
          'Distribute weight evenly between forearms and toes',
        ],
        commonMistakes: [
          'Sagging hips',
          'Elevated hips',
          'Holding breath instead of breathing normally',
        ],
        progressionExercises: [
          'side plank',
          'plank with leg lift',
          'plank with shoulder tap',
        ],
        regressionExercises: ['knee plank', 'incline plank'],
        equipmentOptions: ['none', 'exercise mat'],
      ),

      Exercise(
        id: 'tums-3',
        name: 'Russian Twists',
        description:
            'Sit on the floor with knees bent and feet lifted slightly. Lean back at a 45-degree angle and twist your torso from side to side, touching the ground beside your hips.',
        imageUrl: 'assets/images/exercises/russian_twists.jpg',
        videoPath: 'assets/videos/exercises/abdominal_twist.mp4',
        sets: 3,
        reps: 20,
        restBetweenSeconds: 45,
        targetArea: 'tums',
        difficultyLevel: 2,
        targetMuscles: ['obliques', 'rectus abdominis', 'hip flexors'],
        formTips: [
          'Keep your back straight - don\'t round your shoulders',
          'Twist from your torso, not just your arms',
          'Keep feet elevated throughout the movement for increased difficulty',
        ],
        commonMistakes: [
          'Rounding the back',
          'Moving too quickly without control',
          'Not twisting far enough to engage obliques',
        ],
        progressionExercises: [
          'weighted russian twists',
          'russian twists with extended legs',
        ],
        regressionExercises: ['russian twists with feet on ground'],
        equipmentOptions: ['none', 'dumbbell', 'medicine ball', 'weight plate'],
      ),

      // Full body exercises
      Exercise(
        id: 'full-1',
        name: 'Burpees',
        description:
            'Begin in a standing position. Drop into a squat position with your hands on the ground. Kick your feet back into a plank position. Immediately return your feet to the squat position. Jump up from the squat position.',
        imageUrl: 'assets/images/exercises/burpees.jpg',
        videoPath: 'assets/videos/exercises/burpees.mp4',
        sets: 3,
        reps: 10,
        restBetweenSeconds: 60,
        targetArea: 'fullBody',
        difficultyLevel: 4,
        targetMuscles: [
          'quadriceps',
          'gluteus maximus',
          'pectorals',
          'shoulders',
          'abdominals',
        ],
        formTips: [
          'Keep your core engaged throughout the movement',
          'Land softly when jumping to protect your joints',
          'Maintain a flat back during the plank portion',
        ],
        commonMistakes: [
          'Sagging or piking hips in plank position',
          'Not fully extending hips at the top of the jump',
          'Landing with straight legs',
        ],
        progressionExercises: ['burpee with push-up', 'burpee with tuck jump'],
        regressionExercises: ['step-back burpee', 'no-jump burpee'],
        equipmentOptions: ['none'],
      ),

      Exercise(
        id: 'full-2',
        name: 'Mountain Climbers',
        description:
            'Start in a high plank position with hands under shoulders. Rapidly alternate driving knees toward chest, as if running in place while maintaining the plank position.',
        imageUrl: 'assets/images/exercises/mountain_climbers.jpg',
        videoPath: 'assets/videos/exercises/mountain_climber.mp4',
        sets: 3,
        durationSeconds: 30,
        restBetweenSeconds: 45,
        reps: 0,
        targetArea: 'fullBody',
        difficultyLevel: 3,
        targetMuscles: [
          'abdominals',
          'hip flexors',
          'shoulders',
          'chest',
          'quads',
        ],
        formTips: [
          'Keep hips low and in line with shoulders',
          'Drive knees fully toward chest',
          'Maintain wrist stability by spreading fingers wide',
        ],
        commonMistakes: [
          'Bouncing hips up and down',
          'Not bringing knees far enough forward',
          'Letting shoulders rise toward ears',
        ],
        progressionExercises: [
          'cross-body mountain climbers',
          'slowed-down mountain climbers with leg extension',
        ],
        regressionExercises: [
          'incline mountain climbers',
          'slower-paced mountain climbers',
        ],
        equipmentOptions: ['none', 'exercise mat', 'sliders'],
      ),
    ];
  }

  // Add more exercises to expand the database
  List<Exercise> _getAdditionalExercises() {
    // This method can be used to add more exercises in batches
    return [];
  }
}
