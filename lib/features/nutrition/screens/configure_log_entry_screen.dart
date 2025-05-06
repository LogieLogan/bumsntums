// lib/features/nutrition/screens/configure_log_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart'; // Added kDebugMode import

import '../models/food_item.dart';
import '../models/food_log_entry.dart';
import '../providers/nutrition_provider.dart';
// --- Import the new Service ---
import '../services/nutrition_calculator_service.dart';
// --- End Import ---
import '../../../shared/providers/firebase_providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/components/buttons/primary_button.dart';
import '../services/nutrition_calculator_service.dart';

class ConfigureLogEntryScreen extends ConsumerStatefulWidget {
  final FoodItem foodItem;

  const ConfigureLogEntryScreen({super.key, required this.foodItem});

  @override
  ConsumerState<ConfigureLogEntryScreen> createState() =>
      _ConfigureLogEntryScreenState();
}

class _ConfigureLogEntryScreenState
    extends ConsumerState<ConfigureLogEntryScreen> {

   // ... (formKey, controllers, state variables remain the same) ...
   final _formKey = GlobalKey<FormState>();
   final _servingSizeController = TextEditingController(text: '1');
   String _selectedServingUnit = 'serving';
   MealType _selectedMealType = MealType.snack;
   DateTime _selectedLogTime = DateTime.now();
   CalculatedNutrition _calculatedNutrition = const CalculatedNutrition();
   bool _isLoading = false;
   final List<String> _servingUnits = [
    'serving', 'g', 'ml', 'oz', 'piece', 'slice', 'cup', 'tbsp', 'tsp'
   ];


   @override
  void initState() {
    super.initState();
    // Prioritize 'serving' if API provides a parsable weight for it
        final double? weightFromApi = NutritionCalculatorService.parseWeightFromServingString(widget.foodItem.servingSizeString);

    if (weightFromApi != null) {
      _selectedServingUnit = 'serving'; // Default to 'serving' if API provides its weight
      _servingSizeController.text = '1'; // Default to 1 serving
    } else if (widget.foodItem.nutritionInfo != null) {
       _selectedServingUnit = 'g'; // Fallback to 'g' if nutrition info exists but serving weight doesn't
       _servingSizeController.text = '100';
    } else {
       _selectedServingUnit = 'serving'; // Default if no info at all
       _servingSizeController.text = '1';
    }

    _servingSizeController.addListener(_updateCalculatedNutrition);
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (mounted) {
          _updateCalculatedNutrition();
       }
    });
  }

   // dispose remains the same
   @override
  void dispose() {
    _servingSizeController.removeListener(_updateCalculatedNutrition);
    _servingSizeController.dispose();
    super.dispose();
  }


  // --- Updated Method to pass servingSizeStringFromApi ---
  void _updateCalculatedNutrition() {
    final double servingSize = double.tryParse(_servingSizeController.text) ?? 0.0;
    final calculator = ref.read(nutritionCalculatorServiceProvider);

    final results = calculator.calculateNutrition(
      baseNutrition: widget.foodItem.nutritionInfo,
      servingSize: servingSize,
      servingUnit: _selectedServingUnit,
      servingSizeStringFromApi: widget.foodItem.servingSizeString, // Pass the string here
    );

    setState(() { _calculatedNutrition = results; });
  }
  // --- End Updated Method ---

  // --- _logEntry, _selectLogTime, build, _buildCalculatedMacro remain the same ---
  // Paste the existing methods here

   Future<void> _logEntry() async {
    if (!_formKey.currentState!.validate()) { return; }
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (userId == null) {
       if(mounted){
          ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Error: Not logged in.'), backgroundColor: AppColors.error),);
       }
      setState(() => _isLoading = false);
      return;
    }

    final double servingSize = double.parse(_servingSizeController.text);

    final newEntry = FoodLogEntry(
      id: const Uuid().v4(),
      userId: userId,
      foodItemId: widget.foodItem.id,
      foodItemBarcode: widget.foodItem.barcode,
      foodItemName: widget.foodItem.name,
      foodItemBrand: widget.foodItem.brand,
      loggedAt: _selectedLogTime,
      mealType: _selectedMealType,
      servingSize: servingSize,
      servingUnit: _selectedServingUnit,
      calculatedCalories: _calculatedNutrition.calories,
      calculatedProtein: _calculatedNutrition.protein,
      calculatedCarbs: _calculatedNutrition.carbs,
      calculatedFat: _calculatedNutrition.fat,
    );

    try {
      await ref.read(nutritionDiaryProvider(userId).notifier).addLogEntry(newEntry);
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('${widget.foodItem.name} logged successfully!')),);
          Navigator.of(context).pop();
      }
    } catch (e) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Error logging food: ${e.toString()}'), backgroundColor: AppColors.error),);
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
    final caloriesText = _calculatedNutrition.calories > 0 ? numberFormat.format(_calculatedNutrition.calories) : '--';
    final proteinText = _calculatedNutrition.protein > 0 ? numberFormat.format(_calculatedNutrition.protein) : '--';
    final carbsText = _calculatedNutrition.carbs > 0 ? numberFormat.format(_calculatedNutrition.carbs) : '--';
    final fatText = _calculatedNutrition.fat > 0 ? numberFormat.format(_calculatedNutrition.fat) : '--';

    // Determine if calculation is likely approximate
    bool isApproximate = _calculatedNutrition.calories > 0 && // Only show if *some* calculation happened
                         _selectedServingUnit != 'g' &&
                         _selectedServingUnit != 'ml';


    return Scaffold(
      appBar: AppBar(
        title: Text('Log ${widget.foodItem.name}', overflow: TextOverflow.ellipsis),
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
                  child: Text(widget.foodItem.brand!, style: AppTextStyles.body.copyWith(color: Colors.grey)),
                ),
              // Show original serving size string from API if available
              if (widget.foodItem.servingSizeString != null && widget.foodItem.servingSizeString!.isNotEmpty)
                 Padding(
                   padding: const EdgeInsets.only(top: 8.0),
                   child: Text(
                     'Standard Serving: ${widget.foodItem.servingSizeString}',
                     style: AppTextStyles.small.copyWith(color: Colors.blueGrey, fontStyle: FontStyle.italic),
                   ),
                 ),

              const SizedBox(height: 24),

              Text('Serving Size', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _servingSizeController,
                      decoration: const InputDecoration( labelText: 'Quantity', border: OutlineInputBorder(),),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [ FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _selectedServingUnit,
                      items: _servingUnits.map((String unit) {
                        return DropdownMenuItem<String>( value: unit, child: Text(unit),);
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() { _selectedServingUnit = newValue; });
                           // Update calculation when unit changes
                          _updateCalculatedNutrition();
                        }
                      },
                      decoration: const InputDecoration( labelText: 'Unit', border: OutlineInputBorder(),),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text('Meal', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: MealType.values.map((meal) {
                  return ChoiceChip(
                    label: Text(meal.name[0].toUpperCase() + meal.name.substring(1)),
                    selected: _selectedMealType == meal,
                    onSelected: (selected) { if (selected) { setState(() { _selectedMealType = meal; }); } },
                    selectedColor: AppColors.salmon.withOpacity(0.2),
                    labelStyle: TextStyle( color: _selectedMealType == meal ? AppColors.salmon : Colors.black87,),
                     shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(16), side: BorderSide( color: _selectedMealType == meal ? AppColors.salmon : Colors.grey.shade300,)),
                     backgroundColor: Colors.white,
                     showCheckmark: false,
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              ListTile(
                 contentPadding: EdgeInsets.zero,
                 title: Text('Log Time', style: AppTextStyles.h3),
                 subtitle: Text(DateFormat.yMd().add_jm().format(_selectedLogTime)),
                 trailing: const Icon(Icons.edit_calendar_outlined),
                 onTap: _selectLogTime,
              ),


              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              Text('Calculated Nutrition', style: AppTextStyles.h3),
               const SizedBox(height: 4),
               // Show approximation note only if relevant
               if (isApproximate)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                       'Note: Calculations based on per 100g/ml data. Values for unit "${_selectedServingUnit}" may be approximate.',
                       style: AppTextStyles.caption.copyWith(color: Colors.orange.shade800, fontStyle: FontStyle.italic),
                    ),
                  ),
               if (_calculatedNutrition.calories <= 0 && widget.foodItem.nutritionInfo != null)
                   Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                       'Note: Could not calculate nutrition for the selected unit "${_selectedServingUnit}". Displaying per 100g/ml values instead.',
                       style: AppTextStyles.caption.copyWith(color: Colors.red.shade800, fontStyle: FontStyle.italic),
                    ),
                  ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCalculatedMacro('Calories', caloriesText, AppColors.salmon),
                  _buildCalculatedMacro('Protein', '${proteinText}g', AppColors.popBlue),
                  _buildCalculatedMacro('Carbs', '${carbsText}g', AppColors.popGreen),
                  _buildCalculatedMacro('Fat', '${fatText}g', AppColors.popCoral),
                ],
              ),

               const SizedBox(height: 32),

              PrimaryButton(
                text: _isLoading ? 'Logging...' : 'Log Entry',
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
        Text(label, style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.body.copyWith(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

} // End State class