// lib/features/nutrition/services/open_food_facts_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';
import '../models/food_search_result.dart'; // Import the new model
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/analytics/crash_reporting_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class OpenFoodFactsService {
  // ... (existing fields and constructor) ...
  final String _baseUrl = 'https://world.openfoodfacts.org'; // Base URL might vary slightly for search endpoint
  final AnalyticsService _analyticsService;
  final CrashReportingService _crashReportingService;
  final http.Client _httpClient;
  final Map<String, FoodItem> _cache = {};
  final Duration _timeout = const Duration(seconds: 15); // Slightly longer timeout for search?

  OpenFoodFactsService({
    required AnalyticsService analyticsService,
    required CrashReportingService crashReportingService,
    http.Client? httpClient,
  }) :
    _analyticsService = analyticsService,
    _crashReportingService = crashReportingService,
    _httpClient = httpClient ?? http.Client();

  // --- getProductByBarcode method remains the same ---
  Future<FoodItem?> getProductByBarcode(String barcode) async {
    try {
      if (_cache.containsKey(barcode)) {
        _analyticsService.logEvent( name: 'food_barcode_cache_hit', parameters: {'barcode': barcode} );
        return _cache[barcode];
      }
      _analyticsService.logEvent( name: 'food_barcode_scan', parameters: {'barcode': barcode} );
      if (barcode.isEmpty || barcode.length < 8) {
        _analyticsService.logEvent( name: 'food_invalid_barcode', parameters: {'barcode': barcode});
        return null;
      }
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/api/v0/product/$barcode.json'), // Use product API endpoint
      ).timeout(_timeout);
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 1) {
         _logApiResponseQuality(data, barcode);
        final foodItem = FoodItem.fromOpenFoodFacts(data);
        _cache[barcode] = foodItem;
        _analyticsService.logEvent( name: 'food_product_found', parameters: {
            'barcode': barcode, 'product_name': foodItem.name,
            'has_nutrition_info': (foodItem.nutritionInfo != null).toString(),
          });
        return foodItem;
      } else if (response.statusCode == 200 && data['status'] == 0) {
        _analyticsService.logEvent( name: 'food_barcode_not_found', parameters: {'barcode': barcode} );
        return null;
      } else {
        _analyticsService.logEvent( name: 'food_api_error', parameters: {
            'barcode': barcode, 'status_code': response.statusCode.toString(),
            'api_status': data['status']?.toString() ?? 'unknown' });
        throw Exception('API error: ${response.statusCode} - ${data['status_verbose'] ?? 'Unknown error'}');
      }
    } on SocketException catch (e, stackTrace) {
      _crashReportingService.recordError( e, stackTrace, reason: 'Network error during Open Food Facts API call');
      _analyticsService.logEvent( name: 'food_api_network_error', parameters: {'barcode': barcode, 'error': e.toString()});
      rethrow;
    } on TimeoutException catch (e, stackTrace) {
      _crashReportingService.recordError( e, stackTrace, reason: 'Timeout during Open Food Facts API call');
      _analyticsService.logEvent( name: 'food_api_timeout', parameters: {'barcode': barcode});
      rethrow;
    } catch (e, stackTrace) {
      _crashReportingService.recordError( e, stackTrace, reason: 'Error during Open Food Facts API call');
      if (kDebugMode) { print('Error fetching food product: $e'); }
      _analyticsService.logEvent( name: 'food_api_error', parameters: {'barcode': barcode, 'error': e.toString()});
      rethrow;
    }
  }


  // --- NEW Search Products Method ---
  Future<List<FoodSearchResult>> searchProducts(String query, {int page = 1, int pageSize = 20}) async {
      if (query.trim().isEmpty) {
        return []; // Don't search for empty query
      }

      // Encode the query for the URL
      final encodedQuery = Uri.encodeComponent(query);
      // Construct the search URL using the CGI endpoint
      final searchUrl = Uri.parse(
          '$_baseUrl/cgi/search.pl?search_terms=$encodedQuery&search_simple=1&action=process&json=1&page=$page&page_size=$pageSize'
      );

       _analyticsService.logEvent(name: 'food_search_attempt', parameters: {'query': query, 'page': page});
       if (kDebugMode) { print("Searching OFF: ${searchUrl.toString()}"); }

      try {
         final response = await _httpClient.get(searchUrl).timeout(_timeout);
         final data = json.decode(response.body);

         if (response.statusCode == 200 && data != null && data['products'] is List) {
             final productsList = data['products'] as List;
             final results = productsList
                 .map((productJson) {
                      // Ensure barcode/code is present before parsing
                      if (productJson is Map<String, dynamic> && (productJson.containsKey('code') || productJson.containsKey('_id'))) {
                          return FoodSearchResult.fromOffSearch(productJson);
                      }
                      return null; // Skip if no identifier
                 })
                 .whereNotNull() // Use collection package helper
                 .toList();

             _analyticsService.logEvent(name: 'food_search_success', parameters: {
                 'query': query,
                 'results_count': results.length,
                 'page': page,
             });
              if (kDebugMode) { print("Search successful for '$query'. Found ${results.length} results."); }
             return results;
         } else {
              _analyticsService.logEvent(name: 'food_search_api_error', parameters: {
                 'query': query,
                 'status_code': response.statusCode.toString(),
                 'response_excerpt': response.body.substring(0, (response.body.length > 100 ? 100 : response.body.length)), // Log excerpt
              });
               if (kDebugMode) { print("Search API Error ${response.statusCode}: ${response.body}"); }
              throw Exception('Search API error: ${response.statusCode}');
         }

      } on SocketException catch (e, stackTrace) {
        _crashReportingService.recordError(e, stackTrace, reason: 'Network error during OFF Search');
        _analyticsService.logEvent(name: 'food_search_network_error', parameters: {'query': query, 'error': e.toString()});
        rethrow;
      } on TimeoutException catch (e, stackTrace) {
        _crashReportingService.recordError(e, stackTrace, reason: 'Timeout during OFF Search');
        _analyticsService.logEvent(name: 'food_search_timeout', parameters: {'query': query});
        rethrow;
      } catch (e, stackTrace) {
         _crashReportingService.recordError(e, stackTrace, reason: 'Error during OFF Search');
         if (kDebugMode) { print('Error searching food products: $e'); }
         _analyticsService.logEvent(name: 'food_search_error', parameters: {'query': query, 'error': e.toString()});
         rethrow;
      }
  }
  // --- END Search Products Method ---


  // --- _logApiResponseQuality and clearCache remain the same ---
   void _logApiResponseQuality(Map<String, dynamic> data, String barcode) {
    final productData = data['product'] as Map<String, dynamic>?;
    if (productData == null) return;
    try {
      final Map<String, Object> dataQuality = {
         'has_name': (productData['product_name'] != null).toString(),
         'has_brand': (productData['brands'] != null).toString(),
         'has_image': (productData['image_url'] != null).toString(),
         'has_nutriments': (productData['nutriments'] != null).toString(),
         'barcode': barcode,
      };
      _analyticsService.logEvent( name: 'food_api_data_quality', parameters: dataQuality);
    } catch (e) { if (kDebugMode) { print("Error logging API data quality: $e"); } }
  }
  void clearCache() {
    _cache.clear();
    _analyticsService.logEvent(name: 'food_api_cache_cleared');
  }
}