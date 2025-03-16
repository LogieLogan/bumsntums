// lib/features/auth/services/google_sign_in_service.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleSignInService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Clean up any existing sessions first
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      debugPrint('Successfully signed out from Google');
    } catch (e) {
      debugPrint('Error signing out from Google: $e');
    }
  }
  
  // Main sign-in method
  Future<UserCredential> signIn() async {
    try {
      // No need to force sign out each time - this can cause the process to take longer
      // and may interrupt the user experience
      
      // Initiate sign-in process with a longer timeout
      debugPrint('Initiating Google sign-in...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn()
          .timeout(const Duration(seconds: 30), onTimeout: () {
        debugPrint('Google sign-in timed out');
        throw TimeoutException('Google sign-in process timed out. Please try again.');
      });
      
      // Handle cancellation
      if (googleUser == null) {
        debugPrint('User cancelled Google sign-in');
        throw FirebaseAuthException(
          code: 'sign-in-cancelled',
          message: 'Sign-in was cancelled',
        );
      }
      
      // Get auth tokens
      debugPrint('Getting Google authentication tokens...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create and return Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with credential
      debugPrint('Signing in to Firebase with Google credential...');
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      
      // Clean up on error
      try {
        await _googleSignIn.disconnect();
      } catch (_) {}
      
      // Rethrow as Firebase exception for consistent error handling
      if (e is FirebaseAuthException) {
        rethrow;
      } else if (e is TimeoutException) {
        throw FirebaseAuthException(
          code: 'timeout',
          message: 'Google sign-in timed out. Please try again.',
        );
      } else {
        throw FirebaseAuthException(
          code: 'google-sign-in-failed',
          message: 'Failed to sign in with Google: ${e.toString()}',
        );
      }
    }
  }
}