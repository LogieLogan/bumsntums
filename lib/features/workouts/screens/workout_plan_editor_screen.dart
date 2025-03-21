// lib/features/workouts/screens/workout_plan_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/workout_plan.dart';
import '../providers/workout_planning_provider.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/components/buttons/primary_button.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/providers/analytics_provider.dart';
import 'workout_browse_screen.dart';

class WorkoutPlanEditorScreen extends ConsumerStatefulWidget {
  final String userId;
  final WorkoutPlan? existingPlan; // null for new plan

  const WorkoutPlanEditorScreen({
    Key? key,
    required this.userId,
    this.existingPlan,
  }) : super(key: key);

  @override
  ConsumerState<WorkoutPlanEditorScreen> createState() =>
      _WorkoutPlanEditorScreenState();
}

class _WorkoutPlanEditorScreenState
    extends ConsumerState<WorkoutPlanEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _goalController;

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  List<ScheduledWorkout> _scheduledWorkouts = [];
  bool _isActive = true;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();

    // Initialize with existing plan data if available
    _isEditing = widget.existingPlan != null;

    if (_isEditing) {
      final plan = widget.existingPlan!;
      _nameController = TextEditingController(text: plan.name);
      _descriptionController = TextEditingController(
        text: plan.description ?? '',
      );
      _goalController = TextEditingController(text: plan.goal);
      _startDate = plan.startDate;
      _endDate = plan.endDate;
      _scheduledWorkouts = List.from(plan.scheduledWorkouts);
      _isActive = plan.isActive;
    } else {
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _goalController = TextEditingController();
    }

    // Log screen view for analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(analyticsServiceProvider)
          .logScreenView(
            screenName:
                _isEditing ? 'edit_workout_plan' : 'create_workout_plan',
          );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planActionsState = ref.watch(workoutPlanActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Workout Plan' : 'Create Workout Plan',
          style: AppTextStyles.h2,
        ),
        centerTitle: true,
        backgroundColor: AppColors.pink,
      ),
      body: planActionsState.maybeWhen(
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        orElse: () => _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Plan name
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Plan Name',
              hintText: 'e.g., 4-Week Toning Plan',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a plan name';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (Optional)',
              hintText: 'Describe your workout plan',
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 16),

          // Goal
          TextFormField(
            controller: _goalController,
            decoration: const InputDecoration(
              labelText: 'Goal',
              hintText: 'e.g., Improve core strength',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a goal';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Date range
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start Date', style: AppTextStyles.small),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectStartDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.offWhite,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                              style: AppTextStyles.body,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('End Date (Optional)', style: AppTextStyles.small),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectEndDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.offWhite,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _endDate == null
                                  ? 'Select End Date'
                                  : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                              style: AppTextStyles.body,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Is Active toggle
          SwitchListTile(
            title: Text('Active Plan', style: AppTextStyles.body),
            subtitle: Text(
              'Set as your current active plan',
              style: AppTextStyles.small,
            ),
            value: _isActive,
            onChanged: (value) {
              setState(() {
                _isActive = value;
              });
            },
            activeColor: AppColors.pink,
          ),

          const SizedBox(height: 24),

          // Scheduled workouts section
          Text('Scheduled Workouts', style: AppTextStyles.h3),
          const SizedBox(height: 8),

          // List of scheduled workouts
          if (_scheduledWorkouts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No workouts scheduled yet',
                  style: AppTextStyles.body.copyWith(color: Colors.grey[500]),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _scheduledWorkouts.length,
              itemBuilder: (context, index) {
                final workout = _scheduledWorkouts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.popCoral,
                      child: const Icon(
                        Icons.fitness_center,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(workout.title, style: AppTextStyles.body),
                    subtitle: Text(
                      '${workout.scheduledDate.day}/${workout.scheduledDate.month}/${workout.scheduledDate.year}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _scheduledWorkouts.removeAt(index);
                        });
                      },
                    ),
                    onTap: () => _editScheduledWorkout(index),
                  ),
                );
              },
            ),

          const SizedBox(height: 16),

          // Add workout button
          OutlinedButton.icon(
            onPressed: _addScheduledWorkout,
            icon: const Icon(Icons.add),
            label: const Text('Add Workout'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              side: const BorderSide(color: AppColors.pink),
            ),
          ),

          const SizedBox(height: 32),

          // Save button
          PrimaryButton(
            text: _isEditing ? 'Update Plan' : 'Create Plan',
            onPressed: _savePlan,
          ),

          if (_isEditing) ...[
            const SizedBox(height: 16),

            // Delete button
            OutlinedButton.icon(
              onPressed: _deletePlan,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Delete Plan'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && pickedDate != _startDate) {
      setState(() {
        _startDate = pickedDate;

        // If end date is before start date, clear end date
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 28)),
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _endDate = pickedDate;
      });
    }
  }

  void _addScheduledWorkout() async {
    // First, select a date for the workout
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: _startDate,
      lastDate: _endDate ?? _startDate.add(const Duration(days: 365)),
    );

    if (selectedDate == null) return;

    // Then navigate to workout browse screen to select a workout
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WorkoutBrowseScreen()),
    );

    if (result == null) return;

    // Show time picker for reminder (optional)
    final showReminder = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Reminder?'),
            content: const Text(
              'Would you like to set a reminder for this workout?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Skip'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Set Reminder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pink,
                ),
              ),
            ],
          ),
    );

    DateTime? reminderTime;
    if (showReminder == true) {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (selectedTime != null) {
        reminderTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
      }
    }

    // Add the scheduled workout
    setState(() {
      _scheduledWorkouts.add(
        ScheduledWorkout(
          workoutId: result.id,
          title: result.title,
          workoutImageUrl: result.imageUrl,
          scheduledDate: selectedDate,
          reminderTime: reminderTime,
          reminderEnabled: reminderTime != null,
        ),
      );
    });
  }

  void _editScheduledWorkout(int index) async {
    final workout = _scheduledWorkouts[index];

    // Show date picker with current date
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: workout.scheduledDate,
      firstDate: _startDate,
      lastDate: _endDate ?? _startDate.add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      // Show time picker with current time if reminder exists
      TimeOfDay? initialTime;
      if (workout.reminderTime != null) {
        initialTime = TimeOfDay(
          hour: workout.reminderTime!.hour,
          minute: workout.reminderTime!.minute,
        );
      }

      final selectedTime = await showTimePicker(
        context: context,
        initialTime: initialTime ?? TimeOfDay.now(),
      );

      // Create reminder time if selected
      DateTime? reminderTime;
      if (selectedTime != null) {
        reminderTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
      }

      // Update the scheduled workout
      setState(() {
        _scheduledWorkouts[index] = workout.copyWith(
          scheduledDate: selectedDate,
          reminderTime: reminderTime,
          reminderEnabled: reminderTime != null,
        );
      });
    }
  }

  void _savePlan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_scheduledWorkouts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one workout to your plan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final now = DateTime.now();
      WorkoutPlan plan;

      if (_isEditing) {
        // Update existing plan
        plan = widget.existingPlan!.copyWith(
          name: _nameController.text.trim(),
          description:
              _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
          goal: _goalController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          isActive: _isActive,
          scheduledWorkouts: _scheduledWorkouts,
          updatedAt: now,
        );

        final success = await ref
            .read(workoutPlanActionsProvider.notifier)
            .updateWorkoutPlan(plan);

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Workout plan updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, plan);
          }
        }
      } else {
        // Create new plan
        final uuid = const Uuid();
        plan = WorkoutPlan(
          id: uuid.v4(),
          userId: widget.userId,
          name: _nameController.text.trim(),
          description:
              _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
          goal: _goalController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          isActive: _isActive,
          scheduledWorkouts: _scheduledWorkouts,
          createdAt: now,
          updatedAt: now,
        );

        final planId = await ref
            .read(workoutPlanActionsProvider.notifier)
            .createWorkoutPlan(plan);

        if (planId != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Workout plan created successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, plan);
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _deletePlan() {
    if (!_isEditing) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Plan'),
            content: const Text(
              'Are you sure you want to delete this workout plan? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Close dialog

                  final success = await ref
                      .read(workoutPlanActionsProvider.notifier)
                      .deleteWorkoutPlan(
                        widget.userId,
                        widget.existingPlan!.id,
                      );

                  if (success) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Workout plan deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context); // Return to previous screen
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to delete workout plan'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
