// lib/features/ai/providers/openai_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/openai_service.dart';
import '../../../shared/providers/environment_provider.dart';

final openAIServiceProvider = Provider<OpenAIService>((ref) {
  final environmentServiceAsync = ref.watch(environmentServiceInitProvider);
  
  return environmentServiceAsync.when(
    data: (environmentService) {
      final apiKey = environmentService.openAIApiKey;
      return OpenAIService(apiKey: apiKey);
    },
    loading: () => OpenAIService(apiKey: 'placeholder'),
    error: (error, stackTrace) => OpenAIService(apiKey: 'error_key'),
  );
});