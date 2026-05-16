import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import '../network/server_service.dart';
import 'connectivity_monitor_service.dart';
import 'shared_preferences_service.dart';

/// Outcome of an attempted mode transition.
enum NetworkModeOutcome {
  /// Already in the requested mode — no action taken.
  alreadyInTargetMode,

  /// Mode flag flipped successfully.
  switched,

  /// User cancelled the prompt.
  declined,

  /// Device has no network connectivity.
  noInternet,

  /// Device has connectivity but the configured server did not respond.
  serverUnreachable,
}

/// Central gate that arbitrates between the persisted offline-mode flag
/// (`SharedPreferencesService.isOfflineMode`) and the live device
/// connectivity reported by [ConnectivityMonitorService].
///
/// The single source of truth for "am I offline?" remains the persisted
/// flag — the gate never flips it automatically. Each transition is
/// surfaced as a confirmation prompt so the user retains control.
///
/// Use [probeOnline] for a non-interactive reachability check (e.g. from
/// AppStartGuard) and [tryGoOnline] / [tryGoOffline] from UI handlers
/// that should prompt the user.
class NetworkModeGate {
  NetworkModeGate({
    required SharedPreferencesService prefs,
    required ConnectivityMonitorService connectivity,
    required ServerService serverService,
    Dio? dio,
  })  : _prefs = prefs,
        _connectivity = connectivity,
        _serverService = serverService,
        _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ));

  final SharedPreferencesService _prefs;
  final ConnectivityMonitorService _connectivity;
  final ServerService _serverService;
  final Dio _dio;

  /// True if the persisted user-facing mode flag is "offline".
  bool get isOfflineMode => _prefs.isOfflineMode();

  /// Verifies live reachability: device connectivity AND the configured
  /// server responding to a lightweight request. Any HTTP status counts
  /// as "reachable" — only transport-level failures fail the probe.
  ///
  /// Returns one of: [NetworkModeOutcome.noInternet],
  /// [NetworkModeOutcome.serverUnreachable], or
  /// [NetworkModeOutcome.switched] (used here as "reachable").
  Future<NetworkModeOutcome> probeOnline() async {
    final hasInternet = await _connectivity.hasConnection();
    if (!hasInternet) {
      return NetworkModeOutcome.noInternet;
    }

    final baseUrl = _serverService.baseUrl;
    if (baseUrl.isEmpty) {
      return NetworkModeOutcome.serverUnreachable;
    }

    try {
      await _dio.get<dynamic>(
        baseUrl,
        options: Options(
          validateStatus: (_) => true,
        ),
      );
      // Server replied (any status) → device truly is online. Push the
      // result into the monitor so UI listeners hide the offline badge
      // immediately, even if the platform connectivity event hasn't
      // fired yet (e.g. cold-start race or stale cached status).
      _connectivity.markConnected();
      return NetworkModeOutcome.switched;
    } on DioException {
      return NetworkModeOutcome.serverUnreachable;
    } catch (_) {
      return NetworkModeOutcome.serverUnreachable;
    }
  }

  /// Attempt to transition into online mode.
  ///
  /// If [promptIfNeeded] is true and the user has to confirm, a dialog
  /// is shown using [context]. The dialog is skipped if the flag is
  /// already `false` or if connectivity is missing (in which case the
  /// failure is reported without bothering the user).
  ///
  /// Side-effects on success: persists `isOfflineMode = false`.
  Future<NetworkModeOutcome> tryGoOnline(
    BuildContext context, {
    bool promptIfNeeded = true,
  }) async {
    if (!_prefs.isOfflineMode()) {
      return NetworkModeOutcome.alreadyInTargetMode;
    }

    final probe = await probeOnline();
    if (probe != NetworkModeOutcome.switched) {
      return probe;
    }

    if (promptIfNeeded) {
      if (!context.mounted) return NetworkModeOutcome.declined;
      final confirmed = await _confirmDialog(
        context,
        title: AppLocalizations.of(context)!.onlineModeReturn,
        body: AppLocalizations.of(context)!.onlineModeReturnConfirm,
      );
      if (confirmed != true) {
        return NetworkModeOutcome.declined;
      }
    }

    await _prefs.setOfflineMode(false);
    return NetworkModeOutcome.switched;
  }

  /// Attempt to transition into offline mode after the user confirms.
  ///
  /// No reachability probe is performed — offline is always available.
  /// Side-effects on success: persists `isOfflineMode = true`.
  Future<NetworkModeOutcome> tryGoOffline(
    BuildContext context, {
    bool promptIfNeeded = true,
  }) async {
    if (_prefs.isOfflineMode()) {
      return NetworkModeOutcome.alreadyInTargetMode;
    }

    if (promptIfNeeded) {
      if (!context.mounted) return NetworkModeOutcome.declined;
      final confirmed = await _confirmDialog(
        context,
        title: AppLocalizations.of(context)!.switchToOfflineTitle,
        body: AppLocalizations.of(context)!.switchToOfflineBody,
      );
      if (confirmed != true) {
        return NetworkModeOutcome.declined;
      }
    }

    await _prefs.setOfflineMode(true);
    return NetworkModeOutcome.switched;
  }

  Future<bool?> _confirmDialog(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
  }
}
