// lib/shared/services/svg_asset_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/svg_icons.dart';

class SvgAssetService {
  static Future<void> initializeSvgAssets() async {
    // Skip for web platform
    if (kIsWeb) return;
    
    try {
      // Get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final assetsPath = '${directory.path}/assets/icons/exercises';
      
      // Create directory if it doesn't exist
      final dir = Directory(assetsPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      // Create each SVG file
      for (final entry in SvgIcons.exerciseIcons.entries) {
        final file = File('$assetsPath/${entry.key}.svg');
        if (!await file.exists()) {
          await file.writeAsString(entry.value);
        }
      }
      
      print('SVG assets initialized successfully');
    } catch (e) {
      print('Error initializing SVG assets: $e');
    }
  }
  
  static String getAssetPath(String iconName) {
    return 'assets/icons/exercises/$iconName.svg';
  }
}