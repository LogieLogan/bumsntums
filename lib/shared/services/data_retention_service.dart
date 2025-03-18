// lib/shared/services/data_retention_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../analytics/firebase_analytics_service.dart';

class DataRetentionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService();

  // Define retention periods for different data types
  static const int _foodScanRetentionDays = 90; // 3 months for food scans
  static const int _workoutLogRetentionDays = 365; // 1 year for workout logs
  static const int _inactiveUserRetentionDays = 730; // 2 years for inactive users

  /// Clean up old food scan data
  Future<void> cleanupOldFoodScans() async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: _foodScanRetentionDays));
      final cutoffTimestamp = Timestamp.fromDate(cutoffDate);
      
      // Get all users
      final usersQuery = await _firestore.collection('food_scans').get();
      
      for (var userDoc in usersQuery.docs) {
        final userId = userDoc.id;
        
        // Get scans older than cutoff date
        final scansRef = _firestore.collection('food_scans').doc(userId).collection('scans');
        final oldScansQuery = await scansRef
            .where('createdAt', isLessThan: cutoffTimestamp)
            .where('isOfflineCreated', isEqualTo: false)
            .get();
        
        // Delete old scans
        for (var doc in oldScansQuery.docs) {
          await doc.reference.delete();
        }
      }
      
      _analytics.logEvent(
        name: 'old_food_scans_cleaned',
        parameters: {'cutoff_days': _foodScanRetentionDays},
      );
    } catch (e) {
      _analytics.logError(
        error: e.toString(),
        parameters: {'context': 'cleanupOldFoodScans'},
      );
    }
  }

  /// Clean up old workout logs
  Future<void> cleanupOldWorkoutLogs() async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: _workoutLogRetentionDays));
      final cutoffTimestamp = Timestamp.fromDate(cutoffDate);
      
      // Get all users
      final usersQuery = await _firestore.collection('workout_logs').get();
      
      for (var userDoc in usersQuery.docs) {
        final userId = userDoc.id;
        
        // Get logs older than cutoff date
        final logsRef = _firestore.collection('workout_logs').doc(userId).collection('logs');
        final oldLogsQuery = await logsRef
            .where('completedAt', isLessThan: cutoffTimestamp)
            .get();
        
        // Delete old logs
        for (var doc in oldLogsQuery.docs) {
          await doc.reference.delete();
        }
      }
      
      _analytics.logEvent(
        name: 'old_workout_logs_cleaned',
        parameters: {'cutoff_days': _workoutLogRetentionDays},
      );
    } catch (e) {
      _analytics.logError(
        error: e.toString(),
        parameters: {'context': 'cleanupOldWorkoutLogs'},
      );
    }
  }

  /// Identify inactive users for potential anonymization
  Future<List<String>> getInactiveUserIds() async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: _inactiveUserRetentionDays));
      final cutoffTimestamp = Timestamp.fromDate(cutoffDate);
      
      // Find users who haven't logged in since the cutoff date
      final usersQuery = await _firestore.collection('users_personal_info')
          .where('lastLoginAt', isLessThan: cutoffTimestamp)
          .get();
      
      final inactiveUserIds = usersQuery.docs.map((doc) => doc.id).toList();
      
      _analytics.logEvent(
        name: 'inactive_users_identified',
        parameters: {
          'count': inactiveUserIds.length,
          'cutoff_days': _inactiveUserRetentionDays
        },
      );
      
      return inactiveUserIds;
    } catch (e) {
      _analytics.logError(
        error: e.toString(),
        parameters: {'context': 'getInactiveUserIds'},
      );
      return [];
    }
  }
  
  /// Schedule data retention tasks
  Future<void> scheduleRetentionTasks() async {
    // This would typically be triggered by a Cloud Function on a schedule
    await cleanupOldFoodScans();
    await cleanupOldWorkoutLogs();
    final inactiveUsers = await getInactiveUserIds();
    
    // Log the scheduled tasks
    _analytics.logEvent(
      name: 'retention_tasks_scheduled',
      parameters: {
        'inactive_users_count': inactiveUsers.length,
      },
    );
  }
}