// lib/features/workouts/screens/exercise_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';

class ExerciseEditorScreen extends ConsumerStatefulWidget {
  final Exercise? exercise;
  final bool isNewExercise;

  const ExerciseEditorScreen({
    Key? key,
    this.exercise,
    this.isNewExercise = false,
  }) : super(key: key);

  @override
  ConsumerState<ExerciseEditorScreen> createState() => _ExerciseEditorScreenState();
}

class _ExerciseEditorScreenState extends ConsumerState<ExerciseEditorScreen> {
  late Exercise _currentExercise;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for basic fields
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _restController;
  
  // Controllers for enhanced fields
  late TextEditingController _weightController;
  late TextEditingController _resistanceController;
  late TextEditingController _tempoDownController;
  late TextEditingController _tempoHoldController;
  late TextEditingController _tempoUpController;
  
  // State for form tips and common mistakes
  List<String> _formTips = [];
  List<String> _commonMistakes = [];
  List<String> _targetMuscles = [];
  List<String> _equipmentOptions = [];
  List<String> _progressionExercises = [];
  List<String> _regressionExercises = [];
  
  int _difficultyLevel = 3;
  bool _isDurationBased = false;
  String _targetArea = 'bums';

  @override
  void initState() {
    super.initState();
    
    _initializeExercise();
    
    // Initialize controllers for the fields
    _nameController = TextEditingController(text: _currentExercise.name);
    _descriptionController = TextEditingController(text: _currentExercise.description);
    _setsController = TextEditingController(text: _currentExercise.sets.toString());
    _repsController = TextEditingController(
      text: _currentExercise.reps.toString()
    );
    _restController = TextEditingController(
      text: _currentExercise.restBetweenSeconds.toString()
    );
    
    // Initialize enhanced field controllers
    _weightController = TextEditingController(
      text: _currentExercise.weight?.toString() ?? ''
    );
    _resistanceController = TextEditingController(
      text: _currentExercise.resistanceLevel?.toString() ?? ''
    );
    
    // Initialize tempo controllers
    final tempoMap = _currentExercise.tempo ?? {'down': 2, 'hold': 0, 'up': 2};
    _tempoDownController = TextEditingController(
      text: tempoMap['down']?.toString() ?? '2'
    );
    _tempoHoldController = TextEditingController(
      text: tempoMap['hold']?.toString() ?? '0'
    );
    _tempoUpController = TextEditingController(
      text: tempoMap['up']?.toString() ?? '2'
    );
    
    // Initialize other fields
    _formTips = List.from(_currentExercise.formTips);
    _commonMistakes = List.from(_currentExercise.commonMistakes);
    _targetMuscles = List.from(_currentExercise.targetMuscles);
    _equipmentOptions = List.from(_currentExercise.equipmentOptions);
    _progressionExercises = List.from(_currentExercise.progressionExercises);
    _regressionExercises = List.from(_currentExercise.regressionExercises);
    
    _difficultyLevel = _currentExercise.difficultyLevel;
    _isDurationBased = _currentExercise.durationSeconds != null;
    _targetArea = _currentExercise.targetArea;
  }

