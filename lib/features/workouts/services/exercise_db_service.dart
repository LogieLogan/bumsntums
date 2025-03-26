// lib/features/workouts/services/exercise_db_service.dart
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/services/exercise_media_service.dart';

class ExerciseDBService {
  final http.Client _client;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Exercise> _localExercises = [];
  Map<String, List<Exercise>> _exercisesByCategory = {};
  Map<String, List<Exercise>> _exercisesByEquipment = {};
  Map<int, List<Exercise>> _exercisesByDifficulty = {};

  bool _isInitialized = false;

  // Constructor
  ExerciseDBService({http.Client? client}) : _client = client ?? http.Client();

  // Initialize the local exercise database
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadExercises();
    _categorizeExercises();
    _isInitialized = true;
  }

  // Load all exercises from various sources
  Future<void> _loadExercises() async {
    // Start with mock exercises in development mode
    _localExercises = _getMockExercises();

    // Add additional exercises
    _localExercises.addAll(_getAdditionalExercises());

    // In production, also try to fetch from Firestore
    if (!kDebugMode) {
      try {
        final snapshot = await _firestore.collection('exercises').get();
        final firestoreExercises =
            snapshot.docs
                .map((doc) => Exercise.fromMap({...doc.data(), 'id': doc.id}))
                .toList();

        // Add unique exercises that aren't already in the local list
        for (final exercise in firestoreExercises) {
          if (!_localExercises.any((e) => e.id == exercise.id)) {
            _localExercises.add(exercise);
          }
        }
      } catch (e) {
        debugPrint('Error fetching exercises from Firestore: $e');
        // Continue with local exercises
      }
    }

    // Check for video paths for each exercise
    for (int i = 0; i < _localExercises.length; i++) {
      final exercise = _localExercises[i];
      if (exercise.videoPath == null) {
        final videoPath = await ExerciseMediaService.findVideoForExercise(
          exercise.name,
        );
        if (videoPath != null) {
          _localExercises[i] = exercise.copyWith(videoPath: videoPath);
        }
      }
    }
  }

  // Organize exercises into various categorized maps for quick access
  void _categorizeExercises() {
    // Clear existing maps
    _exercisesByCategory = {};
    _exercisesByEquipment = {};
    _exercisesByDifficulty = {};

    // Categorize each exercise
    for (final exercise in _localExercises) {
      // By target area
      final category = exercise.targetArea.toLowerCase();
      if (!_exercisesByCategory.containsKey(category)) {
        _exercisesByCategory[category] = [];
      }
      _exercisesByCategory[category]!.add(exercise);

      // By equipment
      for (final equipment in exercise.equipmentOptions) {
        final equipmentKey = equipment.toLowerCase();
        if (!_exercisesByEquipment.containsKey(equipmentKey)) {
          _exercisesByEquipment[equipmentKey] = [];
        }
        _exercisesByEquipment[equipmentKey]!.add(exercise);
      }

      // By difficulty level
      final difficultyKey = exercise.difficultyLevel;
      if (!_exercisesByDifficulty.containsKey(difficultyKey)) {
        _exercisesByDifficulty[difficultyKey] = [];
      }
      _exercisesByDifficulty[difficultyKey]!.add(exercise);
    }
  }

  // Get all available exercises
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

    final key = targetArea.toLowerCase();
    return _exercisesByCategory[key] ?? [];
  }

  // Get exercises by difficulty level
  Future<List<Exercise>> getExercisesByDifficulty(int difficultyLevel) async {
    if (!_isInitialized) {
      await initialize();
    }

    return _exercisesByDifficulty[difficultyLevel] ?? [];
  }

  // Get exercises by equipment
  Future<List<Exercise>> getExercisesByEquipment(String equipment) async {
    if (!_isInitialized) {
      await initialize();
    }

    final key = equipment.toLowerCase();
    return _exercisesByEquipment[key] ?? [];
  }

  // Advanced filtering method
  Future<List<Exercise>> filterExercises({
    String? targetArea,
    int? difficultyLevel,
    String? equipment,
    List<String>? targetMuscles,
    bool? hasVideo,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    return _localExercises.where((exercise) {
      // Filter by target area if specified
      if (targetArea != null &&
          exercise.targetArea.toLowerCase() != targetArea.toLowerCase()) {
        return false;
      }

      // Filter by difficulty level if specified
      if (difficultyLevel != null &&
          exercise.difficultyLevel != difficultyLevel) {
        return false;
      }

      // Filter by equipment if specified
      if (equipment != null &&
          !exercise.equipmentOptions.any(
            (e) => e.toLowerCase() == equipment.toLowerCase(),
          )) {
        return false;
      }

      // Filter by target muscles if specified
      if (targetMuscles != null && targetMuscles.isNotEmpty) {
        final hasTargetMuscle = exercise.targetMuscles.any(
          (muscle) => targetMuscles.any(
            (filter) => muscle.toLowerCase().contains(filter.toLowerCase()),
          ),
        );
        if (!hasTargetMuscle) {
          return false;
        }
      }

      // Filter by video availability if specified
      if (hasVideo == true && exercise.videoPath == null) {
        return false;
      }

      return true;
    }).toList();
  }

  // Search exercises by name, description, or target muscles
  Future<List<Exercise>> searchExercises(String query) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (query.isEmpty) {
      return _localExercises;
    }

    final lowerQuery = query.toLowerCase();
    return _localExercises.where((exercise) {
      return exercise.name.toLowerCase().contains(lowerQuery) ||
          exercise.description.toLowerCase().contains(lowerQuery) ||
          exercise.targetMuscles.any(
            (muscle) => muscle.toLowerCase().contains(lowerQuery),
          ) ||
          exercise.targetArea.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Get exercise by ID
  Future<Exercise> getExerciseById(String id) async {
    if (!_isInitialized) {
      await initialize();
    }

    final exercise = _localExercises.firstWhere(
      (exercise) => exercise.id == id,
      orElse: () => throw Exception('Exercise not found: $id'),
    );

    return exercise;
  }

  // Get similar exercises to a given exercise
  Future<List<Exercise>> getSimilarExercises(Exercise exercise) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Find exercises that target the same area and muscles
    return _localExercises.where((e) {
      // Skip the original exercise
      if (e.id == exercise.id) return false;

      // Check for same target area
      if (e.targetArea != exercise.targetArea) return false;

      // Check for at least one common target muscle
      final hasCommonMuscle = e.targetMuscles.any(
        (muscle) => exercise.targetMuscles.contains(muscle),
      );

      return hasCommonMuscle;
    }).toList();
  }

  // Get next progression exercises for a given exercise
  Future<List<Exercise>> getProgressionExercises(Exercise exercise) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Look for exercises by name in the progression list
    final List<Exercise> progressions = [];

    for (final progressionName in exercise.progressionExercises) {
      final matchingExercises =
          _localExercises
              .where(
                (e) =>
                    e.name.toLowerCase() == progressionName.toLowerCase() ||
                    e.name.toLowerCase().contains(
                      progressionName.toLowerCase(),
                    ),
              )
              .toList();

      progressions.addAll(matchingExercises);
    }

    return progressions;
  }

  // Save a custom exercise
  Future<Exercise> saveCustomExercise(Exercise exercise) async {
    // Ensure initialization
    if (!_isInitialized) {
      await initialize();
    }

    // Generate an ID if needed
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

    // Recategorize exercises
    _categorizeExercises();

    // For production, also save to Firestore
    if (!kDebugMode) {
      try {
        await _firestore
            .collection('custom_exercises')
            .doc(newExercise.id)
            .set(newExercise.toMap());
      } catch (e) {
        debugPrint('Error saving custom exercise to Firestore: $e');
        // Continue with local storage
      }
    }

    return newExercise;
  }

  // Get available target areas
  Future<List<String>> getAvailableTargetAreas() async {
    if (!_isInitialized) {
      await initialize();
    }

    final Set<String> areas = {};
    for (final exercise in _localExercises) {
      areas.add(exercise.targetArea);
    }

    return areas.toList()..sort();
  }

  // Get available equipment types
  Future<List<String>> getAvailableEquipment() async {
    if (!_isInitialized) {
      await initialize();
    }

    final Set<String> equipment = {};
    for (final exercise in _localExercises) {
      equipment.addAll(exercise.equipmentOptions);
    }

    return equipment.toList()..sort();
  }

  // Get available target muscles
  Future<List<String>> getAvailableTargetMuscles() async {
    if (!_isInitialized) {
      await initialize();
    }

    final Set<String> muscles = {};
    for (final exercise in _localExercises) {
      muscles.addAll(exercise.targetMuscles);
    }

    return muscles.toList()..sort();
  }

  // Mock exercises
  List<Exercise> _getMockExercises() {
    // Reuse your existing exercises
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
        videoPath: 'assets/videos/exercises/plank_leg_up.mp4',
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

  // Additional exercises to expand the database
  List<Exercise> _getAdditionalExercises() {
    return [
      // Add new exercises here to expand the library
      Exercise(
        id: 'bums-5',
        name: 'Hip Thrust',
        description:
            'Sit with your upper back against a bench, feet on the floor. Place a weight across your hips, then drive through your heels to lift your hips up, forming a straight line from shoulders to knees.',
        imageUrl: 'assets/images/exercises/hip_thrust.jpg',
        videoPath: 'assets/videos/exercises/hip_thrust.mp4',
        sets: 3,
        reps: 12,
        restBetweenSeconds: 60,
        targetArea: 'bums',
        difficultyLevel: 3,
        targetMuscles: ['gluteus maximus', 'hamstrings'],
        formTips: [
          'Keep your chin tucked to maintain a neutral spine',
          'Drive through your heels throughout the movement',
          'Squeeze your glutes hard at the top of the movement',
        ],
        commonMistakes: [
          'Hyperextending the lower back',
          'Not coming up high enough',
          'Using momentum instead of glute strength',
        ],
        progressionExercises: ['single-leg hip thrust', 'banded hip thrust'],
        regressionExercises: ['bodyweight hip thrust', 'glute bridge'],
        equipmentOptions: ['bench', 'barbell', 'dumbbell', 'resistance band'],
      ),

      Exercise(
        id: 'bums-6',
        name: 'Clamshells',
        description:
            'Lie on your side with knees bent at 45 degrees. Keep feet together and raise the top knee while keeping feet in contact, then lower back down.',
        imageUrl: 'assets/images/exercises/clamshell.jpg',
        videoPath: 'assets/videos/exercises/clamshell.mp4',
        sets: 3,
        reps: 15,
        restBetweenSeconds: 30,
        targetArea: 'bums',
        difficultyLevel: 1,
        targetMuscles: ['gluteus medius', 'gluteus minimus', 'hip abductors'],
        formTips: [
          'Keep your hips stacked throughout the movement',
          'Don\'t rotate your pelvis as you lift your knee',
          'Focus on using your glute muscle to lift, not your hip flexors',
        ],
        commonMistakes: [
          'Rolling the pelvis back as the knee lifts',
          'Using momentum instead of control',
          'Not opening the knee far enough',
        ],
        progressionExercises: [
          'banded clamshells',
          'clamshells with straight leg raises',
        ],
        regressionExercises: ['partial range clamshells'],
        equipmentOptions: ['none', 'resistance band'],
      ),

      // Add more exercises as needed
    ];
  }
}
