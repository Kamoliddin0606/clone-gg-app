import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../schema_form_state.dart';
import '_label.dart';

/// `type: string` + `format: text|email|phone|null`.
///
/// Reads the schema's `maxLength` to size the input and uses `format` to
/// pick a keyboard type. Multi-line is enabled when `config.multiline ==
/// true` lives alongside the schema (the renderer flattens it in).
class StringField extends StatefulWidget {
  const StringField({
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
  State<StringField> createState() => _StringFieldState();
}

class _StringFieldState extends State<StringField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initial = widget.formState.read(widget.path);
    _controller = TextEditingController(
      text: initial is String ? initial : '',
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
    widget.formState.write(
      widget.path,
      _controller.text.isEmpty ? null : _controller.text,
    );
  }

  TextInputType _keyboardFor(String? format) {
    switch (format) {
      case 'email':
        return TextInputType.emailAddress;
      case 'phone':
        return TextInputType.phone;
      default:
        return TextInputType.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final format = widget.schema['format'] as String?;
    final maxLength = widget.schema['maxLength'] as int?;
    final multiline = widget.schema['multiline'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: _controller,
        keyboardType: multiline ? TextInputType.multiline : _keyboardFor(format),
        maxLines: multiline ? null : 1,
        minLines: multiline ? 2 : 1,
        maxLength: maxLength,
        inputFormatters: maxLength == null
            ? null
            : [LengthLimitingTextInputFormatter(maxLength)],
        decoration: InputDecoration(
          labelText: fieldLabel(widget.label, widget.required),
          border: const OutlineInputBorder(),
          isDense: true,
          helperText: widget.schema['description'] as String?,
        ),
      ),
    );
  }
}
