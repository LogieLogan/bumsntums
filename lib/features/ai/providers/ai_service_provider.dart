// lib/features/ai/providers/ai_service_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/openai_service.dart';
import '../services/prompt_engine.dart';
import '../services/context_service.dart';
import '../services/personality_engine.dart';
import '../services/conversation_manager.dart';
import '../../auth/services/fitness_profile_service.dart';
import '../../../shared/providers/environment_provider.dart';
import '../services/prompt_engine.dart';

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

// // Provider for ConversationManager
// final conversationManagerProvider = Provider<ConversationManager>((ref) {
//   return ConversationManager();
// });

// Provider for OpenAIService
final openAIServiceProvider = Provider<OpenAIService>((ref) {
  final environmentServiceAsync = ref.watch(environmentServiceInitProvider);
  final promptEngine = ref.watch(promptEngineProvider);
  final contextService = ref.watch(contextServiceProvider);
  final personalityEngine = ref.watch(personalityEngineProvider);

  return environmentServiceAsync.when(
    data: (environmentService) {
      final apiKey = environmentService.openAIApiKey;
      return OpenAIService(
        apiKey: apiKey,
        promptEngine: promptEngine,
        contextService: contextService,
        personalityEngine: personalityEngine,
      );
    },
    loading: () => throw Exception('Environment service is still initializing'),
    error: (error, stackTrace) => throw Exception('Failed to initialize environment service: $error'),
  );
});