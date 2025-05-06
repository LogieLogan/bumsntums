// lib/features/nutrition/screens/quick_add_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

import '../models/food_log_entry.dart';
import '../providers/nutrition_provider.dart';
import '../../../shared/providers/firebase_providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/components/buttons/primary_button.dart';
// Import for DateFormat if used in this file
import 'package:intl/intl.dart';


class QuickAddScreen extends ConsumerStatefulWidget {
  final FoodLogEntry? existingEntry; // Optional: for editing

  const QuickAddScreen({super.key, this.existingEntry});

  @override
  ConsumerState<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends ConsumerState<QuickAddScreen> {
  final _formKey = GlobalKey<FormState>();
  // Initialize controllers
  late TextEditingController _foodNameController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;

  MealType _selectedMealType = MealType.snack;
  DateTime _selectedLogTime = DateTime.now();
  bool _isLoading = false;
  bool get _isEditing => widget.existingEntry != null;


  @override
  void initState() {
    super.initState();
    final entry = widget.existingEntry;
    _foodNameController = TextEditingController(text: entry?.foodItemName ?? '');
    _caloriesController = TextEditingController(text: entry != null ? entry.calculatedCalories.toStringAsFixed(0) : '');
    _proteinController = TextEditingController(text: entry != null && entry.calculatedProtein > 0 ? entry.calculatedProtein.toStringAsFixed(0) : '');
    _carbsController = TextEditingController(text: entry != null && entry.calculatedCarbs > 0 ? entry.calculatedCarbs.toStringAsFixed(0) : '');
    _fatController = TextEditingController(text: entry != null && entry.calculatedFat > 0 ? entry.calculatedFat.toStringAsFixed(0) : '');

    if (entry != null) {
      _selectedMealType = entry.mealType;
      _selectedLogTime = entry.loggedAt;
    }
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  // --- Updated _logQuickAddEntry for Edit/Add ---
  Future<void> _logQuickAddEntry() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (userId == null) {
      // ... (error handling) ...
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Error: Not logged in.'), backgroundColor: AppColors.error),); }
      setState(() => _isLoading = false);
      return;
    }

    final entryToSave = FoodLogEntry(
      id: _isEditing ? widget.existingEntry!.id : const Uuid().v4(),
      userId: userId,
      foodItemId: _isEditing ? widget.existingEntry!.foodItemId : 'quickadd-${const Uuid().v4()}',
      foodItemBarcode: _isEditing ? widget.existingEntry!.foodItemBarcode : null,
      foodItemName: _foodNameController.text.trim(),
      foodItemBrand: _isEditing ? widget.existingEntry!.foodItemBrand : 'Quick Add',
      loggedAt: _selectedLogTime,
      mealType: _selectedMealType,
      servingSize: 1, // Keep serving size/unit simple for quick add
      servingUnit: 'item',
      calculatedCalories: double.tryParse(_caloriesController.text) ?? 0.0,
      calculatedProtein: double.tryParse(_proteinController.text) ?? 0.0,
      calculatedCarbs: double.tryParse(_carbsController.text) ?? 0.0,
      calculatedFat: double.tryParse(_fatController.text) ?? 0.0,
    );

    try {
      final notifier = ref.read(nutritionDiaryProvider(userId).notifier);
      if (_isEditing) {
        // TODO: Add updateLogEntry method to NutritionDiaryNotifier and NutritionRepository
        // For now, we'll delete and re-add for simplicity if update isn't ready.
        // OR call a specific update method if it exists:
        // await notifier.updateLogEntry(entryToSave);
        // Temporary workaround: Delete old then add new (loses original ID if ID changes, but our ID is stable)
        await notifier.deleteLogEntry(widget.existingEntry!.id);
        await notifier.addLogEntry(entryToSave);
         if (kDebugMode) { print("Quick Add: Entry updated (via delete+add)."); }
      } else {
        await notifier.addLogEntry(entryToSave);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${entryToSave.foodItemName} ${_isEditing ? "updated" : "logged"} successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      // ... (error handling) ...
       if (mounted) { ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Error saving entry: ${e.toString()}'), backgroundColor: AppColors.error),); }
    } finally {
      if (mounted) { setState(() => _isLoading = false); }
    }
  }
  // --- End Updated _logQuickAddEntry ---


   Future<void> _selectLogTime() async {
    final DateTime? pickedDate = await showDatePicker( context: context, initialDate: _selectedLogTime, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)),);
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker( context: context, initialTime: TimeOfDay.fromDateTime(_selectedLogTime),);
      if (pickedTime != null) {
        setState(() { _selectedLogTime = DateTime( pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute,); });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Quick Entry' : 'Quick Add Food'),
        leading: IconButton( icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop(),),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_isEditing ? 'Update details and nutrition.' : 'Enter food details and estimated nutrition.', style: AppTextStyles.body),
              const SizedBox(height: 24),
              TextFormField( controller: _foodNameController, decoration: const InputDecoration(labelText: 'Food Name*', border: OutlineInputBorder()),
                validator: (value) { if (value == null || value.trim().isEmpty) { return 'Food name is required'; } return null; },
              ),
              const SizedBox(height: 16),
              TextFormField( controller: _caloriesController, decoration: const InputDecoration(labelText: 'Calories (kcal)*', border: OutlineInputBorder(), suffixText: 'kcal'),
                keyboardType: const TextInputType.numberWithOptions(decimal: false), inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) { if (value == null || value.isEmpty) { return 'Calories are required'; } if (int.tryParse(value) == null || int.parse(value) < 0) { return 'Invalid number'; } return null; },
              ),
              const SizedBox(height: 20),
              Text('Optional Macros (per item/entry)', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Row( children: [
                  Expanded( child: TextFormField( controller: _proteinController, decoration: const InputDecoration(labelText: 'Protein', border: OutlineInputBorder(), suffixText: 'g'), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],),),
                  const SizedBox(width: 12),
                  Expanded( child: TextFormField( controller: _carbsController, decoration: const InputDecoration(labelText: 'Carbs', border: OutlineInputBorder(), suffixText: 'g'), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],),),
                  const SizedBox(width: 12),
                  Expanded( child: TextFormField( controller: _fatController, decoration: const InputDecoration(labelText: 'Fat', border: OutlineInputBorder(), suffixText: 'g'), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],),),
              ],),
              const SizedBox(height: 20),
              Text('Meal', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Wrap( spacing: 8.0, children: MealType.values.map((meal) {
                  return ChoiceChip( label: Text(meal.name[0].toUpperCase() + meal.name.substring(1)), selected: _selectedMealType == meal,
                    onSelected: (selected) { if (selected) { setState(() { _selectedMealType = meal; }); } },
                     selectedColor: AppColors.salmon.withOpacity(0.2), labelStyle: TextStyle( color: _selectedMealType == meal ? AppColors.salmon : Colors.black87,),
                     shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(16), side: BorderSide( color: _selectedMealType == meal ? AppColors.salmon : Colors.grey.shade300,)),
                     backgroundColor: Colors.white, showCheckmark: false, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),);}).toList(),),
              const SizedBox(height: 20),
              ListTile( contentPadding: EdgeInsets.zero, title: Text('Log Time', style: AppTextStyles.h3), subtitle: Text(DateFormat.yMd().add_jm().format(_selectedLogTime)), trailing: const Icon(Icons.edit_calendar_outlined), onTap: _selectLogTime,),
              const SizedBox(height: 32),
              PrimaryButton( text: _isLoading ? 'Saving...' : (_isEditing ? 'Update Entry' : 'Log Quick Add'), onPressed: _isLoading ? null : _logQuickAddEntry, isLoading: _isLoading,),
            ],
          ),
        ),
      ),
    );
  }
}