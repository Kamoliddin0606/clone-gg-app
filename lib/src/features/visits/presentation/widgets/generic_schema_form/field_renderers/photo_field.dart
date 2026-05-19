import 'package:flutter/material.dart';

import '../schema_form_state.dart';

/// `format: photo` — placeholder that defers to the dedicated PHOTO_BEFORE
/// / PHOTO_AFTER task pages.
///
/// The visit pipeline already routes photo capture through the
/// `PhotoCapturePage` (registered task renderer). When a survey-style
/// task needs an embedded photo we surface the count of attached
/// `photo_asset_ids` and leave the actual capture to the dedicated task.
/// This keeps the upload state machine in one place
/// (`PhotoUploadService`) instead of branching it across every renderer.
class PhotoField extends StatelessWidget {
  const PhotoField({
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
    return AnimatedBuilder(
      animation: formState,
      builder: (context, _) {
        final raw = formState.read(path);
        final count = raw is List ? raw.length : 0;
        final theme = Theme.of(context);

        return Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: ListTile(
            leading: Icon(
              Icons.photo_camera_outlined,
              color: theme.colorScheme.primary,
            ),
            title: Text(label ?? 'Foto biriktirish'),
            subtitle: Text(
              count == 0
                  ? 'Foto biriktirilmagan${required ? ' (majburiy)' : ''}'
                  : 'Biriktirilgan suratlar: $count',
            ),
            trailing: const Icon(Icons.info_outline),
            onTap: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(
                  content: Text(
                    'Suratlarni PHOTO_BEFORE / PHOTO_AFTER vazifasidan biriktirish kerak',
                  ),
                ));
            },
          ),
        );
      },
    );
  }
}
