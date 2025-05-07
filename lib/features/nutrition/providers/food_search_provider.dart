// lib/features/nutrition/providers/food_search_provider.dart
import 'dart:async';
import 'package:bums_n_tums/features/nutrition/providers/food_scanner_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/food_search_result.dart';

typedef FoodSearchState = AsyncValue<List<FoodSearchResult>>;

class FoodSearchNotifier extends AutoDisposeAsyncNotifier<List<FoodSearchResult>> {
  Timer? _debounce;

  @override
  FutureOr<List<FoodSearchResult>> build() {
    // --- Add ref.onDispose for cleanup ---
    ref.onDispose(() {
      _debounce?.cancel();
      if (kDebugMode) { print("FoodSearchNotifier disposed, debounce cancelled."); }
    });
    // --- End onDispose ---
    return []; // Initial state
  }

  Future<void> search(String query) async {
    final trimmedQuery = query.trim(); // Trim the query once
    if (trimmedQuery.isEmpty) {
       state = const AsyncData([]);
       _debounce?.cancel();
       return;
    }

    // Set loading immediately
    state = const AsyncLoading();

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
       // Call fetch when timer fires, no need to check mounted here
       await _fetchResults(trimmedQuery);
    });
  }

  void clearSearch() {
     _debounce?.cancel();
     state = const AsyncData([]);
  }

  Future<void> _fetchResults(String query) async {
     // Read service within the method where it's needed
     final offService = ref.read(openFoodFactsServiceProvider);
     if (kDebugMode) { print(">>> FoodSearchNotifier: Fetching results for '$query'"); }
     try {
       // Previous state is implicitly available via `state` if needed, but not required here
       final results = await offService.searchProducts(query);
       // Riverpod handles not updating state if disposed
       state = AsyncData(results);
        if (kDebugMode) { print(">>> FoodSearchNotifier: Setting DATA with ${results.length} results for '$query'"); }
     } catch (e, stack) {
       if (kDebugMode) { print(">>> FoodSearchNotifier: Setting ERROR for '$query': $e"); }
       // Riverpod handles not updating state if disposed
       state = AsyncError(e, stack);
     }
  }
}

// Provider definition remains the same
final foodSearchProvider =
    AsyncNotifierProvider.autoDispose<FoodSearchNotifier, List<FoodSearchResult>>(
  FoodSearchNotifier.new,
);