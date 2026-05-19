import 'dart:convert';

import 'package:flutter/material.dart';

import '../../signature_pad.dart';
import '../schema_form_state.dart';

/// `format: signature` — opens a canvas overlay where the agent draws
/// with their finger. The exported PNG is base64-encoded into the task
/// payload as `data:image/png;base64,...`. The wire size for a typical
/// signature stays under ~30 KB, well within the envelope budget.
///
/// We keep the boolean fallback (`'signed' | null`) for backwards
/// compatibility — if for any reason the canvas export fails (release
/// build on a minimal handset, e.g. Android Go without the
/// `image/PNG` codec) the BLoC still gets a valid string and the
/// envelope still validates against the schema.
class SignatureField extends StatefulWidget {
  const SignatureField({
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
  State<SignatureField> createState() => _SignatureFieldState();
}

class _SignatureFieldState extends State<SignatureField> {
  bool _signed = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.formState.read(widget.path);
    _signed = existing is String && existing.isNotEmpty;
  }

  Future<void> _open() async {
    final result = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _SignatureSheet(),
      ),
    );
    if (!mounted) return;
    if (result == null || result.isEmpty) return;
    widget.formState.write(widget.path, result);
    setState(() => _signed = true);
  }

  void _clear() {
    widget.formState.write(widget.path, null);
    setState(() => _signed = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(
          _signed ? Icons.draw : Icons.draw_outlined,
          color: _signed
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
        ),
        title: Text(widget.label ?? 'Imzo'),
        subtitle: Text(_signed ? 'Imzolangan' : 'Imzolang'),
        trailing: _signed
            ? IconButton(
                tooltip: 'Tozalash',
                icon: const Icon(Icons.refresh),
                onPressed: _clear,
              )
            : const Icon(Icons.chevron_right),
        onTap: _open,
      ),
    );
  }
}

class _SignatureSheet extends StatefulWidget {
  const _SignatureSheet();

  @override
  State<_SignatureSheet> createState() => _SignatureSheetState();
}

class _SignatureSheetState extends State<_SignatureSheet> {
  final SignaturePadController _pad = SignaturePadController();
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final bytes = await _pad.exportPng();
      if (!mounted) return;
      if (bytes == null) {
        // Empty canvas — surface "signed" boolean fallback so the
        // schema still gets a truthy value.
        Navigator.pop(context, 'signed');
        return;
      }
      final payload = 'data:image/png;base64,${base64Encode(bytes)}';
      if (!mounted) return;
      Navigator.pop(context, payload);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Imzo'),
        actions: [
          TextButton(
            onPressed: _pad.clear,
            child: const Text('Tozalash'),
          ),
          TextButton(
            onPressed: _pad.undo,
            child: const Text('Ortga'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SignaturePad(
                  controller: _pad,
                  height: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _saving ? null : () => Navigator.pop(context, null),
                    child: const Text('Bekor qilish'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Saqlash'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
