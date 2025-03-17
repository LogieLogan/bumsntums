// lib/features/nutrition/services/barcode_scanner_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/providers/analytics_provider.dart';

class BarcodeScannerService {
  final AnalyticsService _analyticsService;

  BarcodeScannerService({required AnalyticsService analyticsService})
      : _analyticsService = analyticsService;

  // Helper method to truncate strings for analytics
  String _truncateForAnalytics(String value, [int maxLength = 95]) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength)}...';
  }

  // Start the scanner and return the detected barcode
  Future<String?> scanBarcode(BuildContext context) async {
    String scanResult;

    try {
      _analyticsService.logEvent(name: 'barcode_scan_started');

      // Scanner configuration
      scanResult = await FlutterBarcodeScanner.scanBarcode(
        '#FF66C4', // Scanning line color (app pink)
        'Cancel', // Cancel button text
        true, // Flash enabled option
        ScanMode.BARCODE, // Only scan product barcodes
      );

      // FlutterBarcodeScanner returns "-1" when scan is canceled by user
      if (scanResult == '-1') {
        _analyticsService.logEvent(name: 'barcode_scan_canceled');
        return null;
      }

      _analyticsService.logEvent(
        name: 'barcode_scan_success',
        parameters: {'barcode': _truncateForAnalytics(scanResult)},
      );

      return scanResult;
    } on PlatformException catch (e) {
      final errorMsg = _truncateForAnalytics(e.toString());
      _analyticsService.logEvent(
        name: 'barcode_scan_platform_error',
        parameters: {'error': errorMsg},
      );
      debugPrint('Platform error during barcode scan: $e');
      return null;
    } catch (e) {
      final errorMsg = _truncateForAnalytics(e.toString());
      _analyticsService.logEvent(
        name: 'barcode_scan_error',
        parameters: {'error': errorMsg},
      );
      debugPrint('Error during barcode scan: $e');
      return null;
    }
  }

  // Validate barcode format
  bool isValidBarcode(String barcode) {
    // Basic validation: EAN/UPC barcodes should be numbers of appropriate length
    final validLengths = [8, 12, 13, 14]; // EAN-8, UPC-A, EAN-13, UPC-14
    
    return barcode.isNotEmpty && 
           RegExp(r'^\d+$').hasMatch(barcode) && 
           validLengths.contains(barcode.length);
  }
}

// Provider for the scanner service
final barcodeScannerServiceProvider = Provider<BarcodeScannerService>((ref) {
  return BarcodeScannerService(
    analyticsService: ref.watch(analyticsServiceProvider),
  );
});