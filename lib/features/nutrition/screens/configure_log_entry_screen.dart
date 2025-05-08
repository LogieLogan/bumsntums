// lib/features/nutrition/screens/configure_log_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/food_item.dart';
import '../models/food_log_entry.dart';
import '../providers/nutrition_provider.dart';
import '../services/nutrition_calculator_service.dart';
import '../../../shared/providers/firebase_providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/components/buttons/primary_button.dart';

class ConfigureLogEntryScreen extends ConsumerStatefulWidget {
  final FoodItem foodItem;
  final FoodLogEntry? existingEntry;

  const ConfigureLogEntryScreen({
    super.key,
    required this.foodItem,
    this.existingEntry,
  });

  @override
  ConsumerState<ConfigureLogEntryScreen> createState() =>
      _ConfigureLogEntryScreenState();
}

class _ConfigureLogEntryScreenState
    extends ConsumerState<ConfigureLogEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  late TextEditingController _weightPerCustomUnitController;

  String _selectedServingUnit = 'g';
  MealType _selectedMealType = MealType.snack;
  DateTime _selectedLogTime = DateTime.now();
  CalculatedNutrition _calculatedNutrition = const CalculatedNutrition();
  bool _isLoading = false;

  List<DropdownMenuItem<String>> _unitDropdownItems = [];

  double? _knownWeightOrVolumeForApiServingUnit;
  String? _apiServingUnitDescriptionForDisplay;
  bool _apiProvidedWeightForSelectedApiUnit = false;

  final List<String> _countableUnits = [
    'serving',
    'piece',
    'slice',
    'cup',
    'tbsp',
    'tsp',
  ];

  bool get _isEditing => widget.existingEntry != null;
  bool get _isCountableUnitSelected =>
      _countableUnits.contains(_selectedServingUnit);

  @override
  void initState() {
    super.initState();
    final entry = widget.existingEntry;
    final food = widget.foodItem;

    _quantityController = TextEditingController(
      text:
          entry != null
              ? entry.servingSize.toStringAsFixed(
                entry.servingSize.truncateToDouble() == entry.servingSize
                    ? 0
                    : 1,
              )
              : '1',
    );
    _weightPerCustomUnitController = TextEditingController();

    _knownWeightOrVolumeForApiServingUnit =
        food.apiServingWeightGrams ?? food.apiServingVolumeMl;
    _apiServingUnitDescriptionForDisplay = food.apiServingUnitDescription;
    _apiProvidedWeightForSelectedApiUnit =
        _apiServingUnitDescriptionForDisplay != null &&
        _apiServingUnitDescriptionForDisplay!.isNotEmpty &&
        _knownWeightOrVolumeForApiServingUnit != null &&
        _knownWeightOrVolumeForApiServingUnit! > 0;

    _setupInitialServingOptionsAndState(food, entry);

    _quantityController.addListener(_handleInputsChanged);
    _weightPerCustomUnitController.addListener(_handleInputsChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateCalculatedNutrition();
    });
  }

  void _setupInitialServingOptionsAndState(FoodItem food, FoodLogEntry? entry) {
    List<String> availableUnits = ['g'];
    if (food.nutritionInfo?.calories != null) {
      if (food.apiPackageQuantityString?.toLowerCase().contains('ml') == true ||
          food.apiPackageQuantityString?.toLowerCase().contains('l') == true) {
        if (!availableUnits.contains('ml')) availableUnits.add('ml');
      }
    }

    if (_apiProvidedWeightForSelectedApiUnit) {
      if (!availableUnits.contains(_apiServingUnitDescriptionForDisplay!)) {
        availableUnits.add(_apiServingUnitDescriptionForDisplay!);
      }

      if (entry == null) {
        _selectedServingUnit = _apiServingUnitDescriptionForDisplay!;
        _quantityController.text = '1';
      }
    } else if (food.nutritionInfo != null) {
      if (entry == null) {
        _selectedServingUnit = availableUnits.contains('ml') ? 'ml' : 'g';
        _quantityController.text = '100';
      }
    } else {
      if (entry == null) {
        _selectedServingUnit = 'g';
        _quantityController.text = '1';
      }
    }

    if (entry != null) {
      _selectedServingUnit = entry.servingUnit;

      _selectedMealType = entry.mealType;
      _selectedLogTime = entry.loggedAt;
    }

    for (String unit in _countableUnits) {
      if (!availableUnits.contains(unit)) {
        availableUnits.add(unit);
      }
    }
    availableUnits = availableUnits.toSet().toList();

    if (!availableUnits.contains(_selectedServingUnit)) {
      _selectedServingUnit = 'g';
      if (entry == null) {
        _quantityController.text =
            widget.foodItem.nutritionInfo != null ? '100' : '1';
      }
    }

    _unitDropdownItems =
        availableUnits.map((String unit) {
          return DropdownMenuItem<String>(value: unit, child: Text(unit));
        }).toList();
  }

  bool get _showWeightPerCustomUnitInput {
    final unitLower = _selectedServingUnit.toLowerCase();
    if (unitLower == 'g' || unitLower == 'ml' || unitLower == 'oz')
      return false;

    if (unitLower == _apiServingUnitDescriptionForDisplay?.toLowerCase()) {
      return !_apiProvidedWeightForSelectedApiUnit;
    }

    return _isCountableUnitSelected;
  }

  @override
  void dispose() {
    _quantityController.removeListener(_handleInputsChanged);
    _weightPerCustomUnitController.removeListener(_handleInputsChanged);
    _quantityController.dispose();
    _weightPerCustomUnitController.dispose();
    super.dispose();
  }

  void _handleInputsChanged() {
    _updateCalculatedNutrition();
  }

  void _updateCalculatedNutrition() {
    final double quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final double? userDefinedWeight =
        _showWeightPerCustomUnitInput
            ? (double.tryParse(_weightPerCustomUnitController.text))
            : null;

    final calculator = ref.read(nutritionCalculatorServiceProvider);

    _apiProvidedWeightForSelectedApiUnit =
        _selectedServingUnit == _apiServingUnitDescriptionForDisplay &&
        _knownWeightOrVolumeForApiServingUnit != null &&
        _knownWeightOrVolumeForApiServingUnit! > 0;

    final results = calculator.calculateNutrition(
      baseNutrition: widget.foodItem.nutritionInfo,
      servingSize: quantity,
      servingUnit: _selectedServingUnit,
      userDefinedWeightPerServing: userDefinedWeight,
      knownWeightOfApiServingUnit: _knownWeightOrVolumeForApiServingUnit,
      apiServingUnitDescription: _apiServingUnitDescriptionForDisplay,
    );

    if (mounted) {
      setState(() {
        _calculatedNutrition = results;
      });
    }
  }

  Future<void> _logEntry() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Not logged in.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    double finalServingSize = double.parse(_quantityController.text);
    String finalServingUnit = _selectedServingUnit;
    double? userEnteredWeightPerCustomUnit = double.tryParse(
      _weightPerCustomUnitController.text,
    );

    if (_showWeightPerCustomUnitInput &&
        userEnteredWeightPerCustomUnit != null &&
        userEnteredWeightPerCustomUnit > 0) {
      finalServingSize = finalServingSize * userEnteredWeightPerCustomUnit;
      finalServingUnit = 'g';
    } else if (_selectedServingUnit == _apiServingUnitDescriptionForDisplay &&
        _knownWeightOrVolumeForApiServingUnit != null &&
        _knownWeightOrVolumeForApiServingUnit! > 0) {
      finalServingSize =
          finalServingSize * _knownWeightOrVolumeForApiServingUnit!;
      finalServingUnit =
          widget.foodItem.apiServingWeightGrams != null ? 'g' : 'ml';
    }

    final entryToSave = FoodLogEntry(
      id: _isEditing ? widget.existingEntry!.id : const Uuid().v4(),
      userId: userId,
      foodItemId: widget.foodItem.id,
      foodItemBarcode: widget.foodItem.barcode,
      foodItemName: widget.foodItem.name,
      foodItemBrand: widget.foodItem.brand,
      loggedAt: _selectedLogTime,
      mealType: _selectedMealType,
      servingSize: finalServingSize,
      servingUnit: finalServingUnit,
      calculatedCalories: _calculatedNutrition.calories,
      calculatedProtein: _calculatedNutrition.protein,
      calculatedCarbs: _calculatedNutrition.carbs,
      calculatedFat: _calculatedNutrition.fat,
    );

    try {
      final notifier = ref.read(nutritionDiaryProvider(userId).notifier);
      if (_isEditing) {
        await notifier.deleteLogEntry(widget.existingEntry!.id);
        await notifier.addLogEntry(entryToSave);
      } else {
        await notifier.addLogEntry(entryToSave);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${entryToSave.foodItemName} ${_isEditing ? "updated" : "logged"} successfully!',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving entry: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectLogTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedLogTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedLogTime),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedLogTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat("#,##0.##");
    final caloriesText =
        _calculatedNutrition.calories > 0
            ? numberFormat.format(_calculatedNutrition.calories)
            : '--';
    final proteinText =
        _calculatedNutrition.protein > 0
            ? numberFormat.format(_calculatedNutrition.protein)
            : '--';
    final carbsText =
        _calculatedNutrition.carbs > 0
            ? numberFormat.format(_calculatedNutrition.carbs)
            : '--';
    final fatText =
        _calculatedNutrition.fat > 0
            ? numberFormat.format(_calculatedNutrition.fat)
            : '--';

    String quantityLabel = 'Quantity';
    if (_selectedServingUnit == 'g')
      quantityLabel = 'Grams (g)';
    else if (_selectedServingUnit == 'ml')
      quantityLabel = 'Milliliters (ml)';
    else if (_selectedServingUnit == 'oz')
      quantityLabel = 'Ounces (oz)';
    else if (_isCountableUnitSelected)
      quantityLabel = 'Number of ${_selectedServingUnit}s';

    bool showApproximationNote =
        _calculatedNutrition.isApproximation ||
        (_showWeightPerCustomUnitInput &&
            (double.tryParse(_weightPerCustomUnitController.text) ?? 0.0) <=
                0 &&
            _calculatedNutrition.calories <= 0 &&
            widget.foodItem.nutritionInfo != null);
    String approximationText =
        'Could not calculate accurately for "$_selectedServingUnit".';
    if (_showWeightPerCustomUnitInput &&
        (double.tryParse(_weightPerCustomUnitController.text) ?? 0.0) <= 0) {
      approximationText =
          'Enter weight per "$_selectedServingUnit" above for accurate calculation.';
    } else if (_calculatedNutrition.isApproximation) {
      approximationText =
          'Calculation for "$_selectedServingUnit" is approximate.';
    }

    return Scaffold(
      /* ... (AppBar remains the same) ... */
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Log Entry' : 'Log ${widget.foodItem.name}',
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.foodItem.name, style: AppTextStyles.h2),
              if (widget.foodItem.brand != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    widget.foodItem.brand!,
                    style: AppTextStyles.body.copyWith(color: Colors.grey),
                  ),
                ),
              if (widget.foodItem.apiServingSizeString != null &&
                  widget.foodItem.apiServingSizeString!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Text(
                    'Standard Serving (from packaging): ${widget.foodItem.apiServingSizeString}',
                    style: AppTextStyles.small.copyWith(
                      color: Colors.blueGrey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              const SizedBox(height: 16),
              Text('Amount Eaten', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: quantityLabel,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0)
                          return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: _unitDropdownItems.length > 2 ? 3 : 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedServingUnit,
                      items: _unitDropdownItems,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedServingUnit = newValue;
                            if (!_showWeightPerCustomUnitInput) {
                              _weightPerCustomUnitController.clear();
                            }
                          });
                          _updateCalculatedNutrition();
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child:
                    _showWeightPerCustomUnitInput
                        ? Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: TextFormField(
                            controller: _weightPerCustomUnitController,
                            decoration: InputDecoration(
                              labelText: 'Weight per $_selectedServingUnit (g)',
                              hintText:
                                  'e.g., 30 if 1 $_selectedServingUnit is 30g',
                              border: const OutlineInputBorder(),
                              suffixText: 'g',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  (double.tryParse(value) == null ||
                                      double.parse(value) <= 0)) {
                                return 'Invalid weight';
                              }
                              return null;
                            },
                          ),
                        )
                        : const SizedBox.shrink(),
              ),

              const SizedBox(height: 20),
              Text('Meal', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children:
                    MealType.values.map((meal) {
                      return ChoiceChip(
                        label: Text(
                          meal.name[0].toUpperCase() + meal.name.substring(1),
                        ),
                        selected: _selectedMealType == meal,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedMealType = meal;
                            });
                          }
                        },
                        selectedColor: AppColors.salmon.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color:
                              _selectedMealType == meal
                                  ? AppColors.salmon
                                  : Colors.black87,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color:
                                _selectedMealType == meal
                                    ? AppColors.salmon
                                    : Colors.grey.shade300,
                          ),
                        ),
                        backgroundColor: Colors.white,
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Log Time', style: AppTextStyles.h3),
                subtitle: Text(
                  DateFormat.yMd().add_jm().format(_selectedLogTime),
                ),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _selectLogTime,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text('Calculated Nutrition', style: AppTextStyles.h3),
              const SizedBox(height: 4),
              if (showApproximationNote)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    approximationText,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.orange.shade800,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCalculatedMacro(
                    'Calories',
                    caloriesText,
                    AppColors.salmon,
                  ),
                  _buildCalculatedMacro(
                    'Protein',
                    '${proteinText}g',
                    AppColors.popBlue,
                  ),
                  _buildCalculatedMacro(
                    'Carbs',
                    '${carbsText}g',
                    AppColors.popGreen,
                  ),
                  _buildCalculatedMacro(
                    'Fat',
                    '${fatText}g',
                    AppColors.popCoral,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text:
                    _isLoading
                        ? 'Saving...'
                        : (_isEditing ? 'Update Entry' : 'Log Entry'),
                onPressed: _isLoading ? null : _logEntry,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatedMacro(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
