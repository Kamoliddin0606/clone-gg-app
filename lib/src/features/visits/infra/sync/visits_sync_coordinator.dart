import 'dart:async';

import 'package:flutter/widgets.dart';

import '../photo/photo_upload_service.dart';
import 'connectivity_listener.dart';
import 'outbox_dispatcher.dart';

/// Foreground-side glue that makes the outbox feel "live":
///   * Cycles on app foreground.
///   * Cycles when connectivity flips to online.
///   * Periodically (every 60s) re-checks while foregrounded.
///
/// Background firing (Workmanager / BGTaskScheduler) is delegated to
/// [VisitsBackgroundSync] — keeping the two split lets the foreground loop
/// stay dependency-free of platform plugins.
class VisitsSyncCoordinator with WidgetsBindingObserver {
  VisitsSyncCoordinator({
    required OutboxDispatcher dispatcher,
    required PhotoUploadService photoUploader,
    required ConnectivityListener connectivity,
    Duration periodic = const Duration(seconds: 60),
  })  : _dispatcher = dispatcher,
        _photoUploader = photoUploader,
        _connectivity = connectivity,
        _period = periodic;

  final OutboxDispatcher _dispatcher;
  final PhotoUploadService _photoUploader;
  final ConnectivityListener _connectivity;
  final Duration _period;

  StreamSubscription<bool>? _connSub;
  Timer? _timer;
  bool _started = false;

  /// Wire the observer + start the connectivity listener + tick once.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);

    _connSub = _connectivity.watch().listen((online) {
      if (online) _runOnce();
    });
    _timer = Timer.periodic(_period, (_) => _runOnce());

    await _runOnce();
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    await _connSub?.cancel();
    _connSub = null;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _runOnce();
  }

  Future<void> _runOnce() async {
    try {
      await _photoUploader.cycle();
      await _dispatcher.cycle();
    } catch (_) {
      // Swallow — both cycles are designed to be retriable. UI surfaces
      // failures through OutboxStatusCubit.
    }
  }
}
