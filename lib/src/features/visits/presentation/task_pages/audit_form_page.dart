import 'package:flutter/material.dart';

import 'task_context.dart';

/// Shelf-audit and competitor-audit share the same UX: a free-form list of
/// `{ product_code, facings, stock_units, remarks }` rows the agent fills
/// in. The catalog's `config` decides which fields are required and what
/// label to show; the runtime payload simply collects the inputs.
///
/// The page intentionally doesn't pull a product master list — that lives
/// in the broader catalog feature. v1 of the audit task lets the user
/// enter codes manually; a future iteration plugs in the SKU picker.
class AuditFormPage extends StatefulWidget {
  const AuditFormPage({
    super.key,
    required this.ctx,
    required this.title,
    this.itemsKey = 'items',
    this.codeField = 'product_code',
  });

  final TaskContext ctx;
  final String title;
  final String itemsKey;
  final String codeField;

  @override
  State<AuditFormPage> createState() => _AuditFormPageState();
}

class _AuditFormPageState extends State<AuditFormPage> {
  late final List<_AuditRow> _rows;

  @override
  void initState() {
    super.initState();
    final draft = widget.ctx.draftPayload?[widget.itemsKey];
    _rows = (draft is List)
        ? draft
            .map((e) => _AuditRow.fromJson(
                  (e as Map).cast<String, dynamic>(),
                  codeField: widget.codeField,
                ))
            .toList()
        : [_AuditRow.empty(codeField: widget.codeField)];
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() => _rows.add(_AuditRow.empty(codeField: widget.codeField)));
  }

  void _removeRow(int i) {
    _rows[i].dispose();
    setState(() => _rows.removeAt(i));
  }

  bool get _hasAtLeastOneFilled =>
      _rows.any((r) => r.codeController.text.trim().isNotEmpty);

  void _complete() {
    final items = _rows
        .where((r) => r.codeController.text.trim().isNotEmpty)
        .map((r) => r.toJson(codeField: widget.codeField))
        .toList(growable: false);
    widget.ctx.onCompleted({widget.itemsKey: items});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.ctx.onBack,
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _rows.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          if (i == _rows.length) {
            return OutlinedButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add),
              label: const Text('Qator qo\'shish'),
            );
          }
          return _AuditRowEditor(
            row: _rows[i],
            onRemove: _rows.length == 1 ? null : () => _removeRow(i),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _hasAtLeastOneFilled ? _complete : null,
            child: const Text('Yakunlash'),
          ),
        ),
      ),
    );
  }
}

class _AuditRow {
  _AuditRow({
    required this.codeController,
    required this.facingsController,
    required this.stockController,
    required this.remarksController,
  });

  factory _AuditRow.empty({required String codeField}) => _AuditRow(
        codeController: TextEditingController(),
        facingsController: TextEditingController(),
        stockController: TextEditingController(),
        remarksController: TextEditingController(),
      );

  factory _AuditRow.fromJson(Map<String, dynamic> json,
      {required String codeField}) {
    return _AuditRow(
      codeController:
          TextEditingController(text: (json[codeField] as String?) ?? ''),
      facingsController: TextEditingController(
          text: json['facings']?.toString() ?? ''),
      stockController:
          TextEditingController(text: json['stock_units']?.toString() ?? ''),
      remarksController:
          TextEditingController(text: (json['remarks'] as String?) ?? ''),
    );
  }

  final TextEditingController codeController;
  final TextEditingController facingsController;
  final TextEditingController stockController;
  final TextEditingController remarksController;

  Map<String, dynamic> toJson({required String codeField}) {
    final facings = int.tryParse(facingsController.text.trim());
    final stock = int.tryParse(stockController.text.trim());
    return {
      codeField: codeController.text.trim(),
      if (facings != null) 'facings': facings,
      if (stock != null) 'stock_units': stock,
      if (remarksController.text.trim().isNotEmpty)
        'remarks': remarksController.text.trim(),
    };
  }

  void dispose() {
    codeController.dispose();
    facingsController.dispose();
    stockController.dispose();
    remarksController.dispose();
  }
}

class _AuditRowEditor extends StatelessWidget {
  const _AuditRowEditor({required this.row, this.onRemove});

  final _AuditRow row;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.codeController,
                    decoration: const InputDecoration(
                      labelText: 'Mahsulot kodi',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                if (onRemove != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.facingsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Facings',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: row.stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Qoldiq',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: row.remarksController,
              decoration: const InputDecoration(
                labelText: 'Izoh',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
