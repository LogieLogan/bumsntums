// lib/features/workouts/widgets/execution/exercise_settings_modal.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/analytics/firebase_analytics_service.dart';
import '../../models/exercise.dart';

class ExerciseSettingsModal extends StatefulWidget {
  final Exercise exercise;
  final Function(Exercise) onSave;

  const ExerciseSettingsModal({
    super.key,
    required this.exercise,
    required this.onSave,
  });

  @override
  State<ExerciseSettingsModal> createState() => _ExerciseSettingsModalState();
}

class _ExerciseSettingsModalState extends State<ExerciseSettingsModal> {
  late Exercise _exercise;
  bool _isSavingPreferences = false;

  // Controllers for numeric inputs
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _durationController;
  late TextEditingController _restController;
  late TextEditingController _weightController;
  late TextEditingController _resistanceController;
  
  // Controllers for new inputs
  late TextEditingController _speedController;
  late TextEditingController _gradientController;
  late TextEditingController _heightController;

  // Determine exercise equipment type
  String _exerciseType = 'bodyweight';

  @override
  void initState() {
    super.initState();
    _exercise = widget.exercise;

    // Determine exercise type based on available equipment or name
    _determineExerciseType();

    // Initialize controllers
    _setsController = TextEditingController(text: _exercise.sets.toString());
    _repsController = TextEditingController(text: _exercise.reps.toString());
    _durationController = TextEditingController(
      text: _exercise.durationSeconds?.toString() ?? '',
    );
    _restController = TextEditingController(
      text: _exercise.restBetweenSeconds.toString(),
    );
    _weightController = TextEditingController(
      text: _exercise.weight?.toString() ?? '',
    );
    _resistanceController = TextEditingController(
      text: _exercise.resistanceLevel?.toString() ?? '',
    );
    
    // Initialize new controllers based on additional data from the exercise
    // Extract from the exercise's additional parameters (stored in a Map)
    final additionalParams = _exercise.tempo ?? {};
    
    _speedController = TextEditingController(
      text: additionalParams['speed']?.toString() ?? '',
    );
    _gradientController = TextEditingController(
      text: additionalParams['gradient']?.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: additionalParams['height']?.toString() ?? '',
    );

    // Load user preferences
    _loadSavedPreferences();
  }

