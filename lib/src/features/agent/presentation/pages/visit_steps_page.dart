import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/visit_data_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/step_pages/photo_facing_before_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/step_pages/shelf_audit_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/step_pages/competitor_audit_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/step_pages/create_order_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/step_pages/photo_facing_after_page.dart';
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

class PreviousStep extends VisitStepsEvent {
  final int currentStepIndex;

  const PreviousStep(this.currentStepIndex);

  @override
  List<Object?> get props => [currentStepIndex];
}

class FinishVisit extends VisitStepsEvent {}

class CancelVisit extends VisitStepsEvent {}

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

/// Visit Steps BLoC - Enhanced with repository-based state management
/// Ensures data persistence and consistency across page navigations
class VisitStepsBloc extends Bloc<VisitStepsEvent, VisitStepsState> {
  final DataSyncService _dataSyncService;
  final VisitDataRepository _visitDataRepository;
  late String _visitId; // Unique identifier for this visit session

  VisitStepsBloc({
    required DataSyncService dataSyncService,
    required VisitDataRepository visitDataRepository,
  }) : _dataSyncService = dataSyncService,
        _visitDataRepository = visitDataRepository,
        super(VisitStepsInitial()) {
    on<LoadVisitSteps>(_onLoadVisitSteps);
    on<CompleteStep>(_onCompleteStep);
    on<SkipStep>(_onSkipStep);
    on<PreviousStep>(_onPreviousStep);
    on<FinishVisit>(_onFinishVisit);
    on<CancelVisit>(_onCancelVisit);
  }

  @override
  Future<void> close() {
    debugPrint('VisitStepsBloc closed for visit ID: $_visitId');
    return super.close();
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
        debugPrint('VisitStepsBloc: User code not found, cannot load visit steps');
        emit(VisitStepsError(AppLocalizationsEn().userCodeNotFound));
        return;
      }

      // Get sales req permissions with visit steps from database
      // This method retrieves cached permissions that include visit steps configuration
      final permissions = await dataSyncService.getCachedSalesReqPermissions(userCode);

      if (permissions == null) {
        debugPrint('VisitStepsBloc: Permissions data not available for user $userCode');
        emit(VisitStepsError(AppLocalizationsEn().permissionsDataNotAvailable));
        return;
      }

      // Check if visit steps are available in the permissions
      if (permissions.visitSteps.isEmpty) {
        debugPrint('VisitStepsBloc: No visit steps configured for user $userCode');
        emit(VisitStepsError(AppLocalizationsEn().visitSteps));
        return;
      }

      debugPrint('VisitStepsBloc: Successfully loaded ${permissions.visitSteps.length} visit steps for user $userCode');

      // Generate consistent visit ID for this trading point and date
      // This ensures that visits can be restored when navigating back to the page
      final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format
      _visitId = 'visit_${userCode ?? "unknown"}_${tradingPoint.tradingPoint.id}_$today';

      debugPrint('VisitStepsBloc: Using visit ID: $_visitId');

      // Load existing step progress from persistent storage with enhanced error handling
      final stepProgress = await _loadStepProgressFromStorage(permissions.visitSteps, tradingPoint.tradingPoint.name);

      // Determine current step based on strict sequence
      final isStrictSequence = permissions.strictSequence;
      final currentStepIndex = _getCurrentStepIndex(stepProgress, isStrictSequence);

      debugPrint('VisitStepsBloc: Loaded ${stepProgress.length} steps, current step index: $currentStepIndex, strict sequence: $isStrictSequence');

      emit(VisitStepsLoaded(
        tradingPoint: tradingPoint,
        permissions: permissions,
        stepProgress: stepProgress,
        currentStepIndex: currentStepIndex,
        isStrictSequence: isStrictSequence,
        canProceedToNext: _canProceedToNext(stepProgress, currentStepIndex, isStrictSequence),
      ));

