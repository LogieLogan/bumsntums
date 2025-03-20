// lib/features/workouts/widgets/execution/rest_timer.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../../shared/theme/color_palette.dart';

class RestTimer extends StatefulWidget {
  final int durationSeconds;
  final bool isPaused;
  final VoidCallback onComplete;
  final String nextExerciseName;

  const RestTimer({
    super.key,
    required this.durationSeconds,
    required this.isPaused,
    required this.onComplete,
    required this.nextExerciseName,
  });

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer> with SingleTickerProviderStateMixin {
  late int _secondsRemaining;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.durationSeconds;
    
    // Setup animation controller for breathing animation
    _animationController = AnimationController(
      duration: const Duration(seconds: 4), 
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.repeat(reverse: true);
    _startTimer();
  }

  @override
  void didUpdateWidget(RestTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.isPaused != widget.isPaused) {
      if (widget.isPaused) {
        _timer?.cancel();
        _animationController.stop();
      } else {
        _startTimer();
        _animationController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!widget.isPaused) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
            
            // Haptic feedback for last 3 seconds
            if (_secondsRemaining <= 3 && _secondsRemaining > 0) {
              HapticFeedback.lightImpact();
            }
          } else {
            _timer?.cancel();
            HapticFeedback.mediumImpact();
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
        Text(
          'REST',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.popBlue,
          ),
        ),
        const SizedBox(height: 16),
        
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: AppColors.paleGrey,
                      color: AppColors.popBlue,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        _secondsRemaining.toString(),
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.popBlue,
                        ),
                      ),
                      Text(
                        'seconds',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mediumGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        ),
        
        const SizedBox(height: 24),
        
        // Next exercise preview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.paleGrey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'COMING UP NEXT',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.mediumGrey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.nextExerciseName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Get ready!',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Skip rest button
        TextButton.icon(
          onPressed: widget.onComplete,
          icon: const Icon(Icons.skip_next),
          label: const Text('SKIP REST'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.popBlue,
          ),
        ),
      ],
    );
  }
}