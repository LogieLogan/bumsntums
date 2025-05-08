// lib/features/workouts/screens/workout_log_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

import '../models/workout.dart'; // For workout context (optional but helpful)
import '../models/workout_log.dart'; // The core data model
import '../../../shared/theme/app_colors.dart'; // For styling

class WorkoutLogDetailScreen extends StatelessWidget {
  final WorkoutLog workoutLog;
  final Workout? workoutContext; // Optional: For displaying title/description

  const WorkoutLogDetailScreen({
    super.key,
    required this.workoutLog,
    this.workoutContext, // Make context optional
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm(); // e.g., Jul 15, 2024, 10:30 AM
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(workoutContext?.title ?? workoutLog.workoutName ?? 'Workout Log'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Text(
              workoutContext?.title ?? workoutLog.workoutName ?? 'Workout Details',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (workoutContext?.description != null && workoutContext!.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
                child: Text(workoutContext!.description, style: theme.textTheme.bodyMedium),
              ),
            Divider(height: 20, thickness: 1),

            // --- Key Stats ---
             _buildStatRow(
               icon: Icons.calendar_today,
               label: 'Completed',
               value: dateFormat.format(workoutLog.completedAt),
               iconColor: AppColors.popBlue,
             ),
             _buildStatRow(
               icon: Icons.timer,
               label: 'Duration',
               value: '${workoutLog.durationMinutes} min',
               iconColor: AppColors.popGreen,
             ),
             _buildStatRow(
               icon: Icons.local_fire_department,
               label: 'Calories Burned',
               value: '${workoutLog.caloriesBurned} kcal', // Assuming kcal
               iconColor: AppColors.popCoral,
             ),
            // Add more stats if available/needed (e.g., average heart rate if logged)
            const SizedBox(height: 24),

             // --- User Feedback (If available) ---
             if (workoutLog.userFeedback.rating > 0 || workoutLog.userFeedback.comments != null) ...[
                Text('Your Feedback', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) => Icon(
                      index < workoutLog.userFeedback.rating ? Icons.star : Icons.star_border,
                      color: AppColors.popYellow,
                      size: 24,
                  )),
                ),
                 if (workoutLog.userFeedback.feltEasy)
                   const Padding(padding: EdgeInsets.only(top: 4), child: Text("Felt: Too Easy")),
                 if (workoutLog.userFeedback.feltTooHard)
                    const Padding(padding: EdgeInsets.only(top: 4), child: Text("Felt: Too Hard")),
                 if (workoutLog.userFeedback.comments != null && workoutLog.userFeedback.comments!.isNotEmpty)
                   Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: Text('Comment: ${workoutLog.userFeedback.comments}', style: theme.textTheme.bodySmall),
                   ),
                 const SizedBox(height: 24),
             ],

             // --- Completed Exercises (Placeholder/Optional) ---
             // This requires WorkoutLog.exercisesCompleted to be populated correctly.
             // If it's usually empty, you might hide this section.
             if (workoutLog.exercisesCompleted.isNotEmpty) ...[
                Text('Exercises Logged', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: workoutLog.exercisesCompleted.length,
                    itemBuilder: (context, index) {
                        final exLog = workoutLog.exercisesCompleted[index];
                        // Display basic info from ExerciseLog
                        return ListTile(
                           // dense: true, // Make items smaller
                           leading: const Icon(Icons.fitness_center, color: AppColors.mediumGrey),
                           title: Text(exLog.exerciseName),
                           subtitle: Text(
                              // Build a summary string based on logged data
                              _buildExerciseLogSummary(exLog)
                           ),
                        );
                    },
                 ),
                const SizedBox(height: 24),
             ],


            // --- Action Buttons (Placeholders) ---
            Text('Actions', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap( // Use Wrap for buttons that might overflow
              spacing: 10.0,
              runSpacing: 10.0,
              children: [
                 ElevatedButton.icon(
                    icon: const Icon(Icons.replay),
                    label: const Text('Do Again'),
                    onPressed: () {
                       // TODO: Implement navigation to PreWorkoutSetupScreen
                       print("Do Again tapped for workout: ${workoutLog.workoutId}");
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Do Again - Not implemented yet')));
                    },
                 ),
                 ElevatedButton.icon(
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Save as Template'),
                    onPressed: () {
                      // TODO: Implement saving logic (using CustomWorkoutRepository)
                      print("Save as Template tapped for workout: ${workoutLog.workoutId}");
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save as Template - Not implemented yet')));
                    },
                 ),
                ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    onPressed: () {
                      // TODO: Implement sharing logic
                       print("Share tapped for workout log: ${workoutLog.id}");
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share - Not implemented yet')));
                    },
                 ),
                // Optionally add Delete Log button here later
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({required IconData icon, required String label, required String value, Color? iconColor}) {
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 6.0),
       child: Row(
         children: [
           Icon(icon, size: 20, color: iconColor ?? AppColors.mediumGrey),
           const SizedBox(width: 12),
           Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
           const SizedBox(width: 8),
           Expanded(child: Text(value, textAlign: TextAlign.end)),
         ],
       ),
     );
  }

   String _buildExerciseLogSummary(ExerciseLog exLog) {
     List<String> parts = [];
     if (exLog.setsCompleted > 0) parts.add('${exLog.setsCompleted} sets');
     // Add details based on what's available (reps, weight, duration)
     // Example: if reps exist for first set: parts.add('${exLog.repsCompleted[0]} reps');
     // This needs more logic based on how ExerciseLog is populated
     return parts.join(' | '); // Simple join for now
   }
}