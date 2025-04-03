// // lib/features/ai_workout_planning/widgets/steps/focus_variation_step.dart
// import 'package:flutter/material.dart';
// import '../../../../../shared/theme/color_palette.dart';

// class FocusVariationStep extends StatelessWidget {
//   final List<String> selectedFocusAreas;
//   final String selectedVariationType;
//   final Function(List<String>) onFocusAreasChanged;
//   final Function(String) onVariationTypeChanged;
//   final VoidCallback onContinue;
//   final VoidCallback onBack;

//   const FocusVariationStep({
//     Key? key,
//     required this.selectedFocusAreas,
//     required this.selectedVariationType,
//     required this.onFocusAreasChanged,
//     required this.onVariationTypeChanged,
//     required this.onContinue,
//     required this.onBack,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Plan Focus & Structure',
//           style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           'Choose what areas you want to focus on and how to structure your workouts.',
//           style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//             color: AppColors.mediumGrey,
//           ),
//         ),
//         const SizedBox(height: 32),
        
//         // Focus areas selection
//         Text(
//           'Focus Areas',
//           style: Theme.of(context).textTheme.titleMedium?.copyWith(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           'Select one or more areas to focus on',
//           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//             color: AppColors.mediumGrey,
//           ),
//         ),
//         const SizedBox(height: 12),
//         _buildFocusAreaSelector(context),
//         const SizedBox(height: 32),
        
//         // Variation type selection
//         Text(
//           'Plan Structure',
//           style: Theme.of(context).textTheme.titleMedium?.copyWith(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           'Choose how to structure your workout plan',
//           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//             color: AppColors.mediumGrey,
//           ),
//         ),
//         const SizedBox(height: 12),
//         _buildVariationTypeSelector(context),
//         const SizedBox(height: 32),
        
//         // Navigation buttons
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             OutlinedButton(
//               onPressed: onBack,
//               style: OutlinedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 24,
//                   vertical: 12,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//               ),
//               child: const Text('BACK'),
//             ),
//             ElevatedButton(
//               onPressed: onContinue,
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 24,
//                   vertical: 12,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//               ),
//               child: const Text('CONTINUE'),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildFocusAreaSelector(BuildContext context) {
//     final focusAreas = [
//       {'name': 'Full Body', 'icon': Icons.accessibility_new},
//       {'name': 'Bums', 'icon': Icons.fitness_center},
//       {'name': 'Tums', 'icon': Icons.accessibility},
//       {'name': 'Arms', 'icon': Icons.fitness_center},
//       {'name': 'Legs', 'icon': Icons.directions_walk},
//       {'name': 'Cardio', 'icon': Icons.directions_run},
//     ];

//     return Wrap(
//       spacing: 12,
//       runSpacing: 12,
//       children: focusAreas.map((area) {
//         final isSelected = selectedFocusAreas.contains(area['name']);
//         return FilterChip(
//           label: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 area['icon'] as IconData,
//                 size: 16,
//                 color: isSelected ? Colors.white : AppColors.darkGrey,
//               ),
//               const SizedBox(width: 4),
//               Text(area['name'] as String),
//             ],
//           ),
//           selected: isSelected,
//           onSelected: (selected) {
//             List<String> newSelection = List.from(selectedFocusAreas);
            
//             if (selected) {
//               if (!newSelection.contains(area['name'])) {
//                 newSelection.add(area['name'] as String);
//               }
//             } else {
//               if (newSelection.length > 1) {
//                 // Don't allow removing the last focus area
//                 newSelection.remove(area['name']);
//               }
//             }
            
//             onFocusAreasChanged(newSelection);
//           },
//           backgroundColor: Colors.white,
//           selectedColor: AppColors.pink,
//           checkmarkColor: Colors.white,
//           labelStyle: TextStyle(
//             color: isSelected ? Colors.white : AppColors.darkGrey,
//           ),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildVariationTypeSelector(BuildContext context) {
//     final variationTypes = [
//       {
//         'id': 'balanced',
//         'name': 'Balanced Mix',
//         'description': 'Even mix of workout types throughout the week',
//         'icon': Icons.balance,
//       },
//       {
//         'id': 'progressive',
//         'name': 'Progressive',
//         'description': 'Gradually increasing intensity throughout the week',
//         'icon': Icons.trending_up,
//       },
//       {
//         'id': 'alternating',
//         'name': 'Alternating',
//         'description': 'Alternating between harder and easier workouts',
//         'icon': Icons.swap_vert,
//       },
//       {
//         'id': 'focused',
//         'name': 'Targeted Focus',
//         'description': 'Prioritize specific body areas with specialized workouts',
//         'icon': Icons.center_focus_strong,
//       },
//     ];

//     return Column(
//       children: variationTypes.map((type) {
//         final isSelected = selectedVariationType == type['id'];
//         return Card(
//           elevation: isSelected ? 4 : 1,
//           margin: const EdgeInsets.only(bottom: 12),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//             side: BorderSide(
//               color: isSelected ? AppColors.pink : Colors.transparent,
//               width: 2,
//             ),
//           ),
//           child: InkWell(
//             onTap: () => onVariationTypeChanged(type['id'] as String),
//             borderRadius: BorderRadius.circular(12),
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Row(
//                 children: [
//                   Container(
//                     width: 48,
//                     height: 48,
//                     decoration: BoxDecoration(
//                       color: isSelected ? AppColors.pink : AppColors.pink.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Icon(
//                       type['icon'] as IconData,
//                       color: isSelected ? Colors.white : AppColors.pink,
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           type['name'] as String,
//                           style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           type['description'] as String,
//                           style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                             color: AppColors.mediumGrey,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   if (isSelected)
//                     Icon(Icons.check_circle, color: AppColors.pink)
//                   else
//                     Icon(Icons.circle_outlined, color: AppColors.lightGrey),
//                 ],
//               ),
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }
// }