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

  Future<Map<String, dynamic>> generatePlan({
    required String userId,
    required int durationDays,
    required List<String> focusAreas,
    int? daysPerWeek,
    String? fitnessLevel,
    String? variationType,
    String? specialRequest,
    Map<String, dynamic>? userProfileData,
  }) async {
    try {
      // Default to 3 days per week if not specified
      final workoutDays = daysPerWeek ?? 3;

      // Default to beginner if not specified
      final userLevel = fitnessLevel ?? 'beginner';

      // Convert variation type to a description
      String variationDescription = '';
      if (variationType != null) {
        switch (variationType) {
          case 'balanced':
            variationDescription = 'balanced mix of different workout types';
            break;
          case 'progressive':
            variationDescription =
                'gradually increasing intensity throughout the week';
            break;
          case 'alternating':
            variationDescription =
                'alternating between harder and easier workouts';
            break;
          case 'focused':
            variationDescription = 'focused primarily on specific body areas';
            break;
          default:
            variationDescription = 'balanced mix of different workout types';
        }
      }

      // Extract additional profile information if available
      final age = userProfileData?['age'];
      final userGoals = userProfileData?['goals'] as List<String>? ?? [];
      final preferredLocation = userProfileData?['preferredLocation'];
      final availableEquipment =
          userProfileData?['availableEquipment'] as List<String>? ?? [];
      final healthConditions =
          userProfileData?['healthConditions'] as List<String>? ?? [];

      // Build an enhanced system prompt with all the context
      final systemPrompt = '''
You are an expert fitness trainer creating a personalized ${durationDays}-day workout plan.
 
USER PROFILE:
- Fitness level: $userLevel
${age != null ? "- Age: $age\n" : ""}${userGoals.isNotEmpty ? "- Goals: ${userGoals.join(', ')}\n" : ""}
- Focus areas: ${focusAreas.join(', ')}
${healthConditions.isNotEmpty ? "- Health considerations: ${healthConditions.join(', ')}\n" : ""}
${availableEquipment.isNotEmpty ? "- Available equipment: ${availableEquipment.join(', ')}\n" : "- Equipment: Bodyweight exercises primarily\n"}
${preferredLocation != null ? "- Preferred workout location: $preferredLocation\n" : ""}

PLAN PARAMETERS:
- Duration: $durationDays days
- Workout frequency: $workoutDays days per week
- Plan type: $variationDescription
${specialRequest != null && specialRequest.isNotEmpty ? "- Special request: $specialRequest\n" : ""}

DESIGN PRINCIPLES:
1. Create a cohesive plan that feels like a professionally designed program
2. Balance workout intensity and recovery - don't schedule difficult workouts on consecutive days
3. Ensure proper progression and variety
4. Include a mix of workout types appropriate for the user's goals and focus areas
5. For EACH workout in the plan, create a COMPLETE workout with specific exercises, sets, reps, and rest periods
6. Include 1-2 rest days per week (depending on frequency)

RESPONSE FORMAT:
Respond ONLY with valid JSON in this exact format:
{
  "planName": "Name of the workout plan (be creative)",
  "planDescription": "Brief overview of the plan, goals and approach",
  "focusAreas": ["Primary focus area", "Secondary focus area"],
  "durationDays": $durationDays,
  "daysPerWeek": $workoutDays,
  "fitnessLevel": "$userLevel",
  "scheduledWorkouts": [
    {
      "dayNumber": 1,
      "isRestDay": false,
      "workoutName": "Name of the workout",
      "category": "bums/tums/fullBody/cardio/quickWorkout",
      "difficulty": "beginner/intermediate/advanced",
      "durationMinutes": 30,
      "description": "Brief description of this workout",
      "targetAreas": ["Primary area", "Secondary area"],
      "exercises": [
        {
          "name": "Exercise Name",
          "description": "Exercise instructions",
          "sets": 3,
          "reps": 12,
          "durationSeconds": null,
          "restBetweenSeconds": 30,
          "targetArea": "Specific muscle group"
        }
      ],
      "equipment": ["Equipment needed for this workout"]
    },
    // Additional days...
  ],
  "recommendedEquipment": ["Equipment needed across all workouts"],
  "weeklyProgressionStrategy": "How the plan progresses over time",
  "successTips": ["2-3 tips for successfully completing this plan"]
}
''';

      debugPrint(
        'Generate plan prompt: ${systemPrompt.substring(0, min(200, systemPrompt.length))}...',
      );

      final messages = [
        {"role": "system", "content": systemPrompt},
        {
          "role": "user",
          "content": "Create a workout plan based on these specifications",
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
          'max_tokens': 2000,
          'response_format': {"type": "json_object"},
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('API request failed: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];

      debugPrint(
        'Raw plan response: ${content.substring(0, min(200, content.length))}...',
      );

      // Parse the response
      try {
        final Map<String, dynamic> planData = jsonDecode(content);

        // Process the received data to create actual workouts
        final processedPlanData = await _processGeneratedPlan(planData, userId);

        return processedPlanData;
      } catch (e) {
        debugPrint('Error parsing plan response: $e');
        throw Exception('Failed to parse AI response into plan format');
      }
    } catch (e) {
      debugPrint('Error generating plan: $e');
      throw Exception('Failed to generate plan: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> _processGeneratedPlan(
    Map<String, dynamic> planData,
    String userId,
  ) async {
    // Create a copy of the plan data to modify
    final processedPlan = Map<String, dynamic>.from(planData);

    // Add metadata
    processedPlan['id'] = 'plan-${DateTime.now().millisecondsSinceEpoch}';
    processedPlan['isAiGenerated'] = true;
    processedPlan['createdAt'] = DateTime.now().toIso8601String();
    processedPlan['createdBy'] = 'ai';
    processedPlan['userId'] = userId;

    // Convert the scheduled workouts into actual workout entities with IDs
    final scheduledWorkouts =
        (planData['scheduledWorkouts'] as List<dynamic>?) ?? [];
    final processedWorkouts = <Map<String, dynamic>>[];

    for (int i = 0; i < scheduledWorkouts.length; i++) {
      final workoutData = scheduledWorkouts[i] as Map<String, dynamic>;

      // Skip rest days
      if (workoutData['isRestDay'] == true) {
        processedWorkouts.add(workoutData);
        continue;
      }

      // Create a unique ID for this workout
      final workoutId = 'workout-${DateTime.now().millisecondsSinceEpoch}-$i';

      // Create the workout entity
      final workout = {
        'id': workoutId,
        'title':
            workoutData['workoutName'] ??
            'Day ${workoutData['dayNumber']} Workout',
        'description':
            workoutData['description'] ??
            'Generated workout for day ${workoutData['dayNumber']}',
        'category': workoutData['category'] ?? 'fullBody',
        'difficulty': workoutData['difficulty'] ?? 'beginner',
        'durationMinutes': workoutData['durationMinutes'] ?? 30,
        'estimatedCaloriesBurn': _estimateCalories(workoutData),
        'isAiGenerated': true,
        'createdAt': DateTime.now().toIso8601String(),
        'createdBy': 'ai',
        'exercises': workoutData['exercises'] ?? [],
        'equipment': workoutData['equipment'] ?? [],
        'tags': ['ai-generated', 'plan-workout'],
        'imageUrl': '', // Default empty image URL
      };

      // Update the workout data with the ID reference and remove exercises field
      // (exercises will be stored in the workout document)
      final updatedWorkoutData = Map<String, dynamic>.from(workoutData);
      updatedWorkoutData['workoutId'] = workoutId;
      updatedWorkoutData.remove(
        'exercises',
      ); // Exercises are now in the workout entity

      processedWorkouts.add(updatedWorkoutData);

      // Add this workout to a new field that will hold the complete workout objects
      if (!processedPlan.containsKey('workouts')) {
        processedPlan['workouts'] = [];
      }
      (processedPlan['workouts'] as List).add(workout);
    }

    // Update the scheduledWorkouts field with our processed data
    processedPlan['scheduledWorkouts'] = processedWorkouts;

    return processedPlan;
  }

  // Helper method to estimate calories based on workout data
  int _estimateCalories(Map<String, dynamic> workoutData) {
    // Default base calories
    int baseCalories = 200;

    // Adjust based on duration
    final durationMinutes = workoutData['durationMinutes'] as int? ?? 30;
    baseCalories = (baseCalories * durationMinutes / 30).round();

    // Adjust based on difficulty
    final difficulty = workoutData['difficulty'] as String? ?? 'beginner';
    switch (difficulty.toLowerCase()) {
      case 'intermediate':
        baseCalories = (baseCalories * 1.2).round();
        break;
      case 'advanced':
        baseCalories = (baseCalories * 1.4).round();
        break;
    }

    // Adjust based on workout type
    final category = workoutData['category'] as String? ?? 'fullBody';
    switch (category.toLowerCase()) {
      case 'cardio':
        baseCalories = (baseCalories * 1.3).round();
        break;
      case 'fullbody':
        baseCalories = (baseCalories * 1.2).round();
        break;
    }

    return baseCalories;
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

  WorkoutCategory? _categoryFromString(String category) {
    switch (category.toLowerCase()) {
      case 'bums':
        return WorkoutCategory.bums;
      case 'tums':
        return WorkoutCategory.tums;
      case 'fullbody':
      case 'full body':
        return WorkoutCategory.fullBody;
      case 'cardio':
        return WorkoutCategory.cardio;
      case 'quickworkout':
      case 'quick workout':
      case 'quick':
        return WorkoutCategory.quickWorkout;
      default:
        return WorkoutCategory.fullBody;
    }
  }
}
