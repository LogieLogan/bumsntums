// lib/features/auth/widgets/google_sign_in_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/auth_provider.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../services/firebase_auth_service.dart';
import 'dart:async';

class GoogleSignInButton extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;
  final Function(String) onError;
  final bool isFullWidth;
  final bool isIconOnly;
  
  const GoogleSignInButton({
    super.key, 
    required this.onSuccess,
    required this.onError,
    this.isFullWidth = false,
    this.isIconOnly = false,
  });

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _isLoading = false;
  final _analyticsService = AnalyticsService();
  Timer? _timeoutTimer;

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    _timeoutTimer = Timer(const Duration(seconds: 20), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        widget.onError('Sign-in is taking longer than expected. Please try again.');
      }
    });
    
    try {
      await ref.read(authStateNotifierProvider.notifier).signInWithGoogle();
      _analyticsService.logLogin(method: 'google');
      
      widget.onSuccess();
    } on AuthException catch (e) {
      widget.onError(e.message);
    } catch (e) {
      widget.onError('Failed to sign in with Google. Please try again.');
    } finally {
      _timeoutTimer?.cancel();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Icon-only version (for login screen social row)
    if (widget.isIconOnly) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: Colors.white,
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
              onTap: _isLoading ? null : _signInWithGoogle,
              child: Center(
                child: _isLoading
                  ? SizedBox(
                      width: 20, 
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey.shade700,
                      ),
                    )
                  : FaIcon(
                      FontAwesomeIcons.google, 
                      size: 20, 
                      color: Colors.red,
                    ),
              ),
            ),
          ),
        ),
      );
    }
    
    // Full button version
    return OutlinedButton(
      onPressed: _isLoading ? null : _signInWithGoogle,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _isLoading
            ? SizedBox(
                width: 20, 
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey.shade700,
                ),
              )
            : FaIcon(
                FontAwesomeIcons.google, 
                size: 20, 
                color: Colors.red,
              ),
          const SizedBox(width: 12),
          Text(
            _isLoading ? 'Signing in...' : 'Sign in with Google',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}