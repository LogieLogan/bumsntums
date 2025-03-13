// lib/shared/providers/firebase_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});