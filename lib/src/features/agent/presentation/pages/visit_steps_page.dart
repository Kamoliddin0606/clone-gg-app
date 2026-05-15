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
import 'package:gloria_marketing_flutter/src/features/agent/services/visit_finish_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/post_order_sync_manager.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/order_balance_gate.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/customer_balance_status.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/customer_balance_status_cache.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/debt_blocked_dialog.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/balance_status_indicator.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/balance_status_theme.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/post_order_sync_notification.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/step_pages/photo_facing_before_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/step_pages/shelf_audit_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/step_pages/competitor_audit_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/step_pages/create_order_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/step_pages/photo_facing_after_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/order_models.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/visit_timer_widget.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/floating_timer_overlay.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/order_details_page.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations_en.dart';
import 'package:flutter/services.dart';
import 'package:gloria_marketing_flutter/src/core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

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
  final bool
  isUnplannedOrder; // Flag to indicate if this is an unplanned order visit
  final int? visitDurationSeconds; // Total visit duration in seconds
  final int?
  currentStepDuration; // Current step duration in seconds (deprecated - use stepTimers)
  final Map<int, int>
  stepTimers; // Individual timer for each step (stepCode -> durationSeconds)

  const VisitStepsLoaded({
    required this.tradingPoint,
    required this.permissions,
    required this.stepProgress,
    required this.currentStepIndex,
    required this.isStrictSequence,
    required this.canProceedToNext,
    required this.isUnplannedOrder,
    this.visitDurationSeconds,
    this.currentStepDuration,
    this.stepTimers = const {},
  });

  @override
  List<Object?> get props => [
    tradingPoint,
    permissions,
    stepProgress,
    currentStepIndex,
    isStrictSequence,
    canProceedToNext,
    isUnplannedOrder,
    visitDurationSeconds,
    currentStepDuration,
    stepTimers,
  ];

  /// Create a copy of this state with updated fields
  VisitStepsLoaded copyWith({
    TradingPointWithPermissions? tradingPoint,
    SalesReqPermissions? permissions,
    List<VisitStepProgress>? stepProgress,
    int? currentStepIndex,
    bool? isStrictSequence,
    bool? canProceedToNext,
    bool? isUnplannedOrder,
    int? visitDurationSeconds,
    int? currentStepDuration,
    Map<int, int>? stepTimers,
  }) {
    return VisitStepsLoaded(
      tradingPoint: tradingPoint ?? this.tradingPoint,
      permissions: permissions ?? this.permissions,
      stepProgress: stepProgress ?? this.stepProgress,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isStrictSequence: isStrictSequence ?? this.isStrictSequence,
      canProceedToNext: canProceedToNext ?? this.canProceedToNext,
      isUnplannedOrder: isUnplannedOrder ?? this.isUnplannedOrder,
      visitDurationSeconds: visitDurationSeconds ?? this.visitDurationSeconds,
      currentStepDuration: currentStepDuration ?? this.currentStepDuration,
      stepTimers: stepTimers ?? this.stepTimers,
    );
  }
}

class VisitStepsError extends VisitStepsState {
  final String message;

  const VisitStepsError(this.message);

  @override
  List<Object?> get props => [message];
}

class VisitStepsCompleted extends VisitStepsState {
  final TradingPointWithPermissions tradingPoint;
  final List<VisitStepProgress> completedSteps;
  final String? orderCode; // Order code if an order was created
  final String? orderServerMessage; // Server message for order creation

  const VisitStepsCompleted(
    this.tradingPoint,
    this.completedSteps, {
    this.orderCode,
    this.orderServerMessage,
  });

  @override
  List<Object?> get props => [
    tradingPoint,
    completedSteps,
    orderCode,
    orderServerMessage,
  ];
}

class VisitStepsFinishing extends VisitStepsState {
  final int currentStep;
  final int totalSteps;
  final String message;
  final TradingPointWithPermissions tradingPoint;
  final String? requestData; // SOAP request data for display

  const VisitStepsFinishing({
    required this.currentStep,
    required this.totalSteps,
    required this.message,
    required this.tradingPoint,
    this.requestData,
  });

  @override
  List<Object?> get props => [
    currentStep,
    totalSteps,
    message,
    tradingPoint,
    requestData,
  ];
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

/// Event for completing a visit step
/// Modified to accept flexible data instead of just notes to support
/// complex step completion data like order information with shipping dates
class CompleteStep extends VisitStepsEvent {
  final int stepIndex;
  final Map<String, dynamic> data;

  const CompleteStep(this.stepIndex, this.data);

  @override
  List<Object?> get props => [stepIndex, data];
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

/// Event to update timer durations in UI
/// Triggered periodically to refresh timer display
class UpdateTimers extends VisitStepsEvent {}

/// Event to pause step timer when viewing completed (read-only) step
/// Saves current timer state before pausing
class PauseStepTimer extends VisitStepsEvent {
  final int stepCode;
  const PauseStepTimer(this.stepCode);

  @override
  List<Object?> get props => [stepCode];
}

/// Event to resume step timer when returning from read-only view
class ResumeStepTimer extends VisitStepsEvent {
  final int stepCode;
  const ResumeStepTimer(this.stepCode);

  @override
  List<Object?> get props => [stepCode];
}

/// Event to start step timer when user navigates to a step page
/// This ensures step timer only counts time spent inside the step page
class StartStepTimer extends VisitStepsEvent {
  final int stepCode;
  const StartStepTimer(this.stepCode);

  @override
  List<Object?> get props => [stepCode];
}

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

enum VisitStepStatus { pending, inProgress, completed, skipped }

/// Visit Steps BLoC - Enhanced with repository-based state management
/// Ensures data persistence and consistency across page navigations
/// Supports both planned visits (strict sequence) and unplanned orders (optional steps)
class VisitStepsBloc extends Bloc<VisitStepsEvent, VisitStepsState> {
  final VisitDataRepository _visitDataRepository;
  final VisitFinishService _visitFinishService;
  String _visitId;
  final bool _isUnplannedOrder;

  // Timer management
  Timer? _visitTimer;
  Timer? _stepTimer;
  DateTime? _visitStartTime;
  DateTime? _stepStartTime;
  int _visitDurationSeconds = 0;
  int _stepDurationSeconds = 0;
  int _currentStepCode = 0; // Track which step's timer is currently running

  // In-memory cache layer for performance optimization
  final Map<int, Map<String, dynamic>> _stepTimerCache = {};
  final Map<int, Map<String, dynamic>> _stepDataCache = {};

  // Debounced database write mechanism
  Timer? _dbSaveDebounceTimer;
  bool _hasPendingVisitTimerSave = false;
  bool _hasPendingStepTimerSave = false;

  // Auto-save mechanism for crash resistance
  Timer? _autoSaveTimer;

  // Page entry/exit tracking for accurate duration calculation
  // These will be used to record actual page navigation times
  final Map<int, DateTime> _stepEntryTimes = {};
  final Map<int, DateTime> _stepExitTimes = {};

  VisitStepsBloc({
    required VisitDataRepository visitDataRepository,
    required VisitFinishService visitFinishService,
    required String visitId,
    required bool isUnplannedOrder,
  }) : _visitDataRepository = visitDataRepository,
       _visitFinishService = visitFinishService,
       _visitId = visitId,
       _isUnplannedOrder = isUnplannedOrder,
       super(VisitStepsInitial()) {
    // Initialize auto-save mechanism (every 5 seconds)
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _performAutoSave();
    });

