// lib/shared/components/feedback/shake_to_report.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/feedback_provider.dart';
import '../../services/shake_detector_service.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';
import '../buttons/primary_button.dart';

class ShakeToReportManager extends ConsumerStatefulWidget {
  final Widget child;
  final String userId;
  final String Function() getCurrentScreen;

  const ShakeToReportManager({
    Key? key,
    required this.child,
    required this.userId,
    required this.getCurrentScreen,
  }) : super(key: key);

  @override
  ConsumerState<ShakeToReportManager> createState() =>
      _ShakeToReportManagerState();
}

class _ShakeToReportManagerState extends ConsumerState<ShakeToReportManager> {
  final _shakeDetector = ShakeDetectorService();

  @override
  void initState() {
    super.initState();
    // Start listening for shakes
    _shakeDetector.startListening(onShake: _handleShake);
  }

  @override
  void dispose() {
    _shakeDetector.stopListening();
    super.dispose();
  }

  void _handleShake() {
    if (!mounted) return;

    // Get current screen from the callback
    final currentScreen = widget.getCurrentScreen();

    // Show the bug report dialog
    showDialog(
      context: context,
      builder:
          (context) => ShakeReportDialog(
            userId: widget.userId,
            currentScreen: currentScreen,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class ShakeReportDialog extends ConsumerStatefulWidget {
  final String userId;
  final String currentScreen;

  const ShakeReportDialog({
    Key? key,
    required this.userId,
    required this.currentScreen,
  }) : super(key: key);

  @override
  ConsumerState<ShakeReportDialog> createState() => _ShakeReportDialogState();
}

class _ShakeReportDialogState extends ConsumerState<ShakeReportDialog> {
  final _bugDescriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _bugDescriptionController.dispose();
    super.dispose();
  }

  void _submitBugReport() {
    if (_bugDescriptionController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    final feedbackService = ref.read(feedbackServiceProvider);

    feedbackService
        .submitBugReport(
          userId: widget.userId,
          description: _bugDescriptionController.text,
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
                      ? 'Bug report submitted. Thank you!'
                      : 'Could not submit bug report. Please try again later.',
                ),
              ),
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.bug_report, color: AppColors.popCoral),
          const SizedBox(width: 8),
          Text('Report an Issue', style: AppTextStyles.h3),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You shook your device to report an issue.',
              style: AppTextStyles.small,
            ),
            Text(
              'Current screen: ${widget.currentScreen}',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bugDescriptionController,
              decoration: const InputDecoration(
                hintText: 'Describe what went wrong...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        PrimaryButton(
          text: 'Submit',
          onPressed: _isSubmitting ? null : _submitBugReport,
          isLoading: _isSubmitting,
        ),
      ],
    );
  }
}
