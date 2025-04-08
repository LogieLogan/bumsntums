// lib/shared/services/unit_conversion_service.dart
import '../../features/auth/models/user_profile.dart';

class UnitConversionService {
  // Weight conversions
  static double kgToLbs(double kg) => kg * 2.20462;
  static double lbsToKg(double lbs) => lbs / 2.20462;
  
  // Height conversions
  static double cmToInches(double cm) => cm / 2.54;
  static double inchesToCm(double inches) => inches * 2.54;
  
  // Format height based on unit system
  static String formatHeight(double? heightCm, UnitSystem unitSystem) {
    if (heightCm == null) return 'Not set';
    
    if (unitSystem == UnitSystem.metric) {
      return '${heightCm.toStringAsFixed(1)} cm';
    } else {
      final totalInches = cmToInches(heightCm);
      final feet = (totalInches / 12).floor();
      final inches = (totalInches % 12).round();
      return '$feet\'$inches"';
    }
  }
  
  // Format weight based on unit system
  static String formatWeight(double? weightKg, UnitSystem unitSystem) {
    if (weightKg == null) return 'Not set';
    
    if (unitSystem == UnitSystem.metric) {
      return '${weightKg.toStringAsFixed(1)} kg';
    } else {
      final lbs = kgToLbs(weightKg);
      return '${lbs.toStringAsFixed(1)} lbs';
    }
  }
  
  // Parse height input from string based on unit system
  static double? parseHeight(String input, UnitSystem unitSystem) {
    if (input.isEmpty) return null;
    
    if (unitSystem == UnitSystem.metric) {
      return double.tryParse(input);
    } else {
      // Parse feet and inches format (e.g., "5'10")
      if (input.contains("'")) {
        final parts = input.split("'");
        if (parts.length == 2) {
          final feet = int.tryParse(parts[0].trim()) ?? 0;
          final inches = double.tryParse(parts[1].replaceAll('"', '').trim()) ?? 0;
          return (feet * 30.48) + (inches * 2.54); // Convert to cm
        }
      }
      // Try parsing as total inches
      final inches = double.tryParse(input);
      if (inches != null) {
        return inchesToCm(inches);
      }
      return null;
    }
  }
  
  // Parse weight input from string based on unit system
  static double? parseWeight(String input, UnitSystem unitSystem) {
    if (input.isEmpty) return null;
    
    final weight = double.tryParse(input);
    if (weight == null) return null;
    
    if (unitSystem == UnitSystem.imperial) {
      return lbsToKg(weight); // Convert lbs to kg
    }
    return weight; // Already in kg
  }
}