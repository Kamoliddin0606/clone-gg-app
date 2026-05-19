import '../entities/visit_session.dart';

/// Local-first store for [VisitSession] aggregates. The data layer
/// implementation persists to `visits_v2` and `visit_tasks_v2`.
///
/// All writes are local — server-side persistence is the outbox dispatcher's
/// job (it serialises a [VisitSession] into a `VisitEnvelope` and POSTs it).
abstract class VisitRepository {
  /// Inserts or replaces the session. Used both when the user starts a new
  /// visit and when the BLoC mutates tasks mid-session.
  Future<void> upsert(VisitSession session);

  /// Loads the session by id, or `null` if it isn't on disk.
  Future<VisitSession?> findById(String visitId);

  /// Returns sessions in [statuses] (typically `[inProgress]` at app start
  /// for crash recovery, or `[finishedLocal]` to surface unflushed work).
  Future<List<VisitSession>> findByStatus(List<String> statuses);

  /// Flips local status to `synced` once the outbox confirms a 2xx ACK.
  Future<void> markSynced(String visitId);

  /// Soft delete (status=`cancelled`). The row sticks around for audit.
  Future<void> markCancelled(String visitId);

  /// Hard delete a synced session and its tasks once they're stale (>30
  /// days) — keeps the local DB small. Cancelled / rejected rows are kept.
  Future<int> purgeSyncedOlderThan(Duration age);
}
