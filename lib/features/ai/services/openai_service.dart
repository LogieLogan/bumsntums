// lib/features/ai/services/openai_service.dart (minimal update to fix errors)
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:bums_n_tums/features/ai/services/context_service.dart';
import 'package:bums_n_tums/features/ai/services/personality_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../features/workouts/models/workout.dart';
import 'prompt_engine.dart';

class OpenAIService {
  final String _apiKey;
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  final String _model;
  final PromptEngine? _promptEngine; // Optional to maintain compatibility
  final PersonalityEngine? _personalityEngine;
  final ContextService? _contextService;

  OpenAIService({
    required String apiKey,
    String model = 'gpt-3.5-turbo',
    PromptEngine? promptEngine,
    ContextService? contextService,
    PersonalityEngine? personalityEngine,
  }) : _apiKey = apiKey,
       _model = model,
       _promptEngine = promptEngine,
       _contextService = contextService,
       _personalityEngine = personalityEngine;

  Future<Map<String, dynamic>> generateWorkoutRecommendation({
    required String userId,
    String? specificRequest,
    WorkoutCategory? category,
    int? maxMinutes,
    List<String>? equipment,
    List<String>? focusAreas,
  }) async {
    try {
      final categoryName = category?.name ?? 'fullBody';
      final minutes = maxMinutes ?? 30;
      final roundedMinutes = ((minutes / 5).round() * 5).clamp(5, 60);

      // Log what we're sending
      debugPrint('Generating workout with actual parameters:');
      debugPrint('Category: $categoryName');
      debugPrint('Duration: $roundedMinutes minutes');
      debugPrint(
        'Equipment: ${equipment != null ? equipment.join(", ") : "bodyweight"}',
      );
      debugPrint(
        'Focus Areas: ${focusAreas != null ? focusAreas.join(", ") : "overall fitness"}',
      );
      debugPrint('Special Request: ${specificRequest ?? "none"}');

      // Skip the prompt engine and build the system prompt directly
      final systemPrompt = '''
You are a fitness trainer creating a personalized workout.

CREATE A WORKOUT WITH THESE SPECIFICATIONS:
- Category: $categoryName
- Duration: $roundedMinutes minutes (must be exactly this duration)
- Equipment: ${equipment != null && equipment.isNotEmpty ? equipment.join(', ') : 'bodyweight'}
- Fitness level: beginner
- Focus areas: ${focusAreas != null && focusAreas.isNotEmpty ? focusAreas.join(', ') : 'overall fitness'}
- Special requests: ${specificRequest ?? ''}

IMPORTANT RULES:
1. STRICTLY maintain $roundedMinutes minutes total workout time
2. Use SPECIFIC exercise names (e.g., "Squats", "Push-ups", not generic "Exercise 1")
3. Include appropriate sets, reps, and rest periods
4. Design the workout to match the specified fitness level
5. Ensure exercises target the specified focus areas
6. For cardio exercises, use durationSeconds instead of reps
7. Ensure the workout is appropriate for the equipment specified

Respond ONLY with valid JSON in this exact format:
{
  "title": "Workout title",
  "description": "Brief workout description",
  "category": "$categoryName",
  "difficulty": "beginner",
  "durationMinutes": $roundedMinutes,
  "estimatedCaloriesBurn": integer,
  "equipment": ["item1", "item2"],
  "exercises": [
    {
      "name": "Specific Exercise Name",
      "description": "Clear instructions for the exercise",
      "targetArea": "Specific muscle group",
      "sets": integer,
      "reps": integer,
      "durationSeconds": integer or null,
      "restBetweenSeconds": integer
    }
  ]
}
''';

      // Log the prompt to debug
      debugPrint('Generate workout prompt: $systemPrompt');

      final messages = [
        {"role": "system", "content": systemPrompt},
        {
          "role": "user",
          "content": "Create a workout based on these specifications",
        },
      ];

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1000,
          'response_format': {"type": "json_object"},
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('API request failed: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];

      debugPrint('Raw AI response: $content');

      final workoutData = _parseWorkoutResponse(content);

      // Ensure the duration is set to the rounded minutes
      workoutData['durationMinutes'] = roundedMinutes;

      // Ensure category is correctly set
      workoutData['category'] = categoryName;

      return workoutData;
    } catch (e) {
      debugPrint('Error generating workout: $e');
      throw Exception('Failed to generate workout: ${e.toString()}');
    }
  }

  // Updated refineWorkout method in openai_service.dart
  Future<Map<String, dynamic>> refineWorkout({
    required String userId,
    required Map<String, dynamic> originalWorkout,
    required String refinementRequest,
    String? originalRequest, // Keep for backward compatibility, but don't use
  }) async {
    try {
      List<Map<String, dynamic>> messages;

      // Get essential data from the original workout
      final Map<String, dynamic> workoutEssentials = {
        'title': originalWorkout['title'],
        'description': originalWorkout['description'],
        'category': originalWorkout['category'],
        'difficulty': originalWorkout['difficulty'],
        'durationMinutes': originalWorkout['durationMinutes'],
        'exercises': originalWorkout['exercises'],
        'equipment': originalWorkout['equipment'] ?? [],
      };

      // Log the size of the original workout data for debugging
      debugPrint(
        'Original workout json size: ${jsonEncode(workoutEssentials).length} chars',
      );

      if (_promptEngine != null) {
        // Build system prompt directly, without depending on profile context
        final systemPrompt = _promptEngine.buildPrompt(
          templateId: 'workout_refinement',
          context: {},
          customVars: {
            'workoutDetails': jsonEncode(workoutEssentials),
            'userFeedback': refinementRequest,
          },
        );

        messages = [
          {"role": "system", "content": systemPrompt},
          {
            "role": "user",
            "content":
                "Please refine this workout based on my feedback: $refinementRequest",
          },
        ];
      } else {
        // Fallback implementation
        messages = [
          {
            "role": "system",
            "content": """
WORKOUT REFINEMENT TASK

Current workout to modify:
${jsonEncode(workoutEssentials)}

User wants to change: ${refinementRequest}

ESSENTIAL INSTRUCTIONS:
1. You MUST update the actual exercises based on the refinement request
2. Duration should be a multiple of 15 minutes (15, 30, 45, 60)
3. Use SPECIFIC exercise names (like "Squats", "Lunges", NOT "Exercise 1")
4. When adding exercises, provide full details (name, description, sets, reps, rest)
5. When modifying existing exercises, change the actual exercise data

IMPORTANT: If the refinement affects exercise selection, you MUST change the exercises array.

Respond with the complete modified workout in JSON format, plus a "changesSummary" field that explains exactly what you changed.
""",
          },
          {
            "role": "user",
            "content":
                "Refine this workout based on my feedback: $refinementRequest",
          },
        ];
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1500, // Increase max tokens for complete response
          'response_format': {"type": "json_object"},
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('API request failed: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];

      // Log the raw response to help with debugging
      debugPrint('Raw refinement response: $content');

      try {
        final Map<String, dynamic> parsedResponse = jsonDecode(content);

        // Extract changes summary
        String? changesSummary;
        if (parsedResponse.containsKey('changesSummary')) {
          changesSummary = parsedResponse['changesSummary'];
        } else {
          // Generate a basic summary if none provided
          changesSummary = 'Workout refined based on your feedback.';
          parsedResponse['changesSummary'] = changesSummary;
        }

        // Create the refined workout with the original ID preserved
        final refinedWorkout = Map<String, dynamic>.from(parsedResponse);
        refinedWorkout['id'] =
            originalWorkout['id'] ??
            'workout-${DateTime.now().millisecondsSinceEpoch}';

        // Ensure the changes summary is preserved
        refinedWorkout['changesSummary'] = changesSummary;

        // If the refined workout has no exercises but the original did, preserve them
        if (!refinedWorkout.containsKey('exercises') ||
            refinedWorkout['exercises'] == null ||
            (refinedWorkout['exercises'] as List).isEmpty) {
          debugPrint(
            'Preserving exercises from original workout as refined workout had none',
          );
          refinedWorkout['exercises'] = originalWorkout['exercises'];

          // Add this information to the changes summary
          if (changesSummary == 'Workout refined based on your feedback.') {
            refinedWorkout['changesSummary'] =
                'Workout parameters adjusted based on your feedback, maintaining the original exercises.';
          } else {
            refinedWorkout['changesSummary'] +=
                ' Original exercises preserved.';
          }
        }

        // Ensure the duration is a multiple of 15 minutes
        if (refinedWorkout.containsKey('durationMinutes') &&
            refinedWorkout['durationMinutes'] != null) {
          int duration = refinedWorkout['durationMinutes'] as int;
          int roundedDuration = ((duration / 15).round() * 15).clamp(15, 60);
          refinedWorkout['durationMinutes'] = roundedDuration;
        }

        // Make sure all necessary fields are present
        final requiredFields = [
          'title',
          'description',
          'category',
          'difficulty',
          'durationMinutes',
          'equipment',
        ];
        for (final field in requiredFields) {
          if (!refinedWorkout.containsKey(field) ||
              refinedWorkout[field] == null) {
            refinedWorkout[field] = originalWorkout[field];
          }
        }

        debugPrint(
          'Final refined workout: ${refinedWorkout.toString().substring(0, min(refinedWorkout.toString().length, 200))}...',
        );
        debugPrint(
          'Exercise count: ${(refinedWorkout['exercises'] as List?)?.length ?? 0}',
        );

        return refinedWorkout;
      } catch (e) {
        debugPrint('Error parsing refinement response: $e');
        throw Exception('Failed to parse AI response: ${e.toString()}');
      }
    } catch (e) {
      debugPrint('Error refining workout: $e');
      throw Exception('Failed to refine workout: ${e.toString()}');
    }
  }

  // Update enhancedChat method
  Future<String> enhancedChat({
    required String userId,
    required String message,
    required List<Map<String, String>> previousMessages,
  }) async {
    try {
      List<Map<String, dynamic>> messages;

      // Use our enhanced components if available
      if (_promptEngine != null &&
          _contextService != null &&
          _personalityEngine != null) {
        // Analyze user message to adapt personality
        _personalityEngine.analyzeUserMessage(userId, message);

        // Build context with user profile
        final context = await _contextService.buildContext(userId: userId);

        // Get personality settings for this user
        final personality = _personalityEngine.getPersonalityForUser(userId);

        // Detect message intent/category for template selection
        final messageIntent = detectMessageCategory(message);

        // Select appropriate prompt template
        final templateId = _getTemplateForIntent(messageIntent);

        // Build system prompt
        final systemPrompt = _promptEngine.buildPrompt(
          templateId: templateId,
          context: context.getAllContext(),
          customVars: {
            'personalityModifier': _personalityEngine.getPromptModifier(
              personality,
            ),
          },
        );

        messages = [
          {"role": "system", "content": systemPrompt},
          ...previousMessages.map(
            (m) => {"role": m["role"] ?? "user", "content": m["content"] ?? ""},
          ),
          {"role": "user", "content": message},
        ];
      } else {
        // Fallback to previous implementation
        messages = [
          {"role": "system", "content": "You are a helpful fitness assistant."},
          ...previousMessages.map(
            (m) => {"role": m["role"] ?? "user", "content": m["content"] ?? ""},
          ),
          {"role": "user", "content": message},
        ];
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.8,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('API request failed: ${response.body}');
      }

      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } catch (e) {
      debugPrint('Error in chat: $e');
      throw Exception('Error getting response: ${e.toString()}');
    }
  }

  // Add helper method for intent-to-template mapping
  String _getTemplateForIntent(String intent) {
    switch (intent) {
      case 'workout_advice':
        return 'workout_advice';
      case 'nutrition_advice':
        return 'nutrition_advice';
      case 'motivation':
        return 'motivation';
      case 'form_guidance':
        return 'form_guidance';
      default:
        return 'general_chat';
    }
  }

  // Implement a plan generation method if needed
  Future<String> generatePlan({
    required String userId,
    required int durationDays,
    required List<String> focusAreas,
    int? daysPerWeek,
    String? specialRequest,
  }) async {
    try {
      List<Map<String, dynamic>> messages;

      // Use our enhanced components if available
      if (_promptEngine != null &&
          _contextService != null &&
          _personalityEngine != null) {
        // Build context with user profile and feature-specific data
        final context = await _contextService.buildContext(
          userId: userId,
          featureData: {
            'duration': durationDays.toString(),
            'focusAreas': focusAreas.join(', '),
            'daysPerWeek': (daysPerWeek ?? 3).toString(),
            'specialRequest': specialRequest ?? '',
          },
        );

        // Get personality settings for this user
        final personality = _personalityEngine.getPersonalityForUser(userId);

        // Build system prompt
        final systemPrompt = _promptEngine.buildPrompt(
          templateId: 'plan_creation',
          context: context.getAllContext(),
          customVars: {
            'personalityModifier': _personalityEngine.getPromptModifier(
              personality,
            ),
          },
        );

        messages = [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": "Create a workout plan for me."},
        ];

        // Analyze user message if one was provided
        if (specialRequest != null && specialRequest.isNotEmpty) {
          _personalityEngine.analyzeUserMessage(userId, specialRequest);
        }
      } else {
        // Fallback implementation
        messages = [
          {
            "role": "system",
            "content":
                "You are a professional fitness coach creating a personalized workout plan.",
          },
          {
            "role": "user",
            "content":
                "Create a ${durationDays}-day workout plan focusing on ${focusAreas.join(', ')}. " +
                (daysPerWeek != null
                    ? "I want to work out $daysPerWeek days per week. "
                    : "") +
                (specialRequest ?? ""),
          },
        ];
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1500,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('API request failed: ${response.body}');
      }

      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } catch (e) {
      debugPrint('Error generating plan: $e');
      throw Exception('Failed to generate plan: ${e.toString()}');
    }
  }

  // Used in ai_chat_provider.dart
  String detectMessageCategory(String message) {
    message = message.toLowerCase();

    if (message.contains('workout') || message.contains('exercise')) {
      return 'workout_advice';
    } else if (message.contains('food') || message.contains('nutrition')) {
      return 'nutrition_advice';
    } else if (message.contains('motivat') || message.contains('inspire')) {
      return 'motivation';
    }

    return 'general';
  }

  // Private helper for parsing workout responses
  Map<String, dynamic> _parseWorkoutResponse(String response) {
    try {
      // First try to parse the entire response as JSON
      try {
        final Map<String, dynamic> directJson = jsonDecode(response);

        // If we successfully parsed it directly, add additional metadata
        directJson['id'] = 'workout-${DateTime.now().millisecondsSinceEpoch}';
        directJson['isAiGenerated'] = true;
        directJson['createdAt'] = DateTime.now().toIso8601String();
        directJson['createdBy'] = 'ai';

        return directJson;
      } catch (_) {
        // If direct parsing fails, try to extract JSON from text content
        final jsonRegex = RegExp(r'({[\s\S]*})');
        final match = jsonRegex.firstMatch(response);

        if (match != null) {
          final jsonStr = match.group(1);
          if (jsonStr != null) {
            final Map<String, dynamic> workoutData = jsonDecode(jsonStr);

            // Add additional metadata
            workoutData['id'] =
                'workout-${DateTime.now().millisecondsSinceEpoch}';
            workoutData['isAiGenerated'] = true;
            workoutData['createdAt'] = DateTime.now().toIso8601String();
            workoutData['createdBy'] = 'ai';

            return workoutData;
          }
        }

        // If all else fails, create a basic workout structure
        debugPrint(
          'Could not parse JSON from response, using fallback structure',
        );
        return {
          'id': 'workout-${DateTime.now().millisecondsSinceEpoch}',
          'title': 'Custom Workout',
          'description': 'A personalized workout created just for you.',
          'category': 'fullBody',
          'difficulty': 'beginner',
          'durationMinutes': 30,
          'estimatedCaloriesBurn': 150,
          'isAiGenerated': true,
          'createdAt': DateTime.now().toIso8601String(),
          'createdBy': 'ai',
          'exercises': extractExercisesFromText(response),
          'equipment': [],
          'tags': ['ai-generated'],
        };
      }
    } catch (e) {
      debugPrint('Error parsing workout response: $e');
      throw Exception('Failed to parse AI response into workout format');
    }
  }

  // Helper method to extract exercises from text when JSON parsing fails
  List<Map<String, dynamic>> extractExercisesFromText(String text) {
    final exercises = <Map<String, dynamic>>[];

    // Look for patterns like "1. Exercise Name - description"
    final exerciseRegex = RegExp(
      r'\d+\.\s+([^:]+)[:-]\s*(.*?)(?=\d+\.\s+|$)',
      dotAll: true,
    );
    final matches = exerciseRegex.allMatches(text);

    for (final match in matches) {
      if (match.groupCount >= 2) {
        final name = match.group(1)?.trim() ?? 'Unnamed Exercise';
        final description =
            match.group(2)?.trim() ?? 'No description available';

        exercises.add({
          'name': name,
          'description': description,
          'targetArea': 'Core',
          'sets': 3,
          'reps': 10,
          'restBetweenSeconds': 30,
        });
      }
    }

    // If we couldn't extract any exercises, add a placeholder
    if (exercises.isEmpty) {
      exercises.add({
        'name': 'Body Weight Squat',
        'description':
            'Stand with feet shoulder-width apart, then bend knees and hips to lower your body as if sitting in a chair. Keep chest up and knees tracking over toes. Return to standing.',
        'targetArea': 'Legs',
        'sets': 3,
        'reps': 12,
        'restBetweenSeconds': 30,
      });
    }

    return exercises;
  }
}
