// lib/features/workouts/data/sources/json_exercise_data_source.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/exercise.dart';
import 'exercise_data_source.dart';

/// Implementation of ExerciseDataSource that loads data from JSON files
class JsonExerciseDataSource implements ExerciseDataSource {
  final List<String> _categoryFiles = [
    'assets/data/exercises/bums_exercises.json',
    'assets/data/exercises/tums_exercises.json',
    'assets/data/exercises/full_body_exercises.json',
    'assets/data/exercises/arms_exercises.json',
    'assets/data/exercises/legs_exercises.json',
    'assets/data/exercises/cardio_exercises.json',
  ];
  
  @override
  Future<List<Exercise>> loadExercises() async {
    final List<Exercise> exercises = [];
    
    try {
      // Load exercises from each category file
      for (final file in _categoryFiles) {
        try {
          final String content = await rootBundle.loadString(file);
          final List<dynamic> exerciseList = json.decode(content);
          
          exercises.addAll(
            exerciseList.map((data) => Exercise.fromMap(data)).toList()
          );
        } catch (e) {
          print('Error loading exercises from $file: $e');
          // Continue with other files even if one fails
        }
      }
      
      return exercises;
    } catch (e) {
      print('Error loading exercises from JSON: $e');
      return [];
    }
  }
  
  @override
  Future<Exercise> saveExercise(Exercise exercise) async {
    // For local JSON source, we can't easily save to assets
    // This would be implemented in the Firebase version
    throw UnimplementedError('Saving exercises not supported in JSON data source');
  }
}