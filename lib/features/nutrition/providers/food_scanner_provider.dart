// lib/features/nutrition/providers/food_scanner_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import '../services/open_food_facts_service.dart';
import '../repositories/food_repository.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/analytics/crash_reporting_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../shared/providers/analytics_provider.dart';
import '../../../shared/providers/crash_reporting_provider.dart';

enum ScanningStatus {
  idle,
  scanning,
  processing,
  success,
  failure,
  networkError,
  productNotFound,
}

class FoodScannerState {
  final ScanningStatus status;
  final bool isLoading;
  final FoodItem? scannedItem;
  final String? errorMessage;
  final List<FoodItem> recentScans;
  final int scanCount; // For tracking free tier limits
  final int freeTierLimit; // Configurable scan limit
  final DateTime? lastScanDate;

  const FoodScannerState({
    this.status = ScanningStatus.idle,
    this.isLoading = false,
    this.scannedItem,
    this.errorMessage,
    this.recentScans = const [],
    this.scanCount = 0,
    this.freeTierLimit = 5, // Default free tier limit
    this.lastScanDate,
  });

  bool get isScanning => status == ScanningStatus.scanning;

  bool get canScanMore => scanCount < freeTierLimit || _isNewDay();

  bool get isScanLimitReached => !canScanMore;

  bool _isNewDay() {
    if (lastScanDate == null) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastScan = DateTime(
      lastScanDate!.year,
      lastScanDate!.month,
      lastScanDate!.day,
    );

    return today.isAfter(lastScan);
  }

  FoodScannerState copyWith({
    ScanningStatus? status,
    bool? isLoading,
    FoodItem? scannedItem,
    String? errorMessage,
    List<FoodItem>? recentScans,
    int? scanCount,
    int? freeTierLimit,
    DateTime? lastScanDate,
  }) {
    return FoodScannerState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      scannedItem: scannedItem ?? this.scannedItem,
      errorMessage: errorMessage,
      recentScans: recentScans ?? this.recentScans,
      scanCount: scanCount ?? this.scanCount,
      freeTierLimit: freeTierLimit ?? this.freeTierLimit,
      lastScanDate: lastScanDate ?? this.lastScanDate,
    );
  }
}

class FoodScannerNotifier extends StateNotifier<FoodScannerState> {
  final OpenFoodFactsService _openFoodFactsService;
  final FoodRepository _foodRepository;
  final AnalyticsService _analyticsService;
  final CrashReportingService _crashReportingService; // <-- Still needed

  FoodScannerNotifier({
    required OpenFoodFactsService openFoodFactsService,
    required FoodRepository foodRepository,
    required AnalyticsService analyticsService,
    required CrashReportingService crashReportingService, // <-- Passed in
  }) : _openFoodFactsService = openFoodFactsService,
       _foodRepository = foodRepository,
       _analyticsService = analyticsService,
       _crashReportingService = crashReportingService,
       super(const FoodScannerState());

  // Load initial data
  Future<void> initialize() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Load recent scans
      final recentScans = await _foodRepository.getRecentScans();

      // Load scan count for today
      final scanData = await _foodRepository.getTodayScanCount();

      _analyticsService.logEvent(
        name: 'scanner_initialized',
        parameters: {
          'recent_scans_count': recentScans.length,
          'today_scan_count': scanData.scanCount,
        },
      );

