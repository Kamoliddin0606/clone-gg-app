import 'package:flutter/material.dart';

import '../widgets/generic_schema_form/schema_form_renderer.dart';
import '../widgets/generic_schema_form/schema_form_state.dart';
import '../widgets/generic_schema_form/schema_validator.dart';
import 'task_context.dart';

/// Fallback renderer for any `task_code` that doesn't have a dedicated
/// widget registered in [TaskRendererRegistry]. Walks the catalog's JSON
/// Schema with [SchemaFormRenderer], runs [SchemaValidator] on submit,
/// and hands the validated payload back to the BLoC.
///
/// This is the "Lego" half of the extensibility model: admin uploads a
/// new task definition + JSON Schema, mobile picks it up via the catalog
/// refresh, and the user sees a generated form on the next session — no
/// release required for surveys, NPS, freezer temperature, etc.
class GenericFormPage extends StatefulWidget {
  const GenericFormPage({super.key, required this.ctx});

  final TaskContext ctx;

  @override
  State<GenericFormPage> createState() => _GenericFormPageState();
}

class _GenericFormPageState extends State<GenericFormPage> {
  late final SchemaFormState _formState;
  Map<String, String> _errors = const {};

  @override
  void initState() {
    super.initState();
    _formState = SchemaFormState(initial: widget.ctx.draftPayload);
  }

  @override
  void dispose() {
    _formState.dispose();
    super.dispose();
  }

  void _submit() {
    final payload = _formState.toJson();
    final errors = SchemaValidator.validate(payload, widget.ctx.payloadSchema);
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(
            'Forma to\'liq emas: ${errors.values.join("; ")}',
          ),
        ));
      return;
    }
    widget.ctx.onCompleted(payload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ctx.taskCode),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.ctx.onBack,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SchemaFormRenderer(
            schema: widget.ctx.payloadSchema,
            formState: _formState,
          ),
          if (_errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tuzatish kerak:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    for (final e in _errors.entries)
                      Text('• ${e.key}: ${e.value}'),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submit,
            child: const Text('Yakunlash'),
          ),
        ],
      ),
    );
  }
}
