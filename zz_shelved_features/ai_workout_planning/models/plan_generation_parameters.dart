// // lib/features/ai_workout_planning/models/plan_generation_parameters.dart
// class PlanGenerationParameters {
//   final int durationDays;
//   final int daysPerWeek;
//   final List<String> focusAreas;
//   final String variationType;
//   final String fitnessLevel;
//   final String? specialRequest;
//   final List<String>? equipment;

//   PlanGenerationParameters({
//     this.durationDays = 7,
//     this.daysPerWeek = 3,
//     this.focusAreas = const ['Full Body'],
//     this.variationType = 'balanced',
//     this.fitnessLevel = 'beginner',
//     this.specialRequest,
//     this.equipment,
//   });

//   PlanGenerationParameters copyWith({
//     int? durationDays,
//     int? daysPerWeek,
//     List<String>? focusAreas,
//     String? variationType,
//     String? fitnessLevel,
//     String? specialRequest,
//     List<String>? equipment,
//   }) {
//     return PlanGenerationParameters(
//       durationDays: durationDays ?? this.durationDays,
//       daysPerWeek: daysPerWeek ?? this.daysPerWeek,
//       focusAreas: focusAreas ?? this.focusAreas,
//       variationType: variationType ?? this.variationType,
//       fitnessLevel: fitnessLevel ?? this.fitnessLevel,
//       specialRequest: specialRequest ?? this.specialRequest,
//       equipment: equipment ?? this.equipment,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'durationDays': durationDays,
//       'daysPerWeek': daysPerWeek,
//       'focusAreas': focusAreas,
//       'variationType': variationType,
//       'fitnessLevel': fitnessLevel,
//       'specialRequest': specialRequest,
//       'equipment': equipment,
//     };
//   }
// }