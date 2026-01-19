import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/visit_step_data_service.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/visit_steps_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/visit_timer_widget.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/floating_timer_overlay.dart';

/// Аудит конкурентов - Competitor audit page
/// Supports read-only mode for completed steps
class CompetitorAuditPage extends StatefulWidget {
  final TradingPointWithPermissions tradingPoint;
  final String visitId;
  final int stepCode;
  final String stepName;
  final bool readOnly;

  const CompetitorAuditPage({
    super.key,
    required this.tradingPoint,
    required this.visitId,
    required this.stepCode,
    required this.stepName,
    this.readOnly = false,
  });

  @override
  State<CompetitorAuditPage> createState() => _CompetitorAuditPageState();
}

class _CompetitorAuditPageState extends State<CompetitorAuditPage> {
  final VisitStepDataService _dataService = sl<VisitStepDataService>();
  final TextEditingController _notesController = TextEditingController();
  bool _showTimerOverlay = false;

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
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showTimerOverlay = !_showTimerOverlay;
              });
            },
            icon: Icon(
              _showTimerOverlay ? Icons.timer_off : Icons.timer,
              color: _showTimerOverlay ? theme.colorScheme.primary : null,
            ),
            tooltip: 'Timer',
          ),
          if (widget.readOnly) ...[
            const Icon(Icons.visibility, color: Colors.grey),
            const SizedBox(width: 8),
            const Text(
              'Faqat ko\'rish',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business,
                        size: 64,
                        color: widget.readOnly ? Colors.grey : theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Аудит конкурентов',
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
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
          if (_showTimerOverlay)
            BlocBuilder<VisitStepsBloc, VisitStepsState>(
              builder: (context, state) {
                if (state is VisitStepsLoaded) {
                  final allSteps = state.stepProgress.map((stepProgress) {
                    return StepTimerInfo(
                      stepName: stepProgress.step.stepName,
                      stepCode: stepProgress.step.stepCode,
                      durationSeconds: state.stepTimers[stepProgress.step.stepCode],
                      isActive: stepProgress.step.stepCode == widget.stepCode,
                      isCompleted: stepProgress.status == VisitStepStatus.completed,
                    );
                  }).toList();

                  return FloatingTimerOverlay(
                    visitDurationSeconds: state.visitDurationSeconds,
                    allSteps: allSteps,
                    onClose: () {
                      setState(() {
                        _showTimerOverlay = false;
                      });
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
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