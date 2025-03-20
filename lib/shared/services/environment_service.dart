// lib/shared/services/environment_service.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentService {
  static final EnvironmentService _instance = EnvironmentService._internal();
  factory EnvironmentService() => _instance;
  EnvironmentService._internal();
  
  bool _isInitialized = false;
  String? _cachedOpenAIKey;
  String? _cachedExerciseDBKey;

  bool get isInitialized => _isInitialized;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load the .env file
      await dotenv.load();
      _isInitialized = true;
    } catch (e) {
      print('Error loading environment variables: $e');
      throw Exception('Failed to initialize environment service: $e');
    }
  }
  
  String get openAIApiKey {
    if (!_isInitialized) {
      throw NotInitializedError('Environment service is not initialized');
    }
    
    // First check cached value
    if (_cachedOpenAIKey != null) {
      return _cachedOpenAIKey!;
    }
    
    // Try to get from dotenv
    _cachedOpenAIKey = dotenv.env['OPENAI_API_KEY'];
    if (_cachedOpenAIKey?.isNotEmpty == true) {
      return _cachedOpenAIKey!;
    }
    
    // Fallback for development
    return 'sk-dummy-key-for-development';
  }
  
  // New getter for ExerciseDB API key
  String get exerciseDBApiKey {
    if (!_isInitialized) {
      throw NotInitializedError('Environment service is not initialized');
    }
    
    // First check cached value
    if (_cachedExerciseDBKey != null) {
      return _cachedExerciseDBKey!;
    }
    
    // Try to get from dotenv
    _cachedExerciseDBKey = dotenv.env['EXERCISE_DB_API_KEY'];
    if (_cachedExerciseDBKey?.isNotEmpty == true) {
      return _cachedExerciseDBKey!;
    }
    
    // Fallback for development
    return 'dummy-exercisedb-key-for-development';
  }
}

class NotInitializedError extends Error {
  final String message;
  NotInitializedError(this.message);
  
  @override
  String toString() => message;
}