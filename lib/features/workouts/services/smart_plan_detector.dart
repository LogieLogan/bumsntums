// lib/features/workouts/services/smart_plan_detector.dart
import 'package:collection/collection.dart';
import '../models/workout_plan.dart';

class PatternSuggestion {
  final String description;
  final String patternType;
  final List<ScheduledWorkout> matchedWorkouts;
  
  PatternSuggestion({
    required this.description,
    required this.patternType,
    required this.matchedWorkouts,
  });
}

class SmartPlanDetector {
  // Detect patterns in scheduled workouts
  List<PatternSuggestion> detectPatterns(List<ScheduledWorkout> workouts) {
    List<PatternSuggestion> suggestions = [];
    
    if (workouts.length < 2) return suggestions;
    
    // Sort workouts by date
    final sortedWorkouts = [...workouts];
    sortedWorkouts.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    
    // Check for workouts on same day of week
    final weekdayPatterns = _detectWeekdayPatterns(sortedWorkouts);
    suggestions.addAll(weekdayPatterns);
    
    // Check for workouts with same intervals
    final intervalPatterns = _detectIntervalPatterns(sortedWorkouts);
    suggestions.addAll(intervalPatterns);
    
    // Check for workouts of the same type
    final typePatterns = _detectTypePatterns(sortedWorkouts);
    suggestions.addAll(typePatterns);
    
    return suggestions;
  }
  
  // Detect workouts on the same day of week
  List<PatternSuggestion> _detectWeekdayPatterns(List<ScheduledWorkout> workouts) {
    final List<PatternSuggestion> suggestions = [];
    
    // Group workouts by weekday
    final groupedByWeekday = workouts.groupListsBy((w) => w.scheduledDate.weekday);
    
    // Look for days with multiple workouts
    groupedByWeekday.forEach((weekday, weekdayWorkouts) {
      if (weekdayWorkouts.length >= 2) {
        // We have at least 2 workouts on the same day of week
        final String dayName = _getDayName(weekday);
        
        suggestions.add(PatternSuggestion(
          description: 'You have ${weekdayWorkouts.length} workouts scheduled on $dayName',
          patternType: 'weekly',
          matchedWorkouts: weekdayWorkouts,
        ));
      }
    });
    
    return suggestions;
  }
  
  // Detect workouts with same intervals
  List<PatternSuggestion> _detectIntervalPatterns(List<ScheduledWorkout> workouts) {
    final List<PatternSuggestion> suggestions = [];
    
    // Need at least 3 workouts to detect interval patterns reliably
    if (workouts.length < 3) return suggestions;
    
    // Calculate intervals between consecutive workouts
    List<int> intervals = [];
    for (int i = 1; i < workouts.length; i++) {
      final interval = workouts[i].scheduledDate.difference(workouts[i-1].scheduledDate).inDays;
      intervals.add(interval);
    }
    
    // Check if we have consistent intervals
    final consistentInterval = _getMostCommonInterval(intervals);
    if (consistentInterval > 0) {
      String intervalDesc = '';
      if (consistentInterval == 1) {
        intervalDesc = 'daily';
      } else if (consistentInterval == 7) {
        intervalDesc = 'weekly';
      } else if (consistentInterval % 7 == 0) {
        intervalDesc = 'every ${consistentInterval ~/ 7} weeks';
      } else {
        intervalDesc = 'every $consistentInterval days';
      }
      
      suggestions.add(PatternSuggestion(
        description: 'You have a pattern of $intervalDesc workouts',
        patternType: consistentInterval == 1 ? 'daily' : 
                     consistentInterval == 7 ? 'weekly' : 'custom',
        matchedWorkouts: workouts,
      ));
    }
    
    return suggestions;
  }
  
  // Detect patterns based on workout type
  List<PatternSuggestion> _detectTypePatterns(List<ScheduledWorkout> workouts) {
    final List<PatternSuggestion> suggestions = [];
    
    // Group workouts by category
    final groupedByCategory = workouts.groupListsBy((w) => w.workoutCategory ?? 'unknown');
    
    // Check for categories with multiple workouts
    groupedByCategory.forEach((category, categoryWorkouts) {
      if (category != 'unknown' && categoryWorkouts.length >= 2) {
        // Get a readable category name
        final categoryName = _getCategoryName(category);
        
        suggestions.add(PatternSuggestion(
          description: 'You have ${categoryWorkouts.length} $categoryName workouts',
          patternType: 'category-based',
          matchedWorkouts: categoryWorkouts,
        ));
      }
    });
    
    return suggestions;
  }
  
  // Helper to get the most common interval from a list
  int _getMostCommonInterval(List<int> intervals) {
    if (intervals.isEmpty) return 0;
    
    // Count occurrences of each interval
    final countMap = <int, int>{};
    for (final interval in intervals) {
      countMap[interval] = (countMap[interval] ?? 0) + 1;
    }
    
    // Find the most common interval that appears at least twice
    int mostCommon = 0;
    int highestCount = 1;
    
    countMap.forEach((interval, count) {
      if (count > highestCount) {
        highestCount = count;
        mostCommon = interval;
      }
    });
    
    // Only return if the pattern appears in at least 2 intervals
    return highestCount >= 2 ? mostCommon : 0;
  }
  
  // Helper to get day name from weekday
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Unknown';
    }
  }
  
  // Helper to get readable category name
  String _getCategoryName(String category) {
    switch (category.toLowerCase()) {
      case 'bums': return 'Bums';
      case 'tums': return 'Tums';
      case 'fullbody': return 'Full Body';
      case 'cardio': return 'Cardio';
      case 'quickworkout': return 'Quick Workout';
      default: return category;
    }
  }
}