// lib/features/ai/services/ai_service.dart
import '../../workouts/models/workout.dart';

// Abstract class defining the contract for AI services
abstract class AIService {
  /// Generates a workout recommendation based on user preferences and profile.
  Future<Map<String, dynamic>> generateWorkoutRecommendation({
    required String userId,
    String? specificRequest,
    WorkoutCategory? category,
    int? maxMinutes,
    List<String>? equipment,
    List<String>? focusAreas,
    // User profile details for context
    String? fitnessLevel,
    int? age,
    List<String>? goals,
    String? preferredLocation,
    List<String>? healthConditions,
    Map<String, dynamic>? consultationResponses,
  });

  /// Refines an existing workout based on user feedback.
  Future<Map<String, dynamic>> refineWorkout({
    required String userId,
    required Map<String, dynamic> originalWorkout,
    required String refinementRequest,
    String?
    originalRequest, // The initial request that generated the original workout
  });

  /// Handles chat interactions, providing context-aware responses.
  Future<String> enhancedChat({
    required String userId,
    required String message,
    required List<Map<String, String>> previousMessages,
    Map<String, dynamic>? userProfileData,
  });

  /// Detects the general category or intent of a user's chat message.
  /// Useful for analytics or selecting response strategies.
  String detectMessageCategory(String message);
}
