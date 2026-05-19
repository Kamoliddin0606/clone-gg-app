import 'package:flutter/material.dart';

import '../schema_form_renderer.dart';
import '../schema_form_state.dart';

/// `type: array`. Renders a vertical list of item sub-renderers plus an
/// "Add" button gated by `maxItems`. Honours `minItems` by disabling
/// per-row delete when the list would shrink below the minimum.
class ArrayField extends StatelessWidget {
  const ArrayField({
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
    final itemSchema =
        (schema['items'] as Map?)?.cast<String, dynamic>() ?? const {};
    final minItems = (schema['minItems'] as int?) ?? 0;
    final maxItems = schema['maxItems'] as int?;

    return AnimatedBuilder(
      animation: formState,
      builder: (context, _) {
        final raw = formState.read(path);
        final items = raw is List ? raw : const [];
        final canAdd = maxItems == null || items.length < maxItems;
        final canRemove = items.length > minItems;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (label != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(label!,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
              for (var i = 0; i < items.length; i++)
                _ArrayRow(
                  onRemove: canRemove
                      ? () => formState.removeFromArray(path, i)
                      : null,
                  child: SchemaFormRenderer(
                    schema: itemSchema,
                    formState: formState,
                    path: [...path, i],
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: canAdd
                    ? () => formState.appendToArray(
                          path,
                          _emptyForSchema(itemSchema),
                        )
                    : null,
                icon: const Icon(Icons.add),
                label: Text(canAdd ? 'Qator qo\'shish' : 'Limit'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// JSON-Schema-aware default value for a freshly added array slot. The
  /// goal is to satisfy the renderer's path lookups on the very next
  /// build — `null` is fine for primitives but objects need `{}` and
  /// arrays need `[]` so children can write into them.
  Object? _emptyForSchema(Map<String, dynamic> schema) {
    switch (schema['type']) {
      case 'object':
        return <String, dynamic>{};
      case 'array':
        return <dynamic>[];
      default:
        return null;
    }
  }
}

class _ArrayRow extends StatelessWidget {
  const _ArrayRow({required this.child, this.onRemove});
  final Widget child;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: child),
          IconButton(
            tooltip: 'O\'chirish',
            icon: const Icon(Icons.delete_outline),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
