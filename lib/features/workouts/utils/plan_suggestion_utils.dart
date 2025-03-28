// lib/features/workouts/utils/plan_suggestion_utils.dart
import '../services/smart_plan_detector.dart';

class PlanSuggestionUtils {
  static String getDayName(int weekday) {
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

  static String getCategoryName(String category) {
    switch (category.toLowerCase()) {
      case 'bums': return 'Bums';
      case 'tums': return 'Tums';
      case 'fullbody': return 'Full Body';
      case 'cardio': return 'Cardio';
      case 'quickworkout': return 'Quick Workout';
      default: return category;
    }
  }

  static String getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  // Generate plan suggestion details
  static ({String name, String description}) generatePlanNameFromSuggestion(
    PatternSuggestion suggestion
  ) {
    String planName = 'My Workout Plan';
    String planDescription = '';

    final workouts = suggestion.matchedWorkouts;

    if (suggestion.patternType == 'weekly') {
      final daysOfWeek = workouts.map((w) => w.scheduledDate.weekday).toSet();
      final dayNames = daysOfWeek.map((day) => getDayName(day)).join(', ');
      planName = '$dayNames Workout Plan';
      planDescription = 'Workouts on $dayNames';
    } else if (suggestion.patternType == 'daily') {
      planName = 'Daily Workout Plan';
      planDescription = 'Workouts every day';
    } else if (suggestion.patternType == 'category-based') {
      // Get the common category if all workouts have the same category
      final categories =
          workouts
              .map((w) => w.workoutCategory)
              .where((c) => c != null)
              .toSet();

      if (categories.length == 1 && categories.first != null) {
        final categoryName = getCategoryName(categories.first!);
        planName = '$categoryName Workout Plan';
        planDescription = 'Focus on $categoryName';
      }
    }

    return (name: planName, description: planDescription);
  }
}