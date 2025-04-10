// features/workout_analytics/models/workout_achievement.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class WorkoutAchievement extends Equatable {
  final String achievementId; // Links to the definition ID
  final String userId;
  final DateTime unlockedDate;

  const WorkoutAchievement({
    required this.achievementId,
    required this.userId,
    required this.unlockedDate,
  });

  @override
  List<Object?> get props => [achievementId, userId, unlockedDate];

  Map<String, dynamic> toMap() {
    return {
      'achievementId': achievementId,
      'userId': userId, // Keep userId for potential direct queries if needed
      // Store as Timestamp even if logs use milliseconds, for readability here.
      'unlockedDate': Timestamp.fromDate(unlockedDate),
    };
  }

  factory WorkoutAchievement.fromMap(Map<String, dynamic> map, String docId) {
     // Use docId as achievementId if not stored in map (recommended pattern for subcollections)
    final achievementId = map['achievementId'] ?? docId;

    // Ensure unlockedDate parsing handles Timestamp correctly
    DateTime unlocked;
    if (map['unlockedDate'] is Timestamp) {
      unlocked = (map['unlockedDate'] as Timestamp).toDate();
    } else if (map['unlockedDate'] is int) {
      // Fallback if accidentally stored as millis - log warning?
       print("Warning: Achievement unlockedDate stored as int (millis). Converting.");
       unlocked = DateTime.fromMillisecondsSinceEpoch(map['unlockedDate']);
    } else {
       // Default or throw error if format is unexpected
       print("Error: Unexpected type for achievement unlockedDate. Defaulting to now.");
       unlocked = DateTime.now();
    }

    return WorkoutAchievement(
      achievementId: achievementId,
      userId: map['userId'] ?? '', // Retrieve userId if stored
      unlockedDate: unlocked,
    );
  }
}