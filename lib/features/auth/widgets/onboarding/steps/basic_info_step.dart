// lib/features/auth/widgets/onboarding/steps/basic_info_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/theme/color_palette.dart';
import '../../../../../shared/theme/text_styles.dart';
import '../../../../../shared/components/buttons/primary_button.dart';
import '../../../providers/user_provider.dart';

// Controller class that can be shared between the coordinator and the step
class BasicInfoStepController {
  bool _canContinue = false;
  final _nameController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  Function(String)? onNext;

  // Getters and setters
  bool get canSubmit => _canContinue;
  TextEditingController get nameController => _nameController;
  
  // Methods
  void updateCanContinue(bool value) {
    _canContinue = value;
  }
  
  bool submitForm() {
    if (formKey.currentState!.validate() && onNext != null) {
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
  @override
  void initState() {
    super.initState();
    widget.controller.onNext = widget.onNext;
    _loadInitialDisplayName();
  }

  Future<void> _loadInitialDisplayName() async {
    try {
      final userService = ref.read(userProfileServiceProvider);
      final displayName = await userService.getDisplayName(widget.userId);
      if (displayName != null && mounted) {
        setState(() {
          widget.controller.nameController.text = displayName;
          _validateInput();
        });
      }
    } catch (e) {
      print('Error loading display name: $e');
    }
  }

  void _validateInput() {
    final text = widget.controller.nameController.text.trim();
    setState(() {
      widget.controller.updateCanContinue(text.isNotEmpty);
    });
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
            Text(
              'Let\'s start with your name',
              style: AppTextStyles.h3,
            ),
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
            Opacity(
              opacity: 0.6,
              child: Center(
                child: Text(
                  'This information is required',
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