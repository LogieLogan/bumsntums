// lib/features/auth/widgets/onboarding/components/privacy_policy_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/models/legal_document.dart';
import '../../../../../shared/services/legal_document_service.dart';
import '../../../../../shared/theme/app_text_styles.dart';
import '../../../../../shared/theme/app_colors.dart';

class PrivacyPolicyDialog extends ConsumerStatefulWidget {
  final Function(bool accepted, int version) onResult;

  const PrivacyPolicyDialog({
    super.key,
    required this.onResult,
  });

  @override
  ConsumerState<PrivacyPolicyDialog> createState() => _PrivacyPolicyDialogState();
}

class _PrivacyPolicyDialogState extends ConsumerState<PrivacyPolicyDialog> {
  bool _isLoading = true;
  LegalDocument? _privacyPolicy;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPrivacyPolicy();
  }

  Future<void> _loadPrivacyPolicy() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final service = LegalDocumentService();
      final document = await service.getLegalDocument(LegalDocumentType.privacyPolicy);

      if (mounted) {
        setState(() {
          _privacyPolicy = document;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load privacy policy. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Privacy Policy',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildContent(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    widget.onResult(false, _privacyPolicy?.version ?? 1);
                  },
                  child: const Text('Decline'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onResult(true, _privacyPolicy?.version ?? 1);
                  },
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage,
                style: TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPrivacyPolicy,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_privacyPolicy == null) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Text('Privacy policy not available.'),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: Markdown(
        data: _privacyPolicy!.content,
        shrinkWrap: true,
      ),
    );
  }
}