// lib/features/workouts/widgets/execution/exercise_timer.dart (updated)
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

class _ExerciseTimerState extends State<ExerciseTimer>
    with SingleTickerProviderStateMixin {
  late int _secondsRemaining;
  Timer? _timer;
  late AnimationController _controller;

  final List<String> _messages = [
    'Keep going!',
    'You\'ve got this!',
    'Stay strong!',
    'Almost there!',
    'Final push!',
  ];

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.durationSeconds;

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    );

    if (!widget.isPaused) {
      _controller.forward();
    }

    _startTimer();
  }

  @override
  void didUpdateWidget(ExerciseTimer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle duration changes
    if (oldWidget.durationSeconds != widget.durationSeconds) {
      _secondsRemaining = widget.durationSeconds;
      _controller.duration = Duration(seconds: widget.durationSeconds);
      _controller.reset();
      if (!widget.isPaused) {
        _controller.forward();
      }
    }

    // Handle pause/resume
    if (oldWidget.isPaused != widget.isPaused) {
      if (widget.isPaused) {
        _timer?.cancel();
        _controller.stop();
      } else {
        _startTimer();
        final progress = 1.0 - (_secondsRemaining / widget.durationSeconds);
        _controller.forward(from: progress);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!widget.isPaused && mounted) {
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

  Color _getTimerColor() {
    final progress = _secondsRemaining / widget.durationSeconds;

    if (progress <= 0.3) {
      return AppColors.popCoral;
    } else if (progress <= 0.6) {
      return AppColors.popYellow;
    } else {
      return AppColors.salmon;
    }
  }

  String _getMotivationalMessage() {
    final progress = _secondsRemaining / widget.durationSeconds;

    if (_secondsRemaining <= 3) {
      return 'Almost done!';
    } else if (progress <= 0.2) {
      return _messages[4];
    } else if (progress <= 0.4) {
      return _messages[3];
    } else if (progress <= 0.6) {
      return _messages[2];
    } else if (progress <= 0.8) {
      return _messages[1];
    } else {
      return _messages[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Use padding instead of fixed height
      padding: const EdgeInsets.only(bottom: 10),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final progress = 1.0 - _controller.value;

            return Column(
              mainAxisSize:
                  MainAxisSize
                      .min, // This ensures the column takes minimum space
              children: [
                // Timer circle
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.paleGrey,
                        shape: BoxShape.circle,
                      ),
                    ),

                    // Progress circle
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: Colors.transparent,
                        color: _getTimerColor(),
                      ),
                    ),

                    // Time text
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Seconds count
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: _secondsRemaining <= 3 ? 38 : 34,
                            fontWeight: FontWeight.bold,
                            color:
                                _secondsRemaining <= 3
                                    ? AppColors.popCoral
                                    : AppColors.darkGrey,
                          ),
                          child: Text('$_secondsRemaining'),
                        ),

                        // "seconds left" text
                        Text(
                          'seconds left',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mediumGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8), // Reduced space
                // Motivational message - make this widget smaller
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 20,
                  ), // Constrain height
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _getMotivationalMessage(),
                      key: ValueKey<String>(_getMotivationalMessage()),
                      style: TextStyle(
                        fontSize: 14, // Slightly smaller font
                        fontWeight: FontWeight.bold,
                        color: AppColors.popBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
