// lib/features/auth/providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import 'auth_provider.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('fitness_profiles').doc(userId).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap({
      'userId': userId,
      ...doc.data()!,
    });
  }
  
  // Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    await _firestore.collection('fitness_profiles').doc(profile.userId).update(
      profile.toMap(),
    );
  }
  
  // Create or update display name in personal info
  Future<void> updateDisplayName(String userId, String displayName) async {
    await _firestore.collection('users_personal_info').doc(userId).update({
      'displayName': displayName,
    });
  }
  
  // Update photo URL in personal info
  Future<void> updatePhotoUrl(String userId, String photoUrl) async {
    await _firestore.collection('users_personal_info').doc(userId).update({
      'photoUrl': photoUrl,
    });
  }
}

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});

final userProfileProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
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
      state = AsyncValue.data(profile);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  Future<void> updateProfile(UserProfile profile) async {
    try {
      state = const AsyncValue.loading();
      await _userService.updateUserProfile(profile);
      
      // Also update display name in personal info if it's changed
      if (profile.displayName != null) {
        await _userService.updateDisplayName(profile.userId, profile.displayName!);
      }
      
      // Also update photo URL in personal info if it's changed
      if (profile.photoUrl != null) {
        await _userService.updatePhotoUrl(profile.userId, profile.photoUrl!);
      }
      
      state = AsyncValue.data(profile);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final userProfileNotifierProvider = StateNotifierProvider.autoDispose<UserProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.uid;
  final userService = ref.read(userProfileServiceProvider);
  
  return UserProfileNotifier(userService, userId);
});