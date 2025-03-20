// lib/features/workouts/providers/workout_editor_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../repositories/custom_workout_repository.dart';
import '../../auth/providers/auth_provider.dart';

// State class for workout editor
class WorkoutEditorState {
  final bool isSaving;
  final bool isSuccess;
  final String? errorMessage;
  
  WorkoutEditorState({
    this.isSaving = false,
    this.isSuccess = false,
    this.errorMessage,
  });
  
  WorkoutEditorState copyWith({
    bool? isSaving,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return WorkoutEditorState(
      isSaving: isSaving ?? this.isSaving,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
    );
  }
}

class WorkoutEditorNotifier extends StateNotifier<WorkoutEditorState> {
  final CustomWorkoutRepository _repository;
  final FirebaseAuth _auth;
  
  WorkoutEditorNotifier(this._repository, this._auth) 
      : super(WorkoutEditorState());
  
  Future<bool> saveWorkout(Workout workout) async {
    state = state.copyWith(isSaving: true, errorMessage: null, isSuccess: false);
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'User not logged in',
        );
        return false;
      }
      
      final success = await _repository.saveCustomWorkout(user.uid, workout);
      
      if (success) {
        state = state.copyWith(isSaving: false, isSuccess: true);
        return true;
      } else {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'Failed to save workout',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error: ${e.toString()}',
      );
      return false;
    }
  }
  
  Future<bool> deleteWorkout(String workoutId) async {
    state = state.copyWith(isSaving: true, errorMessage: null, isSuccess: false);
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'User not logged in',
        );
        return false;
      }
      
      final success = await _repository.deleteCustomWorkout(user.uid, workoutId);
      
      if (success) {
        state = state.copyWith(isSaving: false, isSuccess: true);
        return true;
      } else {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'Failed to delete workout',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error: ${e.toString()}',
      );
      return false;
    }
  }
}

// Provider
final workoutEditorProvider = StateNotifierProvider<WorkoutEditorNotifier, WorkoutEditorState>((ref) {
  final repository = CustomWorkoutRepository();
  final auth = FirebaseAuth.instance;
  return WorkoutEditorNotifier(repository, auth);
});