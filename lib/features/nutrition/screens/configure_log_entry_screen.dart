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
  // ... (other state variables) ...
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  late TextEditingController _weightPerCustomUnitController;

  String _selectedServingUnit = 'g';
  MealType _selectedMealType = MealType.snack;
  DateTime _selectedLogTime = DateTime.now();
  CalculatedNutrition _calculatedNutrition = const CalculatedNutrition();
  bool _isLoading = false;

  final List<String> _countableUnits = [
    'serving',
    'piece',
    'slice',
    'cup',
    'tbsp',
    'tsp',
  ];

  // --- Initialize _unitDropdownItems ---
  List<DropdownMenuItem<String>> _unitDropdownItems = [];
  // --- End Initialization ---

  double? _knownWeightOrVolumeForApiServingUnit;
  String? _apiServingUnitDescriptionForDisplay;
  bool _apiProvidedWeightForSelectedApiUnit = false;

  bool get _isEditing => widget.existingEntry != null;
  bool get _isCountableUnitSelected =>
      _countableUnits.contains(_selectedServingUnit);

  // ... (rest of the class, including initState which calls _setupInitialServingOptions) ...
  @override
  void initState() {
    super.initState();
// Initialize _allUnits before _setup...
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

    _setupInitialServingOptions(
      food,
      entry,
    ); // This populates _unitDropdownItems

    _quantityController.addListener(_updateCalculatedNutrition);
    _weightPerCustomUnitController.addListener(_updateCalculatedNutrition);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateCalculatedNutrition();
    });
  }

  void _setupInitialServingOptions(FoodItem food, FoodLogEntry? entry) {
    List<String> availableUnits = ['g', 'ml'];

    _knownWeightOrVolumeForApiServingUnit =
        food.apiServingWeightGrams ?? food.apiServingVolumeMl;
    _apiServingUnitDescriptionForDisplay = food.apiServingUnitDescription;

    if (_apiServingUnitDescriptionForDisplay != null &&
        _apiServingUnitDescriptionForDisplay!.isNotEmpty &&
        _knownWeightOrVolumeForApiServingUnit != null) {
      if (!availableUnits.contains(_apiServingUnitDescriptionForDisplay!)) {
        availableUnits.add(_apiServingUnitDescriptionForDisplay!);
      }
      _apiProvidedWeightForSelectedApiUnit = true;
      if (entry == null) {
        _selectedServingUnit = _apiServingUnitDescriptionForDisplay!;
        _quantityController.text = '1';
      }
    } else if (food.nutritionInfo != null) {
      _apiProvidedWeightForSelectedApiUnit = false;
      if (entry == null) {
        _selectedServingUnit = 'g';
        _quantityController.text = '100';
      }
    } else {
      _apiProvidedWeightForSelectedApiUnit = false;
      if (entry == null) {
        // Check if _isCountableUnitSelected is safe to call here, depends on _selectedServingUnit which might not be set by user yet
        // Safer to just default to 'g' if no other info.
        _selectedServingUnit = 'g'; // Default to 'g' if no info
        _quantityController.text = '1';
      }
    }

    if (entry != null) {
      _selectedServingUnit = entry.servingUnit;
      _selectedMealType = entry.mealType;
      _selectedLogTime = entry.loggedAt;
      if (entry.servingUnit == _apiServingUnitDescriptionForDisplay &&
          _knownWeightOrVolumeForApiServingUnit != null) {
        _apiProvidedWeightForSelectedApiUnit = true;
      } else if (_countableUnits.contains(entry.servingUnit)) {
        // Use _countableUnits directly
        _apiProvidedWeightForSelectedApiUnit = false;
      }
    }

    // Ensure _selectedServingUnit from entry is in availableUnits, if not, default and adjust.
    // This needs to be done carefully to avoid recursive calls if _updateCalculatedNutrition is triggered by setState.
    List<String> finalAvailableUnits =
        availableUnits.toSet().toList(); // Default available units

    if (_apiServingUnitDescriptionForDisplay != null &&
        _apiServingUnitDescriptionForDisplay!.isNotEmpty) {
      if (!finalAvailableUnits.contains(
        _apiServingUnitDescriptionForDisplay!,
      )) {
        finalAvailableUnits.add(_apiServingUnitDescriptionForDisplay!);
      }
    }
    // Add all default countable units to ensure they are always options,
    // the logic for showing weight input handles whether they are "smart" or require user input.
    for (String unit in _countableUnits) {
      if (!finalAvailableUnits.contains(unit)) {
        finalAvailableUnits.add(unit);
      }
    }

    if (!finalAvailableUnits.contains(_selectedServingUnit)) {
      _selectedServingUnit = 'g'; // Fallback to 'g'
      if (entry == null) {
        _quantityController.text =
            widget.foodItem.nutritionInfo != null ? '100' : '1';
      }
    }

    // setState for _unitDropdownItems should happen here, after all logic.
    // And ensure it doesn't trigger an infinite loop with listeners.
    // The direct assignment in initState should be fine.
    _unitDropdownItems =
        finalAvailableUnits.map((String unit) {
          return DropdownMenuItem<String>(value: unit, child: Text(unit));
        }).toList();
  }

  bool get _showWeightPerCustomUnitInput {
    if (_selectedServingUnit == 'g' ||
        _selectedServingUnit == 'ml' ||
        _selectedServingUnit == 'oz') {
      return false;
    }

    // If the selected unit IS the API's defined unit (e.g., "piece")
    if (_selectedServingUnit == _apiServingUnitDescriptionForDisplay) {
      // Show input only if we DON'T have a known weight for this API unit
      return !_apiProvidedWeightForSelectedApiUnit;
    }
    // For any other countable unit (not 'g'/'ml' and not the API's known one)
    return _isCountableUnitSelected; // True if it's in _countableUnits
  }

  // ... (Rest of the class: dispose, _updateCalculatedNutrition, _logEntry, _selectLogTime, build, _buildCalculatedMacro) ...
  @override
  void dispose() {
    _quantityController.removeListener(
      _updateCalculatedNutrition,
    ); // Ensure listeners are removed
    _weightPerCustomUnitController.removeListener(_updateCalculatedNutrition);
    _quantityController.dispose();
    _weightPerCustomUnitController.dispose();
    super.dispose();
  }

  void _updateCalculatedNutrition() {
    final double quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final double? userDefinedWeight =
        _showWeightPerCustomUnitInput
            ? (double.tryParse(_weightPerCustomUnitController.text))
            : null;

    final calculator = ref.read(nutritionCalculatorServiceProvider);
    final results = calculator.calculateNutrition(
      baseNutrition: widget.foodItem.nutritionInfo,
      servingSize: quantity,
      servingUnit: _selectedServingUnit,
      servingSizeStringFromApi: widget.foodItem.apiServingSizeString,
      userDefinedWeightPerServing: userDefinedWeight,
      knownWeightOfApiServingUnit:
          (_selectedServingUnit == _apiServingUnitDescriptionForDisplay)
              ? _knownWeightOrVolumeForApiServingUnit
              : null,
    );

    // Update _apiProvidedWeightForSelectedApiUnit based on current _selectedServingUnit
    if (_selectedServingUnit == widget.foodItem.apiServingUnitDescription) {
      _apiProvidedWeightForSelectedApiUnit =
          (widget.foodItem.apiServingWeightGrams != null ||
              widget.foodItem.apiServingVolumeMl != null);
    } else {
      _apiProvidedWeightForSelectedApiUnit = false;
    }

    if (mounted) {
      // Check if widget is still in the tree
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
        _knownWeightOrVolumeForApiServingUnit != null) {
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
    if (_selectedServingUnit == 'g' || _selectedServingUnit == 'ml') {
      quantityLabel =
          _selectedServingUnit == 'g' ? 'Grams (g)' : 'Milliliters (ml)';
    } else if (_selectedServingUnit == _apiServingUnitDescriptionForDisplay &&
        _knownWeightOrVolumeForApiServingUnit != null) {
      quantityLabel = 'Number of ${_apiServingUnitDescriptionForDisplay}s';
    } else if (_isCountableUnitSelected) {
      quantityLabel = 'Number of ${_selectedServingUnit}s';
    }

    return Scaffold(
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
                            double.parse(value) <= 0) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: _unitDropdownItems.length > 2 ? 3 : 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedServingUnit,
                      items: _unitDropdownItems, // Use the initialized list
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedServingUnit = newValue;
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
              if (_showWeightPerCustomUnitInput)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextFormField(
                    controller: _weightPerCustomUnitController,
                    decoration: InputDecoration(
                      labelText: 'Weight per $_selectedServingUnit (g)',
                      hintText: 'e.g., 30 if 1 $_selectedServingUnit is 30g',
                      border: const OutlineInputBorder(),
                      suffixText: 'g',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
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
              if (_showWeightPerCustomUnitInput &&
                  (double.tryParse(_weightPerCustomUnitController.text) ??
                          0.0) <=
                      0 &&
                  _calculatedNutrition.calories <= 0 &&
                  widget.foodItem.nutritionInfo != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Enter weight per "$_selectedServingUnit" above for accurate calculation, or calculations will be based on 100g/ml.',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.orange.shade800,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else if (_calculatedNutrition.calories <= 0 &&
                  widget.foodItem.nutritionInfo != null &&
                  !_showWeightPerCustomUnitInput &&
                  ![
                    'g',
                    'ml',
                    'oz',
                  ].contains(_selectedServingUnit)) // Refined condition
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Could not calculate for "$_selectedServingUnit". Define weight or use g/ml.',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.red.shade800,
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
