// Rename to: lib/features/workouts/widgets/execution/between_sets_timer.dart
import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import 'dart:async';

class BetweenSetsTimer extends StatefulWidget {
  final int durationSeconds;
  final bool isPaused;
  final int currentSet;
  final int totalSets;
  final VoidCallback onComplete;
  final VoidCallback onAddTime;
  final VoidCallback onReduceTime;

  const BetweenSetsTimer({
    super.key,
    required this.durationSeconds,
    required this.isPaused,
    required this.currentSet,
    required this.totalSets,
    required this.onComplete,
    required this.onAddTime,
    required this.onReduceTime,
  });

  @override
  State<BetweenSetsTimer> createState() => _BetweenSetsTimerState();
}

class _BetweenSetsTimerState extends State<BetweenSetsTimer>
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
  void didUpdateWidget(BetweenSetsTimer oldWidget) {
    super.didUpdateWidget(oldWidget);

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

    if (widget.durationSeconds != oldWidget.durationSeconds) {
      _secondsRemaining = widget.durationSeconds;
      _controller.duration = Duration(seconds: widget.durationSeconds);
      _controller.reset();
      _controller.forward();
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular progress indicator with time
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120, // Even smaller
              height: 120, // Even smaller
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CircularProgressIndicator(
                    value: 1 - _controller.value,
                    strokeWidth: 8, 
                    backgroundColor: AppColors.lightGrey,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.popBlue),
                  );
                },
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(_secondsRemaining),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'seconds',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Time adjustment buttons - more compact
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Material(
              color: AppColors.paleGrey,
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                onTap: widget.onReduceTime,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.remove, color: AppColors.popBlue, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Material(
              color: AppColors.popBlue,
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                onTap: widget.onAddTime,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    return seconds.toString();
  }
}