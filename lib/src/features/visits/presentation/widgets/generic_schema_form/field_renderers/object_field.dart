import 'package:flutter/material.dart';

import '../schema_form_renderer.dart';
import '../schema_form_state.dart';

/// `type: object` — grouped section with one sub-renderer per property.
///
/// At the root we just render the children directly (no card wrapper) so
/// the top-level form looks like a regular list of fields. Nested objects
/// get a card with a title for visual hierarchy.
class ObjectField extends StatelessWidget {
  const ObjectField({
    super.key,
    required this.schema,
    required this.formState,
    required this.path,
    this.label,
  });

  final Map<String, dynamic> schema;
  final SchemaFormState formState;
  final List<Object> path;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final properties =
        (schema['properties'] as Map?)?.cast<String, dynamic>() ?? const {};
    final requiredFields =
        (schema['required'] as List?)?.cast<String>() ?? const [];

    final children = [
      for (final entry in properties.entries)
        SchemaFormRenderer(
          schema: (entry.value as Map).cast<String, dynamic>(),
          formState: formState,
          path: [...path, entry.key],
          label: _propertyLabel(entry.key, entry.value as Map),
          required: requiredFields.contains(entry.key),
        ),
    ];

    if (path.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(label!,
                    style: Theme.of(context).textTheme.titleSmall),
              ),
            ...children,
          ],
        ),
      ),
    );
  }

  String _propertyLabel(String key, Map subSchema) {
    final title = subSchema['title'];
    if (title is String && title.isNotEmpty) return title;
    // Convert `customer_phone` → `Customer phone` for the default label.
    return key
        .split('_')
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
