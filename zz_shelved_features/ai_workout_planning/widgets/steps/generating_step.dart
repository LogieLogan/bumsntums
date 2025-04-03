// // lib/features/ai_workout_planning/widgets/steps/generating_step.dart
// import 'package:flutter/material.dart';
// import 'dart:math' as math;
// import '../../../../../shared/theme/color_palette.dart';

// class PlanGeneratingStep extends StatefulWidget {
//   const PlanGeneratingStep({Key? key}) : super(key: key);

//   @override
//   State<PlanGeneratingStep> createState() => _PlanGeneratingStepState();
// }

// class _PlanGeneratingStepState extends State<PlanGeneratingStep>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
  
//   final List<String> _loadingMessages = [
//     "Creating your personalized workout plan...",
//     "Optimizing workout sequence for maximum results...",
//     "Balancing intensity and recovery periods...",
//     "Scheduling workouts for your preferences...",
//     "Analyzing optimal exercise combinations...",
//     "Crafting a progressive training experience...",
//     "Tailoring workouts to your specific goals...",
//   ];
  
//   int _currentMessageIndex = 0;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1500),
//     )..repeat();
    
//     // Change message every 3 seconds
//     _startMessageCycling();
//   }

//   void _startMessageCycling() {
//     Future.delayed(const Duration(seconds: 3), () {
//       if (mounted) {
//         setState(() {
//           _currentMessageIndex = (_currentMessageIndex + 1) % _loadingMessages.length;
//         });
//         _startMessageCycling();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           SizedBox(
//             width: 120,
//             height: 120,
//             child: CustomPaint(
//               painter: LoadingPainter(_controller),
//               child: Center(
//                 child: Icon(
//                   Icons.calendar_month,
//                   size: 40,
//                   color: AppColors.pink,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 40),
//           Text(
//             "Creating Your Workout Plan",
//             style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           AnimatedSwitcher(
//             duration: const Duration(milliseconds: 500),
//             child: Text(
//               _loadingMessages[_currentMessageIndex],
//               key: ValueKey<int>(_currentMessageIndex),
//               style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                 color: AppColors.mediumGrey,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class LoadingPainter extends CustomPainter {
//   final Animation<double> animation;

//   LoadingPainter(this.animation) : super(repaint: animation);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2);
//     final radius = size.width / 2;
    
//     // Draw outer circle
//     final outerPaint = Paint()
//       ..color = AppColors.pink.withOpacity(0.1)
//       ..style = PaintingStyle.fill;
//     canvas.drawCircle(center, radius, outerPaint);
    
//     // Draw animated arc
//     final arcPaint = Paint()
//       ..color = AppColors.pink
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 4
//       ..strokeCap = StrokeCap.round;
    
//     final startAngle = -math.pi / 2;
//     final sweepAngle = 2 * math.pi * animation.value;
    
//     canvas.drawArc(
//       Rect.fromCircle(center: center, radius: radius - 2),
//       startAngle,
//       sweepAngle,
//       false,
//       arcPaint,
//     );
    
//     // Draw small circles around the arc
//     final smallCirclePaint = Paint()
//       ..color = AppColors.pink
//       ..style = PaintingStyle.fill;
    
//     const smallCircleCount = 5;
//     for (int i = 0; i < smallCircleCount; i++) {
//       final angle = startAngle + (sweepAngle * i / (smallCircleCount - 1));
//       if (angle <= startAngle + sweepAngle) {
//         final x = center.dx + (radius - 2) * math.cos(angle);
//         final y = center.dy + (radius - 2) * math.sin(angle);
//         canvas.drawCircle(Offset(x, y), 3, smallCirclePaint);
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(covariant LoadingPainter oldDelegate) => true;
// }