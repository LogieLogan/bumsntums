// lib/features/workouts/widgets/execution/rest_timer.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../../shared/theme/app_colors.dart';

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
            print("RestTimer: Rest period complete. Calling onComplete...");
            _timer.cancel();
            // Add a small delay before calling onComplete to ensure state transitions properly
            Future.delayed(Duration(milliseconds: 50), () {
              if (mounted) {
                widget.onComplete();
                print("RestTimer: onComplete callback executed");
              }
            });
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Rest',
            style: TextStyle(
              fontSize: 24,
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
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.paleGrey,
                  shape: BoxShape.circle,
                ),
              ),

              SizedBox(
                width: 220,
                height: 220,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      value: 1 - _controller.value,
                      strokeWidth: 15,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.popBlue,
                      ),
                    );
                  },
                ),
              ),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _secondsRemaining.toString(),
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  Text(
                    'seconds',
                    style: TextStyle(fontSize: 16, color: AppColors.mediumGrey),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Time adjustment buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: widget.onReduceTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.popBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.remove, color: AppColors.popBlue, size: 24),
                ),
              ),
              const SizedBox(width: 32),
              GestureDetector(
                onTap: widget.onAddTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.popBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
