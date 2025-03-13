// lib/features/splash/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/providers/user_provider.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    print('Starting auth check...');

    // Give the splash screen a moment to display
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) {
      print('Widget not mounted after delay');
      return;
    }

    try {
      // Navigate based on auth state
      print('Reading auth state...');
      final authState = ref.read(authStateProvider);

      print('Auth state: $authState');

      // Handle the auth state directly
      if (authState is AsyncLoading) {
        print('Auth state is still loading, waiting...');
        // Wait a bit more and check again
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;

        // Try again after delay
        final updatedAuthState = ref.read(authStateProvider);
        _handleAuthState(updatedAuthState);
      } else {
        // Handle current auth state
        _handleAuthState(authState);
      }
    } catch (e) {
      print('Error in auth check: $e');
      if (!mounted) return;
      // Default to login on error
      context.go(AppConstants.loginRoute);
    }
  }

  void _handleAuthState(AsyncValue<User?> authState) {
    authState.whenData((user) async {
      print('Auth state data received, user: ${user?.uid}');

      if (user == null) {
        print('No user, navigating to login');
        if (!mounted) return;
        context.go(AppConstants.loginRoute);
      } else {
        print('User found, checking profile...');
        try {
          print('Fetching user profile...');
          final userProfileAsync = await ref.read(userProfileProvider.future);

          print('User profile: $userProfileAsync');

          if (!mounted) {
            print('Widget not mounted after profile fetch');
            return;
          }

          if (userProfileAsync == null ||
              !userProfileAsync.onboardingCompleted) {
            print('Onboarding needed, navigating to onboarding');
            context.go(AppConstants.onboardingRoute);
          } else {
            print('Onboarding complete, navigating to home');
            context.go(AppConstants.homeRoute);
          }
        } catch (e) {
          print('Error fetching user profile: $e');
          if (!mounted) return;
          context.go(AppConstants.loginRoute);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            const Icon(
              Icons.fitness_center,
              size: 100,
              color: AppColors.salmon,
            ),

            const SizedBox(height: 24),

            // App name
            Text(
              'Bums \'n\' Tums',
              style: AppTextStyles.h1.copyWith(color: AppColors.salmon),
            ),

            const SizedBox(height: 8),

            // Tagline
            Text('Your fitness journey starts here', style: AppTextStyles.body),

            const SizedBox(height: 48),

            // Using shared loading indicator
            const LoadingIndicator(),
          ],
        ),
      ),
    );
  }
}
