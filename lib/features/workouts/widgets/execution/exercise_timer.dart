// lib/features/workouts/widgets/execution/exercise_timer.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../../shared/theme/color_palette.dart';

class ExerciseTimer extends StatefulWidget {
  final int durationSeconds;
  final bool isPaused;
  final VoidCallback onComplete;

  const ExerciseTimer({
    super.key,
    required this.durationSeconds,
    required this.isPaused,
    required this.onComplete,
  });

  @override
  State<ExerciseTimer> createState() => _ExerciseTimerState();
}

class _ExerciseTimerState extends State<ExerciseTimer> {
  late int _secondsRemaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.durationSeconds;
    _startTimer();
  }

  @override
  void didUpdateWidget(ExerciseTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reset timer if duration changed
    if (oldWidget.durationSeconds != widget.durationSeconds) {
      _secondsRemaining = widget.durationSeconds;
    }
    
    // Handle pause/resume
    if (oldWidget.isPaused != widget.isPaused) {
      if (widget.isPaused) {
        _timer?.cancel();
      } else {
        _startTimer();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!widget.isPaused) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
            
            // Vibrate at specific intervals
            if (_secondsRemaining <= 3 && _secondsRemaining > 0) {
              HapticFeedback.lightImpact();
            }
          } else {
            _timer?.cancel();
            HapticFeedback.heavyImpact();
            widget.onComplete();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (_secondsRemaining / widget.durationSeconds);
    
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 10,
                backgroundColor: AppColors.paleGrey,
                color: AppColors.salmon,
              ),
            ),
            Column(
              children: [
                Text(
                  _formatTime(_secondsRemaining),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'seconds left',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    if (seconds < 60) {
      return seconds.toString();
    } else {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }
}