    // Initialize debounced DB write timer (every 10 seconds)
    _dbSaveDebounceTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _performDebouncedSave();
    });
    on<LoadVisitSteps>(_onLoadVisitSteps);
    on<CompleteStep>(_onCompleteStep);
    on<SkipStep>(_onSkipStep);
    on<PreviousStep>(_onPreviousStep);
    on<FinishVisit>(_onFinishVisit);
    on<CancelVisit>(_onCancelVisit);
    on<UpdateTimers>(_onUpdateTimers);
    on<PauseStepTimer>(_onPauseStepTimer);
    on<ResumeStepTimer>(_onResumeStepTimer);
    on<StartStepTimer>(_onStartStepTimer);
  }

  @override
  Future<void> close() async {
    // Perform final save before closing to prevent data loss
    await _performFinalSave();

    // Cancel all timers
    _stopVisitTimer();
    _stopStepTimer();
    _autoSaveTimer?.cancel();
    _dbSaveDebounceTimer?.cancel();

    // Clear caches
    _stepTimerCache.clear();
    _stepDataCache.clear();
    _stepEntryTimes.clear();
    _stepExitTimes.clear();

    return super.close();
  }

  /// Auto-save mechanism - saves current state periodically
  /// Prevents data loss in case of crashes or unexpected app termination
  Future<void> _performAutoSave() async {
    try {
      if (state is! VisitStepsLoaded) return;

      // Save visit timer state if active
      if (_visitTimer != null && _visitStartTime != null) {
        await _saveVisitTimerStateToCache();
      }

      // Save step timer state if active
      if (_stepTimer != null && _currentStepCode > 0) {
        await _saveStepTimerStateToCache(_currentStepCode);
      }
    } catch (e) {
      debugPrint('VisitStepsBloc: Auto-save error: $e');
    }
  }

  /// Debounced save - writes cached data to database periodically
  /// Reduces database write operations while maintaining data integrity
  Future<void> _performDebouncedSave() async {
    try {
      // Save visit timer if pending
      if (_hasPendingVisitTimerSave && _visitStartTime != null) {
        await _saveVisitTimerStateToDB();
        _hasPendingVisitTimerSave = false;
      }

      // Save step timer if pending
      if (_hasPendingStepTimerSave && _currentStepCode > 0) {
        await _saveStepTimerStateToDB(_currentStepCode);
        _hasPendingStepTimerSave = false;
      }
    } catch (e) {
      debugPrint('VisitStepsBloc: Debounced save error: $e');
    }
  }

  /// Final save - ensures all data is persisted before BLoC closes
  /// Critical for preventing data loss on app termination
  Future<void> _performFinalSave() async {
    try {
      // Force save all pending data
      if (_visitStartTime != null) {
        await _saveVisitTimerStateToDB();
      }

      if (_currentStepCode > 0 && _stepStartTime != null) {
        await _saveStepTimerStateToDB(_currentStepCode);
      }

      debugPrint('VisitStepsBloc: Final save completed');
    } catch (e) {
      debugPrint('VisitStepsBloc: Final save error: $e');
    }
  }

  /// Start visit timer - uses StartTime for persistence across navigations
  void _startVisitTimer({
    DateTime? savedStartTime,
    int accumulatedSeconds = 0,
  }) {
    _visitStartTime = savedStartTime ?? DateTime.now();
    _visitTimer?.cancel();

    _visitDurationSeconds =
        accumulatedSeconds +
        DateTime.now().difference(_visitStartTime!).inSeconds;

    _visitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _visitDurationSeconds =
          accumulatedSeconds +
          DateTime.now().difference(_visitStartTime!).inSeconds;
    });

    debugPrint('VisitStepsBloc: Visit timer started at $_visitStartTime');
  }

  /// Stop visit timer
  void _stopVisitTimer() {
    _visitTimer?.cancel();
    _visitTimer = null;
    debugPrint(
      'VisitStepsBloc: Visit timer stopped. Duration: $_visitDurationSeconds',
    );
  }

  /// Start step timer with persistence support
  void _startStepTimer({
    required int stepCode,
    DateTime? savedStartTime,
    int accumulatedSeconds = 0,
  }) {
    _currentStepCode = stepCode;
    _stepStartTime = savedStartTime ?? DateTime.now();
    _stepTimer?.cancel();

    _stepDurationSeconds =
        accumulatedSeconds +
        DateTime.now().difference(_stepStartTime!).inSeconds;

    _stepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _stepDurationSeconds =
          accumulatedSeconds +
          DateTime.now().difference(_stepStartTime!).inSeconds;
    });

    debugPrint(
      'VisitStepsBloc: Step $stepCode timer started at $_stepStartTime',
    );
  }

  /// Stop step timer
  void _stopStepTimer() {
    _stepTimer?.cancel();
    _stepTimer = null;
    debugPrint(
      'VisitStepsBloc: Step timer stopped. Duration: $_stepDurationSeconds',
    );
  }

  /// Save visit timer state to cache (fast, in-memory operation)
  /// Marks data for debounced database write
  Future<void> _saveVisitTimerStateToCache() async {
    if (_visitStartTime == null) return;

    // Mark for database write (will be written in next debounced save)
    _hasPendingVisitTimerSave = true;
  }

  /// Save visit timer state to database (actual DB write)
  /// Called by debounced save mechanism or final save
  Future<void> _saveVisitTimerStateToDB() async {
    if (_visitStartTime == null) return;
    try {
      await _visitDataRepository.saveVisitStepData(
        VisitData(
          visitId: _visitId,
          clientCode: 'timer_metadata',
          stepCode: 0,
          stepName: 'Visit Timer',
          dataType: 'timer_state',
          dataContent: jsonEncode({
            'visitStartTime': _visitStartTime!.toIso8601String(),
            'accumulatedSeconds': _visitDurationSeconds,
          }),
          timestamp: DateTime.now(),
        ),
      );
      debugPrint('VisitStepsBloc: Visit timer state saved to DB');
    } catch (e) {
      debugPrint('VisitStepsBloc: Error saving visit timer state to DB: $e');
    }
  }

  /// Legacy method - redirects to cache-based save
  Future<void> _saveVisitTimerState() async {
    await _saveVisitTimerStateToCache();
  }

  /// Save step timer state to cache (fast, in-memory operation)
  /// Stores in cache and marks for debounced database write
  Future<void> _saveStepTimerStateToCache(int stepCode) async {
    if (_stepStartTime == null) return;

    // Save to in-memory cache
    _stepTimerCache[stepCode] = {
      'stepStartTime': _stepStartTime!.toIso8601String(),
      'accumulatedSeconds': _stepDurationSeconds,
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    // Mark for database write
    _hasPendingStepTimerSave = true;
  }

  /// Save step timer state to database (actual DB write)
  /// Called by debounced save mechanism or final save
  Future<void> _saveStepTimerStateToDB(int stepCode) async {
    if (_stepStartTime == null) return;
    try {
      await _visitDataRepository.saveVisitStepData(
        VisitData(
          visitId: _visitId,
          clientCode: 'timer_metadata',
          stepCode: stepCode,
          stepName: 'Step Timer',
          dataType: 'step_timer_state',
          dataContent: jsonEncode({
            'stepStartTime': _stepStartTime!.toIso8601String(),
            'accumulatedSeconds': _stepDurationSeconds,
          }),
          timestamp: DateTime.now(),
        ),
      );
      debugPrint('VisitStepsBloc: Step $stepCode timer state saved to DB');
    } catch (e) {
      debugPrint('VisitStepsBloc: Error saving step timer state to DB: $e');
    }
  }

  /// Legacy method - redirects to cache-based save
  Future<void> _saveStepTimerState(int stepCode) async {
    await _saveStepTimerStateToCache(stepCode);
  }

  /// Load visit timer state from database
  Future<Map<String, dynamic>?> _loadVisitTimerState() async {
    try {
      final timerData = await _visitDataRepository.getVisitStepDataByStep(
        _visitId,
        0,
      );
      final timerState = timerData
          .where((d) => d.dataType == 'timer_state')
          .toList();
      if (timerState.isNotEmpty) {
        final latest = timerState.reduce(
          (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
        );
        return jsonDecode(latest.dataContent) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading visit timer state: $e');
    }
    return null;
  }

  /// Load step timer state from cache or database
  /// First checks in-memory cache for fast access, then falls back to DB
  Future<Map<String, dynamic>?> _loadStepTimerState(int stepCode) async {
    // Check cache first (instant access)
    if (_stepTimerCache.containsKey(stepCode)) {
      debugPrint('VisitStepsBloc: Step $stepCode timer loaded from cache');
      return _stepTimerCache[stepCode];
    }

    // Load from database if not in cache
    try {
      final timerData = await _visitDataRepository.getVisitStepDataByStep(
        _visitId,
        stepCode,
      );
      final timerState = timerData
          .where((d) => d.dataType == 'step_timer_state')
          .toList();
      if (timerState.isNotEmpty) {
        final latest = timerState.reduce(
          (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
        );
        return jsonDecode(latest.dataContent) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading step timer state: $e');
    }
    return null;
  }

  /// Load all step timers from both completion data and step_timer_state cache
  /// This method loads timer values for all steps from two sources:
  /// 1. Completion data (for completed steps with final duration)
  /// 2. step_timer_state cache (for in-progress or paused steps)
  /// Priority: completion > step_timer_state
  /// Returns a Map of stepCode -> durationSeconds
  Future<Map<int, int>> _loadAllStepTimers(List<VisitStep> visitSteps) async {
    final stepTimers = <int, int>{};

    try {
      // Get all visit data for this visit
      final existingData = await _visitDataRepository.getVisitStepDataByVisitId(
        _visitId,
      );

      debugPrint(
        'VisitStepsBloc: Loading step timers from ${existingData.length} total records',
      );

      // Extract timer values from both completion and cache data
      for (final step in visitSteps) {
        bool timerFound = false;

        // 1. FIRST PRIORITY: Check completion data (for completed steps)
        final completionData = existingData
            .where(
              (d) => d.stepCode == step.stepCode && d.dataType == 'completion',
            )
            .toList();

        if (completionData.isNotEmpty) {
          try {
            final latest = completionData.reduce(
              (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
            );
            final parsedData = latest.parsedDataContent;
            final durationSeconds = parsedData['durationSeconds'] as int?;

            if (durationSeconds != null && durationSeconds > 0) {
              stepTimers[step.stepCode] = durationSeconds;
              timerFound = true;
              debugPrint(
                'VisitStepsBloc: ✅ Loaded timer for step ${step.stepCode} '
                'from COMPLETION: ${durationSeconds}s',
              );
            }
          } catch (e) {
            debugPrint(
              'VisitStepsBloc: Error parsing completion data for step ${step.stepCode}: $e',
            );
          }
        }

        // 2. SECOND PRIORITY: Check step_timer_state cache (if not found in completion)
        if (!timerFound) {
          final timerStateData = existingData
              .where(
                (d) =>
                    d.stepCode == step.stepCode &&
                    d.dataType == 'step_timer_state',
              )
              .toList();

          if (timerStateData.isNotEmpty) {
            try {
              final latest = timerStateData.reduce(
                (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
              );
              final parsedData = latest.parsedDataContent;
              final accumulatedSeconds =
                  parsedData['accumulatedSeconds'] as int?;

              if (accumulatedSeconds != null && accumulatedSeconds > 0) {
                stepTimers[step.stepCode] = accumulatedSeconds;
                timerFound = true;
                debugPrint(
                  'VisitStepsBloc: ✅ Loaded timer for step ${step.stepCode} '
                  'from CACHE (step_timer_state): ${accumulatedSeconds}s',
                );
              }
            } catch (e) {
              debugPrint(
                'VisitStepsBloc: Error parsing step_timer_state for step ${step.stepCode}: $e',
              );
            }
          }
        }

        // Log if no timer found for this step
        if (!timerFound) {
          debugPrint(
            'VisitStepsBloc: ⚠️ No timer data found for step ${step.stepCode} (${step.stepName})',
          );
        }
      }
    } catch (e) {
      debugPrint('VisitStepsBloc: Error loading step timers: $e');
    }

    debugPrint(
      'VisitStepsBloc: Total step timers loaded: ${stepTimers.length} '
      'out of ${visitSteps.length} steps',
    );
    return stepTimers;
  }

  /// Handle UpdateTimers event - refreshes UI with current timer values
  void _onUpdateTimers(UpdateTimers event, Emitter<VisitStepsState> emit) {
    if (state is! VisitStepsLoaded) return;
    final currentState = state as VisitStepsLoaded;

    // Update stepTimers map with current step timer value
    final updatedStepTimers = Map<int, int>.from(currentState.stepTimers);
    if (_currentStepCode > 0) {
      updatedStepTimers[_currentStepCode] = _stepDurationSeconds;
    }

    emit(
      currentState.copyWith(
        visitDurationSeconds: _visitDurationSeconds,
        currentStepDuration: _stepDurationSeconds,
        stepTimers: updatedStepTimers,
      ),
    );
  }

  /// Handle PauseStepTimer event - pauses step timer when viewing read-only step
  /// Saves current timer state before pausing
  Future<void> _onPauseStepTimer(
    PauseStepTimer event,
    Emitter<VisitStepsState> emit,
  ) async {
    if (_currentStepCode > 0) {
      // Save current step timer state before pausing
      await _saveStepTimerState(_currentStepCode);
      _stopStepTimer();
      debugPrint(
        'VisitStepsBloc: Step timer paused for read-only view of step ${event.stepCode}',
      );
    }
  }

  /// Handle ResumeStepTimer event - resumes step timer after returning from read-only view
  Future<void> _onResumeStepTimer(
    ResumeStepTimer event,
    Emitter<VisitStepsState> emit,
  ) async {
    // Load and restart step timer from saved state
    final stepTimerState = await _loadStepTimerState(event.stepCode);
    if (stepTimerState != null) {
      // Resume from accumulated time, but use CURRENT time as new start point
      final accumulatedSeconds =
          stepTimerState['accumulatedSeconds'] as int? ?? 0;
      _startStepTimer(
        stepCode: event.stepCode,
        savedStartTime: DateTime.now(),
        accumulatedSeconds: accumulatedSeconds,
      );
      debugPrint(
        'VisitStepsBloc: Step timer resumed for step ${event.stepCode} with ${accumulatedSeconds}s accumulated',
      );
    } else {
      _startStepTimer(stepCode: event.stepCode);
      debugPrint(
        'VisitStepsBloc: Step timer started fresh for step ${event.stepCode}',
      );
    }
  }

  /// Handle StartStepTimer event - starts step timer when user navigates to a step page
  /// This ensures step timer only counts time spent inside the step page
  /// Also records actual page entry time for accurate duration tracking
  Future<void> _onStartStepTimer(
    StartStepTimer event,
    Emitter<VisitStepsState> emit,
  ) async {
    // Record actual page entry time
    _recordStepEntry(event.stepCode);

    // Load any existing timer state for this step (for persistence across navigation)
    final stepTimerState = await _loadStepTimerState(event.stepCode);
    if (stepTimerState != null) {
      // Resume from accumulated time, but use CURRENT time as new start point
      // This prevents incorrect calculation when resuming after a pause
      final accumulatedSeconds =
          stepTimerState['accumulatedSeconds'] as int? ?? 0;
      _startStepTimer(
        stepCode: event.stepCode,
        savedStartTime: DateTime.now(),
        accumulatedSeconds: accumulatedSeconds,
      );
      debugPrint(
        'VisitStepsBloc: Step timer resumed from saved state for step ${event.stepCode} with ${accumulatedSeconds}s accumulated',
      );
    } else {
      // Start fresh timer for this step
      _startStepTimer(stepCode: event.stepCode);
      await _saveStepTimerState(event.stepCode);
      debugPrint(
        'VisitStepsBloc: Step timer started fresh for step ${event.stepCode}',
      );
    }
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
        debugPrint(
          'VisitStepsBloc: User code not found, cannot load visit steps',
        );
        emit(VisitStepsError(_l10n().userCodeNotFound));
        return;
      }

      // Get sales req permissions with visit steps from database
      // This method retrieves cached permissions that include visit steps configuration
      final permissions = await dataSyncService.getCachedSalesReqPermissions(
        userCode,
      );

      if (permissions == null) {
        debugPrint(
          'VisitStepsBloc: Permissions data not available for user $userCode',
        );
        emit(VisitStepsError(_l10n().permissionsDataNotAvailable));
        return;
      }

      // Check if visit steps are available in the permissions
      if (permissions.visitSteps.isEmpty) {
        debugPrint(
          'VisitStepsBloc: No visit steps configured for user $userCode',
        );
        emit(VisitStepsError(_l10n().visitSteps));
        return;
      }

      debugPrint(
        'VisitStepsBloc: Successfully loaded ${permissions.visitSteps.length} visit steps for user $userCode',
      );

      // For unplanned orders, make all steps optional by modifying the permissions
      // This allows users to skip any step and proceed freely through the visit process
      final modifiedPermissions = _isUnplannedOrder
          ? permissions.copyWith(
              visitSteps: permissions.visitSteps
                  .map((step) => step.copyWith(stepRequired: false))
                  .toList(),
            )
          : permissions;

      // Generate consistent visit ID for this trading point and date
      // This ensures that visits can be restored when navigating back to the page
      final today = DateTime.now().toIso8601String().split(
        'T',
      )[0]; // YYYY-MM-DD format
      _visitId =
          'visit_${userCode ?? "unknown"}_${tradingPoint.tradingPoint.id}_$today';

      debugPrint('VisitStepsBloc: Using visit ID: $_visitId');

      // Load existing step progress from persistent storage with enhanced error handling
      final stepProgress = await _loadStepProgressFromStorage(
        modifiedPermissions.visitSteps,
        tradingPoint.tradingPoint.name,
      );

      // Determine current step based on strict sequence
      final isStrictSequence = modifiedPermissions.strictSequence;
      final currentStepIndex = _getCurrentStepIndex(
        stepProgress,
        isStrictSequence,
      );

      debugPrint(
        'VisitStepsBloc: Loaded ${stepProgress.length} steps, current step index: $currentStepIndex, strict sequence: $isStrictSequence, unplanned order: $_isUnplannedOrder',
      );

      // Load and start visit timer with persistence
      final visitTimerState = await _loadVisitTimerState();
      if (visitTimerState != null) {
        final savedStartTime = DateTime.tryParse(
          visitTimerState['visitStartTime'] ?? '',
        );
        final accumulatedSeconds =
            visitTimerState['accumulatedSeconds'] as int? ?? 0;
        _startVisitTimer(
          savedStartTime: savedStartTime,
          accumulatedSeconds: accumulatedSeconds,
        );
        debugPrint('VisitStepsBloc: Resumed visit timer from saved state');
      } else {
        _startVisitTimer();
        await _saveVisitTimerState();
        debugPrint('VisitStepsBloc: Started new visit timer');
      }

      // Step timer is NOT started here - it will start when user navigates to step page
      // This ensures step timer only counts time spent inside the step page
      _stepDurationSeconds = 0;

      // Load step timers from completion data for all steps
      // This ensures timer values are preserved and displayed in FloatingTimerOverlay
      final initialStepTimers = await _loadAllStepTimers(
        modifiedPermissions.visitSteps,
      );
      debugPrint(
        'VisitStepsBloc: Loaded step timers from DB: $initialStepTimers '
        '(${initialStepTimers.length} steps with timers)',
      );

      emit(
        VisitStepsLoaded(
          tradingPoint: tradingPoint,
          permissions: modifiedPermissions,
          stepProgress: stepProgress,
          currentStepIndex: currentStepIndex,
          isStrictSequence: isStrictSequence,
          canProceedToNext: _canProceedToNext(
            stepProgress,
            currentStepIndex,
            isStrictSequence,
            _isUnplannedOrder,
          ),
          isUnplannedOrder: _isUnplannedOrder,
          visitDurationSeconds: _visitDurationSeconds,
          currentStepDuration: _stepDurationSeconds,
          stepTimers: initialStepTimers,
        ),
      );

      debugPrint(
        'VisitStepsBloc: Visit steps loaded successfully for trading point ${tradingPoint.tradingPoint.name}',
      );
    } catch (e, stackTrace) {
      // Enhanced error logging for debugging
      debugPrint('VisitStepsBloc: Error loading visit steps: $e');
      debugPrint('VisitStepsBloc: Stack trace: $stackTrace');

      // Emit error state with more descriptive message
      final errorMessage = e is Exception
          ? '${_l10n().errorOccurredPrefix}: ${e.toString().replaceAll('Exception: ', '')}'
          : _l10n().errorLoadingPermissions;

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
        debugPrint(
          'User code not found in preferences - cannot load visit steps',
        );
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

  /// Handles step completion event
  /// Updated to process flexible data structure instead of just notes
  /// This allows complex step data (like order information with shipping dates) to be saved
  Future<void> _onCompleteStep(
    CompleteStep event,
    Emitter<VisitStepsState> emit,
  ) async {
    if (state is! VisitStepsLoaded) return;

    final currentState = state as VisitStepsLoaded;
    final updatedProgress = List<VisitStepProgress>.from(
      currentState.stepProgress,
    );
    final step = updatedProgress[event.stepIndex].step;

    // Extract notes from data, defaulting to empty string if not provided
    // This maintains backward compatibility with simple note-only completions
    final notes = event.data['notes'] as String? ?? '';

    // 1. Update current step status locally
    updatedProgress[event.stepIndex] = updatedProgress[event.stepIndex]
        .copyWith(
          status: VisitStepStatus.completed,
          notes: notes,
          completedAt: DateTime.now(),
        );

    // 2. Record actual page exit time for accurate duration tracking
    final exitTime = DateTime.now();
    _stepExitTimes[step.stepCode] = exitTime;

    // 3. Save completion data to persistent storage with timer data
    // Include all data from the event, plus completion metadata and duration
    // CRITICAL: Use _stepDurationSeconds as primary source since it's the most up-to-date
    // The stepTimers map might be stale since UpdateTimers runs periodically
    final stepTimerValue = _stepDurationSeconds > 0
        ? _stepDurationSeconds
        : (currentState.stepTimers[step.stepCode] ?? 0);

    debugPrint(
      'VisitStepsBloc: Completing step ${step.stepCode} with timer value: ${stepTimerValue}s '
      '(_stepDurationSeconds: $_stepDurationSeconds, map value: ${currentState.stepTimers[step.stepCode]})',
    );

    final completionData = Map<String, dynamic>.from(event.data);
    completionData.addAll({
      'completedAt': exitTime.toIso8601String(),
      'status': 'completed',
      'durationSeconds': stepTimerValue,
      'startTime':
          _stepEntryTimes[step.stepCode]?.toIso8601String() ??
          _stepStartTime?.toIso8601String(),
      'endTime': exitTime.toIso8601String(),
    });

    // 4. Use batch operation to save completion data and clear progress data
    // This reduces database transactions from 2 to 1, improving performance
    await _saveStepCompletionBatch(
      stepCode: step.stepCode,
      stepName: step.stepName,
      completionData: completionData,
    );

    // 5. Stop current step timer and reset duration for next step
    _stopStepTimer();
    _stepDurationSeconds = 0;
    _currentStepCode = 0; // Clear current step code

    // 6. Determine next step and update state
    final newCurrentStepIndex = _getCurrentStepIndex(
      updatedProgress,
      currentState.isStrictSequence,
    );

    // 7. Preserve all existing step timers and add the newly completed step's timer
    // This ensures completed step timers are not lost when transitioning to new steps
    final updatedStepTimers = Map<int, int>.from(currentState.stepTimers);
    updatedStepTimers[step.stepCode] = stepTimerValue;

    // Next step timer will start when user navigates to step page (via StartStepTimer event)

    emit(
      VisitStepsLoaded(
        tradingPoint: currentState.tradingPoint,
        permissions: currentState.permissions,
        stepProgress: updatedProgress,
        currentStepIndex: newCurrentStepIndex,
        isStrictSequence: currentState.isStrictSequence,
        canProceedToNext: _canProceedToNext(
          updatedProgress,
          newCurrentStepIndex,
          currentState.isStrictSequence,
          currentState.isUnplannedOrder,
        ),
        isUnplannedOrder: currentState.isUnplannedOrder,
        visitDurationSeconds: _visitDurationSeconds,
        currentStepDuration: _stepDurationSeconds,
        stepTimers: updatedStepTimers,
      ),
    );
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
      emit(VisitStepsError(_l10n().stepCannotBeSkipped));
      return;
    }

    final updatedProgress = List<VisitStepProgress>.from(
      currentState.stepProgress,
    );

    // 1. Update status to completed (skipped)
    updatedProgress[event.stepIndex] = updatedProgress[event.stepIndex]
        .copyWith(
          status: VisitStepStatus.completed, // Skipped is a form of completion
          notes: event.reason,
          skipReason: event.reason,
          completedAt: DateTime.now(),
        );

    // 2. Save skip data to persistent storage
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

    // 3. Clear any "in progress" data for this step to prevent conflicts on reload
    await _removeStepProgressData(step.stepCode);

    // 4. Determine next step and update state
    final newCurrentStepIndex = _getCurrentStepIndex(
      updatedProgress,
      currentState.isStrictSequence,
    );

    // 5. Preserve stepTimers map to prevent loss of completed step timers
    final updatedStepTimers = Map<int, int>.from(currentState.stepTimers);
    // Skipped steps get 0 duration
    updatedStepTimers[step.stepCode] = 0;

    emit(
      VisitStepsLoaded(
        tradingPoint: currentState.tradingPoint,
        permissions: currentState.permissions,
        stepProgress: updatedProgress,
        currentStepIndex: newCurrentStepIndex,
        isStrictSequence: currentState.isStrictSequence,
        canProceedToNext: _canProceedToNext(
          updatedProgress,
          newCurrentStepIndex,
          currentState.isStrictSequence,
          currentState.isUnplannedOrder,
        ),
        isUnplannedOrder: currentState.isUnplannedOrder,
        stepTimers: updatedStepTimers,
      ),
    );
  }

  Future<void> _onPreviousStep(
    PreviousStep event,
    Emitter<VisitStepsState> emit,
  ) async {
    if (state is! VisitStepsLoaded) return;

    final currentState = state as VisitStepsLoaded;
    final currentStepIndex = event.currentStepIndex;
    final previousStepIndex = currentStepIndex - 1;

    if (previousStepIndex < 0) return;

    debugPrint(
      'VisitStepsBloc: PreviousStep - currentStepIndex: $currentStepIndex, previousStepIndex: $previousStepIndex',
    );

    // 1. Clear ALL data for the CURRENT step (Reset)
    final currentStep = currentState.stepProgress[currentStepIndex].step;
    debugPrint(
      'VisitStepsBloc: Clearing all data for current step ${currentStep.stepCode}',
    );
    await _clearStepDataFromStorage(currentStep.stepCode);

    // 2. Update CURRENT step status to pending locally
    final updatedProgress = List<VisitStepProgress>.from(
      currentState.stepProgress,
    );
    updatedProgress[currentStepIndex] = updatedProgress[currentStepIndex]
        .copyWith(
          status: VisitStepStatus.pending,
          notes: null,
          skipReason: null,
          completedAt: null,
        );

    // 3. Reactivate PREVIOUS step
    // We need to remove the 'completion' record for the previous step to make it active again.
    final previousStep = updatedProgress[previousStepIndex].step;
    debugPrint(
      'VisitStepsBloc: Reactivating previous step ${previousStep.stepCode}',
    );

    // Remove completion data for previous step to "un-complete" it
    await _removeStepCompletionData(previousStep.stepCode);

    // Update previous step status to inProgress locally
    updatedProgress[previousStepIndex] = updatedProgress[previousStepIndex]
        .copyWith(status: VisitStepStatus.inProgress, completedAt: null);

    // Save 'progress' marker to ensure it stays active if app restarts
    await _saveStepDataToStorage(
      stepCode: previousStep.stepCode,
      stepName: previousStep.stepName,
      dataType: 'progress',
      dataContent: {
        'status': 'inProgress',
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );

    // Preserve stepTimers map but remove timer for current step (being reset)
    // and previous step (being reactivated)
    final updatedStepTimers = Map<int, int>.from(currentState.stepTimers);
    updatedStepTimers.remove(currentStep.stepCode);
    updatedStepTimers.remove(previousStep.stepCode);

    emit(
      VisitStepsLoaded(
        tradingPoint: currentState.tradingPoint,
        permissions: currentState.permissions,
        stepProgress: updatedProgress,
        currentStepIndex: previousStepIndex,
        isStrictSequence: currentState.isStrictSequence,
        canProceedToNext: _canProceedToNext(
          updatedProgress,
          previousStepIndex,
          currentState.isStrictSequence,
          currentState.isUnplannedOrder,
        ),
        isUnplannedOrder: currentState.isUnplannedOrder,
        stepTimers: updatedStepTimers,
      ),
    );
  }

  Future<void> _onFinishVisit(
    FinishVisit event,
    Emitter<VisitStepsState> emit,
  ) async {
    if (state is! VisitStepsLoaded) return;

    final currentState = state as VisitStepsLoaded;

    // Check if all required steps are completed
    final hasIncompleteRequiredSteps = currentState.stepProgress.any(
      (progress) =>
          progress.step.stepRequired &&
          progress.status != VisitStepStatus.completed,
    );

    if (hasIncompleteRequiredSteps) {
      emit(VisitStepsError(_l10n().allRequiredStepsMustBeCompleted));
      return;
    }

    // ============================================================================
    // MASOFA CHEKLOVI TEKSHIRUVI (Distance Restriction Check)
    // ============================================================================
    // Bu tekshiruv faqat REJALI TASHRIFLAR uchun amal qiladi.
    // Rejadan tashqari buyurtmalar (isUnplannedOrder = true) uchun masofa
    // tekshiruvi o'tkazib yuboriladi, chunki agent ixtiyoriy joydan buyurtma
    // yaratishi mumkin.
    //
    // Tekshiruv shartlari:
    // 1. clientZoneAccess > 0 bo'lishi kerak (server tomonidan belgilangan masofa)
    // 2. isUnplannedOrder = false bo'lishi kerak (rejali tashrif)
    // ============================================================================
    try {
      final clientZoneAccess = currentState.permissions.clientZoneAccess;

      // Rejadan tashqari buyurtmalar uchun masofa tekshiruvini o'tkazib yuborish
      // Bu agent uchun moslashuvchanlikni ta'minlaydi - u ixtiyoriy joydan
      // rejadan tashqari buyurtma yaratishi mumkin
      if (currentState.isUnplannedOrder) {
        debugPrint(
          'VisitStepsBloc: Masofa tekshiruvi o\'tkazib yuborildi - rejadan tashqari buyurtma',
        );
      } else if (clientZoneAccess > 0) {
        // Faqat rejali tashriflar uchun masofa tekshiruvini bajarish
        debugPrint(
          'VisitStepsBloc: Masofa tekshiruvi boshlanmoqda - clientZoneAccess: $clientZoneAccess metr',
        );

        emit(
          VisitStepsFinishing(
            currentStep: 0,
            totalSteps: currentState.stepProgress.length,
            message: _l10n().checkingDistance,
            tradingPoint: currentState.tradingPoint,
          ),
        );

        // Joriy joylashuvni olish
        final locationService = sl<LocationService>();
        final position = await locationService.getCurrentLocation();

        // Joylashuv ma'lumotlari mavjud emasligini tekshirish
        if (position == null) {
          debugPrint('VisitStepsBloc: Joylashuv ma\'lumotlari mavjud emas');
          emit(VisitStepsError(_l10n().locationNotAvailable));
          return;
        }

        // Agent va mijoz orasidagi masofani hisoblash
        final distanceKm = locationService.calculateDistance(
          position.latitude,
          position.longitude,
          currentState.tradingPoint.tradingPoint.latitude,
          currentState.tradingPoint.tradingPoint.longitude,
        );

        final distanceMeters = distanceKm * 1000;

        // Masofa cheklovini tekshirish
        // Agar agent belgilangan masofadan uzoqda bo'lsa, xatolik qaytarish
        if (distanceMeters > clientZoneAccess) {
          debugPrint(
            'VisitStepsBloc: Masofa cheklovi bajarilmadi - joriy: ${distanceMeters.toStringAsFixed(0)}m > talab: ${clientZoneAccess}m',
          );
          emit(VisitStepsError(_l10n().distanceRestrictionError));
          return;
        }

        debugPrint(
          'VisitStepsBloc: Masofa tekshiruvi muvaffaqiyatli - joriy: ${distanceMeters.toStringAsFixed(0)}m <= talab: ${clientZoneAccess}m',
        );
      } else {
        // clientZoneAccess = 0 bo'lganda masofa tekshiruvi o'tkazib yuboriladi
        debugPrint(
          'VisitStepsBloc: Masofa tekshiruvi o\'tkazib yuborildi - clientZoneAccess = 0',
        );
      }
    } catch (e, stackTrace) {
      // Masofa tekshiruvida xatolik yuz berganda
      // Xavfsizlik nuqtai nazaridan, xatolik bo'lsa visitni yakunlashga ruxsat bermaslik
      debugPrint('VisitStepsBloc: Masofa tekshiruvida xatolik: $e');
      debugPrint('VisitStepsBloc: Stack trace: $stackTrace');
      emit(VisitStepsError('${_l10n().errorOccurredPrefix}: $e'));
      return;
    }

    // Start finishing process with progress updates
    try {
      final success = await _visitFinishService.finishVisit(
        visitId: _visitId,
        tradingPoint: currentState.tradingPoint,
        permissions: currentState.permissions,
        onProgress: (currentStep, totalSteps, message, [requestData]) {
          emit(
            VisitStepsFinishing(
              currentStep: currentStep,
              totalSteps: totalSteps,
              message: message,
              tradingPoint: currentState.tradingPoint,
              requestData: requestData,
            ),
          );
        },
        onError: (step, error) {
          emit(
            VisitStepsError(
              '${_l10n().stepErrorPrefix}: ${step.stepName} - $error',
            ),
          );
        },
      );

      if (success) {
        // Stop all timers and save final visit completion data
        _stopVisitTimer();
        _stopStepTimer();

        // Save visit completion data with end time
        await _visitDataRepository.saveVisitStepData(
          VisitData(
            visitId: _visitId,
            clientCode: 'timer_metadata',
            stepCode: 0,
            stepName: 'Visit Completion',
            dataType: 'visit_completion',
            dataContent: jsonEncode({
              'visitStartTime': _visitStartTime?.toIso8601String(),
              'visitEndTime': DateTime.now().toIso8601String(),
              'totalDurationSeconds': _visitDurationSeconds,
              'completedAt': DateTime.now().toIso8601String(),
            }),
            timestamp: DateTime.now(),
          ),
        );
        debugPrint('VisitStepsBloc: Visit completion data saved with endTime');

        // Clear all visit data after successful completion (like canceling visit)
        await _visitFinishService.cancelAllSteps(visitId: _visitId);

        // Get completed steps for display
        final completedSteps = currentState.stepProgress
            .where((p) => p.status == VisitStepStatus.completed)
            .toList();

        // Extract order code and server message if an order was created
        String? orderCode;
        String? orderServerMessage;
        final orderStep = completedSteps.firstWhere(
          (step) => step.step.stepName.toLowerCase() == 'создать заказ',
          orElse: () => VisitStepProgress(
            step: VisitStep(stepCode: -1, stepName: '', stepRequired: false),
            status: VisitStepStatus.pending,
          ),
        );
        if (orderStep.step.stepCode != -1) {
          // Get completion data to extract server message and order code
          try {
            final stepData = await _visitDataRepository.getVisitStepDataByStep(
              _visitId,
              orderStep.step.stepCode,
            );
            final completionData = stepData
                .where((d) => d.dataType == 'completion')
                .toList();
            if (completionData.isNotEmpty) {
              final latestData = completionData.reduce(
                (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
              );
              final parsedData =
                  jsonDecode(latestData.dataContent) as Map<String, dynamic>;
              orderServerMessage = parsedData['serverMessage'] as String?;
              final codeOrder = parsedData['codeOrder'] as String?;
              if (codeOrder != null && codeOrder.isNotEmpty) {
                orderCode = codeOrder;
              }
            }
          } catch (e) {
            debugPrint('VisitStepsBloc: Error extracting order data: $e');
          }

          // Fallback to notes if no codeOrder in completion data
          if (orderCode == null &&
              orderStep.notes != null &&
              orderStep.notes!.isNotEmpty) {
            orderCode = orderStep.notes;
          }
        }

        emit(
          VisitStepsCompleted(
            currentState.tradingPoint,
            completedSteps,
            orderCode: orderCode,
            orderServerMessage: orderServerMessage,
          ),
        );
      }
      // Error already emitted by onError callback
    } catch (e, stackTrace) {
      debugPrint('VisitStepsBloc: Error finishing visit: $e');
      debugPrint('VisitStepsBloc: Stack trace: $stackTrace');
      emit(
        VisitStepsError('${_l10n().visitFinishErrorPrefix}: ${e.toString()}'),
      );
    }
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

      debugPrint(
        'Visit cancelled and all data cleared for visit ID: $_visitId',
      );
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
      debugPrint(
        'VisitStepsBloc: Clearing all visit data for visit ID: $_visitId',
      );

      // Delete all visit step data for this visit ID
      await _visitDataRepository.deleteVisitStepDataByVisitId(_visitId);

      // Clear any cached data in services if needed
      // Note: Individual step data is already cleared via _clearStepDataFromStorage

      debugPrint(
        'VisitStepsBloc: All visit data cleared successfully for visit ID: $_visitId',
      );
    } catch (e, stackTrace) {
      debugPrint('VisitStepsBloc: Error clearing all visit data: $e');
      debugPrint('VisitStepsBloc: Stack trace: $stackTrace');

      // Enhanced error handling - log but don't throw
      // We want to allow cancellation even if cleanup partially fails
      // TODO: Consider implementing partial cleanup recovery
    }
  }

  int _getCurrentStepIndex(
    List<VisitStepProgress> progress,
    bool isStrictSequence,
  ) {
    // Find the first step that is NOT completed.
    // This logic applies to both strict and non-strict for determining the "Active" step.
    // In strict mode, this is the ONLY accessible step (plus completed ones for review).
    // In non-strict mode, this is just the default "next" step.

    final index = progress.indexWhere(
      (p) => p.status != VisitStepStatus.completed,
    );
    return index; // Returns -1 if all are completed
  }

  /// Determines if the user can proceed to the next step
  /// For unplanned orders, always returns true to allow free navigation
  /// For planned visits, follows strict sequence rules
  bool _canProceedToNext(
    List<VisitStepProgress> progress,
    int currentStepIndex,
    bool isStrictSequence,
    bool isUnplannedOrder,
  ) {
    if (currentStepIndex == -1) return false; // All completed

    // For unplanned orders, always allow proceeding to next step
    // This enables flexible workflow where users can skip steps as needed
    if (isUnplannedOrder) return true;

    if (!isStrictSequence) return true; // Can always proceed in non-strict mode

    // In strict mode, check if current step is completed or can be skipped
    final currentStep = progress[currentStepIndex];
    return currentStep.status == VisitStepStatus.completed ||
        (!currentStep.step.stepRequired &&
            currentStep.status == VisitStepStatus.pending);
  }

  /// Load step progress from persistent storage with enhanced error handling
  /// This method ensures data consistency by always loading the latest data from repository
  Future<List<VisitStepProgress>> _loadStepProgressFromStorage(
    List<VisitStep> visitSteps,
    String clientCode,
  ) async {
    try {
      debugPrint(
        'VisitStepsBloc: Loading step progress for visit ID: $_visitId, client: $clientCode',
      );

      // Get existing visit data for this visit session
      final existingData = await _visitDataRepository.getVisitStepDataByVisitId(
        _visitId,
      );

      debugPrint(
        'VisitStepsBloc: Found ${existingData.length} existing data records for visit',
      );

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

        debugPrint(
          'VisitStepsBloc: Processing step ${step.stepCode} (${step.stepName})',
        );

        if (existingDataForStep != null) {
          debugPrint(
            'VisitStepsBloc: Found existing data for step ${step.stepCode}: ${existingDataForStep.keys}',
          );
          // Check for completion data first (takes precedence over progress)
          final progressData = existingDataForStep['progress'];
          final completionData = existingDataForStep['completion'];

          // Prioritize progress data over completion data to handle going back correctly
          if (progressData != null) {
            // Step is in progress (takes precedence over completion)
            debugPrint(
              'VisitStepsBloc: Step ${step.stepCode} has progress data: ${progressData.dataContent}',
            );
            try {
              final parsedData = progressData.parsedDataContent;
              stepProgress.add(
                VisitStepProgress(
                  step: step,
                  status: VisitStepStatus.inProgress,
                  notes: parsedData['notes'], // Keep any existing notes
                ),
              );
              debugPrint(
                'VisitStepsBloc: Step ${step.stepCode} (${step.stepName}) loaded as in-progress with notes: ${parsedData['notes']}',
              );
            } catch (e) {
              debugPrint(
                'VisitStepsBloc: Error parsing progress data for step ${step.stepCode}: $e',
              );
              // Fallback to pending if data is corrupted
              stepProgress.add(
                VisitStepProgress(step: step, status: VisitStepStatus.pending),
              );
            }
          } else if (completionData != null) {
            // Step was previously completed
            debugPrint(
              'VisitStepsBloc: Step ${step.stepCode} has completion data: ${completionData.dataContent}',
            );
            try {
              final parsedData = completionData.parsedDataContent;
              final completedAt = parsedData['completedAt'] != null
                  ? DateTime.parse(parsedData['completedAt'])
                  : null;

              stepProgress.add(
                VisitStepProgress(
                  step: step,
                  status: VisitStepStatus.completed,
                  notes: parsedData['notes'],
                  completedAt: completedAt,
                ),
              );
              debugPrint(
                'VisitStepsBloc: Step ${step.stepCode} (${step.stepName}) loaded as completed with notes: ${parsedData['notes']}',
              );
            } catch (e) {
              debugPrint(
                'VisitStepsBloc: Error parsing completion data for step ${step.stepCode}: $e',
              );
              // Fallback to pending if data is corrupted
              stepProgress.add(
                VisitStepProgress(step: step, status: VisitStepStatus.pending),
              );
            }
          } else {
            // Step has data but no progress/completion status
            debugPrint(
              'VisitStepsBloc: Step ${step.stepCode} has data but no progress/completion status',
            );
            stepProgress.add(
              VisitStepProgress(step: step, status: VisitStepStatus.pending),
            );
            debugPrint(
              'VisitStepsBloc: Step ${step.stepCode} (${step.stepName}) has data but no status, set to pending',
            );
          }
        } else {
          // Step is pending - no data exists
          stepProgress.add(
            VisitStepProgress(step: step, status: VisitStepStatus.pending),
          );
          debugPrint(
            'VisitStepsBloc: Step ${step.stepCode} (${step.stepName}) is pending (no existing data)',
          );
        }
      }

      debugPrint(
        'VisitStepsBloc: Successfully loaded ${stepProgress.length} step progress records',
      );
      return stepProgress;
    } catch (e, stackTrace) {
      debugPrint(
        'VisitStepsBloc: Error loading step progress from storage: $e',
      );
      debugPrint('VisitStepsBloc: Stack trace: $stackTrace');

      // Fallback to default initialization with detailed logging
      debugPrint(
        'VisitStepsBloc: Falling back to default initialization for all steps',
      );
      final fallbackProgress = visitSteps.map((step) {
        debugPrint(
          'VisitStepsBloc: Step ${step.stepCode} (${step.stepName}) initialized as pending (fallback)',
        );
        return VisitStepProgress(step: step, status: VisitStepStatus.pending);
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
        debugPrint(
          'VisitStepsBloc: Cannot save step data - bloc not in loaded state',
        );
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

      debugPrint(
        'VisitStepsBloc: Saving step data - visitId: $_visitId, stepCode: $stepCode, dataType: $dataType',
      );

      await _visitDataRepository.saveVisitStepData(visitData);

      debugPrint(
        'VisitStepsBloc: Step data saved successfully for step $stepCode ($stepName)',
      );
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
      debugPrint(
        'VisitStepsBloc: Clearing step data for visitId: $_visitId, stepCode: $stepCode',
      );

      await _visitDataRepository.deleteVisitStepDataByStepCode(
        _visitId,
        stepCode,
      );

      debugPrint(
        'VisitStepsBloc: Step data cleared successfully for step $stepCode',
      );
    } catch (e, stackTrace) {
      debugPrint('VisitStepsBloc: Error clearing step data from storage: $e');
      debugPrint('VisitStepsBloc: Stack trace: $stackTrace');
    }
  }

  /// Remove specifically the completion data for a step
  /// Used when navigating back to a previous step to "un-complete" it
  Future<void> _removeStepCompletionData(int stepCode) async {
    try {
      debugPrint(
        'VisitStepsBloc: Removing completion data for visitId: $_visitId, stepCode: $stepCode',
      );

      // Get all data for this step
      final stepData = await _visitDataRepository.getVisitStepDataByStep(
        _visitId,
        stepCode,
      );

      // Find completion records
      final completionRecords = stepData.where(
        (d) => d.dataType == 'completion',
      );

      // Delete them
      for (final record in completionRecords) {
        if (record.id != null) {
          await _visitDataRepository.deleteVisitStepData(record.id!);
        }
      }

      debugPrint('VisitStepsBloc: Completion data removed for step $stepCode');
    } catch (e, stackTrace) {
      debugPrint('VisitStepsBloc: Error removing completion data: $e');
      debugPrint('VisitStepsBloc: Stack trace: $stackTrace');
    }
  }

  /// Remove specifically the progress data for a step
  /// Used when completing/skipping a step to ensure it doesn't load as "in progress" next time
  Future<void> _removeStepProgressData(int stepCode) async {
    try {
      debugPrint(
        'VisitStepsBloc: Removing progress data for visitId: $_visitId, stepCode: $stepCode',
      );

      // Get all data for this step
      final stepData = await _visitDataRepository.getVisitStepDataByStep(
        _visitId,
        stepCode,
      );

      // Find progress records
      final progressRecords = stepData.where((d) => d.dataType == 'progress');

      // Delete them
      for (final record in progressRecords) {
        if (record.id != null) {
          await _visitDataRepository.deleteVisitStepData(record.id!);
        }
      }

      debugPrint('VisitStepsBloc: Progress data removed for step $stepCode');
    } catch (e, stackTrace) {
      debugPrint('VisitStepsBloc: Error removing progress data: $e');
      debugPrint('VisitStepsBloc: Stack trace: $stackTrace');
    }
  }

  /// Batch operation to save step completion and clear progress data
  /// This reduces database transactions from 2 to 1, improving performance
  /// Critical for maintaining data consistency during step transitions
  Future<void> _saveStepCompletionBatch({
    required int stepCode,
    required String stepName,
    required Map<String, dynamic> completionData,
  }) async {
    try {
      if (state is! VisitStepsLoaded) {
        debugPrint(
          'VisitStepsBloc: Cannot save completion batch - bloc not in loaded state',
        );
        return;
      }

      final currentState = state as VisitStepsLoaded;

      // Create completion data record
      final completionRecord = VisitData(
        visitId: _visitId,
        clientCode: currentState.tradingPoint.tradingPoint.name,
        stepCode: stepCode,
        stepName: stepName,
        dataType: 'completion',
        dataContent: jsonEncode(completionData),
        timestamp: DateTime.now(),
      );

      debugPrint(
        'VisitStepsBloc: Saving completion batch for step $stepCode ($stepName)',
      );

      // Save completion data
      await _visitDataRepository.saveVisitStepData(completionRecord);

      // Clear progress data in same operation context
      await _removeStepProgressData(stepCode);

      debugPrint(
        'VisitStepsBloc: Completion batch saved successfully for step $stepCode',
      );
    } catch (e, stackTrace) {
      debugPrint('VisitStepsBloc: Error in batch completion save: $e');
      debugPrint('VisitStepsBloc: Stack trace: $stackTrace');

      // Don't throw to avoid breaking UI flow
      // TODO: Implement retry mechanism or user notification
    }
  }

  /// Record step entry time for accurate duration tracking
  /// Called when user navigates to a step page
  void _recordStepEntry(int stepCode) {
    final entryTime = DateTime.now();
    _stepEntryTimes[stepCode] = entryTime;

    debugPrint(
      'VisitStepsBloc: Step $stepCode entry recorded at ${entryTime.toIso8601String()}',
    );
  }

  /// Helper method to get localization instance
  /// Returns AppLocalizations for error messages and UI text
  AppLocalizations _l10n() {
    // This is a placeholder - in real implementation, context would be needed
    // For BLoC, we'll use English fallback
    return AppLocalizationsEn();
  }
}

/// Visit Steps Page Widget
/// Handles both planned visits and unplanned orders.
/// For unplanned orders, all visit steps become optional and users can proceed freely.
class VisitStepsPage extends StatelessWidget {
  final TradingPointWithPermissions tradingPoint;
  final bool
  isUnplannedOrder; // Flag to indicate if this is an unplanned order visit

  const VisitStepsPage({
    super.key,
    required this.tradingPoint,
    this.isUnplannedOrder = false, // Default to planned visit
  });

  @override
  Widget build(BuildContext context) {
    // Generate visitId for this session
    final today = DateTime.now().toIso8601String().split('T')[0];
    final visitId = 'visit_temp_${tradingPoint.tradingPoint.id}_$today';

    return BlocProvider(
      create: (context) => VisitStepsBloc(
        visitDataRepository: VisitDataRepository(sl<ApiDatabaseService>()),
        visitFinishService: VisitFinishService(
          VisitDataRepository(sl<ApiDatabaseService>()),
        ),
        visitId: visitId,
        isUnplannedOrder: isUnplannedOrder,
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
  /// PostOrderSyncManager - for background sync after order submission
  PostOrderSyncManager? _postOrderSyncManager;
  bool _syncStarted = false;

  /// Timer to periodically update UI with current timer values
  Timer? _uiUpdateTimer;

  /// Show/hide floating timer overlay
  bool _showTimerOverlay = false;

  @override
  void initState() {
    super.initState();
    // Start periodic timer to update UI every second
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        context.read<VisitStepsBloc>().add(UpdateTimers());
      }
    });
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    _postOrderSyncManager?.dispose();
    super.dispose();
  }

  /// Start background sync after successful order submission
  void _startBackgroundSync(BuildContext context) {
    if (_syncStarted) return;
    _syncStarted = true;

    debugPrint(
      'VisitStepsView: Starting background sync after order submission',
    );

    _postOrderSyncManager = PostOrderSyncManager(
      dataSyncService: sl<DataSyncService>(),
    );

    final progressStream = _postOrderSyncManager!
        .syncAfterOrderSubmissionStream();

    PostOrderSyncNotification.show(
      context,
      progressStream,
      autoDismissOnComplete: true,
      autoDismissDelay: const Duration(seconds: 4),
    );
  }

  Future<void> _navigateToOrderDetails(
    BuildContext context,
    String orderCode,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final ds = sl<DataSyncService>();
      final order = await ds.getCachedOrderByNumOrder(orderCode);

      if (order == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.orderNotFound),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final model = OrderModel(
        id: order.id,
        numOrder: order.numOrder,
        dateOrder: order.dateOrder,
        captionOrder: order.captionOrder,
        typePriceCode: order.typePriceCode,
        status: order.status,
        commentSupervisor: order.commentSupervisor,
        commentForwarder: order.commentForwarder,
        commentAgent: order.commentAgent,
        total: order.total,
        clientCode: order.clientCode,
        clientName: order.clientName,
        codeOrg: order.codeOrg,
        mainStatus: order.mainStatus,
        courierName: order.courierName,
        courierCar: order.courierCar,
        courierPlate: null,
        items: const [],
      );

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => OrderDetailsPage(order: model)),
      );
    } catch (e) {
      debugPrint('Error navigating to order details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.orderDetailsNavigationErrorPrefix}: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.visitClient),
        centerTitle: true,
        actions: [
          // Timer icon button - toggles floating overlay
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
          BlocBuilder<VisitStepsBloc, VisitStepsState>(
            builder: (context, state) {
              if (state is VisitStepsLoaded &&
                  state.visitDurationSeconds != null) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: CompactVisitTimerWidget(
                      durationSeconds: state.visitDurationSeconds!,
                      isActive: true,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
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
      body: Stack(
        children: [
          BlocConsumer<VisitStepsBloc, VisitStepsState>(
            listener: (context, state) {
              if (state is VisitStepsError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
                // Close the visit page on error after a delay
                Future.delayed(const Duration(seconds: 2), () {
                  if (context.mounted) {
                    Navigator.of(context).pop(false); // Return failure
                  }
                });
              }
              // VisitStepsCompleted is now handled by the UI builder, not the listener
            },
            builder: (context, state) {
              if (state is VisitStepsLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is VisitStepsLoaded) {
                return _buildLoadedView(context, state, theme, l10n);
              }

              if (state is VisitStepsCompleted) {
                return _buildCompletedView(context, state, theme, l10n);
              }

              if (state is VisitStepsFinishing) {
                return _buildFinishingView(context, state, theme, l10n);
              }

              if (state is VisitStepsError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          context.read<VisitStepsBloc>().add(
                            LoadVisitSteps(widget.tradingPoint),
                          );
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
          // Floating timer overlay
          if (_showTimerOverlay)
            BlocBuilder<VisitStepsBloc, VisitStepsState>(
              builder: (context, state) {
                if (state is VisitStepsLoaded) {
                  // Debug: Log stepTimers map before creating UI
                  debugPrint(
                    'FloatingTimerOverlay: stepTimers map = ${state.stepTimers}',
                  );

                  // Prepare all steps with their timer info
                  final allSteps = state.stepProgress.map((stepProgress) {
                    final timerValue =
                        state.stepTimers[stepProgress.step.stepCode];
                    debugPrint(
                      'FloatingTimerOverlay: Step ${stepProgress.step.stepCode} '
                      '(${stepProgress.step.stepName}) - timer: $timerValue, '
                      'isCompleted: ${stepProgress.status == VisitStepStatus.completed}',
                    );

                    return StepTimerInfo(
                      stepName: stepProgress.step.stepName,
                      stepCode: stepProgress.step.stepCode,
                      durationSeconds: timerValue,
                      isActive:
                          state.currentStepIndex >= 0 &&
                          state.currentStepIndex < state.stepProgress.length &&
                          state
                                  .stepProgress[state.currentStepIndex]
                                  .step
                                  .stepCode ==
                              stepProgress.step.stepCode,
                      isCompleted:
                          stepProgress.status == VisitStepStatus.completed,
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
          Expanded(child: _buildStepsList(context, state, theme, l10n)),

          // Action Buttons
          _buildActionButtons(context, state, theme, l10n),
        ],
      ),
    );
  }

  Widget _buildFinishingView(
    BuildContext context,
    VisitStepsFinishing state,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final progress = state.totalSteps > 0
        ? state.currentStep / state.totalSteps
        : 0.0;

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
          _buildClientHeaderFinishing(context, state, theme),

          // Progress Indicator for finishing
          _buildFinishingProgressIndicator(context, state, theme),

          // Center content with message and request data
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    state.message,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${state.currentStep} / ${state.totalSteps} ${l10n.stepsCount}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  // Display SOAP request data if available
                  if (state.requestData != null &&
                      state.requestData!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.code,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.soapRequest,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                onPressed: () async {
                                  if (state.requestData != null &&
                                      state.requestData!.isNotEmpty) {
                                    await Clipboard.setData(
                                      ClipboardData(text: state.requestData!),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.soapRequestCopied),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                tooltip: l10n.copy,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 300),
                            child: SingleChildScrollView(
                              child: SelectableText(
                                state.requestData!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
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
        ],
      ),
    );
  }

  Widget _buildCompletedView(
    BuildContext context,
    VisitStepsCompleted state,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    // Start background sync if order was successfully submitted
    if (state.orderCode != null && state.orderCode!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startBackgroundSync(context);
        }
      });
    }

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
          // Success Header
          _buildCompletionHeader(context, state, theme),

          // Completed Steps List
          Expanded(
            child: _buildCompletedStepsList(context, state, theme, l10n),
          ),

          // Action Buttons
          _buildCompletionActionButtons(context, state, theme, l10n),
        ],
      ),
    );
  }

  Widget _buildCompletionHeader(
    BuildContext context,
    VisitStepsCompleted state,
    ThemeData theme,
  ) {
    final l10n = AppLocalizations.of(context)!;
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
      child: Column(
        children: [
          Icon(Icons.check_circle, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            l10n.visitCompletedSuccessfully,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            state.tradingPoint.tradingPoint.name,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (state.orderCode != null) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.orderNumber}: ${state.orderCode}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (state.orderServerMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              state.orderServerMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedStepsList(
    BuildContext context,
    VisitStepsCompleted state,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.completedSteps.length,
      itemBuilder: (context, index) {
        final stepProgress = state.completedSteps[index];
        final isOrderStep =
            stepProgress.step.stepName.toLowerCase() == 'создать заказ';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: isOrderStep && state.orderCode != null
                ? () => _navigateToOrderDetails(context, state.orderCode!)
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isOrderStep ? Icons.receipt_long : Icons.check_circle,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stepProgress.step.stepName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (stepProgress.notes != null &&
                            stepProgress.notes!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            stepProgress.notes!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (stepProgress.completedAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.completedAt}: ${stepProgress.completedAt!.toLocal().toString().split('.')[0]}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isOrderStep) ...[
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletionActionButtons(
    BuildContext context,
    VisitStepsCompleted state,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final hasOrder = state.orderCode != null && state.orderCode!.isNotEmpty;

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
        child: hasOrder
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Buyurtmani ko'rish tugmasi
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          _navigateToOrderDetails(context, state.orderCode!),
                      icon: const Icon(Icons.receipt_long),
                      label: Text(l10n.viewOrder),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Yakunlash tugmasi
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.done),
                      label: Text(l10n.finishVisit),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              )
            : FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.done),
                label: Text(l10n.finishVisit),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
      ),
    );
  }

  Widget _buildClientHeader(
    BuildContext context,
    VisitStepsLoaded state,
    ThemeData theme,
  ) {
    final l10n = AppLocalizations.of(context)!;
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
                  ? state.tradingPoint.tradingPoint.name.characters.first
                        .toUpperCase()
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
                      '${l10n.visitStepNumber}: ${state.tradingPoint.visitStepNumber}',
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

  Widget _buildClientHeaderFinishing(
    BuildContext context,
    VisitStepsFinishing state,
    ThemeData theme,
  ) {
    final l10n = AppLocalizations.of(context)!;
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
                  ? state.tradingPoint.tradingPoint.name.characters.first
                        .toUpperCase()
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
                  l10n.visitFinishing,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishingProgressIndicator(
    BuildContext context,
    VisitStepsFinishing state,
    ThemeData theme,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final progress = state.totalSteps > 0
        ? state.currentStep / state.totalSteps
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.finishVisit,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${state.currentStep} / ${state.totalSteps}',
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
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    VisitStepsLoaded state,
    ThemeData theme,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final completedSteps = state.stepProgress
        .where((p) => p.status == VisitStepStatus.completed)
        .length;
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
                l10n.visitProgress,
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
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
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

        // Determine if this specific card should be interactive
        // It should be interactive if it's the current step OR if strict sequence is off
        // But we also need to consider if it's completed/skipped
        final canInteract = _canInteractWithStep(stepProgress, index, state);

        return _VisitStepCard(
          key: ValueKey(
            '${stepProgress.step.stepCode}_${stepProgress.status}_$isCurrentStep',
          ), // Force rebuild on state change
          stepProgress: stepProgress,
          isCurrentStep: isCurrentStep,
          canInteract: canInteract,
          isStrictSequence: state.isStrictSequence,
          tradingPoint: state.tradingPoint,
          visitId: (context.read<VisitStepsBloc>() as VisitStepsBloc)._visitId,
          currentStepIndex: state.currentStepIndex,
          onComplete: (data) {
            context.read<VisitStepsBloc>().add(CompleteStep(index, data));
          },
          onSkip: (reason) {
            context.read<VisitStepsBloc>().add(SkipStep(index, reason));
          },
          onPrevious: () {
            context.read<VisitStepsBloc>().add(
              PreviousStep(state.currentStepIndex),
            );
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
                      title: Text(l10n.cancelVisit),
                      content: Text(l10n.cancelVisitConfirmation),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(l10n.no),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: Text(l10n.yes),
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
                      Navigator.of(
                        context,
                      ).pop(false); // Return false to indicate cancellation
                    }
                  }
                },
                icon: const Icon(Icons.close),
                label: Text(l10n.cancel),
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
                label: Text(l10n.finishVisit),
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

  bool _canInteractWithStep(
    VisitStepProgress stepProgress,
    int index,
    VisitStepsLoaded state,
  ) {
    // If strict sequence is disabled, user can interact with any step
    if (!state.isStrictSequence) return true;

    // In strict sequence:
    // 1. Can interact with the CURRENT active step
    if (index == state.currentStepIndex) return true;

    // 2. Can view/edit COMPLETED steps (read-only or edit depending on logic, but card is interactive)
    if (stepProgress.status == VisitStepStatus.completed ||
        stepProgress.status == VisitStepStatus.skipped)
      return true;

    // 3. Cannot interact with future steps
    return false;
  }

  void _showVisitInfoDialog(BuildContext context, VisitStepsLoaded state) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.visitInfo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.client}: ${state.tradingPoint.tradingPoint.name}'),
            const SizedBox(height: 8),
            Text(
              '${l10n.strictSequence}: ${state.isStrictSequence ? l10n.yes : l10n.no}',
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.visitStepNumber}: ${state.tradingPoint.visitStepNumber}',
            ),
            const SizedBox(height: 8),
            Text('${l10n.totalSteps}: ${state.stepProgress.length}'),
            const SizedBox(height: 8),
            Text(
              '${l10n.requiredSteps}: ${state.stepProgress.where((p) => p.step.stepRequired).length}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
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
  final Function(Map<String, dynamic>)
  onComplete; // Updated to accept flexible data for complex completions
  final Function(String) onSkip;
  final Function() onPrevious;

  const _VisitStepCard({
    super.key,
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
    final l10n = AppLocalizations.of(context)!;
    final step = widget.stepProgress.step;
    final status = widget.stepProgress.status;

    Color cardColor;
    Color borderColor;
    IconData statusIcon;

    // Determine card appearance based on status AND current step
    if (widget.isCurrentStep) {
      // Active step styling takes precedence
      cardColor = theme.colorScheme.surface;
      borderColor = theme.colorScheme.primary;
      statusIcon = Icons.play_circle_filled; // Distinct icon for current step
    } else {
      switch (status) {
        case VisitStepStatus.completed:
          cardColor = theme.colorScheme.primaryContainer.withOpacity(0.3);
          borderColor = theme.colorScheme.primary.withOpacity(0.5);
          statusIcon = Icons.check_circle;
          break;
        case VisitStepStatus.skipped:
          cardColor = theme.colorScheme.surfaceVariant.withOpacity(0.3);
          borderColor = theme.colorScheme.outline;
          statusIcon = Icons.skip_next;
          break;
        case VisitStepStatus.inProgress:
          // Should rarely happen for non-current steps in strict mode, but possible
          cardColor = theme.colorScheme.secondaryContainer.withOpacity(0.3);
          borderColor = theme.colorScheme.secondary;
          statusIcon = Icons.play_circle_outline;
          break;
        default: // Pending
          cardColor = theme.colorScheme.surface;
          borderColor = theme.colorScheme.outlineVariant;
          statusIcon = Icons.radio_button_unchecked;
      }
    }

    // Customer-balance gate (M12 rebuilt). The "create order" step is the
    // only one that can be blocked by debt; for every other step we keep
    // the standard appearance. When over-limit we tint the card red,
    // override the status icon with a block glyph and route taps to the
    // dialog instead of the order page. Read-only steps (already
    // completed) still allow viewing the saved order.
    final isCreateOrderStep =
        step.stepName.toLowerCase() == 'создать заказ';
    final isReadOnlyView = status == VisitStepStatus.completed;
    final balanceCache = sl.isRegistered<CustomerBalanceStatusCache>()
        ? sl<CustomerBalanceStatusCache>()
        : null;

    return ListenableBuilder(
      listenable: balanceCache ?? ValueNotifier<int>(0),
      builder: (context, _) {
        final tpInn = widget.tradingPoint.tradingPoint.inn;
        final balanceStatus = balanceCache?.statusFor(tpInn) ??
            CustomerBalanceStatus.unknown;
        final isBlockedByDebt = isCreateOrderStep &&
            !isReadOnlyView &&
            balanceStatus == CustomerBalanceStatus.debtOverLimit;

        Color effectiveCardColor = cardColor;
        Color effectiveBorderColor = borderColor;
        IconData effectiveStatusIcon = statusIcon;

        if (isBlockedByDebt) {
          final tint = BalanceStatusTheme.cardTintFor(
            balanceStatus,
            theme.colorScheme,
          );
          if (tint != null) {
            effectiveCardColor =
                Color.alphaBlend(tint, theme.colorScheme.surface);
          }
          effectiveBorderColor = theme.colorScheme.error;
          effectiveStatusIcon = Icons.block;
        }

        return InkWell(
          onTap: isBlockedByDebt
              ? () => _showDebtBlockedFromTile(context, balanceCache, tpInn)
              : () => _navigateToStepDetail(context, step),
          child: Card(
        elevation: widget.isCurrentStep ? 4 : 1,
        margin: const EdgeInsets.only(bottom: 12),
        color: effectiveCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: effectiveBorderColor,
            width: widget.isCurrentStep || isBlockedByDebt ? 2 : 1,
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
                  Icon(effectiveStatusIcon, color: effectiveBorderColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                step.stepName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            // Pulsing balance status indicator only on the
                            // "create order" step — for every other step the
                            // customer's debt is irrelevant.
                            if (isCreateOrderStep)
                              BalanceStatusIndicator(
                                inn: tpInn,
                                customerName:
                                    widget.tradingPoint.tradingPoint.name,
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: step.stepRequired
                                    ? theme.colorScheme.errorContainer
                                    : theme.colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                step.stepRequired
                                    ? l10n.mandatory
                                    : l10n.optional,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  l10n.current,
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
              // If it's the current step, show action buttons regardless of previous status (unless it was just reset)
              if (widget.isCurrentStep) ...[
                const SizedBox(height: 16),
                // Action buttons for current active step
                Row(
                  children: [
                    // Previous button (only if not the first step)
                    if (widget.currentStepIndex > 0) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            debugPrint(
                              'VisitStepCard: Previous button pressed for step ${widget.stepProgress.step.stepCode}, currentStepIndex: ${widget.currentStepIndex}',
                            );
                            widget.onPrevious();
                          },
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: Text(l10n.previous),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Skip button (only if optional)
                    if (!step.stepRequired) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showSkipDialog(context),
                          icon: const Icon(Icons.skip_next, size: 18),
                          label: Text(l10n.skipStep),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Complete button removed as per requirements
                    // Steps are completed by navigating into them and finishing the task
                  ],
                ),
              ] else if (status == VisitStepStatus.completed) ...[
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
                        l10n.completed,
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
                    '${l10n.notes}: ${widget.stepProgress.notes}',
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
                        l10n.skipped,
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
                    '${l10n.reason}: ${widget.stepProgress.skipReason}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ] else if (widget.isStrictSequence &&
                  status == VisitStepStatus.pending) ...[
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
                        l10n.previousStepsRequired,
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
        },
      );
  }

  /// Render the [DebtBlockedDialog] from the visit-step tile when the user
  /// taps a debt-blocked "create order" step. The cache entry is fed into a
  /// synthetic [BalanceGateResult] so the dialog gets the same shape it
  /// would receive from a live [OrderBalanceGate.check] — keeping a single
  /// UI surface for the "blocked" message.
  Future<void> _showDebtBlockedFromTile(
    BuildContext context,
    CustomerBalanceStatusCache? cache,
    String inn,
  ) async {
    final entry = cache?.entryFor(inn);
    if (entry == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => DebtBlockedDialog(
        gateResult: BalanceGateResult(
          blocked: true,
          balance: entry.balance,
          limit: entry.limit,
          currency: entry.currency,
          fetchedAt: entry.lastUpdated,
          externalUpdatedAt: null,
          isStale: entry.lastUpdated == null
              ? false
              : DateTime.now().difference(entry.lastUpdated!) >
                  const Duration(hours: 24),
          isOffline: false,
          source: 'cache',
          reason: 'debt_limit_exceeded',
        ),
        customerName: widget.tradingPoint.tradingPoint.name,
      ),
    );
  }

  void _showSkipDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${widget.stepProgress.step.stepName} ${l10n.completed.toLowerCase()}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.confirmCompletion),
            const SizedBox(height: 12),
            TextField(
              controller: _skipReasonController,
              decoration: InputDecoration(
                hintText: l10n.enterNotesOptional,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              widget.onSkip(_skipReasonController.text.trim());
              _skipReasonController.clear();
              Navigator.of(context).pop();
            },
            child: Text(l10n.confirmCompletion),
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
    final l10n = AppLocalizations.of(context)!;

    // Retrieve current state to determine step accessibility
    final currentState =
        context.read<VisitStepsBloc>().state as VisitStepsLoaded;

    // Find the progress status for the target step
    final stepProgress = currentState.stepProgress.firstWhere(
      (progress) => progress.step.stepCode == step.stepCode,
    );

    // Determine step accessibility based on completion and current position
    final isCompleted = stepProgress.status == VisitStepStatus.completed;
    final isCurrentStep =
        currentState.currentStepIndex ==
        currentState.stepProgress.indexOf(stepProgress);

    debugPrint(
      'VisitStepsPage: Navigating to step ${step.stepCode} (${step.stepName})',
    );
    debugPrint(
      'VisitStepsPage: Step status: ${stepProgress.status}, isCompleted: $isCompleted, isCurrentStep: $isCurrentStep',
    );
    debugPrint(
      'VisitStepsPage: Step notes: ${stepProgress.notes}, completedAt: ${stepProgress.completedAt}',
    );

    // Enforce navigation restrictions for non-accessible steps
    if (!isCompleted && !isCurrentStep) {
      debugPrint('VisitStepsPage: Navigation blocked - step not accessible');
      // Display user-friendly error message for blocked navigation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.previousStepsRequired),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Set readOnly mode: completed steps are view-only, current step is editable
    final readOnly = isCompleted;
    debugPrint(
      'VisitStepsPage: Setting readOnly=$readOnly for step ${step.stepCode}',
    );

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
        // Customer Balance Gate (Mobile prompt M9). For an editable visit
        // step we must consult the gate first; if the customer is blocked
        // by the project debt-limit we show a dialog and do not push
        // CreateOrderPage. Read-only navigations (already-completed steps)
        // skip the check — viewing a saved order should not be blocked.
        if (!readOnly) {
          final tp = widget.tradingPoint.tradingPoint;
          final gate = await sl<OrderBalanceGate>().check(tp);
          if (!mounted) return;
          if (gate.blocked) {
            await showDialog<void>(
              context: context,
              builder: (_) => DebtBlockedDialog(
                gateResult: gate,
                customerName: tp.name,
              ),
            );
            return;
          }
        }
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
            actions: readOnly
                ? [
                    const Icon(Icons.visibility, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      l10n.readOnly,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                  ]
                : null,
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
                  l10n.pageUnderDevelopment,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  readOnly
                      ? l10n.stepCompletedReadOnly
                      : l10n.stepTypeNotImplemented,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(l10n.back),
                ),
              ],
            ),
          ),
        );
    }

    if (page != null) {
      // Navigate and wait for result
      // Wrap with BlocProvider.value to share VisitStepsBloc with step pages
      // This allows step pages to access timer state for display
      final bloc = context.read<VisitStepsBloc>();

      // Pause step timer if viewing a read-only (completed) step
      // This prevents timer from running while viewing completed steps
      if (readOnly) {
        bloc.add(PauseStepTimer(step.stepCode));
        debugPrint(
          'VisitStepsPage: Paused step timer for read-only navigation',
        );
      } else {
        // Start step timer when entering an editable (current) step
        // This ensures step timer only counts time spent inside the step page
        bloc.add(StartStepTimer(step.stepCode));
        debugPrint(
          'VisitStepsPage: Started step timer for step ${step.stepCode}',
        );
      }

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (navContext) =>
              BlocProvider.value(value: bloc, child: page!),
        ),
      );

      // Handle timer state after returning from step page
      if (readOnly && currentState.currentStepIndex >= 0) {
        // Resume step timer for the current active step after viewing read-only step
        final activeStep =
            currentState.stepProgress[currentState.currentStepIndex].step;
        bloc.add(ResumeStepTimer(activeStep.stepCode));
        debugPrint(
          'VisitStepsPage: Resumed step timer after read-only navigation',
        );
      } else if (!readOnly) {
        // Pause step timer when returning from editable step (saves timer state)
        bloc.add(PauseStepTimer(step.stepCode));
        debugPrint(
          'VisitStepsPage: Paused step timer after returning from step ${step.stepCode}',
        );
      }

      // Handle the result if step was completed
      if (result != null &&
          result is Map<String, dynamic> &&
          result['completed'] == true) {
        final stepIndex = currentState.stepProgress.indexOf(stepProgress);

        // IMPORTANT: Update timers before completing step to ensure current timer value is captured
        // This triggers UpdateTimers event which updates stepTimers map with current _stepDurationSeconds
        bloc.add(UpdateTimers());

        // Wait a brief moment for UpdateTimers to process and update the state
        await Future.delayed(const Duration(milliseconds: 50));

        // Pass the full result data (including order and shipping date) to completion
        // This ensures that complex step data like order information is preserved in the completion record
        final completionData = Map<String, dynamic>.from(result);
        completionData.remove(
          'completed',
        ); // Remove the completion flag as it's not part of the data to save
        context.read<VisitStepsBloc>().add(
          CompleteStep(stepIndex, completionData),
        );
      }
    }
  }
}
