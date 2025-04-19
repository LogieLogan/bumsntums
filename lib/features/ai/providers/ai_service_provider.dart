// lib/features/ai/providers/ai_service_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bums_n_tums/features/ai/services/ai_service.dart';
// Import the new Firebase Vertex AI service implementation
import 'package:bums_n_tums/features/ai/services/firebase_vertexai_service.dart';
// Remove unused imports for OpenAI/Gemini/Environment if they were here previously
// import 'package:bums_n_tums/features/ai/services/gemini_service.dart';
// import 'package:bums_n_tums/features/ai/services/openai_service.dart';
// import 'package:bums_n_tums/shared/providers/environment_provider.dart';
// import 'package:bums_n_tums/shared/services/environment_service.dart';

// --- Remove or comment out providers for components only used by OpenAIService ---
/*
// Provider for PromptEngine
final promptEngineProvider = Provider<PromptEngine>((ref) {
  return PromptEngine();
});

// Provider for PersonalityEngine
final personalityEngineProvider = Provider<PersonalityEngine>((ref) {
  return PersonalityEngine();
});

// Provider for ContextService
final contextServiceProvider = Provider<ContextService>((ref) {
  final fitnessProfileService = FitnessProfileService();
  return ContextService(fitnessProfileService: fitnessProfileService);
});
*/

// --- AI Service Provider ---
// This provider now simply returns an instance of the FirebaseVertexAIService
final aiServiceProvider = Provider<AIService>((ref) {
  // No need to check API keys here, the SDK handles authentication
  // via the Firebase project setup.
  print("AI Service Provider: Creating FirebaseVertexAIService instance.");
  try {
    return FirebaseVertexAIService();
  } catch (e) {
    // Catch potential initialization errors from the service constructor
     print("AI Service Provider: Error creating FirebaseVertexAIService: $e");
     // Depending on how you want to handle this, you could return a
     // dummy service or rethrow. Rethrowing makes the error clear.
     throw Exception("Failed to initialize FirebaseVertexAIService: ${e.toString()}");
  }
});