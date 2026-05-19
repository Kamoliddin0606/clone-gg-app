import 'package:flutter/material.dart';

import 'field_renderers/array_field.dart';
import 'field_renderers/boolean_field.dart';
import 'field_renderers/date_field.dart';
import 'field_renderers/enum_field.dart';
import 'field_renderers/number_field.dart';
import 'field_renderers/object_field.dart';
import 'field_renderers/photo_field.dart';
import 'field_renderers/scale_field.dart';
import 'field_renderers/signature_field.dart';
import 'field_renderers/string_field.dart';
import 'schema_form_state.dart';

/// Pure-schema → widget tree. The renderer recurses through the schema
/// once per build; field widgets subscribe to [SchemaFormState] so leaf
/// mutations don't rebuild the entire form.
///
/// Dispatch table (precedence top → bottom):
///   1. `enum`         → dropdown (regardless of `type`)
///   2. `type:string`  with `format: photo|gps|signature|date|...`
///   3. `type:string`  → text field
///   4. `type:number|integer` → number field
///   5. `type:boolean` → switch
///   6. `type:array`   → dynamic list (sub-renderer per item)
///   7. `type:object`  → grouped section
///
/// Unknown shapes fall through to a `Text(schema.toString())` debug card so
/// the agent at least sees something rather than a silent blank.
class SchemaFormRenderer extends StatelessWidget {
  const SchemaFormRenderer({
    super.key,
    required this.schema,
    required this.formState,
    this.path = const [],
    this.label,
    this.required = false,
  });

  final Map<String, dynamic> schema;
  final SchemaFormState formState;

  /// JSON-pointer-like address inside [formState]. Empty list ⇒ root.
  final List<Object> path;
  final String? label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    // `enum` is independent of type — present a dropdown either way.
    if (schema['enum'] is List) {
      return EnumField(
        schema: schema,
        formState: formState,
        path: path,
        label: label,
        required: required,
      );
    }

    final type = schema['type'] as String?;
    final format = schema['format'] as String?;

    if (type == 'string') {
      switch (format) {
        case 'photo':
          return PhotoField(
            schema: schema,
            formState: formState,
            path: path,
            label: label,
            required: required,
          );
        case 'signature':
          return SignatureField(
            schema: schema,
            formState: formState,
            path: path,
            label: label,
          );
        case 'date':
          return DateField(
            schema: schema,
            formState: formState,
            path: path,
            label: label,
            required: required,
          );
        default:
          return StringField(
            schema: schema,
            formState: formState,
            path: path,
            label: label,
            required: required,
          );
      }
    }

    if (format == 'scale_1_5') {
      return ScaleField(
        schema: schema,
        formState: formState,
        path: path,
        label: label,
      );
    }

    if (type == 'number' || type == 'integer') {
      return NumberField(
        schema: schema,
        formState: formState,
        path: path,
        label: label,
        required: required,
        integer: type == 'integer',
      );
    }

    if (type == 'boolean') {
      return BooleanField(
        schema: schema,
        formState: formState,
        path: path,
        label: label,
      );
    }

    if (type == 'array') {
      return ArrayField(
        schema: schema,
        formState: formState,
        path: path,
        label: label,
      );
    }

    if (type == 'object') {
      return ObjectField(
        schema: schema,
        formState: formState,
        path: path,
        label: label,
      );
    }

    return _UnknownSchemaCard(label: label, schema: schema);
  }
}

class _UnknownSchemaCard extends StatelessWidget {
  const _UnknownSchemaCard({this.label, required this.schema});
  final String? label;
  final Map<String, dynamic> schema;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null) Text(label!),
            Text('Noma\'lum schema tipi: $schema',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
