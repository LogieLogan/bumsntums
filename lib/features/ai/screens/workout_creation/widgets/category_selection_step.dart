// Updated lib/features/ai/screens/workout_creation/widgets/category_selection_step.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../shared/theme/color_palette.dart';
import '../../../../../shared/theme/text_styles.dart';
import '../../../../../features/workouts/models/workout.dart';

class CategorySelectionStep extends StatefulWidget {
  final WorkoutCategory selectedCategory;
  final Function(WorkoutCategory) onCategorySelected;

  const CategorySelectionStep({
    Key? key,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<CategorySelectionStep> createState() => _CategorySelectionStepState();
}

class _CategorySelectionStepState extends State<CategorySelectionStep> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Create staggered animations for each card
    final categories = [
      WorkoutCategory.bums,
      WorkoutCategory.tums,
      WorkoutCategory.fullBody,
      WorkoutCategory.cardio,
      WorkoutCategory.quickWorkout,
    ];

    for (int i = 0; i < categories.length; i++) {
      final begin = 0.05 * i;
      final end = begin + 0.8;
      
      final curvedAnimation = CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, end, curve: Curves.easeOut),
      );
      
      _animations.add(Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation));
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What would you like to focus on today?', style: AppTextStyles.h3),
        const SizedBox(height: 8),
        Text(
          'Select the area you want to target with your workout',
          style: AppTextStyles.body.copyWith(color: AppColors.mediumGrey),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildAnimatedCategoryCard(
              title: 'Bums',
              icon: Icons.fitness_center,
              color: AppColors.salmon,
              category: WorkoutCategory.bums,
              animation: _animations[0],
              description: 'Glutes & lower body',
            ),
            _buildAnimatedCategoryCard(
              title: 'Tums',
              icon: Icons.accessibility_new,
              color: AppColors.popCoral,
              category: WorkoutCategory.tums,
              animation: _animations[1],
              description: 'Core & abs',
            ),
            _buildAnimatedCategoryCard(
              title: 'Full Body',
              icon: Icons.sports_gymnastics,
              color: AppColors.popBlue,
              category: WorkoutCategory.fullBody,
              animation: _animations[2],
              description: 'Complete workout',
            ),
            _buildAnimatedCategoryCard(
              title: 'Cardio',
              icon: Icons.directions_run,
              color: AppColors.popTurquoise,
              category: WorkoutCategory.cardio,
              animation: _animations[3],
              description: 'Heart & endurance',
            ),
            _buildAnimatedCategoryCard(
              title: 'Quick',
              icon: Icons.timer,
              color: AppColors.popGreen,
              category: WorkoutCategory.quickWorkout,
              animation: _animations[4],
              description: 'Fast & effective',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedCategoryCard({
    required String title,
    required IconData icon,
    required Color color,
    required WorkoutCategory category,
    required Animation<double> animation,
    required String description,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.7 + (0.3 * animation.value),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: _buildCategoryCard(
        title: title,
        icon: icon,
        color: color,
        category: category,
        description: description,
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required Color color,
    required WorkoutCategory category,
    required String description,
  }) {
    final isSelected = widget.selectedCategory == category;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onCategorySelected(category);
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.3),
        highlightColor: color.withOpacity(0.1),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color.withOpacity(0.8), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
            border: Border.all(
              color: isSelected ? Colors.transparent : color,
              width: isSelected ? 0 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withOpacity(0.2) 
                      : color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon, 
                  color: isSelected ? Colors.white : color, 
                  size: 28
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white.withOpacity(0.8) 
                      : AppColors.mediumGrey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}