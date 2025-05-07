// lib/features/nutrition/screens/food_search_screen.dart
import 'package:bums_n_tums/features/nutrition/providers/food_scanner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../providers/food_search_provider.dart';
import '../models/food_search_result.dart';
import '../models/food_item.dart';
import 'configure_log_entry_screen.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add listener to trigger search via provider with debounce
    _searchController.addListener(() {
      ref.read(foodSearchProvider.notifier).search(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Function to handle tapping a search result
  Future<void> _onResultTap(FoodSearchResult result) async {
    // Show loading indicator while fetching full details
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: LoadingIndicator(message: "Loading details...")),
    );

    try {
      // Use the OFF service to get full FoodItem details using the barcode/code
      final offService = ref.read(openFoodFactsServiceProvider);
      final FoodItem? foodItem = await offService.getProductByBarcode(result.barcode);
      final navigator = Navigator.of(context); // Get navigator before async gap

      // Pop the loading indicator
      navigator.pop(); // Close loading dialog

      if (foodItem != null && mounted) {
        // Navigate to configuration screen
        navigator.pushReplacement( // Use pushReplacement to avoid stacking search screens
          MaterialPageRoute(
            builder: (_) => ConfigureLogEntryScreen(foodItem: foodItem),
          ),
        );
      } else if (mounted) {
        // Handle case where full details couldn't be fetched (though search found it)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not load full details for this item."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
       Navigator.of(context).pop(); // Close loading dialog on error
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Error loading details: $e"), backgroundColor: AppColors.error),
          );
       }
        if (kDebugMode) { print("Error fetching full details after search tap: $e"); }
    }
  }


  @override
  Widget build(BuildContext context) {
    // Watch the provider's state
    final searchState = ref.watch(foodSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Food'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search for food items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                 suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                         icon: const Icon(Icons.clear, color: Colors.grey),
                         tooltip: 'Clear search',
                         onPressed: () {
                           _searchController.clear();
                           // Clear results using provider
                           ref.read(foodSearchProvider.notifier).clearSearch();
                         },
                       )
                    : null,
              ),
              // No need for onSubmitted if search happens live via listener
            ),
          ),

          // Use AsyncValue.when to build UI based on state
          Expanded(
            child: searchState.when(
               // Initial/Empty Data State
               data: (results) {
                  if (_searchController.text.trim().isEmpty) {
                     return const Center(child: Text('Start typing to search for foods.'));
                  }
                  if (results.isEmpty) {
                     return const Center(child: Text('No results found.'));
                  }
                  // Build the results list
                  return _buildResultsList(results);
               },
               // Loading State
               loading: () => const Center(child: LoadingIndicator(message: 'Searching...')),
               // Error State
               error: (err, stack) {
                  if (kDebugMode) { print("Search Error: $err \n$stack");}
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error searching: ${err.toString()}', style: const TextStyle(color: AppColors.error)),
                    ),
                  );
               },
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget to build the results list ---
  Widget _buildResultsList(List<FoodSearchResult> results) {
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final item = results[index];
        return ListTile(
          leading: SizedBox( // Constrain image size
            width: 50,
            height: 50,
            child: item.imageUrl != null
                ? Image.network(
                    item.imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.fastfood_outlined, color: Colors.grey), // Placeholder icon
                  )
                : const Icon(Icons.fastfood_outlined, color: Colors.grey),
          ),
          title: Text(item.name),
          subtitle: Text(item.brand ?? 'Unknown brand'), // Show brand if available
          onTap: () => _onResultTap(item), // Call handler on tap
        );
      },
    );
  }
}