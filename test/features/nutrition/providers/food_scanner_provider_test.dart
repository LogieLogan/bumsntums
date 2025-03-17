// test/features/nutrition/providers/food_scanner_provider_test.dart
import 'package:bums_n_tums/features/nutrition/models/food_item.dart';
import 'package:bums_n_tums/features/nutrition/providers/food_scanner_provider.dart';
import 'package:bums_n_tums/features/nutrition/repositories/food_repository.dart';
import 'package:bums_n_tums/features/nutrition/services/open_food_facts_service.dart';
import 'package:bums_n_tums/shared/analytics/crash_reporting_service.dart';
import 'package:bums_n_tums/shared/analytics/firebase_analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([
  OpenFoodFactsService, 
  FoodRepository, 
  AnalyticsService,
  CrashReportingService,
])
import 'food_scanner_provider_test.mocks.dart';

void main() {
  late MockOpenFoodFactsService mockOpenFoodFactsService;
  late MockFoodRepository mockFoodRepository;
  late MockAnalyticsService mockAnalyticsService;
  late MockCrashReportingService mockCrashReportingService;
  late FoodScannerNotifier notifier;

  setUp(() {
    mockOpenFoodFactsService = MockOpenFoodFactsService();
    mockFoodRepository = MockFoodRepository();
    mockAnalyticsService = MockAnalyticsService();
    mockCrashReportingService = MockCrashReportingService();
    
    notifier = FoodScannerNotifier(
      openFoodFactsService: mockOpenFoodFactsService,
      foodRepository: mockFoodRepository,
      analyticsService: mockAnalyticsService,
      crashReportingService: mockCrashReportingService,
    );
  });

  group('FoodScannerNotifier', () {
    final mockFoodItem = FoodItem(
      id: 'test-id',
      barcode: '9876543210123',
      name: 'Test Product',
      brand: 'Test Brand',
    );

    final mockScanCount = ScanCountData(
      scanCount: 2,
      lastScanDate: DateTime.now(),
    );

    test('initial state should be correct', () {
      expect(notifier.state.status, equals(ScanningStatus.idle));
      expect(notifier.state.isLoading, equals(false));
      expect(notifier.state.scannedItem, equals(null));
      expect(notifier.state.errorMessage, equals(null));
      expect(notifier.state.recentScans, equals([]));
      expect(notifier.state.scanCount, equals(0));
    });

    test('initialize should load recent scans and scan count', () async {
      // Arrange
      when(mockFoodRepository.getRecentScans())
          .thenAnswer((_) async => [mockFoodItem]);
      
      when(mockFoodRepository.getTodayScanCount())
          .thenAnswer((_) async => mockScanCount);

      // Act
      await notifier.initialize();

      // Assert
      expect(notifier.state.isLoading, equals(false));
      expect(notifier.state.recentScans, equals([mockFoodItem]));
      expect(notifier.state.scanCount, equals(2));
      expect(notifier.state.lastScanDate, equals(mockScanCount.lastScanDate));
      
      verify(mockFoodRepository.getRecentScans()).called(1);
      verify(mockFoodRepository.getTodayScanCount()).called(1);
      verify(mockAnalyticsService.logEvent(
        name: 'scanner_initialized',
        parameters: any,
      )).called(1);
    });

    test('startScanning should set state to scanning', () {
      // Act
      notifier.startScanning();

      // Assert
      expect(notifier.state.status, equals(ScanningStatus.scanning));
      expect(notifier.state.scannedItem, equals(null));
      expect(notifier.state.errorMessage, equals(null));
      
      verify(mockAnalyticsService.logEvent(name: 'food_scanner_opened')).called(1);
    });

    test('startScanning should show error when scan limit is reached', () {
      // Arrange
      notifier = FoodScannerNotifier(
        openFoodFactsService: mockOpenFoodFactsService,
        foodRepository: mockFoodRepository,
        analyticsService: mockAnalyticsService,
        crashReportingService: mockCrashReportingService,
      );
      
      // Set state to have reached scan limit
      notifier = notifier.updateState((state) => state.copyWith(
        scanCount: 5,
        freeTierLimit: 5,
      ));

      // Act
      notifier.startScanning();

      // Assert
      expect(notifier.state.status, equals(ScanningStatus.failure));
      expect(notifier.state.errorMessage, contains('limit'));
      
      verify(mockAnalyticsService.logEvent(
        name: 'free_tier_scan_limit_reached',
      )).called(1);
    });

    test('processBarcode should handle a successful scan', () async {
      // Arrange
      const testBarcode = '9876543210123';
      
      when(mockOpenFoodFactsService.getProductByBarcode(testBarcode))
          .thenAnswer((_) async => mockFoodItem);
      
      when(mockFoodRepository.saveFoodItem(mockFoodItem))
          .thenAnswer((_) async => {});
      
      when(mockFoodRepository.updateScanCount(1))
          .thenAnswer((_) async => {});

      // Act
      await notifier.processBarcode(testBarcode);

      // Assert
      expect(notifier.state.status, equals(ScanningStatus.success));
      expect(notifier.state.isLoading, equals(false));
      expect(notifier.state.scannedItem, equals(mockFoodItem));
      expect(notifier.state.scanCount, equals(1));
      expect(notifier.state.recentScans, contains(mockFoodItem));
      
      verify(mockOpenFoodFactsService.getProductByBarcode(testBarcode)).called(1);
      verify(mockFoodRepository.saveFoodItem(mockFoodItem)).called(1);
      verify(mockFoodRepository.updateScanCount(1)).called(1);
      verify(mockAnalyticsService.logEvent(
        name: 'food_scan_attempt',
        parameters: {'barcode': testBarcode},
      )).called(1);
      verify(mockAnalyticsService.logEvent(
        name: 'food_scan_success',
        parameters: any,
      )).called(1);
    });

    test('processBarcode should handle product not found', () async {
      // Arrange
      const testBarcode = '9876543210123';
      
      when(mockOpenFoodFactsService.getProductByBarcode(testBarcode))
          .thenAnswer((_) async => null);

      // Act
      await notifier.processBarcode(testBarcode);

      // Assert
      expect(notifier.state.status, equals(ScanningStatus.productNotFound));
      expect(notifier.state.isLoading, equals(false));
      expect(notifier.state.scannedItem, equals(null));
      expect(notifier.state.errorMessage, contains('not found'));
      
      verify(mockOpenFoodFactsService.getProductByBarcode(testBarcode)).called(1);
      verify(mockAnalyticsService.logEvent(
        name: 'food_scan_product_not_found',
        parameters: {'barcode': testBarcode},
      )).called(1);
    });

    test('processBarcode should handle errors', () async {
      // Arrange
      const testBarcode = '9876543210123';
      final testError = Exception('Test error');
      
      when(mockOpenFoodFactsService.getProductByBarcode(testBarcode))
          .thenThrow(testError);

      // Act
      await notifier.processBarcode(testBarcode);

      // Assert
      expect(notifier.state.status, equals(ScanningStatus.failure));
      expect(notifier.state.isLoading, equals(false));
      expect(notifier.state.scannedItem, equals(null));
      expect(notifier.state.errorMessage, contains('Error scanning product'));
      
      verify(mockOpenFoodFactsService.getProductByBarcode(testBarcode)).called(1);
      verify(mockCrashReportingService.recordError(
        testError,
        any,
        reason: any,
      )).called(1);
      verify(mockAnalyticsService.logEvent(
        name: 'food_scan_error',
        parameters: any,
      )).called(1);
    });

    test('clearScan should reset scan data', () {
      // Arrange
      notifier = notifier.updateState((state) => state.copyWith(
        scannedItem: mockFoodItem,
        errorMessage: 'Some error',
        status: ScanningStatus.success,
      ));

      // Act
      notifier.clearScan();

      // Assert
      expect(notifier.state.status, equals(ScanningStatus.idle));
      expect(notifier.state.scannedItem, equals(null));
      expect(notifier.state.errorMessage, equals(null));
    });

    test('retryScanning should restart scanning', () {
      // Arrange
      notifier = notifier.updateState((state) => state.copyWith(
        status: ScanningStatus.failure,
        errorMessage: 'Some error',
      ));

      // Act
      notifier.retryScanning();

      // Assert
      expect(notifier.state.status, equals(ScanningStatus.scanning));
      verify(mockAnalyticsService.logEvent(name: 'food_scanner_opened')).called(1);
    });
  });
}

// Extension for testing to update state more easily
extension on FoodScannerNotifier {
  FoodScannerNotifier updateState(FoodScannerState Function(FoodScannerState) update) {
    state = update(state);
    return this;
  }
}