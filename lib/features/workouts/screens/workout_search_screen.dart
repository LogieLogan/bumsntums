// lib/features/workouts/screens/workout_search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../widgets/workout_card.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/theme/color_palette.dart';

class WorkoutSearchScreen extends ConsumerStatefulWidget {
  const WorkoutSearchScreen({super.key});

  @override
  ConsumerState<WorkoutSearchScreen> createState() =>
      _WorkoutSearchScreenState();
}

class _WorkoutSearchScreenState extends ConsumerState<WorkoutSearchScreen> {
  final AnalyticsService _analytics = AnalyticsService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  WorkoutDifficulty? _selectedDifficulty;
  List<String>? _selectedEquipment;
  RangeValues _durationRange = const RangeValues(5, 60);

  @override
  void initState() {
    super.initState();
    _analytics.logScreenView(screenName: 'workout_search');

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allWorkoutsAsync = ref.watch(allWorkoutsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Workouts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search workouts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                        : null,
              ),
            ),
          ),

          // Filter chips
          if (_selectedDifficulty != null || _selectedEquipment != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Difficulty filter chip
                    if (_selectedDifficulty != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(_getDifficultyText(_selectedDifficulty!)),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() {
                              _selectedDifficulty = null;
                            });
                          },
                        ),
                      ),

                    // Equipment filter chips
                    if (_selectedEquipment != null)
                      ..._selectedEquipment!.map(
                        (equipment) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(equipment),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                _selectedEquipment!.remove(equipment);
                                if (_selectedEquipment!.isEmpty) {
                                  _selectedEquipment = null;
                                }
                              });
                            },
                          ),
                        ),
                      ),

                    // Duration range chip
                    Chip(
                      label: Text(
                        '${_durationRange.start.round()}-${_durationRange.end.round()} min',
                      ),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _durationRange = const RangeValues(5, 60);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Results
          Expanded(
            child: allWorkoutsAsync.when(
              data: (workouts) {
                final filteredWorkouts = _filterWorkouts(workouts);

                if (filteredWorkouts.isEmpty) {
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
                        Text(
                          'No workouts found',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredWorkouts.length,
                  itemBuilder: (context, index) {
                    final workout = filteredWorkouts[index];
                    return WorkoutCard(
                      workout: workout,
                      onTap: () => _navigateToWorkoutDetail(workout),
                    );
                  },
                );
              },
              loading: () => const Center(child: LoadingIndicator()),
              error:
                  (error, stack) =>
                      Center(child: Text('Error loading workouts: $error')),
            ),
          ),
        ],
      ),
    );
  }

  List<Workout> _filterWorkouts(List<Workout> workouts) {
    return workouts.where((workout) {
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final title = workout.title.toLowerCase();
        final description = workout.description.toLowerCase();

        if (!title.contains(query) && !description.contains(query)) {
          return false;
        }
      }

      // Filter by difficulty
      if (_selectedDifficulty != null &&
          workout.difficulty != _selectedDifficulty) {
        return false;
      }

      // Filter by equipment
      if (_selectedEquipment != null && _selectedEquipment!.isNotEmpty) {
        // Check if workout requires any of the selected equipment
        if (!_selectedEquipment!.any((e) => workout.equipment.contains(e))) {
          return false;
        }
      }

      // Filter by duration
      final minDuration = _durationRange.start.round();
      final maxDuration = _durationRange.end.round();
      if (workout.durationMinutes < minDuration ||
          workout.durationMinutes > maxDuration) {
        return false;
      }

      return true;
    }).toList();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder: (context, setModalState) {
              return DraggableScrollableSheet(
                initialChildSize: 0.7,
                maxChildSize: 0.9,
                minChildSize: 0.5,
                expand: false,
                builder: (context, scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Filter Workouts',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              TextButton(
                                onPressed: () {
                                  setModalState(() {
                                    _selectedDifficulty = null;
                                    _selectedEquipment = null;
                                    _durationRange = const RangeValues(5, 60);
                                  });
                                },
                                child: const Text('Reset All'),
                              ),
                            ],
                          ),
                          const Divider(),

                          // Difficulty filter
                          Text(
                            'Difficulty',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children:
                                WorkoutDifficulty.values.map((difficulty) {
                                  final isSelected =
                                      _selectedDifficulty == difficulty;

                                  return ChoiceChip(
                                    label: Text(_getDifficultyText(difficulty)),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setModalState(() {
                                        _selectedDifficulty =
                                            selected ? difficulty : null;
                                      });
                                    },
                                    backgroundColor: Colors.white,
                                    selectedColor: AppColors.salmon.withOpacity(
                                      0.2,
                                    ),
                                    labelStyle: TextStyle(
                                      color:
                                          isSelected
                                              ? AppColors.salmon
                                              : Colors.black,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  );
                                }).toList(),
                          ),

                          const SizedBox(height: 16),

                          // Duration filter
                          Text(
                            'Duration (minutes)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                _durationRange.start.round().toString(),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Expanded(
                                child: RangeSlider(
                                  values: _durationRange,
                                  min: 5,
                                  max: 60,
                                  divisions: 11,
                                  labels: RangeLabels(
                                    _durationRange.start.round().toString(),
                                    _durationRange.end.round().toString(),
                                  ),
                                  onChanged: (values) {
                                    setModalState(() {
                                      _durationRange = values;
                                    });
                                  },
                                  activeColor: AppColors.salmon,
                                  inactiveColor: AppColors.paleGrey,
                                ),
                              ),
                              Text(
                                _durationRange.end.round().toString(),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Equipment filter
                          Text(
                            'Equipment',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children:
                                [
                                  'none',
                                  'mat',
                                  'resistance band',
                                  'dumbbells',
                                  'kettlebell',
                                ].map((equipment) {
                                  final isSelected =
                                      _selectedEquipment?.contains(equipment) ??
                                      false;

                                  return FilterChip(
                                    label: Text(equipment),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setModalState(() {
                                        _selectedEquipment ??= [];

                                        if (selected) {
                                          _selectedEquipment!.add(equipment);
                                        } else {
                                          _selectedEquipment!.remove(equipment);
                                          if (_selectedEquipment!.isEmpty) {
                                            _selectedEquipment = null;
                                          }
                                        }
                                      });
                                    },
                                    backgroundColor: Colors.white,
                                    selectedColor: AppColors.salmon.withOpacity(
                                      0.2,
                                    ),
                                    labelStyle: TextStyle(
                                      color:
                                          isSelected
                                              ? AppColors.salmon
                                              : Colors.black,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  );
                                }).toList(),
                          ),

                          const SizedBox(height: 24),

                          // Apply button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // Apply filters by updating state and closing sheet
                                setState(() {
                                  _selectedDifficulty = _selectedDifficulty;
                                  _selectedEquipment = _selectedEquipment;
                                  _durationRange = _durationRange;
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text('Apply Filters'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
    );
  }

  String _getDifficultyText(WorkoutDifficulty difficulty) {
    switch (difficulty) {
      case WorkoutDifficulty.beginner:
        return 'Beginner';
      case WorkoutDifficulty.intermediate:
        return 'Intermediate';
      case WorkoutDifficulty.advanced:
        return 'Advanced';
    }
  }

  void _navigateToWorkoutDetail(Workout workout) {
    // Log analytics event
    _analytics.logEvent(
      name: 'workout_viewed',
      parameters: {
        'workout_id': workout.id,
        'workout_name': workout.title,
        'source': 'search',
      },
    );

    // TODO: Navigate to workout detail screen
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => WorkoutDetailScreen(workoutId: workout.id),
    //   ),
    // );
  }
}
