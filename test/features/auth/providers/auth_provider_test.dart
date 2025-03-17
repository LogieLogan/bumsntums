// test/features/auth/providers/auth_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bums_n_tums/features/auth/providers/auth_provider.dart';
import 'package:bums_n_tums/features/auth/services/firebase_auth_service.dart';
import 'package:bums_n_tums/shared/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'auth_provider_test.mocks.dart';

class MockRef extends Mock implements Ref {}

@GenerateMocks([FirebaseAuthService, User])
void main() {
  late MockFirebaseAuthService mockAuthService;
  late MockRef mockRef;

  setUp(() {
    mockAuthService = MockFirebaseAuthService();
    mockRef = MockRef();
  });

  group('AuthStateNotifier', () {
    test('initial state should be AuthState.initial', () {
      // Create a new stream controller for each test
      final authStateController = StreamController<User?>();
      when(mockAuthService.authStateChanges).thenAnswer(
        (_) => authStateController.stream
      );
      
      final authNotifier = AuthStateNotifier(mockAuthService, mockRef);
      expect(authNotifier.state, equals(AuthState.initial));
      
      // Clean up
      authStateController.close();
    });

    test('should update state when auth state changes to authenticated', () async {
      // Create a new stream controller for this test
      final authStateController = StreamController<User?>();
      when(mockAuthService.authStateChanges).thenAnswer(
        (_) => authStateController.stream
      );
      
      final authNotifier = AuthStateNotifier(mockAuthService, mockRef);
      final mockUser = MockUser();
      
      // Act
      authStateController.add(mockUser);
      
      // Wait for stream to be processed
      await Future.delayed(Duration.zero);
      
      // Assert
      expect(authNotifier.state, equals(AuthState.authenticated));
      
      // Clean up
      authStateController.close();
    });

    test('should update state when auth state changes to unauthenticated', () async {
      // Create a new stream controller for this test
      final authStateController = StreamController<User?>();
      when(mockAuthService.authStateChanges).thenAnswer(
        (_) => authStateController.stream
      );
      
      final authNotifier = AuthStateNotifier(mockAuthService, mockRef);
      
      // Manually set initial state
      authNotifier.state = AuthState.authenticated;
      
      // Act
      authStateController.add(null);
      
      // Wait for stream to be processed
      await Future.delayed(Duration.zero);
      
      // Assert
      expect(authNotifier.state, equals(AuthState.unauthenticated));
      
      // Clean up
      authStateController.close();
    });

    test('signInWithEmailAndPassword should update state correctly on success', () async {
      // Create a new stream controller for this test
      final authStateController = StreamController<User?>();
      when(mockAuthService.authStateChanges).thenAnswer(
        (_) => authStateController.stream
      );
      
      final authNotifier = AuthStateNotifier(mockAuthService, mockRef);
      
      // Arrange
      when(mockAuthService.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123'
      )).thenAnswer((_) async => 
        AppUser(
          id: 'user-id',
          email: 'test@example.com',
          createdAt: DateTime.now(),
        )
      );
      
      // Act
      await authNotifier.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123'
      );
      
      // Assert
      expect(authNotifier.state, equals(AuthState.authenticated));
      verify(mockAuthService.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123'
      )).called(1);
      
      // Clean up
      authStateController.close();
    });

    test('signInWithEmailAndPassword should update state correctly on failure', () async {
      // Create a new stream controller for this test
      final authStateController = StreamController<User?>();
      when(mockAuthService.authStateChanges).thenAnswer(
        (_) => authStateController.stream
      );
      
      final authNotifier = AuthStateNotifier(mockAuthService, mockRef);
      
      // Arrange
      when(mockAuthService.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'wrong-password'
      )).thenThrow(AuthException('Wrong password'));
      
      // Act & Assert
      expect(() async => await authNotifier.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'wrong-password'
      ), throwsA(isA<AuthException>()));
      
      // Wait for async operations
      await Future.delayed(Duration.zero);
      
      // Assert final state
      expect(authNotifier.state, equals(AuthState.error));
      
      // Clean up
      authStateController.close();
    });

    test('signOut should update state correctly on success', () async {
      // Create a new stream controller for this test
      final authStateController = StreamController<User?>();
      when(mockAuthService.authStateChanges).thenAnswer(
        (_) => authStateController.stream
      );
      
      final authNotifier = AuthStateNotifier(mockAuthService, mockRef);
      
      // Arrange
      when(mockAuthService.signOut()).thenAnswer((_) async {});
      
      // Set initial state
      authNotifier.state = AuthState.authenticated;
      
      // Act
      await authNotifier.signOut();
      
      // Assert
      expect(authNotifier.state, equals(AuthState.unauthenticated));
      verify(mockAuthService.signOut()).called(1);
      
      // Clean up
      authStateController.close();
    });
  });
}