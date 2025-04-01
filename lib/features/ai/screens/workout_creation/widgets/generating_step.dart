// lib/features/ai/screens/workout_creation/widgets/generating_step.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../../shared/theme/color_palette.dart';
import '../../../../../shared/theme/text_styles.dart';
import '../../../../../features/workouts/models/workout.dart';

class GeneratingStep extends StatefulWidget {
  final WorkoutCategory selectedCategory;

  const GeneratingStep({
    Key? key,
    required this.selectedCategory,
  }) : super(key: key);

  @override
  State<GeneratingStep> createState() => _GeneratingStepState();
}

class _GeneratingStepState extends State<GeneratingStep> with TickerProviderStateMixin {
  late AnimationController _brainController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _textController;
  
  late Animation<double> _brainRotation;
  late Animation<double> _brainScale;
  late Animation<double> _pulseAnimation;
  
  final List<String> _generationMessages = [
    'Analyzing your preferences...',
    'Designing your workout flow...',
    'Selecting optimal exercises...',
    'Structuring rest periods...',
    'Fine-tuning difficulty level...',
    'Creating personalized routine...',
    'Almost there...'
  ];
  
  int _currentMessageIndex = 0;
  final List<_ParticleData> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    // Setup brain animation (rotation and bouncing)
    _brainController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    
    _brainRotation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _brainController,
      curve: Curves.easeInOut,
    ));
    
    _brainScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.08), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.08, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _brainController,
      curve: Curves.easeInOut,
    ));
    
    // Pulse animation for the outer rings
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut)
    );
    
    // Particle animation controller
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );
    
    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Create initial particles
    _createParticles();
    
    // Start animations
    _brainController.repeat(reverse: true);
    _pulseController.repeat();
    _particleController.repeat();
    
    // Schedule message changes
    _scheduleNextMessage();
  }
  
  void _createParticles() {
    _particles.clear();
    
    // Get the appropriate icon for the category
    IconData categoryIcon = _getCategoryIcon(widget.selectedCategory);
    
    // Create a mix of dots and icons
    for (int i = 0; i < 20; i++) {
      _particles.add(_ParticleData(
        // Random angle around the circle
        angle: _random.nextDouble() * 2 * pi,
        // Random radius
        radius: _random.nextDouble() * 100 + 50,
        // Random size
        size: _random.nextDouble() * 12 + 4,
        // Random speed
        speed: _random.nextDouble() * 0.8 + 0.2,
        // Color
        color: i % 5 == 0 
            ? AppColors.salmon 
            : i % 3 == 0 
                ? AppColors.popBlue 
                : AppColors.popTurquoise,
        // Some particles are icons, others are dots
        isIcon: i % 5 == 0,
        icon: categoryIcon,
      ));
    }
  }
  
  void _scheduleNextMessage() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _textController.forward(from: 0.0).then((_) {
          setState(() {
            _currentMessageIndex = (_currentMessageIndex + 1) % _generationMessages.length;
          });
          _scheduleNextMessage();
        });
      }
    });
  }

  @override
  void dispose() {
    _brainController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.bums:
        return Icons.fitness_center;
      case WorkoutCategory.tums:
        return Icons.accessibility_new;
      case WorkoutCategory.fullBody:
        return Icons.sports_gymnastics;
      case WorkoutCategory.cardio:
        return Icons.directions_run;
      case WorkoutCategory.quickWorkout:
        return Icons.timer;
    }
  }

  String _getCategoryDisplayName(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.bums:
        return 'Bums';
      case WorkoutCategory.tums:
        return 'Tums';
      case WorkoutCategory.fullBody:
        return 'Full Body';
      case WorkoutCategory.cardio:
        return 'Cardio';
      case WorkoutCategory.quickWorkout:
        return 'Quick';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main animation container
              SizedBox(
                height: 250,
                width: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulse rings
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: PulseRingsPainter(
                            progress: _pulseAnimation.value,
                            color: AppColors.salmon,
                          ),
                          size: const Size(200, 200),
                        );
                      },
                    ),
                    
                    // Particles floating around
                    AnimatedBuilder(
                      animation: _particleController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: ParticlesPainter(
                            particles: _particles,
                            progress: _particleController.value,
                          ),
                          size: const Size(200, 200),
                        );
                      }
                    ),
                    
                    // Core "brain" with fitness icon
                    AnimatedBuilder(
                      animation: _brainController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _brainRotation.value,
                          child: Transform.scale(
                            scale: _brainScale.value,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.salmon.withOpacity(0.8),
                                    AppColors.salmon,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.salmon.withOpacity(0.4),
                                    blurRadius: 15,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Brain icon background
                                    Icon(
                                      Icons.psychology,
                                      color: Colors.white.withOpacity(0.8),
                                      size: 40,
                                    ),
                                    // Exercise icon overlay
                                    Icon(
                                      _getCategoryIcon(widget.selectedCategory),
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title with fade transition for changing messages
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _textController,
                  curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                  reverseCurve: const Interval(0.5, 1.0, curve: Curves.easeIn),
                ),
                child: Text(
                  'Creating Your Personalized\n${_getCategoryDisplayName(widget.selectedCategory)} Workout',
                  style: AppTextStyles.h3,
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Changing message with fade transition
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _textController,
                  curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
                  reverseCurve: const Interval(0.3, 0.8, curve: Curves.easeIn),
                ),
                child: Text(
                  _generationMessages[_currentMessageIndex],
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.mediumGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Paint class for pulse rings effect
class PulseRingsPainter extends CustomPainter {
  final double progress;
  final Color color;

  PulseRingsPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw three rings at different opacities and sizes
    _drawRing(canvas, center, progress, 0.3, 120);
    _drawRing(canvas, center, (progress + 0.3) % 1.0, 0.2, 150);
    _drawRing(canvas, center, (progress + 0.6) % 1.0, 0.1, 180);
  }
  
  void _drawRing(Canvas canvas, Offset center, double progress, double maxOpacity, double maxRadius) {
    final Paint paint = Paint()
      ..color = color.withOpacity(maxOpacity * (1.0 - progress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
      
    final radius = progress * maxRadius;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// Particle data class
class _ParticleData {
  double angle;
  double radius;
  double size;
  double speed;
  Color color;
  bool isIcon;
  IconData? icon;

  _ParticleData({
    required this.angle,
    required this.radius,
    required this.size,
    required this.speed,
    required this.color,
    this.isIcon = false,
    this.icon,
  });
}

// Painter for the floating particles
class ParticlesPainter extends CustomPainter {
  final List<_ParticleData> particles;
  final double progress;

  ParticlesPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    for (var particle in particles) {
      // Update angle based on progress and speed
      final currentAngle = particle.angle + (progress * particle.speed * 2 * pi);
      
      // Calculate position
      final x = center.dx + cos(currentAngle) * particle.radius;
      final y = center.dy + sin(currentAngle) * particle.radius;
      
      final position = Offset(x, y);
      
      if (particle.isIcon && particle.icon != null) {
        // Draw icon
        final textPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(particle.icon!.codePoint),
            style: TextStyle(
              fontSize: particle.size * 1.5,
              fontFamily: particle.icon!.fontFamily,
              color: particle.color,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout();
        textPainter.paint(
          canvas, 
          Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2),
        );
      } else {
        // Draw circle
        final paint = Paint()
          ..color = particle.color
          ..style = PaintingStyle.fill;
          
        canvas.drawCircle(position, particle.size / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}