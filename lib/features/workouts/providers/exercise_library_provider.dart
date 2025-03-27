// // lib/features/workouts/providers/exercise_library_provider.dart
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../models/exercise.dart';
// import '../services/exercise_db_service.dart';
// import 'package:equatable/equatable.dart';

// // Provider for the exercise database service
// final exerciseDBServiceProvider = Provider<ExerciseDBService>((ref) {
//   return ExerciseDBService();
// });

// // Provider for all exercises
// final allExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
//   final service = ref.watch(exerciseDBServiceProvider);
//   await service.initialize();
//   return service.getAllExercises();
// });

// // Provider for target areas
// final targetAreasProvider = FutureProvider<List<String>>((ref) async {
//   final service = ref.watch(exerciseDBServiceProvider);
//   return service.getAvailableTargetAreas();
// });

// // Provider for equipment types
// final equipmentTypesProvider = FutureProvider<List<String>>((ref) async {
//   final service = ref.watch(exerciseDBServiceProvider);
//   return service.getAvailableEquipment();
// });

// // Filter parameters class
// class FilterParams extends Equatable {
//   final String? targetArea;
//   final String? equipment;
//   final int? difficultyLevel;
//   final String? searchQuery;

//   const FilterParams({
//     this.targetArea,
//     this.equipment,
//     this.difficultyLevel,
//     this.searchQuery,
//   });

//   @override
//   List<Object?> get props => [
//     targetArea,
//     equipment,
//     difficultyLevel,
//     searchQuery,
//   ];
// }

// // Provider for filtered exercises
// final filteredExercisesProvider =
//     FutureProvider.family<List<Exercise>, FilterParams>((ref, params) async {
//       final service = ref.watch(exerciseDBServiceProvider);

//       // Make sure the service is initialized
//       await service.initialize();

//       if (params.searchQuery != null && params.searchQuery!.isNotEmpty) {
//         // If there's a search query, prioritize search results
//         return service.searchExercises(params.searchQuery!);
//       }

//       // Otherwise use advanced filtering
//       return service.filterExercises(
//         targetArea: params.targetArea,
//         equipment: params.equipment,
//         difficultyLevel: params.difficultyLevel,
//       );
//     });
