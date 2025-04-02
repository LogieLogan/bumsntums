// lib/features/ai_workout_planning/widgets/visualization/plan_preview.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/theme/color_palette.dart';
import 'plan_calendar_view.dart';
import 'workout_distribution_chart.dart';

class PlanPreview extends StatefulWidget {
  final Map<String, dynamic> planData;
  final VoidCallback onRefine;

  const PlanPreview({
    Key? key,
    required this.planData,
    required this.onRefine,
  }) : super(key: key);

  @override
  State<PlanPreview> createState() => _PlanPreviewState();
}

class _PlanPreviewState extends State<PlanPreview> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planName = widget.planData['planName'] as String? ?? 'Your Workout Plan';
    final planDescription = widget.planData['planDescription'] as String? ?? '';
    final successTips = widget.planData['successTips'] as List<dynamic>? ?? [];
    final scheduledWorkouts = widget.planData['scheduledWorkouts'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success animation and header
        Center(
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Plan Created!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your personalized workout plan is ready',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.mediumGrey,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Plan name and description
        Text(
          planName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          planDescription,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        
        const SizedBox(height: 24),
        
        // Tab bar for different views
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Calendar View'),
            Tab(text: 'Statistics'),
          ],
          labelColor: AppColors.pink,
          unselectedLabelColor: AppColors.mediumGrey,
          indicatorColor: AppColors.pink,
        ),
        
        const SizedBox(height: 16),
        
        // Tab content
        SizedBox(
          height: 300, // Fixed height for tab content
          child: TabBarView(
            controller: _tabController,
            children: [
              // Calendar view tab
              PlanCalendarView(scheduledWorkouts: scheduledWorkouts),
              
              // Statistics tab
              WorkoutDistributionChart(planData: widget.planData),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Success tips
        if (successTips.isNotEmpty) ...[
          Text(
            'Tips for Success',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...successTips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates, 
                  color: AppColors.popYellow, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(tip.toString())),
              ],
            ),
          )),
          const SizedBox(height: 16),
        ],
        
        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onRefine,
                icon: const Icon(Icons.edit),
                label: const Text('Refine Plan'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement save functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plan saved successfully!')),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Save Plan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}