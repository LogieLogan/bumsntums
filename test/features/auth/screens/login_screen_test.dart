// test/features/auth/screens/login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bums_n_tums/features/auth/screens/login_screen.dart';
import 'package:bums_n_tums/features/auth/providers/auth_provider.dart';
import 'package:bums_n_tums/features/auth/services/firebase_auth_service.dart';
import 'package:bums_n_tums/shared/analytics/firebase_analytics_service.dart';
import 'package:go_router/go_router.dart';

// Generate mocks for the services
@GenerateMocks([
  FirebaseAuthService, 
  AnalyticsService,
])
import 'login_screen_test.mocks.dart';

// Create a manual mock for AuthStateNotifier
class MockAuthStateNotifier extends StateNotifier<AuthState> with Mock implements AuthStateNotifier {
  MockAuthStateNotifier() : super(AuthState.initial);
  
  @override
  Future<void> signInWithEmailAndPassword({required String email, required String password}) async {
    return super.noSuchMethod(
      Invocation.method(#signInWithEmailAndPassword, [], {
        #email: email,
        #password: password,
      }),
      returnValue: Future<void>.value(),
      returnValueForMissingStub: Future<void>.value(),
    );
  }
}

// Setup MockGoRouter with correct override
class MockGoRouter extends Mock implements GoRouter {
  @override
  void go(String location, {Object? extra}) {}
}

void main() {
  late MockFirebaseAuthService mockAuthService;
  late MockAnalyticsService mockAnalyticsService;
  late MockAuthStateNotifier mockAuthNotifier;

  setUp(() {
    mockAuthService = MockFirebaseAuthService();
    mockAnalyticsService = MockAnalyticsService();
    mockAuthNotifier = MockAuthStateNotifier();
  });

  // Helper function to build the login screen with mocks
  Widget buildLoginScreen() {
    return ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
        authStateNotifierProvider.overrideWithProvider(
          StateNotifierProvider<AuthStateNotifier, AuthState>(
            (ref) => mockAuthNotifier,
          ),
        ),
      ],
      child: MaterialApp(
        home: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen UI', () {
    testWidgets('should render all UI elements correctly', (WidgetTester tester) async {
      // Build the login screen
      await tester.pumpWidget(buildLoginScreen());
      
      // Verify app logo is shown
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      
      // Verify app name is shown
      expect(find.text('Bums \'n\' Tums'), findsOneWidget);
      
      // Verify tagline is shown
      expect(find.text('Your fitness journey starts here'), findsOneWidget);
      
      // Verify email and password fields are shown
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      
      // Verify buttons are shown
      expect(find.widgetWithText(ElevatedButton, 'LOGIN'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'SIGN UP'), findsOneWidget);
      
      // Verify forgot password link is shown
      expect(find.text('Forgot Password?'), findsOneWidget);
      
      // Verify social login options are shown
      expect(find.text('OR'), findsOneWidget);
    });

    // Other test cases remain the same...
  });
}