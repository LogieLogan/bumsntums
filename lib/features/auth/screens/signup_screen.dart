// lib/features/auth/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/auth_button.dart';
import '../providers/auth_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/components/buttons/primary_button.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../services/firebase_auth_service.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import '../widgets/google_sign_in_button.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  final _analyticsService = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _analyticsService.logScreenView(screenName: 'signup_screen');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authStateNotifierProvider.notifier).signInWithApple();
      _analyticsService.logSignUp(method: 'apple');

      // Navigate to onboarding after successful sign-in
      if (mounted) {
        GoRouter.of(context).go('/');
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sign in with Apple. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUpWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check internet connectivity first
      bool hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        setState(() {
          _errorMessage =
              'No internet connection. Please check your network settings.';
          _isLoading = false;
        });
        return;
      }

      await ref
          .read(authStateNotifierProvider.notifier)
          .signUpWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // After successful signup, navigate to onboarding
      if (mounted) {
        GoRouter.of(context).go('/');
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
      // Log the error
      _analyticsService.logError(error: 'Auth Exception: ${e.message}');
    } catch (e) {
      print('Signup error: $e');
      setState(() {
        if (e.toString().contains('permission') ||
            e.toString().contains('Permission')) {
          _errorMessage =
              'Permission denied. Please check app permissions in settings.';
        } else {
          _errorMessage = 'An error occurred. Please try again.';
        }
      });
      // Log the error
      _analyticsService.logError(error: 'General Exception: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add this method to check internet connectivity
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void _navigateToLogin() {
    GoRouter.of(context).go(AppConstants.loginRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App logo or image
                const Icon(
                  Icons.fitness_center,
                  size: 64,
                  color: AppColors.salmon,
                ),

                const SizedBox(height: 16),

                Text(
                  'Join Bums & Tums',
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Create an account to track your fitness journey',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Signup form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email field
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                          helperText: 'Must be at least 8 characters',
                        ),
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < AppConstants.minPasswordLength) {
                            return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Confirm password field
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _signUpWithEmailAndPassword(),
                      ),

                      const SizedBox(height: 24),

                      // Error message
                      if (_errorMessage != null) ...[
                        Text(
                          _errorMessage!,
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Signup button
                      PrimaryButton(
                        text: 'Create Account',
                        onPressed: _signUpWithEmailAndPassword,
                        isLoading: _isLoading,
                      ),

                      const SizedBox(height: 24),

                      // Or divider
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Social signup options
                      GoogleSignInButton(
                        isFullWidth: true,
                        onSuccess: () {
                          GoRouter.of(context).go('/');
                        },
                        onError: (errorMessage) {
                          setState(() {
                            _errorMessage = errorMessage;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      AuthButton(
                        type: AuthButtonType.apple,
                        text: 'Sign up with Apple',
                        onPressed: _signInWithApple,
                      ),

                      const SizedBox(height: 32),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account?'),
                          TextButton(
                            onPressed: _navigateToLogin,
                            child: const Text('Log In'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Terms and privacy policy
                      Text(
                        'By signing up, you agree to our Terms of Service and Privacy Policy',
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
