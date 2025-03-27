// lib/features/workouts/widgets/exercise_demo_widget.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../../../shared/services/exercise_media_service.dart';
import '../../../shared/theme/color_palette.dart';

class ExerciseDemoWidget extends StatefulWidget {
  final Exercise exercise;
  final double height;
  final double width;
  final bool showControls;
  final bool autoPlay;

  const ExerciseDemoWidget({
    super.key,
    required this.exercise,
    this.height = 200,
    this.width = double.infinity,
    this.showControls = true,
    this.autoPlay = false,
  });

  @override
  State<ExerciseDemoWidget> createState() => _ExerciseDemoWidgetState();
}

class _ExerciseDemoWidgetState extends State<ExerciseDemoWidget> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  bool _hasVideoError = false;

  @override
  void initState() {
    super.initState();
    print(
      'Initializing ExerciseDemoWidget for exercise: ${widget.exercise.name}',
    );
    _initializeVideo();
  }

  @override
  void didUpdateWidget(ExerciseDemoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      _disposeVideo();
      _initializeVideo();
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  void _disposeVideo() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
    _isPlaying = false;
  }

  Future<void> _initializeVideo() async {
    try {
      // First check if the exercise has a direct video path specified
      String videoPath;
      if (widget.exercise.videoPath != null &&
          widget.exercise.videoPath!.isNotEmpty) {
        videoPath = widget.exercise.videoPath!;
      } else {
        // Fallback to derived path only if no explicit path is provided
        final String exerciseName = widget.exercise.name
            .trim()
            .toLowerCase()
            .replaceAll(' ', '_');
        videoPath = 'assets/videos/exercises/$exerciseName.mp4';
      }

      _videoController = VideoPlayerController.asset(videoPath);
      await _videoController!.initialize();

      _videoController!.addListener(_videoListener);

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _hasVideoError = false;
        });

        // Auto-play if enabled
        if (widget.autoPlay) {
          _videoController!.play();
          _isPlaying = true;
        }
      }
    } catch (e) {
      print('Video initialization error: $e');
      if (mounted) {
        setState(() {
          _hasVideoError = true;
        });
      }
    }
  }

  void _videoListener() {
    // Update playing state
    if (mounted && _videoController != null) {
      final isPlaying = _videoController!.value.isPlaying;
      if (_isPlaying != isPlaying) {
        setState(() {
          _isPlaying = isPlaying;
        });
      }

      // Loop the video when it completes
      if (_videoController!.value.position >=
          _videoController!.value.duration) {
        _videoController!.seekTo(Duration.zero);
        _videoController!.play();
      }
    }
  }

  void _togglePlay() {
    if (_videoController == null || !_isVideoInitialized) return;

    setState(() {
      if (_isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Map exercise difficulty level to WorkoutDifficulty enum
    final WorkoutDifficulty difficulty =
        widget.exercise.difficultyLevel <= 2
            ? WorkoutDifficulty.beginner
            : (widget.exercise.difficultyLevel <= 4
                ? WorkoutDifficulty.intermediate
                : WorkoutDifficulty.advanced);

    // Display states
    final bool hasVideo = _isVideoInitialized && _videoController != null;
    final bool hasYoutubeVideo =
        widget.exercise.youtubeVideoId != null &&
        widget.exercise.youtubeVideoId!.isNotEmpty;

    // Check if we have an image path as fallback
    final bool hasImagePath =
        widget.exercise.imagePath != null &&
        widget.exercise.imagePath!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main demo container
        Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: AppColors.paleGrey,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.paleGrey, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Local video player (highest priority)
                if (hasVideo)
                  AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  )
                // Image fallback (second priority)
                else if (hasImagePath)
                  Image.asset(
                    widget.exercise.imagePath!,
                    fit: BoxFit.cover,
                    height: widget.height,
                    width: widget.width,
                  )
                // Generic fallback based on difficulty (lowest priority)
                else
                  ExerciseMediaService.workoutImage(
                    difficulty: difficulty,
                    height: widget.height,
                    width: widget.width,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(16),
                  ),

                // Video controls overlay
                if (hasVideo && widget.showControls)
                  GestureDetector(
                    onTap: _togglePlay,
                    child: Container(
                      color: Colors.transparent,
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: _isPlaying ? 0.0 : 0.7,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // YouTube video play button overlay (fallback)
                if (!hasVideo && hasYoutubeVideo && widget.showControls)
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

                // Video error overlay
                if (_hasVideoError && !hasImagePath)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Video unavailable',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
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
                      widget.exercise.name,
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

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!hasVideo && hasYoutubeVideo)
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: () => _showVideoDialog(context),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Watch Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.popBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

            if (!hasVideo && hasYoutubeVideo) const SizedBox(width: 8),

            Flexible(
              child: TextButton.icon(
                onPressed: () => _showInstructionsDialog(context),
                icon: const Icon(Icons.info_outline),
                label: const Text('View Instructions'),
                style: TextButton.styleFrom(foregroundColor: AppColors.salmon),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Show YouTube video in dialog
  void _showVideoDialog(BuildContext context) {
    // Note: In a real implementation, you would integrate YouTube player
    // For this implementation, we'll just show a placeholder
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
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
                    style: TextStyle(fontWeight: FontWeight.bold),
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
      builder:
          (context) => Dialog(
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
                    widget.exercise.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Instructions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(widget.exercise.description),
                  const SizedBox(height: 12),
                  if (widget.exercise.formTips.isNotEmpty) ...[
                    const Text(
                      'Form Tips:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    ...widget.exercise.formTips.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.popGreen,
                            ),
                            const SizedBox(width: 4),
                            Expanded(child: Text(tip)),
                          ],
                        ),
                      ),
                    ),
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
