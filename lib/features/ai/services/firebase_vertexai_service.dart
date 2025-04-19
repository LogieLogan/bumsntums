// lib/features/ai/services/firebase_vertexai_service.dart

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/foundation.dart';
import 'package:bums_n_tums/features/ai/services/ai_service.dart';
import 'package:bums_n_tums/features/workouts/models/workout.dart';

class FirebaseVertexAIService implements AIService {
  late final GenerativeModel _model;
  final String _modelName = 'gemini-1.5-flash';
  final String _systemInstruction = """
You are a creative and knowledgeable fitness trainer specializing in beginner women's fitness (weight loss and toning).
Your primary role is to provide helpful, encouraging, and concise fitness advice in conversational text format. Avoid overly technical jargon.
Your expertise covers fitness, well-being, health, motivation, nutrition, lifestyle, coaching, sport, and leisure related topics.
If asked about unrelated topics (e.g., politics, finance, specific medical diagnoses beyond general wellness advice), politely state that it's outside your scope as a fitness coach and redirect the conversation back to fitness or wellness topics.
IMPORTANT: Respond naturally in plain text for all general chat interactions.
EXCEPTION: If the user's message explicitly asks to "generate a workout" or "refine a workout" AND provides parameters, THEN and ONLY THEN respond ONLY with the required valid JSON object structure, without any additional text, comments, or markdown formatting.
""";
  //

  FirebaseVertexAIService() {
    _model = FirebaseVertexAI.instance.generativeModel(
      model: _modelName,
      systemInstruction: Content.system(_systemInstruction),

      generationConfig: GenerationConfig(temperature: 0.7, candidateCount: 1),
    );
    debugPrint(
      "FirebaseVertexAIService initialized model: $_modelName with system instruction.",
    );
  }

