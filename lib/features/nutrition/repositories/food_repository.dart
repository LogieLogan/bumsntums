// lib/features/nutrition/repositories/food_repository.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';
import '../models/food_item.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScanCountData {
  final int scanCount;
  final DateTime lastScanDate;
  
  ScanCountData({
    required this.scanCount,
    required this.lastScanDate,
  });
}

class FoodRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AnalyticsService _analyticsService;
  Database? _localDb;
  
  // Constants for SharedPreferences keys
  static const String _keyScanCount = 'food_scan_count';
  static const String _keyLastScanDate = 'food_last_scan_date';
  
  FoodRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required AnalyticsService analyticsService,
  }) : 
    _firestore = firestore,
    _auth = auth,
    _analyticsService = analyticsService;
  
  // Initialize local database
  Future<void> initLocalDb() async {
    if (_localDb != null) return;
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'food_scans.db');
    
    _localDb = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create tables
        await db.execute('''
          CREATE TABLE food_items(
            id TEXT PRIMARY KEY,
            barcode TEXT NOT NULL,
            name TEXT NOT NULL,
            brand TEXT,
            image_url TEXT,
            custom_name TEXT,
            user_notes TEXT,
            scanned_at INTEGER NOT NULL,
            is_offline_created INTEGER NOT NULL,
            sync_status TEXT NOT NULL,
            nutrition_info TEXT,
            personalized_info TEXT
          )
        ''');
      },
    );
  }
  
  // Get today's scan count
  Future<ScanCountData> getTodayScanCount() async {
    final prefs = await SharedPreferences.getInstance();
    final lastScanDateStr = prefs.getString(_keyLastScanDate);
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Parse last scan date
    DateTime lastScanDate;
    if (lastScanDateStr != null) {
      lastScanDate = DateTime.parse(lastScanDateStr);
      final lastScanDay = DateTime(
        lastScanDate.year, 
        lastScanDate.month, 
        lastScanDate.day,
      );
      
      // If last scan was before today, reset the counter
      if (lastScanDay.isBefore(today)) {
        await prefs.setInt(_keyScanCount, 0);
        return ScanCountData(
          scanCount: 0,
          lastScanDate: now,
        );
      }
    } else {
      lastScanDate = now;
    }
    
    final scanCount = prefs.getInt(_keyScanCount) ?? 0;
    return ScanCountData(
      scanCount: scanCount,
      lastScanDate: lastScanDate,
    );
  }
  
  // Update the scan count
  Future<void> updateScanCount(int newCount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyScanCount, newCount);
    await prefs.setString(_keyLastScanDate, DateTime.now().toIso8601String());
    
    _analyticsService.logEvent(
      name: 'scan_count_updated',
      parameters: {'new_count': newCount}
    );
  }
  
  // Save a scanned food item
  Future<void> saveFoodItem(FoodItem item) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      // Save to Firestore
      await _firestore
          .collection('food_scans')
          .doc(userId)
          .collection('items')
          .doc(item.id)
          .set(item.toFirestore());
      
      // Save to local DB for offline access
      await initLocalDb();
      await _localDb!.insert(
        'food_items',
        {
          'id': item.id,
          'barcode': item.barcode,
          'name': item.name,
          'brand': item.brand,
          'image_url': item.imageUrl,
          'custom_name': item.customName,
          'user_notes': item.userNotes,
          'scanned_at': item.scannedAt.millisecondsSinceEpoch,
          'is_offline_created': item.isOfflineCreated ? 1 : 0,
          'sync_status': item.syncStatus,
          'nutrition_info': item.nutritionInfo != null 
              ? _mapToJsonString(item.nutritionInfo!.toMap()) 
              : null,
          'personalized_info': item.personalizedInfo != null 
              ? _mapToJsonString(item.personalizedInfo!.toMap()) 
              : null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      _analyticsService.logEvent(
        name: 'food_item_saved',
        parameters: {'barcode': item.barcode}
      );
    } catch (e) {
      _analyticsService.logEvent(
        name: 'food_item_save_error',
        parameters: {'error': e.toString()}
      );
      rethrow;
    }
  }
  
  // Get recent food scans
  Future<List<FoodItem>> getRecentScans({int limit = 10}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      final snapshot = await _firestore
          .collection('food_scans')
          .doc(userId)
          .collection('items')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      _analyticsService.logEvent(
        name: 'recent_scans_fetched',
        parameters: {'count': snapshot.docs.length}
      );
      
      return snapshot.docs
          .map((doc) => FoodItem.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      // If online fetch fails, try local DB
      try {
        await initLocalDb();
        final items = await _localDb!.query(
          'food_items',
          orderBy: 'scanned_at DESC',
          limit: limit,
        );
        
        _analyticsService.logEvent(
          name: 'recent_scans_fetched_locally',
          parameters: {'count': items.length}
        );
        
        return items.map((item) => _foodItemFromLocalDb(item)).toList();
      } catch (localError) {
        _analyticsService.logEvent(
          name: 'food_fetch_error',
          parameters: {
            'cloud_error': e.toString(),
            'local_error': localError.toString()
          }
        );
        rethrow;
      }
    }
  }
  
  // Get a specific food item by barcode
  Future<FoodItem?> getFoodItemByBarcode(String barcode) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      // Try Firestore first
      final snapshot = await _firestore
          .collection('food_scans')
          .doc(userId)
          .collection('items')
          .where('productId', isEqualTo: barcode)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        _analyticsService.logEvent(
          name: 'food_item_found_in_cloud',
          parameters: {'barcode': barcode}
        );
        return FoodItem.fromFirestore(doc.data(), doc.id);
      }
      
      // If not found in Firestore, try local DB
      await initLocalDb();
      final items = await _localDb!.query(
        'food_items',
        where: 'barcode = ?',
        whereArgs: [barcode],
        limit: 1,
      );
      
      if (items.isNotEmpty) {
        _analyticsService.logEvent(
          name: 'food_item_found_locally',
          parameters: {'barcode': barcode}
        );
        return _foodItemFromLocalDb(items.first);
      }
      
      return null;
    } catch (e) {
      _analyticsService.logEvent(
        name: 'food_item_lookup_error',
        parameters: {'barcode': barcode, 'error': e.toString()}
      );
      rethrow;
    }
  }
  
  // Helper methods
  String _mapToJsonString(Map<String, dynamic> map) {
    return jsonEncode(map);
  }
  
  Map<String, dynamic> _jsonStringToMap(String jsonString) {
    return jsonDecode(jsonString);
  }
  
  FoodItem _foodItemFromLocalDb(Map<String, dynamic> dbItem) {
    return FoodItem(
      id: dbItem['id'],
      barcode: dbItem['barcode'],
      name: dbItem['name'],
      brand: dbItem['brand'],
      imageUrl: dbItem['image_url'],
      customName: dbItem['custom_name'],
      userNotes: dbItem['user_notes'],
      scannedAt: DateTime.fromMillisecondsSinceEpoch(dbItem['scanned_at']),
      isOfflineCreated: dbItem['is_offline_created'] == 1,
      syncStatus: dbItem['sync_status'],
      nutritionInfo: dbItem['nutrition_info'] != null
          ? NutritionInfo.fromMap(_jsonStringToMap(dbItem['nutrition_info']))
          : null,
      personalizedInfo: dbItem['personalized_info'] != null
          ? PersonalizedInfo.fromMap(_jsonStringToMap(dbItem['personalized_info']))
          : null,
    );
  }
  
  // Delete a food item
  Future<void> deleteFoodItem(String itemId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      // Delete from Firestore
      await _firestore
          .collection('food_scans')
          .doc(userId)
          .collection('items')
          .doc(itemId)
          .delete();
      
      // Delete from local DB
      await initLocalDb();
      await _localDb!.delete(
        'food_items',
        where: 'id = ?',
        whereArgs: [itemId],
      );
      
      _analyticsService.logEvent(
        name: 'food_item_deleted',
        parameters: {'item_id': itemId}
      );
    } catch (e) {
      _analyticsService.logEvent(
        name: 'food_item_delete_error',
        parameters: {'error': e.toString()}
      );
      rethrow;
    }
  }
  
  // Clear all local data
  Future<void> clearLocalData() async {
    try {
      await initLocalDb();
      await _localDb!.delete('food_items');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyScanCount);
      await prefs.remove(_keyLastScanDate);
      
      _analyticsService.logEvent(name: 'local_food_data_cleared');
    } catch (e) {
      _analyticsService.logEvent(
        name: 'clear_local_data_error',
        parameters: {'error': e.toString()}
      );
      rethrow;
    }
  }
}