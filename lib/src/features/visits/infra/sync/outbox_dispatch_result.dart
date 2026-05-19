/// Classification used by [OutboxDispatcher] to decide whether to ACK,
/// retry, or dead-letter an entry. Produced from the Dio response (or the
/// `Failure` the error mapper attached) without leaking either type into
/// the dispatch loop.
sealed class DispatchOutcome {
  const DispatchOutcome();
}

class DispatchSuccess extends DispatchOutcome {
  const DispatchSuccess({
    required this.httpStatus,
    this.idempotentReplay = false,
  });

  final int httpStatus;

  /// `true` when the backend echoed `Idempotent-Replay: true` (changelog
  /// § 6). Mobile uses it to attribute the round-trip to a retry rather
  /// than a fresh submission in telemetry — fresh 201s and replays
  /// otherwise look identical to the dispatcher.
  final bool idempotentReplay;
}

/// 409 — server already accepted (idempotent replay or visit-level conflict).
/// We treat both as success because the data is on the server.
class DispatchAlreadyAccepted extends DispatchOutcome {
  const DispatchAlreadyAccepted();
}

/// 401 — token refresh required. Attempt counter doesn't increment.
class DispatchAuthExpired extends DispatchOutcome {
  const DispatchAuthExpired();
}

/// Transient: 5xx, 429, timeout, network drop. Reschedule with backoff.
class DispatchTransient extends DispatchOutcome {
  const DispatchTransient({required this.error, this.httpStatus});
  final String error;
  final int? httpStatus;
}

/// Terminal: 400/422 validation, business rule violation. Dead-letter.
class DispatchTerminal extends DispatchOutcome {
  const DispatchTerminal({required this.error, this.httpStatus, this.code});
  final String error;
  final int? httpStatus;
  final String? code;
}