      state = state.copyWith(
        isLoading: false,
        recentScans: recentScans,
        scanCount: scanData.scanCount,
        lastScanDate: scanData.lastScanDate,
        status: ScanningStatus.idle,
      );
    } catch (e, stackTrace) {
      _crashReportingService.recordError(e, stackTrace);

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load scanner data: ${e.toString()}',
        status: ScanningStatus.failure,
      );
    }
  }

  // Start scanning mode
  void startScanning() {
    // Check scan limit
    if (state.isScanLimitReached) {
      _analyticsService.logEvent(name: 'free_tier_scan_limit_reached');

      state = state.copyWith(
        errorMessage:
            'You have reached your daily scan limit. Upgrade to Premium for unlimited scans.',
        status: ScanningStatus.failure,
      );
      return;
    }

    state = state.copyWith(
      status: ScanningStatus.scanning,
      scannedItem: null,
      errorMessage: null,
    );

    _analyticsService.logEvent(name: 'food_scanner_opened');
  }

  // Stop scanning mode
  void stopScanning() {
    state = state.copyWith(status: ScanningStatus.idle);
  }

  // Process barcode
  Future<void> processBarcode(String barcode) async {
    if (barcode.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Invalid barcode detected',
        status: ScanningStatus.failure,
      );
      return;
    }

    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        status: ScanningStatus.processing,
      );

      _analyticsService.logEvent(
        name: 'food_scan_attempt',
        parameters: {'barcode': barcode},
      );

      // Check network connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _analyticsService.logEvent(name: 'food_scan_network_error');

        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'No internet connection. Please check your connectivity and try again.',
          status: ScanningStatus.networkError,
        );
        return;
      }

      // Look up product
      final foodItem = await _openFoodFactsService.getProductByBarcode(barcode);

      if (foodItem != null) {
        // Save to repository
        await _foodRepository.saveFoodItem(foodItem);

        // Increment scan count
        final newScanCount = state.scanCount + 1;
        await _foodRepository.updateScanCount(newScanCount);

        // Update local state
        state = state.copyWith(
          isLoading: false,
          scannedItem: foodItem,
          scanCount: newScanCount,
          lastScanDate: DateTime.now(),
          recentScans: [foodItem, ...state.recentScans].take(10).toList(),
          status: ScanningStatus.success,
        );

        _analyticsService.logEvent(
          name: 'food_scan_success',
          parameters: {
            'barcode': barcode,
            'product_name': foodItem.name,
            'has_nutrition_info': foodItem.nutritionInfo != null,
          },
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Product not found. Please try another barcode.',
          status: ScanningStatus.productNotFound,
        );

        _analyticsService.logEvent(
          name: 'food_scan_product_not_found',
          parameters: {'barcode': barcode},
        );
      }
    } catch (e, stackTrace) {
      _crashReportingService.recordError(
        e,
        stackTrace,
        reason: 'Error during barcode scanning',
      );

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error scanning product: ${e.toString()}',
        status: ScanningStatus.failure,
      );

      _analyticsService.logEvent(
        name: 'food_scan_error',
        parameters: {'error': e.toString()},
      );
    }
  }

  // Clear current scan
  void clearScan() {
    state = state.copyWith(
      scannedItem: null,
      errorMessage: null,
      status: ScanningStatus.idle,
    );
  }

  // Retry scanning after an error
  void retryScanning() {
    startScanning();
  }
}

// Define providers
final foodScannerProvider =
    StateNotifierProvider<FoodScannerNotifier, FoodScannerState>((ref) {
      // Reads the SHARED providers to inject dependencies
      return FoodScannerNotifier(
        openFoodFactsService: ref.watch(openFoodFactsServiceProvider),
        foodRepository: ref.watch(foodRepositoryProvider),
        analyticsService: ref.watch(
          analyticsServiceProvider,
        ), // Reads shared provider
        crashReportingService: ref.watch(
          crashReportingServiceProvider,
        ), // Reads shared provider
      );
    });

// Dependencies
final openFoodFactsServiceProvider = Provider<OpenFoodFactsService>((ref) {
  // Reads the SHARED providers
  final analyticsService = ref.watch(analyticsServiceProvider);
  final crashReportingService = ref.watch(crashReportingServiceProvider);

  return OpenFoodFactsService(
    analyticsService: analyticsService,
    crashReportingService: crashReportingService,
  );
});

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepository(
    firestore: ref.watch(firestoreProvider),
    auth: ref.watch(authProvider),
    analyticsService: ref.watch(analyticsServiceProvider),
  );
});

// These would be defined elsewhere in your app
final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);
final authProvider = Provider((ref) => FirebaseAuth.instance);
