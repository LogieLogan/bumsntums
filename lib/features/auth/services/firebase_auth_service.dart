// lib/features/auth/services/firebase_auth_service.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/analytics/firebase_analytics_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'google_sign_in_service.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService();
  final GoogleSignInService _googleSignInService = GoogleSignInService();

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Sign up with email and password
  Future<AppUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw AuthException('Failed to create user');
      }

      // Create user document in Firestore
      final appUser = AppUser(
        id: user.uid,
        email: user.email!,
        emailVerified: user.emailVerified,
        createdAt: DateTime.now(),
      );

      await _createUserDocument(appUser);
      await _analytics.logSignUp(method: 'email');

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw AuthException('Failed to sign in');
      }

      // Update last login
      final appUser = await _getUserFromFirestore(user.uid);
      await _updateLastLogin(user.uid);
      await _analytics.logLogin(method: 'email');

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Sign in anonymously
  Future<AppUser> signInAnonymously() async {
    try {
      final userCredential = await _firebaseAuth.signInAnonymously();
      final user = userCredential.user;

      if (user == null) {
        throw AuthException('Failed to sign in anonymously');
      }

      // Create anonymous user document
      final appUser = AppUser(
        id: user.uid,
        email: 'anonymous@user.com',
        createdAt: DateTime.now(),
      );

      await _createUserDocument(appUser);
      await _analytics.logLogin(method: 'anonymous');

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(AppUser user) async {
    // Personal info collection - for PII data
    await _firestore.collection('users_personal_info').doc(user.id).set({
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoUrl,
      'emailVerified': user.emailVerified,
      'createdAt': Timestamp.fromDate(user.createdAt),
      'lastLoginAt':
          user.lastLoginAt != null
              ? Timestamp.fromDate(user.lastLoginAt!)
              : null,
    });

    // Fitness profile - for non-PII fitness data
    await _firestore.collection('fitness_profiles').doc(user.id).set({
      'userId': user.id,
      'createdAt': Timestamp.fromDate(user.createdAt),
      'goals': [],
      'completed_workouts': 0,
    });
  }

  // Get user from Firestore
  Future<AppUser> _getUserFromFirestore(String userId) async {
    final docSnapshot =
        await _firestore.collection('users_personal_info').doc(userId).get();

    if (!docSnapshot.exists) {
      throw AuthException('User not found');
    }

    final data = docSnapshot.data()!;
    return AppUser.fromMap({'id': userId, ...data});
  }

  // Update last login timestamp
  Future<void> _updateLastLogin(String userId) async {
    await _firestore.collection('users_personal_info').doc(userId).update({
      'lastLoginAt': Timestamp.now(),
    });
  }

  // Update the _handleFirebaseAuthException method in firebase_auth_service.dart
  Exception _handleFirebaseAuthException(FirebaseAuthException e) {
    print("Firebase Auth Exception: ${e.code} - ${e.message}");

    switch (e.code) {
      case 'user-not-found':
        return AuthException('No user found with this email.');
      case 'wrong-password':
        return AuthException('Wrong password.');
      case 'email-already-in-use':
        return AuthException('The email address is already in use.');
      case 'invalid-email':
        return AuthException('The email address is invalid.');
      case 'weak-password':
        return AuthException('The password is too weak.');
      case 'operation-not-allowed':
        return AuthException('This operation is not allowed.');
      case 'network-request-failed':
        return AuthException(
          'Network error. Please check your internet connection.',
        );
      case 'app-not-authorized':
        return AuthException(
          'App not authorized. Please check app permissions.',
        );
      default:
        return AuthException('Authentication error: ${e.message}');
    }
  }

  Future<AppUser> signInWithGoogle() async {
    try {
      print("Starting Google Sign-In process...");

      // Use our new service
      final userCredential = await _googleSignInService.signIn();
      final user = userCredential.user;

      if (user == null) {
        throw AuthException(
          'Failed to sign in with Google: Firebase user is null',
        );
      }

      // Check if user exists in Firestore
      final docRef = _firestore.collection('users_personal_info').doc(user.uid);
      final docSnapshot = await docRef.get();

      // Create or update user document
      if (!docSnapshot.exists) {
        final appUser = AppUser(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoUrl: user.photoURL,
          emailVerified: user.emailVerified,
          createdAt: DateTime.now(),
        );

        await _createUserDocument(appUser);
      } else {
        await _updateLastLogin(user.uid);
      }

      await _analytics.logLogin(method: 'google');

      // Return the app user
      return await _getUserFromFirestore(user.uid);
    } on FirebaseAuthException catch (e) {
      print(
        "FirebaseAuthException in signInWithGoogle: ${e.code} - ${e.message}",
      );
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      print("FATAL ERROR in Google Sign-In: $e");
      throw AuthException('Failed to sign in with Google: ${e.toString()}');
    }
  }

  // Generate a random nonce for Apple Sign-In
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  // Generate a SHA256 hash of the input
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<AppUser> signInWithApple() async {
    try {
      print("Starting alternative Apple Sign-In process...");

      // Generate a nonce
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request Apple credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Get identity token
      if (appleCredential.identityToken == null) {
        throw AuthException('No identity token received from Apple');
      }

      // Create AuthCredential
      final credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken!,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      // Sign in to Firebase with credential
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user == null) {
        throw AuthException('Failed to sign in with Apple');
      }

      // Check if user exists in Firestore
      print("Checking if user exists in Firestore...");
      final docRef = _firestore.collection('users_personal_info').doc(user.uid);
      final docSnapshot = await docRef.get();

      // Create user document if it doesn't exist
      if (!docSnapshot.exists) {
        print("Creating new user document in Firestore");
        // Apple may not provide name on subsequent logins
        String? displayName;
        if (appleCredential.givenName != null &&
            appleCredential.familyName != null) {
          displayName =
              '${appleCredential.givenName} ${appleCredential.familyName}';
        }

        final appUser = AppUser(
          id: user.uid,
          email: user.email ?? appleCredential.email ?? '',
          displayName: user.displayName ?? displayName,
          photoUrl: user.photoURL,
          emailVerified: user.emailVerified,
          createdAt: DateTime.now(),
        );

        await _createUserDocument(appUser);
      } else {
        print("User already exists, updating last login");
        // Update last login
        await _updateLastLogin(user.uid);
      }

      await _analytics.logLogin(method: 'apple');

      // Return the app user
      print("Apple Sign-In completed successfully");
      return await _getUserFromFirestore(user.uid);
    } on SignInWithAppleException catch (e) {
      print("SignInWithAppleException: $e");
      throw AuthException('Apple sign-in failed: ${e.toString()}');
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException in Apple Sign-In: ${e.code} - ${e.message}");
      throw _handleFirebaseAuthException(e);
    } on AuthException catch (e) {
      print("AuthException in Apple Sign-In: ${e.message}");
      rethrow;
    } catch (e) {
      print("Unexpected error in Apple Sign-In: $e");
      throw AuthException('Failed to sign in with Apple: ${e.toString()}');
    }
  }
}
