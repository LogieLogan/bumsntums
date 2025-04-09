// lib/features/auth/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';
import '../../../shared/models/app_user.dart';

// Auth service provider
final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

// Auth state stream provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Current app user provider
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) return null;

  final userId = authState.uid;
  // Implement a method to fetch user data from Firestore
  // This is just a placeholder for now
  return AppUser(
    id: userId,
    email: authState.email ?? '',
    emailVerified: authState.emailVerified,
    createdAt: DateTime.now(),
  );
});

// Auth state notifier
enum AuthState { initial, authenticated, unauthenticated, loading, error }

class AuthStateNotifier extends StateNotifier<AuthState> {
  final FirebaseAuthService _authService;

  AuthStateNotifier(this._authService, StateNotifierProviderRef<AuthStateNotifier, AuthState> ref) : super(AuthState.initial) {
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        state = AuthState.authenticated;
      } else {
        state = AuthState.unauthenticated;
      }
    });
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      state = AuthState.loading;
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AuthState.authenticated;
    } catch (e) {
      state = AuthState.error;
      rethrow;
    }
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      state = AuthState.loading;
      await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AuthState.authenticated;
    } catch (e) {
      state = AuthState.error;
      rethrow;
    }
  }

  Future<void> signInAnonymously() async {
    try {
      state = AuthState.loading;
      await _authService.signInAnonymously();
      state = AuthState.authenticated;
    } catch (e) {
      state = AuthState.error;
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      state = AuthState.loading;
      await _authService.signOut();
      state = AuthState.unauthenticated;
    } catch (e) {
      state = AuthState.error;
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      state = AuthState.loading;
      await _authService.signInWithGoogle();
      state = AuthState.authenticated;
    } catch (e) {
      state = AuthState.error;
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    try {
      state = AuthState.loading;
      await _authService.signInWithApple();
      state = AuthState.authenticated;
    } catch (e) {
      state = AuthState.error;
      rethrow;
    }
  }
}

final authStateNotifierProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
      final authService = ref.watch(authServiceProvider);
      return AuthStateNotifier(authService, ref);
    });
