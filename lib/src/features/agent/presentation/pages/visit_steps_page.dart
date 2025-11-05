import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations_en.dart';

/// Visit Steps Page - BLoC State Management
abstract class VisitStepsState extends Equatable {
  const VisitStepsState();

  @override
  List<Object?> get props => [];
}

class VisitStepsInitial extends VisitStepsState {}

class VisitStepsLoading extends VisitStepsState {}

class VisitStepsLoaded extends VisitStepsState {
  final TradingPointWithPermissions tradingPoint;
  final SalesReqPermissions permissions;
  final List<VisitStepProgress> stepProgress;
  final int currentStepIndex;
  final bool isStrictSequence;
  final bool canProceedToNext;

  const VisitStepsLoaded({
    required this.tradingPoint,
    required this.permissions,
    required this.stepProgress,
    required this.currentStepIndex,
    required this.isStrictSequence,
    required this.canProceedToNext,
  });

  @override
  List<Object?> get props => [
        tradingPoint,
        permissions,
        stepProgress,
        currentStepIndex,
        isStrictSequence,
        canProceedToNext,
      ];
}

class VisitStepsError extends VisitStepsState {
  final String message;

  const VisitStepsError(this.message);

  @override
  List<Object?> get props => [message];
}

class VisitStepsCompleted extends VisitStepsState {
  final TradingPointWithPermissions tradingPoint;

  const VisitStepsCompleted(this.tradingPoint);

  @override
  List<Object?> get props => [tradingPoint];
}

abstract class VisitStepsEvent extends Equatable {
  const VisitStepsEvent();

  @override
  List<Object?> get props => [];
}

class LoadVisitSteps extends VisitStepsEvent {
  final TradingPointWithPermissions tradingPoint;

  const LoadVisitSteps(this.tradingPoint);

  @override
  List<Object?> get props => [tradingPoint];
}

class CompleteStep extends VisitStepsEvent {
  final int stepIndex;
  final String notes;

  const CompleteStep(this.stepIndex, this.notes);

  @override
  List<Object?> get props => [stepIndex, notes];
}

class SkipStep extends VisitStepsEvent {
  final int stepIndex;
  final String reason;

  const SkipStep(this.stepIndex, this.reason);

  @override
  List<Object?> get props => [stepIndex, reason];
}

class FinishVisit extends VisitStepsEvent {}

/// Visit Step Progress Model
class VisitStepProgress {
  final VisitStep step;
  final VisitStepStatus status;
  final String? notes;
  final String? skipReason;
  final DateTime? completedAt;

  const VisitStepProgress({
    required this.step,
    required this.status,
    this.notes,
    this.skipReason,
    this.completedAt,
  });

