// lib/features/ai_workout_planning/screens/ai_plan_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plan_generation_parameters.dart';
import '../providers/plan_generation_provider.dart';
import '../widgets/steps/welcome_step.dart';
import '../widgets/steps/duration_frequency_step.dart';
import '../widgets/steps/focus_variation_step.dart';
import '../widgets/steps/special_request_step.dart';
import '../widgets/steps/generating_step.dart';
import '../widgets/steps/parameters_summary_sheet.dart';
import '../widgets/visualization/plan_preview.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../auth/providers/user_provider.dart';
import '../../../shared/providers/environment_provider.dart';

enum PlanCreationStep {
  welcome,
  durationFrequency,
  focusVariation,
  specialRequest,
  generating,
  result,
  refinement,
  refinementResult,
}

class AIPlanCreationScreen extends ConsumerStatefulWidget {
  final String userId;

  const AIPlanCreationScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  ConsumerState<AIPlanCreationScreen> createState() =>
      _AIPlanCreationScreenState();
}

class _AIPlanCreationScreenState extends ConsumerState<AIPlanCreationScreen>
    with SingleTickerProviderStateMixin {
  PlanCreationStep _currentStep = PlanCreationStep.welcome;
  int _durationDays = 7;
  int _daysPerWeek = 3;
  List<String> _focusAreas = ['Full Body'];
  String _variationType = 'balanced';
  final TextEditingController _specialRequestController =
      TextEditingController();
  final TextEditingController _refinementController = TextEditingController();
  final AnalyticsService _analytics = AnalyticsService();

  // Animation controller for transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late ScrollController _scrollController;

  // Forward declarations to avoid reference-before-declaration errors
  Widget _buildCurrentStep() => const SizedBox();
  Widget _buildBottomSheet() => const SizedBox();

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    _analytics.logScreenView(screenName: 'ai_plan_creation_screen');
  }

  @override
  void dispose() {
    _specialRequestController.dispose();
    _refinementController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _goToNextStep() {
    // Add haptic feedback
    HapticFeedback.selectionClick();

    // Animate out current step
    _animationController.reverse().then((_) {
      setState(() {
        _currentStep =
            PlanCreationStep.values[(_currentStep.index + 1) %
                PlanCreationStep.values.length];
      });

      // Scroll to top and animate in new step
      _scrollToTop();
      _animationController.forward();
    });
  }

  void _goToPreviousStep() {
    // Add haptic feedback
    HapticFeedback.selectionClick();

    // Animate out current step
    _animationController.reverse().then((_) {
      setState(() {
        if (_currentStep.index > 0) {
          _currentStep = PlanCreationStep.values[_currentStep.index - 1];
        }
      });

      // Scroll to top and animate in new step
      _scrollToTop();
      _animationController.forward();
    });
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _updateDuration(int days) {
    setState(() {
      _durationDays = days;
    });

    _analytics.logEvent(
      name: 'plan_duration_selected',
      parameters: {'days': days},
    );
  }

  void _updateFrequency(int daysPerWeek) {
    setState(() {
      _daysPerWeek = daysPerWeek;
    });

    _analytics.logEvent(
      name: 'plan_frequency_selected',
      parameters: {'days_per_week': daysPerWeek},
    );
  }

  void _updateFocusAreas(List<String> areas) {
    setState(() {
      _focusAreas = areas;
    });

    _analytics.logEvent(
      name: 'plan_focus_areas_updated',
      parameters: {'areas': areas.join(',')},
    );
  }

  void _updateVariationType(String type) {
    setState(() {
      _variationType = type;
    });

    _analytics.logEvent(
      name: 'plan_variation_type_selected',
      parameters: {'type': type},
    );
  }

  Future<void> _generatePlan() async {
    try {
      // First, ensure environment service is initialized
      try {
        await ref.read(environmentServiceInitProvider.future);
      } catch (e) {
        debugPrint('Error ensuring environment service is initialized: $e');
        // Continue anyway, as we'll handle potential errors later
      }

      final userProfile = await ref.read(userProfileProvider.future);
      if (userProfile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to load user profile')),
          );
          setState(() {
            _currentStep = PlanCreationStep.specialRequest;
          });
        }
        return;
      }

      // Extract user profile data
      final userProfileData = {
        'fitnessLevel': userProfile.fitnessLevel.name,
        'age': userProfile.age,
        'goals': userProfile.goals.map((g) => g.name).toList(),
        'preferredLocation': userProfile.preferredLocation?.name,
        'availableEquipment': userProfile.availableEquipment,
        'healthConditions': userProfile.healthConditions,
      };

      // Set parameters then generate
      final notifier = ref.read(planGenerationProvider.notifier);

      // Reset any previous parameters
      notifier.reset();

      // Set new parameters
      notifier.setParameters(
        durationDays: _durationDays,
        daysPerWeek: _daysPerWeek,
        focusAreas: _focusAreas,
        variationType: _variationType,
        fitnessLevel: userProfile.fitnessLevel.name,
        specialRequest:
            _specialRequestController.text.trim().isNotEmpty
                ? _specialRequestController.text.trim()
                : null,
        equipment:
            userProfile.availableEquipment.isNotEmpty
                ? userProfile.availableEquipment
                : null,
      );

      await notifier.generatePlan(
        userId: userProfile.userId,
        userProfileData: userProfileData,
      );

      if (mounted) {
        _animationController.reverse().then((_) {
          setState(() {
            _currentStep = PlanCreationStep.result;
          });
          _scrollToTop();
          _animationController.forward();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating plan: ${e.toString()}')),
        );
        setState(() {
          _currentStep = PlanCreationStep.specialRequest;
        });
      }
    }
  }

  void _startGeneration() {
    // Add haptic feedback
    HapticFeedback.mediumImpact();

    _animationController.reverse().then((_) {
      setState(() {
        _currentStep = PlanCreationStep.generating;
      });

      _scrollToTop();
      _animationController.forward();
      _generatePlan();
    });

    _analytics.logEvent(name: 'plan_generation_started');
  }

  void _startRefinement() {
    // Reset any previous changes summary
    ref.read(planGenerationProvider.notifier).state = ref
        .read(planGenerationProvider.notifier)
        .state
        .copyWith(changesSummary: null);

    // Clear the refinement controller
    _refinementController.clear();

    _animationController.reverse().then((_) {
      setState(() {
        _currentStep = PlanCreationStep.refinement;
      });
      _scrollToTop();
      _animationController.forward();
    });

    _analytics.logEvent(name: 'plan_refinement_started');
  }

  void _startOver() {
    ref.read(planGenerationProvider.notifier).reset();

    _animationController.reverse().then((_) {
      setState(() {
        _specialRequestController.clear();
        _refinementController.clear();
        _currentStep = PlanCreationStep.durationFrequency;
      });
      _scrollToTop();
      _animationController.forward();
    });

    _analytics.logEvent(name: 'plan_creation_restarted');
  }

  bool _shouldShowBottomSheet() {
    // Don't show for welcome, generating, or result steps
    return !([
      PlanCreationStep.welcome,
      PlanCreationStep.generating,
      PlanCreationStep.result,
      PlanCreationStep.refinementResult,
    ].contains(_currentStep));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Workout Plan Creator'),
        actions: [
          if (_currentStep == PlanCreationStep.result ||
              _currentStep == PlanCreationStep.refinementResult)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startOver,
              tooltip: 'Create new plan',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Main content area with fade animation
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildCurrentStepImpl(),
                  ),
                ),
              ),
            ),

            // Parameter summary sheet (only shown for certain steps)
            if (_shouldShowBottomSheet()) _buildBottomSheetImpl(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepImpl() {
    final planGenerationState = ref.watch(planGenerationProvider);

    switch (_currentStep) {
      case PlanCreationStep.welcome:
        return PlanWelcomeStep(onGetStarted: _goToNextStep);

      case PlanCreationStep.durationFrequency:
        return DurationFrequencyStep(
          selectedDuration: _durationDays,
          selectedFrequency: _daysPerWeek,
          onDurationSelected: _updateDuration,
          onFrequencySelected: _updateFrequency,
          onContinue: _goToNextStep,
          onBack: _goToPreviousStep,
        );

      case PlanCreationStep.focusVariation:
        return FocusVariationStep(
          selectedFocusAreas: _focusAreas,
          selectedVariationType: _variationType,
          onFocusAreasChanged: _updateFocusAreas,
          onVariationTypeChanged: _updateVariationType,
          onContinue: _goToNextStep,
          onBack: _goToPreviousStep,
        );

      case PlanCreationStep.specialRequest:
        return SpecialRequestStep(
          controller: _specialRequestController,
          selectedFocusAreas: _focusAreas,
          selectedDuration: _durationDays,
          selectedFrequency: _daysPerWeek,
          selectedVariationType: _variationType,
          onGenerate: _startGeneration,
          onBack: _goToPreviousStep,
        );

      case PlanCreationStep.generating:
        return const PlanGeneratingStep();

      case PlanCreationStep.result:
        if (planGenerationState.planData != null) {
          return PlanPreview(
            planData: planGenerationState.planData!,
            onRefine: _startRefinement,
          );
        }
        return const Center(child: Text("No plan data available"));

      case PlanCreationStep.refinement:
      case PlanCreationStep.refinementResult:
        // These will be implemented later
        return const Center(
          child: Text("Refinement functionality coming soon"),
        );
    }
  }

  Widget _buildBottomSheetImpl() {
    String continueText = 'Continue';
    VoidCallback? onContinue;
    VoidCallback? onBack;

    switch (_currentStep) {
      case PlanCreationStep.durationFrequency:
        onContinue = _goToNextStep;
        onBack = _goToPreviousStep;
        break;
      case PlanCreationStep.focusVariation:
        onContinue = _goToNextStep;
        onBack = _goToPreviousStep;
        break;
      case PlanCreationStep.specialRequest:
        continueText = 'Generate Plan';
        onContinue = _startGeneration;
        onBack = _goToPreviousStep;
        break;
      default:
        break;
    }

    return ParametersSummarySheet(
      durationDays: _durationDays,
      daysPerWeek: _daysPerWeek,
      focusAreas: _focusAreas,
      variationType: _variationType,
      specialRequest:
          _specialRequestController.text.trim().isNotEmpty
              ? _specialRequestController.text.trim()
              : null,
      onBack: onBack,
      onContinue: onContinue,
      showBackButton: _currentStep != PlanCreationStep.welcome,
      showContinueButton: true,
      continueButtonText: continueText,
    );
  }
}
