// lib/features/workouts/widgets/exercise_demo_widget.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/exercise.dart';
import '../../../shared/services/exercise_media_service.dart';
import '../../../shared/theme/color_palette.dart';

class ExerciseDemoWidget extends StatelessWidget {
  final Exercise exercise;
  final double height;
  final double width;
  final bool showControls;
  
  const ExerciseDemoWidget({
    super.key,
    required this.exercise,
    this.height = 200,
    this.width = double.infinity,
    this.showControls = true,
  });
  
  @override
  Widget build(BuildContext context) {
    // Get the best demo image URL for this exercise (preferring animated GIFs)
    final String demoUrl = ExerciseMediaService.getBestExerciseMedia(
      exercise.imageUrl,
      type: MediaType.demo,
    );
    
    // Check if we have a YouTube video ID for this exercise
    final bool hasVideo = exercise.youtubeVideoId != null && 
                         exercise.youtubeVideoId!.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main demo container
        Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: AppColors.paleGrey,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.paleGrey,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Demo image (animated GIF if available)
                CachedNetworkImage(
                  imageUrl: demoUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.salmon,
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    // Fallback to static image if GIF fails
                    return CachedNetworkImage(
                      imageUrl: ExerciseMediaService.getBestExerciseMedia(
                        exercise.imageUrl,
                        type: MediaType.photo,
                      ),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.salmon,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.fitness_center,
                          size: 48,
                          color: AppColors.salmon,
                        ),
                      ),
                    );
                  },
                ),
                
                // Video play button overlay (if YouTube video available)
                if (hasVideo && showControls)
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Launch YouTube video in dialog
                          _showVideoDialog(context);
                        },
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                // Exercise name overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      exercise.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Controls row (if showing controls)
        if (showControls) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasVideo)
                ElevatedButton.icon(
                  onPressed: () => _showVideoDialog(context),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Watch Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.popBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
                
              if (hasVideo)
                const SizedBox(width: 8),
                
              // Instructions button
              TextButton.icon(
                onPressed: () => _showInstructionsDialog(context),
                icon: const Icon(Icons.info_outline),
                label: const Text('View Instructions'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.salmon,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  // Show YouTube video in dialog
  void _showVideoDialog(BuildContext context) {
    // Note: In a real implementation, you would integrate YouTube player
    // For this implementation, we'll just show a placeholder
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'YouTube player would be integrated here',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Show exercise instructions dialog
  void _showInstructionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Instructions:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(exercise.description),
              const SizedBox(height: 12),
              if (exercise.formTips.isNotEmpty) ...[
                const Text(
                  'Form Tips:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ...exercise.formTips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check, size: 16, color: AppColors.popGreen),
                      const SizedBox(width: 4),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                )),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}