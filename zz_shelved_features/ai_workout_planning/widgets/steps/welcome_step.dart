// // lib/features/ai_workout_planning/widgets/steps/welcome_step.dart
// import 'package:flutter/material.dart';
// import '../../../../../shared/theme/color_palette.dart';

// class PlanWelcomeStep extends StatelessWidget {
//   final VoidCallback onGetStarted;

//   const PlanWelcomeStep({
//     Key? key,
//     required this.onGetStarted,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Container(
//           width: 120,
//           height: 120,
//           decoration: BoxDecoration(
//             color: AppColors.pink.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(60),
//           ),
//           child: Icon(
//             Icons.calendar_month_rounded,
//             size: 60,
//             color: AppColors.pink,
//           ),
//         ),
//         const SizedBox(height: 32),
//         Text(
//           'Create Your Workout Plan',
//           style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//             fontWeight: FontWeight.bold,
//             color: AppColors.darkGrey,
//           ),
//           textAlign: TextAlign.center,
//         ),
//         const SizedBox(height: 16),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0),
//           child: Text(
//             'Let AI create a personalized workout plan tailored to your goals, preferences, and schedule.',
//             style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//               color: AppColors.mediumGrey,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ),
//         const SizedBox(height: 40),
//         SizedBox(
//           width: 200,
//           child: ElevatedButton(
//             onPressed: onGetStarted,
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 16.0),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(30),
//               ),
//             ),
//             child: const Text(
//               'GET STARTED',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextButton(
//           onPressed: () {
//             // Show info about AI planning
//             showDialog(
//               context: context,
//               builder: (context) => AlertDialog(
//                 title: const Text('About AI Workout Planning'),
//                 content: const SingleChildScrollView(
//                   child: Text(
//                     'This feature creates balanced, personalized workout plans for your week. '
//                     'The AI considers your fitness level, goals, and preferences to design '
//                     'a plan that optimizes results while preventing overtraining.\n\n'
//                     'You can refine your plan after it\'s created to make it perfect for you.'
//                   ),
//                 ),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text('CLOSE'),
//                   ),
//                 ],
//               ),
//             );
//           },
//           child: const Text('Learn More'),
//         ),
//       ],
//     );
//   }
// }