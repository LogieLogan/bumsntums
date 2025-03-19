// lib/features/ai/services/openai_service.dart
// Update with token optimization, rate limiting, and error handling

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../features/workouts/models/workout.dart';
import 'package:uuid/uuid.dart';
import '../../../features/auth/services/fitness_profile_service.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

class OpenAIService {
  final String _apiKey;
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  final String _model =
      'gpt-3.5-turbo'; // Using smaller model for cost efficiency
  final FitnessProfileService _fitnessProfileService;
  final AnalyticsService _analytics = AnalyticsService();

  // Rate limiting parameters
  static const int _maxRequestsPerMinute = 10;
  static const Duration _cooldownPeriod = Duration(minutes: 5);
  final Map<String, _RateLimitInfo> _userRateLimits = {};

  // Response token limits for different features
  static const int _workoutResponseMaxTokens = 1000;
  static const int _chatResponseMaxTokens = 500;

  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(seconds: 1);

  OpenAIService({
    required String apiKey,
    required FitnessProfileService fitnessProfileService,
  }) : _apiKey = apiKey,
       _fitnessProfileService = fitnessProfileService;

  // Check if user has exceeded rate limits
  bool _isRateLimited(String userId) {
    final now = DateTime.now();

    // If no rate limit info exists for this user, create it
    if (!_userRateLimits.containsKey(userId)) {
      _userRateLimits[userId] = _RateLimitInfo(
        requestCount: 0,
        windowStart: now,
        cooldownUntil: null,
      );
      return false;
    }

    final limitInfo = _userRateLimits[userId]!;

    // Check if user is in cooldown period
    if (limitInfo.cooldownUntil != null &&
        now.isBefore(limitInfo.cooldownUntil!)) {
      return true;
    }

    // Reset counter if window has elapsed
    if (now.difference(limitInfo.windowStart).inMinutes >= 1) {
      limitInfo.requestCount = 0;
      limitInfo.windowStart = now;
      limitInfo.cooldownUntil = null;
    }

    // Check if user has exceeded request limit
    if (limitInfo.requestCount >= _maxRequestsPerMinute) {
      limitInfo.cooldownUntil = now.add(_cooldownPeriod);
      return true;
    }

    // Increment request counter
    limitInfo.requestCount++;
    return false;
  }

