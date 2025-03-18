// lib/features/auth/widgets/onboarding/steps/basic_info_step.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/theme/text_styles.dart';
import '../../../../../shared/theme/color_palette.dart';
import '../../../../../shared/models/legal_document.dart';
import '../../../../../shared/services/legal_document_service.dart';
import '../../../providers/user_provider.dart';
import '../components/privacy_policy_dialog.dart';
import '../components/terms_conditions_dialog.dart';

// Controller class that can be shared between the coordinator and the step
class BasicInfoStepController {
  bool _canContinue = false;
  final _nameController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  Function(String)? onNext;
  bool _hasAcceptedPrivacyPolicy = false;
  bool _hasAcceptedTerms = false;
  int _privacyPolicyVersion = 1;
  int _termsVersion = 1;

  // Getters and setters
  bool get canSubmit => _canContinue && _hasAcceptedPrivacyPolicy && _hasAcceptedTerms;
  TextEditingController get nameController => _nameController;
  bool get hasAcceptedPrivacyPolicy => _hasAcceptedPrivacyPolicy;
  bool get hasAcceptedTerms => _hasAcceptedTerms;
  int get privacyPolicyVersion => _privacyPolicyVersion;
  int get termsVersion => _termsVersion;

  // Methods
  void updateCanContinue(bool value) {
    _canContinue = value;
  }

  void setPrivacyPolicyAccepted(bool value, int version) {
    _hasAcceptedPrivacyPolicy = value;
    _privacyPolicyVersion = version;
  }

  void setTermsAccepted(bool value, int version) {
    _hasAcceptedTerms = value;
    _termsVersion = version;
  }

  bool submitForm() {
    if (formKey.currentState!.validate() && 
        _hasAcceptedPrivacyPolicy && 
        _hasAcceptedTerms &&
        onNext != null) {
      onNext!(_nameController.text);
      return true;
    }
    return false;
  }

  // Cleanup
  void dispose() {
    _nameController.dispose();
  }
}

class BasicInfoStep extends ConsumerStatefulWidget {
  final String userId;
  final Function(String) onNext;
  final BasicInfoStepController controller;

  const BasicInfoStep({
    super.key,
    required this.userId,
    required this.onNext,
    required this.controller,
  });

  @override
  ConsumerState<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends ConsumerState<BasicInfoStep> {
  bool _isLoading = false;
  final LegalDocumentService _legalService = LegalDocumentService();

  @override
  void initState() {
    super.initState();
    widget.controller.onNext = widget.onNext;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userService = ref.read(userProfileServiceProvider);
      final displayName = await userService.getDisplayName(widget.userId);
      if (displayName != null && mounted) {
        widget.controller.nameController.text = displayName;
      }
      
      // Load legal documents to get latest versions
      await _preloadLegalDocuments();
    } catch (e) {
      print('Error loading initial data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _validateInput();
        });
      }
    }
  }

  Future<void> _preloadLegalDocuments() async {
    try {
      // Preload legal documents to ensure they're available in the cache
      await _legalService.getLegalDocument(LegalDocumentType.privacyPolicy);
      await _legalService.getLegalDocument(LegalDocumentType.termsAndConditions);
    } catch (e) {
      print('Error preloading legal documents: $e');
    }
  }

  void _validateInput() {
    final text = widget.controller.nameController.text.trim();
    setState(() {
      widget.controller.updateCanContinue(text.isNotEmpty);
    });
  }

  void _showPrivacyPolicy() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return PrivacyPolicyDialog(
          onResult: (accepted, version) {
            setState(() {
              widget.controller.setPrivacyPolicyAccepted(accepted, version);
            });
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void _showTermsAndConditions() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return TermsConditionsDialog(
          onResult: (accepted, version) {
            setState(() {
              widget.controller.setTermsAccepted(accepted, version);
            });
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Form(
        key: widget.controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Let\'s start with your name', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'This is how you\'ll appear to other users in the app',
              style: AppTextStyles.small,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: widget.controller.nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                helperText: 'This will be visible to other users',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a display name';
                }
                return null;
              },
              onChanged: (value) {
                _validateInput();
              },
            ),
            const SizedBox(height: 32),
            
            // GDPR Consent Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.paleGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Legal Agreements', style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  Text(
                    'To create your account, please review and accept our terms and privacy policy.',
                    style: AppTextStyles.small,
                  ),
                  const SizedBox(height: 16),
                  
                  // Privacy Policy Checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: widget.controller.hasAcceptedPrivacyPolicy,
                        onChanged: (value) {
                          if (value == true && !widget.controller.hasAcceptedPrivacyPolicy) {
                            _showPrivacyPolicy();
                          } else {
                            setState(() {
                              widget.controller.setPrivacyPolicyAccepted(false, 1);
                            });
                          }
                        },
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!widget.controller.hasAcceptedPrivacyPolicy) {
                              _showPrivacyPolicy();
                            } else {
                              setState(() {
                                widget.controller.setPrivacyPolicyAccepted(false, 1);
                              });
                            }
                          },
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.small.copyWith(color: AppColors.darkGrey),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: AppColors.popBlue,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = _showPrivacyPolicy,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Terms & Conditions Checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: widget.controller.hasAcceptedTerms,
                        onChanged: (value) {
                          if (value == true && !widget.controller.hasAcceptedTerms) {
                            _showTermsAndConditions();
                          } else {
                            setState(() {
                              widget.controller.setTermsAccepted(false, 1);
                            });
                          }
                        },
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!widget.controller.hasAcceptedTerms) {
                              _showTermsAndConditions();
                            } else {
                              setState(() {
                                widget.controller.setTermsAccepted(false, 1);
                              });
                            }
                          },
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.small.copyWith(color: AppColors.darkGrey),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms & Conditions',
                                  style: TextStyle(
                                    color: AppColors.popBlue,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = _showTermsAndConditions,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            Opacity(
              opacity: 0.6,
              child: Center(
                child: Text(
                  'All fields are required to continue',
                  style: AppTextStyles.small,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}