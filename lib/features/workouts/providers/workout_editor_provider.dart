// lib/features/workouts/providers/workout_editor_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/workout.dart';
import '../models/workout_section.dart';
import '../repositories/custom_workout_repository.dart';

// State class for workout editor
class WorkoutEditorState {
  final bool isSaving;
  final bool isSuccess;
  final String? errorMessage;
  final Workout? activeWorkout;
  final bool isVersioning;
  final bool isConverting;
  
  WorkoutEditorState({
    this.isSaving = false,
    this.isSuccess = false,
    this.errorMessage,
    this.activeWorkout,
    this.isVersioning = false,
    this.isConverting = false,
  });
  
  WorkoutEditorState copyWith({
    bool? isSaving,
    bool? isSuccess,
    String? errorMessage,
    Workout? activeWorkout,
    bool? isVersioning,
    bool? isConverting,
  }) {
    return WorkoutEditorState(
      isSaving: isSaving ?? this.isSaving,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      activeWorkout: activeWorkout ?? this.activeWorkout,
      isVersioning: isVersioning ?? this.isVersioning,
      isConverting: isConverting ?? this.isConverting,
    );
  }
}

class WorkoutEditorNotifier extends StateNotifier<WorkoutEditorState> {
  final CustomWorkoutRepository _repository;
  final FirebaseAuth _auth;
  
  WorkoutEditorNotifier(this._repository, this._auth) 
      : super(WorkoutEditorState());
  
  // Save workout (regular or template)
  Future<bool> saveWorkout(Workout workout) async {
    state = state.copyWith(
      isSaving: true, 
      errorMessage: null, 
      isSuccess: false,
      activeWorkout: workout,
    );
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'User not logged in',
        );
        return false;
      }
      
      bool success;
      if (workout.isTemplate) {
        success = await _repository.saveWorkoutTemplate(user.uid, workout);
      } else {
        success = await _repository.saveCustomWorkout(user.uid, workout);
      }
      
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
  
  // Delete workout (regular or template)
  Future<bool> deleteWorkout(String workoutId, {bool isTemplate = false}) async {
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
      
      bool success;
      if (isTemplate) {
        success = await _repository.deleteWorkoutTemplate(user.uid, workoutId);
      } else {
        success = await _repository.deleteCustomWorkout(user.uid, workoutId);
      }
      
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
  
  // Save a new version of a workout
  Future<bool> saveWorkoutVersion(Workout workout, String versionNotes) async {
    state = state.copyWith(
      isSaving: true, 
      errorMessage: null, 
      isSuccess: false,
      isVersioning: true,
    );
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isSaving: false,
          isVersioning: false,
          errorMessage: 'User not logged in',
        );
        return false;
      }
      
      // Save the version
      final success = await _repository.saveWorkoutVersion(
        user.uid, 
        workout, 
        versionNotes,
      );
      
      if (success) {
        state = state.copyWith(
          isSaving: false, 
          isSuccess: true,
          isVersioning: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isSaving: false,
          isVersioning: false,
          errorMessage: 'Failed to save workout version',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        isVersioning: false,
        errorMessage: 'Error: ${e.toString()}',
      );
      return false;
    }
  }
  
  // Convert a workout to a template
  Future<bool> convertToTemplate(Workout workout) async {
    state = state.copyWith(
      isSaving: true, 
      errorMessage: null, 
      isSuccess: false,
      isConverting: true,
    );
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isSaving: false,
          isConverting: false,
          errorMessage: 'User not logged in',
        );
        return false;
      }
      
      // Convert to template
      final success = await _repository.convertWorkoutToTemplate(user.uid, workout);
      
      if (success) {
        state = state.copyWith(
          isSaving: false, 
          isSuccess: true,
          isConverting: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isSaving: false,
          isConverting: false,
          errorMessage: 'Failed to convert workout to template',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        isConverting: false,
        errorMessage: 'Error: ${e.toString()}',
      );
      return false;
    }
  }
  
  // Create a workout from a template
  Future<Workout?> createFromTemplate(Workout template) async {
    state = state.copyWith(isSaving: true, errorMessage: null, isSuccess: false);
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'User not logged in',
        );
        return null;
      }
      
      // Create from template
      final newWorkout = await _repository.createWorkoutFromTemplate(user.uid, template);
      
      if (newWorkout != null) {
        state = state.copyWith(
          isSaving: false, 
          isSuccess: true,
          activeWorkout: newWorkout,
        );
        return newWorkout;
      } else {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'Failed to create workout from template',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error: ${e.toString()}',
      );
      return null;
    }
  }
  
  // Add a new section to the workout
  void addSection(String name, {SectionType type = SectionType.normal}) {
    if (state.activeWorkout == null) return;
    
    final sections = List<WorkoutSection>.from(state.activeWorkout!.sections);
    
    sections.add(
      WorkoutSection(
        id: 'section-${const Uuid().v4()}',
        name: name,
        exercises: [],
        type: type,
      ),
    );
    
    state = state.copyWith(
      activeWorkout: state.activeWorkout!.copyWith(sections: sections),
    );
  }
  
  // Remove a section from the workout
  void removeSection(String sectionId) {
    if (state.activeWorkout == null) return;
    
    final sections = List<WorkoutSection>.from(state.activeWorkout!.sections);
    sections.removeWhere((section) => section.id == sectionId);
    
    state = state.copyWith(
      activeWorkout: state.activeWorkout!.copyWith(sections: sections),
    );
  }
  
  // Update a section in the workout
  void updateSection(WorkoutSection updatedSection) {
    if (state.activeWorkout == null) return;
    
    final sections = List<WorkoutSection>.from(state.activeWorkout!.sections);
    final index = sections.indexWhere((section) => section.id == updatedSection.id);
    
    if (index != -1) {
      sections[index] = updatedSection;
      
      state = state.copyWith(
        activeWorkout: state.activeWorkout!.copyWith(sections: sections),
      );
    }
  }
  
  // Reorder sections in the workout
  void reorderSections(int oldIndex, int newIndex) {
    if (state.activeWorkout == null) return;
    
    final sections = List<WorkoutSection>.from(state.activeWorkout!.sections);
    
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final section = sections.removeAt(oldIndex);
    sections.insert(newIndex, section);
    
    state = state.copyWith(
      activeWorkout: state.activeWorkout!.copyWith(sections: sections),
    );
  }
  
  // Update the active workout
  void updateActiveWorkout(Workout workout) {
    state = state.copyWith(activeWorkout: workout);
  }
}

// Provider
final workoutEditorProvider = StateNotifierProvider<WorkoutEditorNotifier, WorkoutEditorState>((ref) {
  final repository = CustomWorkoutRepository();
  final auth = FirebaseAuth.instance;
  return WorkoutEditorNotifier(repository, auth);
});