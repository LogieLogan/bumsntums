// lib/features/nutrition/screens/configure_log_entry_screen.dart
// ... (imports) ...
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

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
  late TextEditingController _quantityController; // Renamed for clarity
  // --- NEW: Controller for user-defined weight per serving ---
  late TextEditingController _weightPerServingController;
  // --- END NEW ---

  String _selectedServingUnit = 'serving';
  MealType _selectedMealType = MealType.snack;
  DateTime _selectedLogTime = DateTime.now();
  CalculatedNutrition _calculatedNutrition = const CalculatedNutrition();
  bool _isLoading = false;

  // Grouped serving units
  final List<String> _preciseUnits = ['g', 'ml', 'oz']; // oz needs conversion factor
  final List<String> _countableUnits = ['serving', 'piece', 'slice', 'cup', 'tbsp', 'tsp'];
  late List<String> _allUnits;


  bool get _isEditing => widget.existingEntry != null;
  bool get _isCountableUnitSelected => _countableUnits.contains(_selectedServingUnit);
  bool _canParseApiServingWeightForSelectedUnit = false;


  @override
  void initState() {
    super.initState();
    _allUnits = [..._preciseUnits, ..._countableUnits];
    final entry = widget.existingEntry;

    _quantityController = TextEditingController(
      text: entry != null ? entry.servingSize.toStringAsFixed(entry.servingSize.truncateToDouble() == entry.servingSize ? 0 : 1) : '1'
    );
    // Initialize new controller
    _weightPerServingController = TextEditingController();


    if (entry != null) {
      _selectedServingUnit = entry.servingUnit;
      _selectedMealType = entry.mealType;
      _selectedLogTime = entry.loggedAt;
      // If editing, and it was a countable unit, try to see if a weight was implied or could be derived
      // This is complex, for now, rely on the initial setup
    } else {
      // Default logic for new entries
      final double? weightFromApi = NutritionCalculatorService.parseWeightFromServingString(widget.foodItem.servingSizeString);
      if (weightFromApi != null && widget.foodItem.servingSizeString!.toLowerCase().contains('serving')) { // Check if API string relates to 'serving'
        _selectedServingUnit = 'serving';
        _quantityController.text = '1';
        _canParseApiServingWeightForSelectedUnit = true;
      } else if (widget.foodItem.nutritionInfo != null) {
         _selectedServingUnit = 'g';
         _quantityController.text = '100';
         _canParseApiServingWeightForSelectedUnit = false; // Assume 'g' doesn't use API serving string for its own weight
      } else {
         _selectedServingUnit = 'serving';
         _quantityController.text = '1';
         _canParseApiServingWeightForSelectedUnit = false;
      }
    }

    _quantityController.addListener(_updateCalculatedNutrition);
    _weightPerServingController.addListener(_updateCalculatedNutrition); // Listen to new controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (mounted) _updateCalculatedNutrition();
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _weightPerServingController.dispose(); // Dispose new controller
    super.dispose();
  }

  void _updateCalculatedNutrition() {
    final double quantity = double.tryParse(_quantityController.text) ?? 0.0;
    // --- NEW: Get user-defined weight per serving ---
    final double? userDefinedWeight = double.tryParse(_weightPerServingController.text);
    // --- END NEW ---

    final calculator = ref.read(nutritionCalculatorServiceProvider);
    final results = calculator.calculateNutrition(
      baseNutrition: widget.foodItem.nutritionInfo,
      servingSize: quantity, // This is the 'number of servings/pieces/etc.' or g/ml amount
      servingUnit: _selectedServingUnit,
      servingSizeStringFromApi: widget.foodItem.servingSizeString,
      // --- NEW: Pass user-defined weight ---
      userDefinedWeightPerServing: userDefinedWeight,
      // --- END NEW ---
    );

    // Update flag based on current selections
    if (_isCountableUnitSelected && _selectedServingUnit == 'serving') {
         _canParseApiServingWeightForSelectedUnit = NutritionCalculatorService.parseWeightFromServingString(widget.foodItem.servingSizeString) != null;
    } else {
        _canParseApiServingWeightForSelectedUnit = false; // Not relevant or not 'serving' unit
    }


    setState(() { _calculatedNutrition = results; });
  }

  // _logEntry needs to use the correct servingSize and servingUnit
  Future<void> _logEntry() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (userId == null) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Error: Not logged in.'), backgroundColor: AppColors.error),); }
      setState(() => _isLoading = false); return;
    }

    double finalServingSize = double.parse(_quantityController.text);
    String finalServingUnit = _selectedServingUnit;

    // If a countable unit was chosen AND user provided a weight per serving,
    // then the log entry should reflect that total weight.
    final double? userDefinedWeight = double.tryParse(_weightPerServingController.text);
    if (_isCountableUnitSelected && userDefinedWeight != null && userDefinedWeight > 0) {
      finalServingSize = finalServingSize * userDefinedWeight; // e.g., 2 pieces * 50g/piece = 100
      finalServingUnit = 'g'; // Log as grams (or ml if that was the unit specified for weight)
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
      servingSize: finalServingSize, // Use potentially adjusted serving size
      servingUnit: finalServingUnit, // Use potentially adjusted unit
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
        if (kDebugMode) { print("ConfigureLogEntry: Entry updated (via delete+add)."); }
      } else {
        await notifier.addLogEntry(entryToSave);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('${entryToSave.foodItemName} ${_isEditing ? "updated" : "logged"} successfully!')),);
        Navigator.of(context).pop();
      }
    } catch (e) {
       if (mounted) { ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Error saving entry: ${e.toString()}'), backgroundColor: AppColors.error),); }
    } finally {
      if (mounted) { setState(() => _isLoading = false); }
    }
  }

  Future<void> _selectLogTime() async { /* ... (no change) ... */
    final DateTime? pickedDate = await showDatePicker( context: context, initialDate: _selectedLogTime, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)),);
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker( context: context, initialTime: TimeOfDay.fromDateTime(_selectedLogTime),);
      if (pickedTime != null) { setState(() { _selectedLogTime = DateTime( pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute,); });}
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat("#,##0.##");
    final caloriesText = _calculatedNutrition.calories > 0 ? numberFormat.format(_calculatedNutrition.calories) : '--';
    final proteinText = _calculatedNutrition.protein > 0 ? numberFormat.format(_calculatedNutrition.protein) : '--';
    final carbsText = _calculatedNutrition.carbs > 0 ? numberFormat.format(_calculatedNutrition.carbs) : '--';
    final fatText = _calculatedNutrition.fat > 0 ? numberFormat.format(_calculatedNutrition.fat) : '--';

    // Determine if user should be prompted for weight per serving
    bool showWeightPerServingInput = _isCountableUnitSelected && !_canParseApiServingWeightForSelectedUnit;
    if (_isEditing && widget.existingEntry!.servingUnit != 'g' && widget.existingEntry!.servingUnit != 'ml' && _isCountableUnitSelected) {
      // If editing an old item that wasn't 'g' or 'ml', and is countable, show the input.
      // The original `servingSize` was likely the count, and `calculatedNutrition` was per that count * the per-item nutrition.
      // This part is tricky. For now, if editing non-g/ml, always show the option to define weight.
      // We'd need to "reverse engineer" the per-item weight if we wanted to prefill _weightPerServingController.
      // Simpler: if it was '2 pieces' at 50kcal, editing will reset to calc per piece * qty
      showWeightPerServingInput = true;
    }


    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Log Entry' : 'Log ${widget.foodItem.name}', overflow: TextOverflow.ellipsis),
        leading: IconButton( icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop(),),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.foodItem.name, style: AppTextStyles.h2),
              if (widget.foodItem.brand != null) Padding( padding: const EdgeInsets.only(top: 4.0), child: Text(widget.foodItem.brand!, style: AppTextStyles.body.copyWith(color: Colors.grey)),),
              if (widget.foodItem.servingSizeString != null && widget.foodItem.servingSizeString!.isNotEmpty)
                 Padding( padding: const EdgeInsets.only(top: 8.0, bottom: 8.0), child: Text( 'Standard Serving (from packaging): ${widget.foodItem.servingSizeString}', style: AppTextStyles.small.copyWith(color: Colors.blueGrey, fontStyle: FontStyle.italic),),),

              const SizedBox(height: 16), // Reduced from 24
              Text('Amount Eaten', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Row( crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded( flex: 2, child: TextFormField( controller: _quantityController,
                      decoration: InputDecoration( labelText: _isCountableUnitSelected ? 'Number of...' : 'Quantity', border: const OutlineInputBorder(),),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [ FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),],
                      validator: (value) { if (value == null || value.isEmpty) return 'Required'; if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Invalid number'; return null; },),),
                  const SizedBox(width: 12),
                  Expanded( flex: 3, child: DropdownButtonFormField<String>( value: _selectedServingUnit, items: _allUnits.map((String unit) => DropdownMenuItem<String>( value: unit, child: Text(unit),)).toList(),
                      onChanged: (String? newValue) { if (newValue != null) { setState(() { _selectedServingUnit = newValue; }); _updateCalculatedNutrition();}},
                      decoration: const InputDecoration( labelText: 'Unit', border: OutlineInputBorder(),),),),],),

              // --- NEW: Conditional Weight Per Serving Input ---
              if (showWeightPerServingInput)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextFormField(
                    controller: _weightPerServingController,
                    decoration: InputDecoration(
                      labelText: 'Weight per $_selectedServingUnit (optional)',
                      hintText: 'e.g., 30 for 30g per slice',
                      border: const OutlineInputBorder(),
                      suffixText: 'g', // Assuming user defines weight in grams
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    // No validator, it's optional
                  ),
                ),
              // --- END NEW ---

              const SizedBox(height: 20),
              Text('Meal', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Wrap( spacing: 8.0, children: MealType.values.map((meal) { /* ... (ChoiceChips) ... */
                  return ChoiceChip( label: Text(meal.name[0].toUpperCase() + meal.name.substring(1)), selected: _selectedMealType == meal,
                    onSelected: (selected) { if (selected) { setState(() { _selectedMealType = meal; }); } },
                     selectedColor: AppColors.salmon.withOpacity(0.2), labelStyle: TextStyle( color: _selectedMealType == meal ? AppColors.salmon : Colors.black87,),
                     shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(16), side: BorderSide( color: _selectedMealType == meal ? AppColors.salmon : Colors.grey.shade300,)),
                     backgroundColor: Colors.white, showCheckmark: false, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),);}).toList(),),
              const SizedBox(height: 20),
              ListTile( contentPadding: EdgeInsets.zero, title: Text('Log Time', style: AppTextStyles.h3), subtitle: Text(DateFormat.yMd().add_jm().format(_selectedLogTime)), trailing: const Icon(Icons.edit_calendar_outlined), onTap: _selectLogTime,),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text('Calculated Nutrition', style: AppTextStyles.h3),
               const SizedBox(height: 4),
               // --- Updated Approximation Note ---
               if (_isCountableUnitSelected && !_canParseApiServingWeightForSelectedUnit && (double.tryParse(_weightPerServingController.text) ?? 0.0) <= 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                       'Note: Calculations are per 100g/ml. To get accurate totals for your "$_selectedServingUnit", please enter its weight in grams above, or adjust quantity if you know its total weight.',
                       style: AppTextStyles.caption.copyWith(color: Colors.orange.shade800, fontStyle: FontStyle.italic),
                    ),
                  )
               else if (_calculatedNutrition.calories <= 0 && widget.foodItem.nutritionInfo != null)
                   Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                       'Note: Could not calculate nutrition for selected unit. Displaying per 100g/ml values or ensure weight per unit is entered.',
                       style: AppTextStyles.caption.copyWith(color: Colors.red.shade800, fontStyle: FontStyle.italic),
                    ),
                  ),
               // --- End Updated Note ---
              Row( mainAxisAlignment: MainAxisAlignment.spaceAround, children: [ /* ... Macros ... */
                  _buildCalculatedMacro('Calories', caloriesText, AppColors.salmon), _buildCalculatedMacro('Protein', '${proteinText}g', AppColors.popBlue),
                  _buildCalculatedMacro('Carbs', '${carbsText}g', AppColors.popGreen), _buildCalculatedMacro('Fat', '${fatText}g', AppColors.popCoral),],),
               const SizedBox(height: 32),
              PrimaryButton( text: _isLoading ? 'Saving...' : (_isEditing ? 'Update Entry' : 'Log Entry'), onPressed: _isLoading ? null : _logEntry, isLoading: _isLoading,),
            ],
          ),
        ),
      ),
    );
  }

    Widget _buildCalculatedMacro(String label, String value, Color color) {
    return Column( crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text(label, style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey)), const SizedBox(height: 4),
        Text(value, style: AppTextStyles.body.copyWith(color: color, fontWeight: FontWeight.bold)),],);
  }
}