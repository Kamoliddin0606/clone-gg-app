import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/outbox_repository.dart';
import '../../../infra/sync/outbox_dispatcher.dart';

/// Lightweight cubit that surfaces outbox queue health: pending /
/// retrying / dead-letter counts plus the latest dispatcher event.
///
/// Pushed to the AppBar badge and the Settings → Sync screen.
class OutboxStatusCubit extends Cubit<OutboxStatusState> {
  OutboxStatusCubit({
    required OutboxRepository outbox,
    required OutboxDispatcher dispatcher,
  })  : _outbox = outbox,
        _dispatcher = dispatcher,
        super(const OutboxStatusState.initial()) {
    _sub = _dispatcher.statusStream.listen((_) => refresh());
  }

  final OutboxRepository _outbox;
  final OutboxDispatcher _dispatcher;
  StreamSubscription<OutboxStatus>? _sub;

  Future<void> refresh() async {
    final counts = await _outbox.countByStatus();
    emit(OutboxStatusState(
      pending: counts['pending'] ?? 0,
      retrying: counts['retrying'] ?? 0,
      inFlight: counts['in_flight'] ?? 0,
      ack: counts['ack'] ?? 0,
      deadLetter: counts['dead_letter'] ?? 0,
    ));
  }

  Future<void> retryAllDeadLetter() async {
    final rows = await _outbox.findByStatus('dead_letter');
    final now = DateTime.now();
    for (final r in rows) {
      await _outbox.requeue(r.envelopeId, now);
    }
    // ignore: unawaited_futures
    _dispatcher.cycle();
    await refresh();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

class OutboxStatusState extends Equatable {
  const OutboxStatusState({
    required this.pending,
    required this.retrying,
    required this.inFlight,
    required this.ack,
    required this.deadLetter,
  });

  const OutboxStatusState.initial()
      : pending = 0,
        retrying = 0,
        inFlight = 0,
        ack = 0,
        deadLetter = 0;

  final int pending;
  final int retrying;
  final int inFlight;
  final int ack;
  final int deadLetter;

  int get unflushed => pending + retrying + inFlight;
  bool get hasDeadLetter => deadLetter > 0;

  @override
  List<Object?> get props => [pending, retrying, inFlight, ack, deadLetter];
}
