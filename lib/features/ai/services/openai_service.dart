// lib/features/ai/services/openai_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../features/auth/models/user_profile.dart';
import '../../../features/workouts/models/workout.dart';
import '../../../features/auth/services/fitness_profile_service.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import 'package:uuid/uuid.dart';

class OpenAIService {
  final String _apiKey;
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  final String _model =
      'gpt-3.5-turbo'; // Using smaller model for cost efficiency
  final FitnessProfileService _fitnessProfileService;
  final AnalyticsService _analytics = AnalyticsService();

  OpenAIService({
    required String apiKey,
    required FitnessProfileService fitnessProfileService,
  }) : _apiKey = apiKey,
       _fitnessProfileService = fitnessProfileService;

  // Modified method signature to use userId instead of UserProfile
  Future<Map<String, dynamic>> generateWorkoutRecommendation({
    required String userId,
    String? specificRequest,
    WorkoutCategory? category,
    int? maxMinutes,
  }) async {
    try {
      // Fetch fitness profile data from Firestore
      final profileData = await _fitnessProfileService.getFitnessProfileForAI(
        userId,
      );

      // Construct the workout generation prompt
      final messages = _buildWorkoutPrompt(
        profileData: profileData,
        specificRequest: specificRequest,
        category: category,
        maxMinutes: maxMinutes,
      );

      // Make API request
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
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _analytics.logEvent(
          name: 'ai_workout_generated',
          parameters: {
            'user_id': userId,
            'category': category?.name ?? 'fullBody',
            'max_minutes': maxMinutes?.toString() ?? 'default',
            'token_count':
                data['usage']['total_tokens']?.toString() ?? 'unknown',
          },
        );

        // Parse AI response into structured workout
        return _parseWorkoutResponse(data['choices'][0]['message']['content']);
      } else {
        throw Exception('Failed to generate workout: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error generating workout: $e');
      rethrow;
    }
  }

  List<Map<String, String>> _buildWorkoutPrompt({
    required Map<String, dynamic> profileData,
    String? specificRequest,
    WorkoutCategory? category,
    int? maxMinutes,
  }) {
    // System message with constraints and format instructions
    final systemMessage = '''
    You are a professional fitness trainer specialized in creating personalized workouts for women focusing on weight loss and toning. 
    
    Create a structured workout plan based on the user's profile:
    - Fitness level: ${profileData['fitnessLevel']}
    - Goals: ${(profileData['goals'] as List<dynamic>?)?.join(', ') ?? 'General fitness'}
    - Focus areas: ${(profileData['bodyFocusAreas'] as List<dynamic>?)?.join(', ') ?? 'Full body'}
    - Available equipment: ${(profileData['availableEquipment'] as List<dynamic>?)?.isEmpty == true ? 'None' : (profileData['availableEquipment'] as List<dynamic>?)?.join(', ')}
    - Preferred location: ${profileData['preferredLocation'] ?? 'Anywhere'}
    - Duration preference: ${maxMinutes ?? profileData['workoutDurationMinutes'] ?? 30} minutes
    - Health considerations: ${(profileData['healthConditions'] as List<dynamic>?)?.isEmpty == true ? 'None' : (profileData['healthConditions'] as List<dynamic>?)?.join(', ')}
    
    Generate a ${category?.name ?? "full body"} workout with the following JSON structure:
    {
      "title": "Workout title",
      "description": "Brief description of the workout benefits",
      "category": "${category?.name ?? 'fullBody'}",
      "difficulty": "beginner|intermediate|advanced (based on user level)",
      "durationMinutes": duration in minutes as integer,
      "estimatedCaloriesBurn": estimated calories as integer,
      "equipment": ["equipment1", "equipment2"],
      "exercises": [
        {
          "name": "Exercise name",
          "description": "Clear instructions on how to perform",
          "targetArea": "Primary body area targeted",
          "sets": number of sets as integer,
          "reps": number of reps as integer,
          "durationSeconds": null or duration for timed exercises,
          "restBetweenSeconds": rest time in seconds as integer
        }
      ]
    }
    
    IMPORTANT RULES:
    1. Only include exercises appropriate for the user's fitness level
    2. Respect any health conditions mentioned
    3. If no equipment is available, only include bodyweight exercises
    4. Follow proper exercise progression
    5. Include appropriate warm-up and cool-down
    6. Ensure proper rest periods between exercises
    7. Total workout time must not exceed ${maxMinutes ?? profileData['workoutDurationMinutes'] ?? 30} minutes
    8. Respond ONLY with valid JSON
    ''';

    // User request with specific customization
    final userMessage =
        specificRequest ?? 'Create a workout plan for me based on my profile.';

    return [
      {'role': 'system', 'content': systemMessage},
      {'role': 'user', 'content': userMessage},
    ];
  }

