// lib/features/workouts/widgets/execution/rest_timer.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../../shared/theme/color_palette.dart';

// In rest_timer.dart
class RestTimer extends StatefulWidget {
  final int durationSeconds;
  final bool isPaused;
  final String nextExerciseName;
  final VoidCallback onComplete;
  final VoidCallback onAddTime;
  final VoidCallback onReduceTime;

  const RestTimer({
    Key? key,
    required this.durationSeconds,
    required this.isPaused,
    required this.nextExerciseName,
    required this.onComplete,
    required this.onAddTime,
    required this.onReduceTime,
  }) : super(key: key);

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Timer _timer;
  late int _secondsRemaining;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.durationSeconds;

    // Initialize animation controller for the progress indicator
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    );

    _controller.forward();
    _startTimer();
  }

  @override
  void didUpdateWidget(RestTimer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the duration has changed, update the seconds remaining
    if (widget.durationSeconds != oldWidget.durationSeconds) {
      print(
        "RestTimer: Duration updated from ${oldWidget.durationSeconds} to ${widget.durationSeconds}",
      );
      setState(() {
        _secondsRemaining = widget.durationSeconds;
      });

      // Reset the animation controller with the new duration
      _controller.duration = Duration(seconds: widget.durationSeconds);
      _controller.reset();
      if (!widget.isPaused) {
        _controller.forward();
      }
    }

    // Handle pausing/resuming
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _timer.cancel();
        _controller.stop();
      } else {
        _startTimer();
        _controller.forward(
          from: 1 - (_secondsRemaining / widget.durationSeconds),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!widget.isPaused) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _timer.cancel();
            widget.onComplete();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.paleGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Rest',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.popBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Circular progress indicator
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      value: 1 - _controller.value,
                      strokeWidth: 12,
                      backgroundColor: AppColors.lightGrey,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.salmon,
                      ),
                    );
                  },
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(_secondsRemaining),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('seconds', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Time adjustment buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  print("Pressed reduce time button");
                  widget.onReduceTime();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.popBlue.withOpacity(0.8),
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Icon(Icons.remove, color: Colors.white),
              ),
              const SizedBox(width: 24),
              ElevatedButton(
                onPressed: () {
                  print("Pressed add time button");
                  widget.onAddTime();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.popBlue,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            'Coming up: ${widget.nextExerciseName}',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Skip button
          ElevatedButton(
            onPressed: widget.onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.popBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Skip Rest'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    return seconds.toString();
  }
}
