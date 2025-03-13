// test/features/splash/splash_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bums_n_tums/features/splash/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen shows app logo and name', (WidgetTester tester) async {
    // Build the splash screen
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    // Verify that the splash screen shows the app logo
    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    
    // Verify that the splash screen shows the app name
    expect(find.text('Bums \'n\' Tums'), findsOneWidget);
    
    // Verify that the splash screen shows the tagline
    expect(find.text('Your fitness journey starts here'), findsOneWidget);
    
    // Verify that the splash screen shows the loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}