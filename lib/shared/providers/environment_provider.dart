// lib/shared/providers/environment_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/environment_service.dart';

// This now returns a future of a pre-initialized service
final environmentServiceInitProvider = FutureProvider<EnvironmentService>((ref) async {
  print('Initializing environment service via provider...');
  final service = EnvironmentService();
  await service.initialize();
  print('Environment service initialized successfully via provider');
  return service;
});

// This now ensures we only use an initialized service
final environmentServiceProvider = Provider<EnvironmentService>((ref) {
  final asyncValue = ref.watch(environmentServiceInitProvider);
  
  return asyncValue.when(
    data: (service) {
      print('Providing initialized environment service');
      return service;
    },
    loading: () {
      print('Environment service is still loading!');
      throw Exception('Environment service is still initializing');
    },
    error: (error, stack) {
      print('Environment service initialization error: $error');
      throw Exception('Failed to initialize environment service: $error');
    },
  );
});