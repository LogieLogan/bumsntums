// lib/features/workouts/screens/exercise_selector_screen.dart
import 'package:bums_n_tums/features/workouts/models/workout.dart';
import 'package:bums_n_tums/features/workouts/screens/exercise_editor_screen.dart';
import 'package:bums_n_tums/features/workouts/widgets/exercise_demo_widget.dart';
import 'package:bums_n_tums/shared/services/exercise_media_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../providers/exercise_selector_provider.dart';
import '../../../shared/theme/app_colors.dart';

class ExerciseSelectorScreen extends ConsumerStatefulWidget {
  const ExerciseSelectorScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ExerciseSelectorScreen> createState() =>
      _ExerciseSelectorScreenState();
}

class _ExerciseSelectorScreenState extends ConsumerState<ExerciseSelectorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTargetArea = 'All';
  int? _selectedDifficulty;
  String? _selectedEquipment;
  late TabController _tabController;

  List<String> _targetAreas = [
    'All',
    'Bums',
    'Tums',
    'Arms',
    'Legs',
    'Back',
    'Chest',
    'Shoulders',
    'Full Body',
  ];

  List<String> _difficulties = [
    'All Difficulties',
    'Very Easy (1)',
    'Easy (2)',
    'Moderate (3)',
    'Hard (4)',
    'Very Hard (5)',
  ];

  List<String> _equipmentOptions = [
    'All Equipment',
    'None',
    'Dumbbell',
    'Resistance Band',
    'Kettlebell',
    'Barbell',
    'Exercise Mat',
    'Stability Ball',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

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
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exerciseState = ref.watch(exerciseSelectorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Exercise'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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

              // Tab bar for Browse/Filter
              TabBar(
                controller: _tabController,
                tabs: const [Tab(text: 'Browse'), Tab(text: 'Filter')],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Browse tab
          _buildBrowseTab(exerciseState),

          // Filter tab
          _buildFilterTab(exerciseState),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showCreateExerciseDialog(),
      ),
    );
  }

  Widget _buildBrowseTab(ExerciseSelectorState exerciseState) {
    return Column(
      children: [
        // Target area filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                      return _buildExerciseListItem(exercise);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildFilterTab(ExerciseSelectorState exerciseState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Difficulty filter
          const Text(
            'Difficulty Level',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < _difficulties.length; i++)
                ChoiceChip(
                  label: Text(_difficulties[i]),
                  selected: _selectedDifficulty == (i == 0 ? null : i),
                  onSelected: (selected) {
                    setState(() {
                      _selectedDifficulty =
                          selected ? (i == 0 ? null : i) : null;
                    });
                    ref
                        .read(exerciseSelectorProvider.notifier)
                        .filterByDifficultyLevel(
                          _selectedDifficulty == null
                              ? null
                              : _selectedDifficulty,
                        );
                  },
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Equipment filter
          const Text(
            'Equipment',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < _equipmentOptions.length; i++)
                ChoiceChip(
                  label: Text(_equipmentOptions[i]),
                  selected:
                      _selectedEquipment ==
                      (i == 0 ? null : _equipmentOptions[i].toLowerCase()),
                  onSelected: (selected) {
                    setState(() {
                      _selectedEquipment =
                          selected
                              ? (i == 0
                                  ? null
                                  : _equipmentOptions[i].toLowerCase())
                              : null;
                    });
                    ref
                        .read(exerciseSelectorProvider.notifier)
                        .filterByEquipment(_selectedEquipment);
                  },
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Results count
          Text(
            '${exerciseState.exercises.length} exercises found',
            style: Theme.of(context).textTheme.bodySmall,
          ),

          const SizedBox(height: 16),

          // Reset filters button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedTargetArea = 'All';
                  _selectedDifficulty = null;
                  _selectedEquipment = null;
                  _searchController.clear();
                });

                // Reset all filters
                ref
                    .read(exerciseSelectorProvider.notifier)
                    .filterByTargetArea(null);
                ref.read(exerciseSelectorProvider.notifier).searchExercises('');
                ref
                    .read(exerciseSelectorProvider.notifier)
                    .filterByDifficultyLevel(null);
                ref
                    .read(exerciseSelectorProvider.notifier)
                    .filterByEquipment(null);
              },
              child: const Text('Reset All Filters'),
            ),
          ),

          const SizedBox(height: 24),

          // Exercise results
          if (!exerciseState.isLoading)
            exerciseState.exercises.isEmpty
                ? const Center(child: Text('No exercises match your filters'))
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: exerciseState.exercises.length,
                  itemBuilder: (context, index) {
                    return _buildExerciseListItem(
                      exerciseState.exercises[index],
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildExerciseListItem(Exercise exercise) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 60,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                color: _getTargetAreaColor(
                  exercise.targetArea,
                ).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: ExerciseMediaService.workoutImage(
                  difficulty:
                      exercise.difficultyLevel <= 2
                          ? WorkoutDifficulty.beginner
                          : (exercise.difficultyLevel <= 4
                              ? WorkoutDifficulty.intermediate
                              : WorkoutDifficulty.advanced),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
        title: Text(exercise.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exercise.targetArea),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildDifficultyIndicator(exercise.difficultyLevel),
                const SizedBox(width: 8),
                if (exercise.durationSeconds != null)
                  Text('${exercise.durationSeconds}s')
                else
                  Text('${exercise.sets} × ${exercise.reps}'),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showExerciseDetails(exercise),
              tooltip: 'View details',
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _selectExercise(exercise),
              tooltip: 'Add to workout',
            ),
          ],
        ),
        onTap: () => _showExerciseDetails(exercise),
      ),
    );
  }

  Widget _buildDifficultyIndicator(int level) {
    Color getColor() {
      switch (level) {
        case 1:
          return Colors.green;
        case 2:
          return Colors.lightGreen;
        case 3:
          return Colors.orange;
        case 4:
          return Colors.deepOrange;
        case 5:
          return Colors.red;
        default:
          return Colors.orange;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: getColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: getColor()),
      ),
      child: Text(
        'Lvl $level',
        style: TextStyle(
          fontSize: 12,
          color: getColor(),
          fontWeight: FontWeight.bold,
        ),
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
                    // Exercise video/image using our demo widget
                    Center(
                      child: ExerciseDemoWidget(
                        exercise: exercise,
                        height: 200,
                        width: double.infinity,
                        showControls: true,
                        autoPlay: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Exercise name and difficulty
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            exercise.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        _buildDifficultyIndicator(exercise.difficultyLevel),
                      ],
                    ),

                    // Target area and muscles
                    const SizedBox(height: 8),
                    Text(
                      'Target Area: ${exercise.targetArea}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),

                    if (exercise.targetMuscles.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children:
                            exercise.targetMuscles.map((muscle) {
                              return Chip(
                                label: Text(muscle),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Exercise description
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(exercise.description),
                    const SizedBox(height: 24),

                    // Exercise parameters
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildExerciseParameter('Sets', '${exercise.sets}'),
                        exercise.durationSeconds != null
                            ? _buildExerciseParameter(
                              'Duration',
                              '${exercise.durationSeconds}s',
                            )
                            : _buildExerciseParameter(
                              'Reps',
                              '${exercise.reps}',
                            ),
                        _buildExerciseParameter(
                          'Rest',
                          '${exercise.restBetweenSeconds}s',
                        ),
                      ],
                    ),

                    // Exercise tempo if available
                    if (exercise.tempo != null) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.paleGrey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Tempo',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildTempoBox(
                                    'Down',
                                    '${exercise.tempo!['down']}',
                                  ),
                                  _buildTempoBox(
                                    'Hold',
                                    '${exercise.tempo!['hold']}',
                                  ),
                                  _buildTempoBox(
                                    'Up',
                                    '${exercise.tempo!['up']}',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Form tips if available
                    if (exercise.formTips.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Form Tips',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...exercise.formTips.map((tip) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(tip)),
                            ],
                          ),
                        );
                      }),
                    ],

                    // Common mistakes if available
                    if (exercise.commonMistakes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Common Mistakes',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...exercise.commonMistakes.map((mistake) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 16,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(mistake)),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 16),

                    // Exercise Type
                    if (exercise.exerciseType.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Exercise Type',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            exercise.exerciseType
                                .map(
                                  (type) => Chip(
                                    label: Text(type),
                                    backgroundColor: AppColors.popBlue
                                        .withOpacity(0.2),
                                    labelStyle: TextStyle(
                                      color: AppColors.popBlue,
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Preparation Steps
                    if (exercise.preparationSteps.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Preparation',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 8),
                      ...exercise.preparationSteps.map(
                        (step) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${exercise.preparationSteps.indexOf(step) + 1}.',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(step)),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Breathing Pattern
                    if (exercise.breathingPattern.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Breathing',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.air, color: AppColors.popTurquoise),
                          const SizedBox(width: 12),
                          Expanded(child: Text(exercise.breathingPattern)),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Benefits
                    if (exercise.benefits.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Benefits',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 8),
                      ...exercise.benefits.map(
                        (benefit) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.star,
                                color: AppColors.popYellow,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(benefit)),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Contraindications
                    if (exercise.contraindications.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Exercise Caution If You Have:',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...exercise.contraindications.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 4.0,
                                  left: 8.0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '•',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(item)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Equipment options
                    if (exercise.equipmentOptions.isNotEmpty) ...[
                      Text(
                        'Equipment Options',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            exercise.equipmentOptions
                                .map(
                                  (equipment) => Chip(
                                    label: Text(equipment),
                                    backgroundColor: AppColors.offWhite,
                                  ),
                                )
                                .toList(),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Action buttons
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add to Workout'),
                          onPressed: () {
                            Navigator.pop(context); // Close the bottom sheet
                            Navigator.pop(
                              context,
                              exercise,
                            ); // Return the exercise to the parent, using the parameter
                          },
                        ),
                      ],
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

  Widget _buildExerciseParameter(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildTempoBox(String label, String value) {
    return Container(
      width: 50,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _selectExercise(Exercise exercise) {
    // Instead of navigating to the editor, directly return the selected exercise
    Navigator.pop(context, exercise);
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

  Color _getTargetAreaColor(String targetArea) {
    switch (targetArea.toLowerCase()) {
      case 'bums':
        return AppColors.popCoral;
      case 'tums':
        return AppColors.popTurquoise;
      case 'arms':
        return AppColors.popBlue;
      case 'legs':
        return AppColors.popYellow;
      case 'back':
        return AppColors.popGreen;
      case 'chest':
        return AppColors.salmon;
      case 'fullbody':
        return AppColors.pink;
      default:
        return AppColors.salmon;
    }
  }
}
