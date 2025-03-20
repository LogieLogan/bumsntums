// lib/features/workouts/screens/exercise_selector_screen.dart
import 'package:bums_n_tums/features/workouts/screens/exercise_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../providers/exercise_selector_provider.dart';

class ExerciseSelectorScreen extends ConsumerStatefulWidget {
  const ExerciseSelectorScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ExerciseSelectorScreen> createState() =>
      _ExerciseSelectorScreenState();
}

class _ExerciseSelectorScreenState
    extends ConsumerState<ExerciseSelectorScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTargetArea = 'All';
  List<String> _targetAreas = [
    'All',
    'Bums',
    'Tums',
    'Arms',
    'Legs',
    'Back',
    'Chest',
    'Shoulders',
  ];

  @override
  void initState() {
    super.initState();

    // Make sure we only load exercises after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (mounted) {
          ref.read(exerciseSelectorProvider.notifier).loadExercises();
        }
      } catch (e) {
        print('Error initializing exercise selector: $e');
        // Show a user-friendly error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load exercises. Please try again.'),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exerciseState = ref.watch(exerciseSelectorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Exercise'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(exerciseSelectorProvider.notifier)
                                .searchExercises('');
                          },
                        )
                        : null,
              ),
              onChanged: (value) {
                ref
                    .read(exerciseSelectorProvider.notifier)
                    .searchExercises(value);
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Target area filter chips
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    _targetAreas.map((area) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(area),
                          selected: _selectedTargetArea == area,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedTargetArea = area;
                              });
                              ref
                                  .read(exerciseSelectorProvider.notifier)
                                  .filterByTargetArea(
                                    area == 'All' ? null : area.toLowerCase(),
                                  );
                            }
                          },
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),

          Expanded(
            child:
                exerciseState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : exerciseState.exercises.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No exercises found'),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => _showCreateExerciseDialog(),
                            child: const Text('Create Custom Exercise'),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: exerciseState.exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = exerciseState.exercises[index];
                        return ListTile(
                          leading:
                              exercise.imageUrl.startsWith('http')
                                  ? Image.network(
                                    exercise.imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, e, s) => const Icon(
                                          Icons.fitness_center,
                                          size: 40,
                                        ),
                                  )
                                  : Image.asset(
                                    exercise.imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, e, s) => const Icon(
                                          Icons.fitness_center,
                                          size: 40,
                                        ),
                                  ),
                          title: Text(exercise.name),
                          subtitle: Text(exercise.targetArea),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _selectExercise(exercise),
                          ),
                          onTap: () => _showExerciseDetails(exercise),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showCreateExerciseDialog(),
      ),
    );
  }

  void _showExerciseDetails(Exercise exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child:
                          exercise.imageUrl.startsWith('http')
                              ? Image.network(
                                exercise.imageUrl,
                                height: 200,
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (context, e, s) => const Icon(
                                      Icons.fitness_center,
                                      size: 100,
                                    ),
                              )
                              : Image.asset(
                                exercise.imageUrl,
                                height: 200,
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (context, e, s) => const Icon(
                                      Icons.fitness_center,
                                      size: 100,
                                    ),
                              ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Target Area: ${exercise.targetArea}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(exercise.description),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            const Text('Sets'),
                            const SizedBox(height: 4),
                            Text(
                              '${exercise.sets}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Reps'),
                            const SizedBox(height: 4),
                            Text(
                              '${exercise.reps}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                // Continuing lib/features/workouts/screens/exercise_selector_screen.dart
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Rest'),
                            const SizedBox(height: 4),
                            Text(
                              '${exercise.restBetweenSeconds}s',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _selectExercise(exercise);
                        },
                        child: const Text('Add to Workout'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _selectExercise(Exercise exercise) {
    // Navigate to the exercise configuration screen
    Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                ExerciseEditorScreen(exercise: exercise, isNewExercise: false),
      ),
    ).then((configuredExercise) {
      if (configuredExercise != null) {
        Navigator.pop(context, configuredExercise);
      }
    });
  }

  Future<void> _showCreateExerciseDialog() async {
    Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (context) => const ExerciseEditorScreen(isNewExercise: true),
      ),
    ).then((newExercise) {
      if (newExercise != null) {
        Navigator.pop(context, newExercise);
      }
    });
  }
}
