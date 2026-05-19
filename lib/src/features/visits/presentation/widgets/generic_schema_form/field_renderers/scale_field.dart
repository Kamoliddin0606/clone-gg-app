import 'package:flutter/material.dart';

import '../schema_form_state.dart';

/// `format: scale_1_5` — 5-star rating (NPS / satisfaction). Stores the
/// integer 1..5 as the wire value; tap a star twice to clear.
class ScaleField extends StatelessWidget {
  const ScaleField({
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
        final score = value is int ? value : 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null) Text(label!),
              const SizedBox(height: 4),
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      icon: Icon(
                        i <= score ? Icons.star : Icons.star_border,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      onPressed: () => formState.write(
                        path,
                        i == score ? null : i,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(score == 0 ? '—' : '$score / 5'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
