# Gamification System

## Achievement System

### Achievement Types
1. **Milestone Achievements**
   - First workout completed
   - 5/10/25/50/100 workouts completed
   - 7/30/90/180/365-day streaks
   - Weight goals achieved (Phase 2)

2. **Activity Achievements**
   - Early bird (morning workouts)
   - Night owl (evening workouts)
   - Weekend warrior (weekend consistency)
   - Variety master (try different workouts)

3. **Target Area Achievements**
   - Bums expert (complete X bums workouts)
   - Tums master (complete X tums workouts)
   - Full body champion (complete X full body workouts)

4. **Consistency Achievements**
   - Perfect week (7 days in a row)
   - Monthly dedication (20+ workouts in a month)
   - Comeback king/queen (return after 7+ day break)

### Achievement Model
```dart
class Achievement {
  final String id;
  final String title;
  final String description;
  final String badgeImageUrl;
  final AchievementCategory category;
  final int level; // 1-5 for tiered achievements
  final AchievementCriteria criteria;
  final String? rewardDescription;
  
  // Constructor, copyWith, toMap, fromMap methods
}

enum AchievementCategory {
  milestone,
  activity,
  targetArea,
  consistency,
  special
}

class AchievementCriteria {
  final AchievementCriteriaType type;
  final int targetValue;
  final String? targetWorkoutCategory;
  final String? timeOfDay;
  
  // Constructor, toMap, fromMap methods
}

enum AchievementCriteriaType {
  workoutCount,
  streak,
  specificWorkoutCount,
  timeOfDayWorkouts,
  dayOfWeekWorkouts,
  workoutVariety
}