  void _determineExerciseType() {
    final name = _exercise.name.toLowerCase();
    final equipment = _exercise.equipmentOptions.map((e) => e.toLowerCase()).toList();
    
    if (equipment.contains('treadmill') || 
        name.contains('run') || 
        name.contains('jog') ||
        name.contains('treadmill')) {
      _exerciseType = 'treadmill';
    } else if (equipment.contains('jump box') || 
               name.contains('box jump') || 
               name.contains('jump') ||
               name.contains('leaps')) {
      _exerciseType = 'jump';
    } else if (equipment.contains('dumbbell') || 
               equipment.contains('barbell') || 
               equipment.contains('kettlebell') ||
               name.contains('dumbbell') ||
               name.contains('weight')) {
      _exerciseType = 'weights';
    } else if (equipment.contains('resistance band') || 
               name.contains('band')) {
      _exerciseType = 'resistance';
    } else {
      _exerciseType = 'bodyweight';
    }
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefKey = 'exercise_prefs_${_exercise.id}';
      
      if (prefs.containsKey(prefKey)) {
        final savedPrefsString = prefs.getString(prefKey);
        if (savedPrefsString != null) {
          final savedPrefsMap = _parsePrefsString(savedPrefsString);
          
          // Apply saved preferences if they exist
          setState(() {
            if (savedPrefsMap.containsKey('sets')) {
              _setsController.text = savedPrefsMap['sets'].toString();
            }
            if (savedPrefsMap.containsKey('reps') && !_isDurationBased()) {
              _repsController.text = savedPrefsMap['reps'].toString();
            }
            if (savedPrefsMap.containsKey('duration') && _isDurationBased()) {
              _durationController.text = savedPrefsMap['duration'].toString();
            }
            if (savedPrefsMap.containsKey('rest')) {
              _restController.text = savedPrefsMap['rest'].toString();
            }
            if (savedPrefsMap.containsKey('weight') && _showWeightInput()) {
              _weightController.text = savedPrefsMap['weight'].toString();
            }
            if (savedPrefsMap.containsKey('resistance') && _showResistanceInput()) {
              _resistanceController.text = savedPrefsMap['resistance'].toString();
            }
            if (savedPrefsMap.containsKey('speed') && _showSpeedInput()) {
              _speedController.text = savedPrefsMap['speed'].toString();
            }
            if (savedPrefsMap.containsKey('gradient') && _showGradientInput()) {
              _gradientController.text = savedPrefsMap['gradient'].toString();
            }
            if (savedPrefsMap.containsKey('height') && _showHeightInput()) {
              _heightController.text = savedPrefsMap['height'].toString();
            }
          });
        }
      }
    } catch (e) {
      // Handle errors silently - preferences are optional
      debugPrint('Error loading preferences: $e');
    }
  }

  // Simple parsing of saved preferences string
  Map<String, dynamic> _parsePrefsString(String prefsString) {
    try {
      final result = <String, dynamic>{};
      final pairs = prefsString.split(',');
      
      for (final pair in pairs) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          final key = parts[0].trim();
          final value = parts[1].trim();
          
          // Try to convert to numeric values if possible
          if (double.tryParse(value) != null) {
            result[key] = double.parse(value);
          } else {
            result[key] = value;
          }
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('Error parsing preferences: $e');
      return {};
    }
  }

  Future<void> _savePreferences() async {
    try {
      setState(() {
        _isSavingPreferences = true;
      });
      
      final prefs = await SharedPreferences.getInstance();
      final prefKey = 'exercise_prefs_${_exercise.id}';
      
      // Build preferences string
      final prefsMap = <String, dynamic>{
        'sets': int.tryParse(_setsController.text) ?? _exercise.sets,
      };
      
      if (_isDurationBased()) {
        prefsMap['duration'] = int.tryParse(_durationController.text) ?? _exercise.durationSeconds;
      } else {
        prefsMap['reps'] = int.tryParse(_repsController.text) ?? _exercise.reps;
      }
      
      prefsMap['rest'] = int.tryParse(_restController.text) ?? _exercise.restBetweenSeconds;
      
      if (_weightController.text.isNotEmpty && _showWeightInput()) {
        prefsMap['weight'] = double.tryParse(_weightController.text);
      }
      
      if (_resistanceController.text.isNotEmpty && _showResistanceInput()) {
        prefsMap['resistance'] = int.tryParse(_resistanceController.text);
      }
      
      if (_speedController.text.isNotEmpty && _showSpeedInput()) {
        prefsMap['speed'] = double.tryParse(_speedController.text);
      }
      
      if (_gradientController.text.isNotEmpty && _showGradientInput()) {
        prefsMap['gradient'] = double.tryParse(_gradientController.text);
      }
      
      if (_heightController.text.isNotEmpty && _showHeightInput()) {
        prefsMap['height'] = double.tryParse(_heightController.text);
      }
      
      // Convert to string
      final prefsString = prefsMap.entries
          .where((e) => e.value != null)
          .map((e) => '${e.key}:${e.value}')
          .join(',');
      
      await prefs.setString(prefKey, prefsString);
      
      // Log analytics event
      final analytics = AnalyticsService();
      analytics.logEvent(
        name: 'exercise_preferences_saved', 
        parameters: {'exercise_id': _exercise.id}
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your preferences have been saved'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error saving preferences: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving preferences: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSavingPreferences = false;
      });
    }
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _durationController.dispose();
    _restController.dispose();
    _weightController.dispose();
    _resistanceController.dispose();
    _speedController.dispose();
    _gradientController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  bool _isDurationBased() {
    return _exercise.durationSeconds != null;
  }

  // Helper methods to determine which inputs to show
  bool _showWeightInput() {
    return _exerciseType == 'weights';
  }

  bool _showResistanceInput() {
    return _exerciseType == 'resistance';
  }

  bool _showSpeedInput() {
    return _exerciseType == 'treadmill';
  }

  bool _showGradientInput() {
    return _exerciseType == 'treadmill';
  }

  bool _showHeightInput() {
    return _exerciseType == 'jump';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercise Settings',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          // Exercise name
          Text(_exercise.name, style: Theme.of(context).textTheme.titleMedium),

          // Exercise Type Tag
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getExerciseTypeColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _exerciseTypeToString(),
              style: TextStyle(color: _getExerciseTypeColor(), fontWeight: FontWeight.bold),
            ),
          ),
          
          const SizedBox(height: 24),

          // Main settings form
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sets and reps/duration section
                  _buildSection(
                    title: 'Sets & Repetitions',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildNumberInput(
                              label: 'Sets',
                              controller: _setsController,
                              min: 1,
                              max: 10,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child:
                                _isDurationBased()
                                    ? _buildNumberInput(
                                      label: 'Duration (seconds)',
                                      controller: _durationController,
                                      min: 5,
                                      max: 300,
                                    )
                                    : _buildNumberInput(
                                      label: 'Reps',
                                      controller: _repsController,
                                      min: 1,
                                      max: 100,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildNumberInput(
                        label: 'Rest between sets (seconds)',
                        controller: _restController,
                        min: 0,
                        max: 300,
                      ),

                      // Add an option to switch between timed and rep-based exercise
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'Exercise Type:',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 16),
                          ToggleButtons(
                            isSelected: [
                              !_isDurationBased(),
                              _isDurationBased(),
                            ],
                            onPressed: (index) {
                              setState(() {
                                if (index == 0 &&
                                    _isDurationBased()) {
                                  // Switch to reps-based
                                  _exercise = _exercise.copyWith(
                                    durationSeconds: null,
                                    reps:
                                        int.tryParse(_repsController.text) ??
                                        10,
                                  );
                                } else if (index == 1 &&
                                    !_isDurationBased()) {
                                  // Switch to time-based
                                  _exercise = _exercise.copyWith(
                                    durationSeconds:
                                        int.tryParse(
                                          _durationController.text,
                                        ) ??
                                        30,
                                  );
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('Reps Based'),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('Time Based'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Dynamic Equipment-Specific Settings
                  if (_showWeightInput() || _showResistanceInput())
                    _buildSection(
                      title: 'Weight & Resistance',
                      children: [
                        if (_showWeightInput())
                          _buildNumberInput(
                            label: 'Weight (kg)',
                            controller: _weightController,
                            min: 0,
                            max: 200,
                            allowDecimal: true,
                          ),
                          
                        if (_showWeightInput() && _showResistanceInput())
                          const SizedBox(height: 16),
                          
                        if (_showResistanceInput())
                          _buildNumberInput(
                            label: 'Resistance Level (1-5)',
                            controller: _resistanceController,
                            min: 1,
                            max: 5,
                          ),
                      ],
                    ),

                  // Treadmill specific settings
                  if (_showSpeedInput() || _showGradientInput())
                    _buildSection(
                      title: 'Treadmill Settings',
                      children: [
                        if (_showSpeedInput())
                          _buildNumberInput(
                            label: 'Speed (km/h)',
                            controller: _speedController,
                            min: 0,
                            max: 20,
                            allowDecimal: true,
                          ),
                          
                        if (_showSpeedInput() && _showGradientInput())
                          const SizedBox(height: 16),
                          
                        if (_showGradientInput())
                          _buildNumberInput(
                            label: 'Gradient (%)',
                            controller: _gradientController,
                            min: 0,
                            max: 20,
                            allowDecimal: true,
                          ),
                      ],
                    ),

                  // Jump-specific settings
                  if (_showHeightInput())
                    _buildSection(
                      title: 'Jump Settings',
                      children: [
                        _buildNumberInput(
                          label: 'Box Height (cm)',
                          controller: _heightController,
                          min: 10,
                          max: 100,
                          allowDecimal: false,
                        ),
                      ],
                    ),

                  // Difficulty level section
                  _buildSection(
                    title: 'Difficulty Level',
                    children: [
                      Slider(
                        value: _exercise.difficultyLevel.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: _getDifficultyLabel(_exercise.difficultyLevel),
                        activeColor: AppColors.salmon,
                        onChanged: (value) {
                          setState(() {
                            _exercise = _exercise.copyWith(
                              difficultyLevel: value.toInt(),
                            );
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Easier',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Harder',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Tempo section if available
                  if (_exercise.tempo != null) _buildTempoSection(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Save default preferences option
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: OutlinedButton.icon(
              onPressed: _isSavingPreferences ? null : _savePreferences,
              icon: _isSavingPreferences
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bookmark_outline),
              label: Text(_isSavingPreferences ? 'Saving...' : 'Save as Default'),
            ),
          ),

          // Save button
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('Apply Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.paleGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNumberInput({
    required String label,
    required TextEditingController controller,
    required int min,
    required int max,
    bool allowDecimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                final currentValue =
                    allowDecimal
                        ? double.tryParse(controller.text) ?? min.toDouble()
                        : int.tryParse(controller.text) ?? min;

                if (allowDecimal) {
                  final newValue = (currentValue as double) - (label.contains('Weight') ? 2.5 : 0.5);
                  if (newValue >= min) {
                    controller.text = newValue.toString();
                  }
                } else {
                  final newValue = (currentValue as int) - 1;
                  if (newValue >= min) {
                    controller.text = newValue.toString();
                  }
                }
              },
            ),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType:
                    allowDecimal
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                inputFormatters: [
                  allowDecimal
                      ? FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))
                      : FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                final currentValue =
                    allowDecimal
                        ? double.tryParse(controller.text) ?? min.toDouble()
                        : int.tryParse(controller.text) ?? min;

                if (allowDecimal) {
                  final newValue = (currentValue as double) + (label.contains('Weight') ? 2.5 : 0.5);
                  if (newValue <= max) {
                    controller.text = newValue.toString();
                  }
                } else {
                  final newValue = (currentValue as int) + 1;
                  if (newValue <= max) {
                    controller.text = newValue.toString();
                  }
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTempoSection() {
    return _buildSection(
      title: 'Movement Tempo',
      children: [
        Text(
          'Control the speed of your movement phases',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTempoButton('Slow', 'slow'),
            _buildTempoButton('Medium', 'medium'),
            _buildTempoButton('Fast', 'fast'),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'You can use tempo to control the speed of different phases of an exercise:',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          '• Slow: Controlled movements with focus on form',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          '• Medium: Balanced pace with moderate tension',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          '• Fast: Dynamic movements for power and cardio',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildTempoButton(String label, String value) {
    final isSelected = (_exercise.tempo?['type'] ?? 'medium') == value;

    return InkWell(
      onTap: () {
        setState(() {
          final updatedTempo = Map<String, dynamic>.from(_exercise.tempo ?? {});
          updatedTempo['type'] = value;
          _exercise = _exercise.copyWith(tempo: updatedTempo);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.salmon : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.salmon : AppColors.lightGrey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _getDifficultyLabel(int difficultyLevel) {
    switch (difficultyLevel) {
      case 1:
        return 'Very Easy';
      case 2:
        return 'Easy';
      case 3:
        return 'Moderate';
      case 4:
        return 'Hard';
      case 5:
        return 'Very Hard';
      default:
        return 'Moderate';
    }
  }

  String _exerciseTypeToString() {
    switch (_exerciseType) {
      case 'treadmill':
        return 'Treadmill/Cardio';
      case 'jump':
        return 'Jumping Exercise';
      case 'weights':
        return 'Weighted Exercise';
      case 'resistance':
        return 'Resistance Exercise';
      case 'bodyweight':
      default:
        return 'Bodyweight Exercise';
    }
  }

  Color _getExerciseTypeColor() {
    switch (_exerciseType) {
      case 'treadmill':
        return AppColors.popBlue;
      case 'jump':
        return AppColors.popGreen;
      case 'weights':
        return AppColors.popCoral;
      case 'resistance':
        return AppColors.popYellow;
      case 'bodyweight':
      default:
        return AppColors.popTurquoise;
    }
  }

  void _saveSettings() {
    // Validate and parse input values
    final sets = int.tryParse(_setsController.text) ?? _exercise.sets;
    final reps = int.tryParse(_repsController.text) ?? _exercise.reps;

    int? durationSeconds;
    if (_isDurationBased() && _durationController.text.isNotEmpty) {
      durationSeconds = int.tryParse(_durationController.text);
    }

    final restBetweenSeconds =
        int.tryParse(_restController.text) ?? _exercise.restBetweenSeconds;

    // Parse optional numeric values
    double? weight;
    if (_weightController.text.isNotEmpty && _showWeightInput()) {
      weight = double.tryParse(_weightController.text);
    }

    int? resistanceLevel;
    if (_resistanceController.text.isNotEmpty && _showResistanceInput()) {
      resistanceLevel = int.tryParse(_resistanceController.text);
    }
    
    // Create/update the additional parameters Map for new settings
    final Map<String, dynamic> additionalParams = Map.from(_exercise.tempo ?? {});
    
    if (_speedController.text.isNotEmpty && _showSpeedInput()) {
      additionalParams['speed'] = double.tryParse(_speedController.text);
    }
    
    if (_gradientController.text.isNotEmpty && _showGradientInput()) {
      additionalParams['gradient'] = double.tryParse(_gradientController.text);
    }
    
    if (_heightController.text.isNotEmpty && _showHeightInput()) {
      additionalParams['height'] = double.tryParse(_heightController.text);
    }

    // Create updated exercise
    final updatedExercise = _exercise.copyWith(
      sets: sets,
      reps: reps,
      durationSeconds: durationSeconds,
      restBetweenSeconds: restBetweenSeconds,
      weight: weight,
      resistanceLevel: resistanceLevel,
      tempo: additionalParams,
    );

    // Call the save callback
    widget.onSave(updatedExercise);

    // Close the modal
    Navigator.pop(context);
  }
}