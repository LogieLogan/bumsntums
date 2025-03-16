// lib/features/auth/screens/login_screen.dart
import 'dart:async';

import 'package:bums_n_tums/features/auth/widgets/auth_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../services/firebase_auth_service.dart';
import 'package:go_router/go_router.dart';
import '../widgets/google_sign_in_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _forgotPasswordEmailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  final _analyticsService = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _analyticsService.logScreenView(screenName: 'login_screen');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _forgotPasswordEmailController.dispose();
    super.dispose();
  }

  // Show forgot password dialog
  void _showForgotPasswordDialog() {
    _forgotPasswordEmailController.text = _emailController.text;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Reset Password', style: AppTextStyles.h3),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter your email address and we\'ll send you a link to reset your password.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _forgotPasswordEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetPassword();
                },
                child: const Text('Send Reset Link'),
              ),
            ],
          ),
    );
  }

  // Reset password functionality
  Future<void> _resetPassword() async {
    final email = _forgotPasswordEmailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your email')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent to your email'),
          backgroundColor: AppColors.success,
        ),
      );

      _analyticsService.logEvent(
        name: 'password_reset_email_sent',
        parameters: {'email': email},
      );
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to send password reset email. Please try again.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authStateNotifierProvider.notifier)
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      _analyticsService.logLogin(method: 'email');

      // Navigate to home screen
      if (mounted) {
        context.go('/');
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authStateNotifierProvider.notifier).signInWithApple();
      _analyticsService.logLogin(method: 'apple');

      // Navigate to home screen
      if (mounted) {
        context.go('/');
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

  Future<void> _signInAnonymously() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authStateNotifierProvider.notifier).signInAnonymously();
      _analyticsService.logLogin(method: 'anonymous');

      // Navigate to home screen
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToSignup() {
    context.push(AppConstants.signupRoute);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.pink, // Solid background color
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative Circles
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.popYellow.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.popTurquoise.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Main content area
              Center(
                child: SingleChildScrollView(
                  child: Container(
                    width: size.width * 0.9,
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // App logo or image
                        const Icon(
                          Icons.fitness_center,
                          size: 60,
                          color: AppColors.pink,
                        ),

                        const SizedBox(height: 16),

                        // App name
                        Text(
                          'Bums \'n\' Tums',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.pink,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        // Tagline
                        Text(
                          'Your fitness journey starts here',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.darkGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),

                        // Login form
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
                                  if (!RegExp(
                                    r'^[^@]+@[^@]+\.[^@]+',
                                  ).hasMatch(value)) {
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
                                ),
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                                onFieldSubmitted:
                                    (_) => _signInWithEmailAndPassword(),
                              ),

                              const SizedBox(height: 8),

                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _showForgotPasswordDialog,
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(color: AppColors.popBlue),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Error message
                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: AppTextStyles.small.copyWith(
                                      color: AppColors.error,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Login button
                              ElevatedButton(
                                onPressed:
                                    _isLoading
                                        ? null
                                        : _signInWithEmailAndPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.pink,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child:
                                    _isLoading
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : const Text(
                                          'LOGIN',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),

                              const SizedBox(height: 16),

                              // Sign up button
                              OutlinedButton(
                                onPressed: _navigateToSignup,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.pink,
                                  side: const BorderSide(color: AppColors.pink),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'SIGN UP',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Or divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: AppColors.lightGrey.withOpacity(
                                        0.5,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(
                                        color: AppColors.mediumGrey,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: AppColors.lightGrey.withOpacity(
                                        0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Social login options
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  AuthButton(
                                    type: AuthButtonType.google,
                                    text: 'Google',
                                    style: AuthButtonStyle.icon,
                                    onPressed: () {
                                      ref
                                          .read(
                                            authStateNotifierProvider.notifier,
                                          )
                                          .signInWithGoogle()
                                          .then(
                                            (_) {
                                              // Let the auth guard handle redirection based on profile state
                                              context.go(
                                                '/',
                                              ); // Trigger auth guard check
                                            },
                                            onError: (error) {
                                              setState(() {
                                                if (error is AuthException) {
                                                  _errorMessage = error.message;
                                                } else {
                                                  _errorMessage =
                                                      'Failed to sign in with Google. Please try again.';
                                                }
                                              });
                                            },
                                          );
                                    },
                                    isLoading: false,
                                  ),
                                  AuthButton(
                                    type: AuthButtonType.apple,
                                    text: 'Apple',
                                    style: AuthButtonStyle.icon,
                                    onPressed: _signInWithApple,
                                    isLoading: false,
                                  ),
                                  AuthButton(
                                    type: AuthButtonType.anonymous,
                                    text: 'Anonymous',
                                    style: AuthButtonStyle.icon,
                                    onPressed: _signInAnonymously,
                                    isLoading: false,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(27.5),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(icon, size: 26, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
