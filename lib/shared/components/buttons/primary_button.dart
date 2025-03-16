// Update to primary_button.dart
import 'package:flutter/material.dart';
import '../../theme/color_palette.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final double width; // Add width parameter

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.width = double.infinity, // Default to full width
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width, // Use the width parameter
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? AppColors.pink : AppColors.lightGrey,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child:
            isLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Text(
                  text.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
      ),
    );
  }
}
