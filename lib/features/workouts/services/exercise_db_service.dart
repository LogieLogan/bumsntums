// lib/features/workouts/services/exercise_db_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/exercise.dart';

class ExerciseDBService {
  final http.Client _client;
  
  // Simplified constructor without API key dependency
  ExerciseDBService({
    http.Client? client,
  }) : _client = client ?? http.Client();
  
  // Add a method to fetch local exercises only
  List<Exercise> getLocalExercises() {
    // This would be implemented to return a list of predefined exercises
    return [];  // Return empty list for now
  }
  
  // Convert API exercise data to our Exercise model - keep this for data conversion if needed
  Exercise apiExerciseToModel(Map<String, dynamic> data, {
    int sets = 3,
    int reps = 12,
    int restBetweenSeconds = 60,
    String targetArea = '',
  }) {
    return Exercise(
      id: 'local-${data['id'] ?? DateTime.now().millisecondsSinceEpoch}',
      name: data['name'] ?? 'Unknown Exercise',
      description: data['instructions']?.join('\n') ?? 'No instructions available',
      imageUrl: data['imageUrl'] ?? 'assets/images/exercises/default.jpg',
      sets: sets,
      reps: reps,
      restBetweenSeconds: restBetweenSeconds,
      targetArea: targetArea.isEmpty ? data['target'] ?? '' : targetArea,
    );
  }
}