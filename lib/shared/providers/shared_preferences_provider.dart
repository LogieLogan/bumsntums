// lib/shared/providers/shared_preferences_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  // This will throw if SharedPreferences.getInstance() hasn't completed
  // when the provider is first read. Usually okay if read within async contexts
  // or after main() has ensured it's initialized.
  // For more robust handling, consider a FutureProvider that resolves to SharedPreferences.
  throw UnimplementedError(
      'SharedPreferences instance should be provided via an override in main.dart'
      ' after SharedPreferences.getInstance() has completed.');
});

// It's often better to initialize SharedPreferences in main and override:
// In main.dart:
//   final prefs = await SharedPreferences.getInstance();
//   runApp(ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)], child: App()));