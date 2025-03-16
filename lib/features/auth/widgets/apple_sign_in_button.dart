// lib/features/auth/widgets/apple_sign_in_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_auth_service.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

class AppleSignInButton extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;
  final Function(String)? onError;
  final bool isFullWidth;

  const AppleSignInButton({
    super.key,
    this.onSuccess,
    this.onError,
    this.isFullWidth = false,
  });

  @override
  ConsumerState<AppleSignInButton> createState() => _AppleSignInButtonState();
}

class _AppleSignInButtonState extends ConsumerState<AppleSignInButton> {
  bool _isLoading = false;
  final _analyticsService = AnalyticsService();

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authStateNotifierProvider.notifier).signInWithApple();
      _analyticsService.logLogin(method: 'apple');

      // Call success callback if provided
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      }
    } on AuthException catch (e) {
      if (widget.onError != null) {
        widget.onError!(e.message);
      }
    } catch (e) {
      if (widget.onError != null) {
        widget.onError!('Failed to sign in with Apple. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _signInWithApple,
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.white,
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : const Icon(Icons.apple, size: 24),
        label: Text(
          widget.isFullWidth ? 'Sign in with Apple' : 'Apple',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}