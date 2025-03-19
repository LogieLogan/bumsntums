// lib/shared/providers/environment_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/environment_service.dart';

final environmentServiceInitProvider = FutureProvider<EnvironmentService>((ref) async {
  final service = EnvironmentService();
  await service.initialize();
  return service;
});

final environmentServiceProvider = Provider<EnvironmentService>((ref) {
  final initState = ref.watch(environmentServiceInitProvider);
  return initState.when(
    data: (service) => service,
    loading: () => throw NotInitializedError('Environment service is still initializing'),
    error: (error, _) => throw error,
  );
});