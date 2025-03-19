// lib/shared/providers/environment_provider.dart - UPDATED
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/environment_service.dart';

final environmentServiceInitProvider = FutureProvider<EnvironmentService>((ref) async {
  final service = EnvironmentService();
  await service.initialize();
  return service;
});

final environmentServiceProvider = Provider<EnvironmentService>((ref) {
  final asyncValue = ref.watch(environmentServiceInitProvider);
  
  return asyncValue.maybeWhen(
    data: (service) => service,
    orElse: () {
      final tempService = EnvironmentService();
      return tempService;
    },
  );
});