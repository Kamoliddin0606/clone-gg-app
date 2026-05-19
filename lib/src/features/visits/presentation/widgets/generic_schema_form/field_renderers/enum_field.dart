import 'package:flutter/material.dart';

import '../schema_form_state.dart';
import '_label.dart';

/// `enum: [...]` — rendered as a dropdown. Labels come from
/// `enumLabels` (parallel array, optional) so the wire value stays a
/// plain string while the user sees `name_i18n`-friendly copy.
///
/// `oneOf: [...]` could also land here but is uncommon in the catalog
/// today; if it shows up we render it the same way and only carry the
/// `const` value forward.
class EnumField extends StatelessWidget {
  const EnumField({
    super.key,
    required this.schema,
    required this.formState,
    required this.path,
    this.label,
    this.required = false,
  });

  final Map<String, dynamic> schema;
  final SchemaFormState formState;
  final List<Object> path;
  final String? label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final values = (schema['enum'] as List).cast<Object?>();
    final labels = (schema['enumLabels'] as List?)?.cast<String>() ?? const [];

    return AnimatedBuilder(
      animation: formState,
      builder: (context, _) {
        final selected = formState.read(path);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: DropdownButtonFormField<Object?>(
            initialValue: values.contains(selected) ? selected : null,
            decoration: InputDecoration(
              labelText: fieldLabel(label, required),
              border: const OutlineInputBorder(),
              isDense: true,
              helperText: schema['description'] as String?,
            ),
            items: [
              for (var i = 0; i < values.length; i++)
                DropdownMenuItem(
                  value: values[i],
                  child: Text(
                    i < labels.length ? labels[i] : '${values[i]}',
                  ),
                ),
            ],
            onChanged: (next) => formState.write(path, next),
          ),
        );
      },
    );
  }
}
