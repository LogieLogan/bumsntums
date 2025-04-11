// lib/features/home/widgets/welcome_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/models/user_profile.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../providers/display_name_provider.dart';

class WelcomeCard extends ConsumerWidget {
  final UserProfile profile;

  const WelcomeCard({
    Key? key,
    required this.profile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.pink.withOpacity(0.8),
            AppColors.popTurquoise.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.pink.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final displayNameAsync = ref.watch(
                      displayNameProvider(profile.userId),
                    );
                    return displayNameAsync.when(
                      data: (name) => Text(
                        'Welcome, $name!',
                        style: AppTextStyles.h2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      loading: () => Text(
                        'Welcome, Fitness Friend!',
                        style: AppTextStyles.h2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      error: (_, __) => Text(
                        'Welcome, Fitness Friend!',
                        style: AppTextStyles.h2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  _getMotivationalMessage(),
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_shouldShowProgress())
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        _buildProgressIndicator(),
                        const SizedBox(width: 12),
                        Text(
                          "Weekly goal: 3/5 workouts",
                          style: AppTextStyles.small.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMotivationalMessage() {
    // In a real implementation, you could rotate through messages or personalize based on user behavior
    final List<String> messages = [
      "Let's make today count! 💪",
      "Ready for a great workout?",
      "Your future self will thank you!",
      "Every workout counts!",
      "Progress happens one step at a time",
    ];
    
    // Simple rotation based on the day of the week
    final int dayOfWeek = DateTime.now().weekday;
    return messages[dayOfWeek % messages.length];
  }

  bool _shouldShowProgress() {
    // In a real implementation, this would check if the user has any workout history
    return false; // Returning false for now
  }

  Widget _buildProgressIndicator() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 0.6, // 3/5 workouts = 0.6
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 4,
          ),
          Text(
            "3/5",
            style: AppTextStyles.small.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}