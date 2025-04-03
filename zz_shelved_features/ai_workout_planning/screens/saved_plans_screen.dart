// // lib/features/ai_workout_planning/screens/saved_plans_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
// import '../models/ai_workout_plan_model.dart';
// import '../providers/ai_workout_plan_provider.dart';
// import '../widgets/plan_detail_bottom_sheet.dart';
// import '../../../shared/components/indicators/loading_indicator.dart';
// import '../../../shared/theme/color_palette.dart';
// import '../../../shared/analytics/firebase_analytics_service.dart';

// class SavedPlansScreen extends ConsumerStatefulWidget {
//   final String userId;

//   const SavedPlansScreen({Key? key, required this.userId}) : super(key: key);

//   @override
//   ConsumerState<SavedPlansScreen> createState() => _SavedPlansScreenState();
// }

// class _SavedPlansScreenState extends ConsumerState<SavedPlansScreen>
//     with SingleTickerProviderStateMixin {
//   final _analyticsService = AnalyticsService();
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();

//     // Set up animations
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );

//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
//     );

//     _animationController.forward();

//     _analyticsService.logScreenView(screenName: 'saved_plans_screen');
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   void _showPlanDetails(AiWorkoutPlan plan) {
//     // Add haptic feedback
//     HapticFeedback.selectionClick();

//     _analyticsService.logEvent(
//       name: 'view_saved_plan_details',
//       parameters: {'plan_id': plan.id},
//     );

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder:
//           (context) => PlanDetailBottomSheet(plan: plan, userId: widget.userId),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final plansState = ref.watch(aiWorkoutPlanNotifierProvider(widget.userId));

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Saved Workout Plans'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               ref
//                   .read(aiWorkoutPlanNotifierProvider(widget.userId).notifier)
//                   .loadPlans();
//               _analyticsService.logEvent(name: 'refresh_saved_plans');
//             },
//             tooltip: 'Refresh plans',
//           ),
//         ],
//       ),
//       body:
//           plansState.isLoading
//               ? const LoadingIndicator(message: 'Loading your plans...')
//               : plansState.plans.isEmpty
//               ? _buildEmptyState()
//               : _buildPlansList(plansState.plans),
//     );
//   }

//   Widget _buildEmptyState() {
//     return FadeTransition(
//       opacity: _fadeAnimation,
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.fitness_center, size: 72, color: AppColors.lightGrey),
//             const SizedBox(height: 16),
//             Text(
//               'No saved workout plans',
//               style: Theme.of(
//                 context,
//               ).textTheme.headlineSmall?.copyWith(color: AppColors.darkGrey),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Create an AI plan to see it here',
//               style: Theme.of(
//                 context,
//               ).textTheme.bodyMedium?.copyWith(color: AppColors.mediumGrey),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _analyticsService.logEvent(
//                   name: 'create_plan_from_empty_state',
//                 );
//               },
//               icon: const Icon(Icons.add),
//               label: const Text('Create a Plan'),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 24,
//                   vertical: 12,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPlansList(List<AiWorkoutPlan> plans) {
//     return AnimatedList(
//       initialItemCount: plans.length,
//       padding: const EdgeInsets.all(16),
//       itemBuilder: (context, index, animation) {
//         final plan = plans[index];
//         return SlideTransition(
//           position: animation.drive(
//             Tween<Offset>(
//               begin: const Offset(1, 0),
//               end: Offset.zero,
//             ).chain(CurveTween(curve: Curves.easeOutCubic)),
//           ),
//           child: FadeTransition(
//             opacity: animation,
//             child: _buildPlanCard(plan, index),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildPlanCard(AiWorkoutPlan plan, int index) {
//     // Determine the primary color based on the first focus area
//     Color cardColor = AppColors.popBlue;
//     if (plan.focusAreas.isNotEmpty) {
//       final firstFocusArea = plan.focusAreas.first.toLowerCase();
//       if (firstFocusArea.contains('bums')) {
//         cardColor = AppColors.pink;
//       } else if (firstFocusArea.contains('tums')) {
//         cardColor = AppColors.popCoral;
//       } else if (firstFocusArea.contains('full')) {
//         cardColor = AppColors.popBlue;
//       } else if (firstFocusArea.contains('cardio')) {
//         cardColor = AppColors.popGreen;
//       }
//     }

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: InkWell(
//         onTap: () => _showPlanDetails(plan),
//         borderRadius: BorderRadius.circular(16),
//         child: Hero(
//           tag: 'plan_card_${plan.id}',
//           child: Material(
//             elevation: 4,
//             shadowColor: cardColor.withOpacity(0.3),
//             borderRadius: BorderRadius.circular(16),
//             child: Container(
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(16),
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     cardColor.withOpacity(0.9),
//                     cardColor.withOpacity(0.7),
//                   ],
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Header with plan name and creation date
//                   Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 plan.name,
//                                 style: Theme.of(
//                                   context,
//                                 ).textTheme.titleLarge?.copyWith(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 'Created on ${DateFormat.yMMMMd().format(plan.createdAt)}',
//                                 style: Theme.of(
//                                   context,
//                                 ).textTheme.bodySmall?.copyWith(
//                                   color: Colors.white.withOpacity(0.8),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 6,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.15),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Text(
//                             StringExtension(plan.fitnessLevel).capitalize(),
//                             style: Theme.of(
//                               context,
//                             ).textTheme.bodySmall?.copyWith(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               // lib/features/ai_workout_planning/screens/saved_plans_screen.dart (continued)
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   // Body with plan details
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Focus areas
//                         Wrap(
//                           spacing: 8,
//                           runSpacing: 8,
//                           children:
//                               plan.focusAreas
//                                   .map(
//                                     (area) => Container(
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 12,
//                                         vertical: 6,
//                                       ),
//                                       decoration: BoxDecoration(
//                                         color: Colors.white.withOpacity(0.2),
//                                         borderRadius: BorderRadius.circular(16),
//                                       ),
//                                       child: Text(
//                                         area,
//                                         style: Theme.of(context)
//                                             .textTheme
//                                             .bodySmall
//                                             ?.copyWith(color: Colors.white),
//                                       ),
//                                     ),
//                                   )
//                                   .toList(),
//                         ),

//                         const SizedBox(height: 16),

//                         // Stats row
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceAround,
//                           children: [
//                             _buildStat(context, '${plan.durationDays}', 'Days'),
//                             _buildStat(
//                               context,
//                               '${plan.daysPerWeek}',
//                               'Days/Week',
//                             ),
//                             _buildStat(
//                               context,
//                               '${plan.workouts.length}',
//                               'Workouts',
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 16),

