/// One row in the `outbox` table. Encapsulates everything the dispatcher
/// needs to retry a request without rebuilding it — payload bytes are frozen
/// at enqueue time so the `idempotency_key` keeps its meaning.
class OutboxEntry {
  const OutboxEntry({
    required this.envelopeId,
    required this.visitId,
    required this.endpoint,
    required this.httpMethod,
    required this.payloadJson,
    required this.idempotencyKey,
    required this.clientUuid,
    required this.status,
    required this.attempts,
    required this.maxAttempts,
    required this.nextAttemptAt,
    required this.createdAt,
    required this.updatedAt,
    this.lastError,
    this.lastHttpStatus,
  });

  final String envelopeId;
  final String? visitId;

  /// Path under the v2 base URL (e.g. `'/visits/finish/'`). Dio prepends
  /// the base.
  final String endpoint;

  final String httpMethod;

  /// Frozen request body. Never recomputed on retry.
  final String payloadJson;

  final String idempotencyKey;
  final String clientUuid;

  /// `pending` | `in_flight` | `retrying` | `ack` | `dead_letter`.
  final String status;

  final int attempts;
  final int maxAttempts;
  final DateTime nextAttemptAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastError;
  final int? lastHttpStatus;
}

/// Local outbox queue. Methods are intentionally small so the dispatcher
/// can keep its loop transparent.
abstract class OutboxRepository {
  Future<void> enqueue(OutboxEntry entry);

  /// Returns the oldest entry whose `next_attempt_at <= now` and whose
  /// status is `pending` or `retrying`. `null` when the queue is drained.
  Future<OutboxEntry?> peekDue(DateTime now);

  /// Marks the entry as `in_flight`; the dispatcher calls this before sending
  /// to prevent a parallel cycle from grabbing the same row.
  Future<void> markInFlight(String envelopeId, DateTime now);

  Future<void> markAck(String envelopeId);

  /// Schedules a retry after a transient failure. The dispatcher computes
  /// [nextAttemptAt] via `BackoffScheduler`.
  ///
  /// Set [bumpAttempts] to `false` for "free" retries (auth-refresh) so the
  /// attempt budget is reserved for real transport failures.
  Future<void> markRetrying(
    String envelopeId,
    DateTime nextAttemptAt,
    String? error, {
    bool bumpAttempts = true,
  });

  /// Terminal failure (4xx other than 401/409, or attempts exhausted).
  Future<void> markDeadLetter(String envelopeId, String error);

  /// Dead-letter UI surface.
  Future<List<OutboxEntry>> findByStatus(String status);

  /// Manual retry from the UI moves a `dead_letter` row back to `pending`.
  Future<void> requeue(String envelopeId, DateTime now);

  /// Lets the user remove a row from dead-letter when they don't want to
  /// retry (e.g. customer abandoned).
  Future<void> delete(String envelopeId);

  /// Live counts for the status badge / Settings page.
  Future<Map<String, int>> countByStatus();
}
