import 'telemetry_outbox_data_source.dart';
import 'telemetry_outbox_entry.dart';

/// Local durable queue for telemetry pings. Methods are intentionally small so
/// the dispatcher loop stays transparent. Mirrors the visits `OutboxRepository`
/// contract, adapted for batch send semantics.
abstract class TelemetryOutboxRepository {
  /// Idempotent on `ping_id` — a double enqueue is a no-op.
  Future<void> enqueue(TelemetryOutboxEntry entry);

  /// Oldest [limit] due entries (`pending`/`retrying`, `next_attempt_at <= now`).
  Future<List<TelemetryOutboxEntry>> peekDueBatch(DateTime now, int limit);

  /// Reserve a batch so a parallel cycle can't grab the same rows.
  Future<void> markInFlight(List<String> pingIds, DateTime now);

  /// Server accepted these pings — drop them (no value in keeping `ack` rows).
  Future<void> ackAndRemove(List<String> pingIds);

  /// Transient failure for the whole batch — reschedule each row with backoff.
  /// Pass [bumpAttempts] = false for "free" retries (e.g. token refresh) so the
  /// attempt budget is reserved for real transport failures.
  Future<void> markRetrying(
    List<TelemetryOutboxEntry> entries,
    DateTime nextAttemptAt,
    String? error, {
    bool bumpAttempts = true,
  });

  /// Terminal failure (server validation reject, or attempts exhausted).
  Future<void> markDeadLetter(
    List<TelemetryOutboxEntry> entries,
    String error, {
    int? httpStatus,
  });

  /// Live counts for the diagnostics surface (pending/in_flight/retrying/
  /// dead_letter).
  Future<Map<String, int>> countByStatus();

  /// Total row count.
  Future<int> count();

  /// Retention sweep down to [maxRows]; returns the number of UNSENT rows
  /// dropped (for the loss metric).
  Future<int> pruneToCap(int maxRows);

  /// Recover rows stuck `in_flight` after a killed cycle (idempotency makes
  /// the re-send safe). Call at the start of a dispatch cycle.
  Future<void> requeueInFlight();

  /// Wipe everything (logout hygiene).
  Future<void> purgeAll();
}

class TelemetryOutboxRepositoryImpl implements TelemetryOutboxRepository {
  TelemetryOutboxRepositoryImpl(this._db);

  final TelemetryOutboxDataSource _db;

  @override
  Future<void> enqueue(TelemetryOutboxEntry entry) => _db.insert(entry);

  @override
  Future<List<TelemetryOutboxEntry>> peekDueBatch(DateTime now, int limit) =>
      _db.peekDueBatch(now, limit);

  @override
  Future<void> markInFlight(List<String> pingIds, DateTime now) =>
      _db.markInFlightMany(pingIds, now);

  @override
  Future<void> ackAndRemove(List<String> pingIds) => _db.deleteMany(pingIds);

  @override
  Future<void> markRetrying(
    List<TelemetryOutboxEntry> entries,
    DateTime nextAttemptAt,
    String? error, {
    bool bumpAttempts = true,
  }) async {
    final now = DateTime.now();
    for (final e in entries) {
      await _db.updateStatus(
        e.pingId,
        status: TelemetryOutboxEntry.statusRetrying,
        nextAttemptAt: nextAttemptAt,
        attempts: bumpAttempts ? e.attempts + 1 : e.attempts,
        lastError: error,
        now: now,
      );
    }
  }

  @override
  Future<void> markDeadLetter(
    List<TelemetryOutboxEntry> entries,
    String error, {
    int? httpStatus,
  }) async {
    final now = DateTime.now();
    for (final e in entries) {
      await _db.updateStatus(
        e.pingId,
        status: TelemetryOutboxEntry.statusDeadLetter,
        lastError: error,
        lastHttpStatus: httpStatus,
        now: now,
      );
    }
  }

  @override
  Future<Map<String, int>> countByStatus() => _db.countByStatus();

  @override
  Future<int> count() => _db.count();

  @override
  Future<int> pruneToCap(int maxRows) => _db.pruneToCap(maxRows);

  @override
  Future<void> requeueInFlight() => _db.requeueInFlight(DateTime.now());

  @override
  Future<void> purgeAll() => _db.purgeAll();
}
