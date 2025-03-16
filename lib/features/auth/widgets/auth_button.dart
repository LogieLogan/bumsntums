// lib/features/auth/widgets/auth_button.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/components/buttons/primary_button.dart';
import '../../../shared/components/buttons/secondary_button.dart';

enum AuthButtonType {
  email,
  google,
  apple,
  anonymous,
}

enum AuthButtonStyle {
  primary,
  secondary,
  icon,
}

class AuthButton extends StatelessWidget {
  final AuthButtonType type;
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final AuthButtonStyle style;

  const AuthButton({
    super.key,
    required this.type,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.style = AuthButtonStyle.secondary,
  });

  @override
  Widget build(BuildContext context) {
    // Icon-only version
    if (style == AuthButtonStyle.icon) {
      return _buildIconButton(context);
    }
    
    // Use primary or secondary button component based on style
    if (style == AuthButtonStyle.primary) {
      return _buildPrimaryButton();
    } else {
      return _buildSecondaryButton();
    }
  }
  
  Widget _buildIconButton(BuildContext context) {
    IconData icon;
    Color color;
    
    switch (type) {
      case AuthButtonType.email:
        icon = Icons.email_outlined;
        color = Colors.blue;
        break;
      case AuthButtonType.google:
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
                onTap: isLoading ? null : onPressed,
                child: Center(
                  child: isLoading
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
      case AuthButtonType.apple:
        icon = Icons.apple;
        color = Colors.black;
        break;
      case AuthButtonType.anonymous:
        icon = Icons.person_outline;
        color = AppColors.popGreen;
        break;
    }
    
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
            onTap: isLoading ? null : onPressed,
            child: Center(
              child: isLoading
                ? SizedBox(
                    width: 20, 
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : Icon(icon, size: 26, color: color),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPrimaryButton() {
    // Use custom buttons based on type without passing iconData or customIcon
    switch (type) {
      case AuthButtonType.email:
        return _buildCustomPrimaryButton(
          icon: Icons.email_outlined,
          text: text,
        );
      case AuthButtonType.google:
        return _buildCustomPrimaryButton(
          iconWidget: FaIcon(FontAwesomeIcons.google, size: 20, color: Colors.white),
          text: text,
        );
      case AuthButtonType.apple:
        return _buildCustomPrimaryButton(
          icon: Icons.apple,
          text: text,
        );
      case AuthButtonType.anonymous:
        return _buildCustomPrimaryButton(
          icon: Icons.person_outline,
          text: text,
        );
    }
  }
  
  // Custom primary button that handles icons internally
  Widget _buildCustomPrimaryButton({
    IconData? icon,
    Widget? iconWidget,
    required String text,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.pink,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              width: 20, 
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else if (iconWidget != null)
            iconWidget
          else if (icon != null)
            Icon(icon, size: 20, color: Colors.white),
            
          if (!isLoading) const SizedBox(width: 8),
          if (!isLoading)
            Text(
              text.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSecondaryButton() {
    switch (type) {
      case AuthButtonType.email:
        return SecondaryButton(
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
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
              isLoading
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
              isLoading
                ? const SizedBox(
                    width: 20, 
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.apple, size: 24),
              const SizedBox(width: 12),
              Text(text),
            ],
          ),
        );
      
      case AuthButtonType.anonymous:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: isLoading
            ? const SizedBox(
                width: 20, 
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Text(text),
        );
    }
  }
}