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
    String? fitnessLevel,
    int? age,
    List<String>? goals,
    String? preferredLocation,
    List<String>? healthConditions,
    Map<String, dynamic>?
    consultationResponses, // Make sure this parameter exists
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

      // Add debug log for consultation responses
      debugPrint('Consultation responses: $consultationResponses');

      // Process consultation responses if available
      String consultationSection = '';
      if (consultationResponses != null && consultationResponses.isNotEmpty) {
        consultationSection = '\nUSER PREFERENCES FROM CONSULTATION:\n';

        // Handle response format from ConsultationStep
        if (consultationResponses.containsKey('q1') ||
            consultationResponses.keys.any((k) => k.startsWith('answer_'))) {
          // Format for direct key-value answers
          consultationResponses.forEach((key, value) {
            consultationSection += "- $value\n";
          });
        } else if (consultationResponses.containsKey('questions')) {
          // Format for questions array
          final questions = consultationResponses['questions'];
          if (questions is List) {
            for (var i = 0; i < questions.length; i++) {
              final q = questions[i];
              if (q is Map) {
                final question = q['question'];
                final answer = q['answer'];
                if (question != null && answer != null) {
                  consultationSection += "- $question: $answer\n";
                }
              }
            }
          }
        } else {
          // General format - try to extract any useful information
          consultationResponses.forEach((key, value) {
            if (value is Map &&
                value.containsKey('question') &&
                value.containsKey('answer')) {
              consultationSection +=
                  "- ${value['question']}: ${value['answer']}\n";
            } else {
              // Just include key-value pairs directly
              consultationSection += "- $key: $value\n";
            }
          });
        }

        debugPrint(
          'Adding consultation section to prompt: $consultationSection',
        );
      }

      // Construct an enhanced system prompt with user profile information and consultation data
      final systemPrompt = '''
You are a creative fitness trainer designing a personalized workout experience. Your goal is to create an effective, engaging workout that feels custom-made.

USER PROFILE:
- Fitness level: ${fitnessLevel ?? "beginner"}
${age != null ? "- Age: $age\n" : ""}${goals != null && goals.isNotEmpty ? "- Goals: ${goals.join(', ')}\n" : ""}
- Focus areas: ${focusAreas != null && focusAreas.isNotEmpty ? focusAreas.join(', ') : 'overall fitness'}
${healthConditions != null && healthConditions.isNotEmpty ? "- Health considerations: ${healthConditions.join(', ')}\n" : ""}

WORKOUT PARAMETERS:
- Category: $categoryName
- Duration: $roundedMinutes minutes
- Available equipment: ${equipment != null && equipment.isNotEmpty ? equipment.join(', ') : 'bodyweight only'}
${specificRequest != null && specificRequest.isNotEmpty ? "- Special request: $specificRequest\n" : ""}
$consultationSection

DESIGN PRINCIPLES:
1. Create a workout that fits exactly $roundedMinutes minutes
2. View equipment as available resources, not requirements - use what makes sense for the best workout
3. Incorporate exercise variety and unexpected combinations while maintaining safety and effectiveness
4. Consider proper exercise sequencing (warm-up, main work, cool-down)
5. Design with the user's fitness level and goals in mind

BE CREATIVE:
- Feel free to introduce novel exercise combinations
- Consider how exercises flow together
- Mix equipment-based and bodyweight movements where appropriate
- Add engaging elements like circuits, intervals, or challenges

Respond ONLY with valid JSON in this exact format:
{
  "title": "Workout title - make it engaging and descriptive",
  "description": "Brief workout description including goals and approach",
  "category": "$categoryName",
  "difficulty": "${fitnessLevel ?? "beginner"}",
  "durationMinutes": $roundedMinutes,
  "estimatedCaloriesBurn": integer,
  "equipment": ["only list equipment actually used"],
  "exercises": [
    {
      "name": "Specific Exercise Name",
      "description": "Clear instructions for the exercise",
      "targetArea": "Primary muscle group",
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

  Future<Map<String, dynamic>> refineWorkout({
    required String userId,
    required Map<String, dynamic> originalWorkout,
    required String refinementRequest,
    String? originalRequest,
  }) async {
    try {
      // Create a cleaner version of the original workout for the prompt
      // Include only the essential properties to keep the prompt size manageable
      final Map<String, dynamic> workoutEssentials = {
        'title': originalWorkout['title'],
        'description': originalWorkout['description'],
        'category': originalWorkout['category'],
        'difficulty': originalWorkout['difficulty'],
        'durationMinutes': originalWorkout['durationMinutes'],
        'equipment': originalWorkout['equipment'] ?? [],
        'exercises': originalWorkout['exercises'],
      };

      // Build a more explicit prompt for refinement
      final systemPrompt = '''
