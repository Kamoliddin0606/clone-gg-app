import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/visit_step_data_service.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

/// Фото ДО (Facing correction) - Before photos page
/// Supports read-only mode for completed steps
class PhotoFacingBeforePage extends StatefulWidget {
  final TradingPointWithPermissions tradingPoint;
  final String visitId;
  final int stepCode;
  final String stepName;
  final bool readOnly;

  const PhotoFacingBeforePage({
    super.key,
    required this.tradingPoint,
    required this.visitId,
    required this.stepCode,
    required this.stepName,
    this.readOnly = false,
  });

  @override
  State<PhotoFacingBeforePage> createState() => _PhotoFacingBeforePageState();
}

class _PhotoFacingBeforePageState extends State<PhotoFacingBeforePage> {
  final VisitStepDataService _dataService = sl<VisitStepDataService>();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stepName),
        centerTitle: true,
        actions: widget.readOnly ? [
          const Icon(Icons.visibility, color: Colors.grey),
          const SizedBox(width: 8),
          const Text(
            'Faqat ko\'rish',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(width: 16),
        ] : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_camera,
                    size: 64,
                    color: widget.readOnly ? Colors.grey : theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Фото ДО (Facing correction)',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.readOnly
                        ? 'Bu step yakunlangan. Faqat ko\'rish rejimida.'
                        : 'Sahifa hozirda ishlab chiqilmoqda',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          if (!widget.readOnly) ...[
            Container(
              padding: const EdgeInsets.all(12 ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                  // bottomLeft: Radius.circular(20),
                  // bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: FilledButton.icon(
                  onPressed: () => _showCompleteDialog(context),
                  icon: const Icon(Icons.check),
                  label: Text(l10n?.completeStep ?? 'Complete Step'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCompleteDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.stepName} ${l10n?.completed?.toLowerCase() ?? 'completed'}'),

        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n?.cancelCompletion ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop({'completed': true, 'notes': _notesController.text.trim()}); // Return result
            },
            child: Text(l10n?.confirmCompletion ?? 'Confirm'),
          ),
        ],
      ),
    );
  }
}