  // Generate workout with retry logic and rate limiting
  Future<Map<String, dynamic>> generateWorkoutRecommendation({
    required String userId,
    String? specificRequest,
    WorkoutCategory? category,
    int? maxMinutes,
  }) async {
    // Check rate limiting
    if (_isRateLimited(userId)) {
      final cooldownMinutes =
          (_userRateLimits[userId]?.cooldownUntil
                  ?.difference(DateTime.now())
                  .inMinutes ??
              0) +
          1;
      throw RateLimitException(
        'Rate limit exceeded. Please try again in $cooldownMinutes minutes.',
      );
    }

    try {
      // Fetch fitness profile data from Firestore
      final profileData = await _fitnessProfileService.getFitnessProfileForAI(
        userId,
      );

      // Log the start of a workout generation request
      _analytics.logEvent(
        name: 'ai_workout_generation_started',
        parameters: {
          'user_id': userId,
          'category': category?.name ?? 'fullBody',
        },
      );

      // Construct the workout generation prompt
      final messages = _buildWorkoutPrompt(
        profileData: profileData,
        specificRequest: specificRequest,
        category: category,
        maxMinutes: maxMinutes,
      );

      // Make API request with retry logic
      final response = await _makeRequestWithRetry(
        messages: messages,
        maxTokens: _workoutResponseMaxTokens,
        temperature: 0.7,
      );

      final data = jsonDecode(response.body);

      // Track token usage
      _trackTokenUsage(
        userId: userId,
        feature: 'workout_generation',
        data: data,
      );

      // Parse AI response into structured workout
      final result = _parseWorkoutResponse(
        data['choices'][0]['message']['content'],
      );

      return result;
    } catch (e) {
      if (e is RateLimitException) {
        rethrow;
      }
      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'generateWorkoutRecommendation',
          'userId': userId,
        },
      );
      debugPrint('Error generating workout: $e');
      throw WorkoutGenerationException(
        'Failed to generate workout: ${e.toString()}',
      );
    }
  }

  // Chat feature with retry logic and rate limiting
  Future<String> chat({
    required String userId,
    required String message,
    List<Map<String, String>>? previousMessages,
  }) async {
    // Check rate limiting
    if (_isRateLimited(userId)) {
      final cooldownMinutes =
          (_userRateLimits[userId]?.cooldownUntil
                  ?.difference(DateTime.now())
                  .inMinutes ??
              0) +
          1;
      throw RateLimitException(
        'Rate limit exceeded. Please try again in $cooldownMinutes minutes.',
      );
    }

    try {
      // Fetch fitness profile data from Firestore
      final profileData = await _fitnessProfileService.getFitnessProfileForAI(
        userId,
      );

      // Log chat message
      _analytics.logEvent(
        name: 'ai_chat_message_sent',
        parameters: {
          'user_id': userId,
          'message_length': message.length.toString(),
        },
      );

      // Build conversation history
      final messages = _buildChatPrompt(
        profileData: profileData,
        userMessage: message,
        previousMessages: previousMessages,
      );

      // Make API request with retry logic
      final response = await _makeRequestWithRetry(
        messages: messages,
        maxTokens: _chatResponseMaxTokens,
        temperature: 0.8,
      );

      final data = jsonDecode(response.body);

      // Track token usage
      _trackTokenUsage(userId: userId, feature: 'chat', data: data);

      return data['choices'][0]['message']['content'];
    } catch (e) {
      if (e is RateLimitException) {
        rethrow;
      }
      _analytics.logError(
        error: e.toString(),
        parameters: {'context': 'chat', 'userId': userId, 'message': message},
      );
      debugPrint('Error chatting with AI: $e');
      throw ChatException('Error getting response: ${e.toString()}');
    }
  }

  // Make API request with exponential backoff retry
  Future<http.Response> _makeRequestWithRetry({
    required List<Map<String, String>> messages,
    required int maxTokens,
    required double temperature,
  }) async {
    int attempts = 0;
    Duration delay = _initialRetryDelay;

    while (attempts < _maxRetries) {
      try {
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': _model,
            'messages': messages,
            'temperature': temperature,
            'max_tokens': maxTokens,
          }),
        );

        // Check for success
        if (response.statusCode == 200) {
          return response;
        }

        // Handle rate limiting from OpenAI
        if (response.statusCode == 429) {
          // Rate limit hit, wait longer before retrying
          attempts++;
          if (attempts >= _maxRetries) {
            throw Exception(
              'OpenAI rate limit exceeded after $_maxRetries attempts',
            );
          }
          await Future.delayed(delay);
          delay *= 2; // Exponential backoff
          continue;
        }

        // Other error status codes
        throw Exception(
          'API request failed with status ${response.statusCode}: ${response.body}',
        );
      } catch (e) {
        // Network or other errors
        attempts++;
        if (attempts >= _maxRetries) {
          rethrow;
        }
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }

    throw Exception('Failed after $_maxRetries attempts');
  }

  // Track token usage for cost monitoring
  void _trackTokenUsage({
    required String userId,
    required String feature,
    required Map<String, dynamic> data,
  }) {
    try {
      final usage = data['usage'];
      if (usage != null) {
        final promptTokens = usage['prompt_tokens'] ?? 0;
        final completionTokens = usage['completion_tokens'] ?? 0;
        final totalTokens = usage['total_tokens'] ?? 0;

        _analytics.logEvent(
          name: 'ai_token_usage',
          parameters: {
            'user_id': userId,
            'feature': feature,
            'prompt_tokens': promptTokens.toString(),
            'completion_tokens': completionTokens.toString(),
            'total_tokens': totalTokens.toString(),
          },
        );
      }
    } catch (e) {
      debugPrint('Error tracking token usage: $e');
      // Non-critical error, don't throw
    }
  }

  // Build optimized workout prompt - refactored for fewer tokens
  List<Map<String, String>> _buildWorkoutPrompt({
    required Map<String, dynamic> profileData,
    String? specificRequest,
    WorkoutCategory? category,
    int? maxMinutes,
  }) {
    // System message with optimized token usage
    final systemMessage = '''
You are a fitness trainer creating personalized workouts. Use this profile:
- Level: ${profileData['fitnessLevel']}
- Goals: ${(profileData['goals'] as List<dynamic>?)?.join(', ') ?? 'General fitness'}
- Focus: ${(profileData['bodyFocusAreas'] as List<dynamic>?)?.isEmpty == true ? 'Full body' : (profileData['bodyFocusAreas'] as List<dynamic>?)?.join(', ')}
- Equipment: ${(profileData['availableEquipment'] as List<dynamic>?)?.isEmpty == true ? 'None' : (profileData['availableEquipment'] as List<dynamic>?)?.join(', ')}
- Location: ${profileData['preferredLocation'] ?? 'Anywhere'}
- Duration: ${maxMinutes ?? profileData['workoutDurationMinutes'] ?? 30} minutes
- Health: ${(profileData['healthConditions'] as List<dynamic>?)?.isEmpty == true ? 'None' : (profileData['healthConditions'] as List<dynamic>?)?.join(', ')}

Create a ${category?.name ?? "full body"} workout in this JSON format:
{
  "title": "Workout title",
  "description": "Brief workout description",
  "category": "${category?.name ?? 'fullBody'}",
  "difficulty": "beginner|intermediate|advanced",
  "durationMinutes": integer,
  "estimatedCaloriesBurn": integer,
  "equipment": ["item1", "item2"],
  "exercises": [
    {
      "name": "Name",
      "description": "Instructions",
      "targetArea": "Area",
      "sets": integer,
      "reps": integer,
      "durationSeconds": integer or null,
      "restBetweenSeconds": integer
    }
  ]
}

RULES: Match fitness level, respect health conditions, use available equipment, include warm-up/cool-down, respect time limit, respond ONLY with valid JSON.
''';

    // User request with specific customization
    final userMessage =
        specificRequest ?? 'Create a workout plan for me based on my profile.';

    return [
      {'role': 'system', 'content': systemMessage},
      {'role': 'user', 'content': userMessage},
    ];
  }

  // Build optimized chat prompt - refactored for fewer tokens
  List<Map<String, String>> _buildChatPrompt({
    required Map<String, dynamic> profileData,
    required String userMessage,
    List<Map<String, String>>? previousMessages,
  }) {
    // System message with optimized token usage
    final systemMessage = '''
You are a supportive fitness coach for women. User profile:
- Level: ${profileData['fitnessLevel']}
- Goals: ${(profileData['goals'] as List<dynamic>?)?.join(', ') ?? 'General fitness'}
- Focus: ${(profileData['bodyFocusAreas'] as List<dynamic>?)?.isEmpty == true ? 'Full body' : (profileData['bodyFocusAreas'] as List<dynamic>?)?.join(', ')}

Be encouraging, helpful, and personalized. You can advise on workouts, nutrition, motivation, and fitness education.

When users ask for complete workout plans or routines, suggest they use the app's AI Workout Generator feature instead of creating a full plan in chat.
Use this format: "[Use AI Workout Generator](workout_generator)" when suggesting they use this feature.

Keep responses concise, positive, and reference their goals when relevant. Never refer to personal information like name or age.
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

  // Utility methods (keeping them the same)
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

  List<Map<String, String>> _buildCategorySpecificPrompt({
    required String category,
    required Map<String, dynamic> profileData,
    required String userMessage,
  }) {
    String systemPrompt;

    switch (category) {
      case 'workout_advice':
        systemPrompt = '''
You are a personal trainer specializing in exercise form and workout optimization.

USER PROFILE:
- Fitness level: ${profileData['fitnessLevel']}
- Goals: ${(profileData['goals'] as List<dynamic>?)?.join(', ') ?? 'General fitness'}
- Equipment: ${(profileData['availableEquipment'] as List<dynamic>?)?.isEmpty == true ? 'None' : (profileData['availableEquipment'] as List<dynamic>?)?.join(', ')}
- Health concerns: ${(profileData['healthConditions'] as List<dynamic>?)?.isEmpty == true ? 'None' : (profileData['healthConditions'] as List<dynamic>?)?.join(', ')}

Provide detailed, technique-focused exercise guidance. Include form cues, common mistakes to avoid, and modifications based on their fitness level. Reference specific muscles worked and proper breathing patterns when relevant.

Keep responses practical and actionable. Use clear, step-by-step instructions. Prioritize safety and proper form.
''';
        break;

      case 'nutrition_advice':
        systemPrompt = '''
You are a nutrition coach specializing in fitness-oriented meal planning.

USER PROFILE:
- Goals: ${(profileData['goals'] as List<dynamic>?)?.join(', ') ?? 'General fitness'}
- Dietary preferences: ${(profileData['dietaryPreferences'] as List<dynamic>?)?.isEmpty == true ? 'None specified' : (profileData['dietaryPreferences'] as List<dynamic>?)?.join(', ')}
- Allergies: ${(profileData['allergies'] as List<dynamic>?)?.isEmpty == true ? 'None' : (profileData['allergies'] as List<dynamic>?)?.join(', ')}

Provide nutrition advice tailored to their fitness goals. Suggest practical meal ideas, portion guidance, and nutrient timing strategies. Respect their dietary preferences and allergies.

Focus on sustainable eating habits rather than restrictive diets. Include the rationale behind recommendations to help build nutrition knowledge.
''';
        break;

      case 'motivation':
        systemPrompt = '''
You are a motivational fitness coach specialized in building fitness consistency.

USER PROFILE:
- Goals: ${(profileData['goals'] as List<dynamic>?)?.join(', ') ?? 'General fitness'}
- Focus areas: ${(profileData['bodyFocusAreas'] as List<dynamic>?)?.isEmpty == true ? 'Full body' : (profileData['bodyFocusAreas'] as List<dynamic>?)?.join(', ')}

Provide encouraging, empathetic motivation tailored to their specific goals. Offer practical strategies to overcome common obstacles, build consistency, and stay motivated through challenges.

Use positive, empowering language. Share relatable examples and specific action steps they can implement immediately.
''';
        break;

      default: // General fitness advice
        systemPrompt = '''
You are a supportive fitness coach for women. User profile:
- Level: ${profileData['fitnessLevel']}
- Goals: ${(profileData['goals'] as List<dynamic>?)?.join(', ') ?? 'General fitness'}
- Focus: ${(profileData['bodyFocusAreas'] as List<dynamic>?)?.isEmpty == true ? 'Full body' : (profileData['bodyFocusAreas'] as List<dynamic>?)?.join(', ')}

Be encouraging, helpful, and personalized. You can advise on workouts, nutrition, motivation, and fitness education.

Keep responses concise, positive, and reference their goals when relevant. Never refer to personal information like name or age.
''';
    }

    return [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userMessage},
    ];
  }

  // Method to detect intent and use appropriate prompt template
  Future<String> enhancedChat({
    required String userId,
    required String message,
    List<Map<String, String>>? previousMessages,
  }) async {
    try {
      // Fetch fitness profile data
      final profileData = await _fitnessProfileService.getFitnessProfileForAI(
        userId,
      );

      // Detect message intent/category
      final category = detectMessageCategory(message);

      // Build appropriate prompt
      final messages = _buildCategorySpecificPrompt(
        category: category,
        profileData: profileData,
        userMessage: message,
      );

      // Add previous messages if available
      if (previousMessages != null && previousMessages.isNotEmpty) {
        // Insert previous messages between system and user message
        messages.insertAll(1, previousMessages);
      }

      // Make API request with retry logic
      final response = await _makeRequestWithRetry(
        messages: messages,
        maxTokens: _chatResponseMaxTokens,
        temperature: 0.8,
      );

      final data = jsonDecode(response.body);

      // Track token usage with category
      _trackTokenUsage(userId: userId, feature: 'chat_$category', data: data);

      return data['choices'][0]['message']['content'];
    } catch (e) {
      rethrow;
    }
  }

  // Simple intent detection for messages
  String detectMessageCategory(String message) {
    message = message.toLowerCase();

    // Workout-related keywords
    if (message.contains('exercise') ||
        message.contains('workout') ||
        message.contains('form') ||
        message.contains('technique') ||
        message.contains('sets') ||
        message.contains('reps')) {
      return 'workout_advice';
    }

    // Nutrition-related keywords
    if (message.contains('eat') ||
        message.contains('food') ||
        message.contains('diet') ||
        message.contains('nutrition') ||
        message.contains('meal') ||
        message.contains('protein') ||
        message.contains('carbs') ||
        message.contains('calories')) {
      return 'nutrition_advice';
    }

    // Motivation-related keywords
    if (message.contains('motivat') ||
        message.contains('struggle') ||
        message.contains('habit') ||
        message.contains('consistent') ||
        message.contains('stick') ||
        message.contains('routine') ||
        message.contains('discouraged')) {
      return 'motivation';
    }

    // Default to general advice
    return 'general';
  }
}

// Rate limit information class
class _RateLimitInfo {
  int requestCount;
  DateTime windowStart;
  DateTime? cooldownUntil;

  _RateLimitInfo({
    required this.requestCount,
    required this.windowStart,
    this.cooldownUntil,
  });
}

// Custom exceptions for better error handling
class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);

  @override
  String toString() => message;
}

class WorkoutGenerationException implements Exception {
  final String message;
  WorkoutGenerationException(this.message);

  @override
  String toString() => message;
}

class ChatException implements Exception {
  final String message;
  ChatException(this.message);

  @override
  String toString() => message;
}
