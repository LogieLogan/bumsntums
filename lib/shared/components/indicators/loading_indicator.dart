// lib/shared/components/indicators/loading_indicator.dart
import 'package:flutter/material.dart';
import '../../theme/color_palette.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final Color color;
  
  const LoadingIndicator({
    super.key,
    this.message,
    this.color = AppColors.salmon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: color),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}