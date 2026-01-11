import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/visit_steps_page.dart';

import '../../data/models/trading_point_with_permissions.dart';

/// Data Persistence Status Widget
class DataPersistenceIndicator extends StatelessWidget {
  final bool isSaving;
  final bool hasUnsavedChanges;
  final bool isOnline;
  final int unsyncedCount;
  final VoidCallback? onSyncPressed;

  const DataPersistenceIndicator({
    super.key,
    required this.isSaving,
    required this.hasUnsavedChanges,
    required this.isOnline,
    required this.unsyncedCount,
    this.onSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(colorScheme),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColor(colorScheme),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusIcon(),
          const SizedBox(width: 6),
          _buildStatusText(theme),
          if (unsyncedCount > 0 && onSyncPressed != null) ...[
            const SizedBox(width: 8),
            _buildSyncButton(theme),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    if (isSaving) return colorScheme.primaryContainer.withOpacity(0.8);
    if (hasUnsavedChanges) return colorScheme.secondaryContainer.withOpacity(0.6);
    if (!isOnline) return colorScheme.errorContainer.withOpacity(0.3);
    return colorScheme.surface;
  }

  Color _getBorderColor(ColorScheme colorScheme) {
    if (isSaving) return colorScheme.primary;
    if (hasUnsavedChanges) return colorScheme.secondary;
    if (!isOnline) return colorScheme.error;
    return colorScheme.outline;
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    if (isSaving) {
      icon = Icons.sync;
      color = Colors.blue;
    } else if (hasUnsavedChanges) {
      icon = Icons.edit;
      color = Colors.orange;
    } else if (!isOnline) {
      icon = Icons.cloud_off;
      color = Colors.red;
    } else if (unsyncedCount > 0) {
      icon = Icons.cloud_queue;
      color = Colors.blue;
    } else {
      icon = Icons.cloud_done;
      color = Colors.green;
    }

    return Icon(
      icon,
      size: 16,
      color: color,
    );
  }

  Widget _buildStatusText(ThemeData theme) {
    String text;
    Color color;

    if (isSaving) {
      text = 'Saving...';
      color = theme.colorScheme.primary;
    } else if (hasUnsavedChanges) {
      text = 'Unsaved changes';
      color = theme.colorScheme.onSurfaceVariant;
    } else if (!isOnline) {
      text = 'Offline';
      color = theme.colorScheme.error;
    } else if (unsyncedCount > 0) {
      text = '$unsyncedCount pending sync';
      color = theme.colorScheme.primary;
    } else {
      text = 'All synced';
      color = theme.colorScheme.primary;
    }

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSyncButton(ThemeData theme) {
    return InkWell(
      onTap: onSyncPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'SYNC',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

/// Step Completion Animation
class StepCompletionAnimation extends StatefulWidget {
  final bool isCompleted;
  final Widget child;

  const StepCompletionAnimation({
    super.key,
    required this.isCompleted,
    required this.child,
  });

  @override
  State<StepCompletionAnimation> createState() => _StepCompletionAnimationState();
}

class _StepCompletionAnimationState extends State<StepCompletionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(StepCompletionAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted && !oldWidget.isCompleted) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: widget.child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Auto-save indicator overlay
class AutoSaveIndicator extends StatelessWidget {
  final bool isVisible;
  final String message;

  const AutoSaveIndicator({
    super.key,
    required this.isVisible,
    this.message = 'Auto-saving...',
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 16,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surface,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.primary,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Enhanced Visit Steps View with persistence indicators
class VisitStepsViewWithPersistence extends StatefulWidget {
  final TradingPointWithPermissions tradingPoint;

  const VisitStepsViewWithPersistence({
    super.key,
    required this.tradingPoint,
  });

  @override
  State<VisitStepsViewWithPersistence> createState() => _VisitStepsViewWithPersistenceState();
}

class _VisitStepsViewWithPersistenceState extends State<VisitStepsViewWithPersistence> {
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  bool _isOnline = true;
  int _unsyncedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPersistenceStatus();
  }

  Future<void> _loadPersistenceStatus() async {
    // Load persistence status from services
    // This would integrate with the sync service
    setState(() {
      _isOnline = true; // Mock - would check connectivity
      _unsyncedCount = 0; // Mock - would get from sync service
    });
  }

  void _onStepChanged() {
    setState(() {
      _hasUnsavedChanges = true;
    });

    // Auto-save after a delay
    _autoSave();
  }

  Future<void> _autoSave() async {
    setState(() {
      _isSaving = true;
    });

    // Simulate save operation
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isSaving = false;
      _hasUnsavedChanges = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        VisitStepsView(tradingPoint: widget.tradingPoint),
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: 16,
          child: DataPersistenceIndicator(
            isSaving: _isSaving,
            hasUnsavedChanges: _hasUnsavedChanges,
            isOnline: _isOnline,
            unsyncedCount: _unsyncedCount,
            onSyncPressed: _unsyncedCount > 0 ? () => _syncData() : null,
          ),
        ),
        AutoSaveIndicator(
          isVisible: _isSaving,
          message: 'Saving step data...',
        ),
      ],
    );
  }

  Future<void> _syncData() async {
    // Implement sync logic
    setState(() {
      _isSaving = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSaving = false;
      _unsyncedCount = 0;
    });
  }
}

/// Progress indicator with persistence status
class VisitProgressWithPersistence extends StatelessWidget {
  final List<VisitStepProgress> stepProgress;
  final bool isSaving;
  final bool hasUnsavedChanges;

  const VisitProgressWithPersistence({
    super.key,
    required this.stepProgress,
    required this.isSaving,
    required this.hasUnsavedChanges,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedSteps = stepProgress.where((p) => p.status == VisitStepStatus.completed).length;
    final totalSteps = stepProgress.length;
    final progress = totalSteps > 0 ? completedSteps / totalSteps : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Visit Progress',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  if (isSaving)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  if (hasUnsavedChanges)
                    Icon(
                      Icons.edit,
                      size: 14,
                      color: theme.colorScheme.secondary,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    '$completedSteps / $totalSteps',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.outlineVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              isSaving ? theme.colorScheme.secondary : theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Step card with persistence feedback
class _VisitStepCardWithPersistence extends StatefulWidget {
  final VisitStepProgress stepProgress;
  final bool isCurrentStep;
  final bool canInteract;
  final bool isStrictSequence;
  final Function(String) onComplete;
  final Function(String) onSkip;
  final bool isSaving;

  const _VisitStepCardWithPersistence({
    required this.stepProgress,
    required this.isCurrentStep,
    required this.canInteract,
    required this.isStrictSequence,
    required this.onComplete,
    required this.onSkip,
    required this.isSaving,
  });

  @override
  State<_VisitStepCardWithPersistence> createState() => _VisitStepCardWithPersistenceState();
}

class _VisitStepCardWithPersistenceState extends State<_VisitStepCardWithPersistence> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _skipReasonController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    _skipReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final step = widget.stepProgress.step;
    final status = widget.stepProgress.status;

    Color cardColor;
    Color borderColor;
    IconData statusIcon;

    switch (status) {
      case VisitStepStatus.completed:
        cardColor = theme.colorScheme.primaryContainer.withOpacity(0.3);
        borderColor = theme.colorScheme.primary;
        statusIcon = Icons.check_circle;
        break;
      case VisitStepStatus.skipped:
        cardColor = theme.colorScheme.surfaceVariant.withOpacity(0.3);
        borderColor = theme.colorScheme.outline;
        statusIcon = Icons.skip_next;
        break;
      case VisitStepStatus.inProgress:
        cardColor = theme.colorScheme.secondaryContainer.withOpacity(0.3);
        borderColor = theme.colorScheme.secondary;
        statusIcon = Icons.play_circle;
        break;
      default:
        cardColor = theme.colorScheme.surface;
        borderColor = widget.isCurrentStep ? theme.colorScheme.primary : theme.colorScheme.outlineVariant;
        statusIcon = Icons.radio_button_unchecked;
    }

    return StepCompletionAnimation(
      isCompleted: status == VisitStepStatus.completed,
      child: Card(
        elevation: widget.isCurrentStep ? 4 : 1,
        margin: const EdgeInsets.only(bottom: 12),
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: borderColor,
            width: widget.isCurrentStep ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Header with saving indicator
              Row(
                children: [
                  Icon(
                    statusIcon,
                    color: borderColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.stepName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: step.stepRequired
                                    ? theme.colorScheme.errorContainer
                                    : theme.colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                step.stepRequired ? 'Mandatory' : 'Optional',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: step.stepRequired
                                      ? theme.colorScheme.onErrorContainer
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (widget.isCurrentStep) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Current',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                            if (widget.isSaving) ...[
                              const SizedBox(width: 8),
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Status-specific content
              if (status == VisitStepStatus.completed) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Completed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.stepProgress.completedAt != null) ...[
                        const Spacer(),
                        Text(
                          _formatDateTime(widget.stepProgress.completedAt!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.stepProgress.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Notes: ${widget.stepProgress.notes}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ] else if (status == VisitStepStatus.skipped) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.skip_next,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Skipped',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.stepProgress.skipReason?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Reason: ${widget.stepProgress.skipReason}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ] else if (widget.canInteract) ...[
                const SizedBox(height: 16),
                // Action buttons for pending/in-progress steps
                Row(
                  children: [
                    if (!step.stepRequired) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showSkipDialog(context),
                          icon: const Icon(Icons.skip_next, size: 18),
                          label: Text(AppLocalizations.of(context)?.skipStep ?? 'Skip Step'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      flex: step.stepRequired ? 1 : 1,
                      child: FilledButton.icon(
                        onPressed: () => _showCompleteDialog(context),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(AppLocalizations.of(context)?.completeStep ?? 'Complete Step'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (widget.isStrictSequence && status == VisitStepStatus.pending) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)?.previousStepsMustBeCompleted ?? 'Previous steps must be completed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCompleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.stepCompleted(widget.stepProgress.step.stepName) ?? '${widget.stepProgress.step.stepName} completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)?.confirmCompletion ?? 'Confirm completion'),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Enter notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget.onComplete(_notesController.text.trim());
              _notesController.clear();
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)?.confirm ?? 'Confirm'),
          ),
        ],
      ),
    );
  }

  void _showSkipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.stepSkip(widget.stepProgress.step.stepName) ?? '${widget.stepProgress.step.stepName} skip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)?.enterSkipReason ?? 'Enter skip reason'),
            const SizedBox(height: 12),
            TextField(
              controller: _skipReasonController,
              decoration: const InputDecoration(
                hintText: 'Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget.onSkip(_skipReasonController.text.trim());
              _skipReasonController.clear();
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)?.confirmSkip ?? 'Confirm Skip'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}.${dateTime.month}';
  }
}