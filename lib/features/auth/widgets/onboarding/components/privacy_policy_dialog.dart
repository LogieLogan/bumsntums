// lib/features/auth/widgets/onboarding/components/privacy_policy_dialog.dart
import 'package:flutter/material.dart';
import '../../../../../shared/theme/color_palette.dart';
import '../../../../../shared/theme/text_styles.dart';
import '../../../../../shared/components/buttons/primary_button.dart';

class PrivacyPolicyDialog extends StatelessWidget {
  final VoidCallback onAccept;

  const PrivacyPolicyDialog({
    super.key,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Privacy Policy',
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'How We Use Your Data',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 8),
              Text(
                'At Bums \'n\' Tums, we take your privacy seriously. We collect personal information to provide you with a personalized fitness experience:',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 16),
              _buildPrivacySection(
                icon: Icons.fitness_center,
                title: 'Personalized Workouts',
                content: 'We use your fitness goals, health information, and physical details to create personalized workout plans tailored to your needs.',
              ),
              _buildPrivacySection(
                icon: Icons.restaurant_menu,
                title: 'Nutrition Recommendations',
                content: 'Your dietary preferences and allergies help us suggest appropriate food options that align with your fitness goals.',
              ),
              _buildPrivacySection(
                icon: Icons.monitor_heart,
                title: 'Health & Safety',
                content: 'Health conditions you share allow us to provide safer workout recommendations by avoiding exercises that might be inappropriate for your situation.',
              ),
              _buildPrivacySection(
                icon: Icons.smart_toy,
                title: 'AI Processing',
                content: 'We use artificial intelligence to create personalized fitness recommendations. Your data is processed locally on your device and within our secure cloud environment.',
              ),
              const SizedBox(height: 16),
              Text(
                'Data Protection',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 8),
              Text(
                '• Your personal information is stored securely using industry-standard encryption.\n'
                '• Health and personal data is separated from public profile information.\n'
                '• We never share your personal health information with third parties.\n'
                '• You can request deletion of your data at any time through the app settings.',
                style: AppTextStyles.small,
              ),
              const SizedBox(height: 24),
              Center(
                child: PrimaryButton(
                  text: 'Accept & Continue',
                  onPressed: onAccept,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.salmon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.salmon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}