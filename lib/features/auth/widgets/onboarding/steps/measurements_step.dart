import 'package:bums_n_tums/shared/theme/color_palette.dart';
import 'package:bums_n_tums/shared/theme/text_styles.dart';
import 'package:flutter/material.dart';

class MeasurementsStep extends StatefulWidget {
  final DateTime? initialDateOfBirth;
  final double? initialHeight;
  final double? initialWeight;
  final Function(DateTime?, double?, double?) onNext;
  final Function(DateTime?, double?, double?)? onChanged;

  const MeasurementsStep({
    super.key,
    this.initialDateOfBirth,
    this.initialHeight,
    this.initialWeight,
    required this.onNext,
    this.onChanged,
  });

  @override
  State<MeasurementsStep> createState() => MeasurementsStepState();
}

class MeasurementsStepState extends State<MeasurementsStep> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDateOfBirth;
    _heightController.text = widget.initialHeight?.toString() ?? '';
    _weightController.text = widget.initialWeight?.toString() ?? '';
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _updateMeasurements() {
    if (widget.onChanged != null) {
      double? height = _heightController.text.isNotEmpty 
          ? double.tryParse(_heightController.text) 
          : null;
      double? weight = _weightController.text.isNotEmpty 
          ? double.tryParse(_weightController.text) 
          : null;
      widget.onChanged!(_selectedDate, height, weight);
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
          Text(
            'These measurements help us personalize your experience',
            style: AppTextStyles.small,
          ),
          const SizedBox(height: 16),

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
            decoration: const InputDecoration(
              labelText: 'Height (cm)',
              hintText: 'Enter your height',
              suffixText: 'cm',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _updateMeasurements(); // Call onChanged when height changes
            },
          ),

          const SizedBox(height: 16),

          // Weight
          TextField(
            controller: _weightController,
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              hintText: 'Enter your weight',
              suffixText: 'kg',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _updateMeasurements(); // Call onChanged when weight changes
            },
          ),
        ],
      ),
    );
  }
}