// lib/features/auth/widgets/onboarding/components/terms_conditions_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/models/legal_document.dart';
import '../../../../../shared/services/legal_document_service.dart';
import '../../../../../shared/theme/app_text_styles.dart';
import '../../../../../shared/theme/app_colors.dart';

class TermsConditionsDialog extends ConsumerStatefulWidget {
  final Function(bool accepted, int version) onResult;

  const TermsConditionsDialog({
    super.key,
    required this.onResult,
  });

  @override
  ConsumerState<TermsConditionsDialog> createState() => _TermsConditionsDialogState();
}

class _TermsConditionsDialogState extends ConsumerState<TermsConditionsDialog> {
  bool _isLoading = true;
  LegalDocument? _termsConditions;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTermsConditions();
  }

  Future<void> _loadTermsConditions() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final service = LegalDocumentService();
      final document = await service.getLegalDocument(LegalDocumentType.termsAndConditions);

      if (mounted) {
        setState(() {
          _termsConditions = document;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load terms and conditions. Please try again.';
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
              'Terms & Conditions',
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
                    widget.onResult(false, _termsConditions?.version ?? 1);
                  },
                  child: const Text('Decline'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onResult(true, _termsConditions?.version ?? 1);
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
                onPressed: _loadTermsConditions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_termsConditions == null) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Text('Terms and conditions not available.'),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: Markdown(
        data: _termsConditions!.content,
        shrinkWrap: true,
      ),
    );
  }
}