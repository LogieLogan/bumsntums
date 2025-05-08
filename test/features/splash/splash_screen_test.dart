// test/features/splash/splash_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bums_n_tums/features/splash/screens/splash_screen.dart';
import 'package:bums_n_tums/features/auth/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([User])
void main() {
  testWidgets('SplashScreen shows app logo and name', (WidgetTester tester) async {
    // Override the auth provider to prevent auto-navigation
    final container = ProviderContainer(
      overrides: [
        // Override the auth state provider to return null (unauthenticated)
        authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
      ],
    );

    // Build the splash screen with the overridden providers
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SplashScreen(
            testMode: true, // Add this parameter to your SplashScreen
          ),
        ),
      ),
    );

    // Verify UI elements without waiting for navigation
    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    expect(find.text('Bums \'n\' Tums'), findsOneWidget);
    expect(find.text('Your fitness journey starts here'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Clean up
    container.dispose();
  });
}