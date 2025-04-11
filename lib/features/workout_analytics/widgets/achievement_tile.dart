// lib/features/workout_analytics/widgets/achievement_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/achievement_definitions.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';

// Convert to StatefulWidget
class AchievementTile extends StatefulWidget {
  final DisplayAchievement achievement;
  final Duration animationDelay; // Optional delay for staggering effect

  const AchievementTile({
    Key? key,
    required this.achievement,
    this.animationDelay = Duration.zero, // Default to no delay
  }) : super(key: key);

  @override
  State<AchievementTile> createState() => _AchievementTileState();
}

class _AchievementTileState extends State<AchievementTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // Grayscale color filter matrix
  static const List<double> _grayscaleMatrix = <double>[
    0.2126, 0.7152, 0.0722, 0, 0, // Red channel
    0.2126, 0.7152, 0.0722, 0, 0, // Green channel
    0.2126, 0.7152, 0.0722, 0, 0, // Blue channel
    0, 0, 0, 1, 0, // Alpha channel
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Animation duration
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start animation after optional delay
    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        // Check if widget is still mounted before starting
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access widget properties via widget.achievement
    final bool isUnlocked = widget.achievement.isUnlocked;
    // ... (define colors, opacity based on isUnlocked as before) ...
    final Color iconBgColor =
        isUnlocked
            ? AppColors.popYellow.withOpacity(0.15)
            : AppColors.lightGrey.withOpacity(0.1);
    final Color iconFgColor =
        isUnlocked ? AppColors.popYellow : AppColors.mediumGrey;
    final Color titleColor =
        isUnlocked ? AppColors.darkGrey : AppColors.mediumGrey;
    final Color descColor = AppColors.mediumGrey;
    final double opacity = isUnlocked ? 1.0 : 0.7;

    // Build the core content of the tile
    Widget tileContent = Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          /* ... decoration ... */
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
          border:
              isUnlocked
                  ? Border.all(
                    color: AppColors.popYellow.withOpacity(0.6),
                    width: 1,
                  )
                  : Border.all(color: AppColors.paleGrey, width: 1),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              /* ... Icon container ... */
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                widget.achievement.definition.iconIdentifier,
                style: TextStyle(fontSize: 28, color: iconFgColor),
              ),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              /* ... Text column ... */
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.achievement.definition.title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.achievement.definition.description,
                    style: AppTextStyles.small.copyWith(color: descColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isUnlocked &&
                      widget.achievement.unlockedInfo != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Unlocked: ${DateFormat.yMMMd().format(widget.achievement.unlockedInfo!.unlockedDate)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.popGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isUnlocked)
              const Padding(
                /* Checkmark */
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.popGreen,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );

    // Apply ColorFiltered if NOT unlocked
    if (!isUnlocked) {
      tileContent = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
        child: tileContent,
      );
    }

    // Wrap the final content with FadeTransition
    return FadeTransition(opacity: _fadeAnimation, child: tileContent);
  }
}
