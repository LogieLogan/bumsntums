// lib/features/auth/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../widgets/profile_setup_form.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _analyticsService = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _analyticsService.logScreenView(screenName: 'onboarding_screen');
  }

  void _onProfileSetupComplete(UserProfile profile) {
    // Navigate to home screen
    Navigator.pushReplacementNamed(context, AppConstants.homeRoute);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Profile'),
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('You need to be logged in to access this page'),
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Let\'s personalize your experience',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tell us about yourself so we can create a personalized fitness plan for you.',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final userProfileAsync = ref.watch(userProfileProvider);
                        
                        return userProfileAsync.when(
                          data: (profile) {
                            // Use existing profile or create a new one
                            final userProfile = profile ?? UserProfile.empty(user.uid);
                            
                            return ProfileSetupForm(
                              initialProfile: userProfile,
                              onComplete: _onProfileSetupComplete,
                            );
                          },
                          loading: () => const LoadingIndicator(
                            message: 'Loading your profile...',
                          ),
                          error: (error, stackTrace) => Center(
                            child: Text(
                              'Error loading profile: ${error.toString()}',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingIndicator(
          message: 'Loading...',
        ),
        error: (error, stackTrace) => Center(
          child: Text(
            'Error: ${error.toString()}',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}