  @override
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
    Map<String, dynamic>? consultationResponses,
  }) async {
    final categoryName = category?.name ?? 'fullBody';
    final minutes = maxMinutes ?? 30;
    final roundedMinutes = ((minutes / 5).round() * 5).clamp(15, 90);

    debugPrint('FirebaseVertexAI: Generating workout for user $userId');

    String consultationSection = '';
    if (consultationResponses != null && consultationResponses.isNotEmpty) {
      consultationSection = '\nUSER PREFERENCES FROM CONSULTATION:\n';
      consultationResponses.forEach((key, value) {
        consultationSection += "- $key: ${value.toString()}\n";
      });
    }

    final prompt = """
Generate a personalized workout plan based on the following details. Respond ONLY with a valid JSON object matching the specified structure. Do not include any explanatory text, markdown formatting (like ```json), or comments before or after the JSON object itself.

USER PROFILE:
- User ID: $userId
- Fitness level: ${fitnessLevel ?? "beginner"}
${age != null ? "- Age: $age\n" : ""}
${goals != null && goals.isNotEmpty ? "- Goals: ${goals.join(', ')}\n" : ""}
- Focus areas: ${focusAreas != null && focusAreas.isNotEmpty ? focusAreas.join(', ') : 'overall fitness'}
${healthConditions != null && healthConditions.isNotEmpty ? "- Health considerations (adapt exercises accordingly): ${healthConditions.join(', ')}\n" : ""}
${preferredLocation != null ? "- Preferred workout location: $preferredLocation\n" : ""}

WORKOUT REQUIREMENTS:
- Category: $categoryName
- Target Duration: Exactly $roundedMinutes minutes (total time)
- Available equipment: ${equipment != null && equipment.isNotEmpty ? equipment.join(', ') : 'bodyweight only'}
${specificRequest != null && specificRequest.isNotEmpty ? "- Special user request: $specificRequest\n" : ""}
$consultationSection

DESIGN PRINCIPLES:
1. Structure: Include "Warm-up", "Main Workout", "Cool-down" in 'sections'.
2. Duration: Total time near ${roundedMinutes} min. Top-level 'durationMinutes' MUST be ${roundedMinutes}.
3. Equipment: Use available items. List ONLY used items in 'equipment' array.
4. Suitability: Beginner-friendly, safe exercises matching profile.
5. Clarity: Clear exercise descriptions. Include 'targetArea'.

REQUIRED JSON OUTPUT STRUCTURE:
{
  "title": "string (Engaging Workout Title)",
  "description": "string (Brief workout description)",
  "category": "$categoryName",
  "difficulty": "${fitnessLevel ?? "beginner"}",
  "durationMinutes": $roundedMinutes,
  "estimatedCaloriesBurn": number (Optional),
  "equipment": ["string (only list equipment actually used)"],
  "tags": ["string"] (Optional),
  
  "exercises": [
    {
      "name": "string (Specific Exercise Name - REQUIRED)",
      "description": "string (Clear instructions - REQUIRED)",
      "targetArea": "string (Primary muscle group - Optional)",
      "sets": number (REQUIRED),
      "reps": number (Optional, use EITHER reps OR durationSeconds),
      "durationSeconds": number (Optional),
      "restBetweenSeconds": number (REQUIRED)
    }
    
  ] 
}
""";

    try {
      debugPrint("Sending generation request to Vertex AI Gemini...");
      final generationConfig = GenerationConfig(
        responseMimeType: "application/json",
        temperature: 0.6,
      );

      final response = await _model.generateContent([
        Content.text(prompt),
      ], generationConfig: generationConfig);

      final responseText = response.text;
      debugPrint("Raw Vertex AI workout response: $responseText");

      if (responseText == null || responseText.trim().isEmpty) {
        final blockReason = response.promptFeedback?.blockReason;
        final safetyRatings = response.candidates?.first.safetyRatings;
        debugPrint(
          "Vertex AI Error: Empty or blocked response. Reason: $blockReason, Ratings: $safetyRatings",
        );
        throw Exception(
          blockReason != null
              ? 'Request blocked by safety filters: ${blockReason.name}'
              : 'AI service returned an empty response.',
        );
      }

      try {
        final Map<String, dynamic> workoutData = jsonDecode(responseText);
        workoutData['id'] = 'workout-${DateTime.now().millisecondsSinceEpoch}';
        workoutData['isAiGenerated'] = true;
        workoutData['createdAt'] = DateTime.now().toIso8601String();
        workoutData['createdBy'] = 'ai_firebase_vertexai';

        if (workoutData['title'] == null || workoutData['sections'] == null) {
          debugPrint(
            "Warning: Parsed workout JSON missing key fields (title/sections).",
          );
        }
        workoutData['durationMinutes'] = roundedMinutes;
        workoutData['category'] = categoryName;

        debugPrint("Workout generated and parsed successfully.");
        return workoutData;
      } catch (e) {
        debugPrint("JSON Parsing Error: $e");
        throw Exception('Failed to parse AI response into workout format.');
      }
    } on FirebaseException catch (e) {
      debugPrint(
        "FirebaseException during workout generation: ${e.code} - ${e.message}",
      );
      throw Exception(
        "Network or Firebase error generating workout: ${e.message}",
      );
    } catch (e) {
      debugPrint("Error generating workout via Firebase Vertex AI: $e");
      throw Exception('Failed to generate workout: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> refineWorkout({
    required String userId,
    required Map<String, dynamic> originalWorkout,
    required String refinementRequest,
    String? originalRequest,
  }) async {
    debugPrint('FirebaseVertexAI: Refining workout for user $userId');

    final workoutToRefine =
        originalWorkout.containsKey('sections')
            ? Map<String, dynamic>.from(originalWorkout)
            : _structureFlatWorkout(originalWorkout);

    final Map<String, dynamic> workoutContext = {
      'title': workoutToRefine['title'],
      'description': workoutToRefine['description'],
      'category': workoutToRefine['category'],
      'difficulty': workoutToRefine['difficulty'],
      'durationMinutes': workoutToRefine['durationMinutes'],
      'equipment': workoutToRefine['equipment'] ?? [],
      'sections': workoutToRefine['sections'] ?? [],
    };

    final prompt = """
Refine the following JSON workout based *only* on the user's request. Respond ONLY with the complete, modified, valid JSON object for the workout, including a 'changesSummary'. Do not add any text before or after the JSON.

CURRENT WORKOUT JSON:
```json
${jsonEncode(workoutContext)}
USER REFINEMENT REQUEST: "$refinementRequest"
originalRequest"" : ""}
INSTRUCTIONS:
Modify the CURRENT WORKOUT JSON based strictly on the USER REFINEMENT REQUEST.
Maintain overall structure (Warm-up, Main, Cool-down sections).
Adjust exercises, sets, reps, duration, rest, equipment as needed.
If duration changes, update durationMinutes (keep multiple of 5).
Update title, description, equipment, tags if necessary.
Provide a brief changesSummary field within the JSON explaining modifications.
REQUIRED JSON OUTPUT STRUCTURE (same as input, plus changesSummary):
{
  "title": "Updated Title (if changed)",
  "description": "Updated Description (if changed)",
  "category": "${workoutContext['category']}",
  "difficulty": "Updated Difficulty (if changed)",
  "durationMinutes": integer, 
  "estimatedCaloriesBurn": number (Optional),
  "equipment": ["Updated list of ALL needed equipment"],
  "tags": ["Updated list of relevant tags"],
  
  "exercises": [ /* Fully updated list of exercise objects */ ], 
  "changesSummary": "string (Brief explanation of changes made)."
}
""";
    try {
      debugPrint("Sending refinement request to Vertex AI Gemini...");
      final generationConfig = GenerationConfig(
        responseMimeType: "application/json",
        temperature: 0.5,
      );

      final response = await _model.generateContent([
        Content.text(prompt),
      ], generationConfig: generationConfig);

      final responseText = response.text;
      debugPrint("Raw Vertex AI refine response: $responseText");

      if (responseText == null || responseText.trim().isEmpty) {
        final blockReason = response.promptFeedback?.blockReason;
        debugPrint(
          "Vertex AI Error: Empty/blocked refinement response. Reason: $blockReason",
        );
        throw Exception(
          blockReason != null
              ? 'Refinement request blocked by safety filters: ${blockReason.name}'
              : 'AI service returned an empty response during refinement.',
        );
      }

      try {
        final Map<String, dynamic> refinedWorkoutData = jsonDecode(
          responseText,
        );

        refinedWorkoutData['id'] =
            workoutToRefine['id'] ??
            'refined-workout-${DateTime.now().millisecondsSinceEpoch}';
        refinedWorkoutData['isAiGenerated'] = true;
        refinedWorkoutData['createdAt'] =
            workoutToRefine['createdAt'] ?? DateTime.now().toIso8601String();
        refinedWorkoutData['createdBy'] = 'ai_firebase_vertexai_refined';

        if (refinedWorkoutData['durationMinutes'] is int) {
          final duration = refinedWorkoutData['durationMinutes'] as int;
          refinedWorkoutData['durationMinutes'] = ((duration / 5).round() * 5)
              .clamp(15, 90);
        } else {
          refinedWorkoutData['durationMinutes'] =
              workoutToRefine['durationMinutes'];
        }

        if (refinedWorkoutData['changesSummary'] == null) {
          refinedWorkoutData['changesSummary'] =
              "Workout refined (summary missing).";
        }

        debugPrint("Workout refined and parsed successfully.");
        return refinedWorkoutData;
      } catch (e) {
        debugPrint("JSON Parsing Error during refinement: $e");
        throw Exception('Failed to parse AI refinement response.');
      }
    } on FirebaseException catch (e) {
      debugPrint(
        "FirebaseException during workout refinement: ${e.code} - ${e.message}",
      );
      throw Exception(
        "Network or Firebase error refining workout: ${e.message}",
      );
    } catch (e) {
      debugPrint("Error refining workout via Firebase Vertex AI: $e");
      throw Exception('Failed to refine workout: ${e.toString()}');
    }
  }

  @override
  Future<String> enhancedChat({
    required String userId,
    required String message,
    required List<Map<String, String>> previousMessages,
    Map<String, dynamic>? userProfileData,
  }) async {
    debugPrint("------------------------------------------");
    debugPrint("FirebaseVertexAIService.enhancedChat called:");
    debugPrint("  UserId: $userId");
    debugPrint("  Message: $message");
    debugPrint("  PreviousMessages Count: ${previousMessages.length}");

    debugPrint(
      "  Received UserProfileData: ${userProfileData == null ? 'null' : userProfileData.toString()}",
    );

    List<Content> chatHistoryWithContext = [];

    if (userProfileData != null && userProfileData.isNotEmpty) {
      String profileSummary = "User Profile Summary:\n";
      profileSummary +=
          "- Fitness Level: ${userProfileData['fitnessLevel'] ?? 'N/A'}\n";
      profileSummary +=
          "- Goals: ${(userProfileData['goals'] as List?)?.join(', ') ?? 'N/A'}\n";
      profileSummary += "- Age: ${userProfileData['age'] ?? 'N/A'}\n";

      debugPrint("  Formatted Profile Summary for Context:\n$profileSummary");

      chatHistoryWithContext.add(
        Content('user', [
          TextPart(
            "CONTEXT:\n$profileSummary\nRemember this context and tailor your fitness advice accordingly.",
          ),
        ]),
      );
      debugPrint("  Added profile context part.");
    } else {
      debugPrint("  No userProfileData provided, skipping profile context.");
    }

    final history =
        previousMessages.map((m) {
          final role = m['role'] == 'assistant' ? 'model' : 'user';
          return Content(role, [TextPart(m['content'] ?? '')]);
        }).toList();

    chatHistoryWithContext.addAll(history);

    debugPrint(
      "  Added ${history.length} previous messages to chatHistoryWithContext.",
    );
    debugPrint(
      "  Total parts in chatHistoryWithContext BEFORE sending: ${chatHistoryWithContext.length}",
    );

    try {
      final chat = _model.startChat(history: chatHistoryWithContext);
      debugPrint(
        "Sending chat message ('${message}') to Vertex AI Gemini with history/context...",
      );

      final response = await chat.sendMessage(Content.text(message));

      final responseText = response.text;
      debugPrint("Raw Vertex AI chat response: $responseText");
      debugPrint("------------------------------------------");
      if (responseText == null || responseText.trim().isEmpty) {
        final blockReason = response.promptFeedback?.blockReason;
        throw Exception(
          blockReason != null
              ? 'Blocked: ${blockReason.name}'
              : 'Empty response.',
        );
      }
      return responseText.trim();
    } on FirebaseException catch (e) {
      debugPrint("------------------------------------------");
      throw Exception("Firebase error during chat: ${e.message}");
    } catch (e) {
      debugPrint("------------------------------------------");
      throw Exception('Failed to get chat response: ${e.toString()}');
    }
  }

  @override
  String detectMessageCategory(String message) {
    message = message.toLowerCase();
    if (message.contains('workout') ||
        message.contains('exercise') ||
        message.contains('train') ||
        message.contains('routine') ||
        message.contains('sets') ||
        message.contains('reps')) {
      return 'workout_advice';
    } else if (message.contains('food') ||
        message.contains('nutrition') ||
        message.contains('diet') ||
        message.contains('eat') ||
        message.contains('calorie') ||
        message.contains('meal')) {
      return 'nutrition_advice';
    } else if (message.contains('motivat') ||
        message.contains('inspire') ||
        message.contains('encourage') ||
        message.contains('struggl') ||
        message.contains('keep going')) {
      return 'motivation';
    } else if (message.contains('how to do') ||
        message.contains('form') ||
        message.contains('correct way') ||
        message.contains('technique')) {
      return 'form_guidance';
    } else if (message.contains('hi') ||
        message.contains('hello') ||
        message.contains('how are you')) {
      return 'greeting';
    }
    return 'general';
  }

  Map<String, dynamic> _structureFlatWorkout(Map<String, dynamic> flatWorkout) {
    debugPrint("Structuring flat workout for refinement context...");
    final structured = Map<String, dynamic>.from(flatWorkout);
    final exercises = structured.remove('exercises');
    if (exercises is List && exercises.isNotEmpty) {
      structured['sections'] = [
        {'name': 'Warm-up', 'durationMinutes': 5, 'exercises': []},
        {
          'name': 'Main Workout',
          'durationMinutes': (structured['durationMinutes'] ?? 30) - 10,
          'exercises': List<Map<String, dynamic>>.from(
            exercises.whereType<Map<String, dynamic>>(),
          ),
        },
        {'name': 'Cool-down', 'durationMinutes': 5, 'exercises': []},
      ];
    } else {
      structured['sections'] = [
        {'name': 'Warm-up', 'durationMinutes': 5, 'exercises': []},
        {
          'name': 'Main Workout',
          'durationMinutes': (structured['durationMinutes'] ?? 30) - 10,
          'exercises': [],
        },
        {'name': 'Cool-down', 'durationMinutes': 5, 'exercises': []},
      ];
    }
    return structured;
  }
}
