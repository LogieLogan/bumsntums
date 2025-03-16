// lib/features/auth/widgets/onboarding/steps/workout_environment_step.dart
import 'package:flutter/material.dart';
import '../../../../../shared/theme/color_palette.dart';
import '../../../../../shared/theme/text_styles.dart';
import '../../../models/user_profile.dart';

class WorkoutEnvironmentStepController {
  List<WorkoutLocation> selectedLocations = [];
  List<String> selectedEquipment = [];
  int? weeklyWorkoutDays;
  int? workoutDurationMinutes;
  String? customLocation;
  
  bool get isValid {
    return selectedLocations.isNotEmpty && 
           selectedEquipment.isNotEmpty && 
           weeklyWorkoutDays != null && 
           workoutDurationMinutes != null;
  }
  
  WorkoutLocation? get primaryLocation {
    if (selectedLocations.isEmpty) return null;
    return selectedLocations.first;
  }
  
  String? get validationMessage {
    if (selectedLocations.isEmpty) {
      return "Please select where you'll be working out";
    }
    if (selectedEquipment.isEmpty) {
      return "Please select at least one equipment option";
    }
    if (weeklyWorkoutDays == null) {
      return "Please select how many days you'll work out";
    }
    if (workoutDurationMinutes == null) {
      return "Please select your workout duration";
    }
    return null;
  }
}

class WorkoutEnvironmentStep extends StatefulWidget {
  final WorkoutLocation? initialLocation;
  final List<String> initialEquipment;
  final int? initialWeeklyDays;
  final int? initialDuration;
  final Function(WorkoutLocation?, List<String>, int?, int?) onNext;
  final WorkoutEnvironmentStepController controller;

  const WorkoutEnvironmentStep({
    super.key,
    this.initialLocation,
    this.initialEquipment = const [],
    this.initialWeeklyDays,
    this.initialDuration,
    required this.onNext,
    required this.controller,
  });

  @override
  State<WorkoutEnvironmentStep> createState() => _WorkoutEnvironmentStepState();
}

class _WorkoutEnvironmentStepState extends State<WorkoutEnvironmentStep> {
  final _customEquipmentController = TextEditingController();
  final _customLocationController = TextEditingController();
  bool _isAddingCustomEquipment = false;
  bool _isAddingCustomLocation = false;
  
  final List<WorkoutLocation> _availableLocations = [
    WorkoutLocation.home,
    WorkoutLocation.gym,
    WorkoutLocation.outdoors,
  ];
  
  final List<String> _commonEquipment = [
    'No Equipment',
    'Dumbbells',
    'Resistance Bands',
    'Yoga Mat',
    'Exercise Ball',
    'Kettlebell',
    'Bench',
    'Full Gym Access',
  ];
  