WORKOUT REFINEMENT TASK

I have a workout that I want to refine based on specific feedback. DO NOT create an entirely new workout - 
I need you to modify the EXISTING workout while preserving its core structure and purpose.

CURRENT WORKOUT:
${jsonEncode(workoutEssentials)}

USER REFINEMENT REQUEST: "${refinementRequest}"

INSTRUCTIONS:
1. MODIFY the existing workout - do not create an entirely new one
2. Keep the same category and general structure
3. Make specific changes based on the refinement request
4. Preserve the existing exercise structure where possible
5. ALWAYS include a complete "exercises" array in your response
6. Return the complete modified workout JSON

Your response should be VALID JSON with these fields:
- title (can be updated based on changes)
- description (can be updated to reflect changes)
- category (should generally remain the same)
- difficulty (can be adjusted based on the request)
- durationMinutes (can be adjusted but should be a multiple of 15)
- equipment (can be updated based on the request)
- exercises (MUST include the complete array with all modifications)
- changesSummary (a brief explanation of what you changed)

DO NOT nest the workout under another object. Respond with the direct workout JSON.
''';

      final messages = [
        {"role": "system", "content": systemPrompt},
        {
          "role": "user",
          "content":
              "Please refine this workout based on my feedback: $refinementRequest",
        },
      ];

      // Add debug logging
      debugPrint(
        'Original workout json size: ${jsonEncode(workoutEssentials).length} chars',
      );

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
          'response_format': {"type": "json_object"},
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('API request failed: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];

      // Debug logging
      debugPrint('Raw API Response:');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint(
        'Response content (first 200 chars): ${content.substring(0, min(200, content.length))}...',
      );

      try {
        final Map<String, dynamic> parsedResponse = jsonDecode(content);

        // Handle nested workout structure if present
        Map<String, dynamic> workoutData;
        if (parsedResponse.containsKey('workout')) {
          // Extract the workout from nested structure
          workoutData = Map<String, dynamic>.from(parsedResponse['workout']);

          // Check if there's a changes summary at the root level
          if (parsedResponse.containsKey('changesSummary')) {
            workoutData['changesSummary'] = parsedResponse['changesSummary'];
          }
        } else {
          // Response is already in the expected format
          workoutData = parsedResponse;
        }

        // Extract changes summary
        String? changesSummary;
        if (workoutData.containsKey('changesSummary')) {
          changesSummary = workoutData['changesSummary'];
          workoutData.remove('changesSummary');
        } else {
          // Generate a basic summary if none provided
          changesSummary = 'Workout refined based on your feedback.';
        }

        // Create the refined workout with the original ID preserved
        final refinedWorkout = Map<String, dynamic>.from(workoutData);
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

        // Ensure the workout maintains critical fields from the original if missing
        final originalFields = [
          'category',
          'title',
          'difficulty',
          'durationMinutes',
          'equipment',
        ];
        for (final field in originalFields) {
          if (!refinedWorkout.containsKey(field) ||
              refinedWorkout[field] == null) {
            refinedWorkout[field] = originalWorkout[field];
          }
        }

        // Make sure title is present (use the "name" field if provided)
        if (!refinedWorkout.containsKey('title') &&
            refinedWorkout.containsKey('name')) {
          refinedWorkout['title'] = refinedWorkout['name'];
          refinedWorkout.remove('name');
        }

        // Fix any "duration" field instead of "durationMinutes"
        if (!refinedWorkout.containsKey('durationMinutes') &&
            refinedWorkout.containsKey('duration')) {
          refinedWorkout['durationMinutes'] = refinedWorkout['duration'];
          refinedWorkout.remove('duration');
        }

        // Ensure duration is a multiple of 15 minutes
        if (refinedWorkout.containsKey('durationMinutes')) {
          final duration = refinedWorkout['durationMinutes'];
          if (duration is int) {
            final roundedDuration = ((duration / 15).round() * 15).clamp(
              15,
              60,
            );
            refinedWorkout['durationMinutes'] = roundedDuration;
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
