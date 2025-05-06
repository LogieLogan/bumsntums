// lib/features/nutrition/screens/nutrition_screen.dart
import 'package:bums_n_tums/features/nutrition/providers/food_scanner_provider.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

// Import Nutrition features
import '../providers/nutrition_provider.dart';
import '../models/food_log_entry.dart';
import '../models/food_item.dart';
import '../models/estimated_goals.dart'; // Import EstimatedGoals
import '../services/barcode_scanner_service.dart';
import '../services/open_food_facts_service.dart';
import 'configure_log_entry_screen.dart';
import '../widgets/food_log_entry_tile.dart';

// Import Shared features
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/providers/firebase_providers.dart';


// --- NutritionScreen Widget Definition ---
class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}


class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  // State, initState, date/log methods remain the same
  bool _isScanningOrFetching = false;

  @override
  void initState() { super.initState(); }

  void _changeDate(int days) {
    final userId = ref.read(userIdProvider);
    if (userId == null) { if (kDebugMode) { print("Cannot change date: User ID is null."); } return; }
    final currentSelectedDate = ref.read(nutritionDiaryProvider(userId)).selectedDate;
    final newDate = currentSelectedDate.add(Duration(days: days));
    ref.read(nutritionDiaryProvider(userId).notifier).changeDate(newDate);
  }

  Future<void> _selectDate() async {
    final userId = ref.read(userIdProvider);
    if (userId == null) { if (kDebugMode) { print("Cannot select date: User ID is null."); } return; }
    final currentSelectedDate = ref.read(nutritionDiaryProvider(userId)).selectedDate;
    final DateTime? picked = await showDatePicker( context: context, initialDate: currentSelectedDate, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)),);
    if (picked != null && picked != currentSelectedDate && mounted) {
      ref.read(nutritionDiaryProvider(userId).notifier).changeDate(picked);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final selectedDay = DateTime(date.year, date.month, date.day);
    if (selectedDay == today) return 'Today';
    if (selectedDay == yesterday) return 'Yesterday';
    return DateFormat('EEEE, MMM d').format(date);
  }

  void _showLogOptions() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder( borderRadius: BorderRadius.vertical(top: Radius.circular(20)),),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
          child: Wrap( children: <Widget>[
              Padding( padding: const EdgeInsets.only(bottom: 15.0, left: 10.0), child: Text("Log Food", style: AppTextStyles.h3),),
              ListTile( leading: const Icon(Icons.qr_code_scanner_outlined, color: AppColors.offWhite), title: const Text('Scan Barcode'), onTap: () { Navigator.pop(context); _startScan(); }, ),
          ],),
        );
      },
    );
  }

  Future<void> _startScan() async {
    if (_isScanningOrFetching) return;
    setState(() => _isScanningOrFetching = true);
    final barcodeService = ref.read(barcodeScannerServiceProvider);
    final offService = ref.read(openFoodFactsServiceProvider);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final barcode = await barcodeService.scanBarcode(context);
    if (barcode != null && barcodeService.isValidBarcode(barcode)) {
       if (kDebugMode) { print("Barcode scanned: $barcode. Fetching details..."); }
      try {
        final FoodItem? foodItem = await offService.getProductByBarcode(barcode);
        if (foodItem != null && mounted) {
          navigator.push(MaterialPageRoute( builder: (_) => ConfigureLogEntryScreen(foodItem: foodItem),));
        } else if (mounted) {
           if (kDebugMode) { print("Product not found for barcode: $barcode"); }
           scaffoldMessenger.showSnackBar( const SnackBar( content: Text("Product details not found."), backgroundColor: Colors.orange,),);
        }
      } catch (e, stack) {
         if (kDebugMode) { print("Error fetching/processing barcode $barcode: $e\n$stack"); }
         if (mounted) { scaffoldMessenger.showSnackBar( SnackBar(content: Text("Error fetching details: ${e.toString()}"), backgroundColor: AppColors.error,),);}
      }
    } else if (barcode != null) {
        if (kDebugMode) { print("Invalid barcode format scanned: $barcode"); }
        if (mounted) { scaffoldMessenger.showSnackBar( const SnackBar(content: Text("Invalid barcode format scanned."), backgroundColor: Colors.orange,),);}
    } else {
        if (kDebugMode) { print("Scan cancelled or failed."); }
    }
    if (mounted) { setState(() => _isScanningOrFetching = false); }
  }

  // --- Build Method (using diaryState) ---
  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(userIdProvider);
    if (userId == null) {
      if (kDebugMode) { print("<<< NutritionScreen Build: userId is NULL"); }
      return const Scaffold(body: Center(child: LoadingIndicator(message: "Authenticating...")));
    }

    final diaryState = ref.watch(nutritionDiaryProvider(userId));
    if (kDebugMode) { /* Debug prints from previous step */ }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Diary'),
        centerTitle: true,
        actions: [
          IconButton( icon: const Icon(Icons.calendar_today_outlined), tooltip: 'Select Date', onPressed: _selectDate,)
        ],
      ),
      body: Column(
        children: [
          _buildDateNavigator(diaryState.selectedDate),
          const Divider(height: 1),
          // Pass both log state and goal state to summary card
          _buildDailySummaryCard(diaryState.logEntriesState, diaryState.estimatedGoalsState),
          Expanded(
            child: _buildLoggedItemsList(diaryState.logEntriesState),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanningOrFetching ? null : _showLogOptions,
        tooltip: 'Log Food',
        backgroundColor: _isScanningOrFetching ? Colors.grey : AppColors.salmon,
        child: _isScanningOrFetching ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5,)) : const Icon(Icons.add),
      ),
    );
  }
  // --- End Build Method ---


  // --- UI Builder Methods ---

  Widget _buildDateNavigator(DateTime selectedDate) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton( icon: const Icon(Icons.chevron_left), onPressed: () => _changeDate(-1), tooltip: 'Previous Day',),
          Text( _formatDate(selectedDate), style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w500),),
          IconButton( icon: const Icon(Icons.chevron_right), onPressed: () => _changeDate(1), tooltip: 'Next Day',),
        ],
      ),
    );
  }

  // --- Updated Daily Summary Card ---
  Widget _buildDailySummaryCard(
    AsyncValue<List<FoodLogEntry>> logState,
    AsyncValue<EstimatedGoals> goalState,
  ) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             // Add Row for Title and Info Icon
             Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text('Daily Summary', style: AppTextStyles.h3),
                   goalState.maybeWhen(
                      data: (goals) => goals.areMet // Only show info icon if goals were estimated
                         ? IconButton(
                              icon: const Icon(Icons.info_outline, color: Colors.grey),
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(), // Remove default padding
                              tooltip: 'Goals estimated based on your profile.',
                              onPressed: () {
                                 // TODO: Show a dialog explaining goal estimation
                                 showDialog(context: context, builder: (context) => AlertDialog(
                                    title: const Text("Estimated Goals"),
                                    content: const Text("These nutritional goals are estimated based on your profile (age, weight, height, activity level, fitness goal). Adjustments can be made in settings (feature coming soon!). Focus on consistency!"),
                                    actions: [TextButton(child: const Text("OK"), onPressed: () => Navigator.of(context).pop())],
                                 ));
                              },
                           )
                         : const SizedBox.shrink(), // Hide icon if using defaults
                      orElse: () => const SizedBox.shrink(), // Hide icon while loading/error
                   ),
                ],
             ),
            const SizedBox(height: 16),

            // Combine goal and log states for display
            // Show loading if either is loading
            if (logState is AsyncLoading || goalState is AsyncLoading)
              const Row(
                 mainAxisAlignment: MainAxisAlignment.spaceAround,
                 children: [
                    CircularProgressIndicator(strokeWidth: 2.0),
                    CircularProgressIndicator(strokeWidth: 2.0),
                    CircularProgressIndicator(strokeWidth: 2.0),
                    CircularProgressIndicator(strokeWidth: 2.0),
                 ],
              )
            // Show error if either has an error
            else if (logState is AsyncError || goalState is AsyncError)
              Text(
                 'Error loading summary data',
                 style: AppTextStyles.body.copyWith(color: AppColors.error),
              )
            // Otherwise, show data (assuming both have loaded successfully)
            else
              Builder(builder: (context) { // Use Builder to ensure data is available
                 final logs = logState.asData?.value ?? []; // Get logs or empty list
                 final goals = goalState.asData?.value ?? EstimatedGoals.defaults(); // Get goals or defaults

                 // Calculate totals
                 double totalCalories = logs.fold(0.0, (sum, entry) => sum + entry.calculatedCalories);
                 double totalProtein = logs.fold(0.0, (sum, entry) => sum + entry.calculatedProtein);
                 double totalCarbs = logs.fold(0.0, (sum, entry) => sum + entry.calculatedCarbs);
                 double totalFat = logs.fold(0.0, (sum, entry) => sum + entry.calculatedFat);

                 return Row(
                   mainAxisAlignment: MainAxisAlignment.spaceAround,
                   children: [
                     _buildMacroSummary('Calories', totalCalories.toStringAsFixed(0), goals.targetCalories.toString(), AppColors.salmon),
                     _buildMacroSummary('Protein', '${totalProtein.toStringAsFixed(0)}g', '${goals.targetProtein}g', AppColors.popBlue),
                     _buildMacroSummary('Carbs', '${totalCarbs.toStringAsFixed(0)}g', '${goals.targetCarbs}g', AppColors.popGreen),
                     _buildMacroSummary('Fat', '${totalFat.toStringAsFixed(0)}g', '${goals.targetFat}g', AppColors.popCoral),
                   ],
                 );
              }),
          ],
        ),
      ),
    );
  }
  // --- End Updated Daily Summary Card ---


   Widget _buildMacroSummary(String label, String value, String goal, Color color) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Center align text
        children: [
          Text(label, style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey)),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.h3.copyWith(color: color), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text('Goal: $goal', style: AppTextStyles.caption.copyWith(color: AppColors.mediumGrey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // _buildLoggedItemsList remains the same as previous correct version
   Widget _buildLoggedItemsList(AsyncValue<List<FoodLogEntry>> logState) {
    return logState.when(
      data: (logs) {
        if (logs.isEmpty) { return Center( child: Padding( padding: const EdgeInsets.symmetric( vertical: 32.0, horizontal: 20.0,), child: Text( "Nothing logged for this day yet.\nTap '+' to add an item!", style: AppTextStyles.body.copyWith(color: Colors.grey.shade600), textAlign: TextAlign.center,),),); }
        final groupedLogs = groupBy(logs, (FoodLogEntry entry) => entry.mealType,);
        const mealOrder = [ MealType.breakfast, MealType.lunch, MealType.dinner, MealType.snack, ];
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          children: mealOrder.map((mealType) {
                final entriesForMeal = groupedLogs[mealType] ?? [];
                if (entriesForMeal.isEmpty) { return const SizedBox.shrink(); }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding( padding: const EdgeInsets.only( top: 16.0, bottom: 8.0, left: 8.0,), child: Text( mealType.name[0].toUpperCase() + mealType.name.substring(1), style: AppTextStyles.h3,),),
                    Column( children: entriesForMeal.map((entry) => FoodLogEntryTile( entry: entry,)).toList(),),
                    const Divider(height: 24, thickness: 0.5),
                  ],
                );
              }).toList(),
        );
      },
      loading: () => const Center(child: LoadingIndicator(message: "Loading log...")),
      error: (err, stack) => Center( child: Padding( padding: const EdgeInsets.all(16.0), child: Text( "Error loading log: ${err.toString()}", style: const TextStyle(color: AppColors.error),),),),
    );
  }

} // End of _NutritionScreenState


// --- Providers userIdProvider, httpClientProvider remain the same ---
final userIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(firebaseAuthProvider);
  return authState.currentUser?.uid;
});
final httpClientProvider = Provider((ref) => http.Client());