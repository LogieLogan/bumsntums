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
  }) : 
    _analyticsService = analyticsService,
    _crashReportingService = crashReportingService,
    _httpClient = httpClient ?? http.Client();
  
  Future<FoodItem?> getProductByBarcode(String barcode) async {
    try {
      // Check cache first
      if (_cache.containsKey(barcode)) {
        _analyticsService.logEvent(
          name: 'food_barcode_cache_hit', 
          parameters: {'barcode': barcode}
        );
        return _cache[barcode];
      }
      
      _analyticsService.logEvent(
        name: 'food_barcode_scan', 
        parameters: {'barcode': barcode}
      );
      
      // Add validation for the barcode
      if (barcode.isEmpty || barcode.length < 8) {
        _analyticsService.logEvent(
          name: 'food_invalid_barcode',
          parameters: {'barcode': barcode}
        );
        return null;
      }
      
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/product/$barcode.json'),
      ).timeout(_timeout);

      final data = json.decode(response.body);
      
      // Check status code and API response status
      if (response.statusCode == 200 && data['status'] == 1) {
        _logApiResponse(data, barcode);
        
        // Generate a unique ID for this food item
        final id = const Uuid().v4();
        
        // Create new food item from API data
        final foodItem = FoodItem(
          id: id,
          barcode: barcode,
          name: data['product']['product_name'] ?? 'Unknown Product',
          brand: data['product']['brands'],
          imageUrl: data['product']['image_url'],
          nutritionInfo: data['product']['nutriments'] != null
              ? NutritionInfo.fromOpenFoodFacts(data['product']['nutriments'])
              : null,
        );
        
        // Cache the result
        _cache[barcode] = foodItem;
        
        _analyticsService.logEvent(
          name: 'food_product_found',
          parameters: {
            'barcode': barcode,
            'product_name': foodItem.name,
            'has_nutrition_info': foodItem.nutritionInfo != null,
          }
        );
        
        return foodItem;
      } else if (response.statusCode == 200 && data['status'] == 0) {
        // Product not found in the database
        _analyticsService.logEvent(
          name: 'food_barcode_not_found', 
          parameters: {'barcode': barcode}
        );
        return null;
      } else {
        // API returned an error
        _analyticsService.logEvent(
          name: 'food_api_error', 
          parameters: {
            'barcode': barcode,
            'status_code': response.statusCode.toString(),
            'api_status': data['status'].toString()
          }
        );
        throw Exception('API error: ${response.statusCode} - ${data['status_verbose']}');
      }
    } on SocketException catch (e, stackTrace) {
      // Network connectivity issues
      _crashReportingService.recordError(
        e, 
        stackTrace, 
        reason: 'Network error during Open Food Facts API call'
      );
      
      _analyticsService.logEvent(
        name: 'food_api_network_error',
        parameters: {'barcode': barcode, 'error': e.toString()}
      );
      
      rethrow;
    } on TimeoutException catch (e, stackTrace) {
      // API request timeout
      _crashReportingService.recordError(
        e, 
        stackTrace, 
        reason: 'Timeout during Open Food Facts API call'
      );
      
      _analyticsService.logEvent(
        name: 'food_api_timeout',
        parameters: {'barcode': barcode}
      );
      
      rethrow;
    } catch (e, stackTrace) {
      // Other errors
      _crashReportingService.recordError(
        e, 
        stackTrace, 
        reason: 'Error during Open Food Facts API call'
      );
      
      if (kDebugMode) {
        print('Error fetching food product: $e');
      }
      
      _analyticsService.logEvent(
        name: 'food_api_error',
        parameters: {'barcode': barcode, 'error': e.toString()}
      );
      
      rethrow;
    }
  }
  
  void _logApiResponse(Map<String, dynamic> data, String barcode) {
    try {
      // Log the quality of the data we received from the API
      final hasName = data['product']['product_name'] != null;
      final hasBrand = data['product']['brands'] != null;
      final hasImage = data['product']['image_url'] != null;
      final hasNutriments = data['product']['nutriments'] != null;
      
      final dataQuality = {
        'has_name': hasName,
        'has_brand': hasBrand,
        'has_image': hasImage,
        'has_nutriments': hasNutriments,
        'barcode': barcode,
      };
      
      _analyticsService.logEvent(
        name: 'food_api_data_quality',
        parameters: dataQuality
      );
    } catch (e) {
      // Ignore errors in analytics logging
    }
  }
  
  // Clear cache for testing or memory management
  void clearCache() {
    _cache.clear();
    _analyticsService.logEvent(name: 'food_api_cache_cleared');
  }
}