  VisitStepProgress copyWith({
    VisitStepStatus? status,
    String? notes,
    String? skipReason,
    DateTime? completedAt,
  }) {
    return VisitStepProgress(
      step: step,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      skipReason: skipReason ?? this.skipReason,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

enum VisitStepStatus {
  pending,
  inProgress,
  completed,
  skipped,
}

/// Visit Steps BLoC
class VisitStepsBloc extends Bloc<VisitStepsEvent, VisitStepsState> {
  // final DataSyncService _dataSyncService;

  VisitStepsBloc({required DataSyncService dataSyncService})
      : super(VisitStepsInitial()) {
    on<LoadVisitSteps>(_onLoadVisitSteps);
    on<CompleteStep>(_onCompleteStep);
    on<SkipStep>(_onSkipStep);
    on<FinishVisit>(_onFinishVisit);
  }

  Future<void> _onLoadVisitSteps(
    LoadVisitSteps event,
    Emitter<VisitStepsState> emit,
  ) async {
    emit(VisitStepsLoading());

    try {
      final tradingPoint = event.tradingPoint;

      // Fetch visit steps from database instead of using tradingPoint.permissions
      // This ensures we get the latest visit steps configured for the current user
      final dataSyncService = sl<DataSyncService>();
      final userCode = await _getCurrentUserCode();

      if (userCode == null) {
        emit(VisitStepsError(AppLocalizationsEn().userCodeNotFound));
        return;
      }

      // Get sales req permissions with visit steps from database
      // This method retrieves cached permissions that include visit steps configuration
      final permissions = await dataSyncService.getCachedSalesReqPermissions(userCode);

      if (permissions == null) {
        emit(VisitStepsError(AppLocalizationsEn().permissionsDataNotAvailable));
        return;
      }

      // Check if visit steps are available in the permissions
      if (permissions.visitSteps.isEmpty) {
        emit(VisitStepsError(AppLocalizationsEn().visitSteps));
        return;
      }

      debugPrint('Successfully loaded ${permissions.visitSteps.length} visit steps for user $userCode');

      // Initialize step progress using database visit steps
      final stepProgress = permissions.visitSteps.map((step) {
        return VisitStepProgress(
          step: step,
          status: VisitStepStatus.pending,
        );
      }).toList();

      // Determine current step based on strict sequence
      final isStrictSequence = permissions.strictSequence;
      final currentStepIndex = _getCurrentStepIndex(stepProgress, isStrictSequence);

      emit(VisitStepsLoaded(
        tradingPoint: tradingPoint,
        permissions: permissions,
        stepProgress: stepProgress,
        currentStepIndex: currentStepIndex,
        isStrictSequence: isStrictSequence,
        canProceedToNext: _canProceedToNext(stepProgress, currentStepIndex, isStrictSequence),
      ));
    } catch (e, stackTrace) {
      // Log error for debugging with stack trace
      debugPrint('Error loading visit steps: $e');
      debugPrint('Stack trace: $stackTrace');
      emit(VisitStepsError(AppLocalizationsEn().errorLoadingPermissions));
    }
  }

  /// Helper method to get current user code from preferences
  /// This method retrieves the user code from shared preferences
  /// Returns null if user code is not available or an error occurs
  /// Used to fetch user-specific visit steps from database
  Future<String?> _getCurrentUserCode() async {
    try {
      // Ensure SharedPreferencesService is ready before accessing
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();
      final userCode = prefs.getUserCode();

      if (userCode == null || userCode.isEmpty) {
        debugPrint('User code not found in preferences - cannot load visit steps');
        return null;
      }

      debugPrint('Retrieved user code for visit steps: $userCode');
      return userCode;
    } catch (e, stackTrace) {
      debugPrint('Error getting user code from preferences: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<void> _onCompleteStep(
    CompleteStep event,
    Emitter<VisitStepsState> emit,
  ) async {
    if (state is! VisitStepsLoaded) return;

    final currentState = state as VisitStepsLoaded;
    final updatedProgress = List<VisitStepProgress>.from(currentState.stepProgress);

    updatedProgress[event.stepIndex] = updatedProgress[event.stepIndex].copyWith(
      status: VisitStepStatus.completed,
      notes: event.notes,
      completedAt: DateTime.now(),
    );

    final newCurrentStepIndex = _getCurrentStepIndex(updatedProgress, currentState.isStrictSequence);

    emit(VisitStepsLoaded(
      tradingPoint: currentState.tradingPoint,
      permissions: currentState.permissions,
      stepProgress: updatedProgress,
      currentStepIndex: newCurrentStepIndex,
      isStrictSequence: currentState.isStrictSequence,
      canProceedToNext: _canProceedToNext(updatedProgress, newCurrentStepIndex, currentState.isStrictSequence),
    ));
  }

  Future<void> _onSkipStep(
    SkipStep event,
    Emitter<VisitStepsState> emit,
  ) async {
    if (state is! VisitStepsLoaded) return;

    final currentState = state as VisitStepsLoaded;
    final step = currentState.stepProgress[event.stepIndex].step;

    // Only allow skipping if step is not required
    if (step.stepRequired) {
      emit(VisitStepsError(AppLocalizationsEn().stepCannotBeSkipped));
      return;
    }

    final updatedProgress = List<VisitStepProgress>.from(currentState.stepProgress);

    updatedProgress[event.stepIndex] = updatedProgress[event.stepIndex].copyWith(
      status: VisitStepStatus.skipped,
      skipReason: event.reason,
      completedAt: DateTime.now(),
    );

    final newCurrentStepIndex = _getCurrentStepIndex(updatedProgress, currentState.isStrictSequence);

    emit(VisitStepsLoaded(
      tradingPoint: currentState.tradingPoint,
      permissions: currentState.permissions,
      stepProgress: updatedProgress,
      currentStepIndex: newCurrentStepIndex,
      isStrictSequence: currentState.isStrictSequence,
      canProceedToNext: _canProceedToNext(updatedProgress, newCurrentStepIndex, currentState.isStrictSequence),
    ));
  }

  Future<void> _onFinishVisit(
    FinishVisit event,
    Emitter<VisitStepsState> emit,
  ) async {
    if (state is! VisitStepsLoaded) return;

    final currentState = state as VisitStepsLoaded;

    // Check if all required steps are completed
    final hasIncompleteRequiredSteps = currentState.stepProgress.any((progress) =>
        progress.step.stepRequired && progress.status != VisitStepStatus.completed);

    if (hasIncompleteRequiredSteps) {
      emit(VisitStepsError(AppLocalizationsEn().allRequiredStepsMustBeCompleted));
      return;
    }

    // TODO: Save visit data to database/server
    // await _saveVisitData(currentState);

    emit(VisitStepsCompleted(currentState.tradingPoint));
  }

  int _getCurrentStepIndex(List<VisitStepProgress> progress, bool isStrictSequence) {
    if (!isStrictSequence) {
      // In non-strict mode, find first pending step
      return progress.indexWhere((p) => p.status == VisitStepStatus.pending);
    } else {
      // In strict mode, find first pending step that can be accessed
      for (int i = 0; i < progress.length; i++) {
        if (progress[i].status == VisitStepStatus.pending) {
          // Check if all previous required steps are completed
          bool canAccess = true;
          for (int j = 0; j < i; j++) {
            if (progress[j].step.stepRequired && progress[j].status != VisitStepStatus.completed) {
              canAccess = false;
              break;
            }
          }
          if (canAccess) return i;
        }
      }
      return -1; // All steps completed
    }
  }

  bool _canProceedToNext(List<VisitStepProgress> progress, int currentStepIndex, bool isStrictSequence) {
    if (currentStepIndex == -1) return false; // All completed

    if (!isStrictSequence) return true; // Can always proceed in non-strict mode

    // In strict mode, check if current step is completed or can be skipped
    final currentStep = progress[currentStepIndex];
    return currentStep.status == VisitStepStatus.completed ||
           (!currentStep.step.stepRequired && currentStep.status == VisitStepStatus.pending);
  }
}

/// Visit Steps Page Widget
class VisitStepsPage extends StatelessWidget {
  final TradingPointWithPermissions tradingPoint;

  const VisitStepsPage({
    super.key,
    required this.tradingPoint,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VisitStepsBloc(
        dataSyncService: sl<DataSyncService>(),
      )..add(LoadVisitSteps(tradingPoint)),
      child: VisitStepsView(tradingPoint: tradingPoint),
    );
  }
}

class VisitStepsView extends StatefulWidget {
  final TradingPointWithPermissions tradingPoint;

  const VisitStepsView({super.key, required this.tradingPoint});

  @override
  State<VisitStepsView> createState() => _VisitStepsViewState();
}

class _VisitStepsViewState extends State<VisitStepsView> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Ensure AppLocalizations is available, fallback to default if null
    if (l10n == null) {
      return Center(child: Text(AppLocalizationsEn().error));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.visitClient),
        centerTitle: true,
        actions: [
          BlocBuilder<VisitStepsBloc, VisitStepsState>(
            builder: (context, state) {
              if (state is VisitStepsLoaded) {
                return IconButton(
                  onPressed: () {
                    _showVisitInfoDialog(context, state);
                  },
                  icon: const Icon(Icons.info_outline),
                  tooltip: l10n.visitInfo,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<VisitStepsBloc, VisitStepsState>(
        listener: (context, state) {
          if (state is VisitStepsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is VisitStepsCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.visitCompletedSuccessfully),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(true); // Return success
          }
        },
        builder: (context, state) {
          if (state is VisitStepsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is VisitStepsLoaded) {
            return _buildLoadedView(context, state, theme, l10n);
          }

          if (state is VisitStepsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      context.read<VisitStepsBloc>().add(LoadVisitSteps(widget.tradingPoint));
                    },
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          return Center(child: Text(l10n.unknownState));
        },
      ),
    );
  }

  Widget _buildLoadedView(
    BuildContext context,
    VisitStepsLoaded state,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.08),
            theme.colorScheme.primaryContainer.withOpacity(0.06),
          ],
        ),
      ),
      child: Column(
        children: [
          // Client Header
          _buildClientHeader(context, state, theme),

          // Progress Indicator
          _buildProgressIndicator(context, state, theme),

          // Steps List
          Expanded(
            child: _buildStepsList(context, state, theme, l10n),
          ),

          // Action Buttons
          _buildActionButtons(context, state, theme, l10n),
        ],
      ),
    );
  }

  Widget _buildClientHeader(BuildContext context, VisitStepsLoaded state, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              state.tradingPoint.tradingPoint.name.isNotEmpty
                  ? state.tradingPoint.tradingPoint.name.characters.first.toUpperCase()
                  : '?',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.tradingPoint.tradingPoint.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  state.tradingPoint.tradingPoint.address,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${l10n?.visitStepNumber ?? 'Visit Step'}: ${state.tradingPoint.visitStepNumber}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, VisitStepsLoaded state, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final completedSteps = state.stepProgress.where((p) => p.status == VisitStepStatus.completed).length;
    final totalSteps = state.stepProgress.length;
    final progress = totalSteps > 0 ? completedSteps / totalSteps : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.visitProgress ?? 'Visit Progress',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$completedSteps / $totalSteps',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.outlineVariant,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsList(
    BuildContext context,
    VisitStepsLoaded state,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.stepProgress.length,
      itemBuilder: (context, index) {
        final stepProgress = state.stepProgress[index];
        final isCurrentStep = index == state.currentStepIndex;
        final canInteract = _canInteractWithStep(stepProgress, index, state);

        return _VisitStepCard(
          stepProgress: stepProgress,
          isCurrentStep: isCurrentStep,
          canInteract: canInteract,
          isStrictSequence: state.isStrictSequence,
          onComplete: (notes) {
            context.read<VisitStepsBloc>().add(CompleteStep(index, notes));
          },
          onSkip: (reason) {
            context.read<VisitStepsBloc>().add(SkipStep(index, reason));
          },
        );
      },
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    VisitStepsLoaded state,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final allRequiredCompleted = !state.stepProgress.any(
      (p) => p.step.stepRequired && p.status != VisitStepStatus.completed,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close),
                label: Text(l10n.cancel ?? 'Cancel'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: allRequiredCompleted
                    ? () => context.read<VisitStepsBloc>().add(FinishVisit())
                    : null,
                icon: const Icon(Icons.check_circle),
                label: Text(l10n.finishVisit ?? 'Finish Visit'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canInteractWithStep(VisitStepProgress stepProgress, int index, VisitStepsLoaded state) {
    if (!state.isStrictSequence) return true;

    // In strict sequence, can only interact with current step
    return index == state.currentStepIndex;
  }

  void _showVisitInfoDialog(BuildContext context, VisitStepsLoaded state) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.visitInfo ?? 'Visit Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n?.client ?? 'Client'}: ${state.tradingPoint.tradingPoint.name}'),
            const SizedBox(height: 8),
            Text('${l10n?.strictSequence ?? 'Strict Sequence'}: ${state.isStrictSequence ? (l10n?.yes ?? 'Yes') : (l10n?.no ?? 'No')}'),
            const SizedBox(height: 8),
            Text('${l10n?.visitStepNumber ?? 'Visit Step'}: ${state.tradingPoint.visitStepNumber}'),
            const SizedBox(height: 8),
            Text('${l10n?.totalSteps ?? 'Total Steps'}: ${state.stepProgress.length}'),
            const SizedBox(height: 8),
            Text('${l10n?.requiredSteps ?? 'Required Steps'}: ${state.stepProgress.where((p) => p.step.stepRequired).length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n?.close ?? 'Close'),
          ),
        ],
      ),
    );
  }
}

