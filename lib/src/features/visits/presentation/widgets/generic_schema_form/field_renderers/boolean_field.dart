import 'package:flutter/material.dart';

import '../schema_form_state.dart';

/// `type: boolean`. Rendered as a SwitchListTile because the form is
/// usually a vertical list — Checkbox would lose visual weight.
class BooleanField extends StatelessWidget {
  const BooleanField({
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
    return AnimatedBuilder(
      animation: formState,
      builder: (context, _) {
        final value = formState.read(path);
        final on = value is bool ? value : (schema['default'] as bool? ?? false);
        return SwitchListTile(
          value: on,
          contentPadding: EdgeInsets.zero,
          title: Text(label ?? ''),
          subtitle: schema['description'] is String
              ? Text(schema['description'] as String)
              : null,
          onChanged: (next) => formState.write(path, next),
        );
      },
    );
  }
}
