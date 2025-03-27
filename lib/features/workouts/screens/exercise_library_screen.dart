// lib/features/workouts/screens/exercise_library_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../providers/exercise_providers.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/theme/color_palette.dart';
import '../widgets/exercise_list_item.dart';
import '../widgets/exercise_filter_bar.dart';
import 'package:go_router/go_router.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  String? _selectedTargetArea;
  String? _selectedEquipment;
  int? _selectedDifficulty;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    // Make sure we only load exercises after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (mounted) {
          // Initialize the exercise service (using the new provider)
          final service = ref.read(exerciseServiceProvider);
          service.initialize();
        }
      } catch (e) {
        print('Error initializing exercise library: $e');
        // Show a user-friendly error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load exercises. Please try again.'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // First determine if we need filtered or all exercises
    final exercisesAsync =
        (_selectedTargetArea != null ||
                _selectedEquipment != null ||
                _selectedDifficulty != null ||
                _searchQuery.isNotEmpty)
            ? ref.watch(
              filteredExercisesProvider(
                FilterParams(
                  targetArea: _selectedTargetArea,
                  equipment: _selectedEquipment,
                  difficultyLevel: _selectedDifficulty,
                  searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
                ),
              ),
            )
            : ref.watch(allExercisesProvider);

    final targetAreasAsync = ref.watch(targetAreasProvider);
    final equipmentTypesAsync = ref.watch(equipmentTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Library')),
      body: Column(
        children: [
          // Integrated search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Target area filter
                  targetAreasAsync.when(
                    data:
                        (areas) =>
                            areas.isEmpty
                                ? const SizedBox()
                                : ExerciseFilterBar(
                                  title: 'Target Area',
                                  options: areas,
                                  selectedOption: _selectedTargetArea,
                                  onSelected: (area) {
                                    setState(() {
                                      _selectedTargetArea =
                                          _selectedTargetArea == area
                                              ? null
                                              : area;
                                    });
                                  },
                                ),
                    loading:
                        () => const SizedBox(
                          width: 100,
                          child: LoadingIndicator(),
                        ),
                    error: (_, __) => const Text('Error loading target areas'),
                  ),

                  const SizedBox(width: 12),

                  // Equipment filter
                  equipmentTypesAsync.when(
                    data:
                        (types) =>
                            types.isEmpty
                                ? const SizedBox()
                                : ExerciseFilterBar(
                                  title: 'Equipment',
                                  options: types,
                                  selectedOption: _selectedEquipment,
                                  onSelected: (equipment) {
                                    setState(() {
                                      _selectedEquipment =
                                          _selectedEquipment == equipment
                                              ? null
                                              : equipment;
                                    });
                                  },
                                ),
                    loading:
                        () => const SizedBox(
                          width: 100,
                          child: LoadingIndicator(),
                        ),
                    error:
                        (_, __) => const Text('Error loading equipment types'),
                  ),

                  const SizedBox(width: 12),

                  // Difficulty filter
                  ExerciseFilterBar(
                    title: 'Difficulty',
                    options: const ['1', '2', '3', '4', '5'],
                    selectedOption: _selectedDifficulty?.toString(),
                    onSelected: (difficulty) {
                      setState(() {
                        final diffValue = int.parse(difficulty);
                        _selectedDifficulty =
                            _selectedDifficulty == diffValue ? null : diffValue;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // Active filters display and clear button
          if (_selectedTargetArea != null ||
              _selectedEquipment != null ||
              _selectedDifficulty != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Text(
                    'Active filters:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_selectedTargetArea != null)
                            _buildActiveFilterChip(_selectedTargetArea!, () {
                              setState(() {
                                _selectedTargetArea = null;
                              });
                            }),
                          if (_selectedEquipment != null)
                            _buildActiveFilterChip(_selectedEquipment!, () {
                              setState(() {
                                _selectedEquipment = null;
                              });
                            }),
                          if (_selectedDifficulty != null)
                            _buildActiveFilterChip(
                              'Difficulty $_selectedDifficulty',
                              () {
                                setState(() {
                                  _selectedDifficulty = null;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedTargetArea = null;
                        _selectedEquipment = null;
                        _selectedDifficulty = null;
                      });
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),

          // Exercise list
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                if (exercises.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No exercises found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try different search terms or filters'
                              : 'Try different filters',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _selectedTargetArea = null;
                              _selectedEquipment = null;
                              _selectedDifficulty = null;
                            });
                          },
                          child: const Text('Clear All Filters'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // Refresh all providers
                    ref.refresh(allExercisesProvider);
                    ref.refresh(targetAreasProvider);
                    ref.refresh(equipmentTypesProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return ExerciseListItem(
                        exercise: exercise,
                        index: index,
                        onTap: () {
                          context.push('/exercise-detail/${exercise.id}');
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: LoadingIndicator()),
              error:
                  (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Error loading exercises: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Refresh all providers
                            ref.refresh(allExercisesProvider);
                            ref.refresh(targetAreasProvider);
                            ref.refresh(equipmentTypesProvider);
                          },
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // Add this helper method to your class
  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        backgroundColor: AppColors.salmon.withOpacity(0.1),
        labelStyle: TextStyle(color: AppColors.salmon),
        deleteIconColor: AppColors.salmon,
      ),
    );
  }
}
