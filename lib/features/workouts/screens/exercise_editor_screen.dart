// lib/features/workouts/screens/exercise_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../services/exercise_db_service.dart';

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
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _restController;
  String _selectedTargetArea = 'bums';
  final List<String> _targetAreas = ['bums', 'tums', 'arms', 'legs', 'back', 'chest', 'shoulders'];
  bool _isLoadingImage = false;
  
  @override
  void initState() {
    super.initState();
    final exercise = widget.exercise;
    _nameController = TextEditingController(text: exercise?.name ?? '');
    _descriptionController = TextEditingController(text: exercise?.description ?? '');
    _imageUrlController = TextEditingController(text: exercise?.imageUrl ?? '');
    _setsController = TextEditingController(text: (exercise?.sets ?? 3).toString());
    _repsController = TextEditingController(text: (exercise?.reps ?? 12).toString());
    _restController = TextEditingController(
      text: (exercise?.restBetweenSeconds ?? 60).toString(),
    );
    _selectedTargetArea = exercise?.targetArea ?? 'bums';
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _restController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNewExercise ? 'Create Exercise' : 'Edit Exercise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveExercise,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                  hintText: 'e.g., Squats',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter exercise name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe how to perform this exercise',
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Target area selection
              DropdownButtonFormField<String>(
                value: _selectedTargetArea,
                decoration: const InputDecoration(labelText: 'Target Area'),
                items: _targetAreas.map((area) {
                  return DropdownMenuItem(
                    value: area,
                    child: Text(area.substring(0, 1).toUpperCase() + area.substring(1)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedTargetArea = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a target area';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Sets, reps, and rest inputs in a row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _setsController,
                      decoration: const InputDecoration(
                        labelText: 'Sets',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final sets = int.tryParse(value);
                        if (sets == null || sets < 1) {
                          return 'Min 1';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _repsController,
                      decoration: const InputDecoration(
                        labelText: 'Reps',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final reps = int.tryParse(value);
                        if (reps == null || reps < 1) {
                          return 'Min 1';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _restController,
                      decoration: const InputDecoration(
                        labelText: 'Rest (sec)',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final rest = int.tryParse(value);
                        if (rest == null || rest < 5) {
                          return 'Min 5';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Image section
              const Text(
                'Exercise Image',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // Image preview
              if (_imageUrlController.text.isNotEmpty) ...[
                Center(
                  child: _imageUrlController.text.startsWith('http')
                      ? Image.network(
                          _imageUrlController.text,
                          height: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (context, e, s) => 
                              const Icon(Icons.broken_image, size: 100),
                        )
                      : Image.asset(
                          _imageUrlController.text,
                          height: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (context, e, s) => 
                              const Icon(Icons.broken_image, size: 100),
                        ),
                ),
                const SizedBox(height: 16),
              ],
              
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'https://example.com/image.jpg or assets/images/...',
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
  
  void _saveExercise() {
    if (_formKey.currentState!.validate()) {
      final exercise = Exercise(
        id: widget.exercise?.id ?? 'custom-${const Uuid().v4()}',
        name: _nameController.text,
        description: _descriptionController.text,
        imageUrl: _imageUrlController.text.isEmpty
            ? 'assets/images/exercises/placeholder.jpg'
            : _imageUrlController.text,
        sets: int.parse(_setsController.text),
        reps: int.parse(_repsController.text),
        restBetweenSeconds: int.parse(_restController.text),
        targetArea: _selectedTargetArea,
        modifications: widget.exercise?.modifications ?? [],
      );
      
      Navigator.pop(context, exercise);
    }
  }
}