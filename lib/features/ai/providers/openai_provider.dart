// lib/features/ai/providers/openai_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/openai_service.dart';
import '../../../shared/providers/environment_provider.dart';
import '../../../features/auth/providers/fitness_profile_provider.dart';

final openAIServiceProvider = Provider<OpenAIService>((ref) {
  final environmentServiceAsync = ref.watch(environmentServiceInitProvider);
  final fitnessProfileService = ref.watch(fitnessProfileServiceProvider);
  
  return environmentServiceAsync.when(
    data: (environmentService) {
      final apiKey = environmentService.openAIApiKey;
      return OpenAIService(
        apiKey: apiKey,
        fitnessProfileService: fitnessProfileService,
      );
    },
    loading: () => OpenAIService.placeholder(fitnessProfileService),
    error: (error, stackTrace) => OpenAIService.error(error, fitnessProfileService),
  );
});