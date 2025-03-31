// lib/features/ai/models/ai_context.dart
import 'package:equatable/equatable.dart';

class AIContext extends Equatable {
  final Map<String, dynamic> profileData;
  final Map<String, dynamic> sessionData;
  final Map<String, dynamic> featureData;
  
  const AIContext({
    required this.profileData,
    this.sessionData = const {},
    this.featureData = const {},
  });

  @override
  List<Object?> get props => [profileData, sessionData, featureData];

  AIContext copyWith({
    Map<String, dynamic>? profileData,
    Map<String, dynamic>? sessionData,
    Map<String, dynamic>? featureData,
  }) {
    return AIContext(
      profileData: profileData ?? this.profileData,
      sessionData: sessionData ?? this.sessionData,
      featureData: featureData ?? this.featureData,
    );
  }

  AIContext updateSessionData(Map<String, dynamic> newData) {
    final updatedSessionData = Map<String, dynamic>.from(sessionData);
    updatedSessionData.addAll(newData);
    
    return copyWith(
      sessionData: updatedSessionData,
    );
  }

  AIContext updateFeatureData(Map<String, dynamic> newData) {
    final updatedFeatureData = Map<String, dynamic>.from(featureData);
    updatedFeatureData.addAll(newData);
    
    return copyWith(
      featureData: updatedFeatureData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profileData': profileData,
      'sessionData': sessionData,
      'featureData': featureData,
    };
  }

  factory AIContext.fromMap(Map<String, dynamic> map) {
    return AIContext(
      profileData: Map<String, dynamic>.from(map['profileData'] ?? {}),
      sessionData: Map<String, dynamic>.from(map['sessionData'] ?? {}),
      featureData: Map<String, dynamic>.from(map['featureData'] ?? {}),
    );
  }

  Map<String, dynamic> getAllContext() {
    final result = <String, dynamic>{};
    result.addAll(profileData);
    result.addAll(sessionData);
    result.addAll(featureData);
    return result;
  }
}