// lib/features/auth/widgets/onboarding/steps/measurements_step.dart
import 'package:flutter/material.dart';
import '../../../../../shared/theme/app_text_styles.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/services/unit_conversion_service.dart';
import '../../../models/user_profile.dart';

class MeasurementsStep extends StatefulWidget {
  final DateTime? initialDateOfBirth;
  final double? initialHeight;
  final double? initialWeight;
  final UnitSystem initialUnitSystem;
  final Function(DateTime?, double?, double?, UnitSystem) onNext;
  final Function(DateTime?, double?, double?, UnitSystem)? onChanged;

  const MeasurementsStep({
    Key? key,
    this.initialDateOfBirth,
    this.initialHeight,
    this.initialWeight,
    this.initialUnitSystem = UnitSystem.metric,
    required this.onNext,
    this.onChanged,
  }) : super(key: key);

  @override
  State<MeasurementsStep> createState() => _MeasurementsStepState();
}

class _MeasurementsStepState extends State<MeasurementsStep> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  late UnitSystem _unitSystem;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDateOfBirth;
    _unitSystem = widget.initialUnitSystem;
    
    // Set initial values based on the unit system
    _setInitialValues();
  }

  void _setInitialValues() {
    if (widget.initialHeight != null) {
      if (_unitSystem == UnitSystem.metric) {
        _heightController.text = widget.initialHeight!.toStringAsFixed(1);
      } else {
        final totalInches = UnitConversionService.cmToInches(widget.initialHeight!);
        final feet = (totalInches / 12).floor();
        final inches = (totalInches % 12).round();
        _heightController.text = '$feet\'$inches"';
      }
    }
    
    if (widget.initialWeight != null) {
      if (_unitSystem == UnitSystem.metric) {
        _weightController.text = widget.initialWeight!.toStringAsFixed(1);
      } else {
        final lbs = UnitConversionService.kgToLbs(widget.initialWeight!);
        _weightController.text = lbs.toStringAsFixed(1);
      }
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _updateMeasurements() {
    if (widget.onChanged != null) {
      final height = UnitConversionService.parseHeight(_heightController.text, _unitSystem);
      final weight = UnitConversionService.parseWeight(_weightController.text, _unitSystem);
      widget.onChanged!(_selectedDate, height, weight, _unitSystem);
    }
  }

  void _setUnitSystem(UnitSystem unitSystem) {
    if (_unitSystem == unitSystem) return;
    
    setState(() {
      // Convert existing values if needed
      _convertHeightValue(unitSystem);
      _convertWeightValue(unitSystem);
      
      _unitSystem = unitSystem;
      _updateMeasurements();
    });
  }

  void _convertHeightValue(UnitSystem newUnitSystem) {
    if (_heightController.text.isEmpty) return;
    
    // Current value is in cm or feet/inches format based on current unit system
    final currentHeightCm = UnitConversionService.parseHeight(_heightController.text, _unitSystem);
    if (currentHeightCm == null) return;
    
    // Convert to new format
    if (newUnitSystem == UnitSystem.metric) {
      _heightController.text = currentHeightCm.toStringAsFixed(1);
    } else {
      final totalInches = UnitConversionService.cmToInches(currentHeightCm);
      final feet = (totalInches / 12).floor();
      final inches = (totalInches % 12).round();
      _heightController.text = '$feet\'$inches"';
    }
  }

  void _convertWeightValue(UnitSystem newUnitSystem) {
    if (_weightController.text.isEmpty) return;
    
    final weight = double.tryParse(_weightController.text);
    if (weight == null) return;
    
    if (newUnitSystem == UnitSystem.metric && _unitSystem == UnitSystem.imperial) {
      // Convert lbs to kg
      final kg = UnitConversionService.lbsToKg(weight);
      _weightController.text = kg.toStringAsFixed(1);
    } else if (newUnitSystem == UnitSystem.imperial && _unitSystem == UnitSystem.metric) {
      // Convert kg to lbs
      final lbs = UnitConversionService.kgToLbs(weight);
      _weightController.text = lbs.toStringAsFixed(1);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    // Default to 25 years ago if no date selected
    final initialDate = _selectedDate ?? 
        DateTime.now().subtract(const Duration(days: 365 * 25));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1923), // 100 years ago
      lastDate: DateTime.now().subtract(
        const Duration(days: 365 * 13),
      ), // 13 years ago
      helpText: 'Select your date of birth',
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateMeasurements(); // Call onChanged when date changes
      });
    }
  }

  String _getFormattedDate() {
    if (_selectedDate == null) return 'Not set';
    return '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
  }

  int? _calculateAge() {
    if (_selectedDate == null) return null;

    final now = DateTime.now();
    int age = now.year - _selectedDate!.year;
    if (now.month < _selectedDate!.month ||
        (now.month == _selectedDate!.month && now.day < _selectedDate!.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your measurements', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            'This helps us provide more accurate workout and nutrition recommendations',
            style: AppTextStyles.small,
          ),
          const SizedBox(height: 24),
          
          // Unit System Selection
          Text('Preferred units', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildUnitTypeButton(
                  title: 'Metric',
                  subtitle: 'kg, cm',
                  isSelected: _unitSystem == UnitSystem.metric,
                  onTap: () => _setUnitSystem(UnitSystem.metric),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUnitTypeButton(
                  title: 'Imperial',
                  subtitle: 'lbs, ft/in',
                  isSelected: _unitSystem == UnitSystem.imperial,
                  onTap: () => _setUnitSystem(UnitSystem.imperial),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Date of Birth
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date of Birth',
                    style: TextStyle(color: AppColors.mediumGrey, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getFormattedDate(),
                        style: TextStyle(
                          color: _selectedDate == null
                              ? AppColors.lightGrey
                              : AppColors.darkGrey,
                          fontSize: 16,
                        ),
                      ),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                  if (_selectedDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Age: ${_calculateAge()}',
                      style: TextStyle(
                        color: AppColors.mediumGrey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Height
          TextField(
            controller: _heightController,
            decoration: InputDecoration(
              labelText: _unitSystem == UnitSystem.metric ? 'Height (cm)' : 'Height (ft\'in")',
              hintText: _unitSystem == UnitSystem.metric ? 'Enter your height in cm' : 'e.g., 5\'10"',
              suffixText: _unitSystem == UnitSystem.metric ? 'cm' : '',
            ),
            keyboardType: TextInputType.text,
            onChanged: (value) {
              _updateMeasurements(); // Call onChanged when height changes
            },
          ),

          const SizedBox(height: 16),

          // Weight
          TextField(
            controller: _weightController,
            decoration: InputDecoration(
              labelText: _unitSystem == UnitSystem.metric ? 'Weight (kg)' : 'Weight (lbs)',
              hintText: 'Enter your weight',
              suffixText: _unitSystem == UnitSystem.metric ? 'kg' : 'lbs',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _updateMeasurements(); // Call onChanged when weight changes
            },
          ),
          
          const SizedBox(height: 16),
          Text(
            'Your measurements are private and only used to personalize your experience',
            style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildUnitTypeButton({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.salmon.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.salmon : AppColors.lightGrey,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: AppTextStyles.body.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.salmon : AppColors.darkGrey,
              ),
            ),
            Text(
              subtitle,
              style: AppTextStyles.small.copyWith(
                color: isSelected ? AppColors.salmon : AppColors.mediumGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}