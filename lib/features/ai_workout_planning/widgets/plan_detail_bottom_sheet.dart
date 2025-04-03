// lib/features/ai_workout_planning/widgets/plan_detail_bottom_sheet.dart
import 'package:bums_n_tums/features/workouts/models/workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/ai_workout_plan_model.dart';
import '../providers/ai_workout_plan_provider.dart';
import '../../workouts/screens/workout_detail_screen.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

class PlanDetailBottomSheet extends ConsumerStatefulWidget {
  final AiWorkoutPlan plan;
  final String userId;

  const PlanDetailBottomSheet({
    Key? key,
    required this.plan,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<PlanDetailBottomSheet> createState() => _PlanDetailBottomSheetState();
}

class _PlanDetailBottomSheetState extends ConsumerState<PlanDetailBottomSheet> 
    with SingleTickerProviderStateMixin {
  final _analyticsService = AnalyticsService();
  late AnimationController _animationController;
  late Animation<double> _contentAnimation;
  bool _showDeleteConfirmation = false;

  @override
  void initState() {
    super.initState();
    
    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _contentAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuad,
    );
    
    _animationController.forward();
    
    _analyticsService.logEvent(
      name: 'plan_detail_bottom_sheet_viewed',
      parameters: {'plan_id': widget.plan.id},
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine the primary color based on the first focus area
    Color primaryColor = AppColors.popBlue;
    if (widget.plan.focusAreas.isNotEmpty) {
      final firstFocusArea = widget.plan.focusAreas.first.toLowerCase();
      if (firstFocusArea.contains('bums')) {
        primaryColor = AppColors.pink;
      } else if (firstFocusArea.contains('tums')) {
        primaryColor = AppColors.popCoral;
      } else if (firstFocusArea.contains('full')) {
        primaryColor = AppColors.popBlue;
      } else if (firstFocusArea.contains('cardio')) {
        primaryColor = AppColors.popGreen;
      }
    }
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Hero(
                        tag: 'plan_title_${widget.plan.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            widget.plan.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGrey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _toggleDeleteConfirmation();
                      },
                      icon: Icon(
                        Icons.delete_outline,
                        color: _showDeleteConfirmation ? Colors.red : AppColors.mediumGrey,
                      ),
                      tooltip: 'Delete plan',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Created on ${DateFormat.yMMMMd().format(widget.plan.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mediumGrey,
                  ),
                ),
              ],
            ),
          ),
          
