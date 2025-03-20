// lib/features/workouts/services/voice_guidance_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VoiceGuidanceService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;
  bool _enabled = true;
  
  // Initialize the TTS engine
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5); // Slightly slower for clarity
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
      _initialized = false;
    }
  }
  
  // Enable or disable voice guidance
  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!_enabled) {
      _flutterTts.stop();
    }
  }
  
  // Speak a message
  Future<void> speak(String message) async {
    if (!_enabled || !_initialized) return;
    
    try {
      await _flutterTts.speak(message);
    } catch (e) {
      debugPrint('Error speaking: $e');
    }
  }
  
  // Stop speaking
  Future<void> stop() async {
    if (!_initialized) return;
    
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }
  
  // Prepare exercise announcements
  Future<void> announceExerciseStart(String exerciseName, int sets, int reps) async {
    if (reps > 0) {
      await speak('Next exercise: $exerciseName. $sets sets of $reps reps.');
    } else {
      await speak('Next exercise: $exerciseName.');
    }
  }
  
  // Announce timed exercise
  Future<void> announceTimedExercise(String exerciseName, int seconds) async {
    await speak('Next exercise: $exerciseName for $seconds seconds.');
  }
  
  // Announce rest period
  Future<void> announceRest(int seconds, String nextExercise) async {
    await speak('Rest for $seconds seconds. Next up: $nextExercise.');
  }
  
  // Countdown last 3 seconds
  Future<void> announceCountdown() async {
    await speak('3, 2, 1, Go!');
  }
  
  // Announce exercise completion
  Future<void> announceComplete() async {
    await speak('Exercise complete!');
  }
  
  // Announce workout completion
  Future<void> announceWorkoutComplete() async {
    await speak('Congratulations! You have completed your workout.');
  }
  
  // Dispose resources
  void dispose() {
    _flutterTts.stop();
  }
}

final voiceGuidanceProvider = Provider<VoiceGuidanceService>((ref) {
  final voiceGuidance = VoiceGuidanceService();
  voiceGuidance.initialize();
  return voiceGuidance;
});