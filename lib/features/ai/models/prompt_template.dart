// lib/features/ai/models/prompt_template.dart
import 'package:equatable/equatable.dart';

enum PromptCategory {
  general,
  workoutCreation,
  planCreation,
  nutritionAdvice,
  motivationalSupport,
  formGuidance,
  workoutRefinement,
  planRefinement,
}

class PromptTemplate extends Equatable {
  final String id;
  final String name;
  final String systemPrompt;
  final String version;
  final PromptCategory category;
  final Map<String, String> variables;
  final List<String> requiredUserAttributes;
  final Map<String, dynamic> metadata;
  
  const PromptTemplate({
    required this.id,
    required this.name,
    required this.systemPrompt,
    required this.version,
    required this.category,
    this.variables = const {},
    this.requiredUserAttributes = const [],
    this.metadata = const {},
  });

  @override
  List<Object?> get props => [
    id, name, systemPrompt, version, category, variables, requiredUserAttributes, metadata
  ];

  /// Builds the prompt by replacing variables with values from userData
  String build(Map<String, dynamic> userData, {Map<String, String>? customVars}) {
    String result = systemPrompt;
    
    // Replace user profile variables
    for (final attr in requiredUserAttributes) {
      if (userData.containsKey(attr)) {
        final value = _formatValue(userData[attr]);
        result = result.replaceAll('{$attr}', value);
      } else {
        // Use a default value if the attribute is missing
        result = result.replaceAll('{$attr}', 'not specified');
      }
    }
    
    // Replace standard variables
    for (final entry in variables.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    
    // Replace custom variables if provided
    if (customVars != null) {
      for (final entry in customVars.entries) {
        result = result.replaceAll('{${entry.key}}', entry.value);
      }
    }
    
    return result;
  }
  
  String _formatValue(dynamic value) {
    if (value == null) return 'not specified';
    
    if (value is List) {
      if (value.isEmpty) return 'not specified';
      return value.join(', ');
    }
    
    return value.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'systemPrompt': systemPrompt,
      'version': version,
      'category': category.name,
      'variables': variables,
      'requiredUserAttributes': requiredUserAttributes,
      'metadata': metadata,
    };
  }

  factory PromptTemplate.fromMap(Map<String, dynamic> map) {
    return PromptTemplate(
      id: map['id'],
      name: map['name'],
      systemPrompt: map['systemPrompt'],
      version: map['version'],
      category: PromptCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => PromptCategory.general,
      ),
      variables: Map<String, String>.from(map['variables'] ?? {}),
      requiredUserAttributes: List<String>.from(map['requiredUserAttributes'] ?? []),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}