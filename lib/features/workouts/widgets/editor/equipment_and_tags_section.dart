// lib/features/workouts/widgets/editor/equipment_and_tags_section.dart
import 'package:flutter/material.dart';

class EquipmentAndTagsSection extends StatelessWidget {
  final List<String> equipment;
  final List<String> tags;
  final Function(String) onAddEquipment;
  final Function(String) onRemoveEquipment;
  final Function(String) onAddTag;
  final Function(String) onRemoveTag;

  const EquipmentAndTagsSection({
    Key? key,
    required this.equipment,
    required this.tags,
    required this.onAddEquipment,
    required this.onRemoveEquipment,
    required this.onAddTag,
    required this.onRemoveTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Equipment section
        const Text(
          'Equipment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ...equipment.map(
              (item) => Chip(
                label: Text(item),
                onDeleted: () => onRemoveEquipment(item),
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              onPressed: () => _showAddItemDialog(
                context, 
                'Add Equipment', 
                'e.g., dumbbells, mat, resistance band',
                onAddEquipment,
              ),
            ),
          ],
        ),

        // Tags section
        const SizedBox(height: 24),
        const Text(
          'Tags',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ...tags.map(
              (tag) => Chip(
                label: Text(tag),
                onDeleted: () => onRemoveTag(tag),
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              onPressed: () => _showAddItemDialog(
                context, 
                'Add Tag', 
                'e.g., beginner, strength, cardio',
                onAddTag,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddItemDialog(
    BuildContext context, 
    String title, 
    String hint,
    Function(String) onAdd,
  ) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onAdd(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}