/// Individual Visit Step Card
class _VisitStepCard extends StatefulWidget {
  final VisitStepProgress stepProgress;
  final bool isCurrentStep;
  final bool canInteract;
  final bool isStrictSequence;
  final Function(String) onComplete;
  final Function(String) onSkip;

  const _VisitStepCard({
    required this.stepProgress,
    required this.isCurrentStep,
    required this.canInteract,
    required this.isStrictSequence,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<_VisitStepCard> createState() => _VisitStepCardState();
}

class _VisitStepCardState extends State<_VisitStepCard> {
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
    final l10n = AppLocalizations.of(context);
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

    return Card(
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
            // Step Header
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
                              step.stepRequired ? (l10n?.mandatory ?? 'Mandatory') : (l10n?.optional ?? 'Optional'),
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
                                l10n?.current ?? 'Current',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
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
                      l10n?.completed ?? 'Completed',
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
                  '${l10n?.notes ?? 'Notes'}: ${widget.stepProgress.notes}',
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
                      l10n?.skipped ?? 'Skipped',
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
                  '${l10n?.reason ?? 'Reason'}: ${widget.stepProgress.skipReason}',
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
                        label: Text(l10n?.skipStep ?? 'Skip Step'),
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
                      label: Text(l10n?.completeStep ?? 'Complete Step'),
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
                      l10n?.previousStepsRequired ?? 'Previous steps must be completed',
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
    );
  }

  void _showCompleteDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.stepProgress.step.stepName} ${l10n?.completed?.toLowerCase() ?? 'completed'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n?.confirmCompletion ?? 'Confirm completion'),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: l10n?.enterNotesOptional ?? 'Enter notes (optional)',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n?.cancelCompletion ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget.onComplete(_notesController.text.trim());
              _notesController.clear();
              Navigator.of(context).pop();
            },
            child: Text(l10n?.confirmCompletion ?? 'Confirm'),
          ),
        ],
      ),
    );
  }

  void _showSkipDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.stepProgress.step.stepName} ${l10n?.skipStep?.toLowerCase() ?? 'skip'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n?.enterSkipReason ?? 'Enter skip reason'),
            const SizedBox(height: 12),
            TextField(
              controller: _skipReasonController,
              decoration: InputDecoration(
                hintText: l10n?.reason ?? 'Reason',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget.onSkip(_skipReasonController.text.trim());
              _skipReasonController.clear();
              Navigator.of(context).pop();
            },
            child: Text(l10n?.confirmSkip ?? 'Confirm Skip'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}.${dateTime.month}';
  }
}