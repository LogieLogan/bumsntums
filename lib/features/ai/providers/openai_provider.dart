// lib/features/ai/providers/openai_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/openai_service.dart';
import '../../../shared/providers/environment_provider.dart';

final openAIServiceProvider = Provider<OpenAIService>((ref) {
  final environmentService = ref.watch(environmentServiceProvider);
  final apiKey = environmentService.openAIApiKey;
  return OpenAIService(apiKey: apiKey);
});