          // Delete confirmation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showDeleteConfirmation ? 80 : 0,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _showDeleteConfirmation ? Column(
              children: [
                Text(
                  'Are you sure you want to delete this plan?',
                  style: TextStyle(color: Colors.red[700]),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: _toggleDeleteConfirmation,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.mediumGrey,
                      ),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: _deletePlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ) : null,
          ),
          
          // Divider
          const Divider(),
          
          // Scrollable content
          Expanded(
            child: FadeTransition(
              opacity: _contentAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(_contentAnimation),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      if (widget.plan.description.isNotEmpty) ...[
                        Text(
                          'Description',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.plan.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Plan stats
                      Text(
                        'Plan Details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatRow(
                        context, 
                        'Duration', 
                        '${widget.plan.durationDays} days',
                        Icons.calendar_today,
                      ),
                      _buildStatRow(
                        context, 
                        'Frequency', 
                        '${widget.plan.daysPerWeek} days per week',
                        Icons.repeat,
                      ),
                      _buildStatRow(
                        context, 
                        'Difficulty', 
                        widget.plan.fitnessLevel.capitalize(),
                        Icons.fitness_center,
                      ),
                      _buildStatRow(
                        context, 
                        'Focus', 
                        widget.plan.focusAreas.join(', '),
                        Icons.stars,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Workouts
                      Text(
                        'Workouts',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...widget.plan.workouts.map((workout) => _buildWorkoutCard(
                        context,
                        workout,
                        primaryColor,
                      )),
                      
                      const SizedBox(height: 24),
                      
                      // Target area distribution
                      if (widget.plan.targetAreaDistribution != null &&
                          widget.plan.targetAreaDistribution!.isNotEmpty) ...[
                        Text(
                          'Workout Distribution',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDistributionChart(
                          context,
                          widget.plan.targetAreaDistribution!,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Action buttons
          Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + MediaQuery.of(context).padding.bottom),
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _startPlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Plan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatRow(
    BuildContext context, 
    String label, 
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.paleGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.mediumGrey,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mediumGrey,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildWorkoutCard(
    BuildContext context,
    PlanWorkout workout,
    Color primaryColor,
  ) {
    // Determine workout category color
    Color categoryColor;
    switch (workout.category) {
      case WorkoutCategory.bums:
        categoryColor = AppColors.pink;
        break;
      case WorkoutCategory.tums:
        categoryColor = AppColors.popCoral;
        break;
      case WorkoutCategory.cardio:
        categoryColor = AppColors.popGreen;
        break;
      case WorkoutCategory.fullBody:
      default:
        categoryColor = AppColors.popBlue;
        break;
    }
    
    // Determine difficulty indicator
    String difficultyText;
    switch (workout.difficulty) {
      case WorkoutDifficulty.beginner:
        difficultyText = 'Beginner';
        break;
      case WorkoutDifficulty.intermediate:
        difficultyText = 'Intermediate';
        break;
      case WorkoutDifficulty.advanced:
        difficultyText = 'Advanced';
        break;
      default:
        difficultyText = 'All Levels';
        break;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to workout detail
          HapticFeedback.selectionClick();
          _analyticsService.logEvent(
            name: 'plan_workout_tapped',
            parameters: {
              'workout_id': workout.workoutId,
              'plan_id': widget.plan.id,
            },
          );
          
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WorkoutDetailScreen(
                workoutId: workout.workoutId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.paleGrey,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      workout.category.name,
                      style: TextStyle(
                        color: categoryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paleGrey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      difficultyText,
                      style: TextStyle(
                        color: AppColors.mediumGrey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Day ${workout.dayIndex + 1}',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                workout.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (workout.description != null && workout.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  workout.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mediumGrey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDistributionChart(
    BuildContext context,
    Map<String, double> distribution,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.paleGrey,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: distribution.entries.map((entry) {
          // Determine bar color
          Color barColor;
          final category = entry.key.toLowerCase();
          if (category.contains('bums')) {
            barColor = AppColors.pink;
          } else if (category.contains('tums')) {
            barColor = AppColors.popCoral;
          } else if (category.contains('cardio')) {
            barColor = AppColors.popGreen;
          } else {
            barColor = AppColors.popBlue;
          }
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${entry.value.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: entry.value / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.paleGrey,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  void _toggleDeleteConfirmation() {
    HapticFeedback.selectionClick();
    setState(() {
      _showDeleteConfirmation = !_showDeleteConfirmation;
    });
  }
  
  void _deletePlan() {
    HapticFeedback.mediumImpact();
    _analyticsService.logEvent(
      name: 'plan_deleted',
      parameters: {'plan_id': widget.plan.id},
    );
    
    // Delete the plan
    ref.read(aiWorkoutPlanNotifierProvider(widget.userId).notifier)
      .deletePlan(widget.plan.id)
      .then((_) {
        // Close the bottom sheet
        Navigator.pop(context);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
  }
  
  void _startPlan() {
    HapticFeedback.mediumImpact();
    _analyticsService.logEvent(
      name: 'start_plan_button_tapped',
      parameters: {'plan_id': widget.plan.id},
    );
    
    // Close the bottom sheet
    Navigator.pop(context);
    
    // Show date picker for start date
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.pink,
              onPrimary: Colors.white,
              onSurface: AppColors.darkGrey,
            ),
          ),
          child: child!,
        );
      },
    ).then((selectedDate) {
      if (selectedDate != null) {
        // Start the plan
        ref.read(aiWorkoutPlanNotifierProvider(widget.userId).notifier)
          .startPlan(widget.plan.id, selectedDate)
          .then((_) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Plan "${widget.plan.name}" added to your schedule'),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'View',
                  onPressed: () {
                    // Go back to the weekly planning screen
                    Navigator.pop(context);
                  },
                ),
              ),
            );
          });
      }
    });
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}