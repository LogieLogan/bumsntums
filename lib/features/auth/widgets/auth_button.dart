// lib/features/auth/widgets/auth_button.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Add this import
import '../../../shared/theme/color_palette.dart';
import '../../../shared/components/buttons/primary_button.dart';

enum AuthButtonType {
  email,
  google,
  apple,
  anonymous,
}

class AuthButton extends StatelessWidget {
  final AuthButtonType type;
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const AuthButton({
    super.key,
    required this.type,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case AuthButtonType.email:
        return PrimaryButton(
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
          iconData: Icons.email_outlined,
        );
      
      case AuthButtonType.google:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: AppColors.lightGrey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Replace the Image.asset with FaIcon
              const FaIcon(
                FontAwesomeIcons.google,
                size: 24,
                color: Colors.red,
              ),
              const SizedBox(width: 12),
              Text(text),
            ],
          ),
        );
      
      case AuthButtonType.apple:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.apple, size: 24),
              const SizedBox(width: 12),
              Text(text),
            ],
          ),
        );
      
      case AuthButtonType.anonymous:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: Text(text),
        );
    }
  }
}