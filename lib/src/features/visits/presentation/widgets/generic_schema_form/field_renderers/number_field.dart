import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../schema_form_state.dart';
import '_label.dart';

/// `type: number | integer` with optional `minimum` / `maximum`.
///
/// The formatter is the trick: integers reject decimal separators
/// up-front; floats permit one. We parse on every keystroke and write
/// `null` when the field is empty so server-side `required` validation
/// catches it.
class NumberField extends StatefulWidget {
  const NumberField({
    super.key,
    required this.schema,
    required this.formState,
    required this.path,
    required this.integer,
    this.label,
    this.required = false,
  });

  final Map<String, dynamic> schema;
  final SchemaFormState formState;
  final List<Object> path;
  final bool integer;
  final String? label;
  final bool required;

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initial = widget.formState.read(widget.path);
    _controller = TextEditingController(
      text: initial is num ? initial.toString() : '',
    );
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      widget.formState.write(widget.path, null);
      return;
    }
    final parsed = widget.integer ? int.tryParse(raw) : double.tryParse(raw);
    widget.formState.write(widget.path, parsed);
  }

  @override
  Widget build(BuildContext context) {
    final minimum = widget.schema['minimum'];
    final maximum = widget.schema['maximum'];
    final pattern = widget.integer
        ? RegExp(r'^-?\d*$')
        : RegExp(r'^-?\d*\.?\d*$');
    final helper = [
      if (minimum is num) 'min: $minimum',
      if (maximum is num) 'max: $maximum',
      if (widget.schema['description'] is String) widget.schema['description'],
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.numberWithOptions(
          decimal: !widget.integer,
          signed: (minimum is num) && minimum < 0,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(pattern),
        ],
        decoration: InputDecoration(
          labelText: fieldLabel(widget.label, widget.required),
          border: const OutlineInputBorder(),
          isDense: true,
          helperText: helper.isEmpty ? null : helper,
        ),
      ),
    );
  }
}
