// lib/features/ai/services/personality_engine.dart
import 'package:flutter/foundation.dart';
import '../models/personality_settings.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

class PersonalityEngine {
  final Map<String, PersonalitySettings> _personalities = {};
  final AnalyticsService _analytics = AnalyticsService();
  
  // Cache of user communication styles
  final Map<String, Map<String, dynamic>> _userStyleCache = {};
  
  PersonalityEngine() {
    _initializeDefaultPersonalities();
  }
  
  void _initializeDefaultPersonalities() {
    // Default personality
    _addPersonality(PersonalitySettings.defaultPersonality());
    
    // Formal trainer
    _addPersonality(
      PersonalitySettings(
        id: 'formal_trainer',
        name: 'Professional Trainer',
        description: 'Formal, detail-oriented fitness professional.',
        tone: ToneLevel.formal,
        detailLevel: DetailLevel.detailed,
        humorLevel: HumorLevel.none,
        encouragementLevel: EncouragementLevel.moderate,
      )
    );
    
    // Enthusiastic motivator
    _addPersonality(
      PersonalitySettings(
        id: 'enthusiastic_motivator',
        name: 'Enthusiastic Motivator',
        description: 'High-energy, highly encouraging coach with frequent humor.',
        tone: ToneLevel.casual,
        detailLevel: DetailLevel.balanced,
        humorLevel: HumorLevel.frequent,
        encouragementLevel: EncouragementLevel.supportive,
      )
    );
    
    // Concise coach
    _addPersonality(
      PersonalitySettings(
        id: 'concise_coach',
        name: 'Concise Coach',
        description: 'Brief, to-the-point guidance with minimal elaboration.',
        tone: ToneLevel.balanced,
        detailLevel: DetailLevel.minimal,
        humorLevel: HumorLevel.none,
        encouragementLevel: EncouragementLevel.minimal,
      )
    );
  }
  
  void _addPersonality(PersonalitySettings personality) {
    _personalities[personality.id] = personality;
  }
  
  PersonalitySettings? getPersonality(String personalityId) {
    return _personalities[personalityId];
  }
  
  List<PersonalitySettings> getAllPersonalities() {
    return _personalities.values.toList();
  }
  
  /// Get the personality for a user, potentially adaptively
  PersonalitySettings getPersonalityForUser(String userId, {String? defaultPersonalityId}) {
    // Get base personality - with null check
    final basePersonality = defaultPersonalityId != null 
        ? (getPersonality(defaultPersonalityId) ?? PersonalitySettings.defaultPersonality())
        : PersonalitySettings.defaultPersonality();
    
    // Check if we have cached user style preferences
    if (_userStyleCache.containsKey(userId)) {
      final userStyle = _userStyleCache[userId]!;
      
      // Create an adapted personality based on observed user preferences
      return basePersonality.copyWith(
        tone: userStyle['preferredTone'] != null 
            ? ToneLevel.values.firstWhere(
                (t) => t.name == userStyle['preferredTone'],
                orElse: () => basePersonality.tone,
              )
            : null,
        detailLevel: userStyle['preferredDetailLevel'] != null
            ? DetailLevel.values.firstWhere(
                (d) => d.name == userStyle['preferredDetailLevel'],
                orElse: () => basePersonality.detailLevel,
              )
            : null,
      );
    }
    
    return basePersonality;
  }
  
  /// Analyze user message to detect communication style
  void analyzeUserMessage(String userId, String message) {
    try {
      // Don't analyze very short messages
      if (message.length < 10) return;
      
      // Calculate metrics
      final wordCount = message.split(' ').length;
      final sentenceCount = message.split(RegExp(r'[.!?]')).where((s) => s.trim().isNotEmpty).length;
      final avgSentenceLength = sentenceCount > 0 ? (wordCount / sentenceCount).toDouble() : wordCount.toDouble();
      
      final hasQuestions = message.contains('?');
      final hasCasualWords = RegExp(r'\b(lol|haha|hehe|hey|thanks|cool|awesome|yeah)\b', caseSensitive: false).hasMatch(message);
      final hasFormalWords = RegExp(r'\b(therefore|additionally|consequently|furthermore|regarding)\b', caseSensitive: false).hasMatch(message);
      
      // Get current style data or initialize new entry
      final userStyle = _userStyleCache[userId] ?? {};
      
      // Update message count
      final messageCount = (userStyle['messageCount'] as int?) ?? 0;
      userStyle['messageCount'] = messageCount + 1;
      
      // Update metrics with weighted average
      userStyle['avgWordCount'] = _updateAverage(
        userStyle['avgWordCount'], wordCount.toDouble(), messageCount);
      userStyle['avgSentenceLength'] = _updateAverage(
        userStyle['avgSentenceLength'], avgSentenceLength, messageCount);
      userStyle['questionFrequency'] = _updateAverage(
        userStyle['questionFrequency'], hasQuestions ? 1.0 : 0.0, messageCount);
      userStyle['casualWordFrequency'] = _updateAverage(
        userStyle['casualWordFrequency'], hasCasualWords ? 1.0 : 0.0, messageCount);
      userStyle['formalWordFrequency'] = _updateAverage(
        userStyle['formalWordFrequency'], hasFormalWords ? 1.0 : 0.0, messageCount);
      
      // Determine preferred styles based on metrics
      if (messageCount >= 3) { // Only after seeing a few messages
        // Determine tone preference
        if (userStyle['casualWordFrequency'] > 0.3) {
          userStyle['preferredTone'] = ToneLevel.casual.name;
        } else if (userStyle['formalWordFrequency'] > 0.2) {
          userStyle['preferredTone'] = ToneLevel.formal.name;
        } else {
          userStyle['preferredTone'] = ToneLevel.balanced.name;
        }
        
        // Determine detail level preference
        double avgWordCount = (userStyle['avgWordCount'] as num).toDouble();
        double questionFrequency = (userStyle['questionFrequency'] as num).toDouble();
        
        if (avgWordCount > 30 || questionFrequency > 0.5) {
          userStyle['preferredDetailLevel'] = DetailLevel.detailed.name;
        } else if (avgWordCount < 15) {
          userStyle['preferredDetailLevel'] = DetailLevel.minimal.name;
        } else {
          userStyle['preferredDetailLevel'] = DetailLevel.balanced.name;
        }
      }
      
      // Save updated style
      _userStyleCache[userId] = userStyle;
      
      debugPrint('Updated user style for $userId: ${userStyle['preferredTone']}, ${userStyle['preferredDetailLevel']}');
      
    } catch (e) {
      debugPrint('Error analyzing user message: $e');
    }
  }
  
  /// Update running average with new value
  double _updateAverage(dynamic currentAvg, double newValue, int previousCount) {
    if (currentAvg == null) return newValue;
    if (previousCount == 0) return newValue;
    
    final double current = (currentAvg as num).toDouble();
    return (current * previousCount + newValue) / (previousCount + 1);
  }
  
  /// Get prompt modifier based on personality settings
  String getPromptModifier(PersonalitySettings personality) {
    return personality.getPromptModifier();
  }
  
  /// Clear user style cache (for testing or memory management)
  void clearUserStyleCache() {
    _userStyleCache.clear();
  }
}