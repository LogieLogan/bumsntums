// lib/features/workout_planning/screens/workout_scheduling_screen.dart
import 'package:bums_n_tums/features/workouts/models/workout.dart';
import 'package:bums_n_tums/features/workouts/models/workout_category_extensions.dart';
import 'package:bums_n_tums/features/workouts/repositories/custom_workout_repository.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_editor_screen.dart';
import 'package:bums_n_tums/features/ai_workout_creation/screens/ai_workout_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_templates_screen.dart';
import 'package:bums_n_tums/features/workout_planning/models/scheduled_workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workout_planning_provider.dart';
import '../../../features/workouts/providers/workout_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/components/buttons/primary_button.dart';
import 'package:intl/intl.dart';

enum TimeOfDayOption { morning, lunch, evening }

class WorkoutSchedulingScreen extends ConsumerStatefulWidget {
  final String userId;
  final DateTime scheduledDate;
  final bool isLoggingMode;

  const WorkoutSchedulingScreen({
    super.key,
    required this.userId,
    required this.scheduledDate,
    this.isLoggingMode = false,
  });

  @override
  ConsumerState<WorkoutSchedulingScreen> createState() =>
      _WorkoutSchedulingScreenState();
}

class _WorkoutSchedulingScreenState
    extends ConsumerState<WorkoutSchedulingScreen>
    with TickerProviderStateMixin {
  TimeOfDayOption? _selectedTimeOption;
  String? _selectedWorkoutId;
  String _searchQuery = '';
  WorkoutCategory? _filterCategory;
  bool _isSaving = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Add listener if needed, e.g., to clear selection when tab changes
    // _tabController.addListener(() {
    //   if (_tabController.indexIsChanging) {
    //     setState(() {
    //       _selectedWorkoutId = null; // Clear selection on tab change
    //     });
    //   }
    // });
  }

  @override
  void dispose() {
    // Dispose TabController
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers needed for the lists within the tabs
    final workoutsAsync = ref.watch(allWorkoutsProvider);
    final myWorkoutsAsync = ref.watch(
      customWorkoutsStreamProvider(widget.userId),
    );
    final dateFormatter = DateFormat('EEEE, MMMM d');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isLoggingMode ? 'Log Workout' : 'Schedule Workout'),
        // The TabBar is now placed within the body Column
      ),
      body: Stack(
        // Stack for loading overlay
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
            ).copyWith(top: 16.0), // Main padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date display
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Date: ${dateFormatter.format(widget.scheduledDate)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Create Workout',
                      onPressed: () {
                        _showWorkoutCreationOptions(context);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Time selection
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

                // Search and Filter Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText:
                              'Search workouts in selected tab', // Updated hint
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
                      tooltip: 'Filter categories', // Add tooltip
                      onPressed: () {
                        _showFilterOptions(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // TabBar for switching lists
                TabBar(
                  controller: _tabController,
                  labelColor:
                      Theme.of(context).tabBarTheme.labelColor ??
                      AppColors.darkGrey,
                  unselectedLabelColor:
                      Theme.of(context).tabBarTheme.unselectedLabelColor ??
                      AppColors.mediumGrey,
                  indicatorColor:
                      Theme.of(context).tabBarTheme.indicatorColor ??
                      AppColors.salmon,
                  indicatorWeight: 3.0,
                  tabs: const [
                    Tab(text: 'All Workouts'),
                    Tab(text: 'My Workouts'),
                  ],
                ),
                const SizedBox(height: 8), // Space below TabBar
                // TabBarView containing the workout lists
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // View for "All Workouts" tab - passes the correct provider
                      _buildWorkoutsList(workoutsAsync),
                      // View for "My Workouts" tab - passes the correct provider
                      _buildMyWorkoutsList(myWorkoutsAsync),
                    ],
                  ),
                ),

                // Submit Button (Schedule/Log)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                  child: PrimaryButton(
                    text:
                        widget.isLoggingMode
                            ? 'Log Workout'
                            : 'Schedule Workout',
                    onPressed:
                        (_selectedWorkoutId == null ||
                                _selectedTimeOption == null ||
                                _isSaving)
                            ? null
                            : () => _saveAndMaybeComplete(context),
                    isEnabled:
                        _selectedWorkoutId != null &&
                        _selectedTimeOption != null &&
                        !_isSaving,
                    isLoading: _isSaving,
                    width: double.infinity, // Make button full width
                  ),
                ),
              ],
            ),
          ),
          // Loading Overlay (remains the same)
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(
                child: LoadingIndicator(message: 'Saving...'),
              ),
            ),
        ],
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
              ? category.displayColor.withOpacity(0.2)
              : AppColors.lightGrey,
      checkmarkColor:
          category != null ? category.displayColor : AppColors.darkGrey,
      labelStyle: TextStyle(
        color:
            isSelected
                ? (category != null
                    ? category.displayColor
                    : AppColors.darkGrey)
                : AppColors.darkGrey,
      ),
    );
  }

  Widget _buildWorkoutsList(AsyncValue<List<Workout>> workoutsAsync) {
    return workoutsAsync.when(
      data: (workouts) {
        var filteredWorkouts =
            workouts.where((workout) {
              final matchesSearch =
                  _searchQuery.isEmpty ||
                  workout.title.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  workout.description.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );
              final matchesCategory =
                  _filterCategory == null ||
                  workout.category == _filterCategory;
              return matchesSearch && matchesCategory;
            }).toList();

        if (filteredWorkouts.isEmpty) {
          return Center(child: Column(/* No results UI */));
        }
        return ListView.builder(
          itemCount: filteredWorkouts.length,
          itemBuilder:
              (context, index) => _buildWorkoutCard(filteredWorkouts[index]),
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
        var filteredWorkouts =
            workouts.where((workout) {
              final matchesSearch =
                  _searchQuery.isEmpty ||
                  workout.title.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  workout.description.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );
              final matchesCategory =
                  _filterCategory == null ||
                  workout.category == _filterCategory;
              return matchesSearch && matchesCategory;
            }).toList();
        if (filteredWorkouts.isEmpty) {
          return Center(child: Column(/* No custom results UI */));
        }
        return ListView.builder(
          itemCount: filteredWorkouts.length,
          itemBuilder:
              (context, index) => _buildWorkoutCard(filteredWorkouts[index]),
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
                    Row(children: [/* Category and Duration Badges */]),
                    const SizedBox(height: 4),
                    Text(
                      workout.difficulty.displayName,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
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
                if (!widget.isLoggingMode)
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

  Future<void> _createFromScratch(BuildContext context) async {
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

  Future<void> _useTemplate(BuildContext context) async {
    try {
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

  Future<void> _createWithAI(BuildContext context) async {
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

  Future<void> _saveAndMaybeComplete(BuildContext context) async {
    if (_selectedWorkoutId == null || _selectedTimeOption == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final TimeOfDay preferredTime = _getTimeOfDayFromOption(
        _selectedTimeOption!,
      );
      final planningNotifier = ref.read(
        plannerItemsNotifierProvider(widget.userId).notifier,
      );

      final ScheduledWorkout scheduledWorkout = await planningNotifier
          .scheduleWorkout(
            _selectedWorkoutId!,
            widget.scheduledDate,
            preferredTime: preferredTime,
          );
      print("Workout item scheduled/logged in DB: ${scheduledWorkout.id}");

      if (widget.isLoggingMode) {
        print(
          "Logging mode: Attempting to mark item ${scheduledWorkout.id} as complete...",
        );
        await planningNotifier.markScheduledItemComplete(scheduledWorkout);
        print("Item ${scheduledWorkout.id} marked as complete via notifier.");
      }

      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              widget.isLoggingMode
                  ? 'Workout logged successfully!'
                  : 'Workout scheduled successfully!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      print("Error during save/complete process: $e\n$stackTrace");
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${widget.isLoggingMode ? 'log' : 'schedule'} workout: $e',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
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
}
