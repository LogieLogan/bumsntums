// // lib/features/workout_analytics/widgets/achievements_section.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../models/workout_achievement.dart';
// import '../../../shared/theme/color_palette.dart';
// import '../../../shared/theme/text_styles.dart';

// class AchievementsSection extends ConsumerWidget {
//   final String userId;
  
//   const AchievementsSection({
//     Key? key,
//     required this.userId,
//   }) : super(key: key);
  
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final achievementsAsync = ref.watch(userAchievementsProvider(userId));
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(Icons.emoji_events, color: AppColors.popYellow, size: 24),
//             const SizedBox(width: 8),
//             Text(
//               'Achievements',
//               style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),
//         achievementsAsync.when(
//           data: (achievements) {
//             if (achievements.isEmpty) {
//               return _buildEmptyAchievements();
//             }
//             return _buildAchievementsList(achievements, context, ref);
//           },
//           loading: () => const Center(
//             child: Padding(
//               padding: EdgeInsets.all(16.0),
//               child: CircularProgressIndicator(),
//             ),
//           ),
//           error: (error, _) => Center(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Text(
//                 'Failed to load achievements: $error',
//                 style: AppTextStyles.body.copyWith(color: AppColors.error),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
  
//   Widget _buildEmptyAchievements() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Icon(Icons.emoji_events_outlined, size: 48, color: AppColors.lightGrey),
//           const SizedBox(height: 16),
//           Text(
//             'No achievements yet',
//             style: AppTextStyles.body.copyWith(
//               fontWeight: FontWeight.bold,
//               color: AppColors.darkGrey,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Keep working out to unlock achievements!',
//             style: AppTextStyles.small.copyWith(
//               color: AppColors.mediumGrey,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
  
//   Widget _buildAchievementsList(List<WorkoutAchievement> achievements, BuildContext context, WidgetRef ref) {
//     // Sort achievements: unlocked first (by date), then by progress
//     achievements.sort((a, b) {
//       if (a.isUnlocked && b.isUnlocked) {
//         return b.unlockedAt!.compareTo(a.unlockedAt!); // Most recent first
//       } else if (a.isUnlocked) {
//         return -1; // a comes first
//       } else if (b.isUnlocked) {
//         return 1; // b comes first
//       } else {
//         return b.progress.compareTo(a.progress); // Higher progress first
//       }
//     });
    
//     // Group by category
//     final Map<String, List<WorkoutAchievement>> categorizedAchievements = {};
//     for (final achievement in achievements) {
//       if (!categorizedAchievements.containsKey(achievement.category)) {
//         categorizedAchievements[achievement.category] = [];
//       }
//       categorizedAchievements[achievement.category]!.add(achievement);
//     }
    
//     // First show a grid of the most recent unlocked achievements
//     final unlockedAchievements = achievements.where((a) => a.isUnlocked).take(4).toList();
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (unlockedAchievements.isNotEmpty) ...[
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 10,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Recent Achievements',
//                   style: AppTextStyles.body.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.darkGrey,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 GridView.builder(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 2,
//                     childAspectRatio: 1.5,
//                     crossAxisSpacing: 8,
//                     mainAxisSpacing: 8,
//                   ),
//                   itemCount: unlockedAchievements.length,
//                   itemBuilder: (context, index) {
//                     final achievement = unlockedAchievements[index];
//                     return _buildAchievementCard(achievement);
//                   },
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//         ],
        
//         // Then show all achievements by category
//         ...categorizedAchievements.entries.map((entry) {
//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 8.0),
//                 child: Text(
//                   entry.key,
//                   style: AppTextStyles.body.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.darkGrey,
//                   ),
//                 ),
//               ),
//               ...entry.value.map((achievement) {
//                 return Padding(
//                   padding: const EdgeInsets.only(bottom: 8.0),
//                   child: _buildAchievementListItem(achievement),
//                 );
//               }).toList(),
//               const SizedBox(height: 8),
//             ],
//           );
//         }).toList(),
//       ],
//     );
//   }
  
//   Widget _buildAchievementCard(WorkoutAchievement achievement) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: achievement.tierColor.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: achievement.tierColor.withOpacity(0.5),
//           width: 1.5,
//         ),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             achievement.icon,
//             color: achievement.tierColor,
//             size: 24,
//           ),
//           const SizedBox(height: 4),
//           Text(
//             achievement.title,
//             style: AppTextStyles.small.copyWith(
//               fontWeight: FontWeight.bold,
//               color: AppColors.darkGrey,
//             ),
//             textAlign: TextAlign.center,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//           Text(
//             achievement.tierName,
//             style: AppTextStyles.caption.copyWith(
//               color: achievement.tierColor,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
  
//   Widget _buildAchievementListItem(WorkoutAchievement achievement) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.03),
//             blurRadius: 5,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: achievement.tierColor.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               achievement.icon,
//               color: achievement.tierColor,
//               size: 24,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         achievement.title,
//                         style: AppTextStyles.body.copyWith(
//                           fontWeight: FontWeight.bold,
//                           color: AppColors.darkGrey,
//                         ),
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                       decoration: BoxDecoration(
//                         color: achievement.tierColor.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         achievement.tierName,
//                         style: AppTextStyles.caption.copyWith(
//                           color: achievement.tierColor,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   achievement.description,
//                   style: AppTextStyles.small.copyWith(
//                     color: AppColors.mediumGrey,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Stack(
//                   children: [
//                     Container(
//                       height: 6,
//                       decoration: BoxDecoration(
//                         color: AppColors.paleGrey,
//                         borderRadius: BorderRadius.circular(3),
//                       ),
//                     ),
//                     FractionallySizedBox(
//                       widthFactor: achievement.progress.clamp(0.0, 1.0),
//                       child: Container(
//                         height: 6,
//                         decoration: BoxDecoration(
//                           color: achievement.isUnlocked
//                               ? achievement.tierColor
//                               : achievement.tierColor.withOpacity(0.5),
//                           borderRadius: BorderRadius.circular(3),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       '${achievement.currentValue}/${achievement.targetValue}',
//                       style: AppTextStyles.caption.copyWith(
//                         color: AppColors.mediumGrey,
//                       ),
//                     ),
//                     if (achievement.isUnlocked)
//                       Text(
//                         'Unlocked',
//                         style: AppTextStyles.caption.copyWith(
//                           color: achievement.tierColor,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }