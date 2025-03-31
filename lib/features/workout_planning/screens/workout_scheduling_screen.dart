// lib/features/workout_planning/screens/workout_scheduling_screen.dart
import 'package:bums_n_tums/features/workouts/models/workout.dart';
import 'package:bums_n_tums/features/workouts/repositories/custom_workout_repository.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_editor_screen.dart';
import 'package:bums_n_tums/features/ai/screens/workout_creation/ai_workout_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_templates_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workout_planning_provider.dart';
import '../../../features/workouts/providers/workout_provider.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/components/buttons/primary_button.dart';
import 'package:intl/intl.dart';

enum TimeOfDayOption { morning, lunch, evening }

class WorkoutSchedulingScreen extends ConsumerStatefulWidget {
  final String userId;
  final DateTime scheduledDate;

  const WorkoutSchedulingScreen({
    Key? key,
    required this.userId,
    required this.scheduledDate,
  }) : super(key: key);

  @override
  ConsumerState<WorkoutSchedulingScreen> createState() =>
      _WorkoutSchedulingScreenState();
}

class _WorkoutSchedulingScreenState
    extends ConsumerState<WorkoutSchedulingScreen> {
  TimeOfDayOption? _selectedTimeOption;
  String? _selectedWorkoutId;
  String _searchQuery = '';
  WorkoutCategory? _filterCategory;
  bool _showMyWorkoutsOnly = false;

  @override
  Widget build(BuildContext context) {
    final workoutsAsync = ref.watch(allWorkoutsProvider);
    final myWorkoutsAsync = ref.watch(
      customWorkoutsStreamProvider(widget.userId),
    );
    final dateFormatter = DateFormat('EEEE, MMMM d');

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Workout')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date display
            Text(
              'Date: ${dateFormatter.format(widget.scheduledDate)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 16),

            // Time options
            Text('When:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            Row(
              children: [
                _buildTimeOptionButton(
                  TimeOfDayOption.morning,
                  'Morning',
                  Icons.wb_sunny,
                ),
                const SizedBox(width: 8),
                _buildTimeOptionButton(
                  TimeOfDayOption.lunch,
                  'Lunch',
                  Icons.lunch_dining,
                ),
                const SizedBox(width: 8),
                _buildTimeOptionButton(
                  TimeOfDayOption.evening,
                  'Evening',
                  Icons.nights_stay,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Search and filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search workouts',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    _showFilterOptions(context);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select a workout:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create Workout'),
                  onPressed: () {
                    _showWorkoutCreationOptions(context);
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Workout list with filtering
            Expanded(
              child:
                  _showMyWorkoutsOnly
                      ? _buildMyWorkoutsList(myWorkoutsAsync)
                      : _buildWorkoutsList(workoutsAsync),
            ),

            // Schedule button
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
              child: PrimaryButton(
                text: 'Schedule Workout',
                onPressed:
                    (_selectedWorkoutId == null || _selectedTimeOption == null)
                        ? null
                        : () => _scheduleWorkout(context),
                isEnabled:
                    _selectedWorkoutId != null && _selectedTimeOption != null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeOptionButton(
    TimeOfDayOption option,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedTimeOption == option;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTimeOption = option;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected ? AppColors.pink : AppColors.pink.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : AppColors.pink),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Workouts',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildCategoryFilterChip(null, 'All', setModalState),
                      _buildCategoryFilterChip(
                        WorkoutCategory.bums,
                        'Bums',
                        setModalState,
                      ),
                      _buildCategoryFilterChip(
                        WorkoutCategory.tums,
                        'Tums',
                        setModalState,
                      ),
                      _buildCategoryFilterChip(
                        WorkoutCategory.fullBody,
                        'Full Body',
                        setModalState,
                      ),
                      _buildCategoryFilterChip(
                        WorkoutCategory.cardio,
                        'Cardio',
                        setModalState,
                      ),
                      _buildCategoryFilterChip(
                        WorkoutCategory.quickWorkout,
                        'Quick',
                        setModalState,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  CheckboxListTile(
                    title: const Text('Show only my workouts'),
                    value: _showMyWorkoutsOnly,
                    onChanged: (value) {
                      setModalState(() {
                        _showMyWorkoutsOnly = value ?? false;
                      });
                      setState(() {
                        _showMyWorkoutsOnly = value ?? false;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryFilterChip(
    WorkoutCategory? category,
    String label,
    StateSetter setModalState,
  ) {
    final isSelected = _filterCategory == category;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() {
          _filterCategory = selected ? category : null;
        });
        setState(() {
          _filterCategory = selected ? category : null;
        });
      },
      backgroundColor: Colors.white,
      selectedColor:
          category != null
              ? _getCategoryColor(category).withOpacity(0.2)
              : AppColors.lightGrey,
      checkmarkColor:
          category != null ? _getCategoryColor(category) : AppColors.darkGrey,
      labelStyle: TextStyle(
        color:
            isSelected
                ? (category != null
                    ? _getCategoryColor(category)
                    : AppColors.darkGrey)
                : AppColors.darkGrey,
      ),
    );
  }

  Widget _buildWorkoutsList(AsyncValue<List<Workout>> workoutsAsync) {
    return workoutsAsync.when(
      data: (workouts) {
        // Apply filtering
        var filteredWorkouts =
            workouts.where((workout) {
              // Search filter
              final matchesSearch =
                  _searchQuery.isEmpty ||
                  workout.title.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  workout.description.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );

              // Category filter
              final matchesCategory =
                  _filterCategory == null ||
                  workout.category == _filterCategory;

              return matchesSearch && matchesCategory;
            }).toList();

        if (filteredWorkouts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: AppColors.lightGrey),
                const SizedBox(height: 16),
                Text(
                  'No workouts match your filters',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _filterCategory = null;
                    });
                  },
                  child: const Text('Clear Filters'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredWorkouts.length,
          itemBuilder: (context, index) {
            final workout = filteredWorkouts[index];
            return _buildWorkoutCard(workout);
          },
        );
      },
      loading: () => const LoadingIndicator(message: 'Loading workouts...'),
      error:
          (error, stack) =>
              Center(child: Text('Error loading workouts: $error')),
    );
  }

  Widget _buildMyWorkoutsList(AsyncValue<List<Workout>> myWorkoutsAsync) {
    return myWorkoutsAsync.when(
      data: (workouts) {
        // Apply filtering
        var filteredWorkouts =
            workouts.where((workout) {
              // Search filter
              final matchesSearch =
                  _searchQuery.isEmpty ||
                  workout.title.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  workout.description.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );

              // Category filter
              final matchesCategory =
                  _filterCategory == null ||
                  workout.category == _filterCategory;

              return matchesSearch && matchesCategory;
            }).toList();

        if (filteredWorkouts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: AppColors.lightGrey),
                const SizedBox(height: 16),
                const Text(
                  'No custom workouts match your filters',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _filterCategory = null;
                    });
                  },
                  child: const Text('Clear Filters'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredWorkouts.length,
          itemBuilder: (context, index) {
            final workout = filteredWorkouts[index];
            return _buildWorkoutCard(workout);
          },
        );
      },
      loading:
          () => const LoadingIndicator(message: 'Loading your workouts...'),
      error:
          (error, stack) =>
              Center(child: Text('Error loading your workouts: $error')),
    );
  }

  Widget _buildWorkoutCard(Workout workout) {
    if (workout.imageUrl.isEmpty) {
      // Fix the imageUrl if it's empty
      workout = workout.copyWith(
        imageUrl: 'assets/images/workouts/default_workout.jpg',
      );
    }

    final isSelected = _selectedWorkoutId == workout.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isSelected
                ? BorderSide(color: AppColors.pink, width: 2)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedWorkoutId = workout.id;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Workout info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(
                              workout.category,
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getCategoryName(workout.category),
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: _getCategoryColor(workout.category),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.popBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${workout.durationMinutes} min',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.popBlue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDifficultyName(workout.difficulty),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected)
                Icon(Icons.check_circle, color: AppColors.pink)
              else
                Icon(Icons.radio_button_unchecked, color: AppColors.lightGrey),
            ],
          ),
        ),
      ),
    );
  }

  void _showWorkoutCreationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Create Workout',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.create, color: AppColors.pink),
                  title: const Text('Create from Scratch'),
                  subtitle: const Text('Start with a blank workout'),
                  onTap: () {
                    Navigator.pop(context);
                    _createFromScratch(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.copy, color: AppColors.popBlue),
                  title: const Text('Use Template'),
                  subtitle: const Text(
                    'Start with one of your saved templates',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _useTemplate(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.psychology, color: AppColors.popGreen),
                  title: const Text('Create with AI'),
                  subtitle: const Text(
                    'Let AI generate a personalized workout',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _createWithAI(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _createFromScratch(BuildContext context) async {
    final newWorkout = await Navigator.push<Workout>(
      context,
      MaterialPageRoute(builder: (context) => const WorkoutEditorScreen()),
    );

    if (newWorkout != null) {
      setState(() {
        _selectedWorkoutId = newWorkout.id;
      });
    }
  }

  void _useTemplate(BuildContext context) async {
    try {
      // Use MaterialPageRoute instead of pushNamed
      final selectedTemplate = await Navigator.of(context).push<Workout>(
        MaterialPageRoute(
          builder:
              (context) => const WorkoutTemplatesScreen(selectionMode: true),
        ),
      );

      if (selectedTemplate != null) {
        setState(() {
          _selectedWorkoutId = selectedTemplate.id;
        });
      }
    } catch (e) {
      print('Error selecting template: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load workout templates: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _createWithAI(BuildContext context) async {
    final aiWorkout = await Navigator.push<Workout>(
      context,
      MaterialPageRoute(
        builder: (context) => const AIWorkoutScreen(),
        settings: const RouteSettings(arguments: true),
      ),
    );

    if (aiWorkout != null) {
      setState(() {
        _selectedWorkoutId = aiWorkout.id;
      });
    }
  }

  void _scheduleWorkout(BuildContext context) async {
    if (_selectedWorkoutId == null || _selectedTimeOption == null) return;

    try {
      // Convert time option to a TimeOfDay
      final TimeOfDay preferredTime = _getTimeOfDayFromOption(
        _selectedTimeOption!,
      );

      // Get the planning notifier
      final planningNotifier = ref.read(
        workoutPlanningNotifierProvider(widget.userId).notifier,
      );

      // Schedule the workout
      await planningNotifier.scheduleWorkout(
        _selectedWorkoutId!,
        widget.scheduledDate,
        preferredTime: preferredTime,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Workout scheduled successfully!'),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule workout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  TimeOfDay _getTimeOfDayFromOption(TimeOfDayOption option) {
    switch (option) {
      case TimeOfDayOption.morning:
        return const TimeOfDay(hour: 8, minute: 0);
      case TimeOfDayOption.lunch:
        return const TimeOfDay(hour: 12, minute: 0);
      case TimeOfDayOption.evening:
        return const TimeOfDay(hour: 18, minute: 0);
    }
  }

  Color _getCategoryColor(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.bums:
        return AppColors.pink;
      case WorkoutCategory.tums:
        return AppColors.popCoral;
      case WorkoutCategory.fullBody:
        return AppColors.popBlue;
      case WorkoutCategory.cardio:
        return AppColors.popGreen;
      case WorkoutCategory.quickWorkout:
        return AppColors.popYellow;
    }
  }

  String _getCategoryName(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.bums:
        return 'Bums';
      case WorkoutCategory.tums:
        return 'Tums';
      case WorkoutCategory.fullBody:
        return 'Full Body';
      case WorkoutCategory.cardio:
        return 'Cardio';
      case WorkoutCategory.quickWorkout:
        return 'Quick';
    }
  }

  String _getDifficultyName(WorkoutDifficulty difficulty) {
    switch (difficulty) {
      case WorkoutDifficulty.beginner:
        return 'Beginner';
      case WorkoutDifficulty.intermediate:
        return 'Intermediate';
      case WorkoutDifficulty.advanced:
        return 'Advanced';
    }
  }
}