  Map<String, dynamic> _parseWorkoutResponse(String response) {
    try {
      // Extract JSON from the response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      final jsonStr = response.substring(jsonStart, jsonEnd);

      final Map<String, dynamic> workoutData = jsonDecode(jsonStr);

      // Add additional metadata
      workoutData['id'] = const Uuid().v4();
      workoutData['isAiGenerated'] = true;
      workoutData['createdAt'] = DateTime.now().toIso8601String();
      workoutData['createdBy'] = 'ai';

      return workoutData;
    } catch (e) {
      debugPrint('Error parsing workout response: $e');
      throw Exception('Failed to parse AI response into workout format');
    }
  }

  Future<String> chat({
    required String userId,
    required String message,
    List<Map<String, String>>? previousMessages,
  }) async {
    try {
      // Fetch fitness profile data from Firestore
      final profileData = await _fitnessProfileService.getFitnessProfileForAI(
        userId,
      );

      // Build conversation history
      final messages = _buildChatPrompt(
        profileData: profileData,
        userMessage: message,
        previousMessages: previousMessages,
      );

      // Make API request
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
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _analytics.logEvent(
          name: 'ai_chat_message',
          parameters: {
            'user_id': userId,
            'message_length': message.length.toString(),
            'token_count':
                data['usage']['total_tokens']?.toString() ?? 'unknown',
          },
        );
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to chat with AI: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error chatting with AI: $e');
      rethrow;
    }
  }

  List<Map<String, String>> _buildChatPrompt({
    required Map<String, dynamic> profileData,
    required String userMessage,
    List<Map<String, String>>? previousMessages,
  }) {
    // System message with constraints and persona
    final systemMessage = '''
    You are a friendly, supportive fitness coach specializing in helping women achieve their fitness goals through tailored workout plans and nutrition advice.
    
    USER PROFILE:
    - Fitness level: ${profileData['fitnessLevel']}
    - Goals: ${(profileData['goals'] as List<dynamic>?)?.join(', ') ?? 'General fitness'}
    - Focus areas: ${(profileData['bodyFocusAreas'] as List<dynamic>?)?.isEmpty == true ? 'Full body' : (profileData['bodyFocusAreas'] as List<dynamic>?)?.join(', ')}
    
    Your responses should be encouraging, informative, and tailored to the user's specific profile. Keep your tone conversational, friendly, and supportive. Avoid generic advice and personalize your responses.
    
    You can help with:
    - Workout advice and modifications
    - Nutrition guidance tailored to their goals
    - Motivation and encouragement
    - Fitness education and explanations
    
    IMPORTANT:
    - Keep responses concise and easy to understand
    - Use encouraging, positive language
    - Reference their specific goals and focus areas
    - When giving advice, explain the benefits or reasoning
    - Never refer to the user's personal information (name, age, etc.)
    ''';

    List<Map<String, String>> messages = [
      {'role': 'system', 'content': systemMessage},
    ];

    // Add previous conversation history if available
    if (previousMessages != null && previousMessages.isNotEmpty) {
      messages.addAll(previousMessages);
    }

    // Add current user message
    messages.add({'role': 'user', 'content': userMessage});

    return messages;
  }
}
