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

    // Handle exercise change
    if (oldWidget.exercise.id != widget.exercise.id) {
      _disposeVideo();
      _initializeVideo();
    }

    // Handle autoPlay change
    if (oldWidget.autoPlay != widget.autoPlay && _videoController != null) {
      if (widget.autoPlay) {
        _videoController!.play();
        _isPlaying = true;
      } else {
        _videoController!.pause();
        _isPlaying = false;
      }
      // Refresh UI to show correct play/pause state
      setState(() {});
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

      // Set video to loop automatically
      _videoController!.setLooping(true);

      // Add listener before setting state
      _videoController!.addListener(_videoListener);

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _hasVideoError = false;
        });

        // Start playing if autoPlay is enabled
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

      // Handle video completion without stopping
      if (_videoController!.value.position >=
          _videoController!.value.duration) {
        // If autoplay is enabled, just continue looping
        if (widget.autoPlay) {
          // Video will loop automatically since we set looping to true
        } else {
          // For manual mode, pause and show play button
          setState(() {
            _isPlaying = false;
          });
          _videoController!.seekTo(Duration.zero);
        }
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final double effectiveHeight = constraints.maxHeight;
        final double effectiveWidth = constraints.maxWidth;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Local video player (highest priority)
            if (hasVideo)
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              )
            // Image fallback (second priority)
            else if (hasImagePath)
              Image.asset(
                widget.exercise.imagePath!,
                fit: BoxFit.contain,
                width: effectiveWidth,
                height: effectiveHeight,
              )
            // Generic fallback based on difficulty (lowest priority)
            else
              ExerciseMediaService.workoutImage(
                difficulty: difficulty,
                height: effectiveHeight,
                width: effectiveWidth,
                fit: BoxFit.contain,
              ),

            // Video controls overlay - only show when NOT in autoPlay mode and when controls are enabled
            if (hasVideo && widget.showControls && !widget.autoPlay)
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

            // Exercise name overlay at bottom
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
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
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
        );
      },
    );
  }

}
