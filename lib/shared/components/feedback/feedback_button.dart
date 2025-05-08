// lib/shared/components/feedback/feedback_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/feedback_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../buttons/secondary_button.dart';

class FeedbackButton extends ConsumerWidget {
  final String userId;
  final String currentScreen;

  const FeedbackButton({
    super.key,
    required this.userId,
    required this.currentScreen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.feedback_outlined),
      onPressed: () => _showFeedbackDialog(context, ref),
      tooltip: 'Send Feedback',
    );
  }

  void _showFeedbackDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) =>
              FeedbackDialog(userId: userId, currentScreen: currentScreen),
    );
  }
}

class FeedbackDialog extends ConsumerStatefulWidget {
  final String userId;
  final String currentScreen;

  const FeedbackDialog({
    super.key,
    required this.userId,
    required this.currentScreen,
  });

  @override
  ConsumerState<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<FeedbackDialog> {
  String _feedbackType = 'feature'; // 'feature' or 'bug'
  final _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    if (_feedbackController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    final feedbackService = ref.read(feedbackServiceProvider);

    if (_feedbackType == 'feature') {
      feedbackService
          .submitFeatureRequest(
            userId: widget.userId,
            featureDescription: _feedbackController.text,
          )
          .then((success) {
            if (mounted) {
              setState(() => _isSubmitting = false);
              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Thanks for your feedback!'
                        : 'Could not submit feedback. Please try again later.',
                  ),
                ),
              );
            }
          });
    } else {
      // bug
      feedbackService
          .submitBugReport(
            userId: widget.userId,
            description: _feedbackController.text,
            screenName: widget.currentScreen,
          )
          .then((success) {
            if (mounted) {
              setState(() => _isSubmitting = false);
              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Thanks for your feedback!'
                        : 'Could not submit feedback. Please try again later.',
                  ),
                ),
              );
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Send Feedback', style: AppTextStyles.h3),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What would you like to share?', style: AppTextStyles.small),
            const SizedBox(height: 16),
            _buildFeedbackTypeSelector(),
            const SizedBox(height: 16),
            TextField(
              controller: _feedbackController,
              decoration: InputDecoration(
                hintText:
                    _feedbackType == 'feature'
                        ? 'Describe the feature you\'d like'
                        : 'Describe the issue you\'re experiencing',
                border: const OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: AppTextStyles.body),
        ),
        SecondaryButton(
          text: 'Submit',
          onPressed: _isSubmitting ? null : _submitFeedback,
          isLoading: _isSubmitting,
        ),
      ],
    );
  }

  Widget _buildFeedbackTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeOption(
            title: 'Feature Request',
            value: 'feature',
            icon: Icons.lightbulb_outline,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTypeOption(
            title: 'Report Issue',
            value: 'bug',
            icon: Icons.bug_report_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _feedbackType == value;

    return GestureDetector(
      onTap: () => setState(() => _feedbackType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.paleGrey : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.pink : AppColors.lightGrey,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.pink : AppColors.mediumGrey,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.small.copyWith(
                color: isSelected ? AppColors.darkGrey : AppColors.mediumGrey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
