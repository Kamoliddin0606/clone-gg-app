import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../schema_form_state.dart';
import '_label.dart';

/// `type: string, format: date`. Stores the wire value as `YYYY-MM-DD`
/// (RFC 3339 date) so the backend gets ISO strings without timezone
/// noise. Honours `minDate`/`maxDate` extension keys when present.
class DateField extends StatelessWidget {
  const DateField({
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
        final value = formState.read(path);
        final parsed = value is String ? DateTime.tryParse(value) : null;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: InkWell(
            onTap: () => _pick(context, parsed),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: fieldLabel(label, required),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: const Icon(Icons.calendar_today, size: 18),
              ),
              child: Text(
                parsed == null
                    ? 'Sanani tanlang'
                    : DateFormat.yMMMMd().format(parsed),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pick(BuildContext context, DateTime? current) async {
    final minDate = _parseDate(schema['minDate']) ?? DateTime(2000);
    final maxDate = _parseDate(schema['maxDate']) ?? DateTime(2100);
    final initial = current ?? DateTime.now();
    final pinned = initial.isBefore(minDate)
        ? minDate
        : (initial.isAfter(maxDate) ? maxDate : initial);

    final picked = await showDatePicker(
      context: context,
      initialDate: pinned,
      firstDate: minDate,
      lastDate: maxDate,
    );
    if (picked == null) return;
    formState.write(
      path,
      DateFormat('yyyy-MM-dd').format(picked),
    );
  }

  DateTime? _parseDate(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
