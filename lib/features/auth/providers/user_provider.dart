// lib/features/auth/providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import 'auth_provider.dart';

// Updated UserProfileService in lib/features/auth/providers/user_provider.dart
class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if profile exists
  Future<bool> checkProfileExists(String userId) async {
    final doc =
        await _firestore.collection('fitness_profiles').doc(userId).get();
    return doc.exists;
  }

  // Create a new user profile
  Future<void> createUserProfile(UserProfile profile) async {
    await _firestore
        .collection('fitness_profiles')
        .doc(profile.userId)
        .set(profile.toMap());
  }

  // Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    final doc =
        await _firestore.collection('fitness_profiles').doc(userId).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap({'userId': userId, ...doc.data()!});
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      print("UserProfileService: Updating profile for user ${profile.userId}");
      final profileMap = profile.toMap();

      // Filter out null values that might cause issues with Firestore
      final cleanedMap = Map<String, dynamic>.from(profileMap);
      cleanedMap.removeWhere((key, value) => value == null);

      print("UserProfileService: Cleaned map for Firestore: $cleanedMap");

      await _firestore
          .collection('fitness_profiles')
          .doc(profile.userId)
          .update(cleanedMap);

      print("UserProfileService: Update completed successfully");
    } catch (e) {
      print("UserProfileService: Error updating profile: $e");
      rethrow; // Rethrow to allow proper error handling upstream
    }
  }

  // Update or create user profile (uses set with merge)
  Future<void> upsertUserProfile(UserProfile profile) async {
    await _firestore
        .collection('fitness_profiles')
        .doc(profile.userId)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  // Get display name from personal info
  Future<String?> getDisplayName(String userId) async {
    final doc =
        await _firestore.collection('users_personal_info').doc(userId).get();
    if (!doc.exists) return null;
    return doc.data()?['displayName'];
  }

  // Get photo URL from personal info
  Future<String?> getPhotoUrl(String userId) async {
    final doc =
        await _firestore.collection('users_personal_info').doc(userId).get();
    if (!doc.exists) return null;
    return doc.data()?['photoUrl'];
  }

  // Create or update display name in personal info
  Future<void> updateDisplayName(String userId, String displayName) async {
    // Check if document exists
    final docRef = _firestore.collection('users_personal_info').doc(userId);
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.update({'displayName': displayName});
    } else {
      await docRef.set({'displayName': displayName}, SetOptions(merge: true));
    }
  }

  // Update photo URL in personal info
  Future<void> updatePhotoUrl(String userId, String photoUrl) async {
    // Check if document exists
    final docRef = _firestore.collection('users_personal_info').doc(userId);
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.update({'photoUrl': photoUrl});
    } else {
      await docRef.set({'photoUrl': photoUrl}, SetOptions(merge: true));
    }
  }
}

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});

final userProfileProvider = FutureProvider.autoDispose<UserProfile?>((
  ref,
) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) async {
      if (user == null) return null;

      final userService = ref.read(userProfileServiceProvider);
      return await userService.getUserProfile(user.uid);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final UserProfileService _userService;
  final String? _userId;

  UserProfileNotifier(this._userService, this._userId)
    : super(const AsyncValue.loading()) {
    if (_userId != null) {
      _loadUserProfile();
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      state = const AsyncValue.loading();
      final profile = await _userService.getUserProfile(_userId!);
      if (mounted) {
        state = AsyncValue.data(profile);
      }
    } catch (e, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    try {
      print("UserProfileNotifier: Updating profile...");
      print("Profile data received:");
      print("UserId: ${profile.userId}");
      print("Height: ${profile.heightCm}");
      print("Weight: ${profile.weightKg}");
      print("DOB: ${profile.dateOfBirth}");
      print("Fitness Level: ${profile.fitnessLevel}");
      print("Goals: ${profile.goals.map((g) => g.name).join(', ')}");
      print("Body Focus Areas: ${profile.bodyFocusAreas.join(', ')}");
      print("Workout Location: ${profile.preferredLocation?.name}");
      print("Equipment: ${profile.availableEquipment.join(', ')}");
      print("Weekly Days: ${profile.weeklyWorkoutDays}");
      print("Duration: ${profile.workoutDurationMinutes}");

      state = const AsyncValue.loading();

      // Check if the fitness profile document exists before updating
      final docExists = await _userService.checkProfileExists(profile.userId);

      // Convert to Map to check for null values
      final profileMap = profile.toMap();
      print("Profile Map for Firebase: $profileMap");

      if (!docExists) {
        print("UserProfileNotifier: Creating new profile document");
        // Create the document if it doesn't exist
        await _userService.createUserProfile(profile);
      } else {
        print("UserProfileNotifier: Updating existing profile document");
        // Update existing document
        await _userService.updateUserProfile(profile);
      }

      // Verify the data was saved by retrieving it again
      final savedProfile = await _userService.getUserProfile(profile.userId);
      print("Saved profile data from Firebase:");
      if (savedProfile != null) {
        print("Height: ${savedProfile.heightCm}");
        print("Weight: ${savedProfile.weightKg}");
        print("DOB: ${savedProfile.dateOfBirth}");
        print("Fitness Level: ${savedProfile.fitnessLevel}");
        print("Goals: ${savedProfile.goals.map((g) => g.name).join(', ')}");
        print("Body Focus Areas: ${savedProfile.bodyFocusAreas.join(', ')}");
        print("Workout Location: ${savedProfile.preferredLocation?.name}");
        print("Equipment: ${savedProfile.availableEquipment.join(', ')}");
        print("Weekly Days: ${savedProfile.weeklyWorkoutDays}");
        print("Duration: ${savedProfile.workoutDurationMinutes}");
      } else {
        print("WARNING: Could not retrieve saved profile!");
      }

      print(
        "UserProfileNotifier: Profile updated successfully, onboardingCompleted=${profile.onboardingCompleted}",
      );

      if (mounted) {
        state = AsyncValue.data(profile);
      }
    } catch (e, stackTrace) {
      print("UserProfileNotifier: Error updating profile: $e");
      print("Stack trace: $stackTrace");
      if (mounted) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }
}

final userProfileNotifierProvider = StateNotifierProvider.autoDispose<
  UserProfileNotifier,
  AsyncValue<UserProfile?>
>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.uid;
  final userService = ref.read(userProfileServiceProvider);

  return UserProfileNotifier(userService, userId);
});
