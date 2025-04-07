// lib/features/workouts/widgets/execution/workout_bottom_controls.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/color_palette.dart';
import '../../models/exercise.dart';
import '../../providers/workout_execution_provider.dart';

class WorkoutBottomControls extends ConsumerWidget {
  final Exercise exercise;
  final VoidCallback onCompleteSet;
  final VoidCallback onShowInfo;
  final bool isTimeBased;
  
  const WorkoutBottomControls({
    Key? key,
    required this.exercise,
    required this.onCompleteSet,
    required this.onShowInfo,
    required this.isTimeBased,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(workoutExecutionProvider);
    final isPaused = executionState.isPaused;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // For rep-based exercises only
            if (!isTimeBased) ...[
              // Complete set button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isPaused ? null : onCompleteSet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.salmon,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    disabledBackgroundColor: AppColors.lightGrey,
                  ),
                  child: Text(
                    isTimeBased ? 'NEXT EXERCISE' : 'COMPLETE SET',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
            
            // Row of quick action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.info_outline,
                  label: 'INFO',
                  onTap: onShowInfo,
                  color: AppColors.popBlue,
                ),
                
                _buildActionButton(
                  icon: Icons.speed,
                  label: 'EASIER',
                  onTap: () => _showDifficultyDialog(context, true),
                  color: AppColors.popGreen,
                ),
                
                _buildActionButton(
                  icon: Icons.whatshot,
                  label: 'HARDER',
                  onTap: () => _showDifficultyDialog(context, false),
                  color: AppColors.popCoral,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showDifficultyDialog(BuildContext context, bool makeEasier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(makeEasier ? 'Make Exercise Easier' : 'Make Exercise Harder'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                makeEasier
                    ? 'Here are some ways to make "${exercise.name}" easier:'
                    : 'Here are some ways to make "${exercise.name}" harder:',
              ),
              const SizedBox(height: 16),
              ...(_getModificationsList(makeEasier).map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: makeEasier ? AppColors.popGreen : AppColors.popCoral,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
  
  List<String> _getModificationsList(bool makeEasier) {
    if (makeEasier) {
      // Default modifications for easier workouts if exercise doesn't provide any
      final defaultEasierMods = [
        'Reduce the weight or resistance',
        'Take longer rest periods between sets',
        'Reduce the range of motion',
        'Slow down the movement',
        'Reduce the number of repetitions',
      ];
      
      return exercise.regressionExercises.isNotEmpty
          ? exercise.regressionExercises 
          : defaultEasierMods;
    } else {
      // Default modifications for harder workouts
      final defaultHarderMods = [
        'Increase the weight or resistance',
        'Decrease rest time between sets',
        'Increase the range of motion',
        'Add a pause at the most challenging point',
        'Increase the number of repetitions',
      ];
      
      return exercise.progressionExercises.isNotEmpty
          ? exercise.progressionExercises
          : defaultHarderMods;
    }
  }
}