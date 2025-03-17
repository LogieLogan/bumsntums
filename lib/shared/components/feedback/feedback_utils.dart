// lib/shared/components/feedback/feedback_utils.dart
import 'package:flutter/material.dart';
import 'satisfaction_prompt.dart';

class FeedbackUtils {
  /// Show a satisfaction prompt after a user completes a key action
  static void showSatisfactionPrompt({
    required BuildContext context,
    required String featureName,
    required String userId,
    VoidCallback? onComplete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SatisfactionPrompt(
          featureName: featureName,
          userId: userId,
          onComplete: onComplete,
        ),
      ),
    );
  }
  
  /// Show a prompt after N uses of a feature
  static void maybeShowFeedbackPrompt({
    required BuildContext context,
    required String featureName,
    required String userId,
    required int currentUsageCount,
    required List<int> triggerCounts, // e.g. [3, 10, 25]
    required Future<void> Function(int count) updateUsageCount,
    VoidCallback? onComplete,
  }) async {
    final newCount = currentUsageCount + 1;
    
    // Update usage count first
    await updateUsageCount(newCount);
    
    // Check if we should show feedback
    if (triggerCounts.contains(newCount)) {
      if (context.mounted) {
        showSatisfactionPrompt(
          context: context,
          featureName: featureName,
          userId: userId,
          onComplete: onComplete,
        );
      }
    }
  }
}