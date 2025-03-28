// lib/features/workouts/widgets/calendar/plan_creation_dialog.dart
import 'package:flutter/material.dart';
import '../../../../shared/theme/color_palette.dart';

class PlanCreationDialog extends StatefulWidget {
  final String initialName;
  final String initialDescription;

  const PlanCreationDialog({
    Key? key,
    required this.initialName,
    required this.initialDescription,
  }) : super(key: key);

  @override
  State<PlanCreationDialog> createState() => _PlanCreationDialogState();
}

class _PlanCreationDialogState extends State<PlanCreationDialog> {
  late String _planName;
  late String _planDescription;
  
  @override
  void initState() {
    super.initState();
    _planName = widget.initialName;
    _planDescription = widget.initialDescription;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Workout Plan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create a new plan based on your workout pattern:'),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _planName,
            decoration: const InputDecoration(labelText: 'Plan Name'),
            onChanged: (value) {
              _planName = value;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _planDescription,
            decoration: const InputDecoration(
              labelText: 'Description (Optional)',
            ),
            onChanged: (value) {
              _planDescription = value;
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, (_planName, _planDescription)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.pink,
            foregroundColor: Colors.white,
          ),
          child: const Text('Create Plan'),
        ),
      ],
    );
  }
}