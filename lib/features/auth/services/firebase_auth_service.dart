// lib/features/auth/services/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/analytics/firebase_analytics_service.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService();

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
      'lastLoginAt': user.lastLoginAt != null 
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
    final docSnapshot = await _firestore
        .collection('users_personal_info')
        .doc(userId)
        .get();
    
    if (!docSnapshot.exists) {
      throw AuthException('User not found');
    }
    
    final data = docSnapshot.data()!;
    return AppUser.fromMap({
      'id': userId,
      ...data,
    });
  }

  // Update last login timestamp
  Future<void> _updateLastLogin(String userId) async {
    await _firestore.collection('users_personal_info').doc(userId).update({
      'lastLoginAt': Timestamp.now(),
    });
  }

  // Handle Firebase auth exceptions
  Exception _handleFirebaseAuthException(FirebaseAuthException e) {
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
      default:
        return AuthException('Authentication error: ${e.message}');
    }
  }
}