  void _initializeExercise() {
    if (widget.exercise != null) {
      _currentExercise = widget.exercise!;
    } else {
      // Create a new empty exercise
      _currentExercise = Exercise(
        id: '',
        name: '',
        description: '',
        imageUrl: 'assets/images/exercises/default.jpg',
        sets: 3,
        reps: 12,
        restBetweenSeconds: 60,
        targetArea: 'bums',
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _restController.dispose();
    _weightController.dispose();
    _resistanceController.dispose();
    _tempoDownController.dispose();
    _tempoHoldController.dispose();
    _tempoUpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNewExercise ? 'Create Exercise' : 'Edit Exercise'),
        actions: [
          TextButton(
            onPressed: _saveExercise,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic information section
              _buildBasicInfoSection(),
              
              const SizedBox(height: 24),
              const Divider(),
              
              // Exercise details section
              _buildExerciseDetailsSection(),
              
              const SizedBox(height: 24),
              const Divider(),
              
              // Advanced options section - collapsible
              _buildAdvancedOptionsSection(),
              
              const SizedBox(height: 32),
              
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveExercise,
                  child: const Text('Save Exercise'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Exercise Name',
            hintText: 'e.g., Squats, Push-ups',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an exercise name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Exercise description
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Describe the exercise and its execution',
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildExerciseDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exercise Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Duration vs Reps toggle
        SwitchListTile(
          title: const Text('Duration-based Exercise'),
          subtitle: Text(_isDurationBased 
            ? 'Exercise is timed (e.g., Plank)' 
            : 'Exercise is rep-based (e.g., Squats)'
          ),
          value: _isDurationBased,
          onChanged: (value) {
            setState(() {
              _isDurationBased = value;
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        // Sets input
        TextFormField(
          controller: _setsController,
          decoration: const InputDecoration(
            labelText: 'Sets',
            hintText: 'Number of sets',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter number of sets';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Reps or Duration based on toggle
        if (_isDurationBased) 
          TextFormField(
            controller: _repsController,
            decoration: const InputDecoration(
              labelText: 'Duration (seconds)',
              hintText: 'e.g., 30, 45, 60',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the duration';
              }
              return null;
            },
          )
        else
          TextFormField(
            controller: _repsController,
            decoration: const InputDecoration(
              labelText: 'Reps per Set',
              hintText: 'e.g., 10, 12, 15',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter number of reps';
              }
              return null;
            },
          ),
        
        const SizedBox(height: 16),
        
        // Rest between sets
        TextFormField(
          controller: _restController,
          decoration: const InputDecoration(
            labelText: 'Rest Between Sets (seconds)',
            hintText: 'e.g., 30, 45, 60',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter rest time';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 24),
        
        // Weight input (if applicable)
        TextFormField(
          controller: _weightController,
          decoration: const InputDecoration(
            labelText: 'Weight (kg/lbs) - Optional',
            hintText: 'Leave empty if bodyweight only',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Resistance level (if applicable)
        TextFormField(
          controller: _resistanceController,
          decoration: const InputDecoration(
            labelText: 'Resistance Level (1-10) - Optional',
            hintText: 'For resistance bands or machines',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }

  Widget _buildAdvancedOptionsSection() {
    return ExpansionTile(
      title: const Text(
        'Advanced Options',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target muscles section
              const SizedBox(height: 16),
              const Text('Target Muscles',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildStringListEditor(
                _targetMuscles, 
                'Add Target Muscle',
                'e.g., gluteus maximus, quadriceps',
                (value) {
                  setState(() {
                    _targetMuscles.add(value);
                  });
                },
                (index) {
                  setState(() {
                    _targetMuscles.removeAt(index);
                  });
                },
              ),
              
              // Equipment options section
              const SizedBox(height: 24),
              const Text('Equipment Options',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildStringListEditor(
                _equipmentOptions, 
                'Add Equipment Option',
                'e.g., dumbbells, resistance band',
                (value) {
                  setState(() {
                    _equipmentOptions.add(value);
                  });
                },
                (index) {
                  setState(() {
                    _equipmentOptions.removeAt(index);
                  });
                },
              ),
              
              // Form tips section
              const SizedBox(height: 24),
              const Text('Form Tips',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildStringListEditor(
                _formTips, 
                'Add Form Tip',
                'e.g., Keep your back straight',
                (value) {
                  setState(() {
                    _formTips.add(value);
                  });
                },
                (index) {
                  setState(() {
                    _formTips.removeAt(index);
                  });
                },
              ),
              
              // Common mistakes section
              const SizedBox(height: 24),
              const Text('Common Mistakes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildStringListEditor(
                _commonMistakes, 
                'Add Common Mistake',
                'e.g., Knees caving inward',
                (value) {
                  setState(() {
                    _commonMistakes.add(value);
                  });
                },
                (index) {
                  setState(() {
                    _commonMistakes.removeAt(index);
                  });
                },
              ),
              
              // Progression exercises section
              const SizedBox(height: 24),
              const Text('Progression Exercises (Harder Variations)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildStringListEditor(
                _progressionExercises, 
                'Add Progression',
                'e.g., Single-leg variation',
                (value) {
                  setState(() {
                    _progressionExercises.add(value);
                  });
                },
                (index) {
                  setState(() {
                    _progressionExercises.removeAt(index);
                  });
                },
              ),
              
              // Regression exercises section
              const SizedBox(height: 24),
              const Text('Regression Exercises (Easier Variations)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildStringListEditor(
                _regressionExercises, 
                'Add Regression',
                'e.g., Assisted variation',
                (value) {
                  setState(() {
                    _regressionExercises.add(value);
                  });
                },
                (index) {
                  setState(() {
                    _regressionExercises.removeAt(index);
                  });
                },
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStringListEditor(
    List<String> items,
    String addButtonText,
    String hintText,
    Function(String) onAdd,
    Function(int) onRemove,
  ) {
    // Text controller for adding new items
    final TextEditingController controller = TextEditingController();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // List of existing items
        if (items.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(items[index]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => onRemove(index),
                ),
              );
            },
          ),
          
        // Add new item section
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  onAdd(controller.text);
                  controller.clear();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  void _saveExercise() {
    if (_formKey.currentState!.validate()) {
      // Create/update the exercise object
      final exercise = Exercise(
        id: _currentExercise.id.isNotEmpty 
            ? _currentExercise.id 
            : 'custom-${const Uuid().v4()}',
        name: _nameController.text,
        description: _descriptionController.text,
        imageUrl: _currentExercise.imageUrl,
        youtubeVideoId: _currentExercise.youtubeVideoId,
        sets: int.tryParse(_setsController.text) ?? 3,
        reps: int.tryParse(_repsController.text) ?? 12,
        durationSeconds: _isDurationBased 
            ? int.tryParse(_repsController.text) 
            : null,
        restBetweenSeconds: int.tryParse(_restController.text) ?? 60,
        targetArea: _targetArea,
        weight: _weightController.text.isNotEmpty 
            ? double.tryParse(_weightController.text)
            : null,
        resistanceLevel: _resistanceController.text.isNotEmpty
            ? int.tryParse(_resistanceController.text)
            : null,
        tempo: {
          'down': int.tryParse(_tempoDownController.text) ?? 2,
          'hold': int.tryParse(_tempoHoldController.text) ?? 0,
          'up': int.tryParse(_tempoUpController.text) ?? 2,
        },
        difficultyLevel: _difficultyLevel,
        targetMuscles: _targetMuscles,
        formTips: _formTips,
        commonMistakes: _commonMistakes,
        progressionExercises: _progressionExercises,
        regressionExercises: _regressionExercises,
        equipmentOptions: _equipmentOptions,
      );
      
      // Return the exercise to the calling screen
      Navigator.pop(context, exercise);
    }
  }
}