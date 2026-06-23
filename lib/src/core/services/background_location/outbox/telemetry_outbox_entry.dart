/// One row in the `telemetry_outbox` table. Encapsulates everything the
/// dispatcher needs to retry a location/telemetry ping without rebuilding it —
/// the payload bytes are frozen at enqueue time so the `idempotencyKey` keeps
/// its meaning across retries (the server dedups replays on it).
///
/// Mirrors the visits `OutboxEntry`
/// (`lib/src/features/visits/domain/repositories/outbox_repository.dart`) but
/// drops visit-specific fields and the per-row endpoint (telemetry always
/// targets the single batch pings endpoint).
class TelemetryOutboxEntry {
  const TelemetryOutboxEntry({
    required this.pingId,
    required this.payloadJson,
    required this.clientUuid,
    required this.idempotencyKey,
    required this.status,
    required this.attempts,
    required this.maxAttempts,
    required this.nextAttemptAt,
    required this.loggedAt,
    required this.createdAt,
    required this.updatedAt,
    this.lastError,
    this.lastHttpStatus,
  });

  /// Stable client-generated id (UUID v4). Primary key.
  final String pingId;

  /// Frozen `TelemetryPingRequest.toJson()` for a single ping. Never recomputed
  /// on retry.
  final String payloadJson;

  /// Device-stable local UUID (see `LocalUuidService`). Lets the backend group
  /// pings by device even before registration completes.
  final String clientUuid;

  /// Per-ping idempotency token (== [pingId]). Sent inside the payload so the
  /// server can dedup replays after an ambiguous (timed-out) batch.
  final String idempotencyKey;

  /// `pending` | `in_flight` | `retrying` | `ack` | `dead_letter`.
  final String status;

  final int attempts;
  final int maxAttempts;
  final DateTime nextAttemptAt;

  /// Capture time of the ping (NOT send time). Preserved across the queue
  /// round-trip so the server timeline stays accurate.
  final DateTime loggedAt;

  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastError;
  final int? lastHttpStatus;

  // Status constants — kept here so the data source, repository and dispatcher
  // never drift on a literal typo.
  static const String statusPending = 'pending';
  static const String statusInFlight = 'in_flight';
  static const String statusRetrying = 'retrying';
  static const String statusAck = 'ack';
  static const String statusDeadLetter = 'dead_letter';
}