  final List<String> _moreEquipment = [
    'Barbell & Plates',
    'Pull-Up Bar',
    'Jump Rope',
    'Foam Roller',
    'Medicine Ball',
    'TRX / Suspension Trainer',
    'Treadmill',
    'Stationary Bike',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      widget.controller.selectedLocations = [widget.initialLocation!];
    }
    widget.controller.selectedEquipment = List.from(widget.initialEquipment);
    widget.controller.weeklyWorkoutDays = widget.initialWeeklyDays;
    widget.controller.workoutDurationMinutes = widget.initialDuration;
  }

  @override
  void dispose() {
    _customEquipmentController.dispose();
    _customLocationController.dispose();
    super.dispose();
  }

  void _toggleLocation(WorkoutLocation location) {
    setState(() {
      if (widget.controller.selectedLocations.contains(location)) {
        widget.controller.selectedLocations.remove(location);
      } else {
        widget.controller.selectedLocations.add(location);
      }
    });
  }

  void _addCustomLocation() {
    final location = _customLocationController.text.trim();
    if (location.isNotEmpty) {
      setState(() {
        widget.controller.customLocation = location;
        _customLocationController.clear();
        _isAddingCustomLocation = false;
      });
    }
  }

  void _removeCustomLocation() {
    setState(() {
      widget.controller.customLocation = null;
    });
  }

  void _toggleEquipment(String equipment) {
    setState(() {
      final equipList = widget.controller.selectedEquipment;
      if (equipList.contains(equipment)) {
        equipList.remove(equipment);
      } else {
        if (equipment == 'No Equipment') {
          widget.controller.selectedEquipment = ['No Equipment'];
        } else {
          equipList.remove('No Equipment');
          equipList.add(equipment);
        }
      }
    });
  }

  void _addCustomEquipment() {
    final equipment = _customEquipmentController.text.trim();
    if (equipment.isNotEmpty) {
      setState(() {
        widget.controller.selectedEquipment.remove('No Equipment');
        widget.controller.selectedEquipment.add(equipment);
        _customEquipmentController.clear();
        _isAddingCustomEquipment = false;
      });
    }
  }

  void _removeCustomEquipment(String equipment) {
    setState(() {
      widget.controller.selectedEquipment.remove(equipment);
    });
  }

  String _getLocationTitle(WorkoutLocation location) {
    switch (location) {
      case WorkoutLocation.home: return 'Home';
      case WorkoutLocation.gym: return 'Gym';
      case WorkoutLocation.outdoors: return 'Outdoors';
      case WorkoutLocation.anywhere: return 'Anywhere';
    }
  }

  IconData _getLocationIcon(WorkoutLocation location) {
    switch (location) {
      case WorkoutLocation.home: return Icons.home;
      case WorkoutLocation.gym: return Icons.fitness_center;
      case WorkoutLocation.outdoors: return Icons.park;
      case WorkoutLocation.anywhere: return Icons.place;
    }
  }

  bool _isCustomEquipment(String equipment) {
    return !_commonEquipment.contains(equipment) && !_moreEquipment.contains(equipment);
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get screen size for adaptable layout
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth - 32; // Accounting for padding
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Your Workout Environment', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text(
            'Tell us about where you\'ll be working out',
            style: AppTextStyles.small,
          ),
          const SizedBox(height: 8),

          // Location selection
          Text('Where will you workout? (select all that apply)', 
              style: AppTextStyles.body),
          const SizedBox(height: 8),
          
          // Wrap for locations (more flexible than GridView)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableLocations.map((location) {
              final isSelected = widget.controller.selectedLocations.contains(location);
              return SizedBox(
                width: (contentWidth - 8) / 2, // 2 columns with spacing
                child: Card(
                  elevation: isSelected ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppColors.pink : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  color: isSelected ? AppColors.pink.withOpacity(0.1) : null,
                  margin: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () => _toggleLocation(location),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getLocationIcon(location),
                            color: isSelected ? AppColors.pink : AppColors.mediumGrey,
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getLocationTitle(location),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.small.copyWith(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.pink : AppColors.darkGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          // Custom location
          const SizedBox(height: 8),
          if (widget.controller.customLocation != null)
            Container(
              width: contentWidth,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.pink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.pink, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.pink,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.controller.customLocation!,
                        style: AppTextStyles.small.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.pink,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.pink, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _removeCustomLocation,
                    ),
                  ],
                ),
              ),
            ),
          
          // Add custom location
          if (!_isAddingCustomLocation && widget.controller.customLocation == null)
            TextButton.icon(
              icon: const Icon(Icons.add_location_alt, size: 18),
              label: const Text('Add custom location'),
              onPressed: () {
                setState(() {
                  _isAddingCustomLocation = true;
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          
          // Custom location input
          if (_isAddingCustomLocation)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customLocationController,
                      decoration: const InputDecoration(
                        hintText: 'Enter location',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: AppColors.pink, size: 20),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    onPressed: _addCustomLocation,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _customLocationController.clear();
                        _isAddingCustomLocation = false;
                      });
                    },
                  ),
                ],
              ),
            ),

          const Divider(height: 16),

          // Equipment selection
          Text('What equipment do you have access to?', style: AppTextStyles.body),
          const SizedBox(height: 8),
          
          // Equipment chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._commonEquipment.map((equipment) {
                final isSelected = widget.controller.selectedEquipment.contains(equipment);
                return FilterChip(
                  label: Text(equipment),
                  selected: isSelected,
                  onSelected: (_) => _toggleEquipment(equipment),
                  backgroundColor: AppColors.offWhite,
                  selectedColor: AppColors.popTurquoise.withOpacity(0.2),
                  checkmarkColor: AppColors.popTurquoise,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.popTurquoise : AppColors.darkGrey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.popTurquoise : Colors.transparent,
                  ),
                  visualDensity: VisualDensity.compact,
                );
              }),
              
              // More equipment button
              ActionChip(
                label: const Text("More..."),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("More Equipment Options"),
                      content: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _moreEquipment.map((equipment) {
                          final isSelected = widget.controller.selectedEquipment.contains(equipment);
                          return FilterChip(
                            label: Text(equipment),
                            selected: isSelected,
                            onSelected: (_) {
                              _toggleEquipment(equipment);
                              setState(() {});
                            },
                            backgroundColor: AppColors.offWhite,
                            selectedColor: AppColors.popTurquoise.withOpacity(0.2),
                            checkmarkColor: AppColors.popTurquoise,
                          );
                        }).toList(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Close"),
                        ),
                      ],
                    ),
                  );
                },
                backgroundColor: AppColors.offWhite,
                visualDensity: VisualDensity.compact,
              ),
              
              // Custom equipment
              ...widget.controller.selectedEquipment.where(_isCustomEquipment).map((equipment) {
                return Chip(
                  label: Text(equipment),
                  backgroundColor: AppColors.popTurquoise.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: AppColors.popTurquoise,
                    fontWeight: FontWeight.bold,
                  ),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _removeCustomEquipment(equipment),
                  deleteIconColor: AppColors.popTurquoise,
                  visualDensity: VisualDensity.compact,
                );
              }),
            ],
          ),

          // Custom equipment input
          if (_isAddingCustomEquipment)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customEquipmentController,
                      decoration: const InputDecoration(
                        hintText: 'Enter equipment',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: AppColors.popTurquoise, size: 20),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    onPressed: _addCustomEquipment,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _customEquipmentController.clear();
                        _isAddingCustomEquipment = false;
                      });
                    },
                  ),
                ],
              ),
            )
          else
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add custom equipment'),
              onPressed: () {
                setState(() {
                  _isAddingCustomEquipment = true;
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),

          const Divider(height: 16),

          // Days per week
          Text('How many days per week will you work out?', style: AppTextStyles.body),
          const SizedBox(height: 8),
          
          // Days selector using Wrap
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (index) {
              final days = index + 1;
              final isSelected = widget.controller.weeklyWorkoutDays == days;
              
              // Calculate size based on available width
              final size = (contentWidth - (6 * 8)) / 7; // 7 items with 6 spaces between
              
              return InkWell(
                onTap: () {
                  setState(() {
                    widget.controller.weeklyWorkoutDays = days;
                  });
                },
                borderRadius: BorderRadius.circular(size / 2),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.popYellow.withOpacity(0.3) : AppColors.offWhite,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.popYellow : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$days',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          // Workout duration
          Text('Typical workout duration', style: AppTextStyles.body),
          const SizedBox(height: 8),
          
          // Duration selector
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDurationChip(15),
              _buildDurationChip(20),
              _buildDurationChip(30),
              _buildDurationChip(45),
              _buildDurationChip(60),
              _buildDurationChip(60, label: '60+'),
            ],
          ),

          const SizedBox(height: 16), // Bottom padding
        ],
      ),
    );
  }
  
  Widget _buildDurationChip(int minutes, {String? label}) {
    final displayText = label ?? "$minutes min";
    final isSelected = widget.controller.workoutDurationMinutes == minutes;
    
    return ChoiceChip(
      label: Text(
        displayText,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          widget.controller.workoutDurationMinutes = minutes;
        });
      },
      backgroundColor: AppColors.offWhite,
      selectedColor: AppColors.popCoral.withOpacity(0.3),
      labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}