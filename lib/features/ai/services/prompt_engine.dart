// lib/features/ai/services/prompt_engine.dart
import 'package:flutter/foundation.dart';
import '../models/prompt_template.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

class PromptEngine {
  final Map<String, PromptTemplate> _templates = {};
  final AnalyticsService _analytics = AnalyticsService();

  PromptEngine() {
    _initializeTemplates();
  }

  void _initializeTemplates() {
    // Add default templates
    _addTemplate(
      PromptTemplate(
        id: 'general_chat',
        name: 'General Chat',
        version: '1.0.0',
        category: PromptCategory.general,
        systemPrompt: '''
You are a supportive fitness coach for women. User profile:
- Level: {fitnessLevel}
- Goals: {goals}
- Focus: {bodyFocusAreas}

{personalityModifier}

Be encouraging, helpful, and personalized. You can advise on workouts, nutrition, motivation, and fitness education.

When users ask for complete workout plans or routines, suggest they use the app's AI Workout Generator feature instead of creating a full plan in chat.
Use this format: "[Use AI Workout Generator](workout_generator)" when suggesting they use this feature.

Keep responses concise, positive, and reference their goals when relevant. Never refer to personal information like name or age.
''',
        requiredUserAttributes: ['fitnessLevel', 'goals', 'bodyFocusAreas'],
        variables: {
          'personalityModifier':
              'Use a friendly, supportive tone with occasional humor.',
        },
      ),
    );

    _addTemplate(
      PromptTemplate(
        id: 'workout_creation',
        name: 'Workout Creation',
        version: '2.2.0',
        category: PromptCategory.workoutCreation,
        systemPrompt: '''
You are a fitness trainer creating a personalized workout.

CREATE A WORKOUT WITH THESE SPECIFICATIONS:
- Category: {workoutCategory}
- Duration: {duration} minutes (must be exactly this duration)
- Equipment: {equipment}
- Fitness level: {fitnessLevel}
- Focus areas: {focusAreas}
- Special requests: {specialRequest}

IMPORTANT RULES:
1. STRICTLY maintain {duration} minutes total workout time
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
  "category": "{workoutCategory}",
  "difficulty": "{fitnessLevel}",
  "durationMinutes": {duration},
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
''',
        requiredUserAttributes: [],
        variables: {
          'workoutCategory': 'fullBody',
          'duration': '30',
          'equipment': 'bodyweight',
          'fitnessLevel': 'beginner',
          'focusAreas': 'overall fitness',
          'specialRequest': '',
        },
      ),
    );

    _addTemplate(
      PromptTemplate(
        id: 'plan_creation',
        name: 'Plan Creation',
        version: '1.0.0',
        category: PromptCategory.planCreation,
        systemPrompt: '''
You are a professional fitness coach creating a personalized workout plan. User profile:
- Level: {fitnessLevel}
- Goals: {goals}
- Focus areas: {bodyFocusAreas}
- Equipment: {availableEquipment}
- Workout days per week: {weeklyWorkoutDays}
- Workout duration: {workoutDurationMinutes} minutes
- Health concerns: {healthConditions}

{personalityModifier}

Create a balanced {duration}-day workout plan focusing on {focusAreas}.
The plan should:
- Match their fitness level
- Progress appropriately
- Include adequate rest days
- Respect any health limitations
- Utilize available equipment
- Include variety for engagement
- Work towards their stated goals

For each workout day, provide:
1. The day (e.g., "Day 1 - Monday")
2. A workout title
3. Target areas
4. Duration
5. Brief description
6. List of 4-7 exercises with sets and reps

Explain the plan structure and how it supports their goals. Offer guidance on progression and adapting the plan as needed.
''',
        requiredUserAttributes: [
          'fitnessLevel',
          'goals',
          'bodyFocusAreas',
          'availableEquipment',
          'weeklyWorkoutDays',
          'workoutDurationMinutes',
          'healthConditions',
        ],
        variables: {
          'personalityModifier':
              'Use a friendly, supportive tone with occasional humor.',
          'duration': '7',
          'focusAreas': 'overall fitness with emphasis on user\'s goals',
        },
      ),
    );

    _addTemplate(
      PromptTemplate(
        id: 'workout_refinement',
        name: 'Workout Refinement',
        version: '2.0.0',
        category: PromptCategory.workoutRefinement,
        systemPrompt: '''
WORKOUT REFINEMENT TASK

Current workout to modify:
{workoutDetails}

User wants to change: {userFeedback}

ESSENTIAL INSTRUCTIONS:
1. You MUST update the actual exercises based on the refinement request
2. Duration should be a multiple of 15 minutes (15, 30, 45, 60)
3. Use SPECIFIC exercise names (like "Squats", "Lunges", NOT "Exercise 1")
4. When adding exercises, provide full details (name, description, sets, reps, rest)
5. When modifying existing exercises, change the actual exercise data

IMPORTANT: If the refinement affects exercise selection, you MUST change the exercises array.

Respond with the complete modified workout in JSON format, plus a "changesSummary" field that explains exactly what you changed.
''',
        requiredUserAttributes: [],
        variables: {'workoutDetails': '{}', 'userFeedback': ''},
      ),
    );
  }

  void _addTemplate(PromptTemplate template) {
    _templates[template.id] = template;
  }

  PromptTemplate? getTemplate(String templateId) {
    return _templates[templateId];
  }

  List<PromptTemplate> getTemplatesByCategory(PromptCategory category) {
    return _templates.values.where((t) => t.category == category).toList();
  }

  List<PromptTemplate> getAllTemplates() {
    return _templates.values.toList();
  }

  Future<void> loadTemplatesFromFirestore() async {
    // Implement loading templates from Firestore if needed
    // This would allow updating templates without app updates
  }

  String buildPrompt({
    required String templateId,
    required Map<String, dynamic> context,
    Map<String, String>? customVars,
  }) {
    try {
      final template = getTemplate(templateId);
      if (template == null) {
        throw Exception('Template not found: $templateId');
      }

      // Add personality modifier if provided
      final allVars =
          customVars != null
              ? Map<String, String>.from(customVars)
              : <String, String>{};

      final result = template.build(context, customVars: allVars);

      // Log template usage
      _analytics.logEvent(
        name: 'ai_prompt_template_used',
        parameters: {
          'template_id': templateId,
          'template_version': template.version,
        },
      );

      return result;
    } catch (e) {
      debugPrint('Error building prompt: $e');
      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'PromptEngine.buildPrompt',
          'templateId': templateId,
        },
      );

      // Return fallback prompt
      return "You are a helpful fitness assistant. Provide a helpful response.";
    }
  }
}
