// lib/features/nutrition/services/open_food_facts_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/analytics/crash_reporting_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:uuid/uuid.dart';

class OpenFoodFactsService {
  final String _baseUrl = 'https://world.openfoodfacts.org/api/v0';
  final AnalyticsService _analyticsService;
  final CrashReportingService _crashReportingService;
  final http.Client _httpClient;

  // Local cache for API responses to minimize redundant network calls
  final Map<String, FoodItem> _cache = {};

  // Request timeout duration
  final Duration _timeout = const Duration(seconds: 10);

  OpenFoodFactsService({
    required AnalyticsService analyticsService,
    required CrashReportingService crashReportingService,
    http.Client? httpClient,
  }) : _analyticsService = analyticsService,
       _crashReportingService = crashReportingService,
       _httpClient = httpClient ?? http.Client();

  Future<FoodItem?> getProductByBarcode(String barcode) async {
    try {
      if (_cache.containsKey(barcode)) {
        _analyticsService.logEvent(
          name: 'food_barcode_cache_hit',
          parameters: {'barcode': barcode},
        );
        return _cache[barcode];
      }

      _analyticsService.logEvent(
        name: 'food_barcode_scan',
        parameters: {'barcode': barcode},
      );

      if (barcode.isEmpty || barcode.length < 8) {
        _analyticsService.logEvent(
          name: 'food_invalid_barcode',
          parameters: {'barcode': barcode},
        );
        return null;
      }

      final response = await _httpClient
          .get(Uri.parse('$_baseUrl/product/$barcode.json'))
          .timeout(_timeout);

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 1) {
        // --- Logging API Response Quality (BEFORE parsing FoodItem) ---
        _logApiResponseQuality(data, barcode);
        // --- End Logging ---

        // Create new food item using the factory
        final foodItem = FoodItem.fromOpenFoodFacts(data);
        // Use the barcode as the ID if the top-level 'id' isn't reliable,
        // or ensure the factory handles ID generation if needed.
        // For consistency, let's assume the factory uses the barcode or generates one.

        _cache[barcode] = foodItem;

        // --- Convert Booleans to Strings for Analytics ---
        _analyticsService.logEvent(
          name: 'food_product_found',
          parameters: {
            'barcode': barcode,
            'product_name': foodItem.name, // Already string
            // Convert boolean to string
            'has_nutrition_info': (foodItem.nutritionInfo != null).toString(),
          },
        );
        // --- End Conversion ---

        return foodItem;
      } else if (response.statusCode == 200 && data['status'] == 0) {
        _analyticsService.logEvent(
          name: 'food_barcode_not_found',
          parameters: {'barcode': barcode},
        );
        return null;
      } else {
        _analyticsService.logEvent(
          name: 'food_api_error',
          parameters: {
            'barcode': barcode,
            'status_code': response.statusCode.toString(), // Ensure string
            'api_status':
                data['status']?.toString() ??
                'unknown', // Ensure string/handle null
          },
        );
        throw Exception(
          'API error: ${response.statusCode} - ${data['status_verbose'] ?? 'Unknown error'}',
        );
      }
    } on SocketException catch (e, stackTrace) {
      _crashReportingService.recordError(
        e,
        stackTrace,
        reason: 'Network error during Open Food Facts API call',
      );
      _analyticsService.logEvent(
        name: 'food_api_network_error',
        parameters: {'barcode': barcode, 'error': e.toString()},
      );
      rethrow;
    } on TimeoutException catch (e, stackTrace) {
      _crashReportingService.recordError(
        e,
        stackTrace,
        reason: 'Timeout during Open Food Facts API call',
      );
      _analyticsService.logEvent(
        name: 'food_api_timeout',
        parameters: {'barcode': barcode},
      );
      rethrow;
    } catch (e, stackTrace) {
      _crashReportingService.recordError(
        e,
        stackTrace,
        reason: 'Error during Open Food Facts API call',
      );
      if (kDebugMode) {
        print('Error fetching food product: $e');
      }
      _analyticsService.logEvent(
        name: 'food_api_error',
        parameters: {'barcode': barcode, 'error': e.toString()},
      );
      rethrow;
    }
  }

  // --- Updated _logApiResponseQuality Method ---
  void _logApiResponseQuality(Map<String, dynamic> data, String barcode) {
    // Ensure product data exists before accessing sub-fields
    final productData = data['product'] as Map<String, dynamic>?;
    if (productData == null) return; // Exit if no product data

    try {
      // Convert booleans to strings for analytics
      final Map<String, Object> dataQuality = {
        'has_name': (productData['product_name'] != null).toString(),
        'has_brand': (productData['brands'] != null).toString(),
        'has_image': (productData['image_url'] != null).toString(),
        'has_nutriments': (productData['nutriments'] != null).toString(),
        'barcode': barcode,
      };

      _analyticsService.logEvent(
        name: 'food_api_data_quality',
        parameters: dataQuality,
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error logging API data quality: $e");
      }
      // Ignore errors in this specific analytics logging
    }
  }

  // Clear cache for testing or memory management
  void clearCache() {
    _cache.clear();
    _analyticsService.logEvent(name: 'food_api_cache_cleared');
  }
}
