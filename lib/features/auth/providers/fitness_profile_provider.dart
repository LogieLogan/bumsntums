// lib/features/auth/providers/fitness_profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/fitness_profile_service.dart';

final fitnessProfileServiceProvider = Provider<FitnessProfileService>((ref) {
  return FitnessProfileService();
});

final fitnessProfileForAIProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final fitnessProfileService = ref.read(fitnessProfileServiceProvider);
  return fitnessProfileService.getFitnessProfileForAI(userId);
});