// lib/shared/components/feedback/satisfaction_prompt.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/feedback_provider.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';
import '../buttons/primary_button.dart';

class SatisfactionPrompt extends ConsumerStatefulWidget {
  final String featureName;
  final String userId;
  final VoidCallback? onComplete;

  const SatisfactionPrompt({
    Key? key,
    required this.featureName,
    required this.userId,
    this.onComplete,
  }) : super(key: key);

  @override
  ConsumerState<SatisfactionPrompt> createState() => _SatisfactionPromptState();
}

class _SatisfactionPromptState extends ConsumerState<SatisfactionPrompt> {
  int? _selectedRating;
  String? _comment;
  bool _isSubmitting = false;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitRating() {
    if (_selectedRating == null) return;

    setState(() => _isSubmitting = true);

    final feedbackService = ref.read(feedbackServiceProvider);

    feedbackService
        .submitSatisfactionRating(
          userId: widget.userId,
          rating: _selectedRating!,
          comment: _comment,
          featureName: widget.featureName,
        )
        .then((success) {
          if (mounted) {
            setState(() => _isSubmitting = false);
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thanks for your feedback!')),
              );
              Navigator.of(context).pop();
              if (widget.onComplete != null) {
                widget.onComplete!();
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Could not submit feedback. Please try again later.',
                  ),
                ),
              );
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'How was your experience?',
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Help us improve ${widget.featureName}',
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildRatingSelector(),
          const SizedBox(height: 16),
          if (_selectedRating != null && _selectedRating! < 4) ...[
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Tell us how we can improve',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => _comment = value,
            ),
            const SizedBox(height: 16),
          ],
          PrimaryButton(
            text: 'Submit',
            onPressed: _selectedRating == null ? null : _submitRating,
            isLoading: _isSubmitting,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (widget.onComplete != null) {
                widget.onComplete!();
              }
            },
            child: const Text('Not now'),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) {
        final rating = index + 1;
        return _buildRatingOption(rating);
      }),
    );
  }

  Widget _buildRatingOption(int rating) {
    final isSelected = _selectedRating == rating;

    return GestureDetector(
      onTap: () => setState(() => _selectedRating = rating),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.paleGrey : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              _getIconForRating(rating),
              color: isSelected ? AppColors.pink : AppColors.mediumGrey,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              _getLabelForRating(rating),
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.darkGrey : AppColors.mediumGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForRating(int rating) {
    switch (rating) {
      case 1:
        return Icons.sentiment_very_dissatisfied;
      case 2:
        return Icons.sentiment_dissatisfied;
      case 3:
        return Icons.sentiment_neutral;
      case 4:
        return Icons.sentiment_satisfied;
      case 5:
        return Icons.sentiment_very_satisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  String _getLabelForRating(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Great';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}