//                         // Start plan button
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             onPressed: () {
//                               // Handle starting the plan
//                               _startPlan(plan);
//                             },
//                             style: ElevatedButton.styleFrom(
//                               foregroundColor: cardColor,
//                               backgroundColor: Colors.white,
//                               elevation: 0,
//                               padding: const EdgeInsets.symmetric(vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                             child: Text(
//                               'Start Plan',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 color: cardColor,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStat(BuildContext context, String value, String label) {
//     return Column(
//       children: [
//         Text(
//           value,
//           style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         Text(
//           label,
//           style: Theme.of(
//             context,
//           ).textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.8)),
//         ),
//       ],
//     );
//   }

//   void _startPlan(AiWorkoutPlan plan) {
//     // Add haptic feedback
//     HapticFeedback.mediumImpact();

//     _analyticsService.logEvent(
//       name: 'start_saved_plan_button_tapped',
//       parameters: {'plan_id': plan.id},
//     );

//     // Show date picker for start date
//     showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.light(
//               primary: AppColors.pink,
//               onPrimary: Colors.white,
//               onSurface: AppColors.darkGrey,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     ).then((selectedDate) {
//       if (selectedDate != null) {
//         // Start the plan
//         ref
//             .read(aiWorkoutPlanNotifierProvider(widget.userId).notifier)
//             .startPlan(plan.id, selectedDate)
//             .then((_) {
//               // Show success message
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('Plan "${plan.name}" added to your schedule'),
//                   behavior: SnackBarBehavior.floating,
//                   action: SnackBarAction(
//                     label: 'View',
//                     onPressed: () {
//                       // Go back to the weekly planning screen
//                       Navigator.pop(context);
//                     },
//                   ),
//                 ),
//               );
//             });
//       }
//     });
//   }
// }

// // Extension to capitalize first letter
// extension StringExtension on String {
//   String capitalize() {
//     return '${this[0].toUpperCase()}${substring(1)}';
//   }
// }