      debugPrint('VisitStepsBloc: Visit steps loaded successfully for trading point ${tradingPoint.tradingPoint.name}');
    } catch (e, stackTrace) {
      // Enhanced error logging for debugging
      debugPrint('VisitStepsBloc: Error loading visit steps: $e');
      debugPrint('VisitStepsBloc: Stack trace: $stackTrace');

      // Emit error state with more descriptive message
      final errorMessage = e is Exception
          ? 'Xatolik yuz berdi: ${e.toString().replaceAll('Exception: ', '')}'
          : AppLocalizationsEn().errorLoadingPermissions;

      emit(VisitStepsError(errorMessage));
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
    final step = updatedProgress[event.stepIndex].step;

    updatedProgress[event.stepIndex] = updatedProgress[event.stepIndex].copyWith(
      status: VisitStepStatus.completed,
      notes: event.notes,
      completedAt: DateTime.now(),
    );

    // Save step completion data to persistent storage
    await _saveStepDataToStorage(
      stepCode: step.stepCode,
      stepName: step.stepName,
      dataType: 'completion',
      dataContent: {
        'notes': event.notes,
        'completedAt': DateTime.now().toIso8601String(),
        'status': 'completed',
      },
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
      status: VisitStepStatus.completed,
      notes: event.reason,
      completedAt: DateTime.now(),
    );

    // Save step completion data to persistent storage
    await _saveStepDataToStorage(
      stepCode: step.stepCode,
      stepName: step.stepName,
      dataType: 'completion',
      dataContent: {
        'notes': event.reason,
        'completedAt': DateTime.now().toIso8601String(),
        'status': 'completed',
        'skipped': true,
      },
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

  Future<void> _onPreviousStep(
    PreviousStep event,
    Emitter<VisitStepsState> emit,
  ) async {
    if (state is! VisitStepsLoaded) return;

    final currentState = state as VisitStepsLoaded;

    // Calculate previous step index
    final previousStepIndex = event.currentStepIndex - 1;

    // Ensure we don't go below 0
    if (previousStepIndex < 0) return;

    // Clear data for the current step from database
    final currentStep = currentState.stepProgress[event.currentStepIndex].step;
    await _clearStepDataFromStorage(currentStep.stepCode);

    // Update step progress: clear current step and set previous step to in-progress
    final updatedProgress = List<VisitStepProgress>.from(currentState.stepProgress);

    // Clear current step (reset to pending and clear all data)
    updatedProgress[event.currentStepIndex] = updatedProgress[event.currentStepIndex].copyWith(
      status: VisitStepStatus.pending,
      notes: null,
      skipReason: null,
      completedAt: null,
    );

    // Set previous step to in-progress status and update its data in database
    final previousStep = updatedProgress[previousStepIndex].step;
    updatedProgress[previousStepIndex] = updatedProgress[previousStepIndex].copyWith(
      status: VisitStepStatus.inProgress,
      completedAt: null, // Clear completion time since it's now in progress
    );

    // Save the in-progress status for the previous step to database
    await _saveStepDataToStorage(
      stepCode: previousStep.stepCode,
      stepName: previousStep.stepName,
      dataType: 'progress',
      dataContent: {
        'status': 'inProgress',
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );

    emit(VisitStepsLoaded(
      tradingPoint: currentState.tradingPoint,
      permissions: currentState.permissions,
      stepProgress: updatedProgress,
      currentStepIndex: previousStepIndex,
      isStrictSequence: currentState.isStrictSequence,
      canProceedToNext: _canProceedToNext(updatedProgress, previousStepIndex, currentState.isStrictSequence),
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

  Future<void> _onCancelVisit(
    CancelVisit event,
    Emitter<VisitStepsState> emit,
  ) async {
    if (state is! VisitStepsLoaded) return;

    try {
      // Clear all visit data from database
      await _clearAllVisitData();

      // Clear any cached data in memory
      // Note: BLoC state will be cleared when widget is disposed

      debugPrint('Visit cancelled and all data cleared for visit ID: $_visitId');
    } catch (e) {
      debugPrint('Error clearing visit data during cancel: $e');
      // Don't block navigation even if cleanup fails
    }

    // Navigate back without returning success (indicates cancellation)
    // The navigation will be handled by the UI layer
  }

  /// Clear all visit data from database and storage with enhanced error handling
  /// This ensures complete cleanup when visit is cancelled
  Future<void> _clearAllVisitData() async {
    try {
      debugPrint('VisitStepsBloc: Clearing all visit data for visit ID: $_visitId');

      // Delete all visit step data for this visit ID
      await _visitDataRepository.deleteVisitStepDataByVisitId(_visitId);

      // Clear any cached data in services if needed
      // Note: Individual step data is already cleared via _clearStepDataFromStorage

      debugPrint('VisitStepsBloc: All visit data cleared successfully for visit ID: $_visitId');
    } catch (e, stackTrace) {
      debugPrint('VisitStepsBloc: Error clearing all visit data: $e');
      debugPrint('VisitStepsBloc: Stack trace: $stackTrace');

      // Enhanced error handling - log but don't throw
      // We want to allow cancellation even if cleanup partially fails
      // TODO: Consider implementing partial cleanup recovery
    }
  }

  int _getCurrentStepIndex(List<VisitStepProgress> progress, bool isStrictSequence) {
    if (!isStrictSequence) {
      // In non-strict mode, find first pending or in-progress step
      return progress.indexWhere((p) => p.status == VisitStepStatus.pending || p.status == VisitStepStatus.inProgress);
    } else {
      // In strict mode, find first pending or in-progress step that can be accessed
      for (int i = 0; i < progress.length; i++) {
        if (progress[i].status == VisitStepStatus.pending || progress[i].status == VisitStepStatus.inProgress) {
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

  /// Load step progress from persistent storage with enhanced error handling
  /// This method ensures data consistency by always loading the latest data from repository
  Future<List<VisitStepProgress>> _loadStepProgressFromStorage(List<VisitStep> visitSteps, String clientCode) async {
    try {
      debugPrint('VisitStepsBloc: Loading step progress for visit ID: $_visitId, client: $clientCode');

      // Get existing visit data for this visit session
      final existingData = await _visitDataRepository.getVisitStepDataByVisitId(_visitId);

      debugPrint('VisitStepsBloc: Found ${existingData.length} existing data records for visit');

      // Create a map of step code to existing data for quick lookup
      final existingDataMap = <int, Map<String, VisitData>>{};
      for (final data in existingData) {
        if (!existingDataMap.containsKey(data.stepCode)) {
          existingDataMap[data.stepCode] = {};
        }
        existingDataMap[data.stepCode]![data.dataType] = data;
      }

      // Initialize step progress based on existing data
      final stepProgress = <VisitStepProgress>[];

      for (final step in visitSteps) {
        final existingDataForStep = existingDataMap[step.stepCode];

        if (existingDataForStep != null) {
          // Check for progress data first (takes precedence over completion)
          final progressData = existingDataForStep['progress'];
          final completionData = existingDataForStep['completion'];

          if (progressData != null) {
            // Step is in progress
            try {
              final parsedData = progressData.parsedDataContent;
              stepProgress.add(VisitStepProgress(
                step: step,
                status: VisitStepStatus.inProgress,
                notes: parsedData['notes'], // Keep any existing notes
              ));
              debugPrint('VisitStepsBloc: Step ${step.stepCode} (${step.stepName}) loaded as in-progress');
            } catch (e) {
              debugPrint('VisitStepsBloc: Error parsing progress data for step ${step.stepCode}: $e');
              // Fallback to pending if data is corrupted
              stepProgress.add(VisitStepProgress(
                step: step,
                status: VisitStepStatus.pending,
              ));
            }
          } else if (completionData != null) {
            // Step was previously completed
            try {
              final parsedData = completionData.parsedDataContent;
              final completedAt = parsedData['completedAt'] != null
                  ? DateTime.parse(parsedData['completedAt'])
                  : null;

              stepProgress.add(VisitStepProgress(
                step: step,
                status: VisitStepStatus.completed,
                notes: parsedData['notes'],
                completedAt: completedAt,
              ));
              debugPrint('VisitStepsBloc: Step ${step.stepCode} (${step.stepName}) loaded as completed');
            } catch (e) {
              debugPrint('VisitStepsBloc: Error parsing completion data for step ${step.stepCode}: $e');
              // Fallback to pending if data is corrupted
              stepProgress.add(VisitStepProgress(
                step: step,
                status: VisitStepStatus.pending,
              ));
            }
          } else {
            // Step has data but no progress/completion status
            stepProgress.add(VisitStepProgress(
              step: step,
              status: VisitStepStatus.pending,
            ));
            debugPrint('VisitStepsBloc: Step ${step.stepCode} (${step.stepName}) has data but no status, set to pending');
          }
        } else {
          // Step is pending - no data exists
          stepProgress.add(VisitStepProgress(
            step: step,
            status: VisitStepStatus.pending,
          ));
          debugPrint('VisitStepsBloc: Step ${step.stepCode} (${step.stepName}) is pending (no existing data)');
        }
      }

      debugPrint('VisitStepsBloc: Successfully loaded ${stepProgress.length} step progress records');
      return stepProgress;
    } catch (e, stackTrace) {
      debugPrint('VisitStepsBloc: Error loading step progress from storage: $e');
      debugPrint('VisitStepsBloc: Stack trace: $stackTrace');

      // Fallback to default initialization with detailed logging
      debugPrint('VisitStepsBloc: Falling back to default initialization for all steps');
      final fallbackProgress = visitSteps.map((step) {
        debugPrint('VisitStepsBloc: Step ${step.stepCode} (${step.stepName}) initialized as pending (fallback)');
        return VisitStepProgress(
          step: step,
          status: VisitStepStatus.pending,
        );
      }).toList();

      return fallbackProgress;
    }
  }

  /// Save step data to persistent storage with enhanced error handling
  /// This ensures data is properly persisted even if UI operations fail
  Future<void> _saveStepDataToStorage({
    required int stepCode,
    required String stepName,
    required String dataType,
    required Map<String, dynamic> dataContent,
  }) async {
    try {
      // Validate current state
      if (state is! VisitStepsLoaded) {
        debugPrint('VisitStepsBloc: Cannot save step data - bloc not in loaded state');
        return;
      }

      final currentState = state as VisitStepsLoaded;
      final visitData = VisitData(
        visitId: _visitId,
        clientCode: currentState.tradingPoint.tradingPoint.name,
        stepCode: stepCode,
        stepName: stepName,
        dataType: dataType,
        dataContent: jsonEncode(dataContent),
        timestamp: DateTime.now(),
      );

      debugPrint('VisitStepsBloc: Saving step data - visitId: $_visitId, stepCode: $stepCode, dataType: $dataType');

      await _visitDataRepository.saveVisitStepData(visitData);

      debugPrint('VisitStepsBloc: Step data saved successfully for step $stepCode ($stepName)');
    } catch (e, stackTrace) {
      debugPrint('VisitStepsBloc: Error saving step data to storage: $e');
      debugPrint('VisitStepsBloc: Stack trace: $stackTrace');

      // Enhanced error handling - could implement retry logic here
      // For now, we don't throw to avoid breaking the UI flow
      // TODO: Consider implementing a retry mechanism or user notification
    }
  }

  /// Clear step data from persistent storage with enhanced error handling
  /// This ensures data cleanup happens reliably
  Future<void> _clearStepDataFromStorage(int stepCode) async {
    try {
      debugPrint('VisitStepsBloc: Clearing step data for visitId: $_visitId, stepCode: $stepCode');

      await _visitDataRepository.deleteVisitStepDataByStepCode(_visitId, stepCode);

      debugPrint('VisitStepsBloc: Step data cleared successfully for step $stepCode');
    } catch (e, stackTrace) {
      debugPrint('VisitStepsBloc: Error clearing step data from storage: $e');
      debugPrint('VisitStepsBloc: Stack trace: $stackTrace');

      // Enhanced error handling - could implement cleanup retry logic here
      // For now, we don't throw to avoid breaking the UI flow
      // TODO: Consider implementing cleanup retry mechanism
    }
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
        visitDataRepository: VisitDataRepository(sl<ApiDatabaseService>()),
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
          tradingPoint: state.tradingPoint,
          visitId: (context.read<VisitStepsBloc>() as VisitStepsBloc)._visitId,
          currentStepIndex: state.currentStepIndex,
          onComplete: (notes) {
            context.read<VisitStepsBloc>().add(CompleteStep(index, notes));
          },
          onSkip: (reason) {
            context.read<VisitStepsBloc>().add(SkipStep(index, reason));
          },
          onPrevious: () {
            context.read<VisitStepsBloc>().add(PreviousStep(state.currentStepIndex));
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
                onPressed: () async {
                  // Show confirmation dialog before canceling
                  final shouldCancel = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n?.cancelVisit ?? 'Cancel Visit'),
                      content: Text(l10n?.cancelVisitConfirmation ?? 'Are you sure you want to cancel this visit? All progress will be lost.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(l10n?.no ?? 'No'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: Text(l10n?.yes ?? 'Yes'),
                        ),
                      ],
                    ),
                  );

                  if (shouldCancel == true) {
                    // Trigger cancel event to clear all data
                    context.read<VisitStepsBloc>().add(CancelVisit());
                    // Navigate back after a brief delay to allow cleanup
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (context.mounted) {
                      Navigator.of(context).pop(false); // Return false to indicate cancellation
                    }
                  }
                },
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
  final TradingPointWithPermissions tradingPoint;
  final String visitId;
  final int currentStepIndex;
  final Function(String) onComplete;
  final Function(String) onSkip;
  final Function() onPrevious;

  const _VisitStepCard({
    required this.stepProgress,
    required this.isCurrentStep,
    required this.canInteract,
    required this.isStrictSequence,
    required this.tradingPoint,
    required this.visitId,
    required this.currentStepIndex,
    required this.onComplete,
    required this.onSkip,
    required this.onPrevious,
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

    return InkWell(
      onTap: () => _navigateToStepDetail(context, step),
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
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
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
                  if (widget.currentStepIndex > 0) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onPrevious,
                        icon: const Icon(Icons.skip_previous, size: 18),
                        label: Text(l10n?.previous ?? 'Previous'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
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
                  if (!widget.isCurrentStep) ...[
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
        title: Text('${widget.stepProgress.step.stepName} ${l10n?.completed?.toLowerCase() ?? 'completed'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n?.confirmCompletion ?? 'Confirm completion'),
            const SizedBox(height: 12),
            TextField(
              controller: _skipReasonController,
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
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget.onSkip(_skipReasonController.text.trim());
              _skipReasonController.clear();
              Navigator.of(context).pop();
            },
            child: Text(l10n?.confirmCompletion ?? 'Confirm Completion'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}.${dateTime.month}';
  }

  /// Navigates to the step detail page based on step status and permissions
  /// Navigation rules:
  /// - Completed steps: allow navigation with readOnly=true (view-only mode)
  /// - Current step: allow navigation with readOnly=false (editable mode)
  /// - Pending steps (not current): block navigation with error message
  ///
  /// This ensures data integrity by preventing access to steps that haven't been
  /// reached yet in strict sequence mode, while allowing review of completed steps.
  void _navigateToStepDetail(BuildContext context, VisitStep step) async {
    final l10n = AppLocalizations.of(context);

    // Retrieve current state to determine step accessibility
    final currentState = context.read<VisitStepsBloc>().state as VisitStepsLoaded;

    // Find the progress status for the target step
    final stepProgress = currentState.stepProgress
        .firstWhere((progress) => progress.step.stepCode == step.stepCode);

    // Determine step accessibility based on completion and current position
    final isCompleted = stepProgress.status == VisitStepStatus.completed;
    final isCurrentStep = currentState.currentStepIndex ==
        currentState.stepProgress.indexOf(stepProgress);

    // Enforce navigation restrictions for non-accessible steps
    if (!isCompleted && !isCurrentStep) {
      // Display user-friendly error message for blocked navigation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.previousStepsRequired ?? 'Previous steps must be completed'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Set readOnly mode: completed steps are view-only, current step is editable
    final readOnly = isCompleted;

    Widget? page;

    // Navigate based on step name with readOnly parameter
    switch (step.stepName.toLowerCase()) {
      case 'фото до (facing correction)':
        page = PhotoFacingBeforePage(
          tradingPoint: widget.tradingPoint,
          visitId: widget.visitId,
          stepCode: step.stepCode,
          stepName: step.stepName,
          readOnly: readOnly,
        );
        break;
      case 'аудит полки (остатки)':
        page = ShelfAuditPage(
          tradingPoint: widget.tradingPoint,
          visitId: widget.visitId,
          stepCode: step.stepCode,
          stepName: step.stepName,
          readOnly: readOnly,
        );
        break;
      case 'аудит конкурентов':
        page = CompetitorAuditPage(
          tradingPoint: widget.tradingPoint,
          visitId: widget.visitId,
          stepCode: step.stepCode,
          stepName: step.stepName,
          readOnly: readOnly,
        );
        break;
      case 'создать заказ':
        page = CreateOrderPage(
          tradingPoint: widget.tradingPoint,
          visitId: widget.visitId,
          stepCode: step.stepCode,
          stepName: step.stepName,
          readOnly: readOnly,
        );
        break;
      case 'фото после (facing correction)':
        page = PhotoFacingAfterPage(
          tradingPoint: widget.tradingPoint,
          visitId: widget.visitId,
          stepCode: step.stepCode,
          stepName: step.stepName,
          readOnly: readOnly,
        );
        break;
      default:
        // For unknown step types, show a placeholder with readOnly state
        page = Scaffold(
          appBar: AppBar(
            title: Text(step.stepName),
            centerTitle: true,
            actions: readOnly ? [
              const Icon(Icons.visibility, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Faqat ko\'rish',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(width: 16),
            ] : null,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.construction,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sahifa ishlab chiqilmoqda',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  readOnly
                      ? 'Bu step yakunlangan. Faqat ko\'rish rejimida.'
                      : 'Bu step turi uchun sahifa hali yaratilmagan',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(AppLocalizations.of(context)?.back ?? 'Orqaga'),
                ),
              ],
            ),
          ),
        );
    }

    if (page != null) {
      // Navigate and wait for result
      final result = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => page!),
      );

      // Handle the result if step was completed
      if (result != null && result is Map<String, dynamic> && result['completed'] == true) {
        final notes = result['notes'] as String? ?? '';
        final stepIndex = currentState.stepProgress.indexOf(stepProgress);
        context.read<VisitStepsBloc>().add(CompleteStep(stepIndex, notes));
      }
    }
  }
}