import '../../domain/repositories/outbox_repository.dart';
import '../local/outbox_data_source.dart';

/// Domain-facing repository. Delegates SQL to [OutboxDataSource] and adds
/// the status-transition policy the dispatcher relies on.
class OutboxRepositoryImpl implements OutboxRepository {
  OutboxRepositoryImpl(this._db);

  final OutboxDataSource _db;

  @override
  Future<void> enqueue(OutboxEntry entry) => _db.insert(entry);

  @override
  Future<OutboxEntry?> peekDue(DateTime now) => _db.peekDue(now);

  @override
  Future<void> markInFlight(String envelopeId, DateTime now) =>
      _db.updateStatus(envelopeId, status: 'in_flight', now: now);

  @override
  Future<void> markAck(String envelopeId) => _db.updateStatus(
        envelopeId,
        status: 'ack',
        now: DateTime.now(),
      );

  @override
  Future<void> markRetrying(
    String envelopeId,
    DateTime nextAttemptAt,
    String? error, {
    bool bumpAttempts = true,
  }) async {
    final now = DateTime.now();
    final existing = await _db.findById(envelopeId);
    final currentAttempts = existing?.attempts ?? 0;
    final nextAttempts = bumpAttempts ? currentAttempts + 1 : currentAttempts;
    await _db.updateStatus(
      envelopeId,
      status: 'retrying',
      nextAttemptAt: nextAttemptAt,
      attempts: nextAttempts,
      lastError: error,
      now: now,
    );
  }

  @override
  Future<void> markDeadLetter(String envelopeId, String error) =>
      _db.updateStatus(
        envelopeId,
        status: 'dead_letter',
        lastError: error,
        now: DateTime.now(),
      );

  @override
  Future<List<OutboxEntry>> findByStatus(String status) =>
      _db.findByStatus(status);

  @override
  Future<void> requeue(String envelopeId, DateTime now) async {
    await _db.updateStatus(
      envelopeId,
      status: 'pending',
      nextAttemptAt: now,
      attempts: 0,
      lastError: null,
      now: now,
    );
  }

  @override
  Future<void> delete(String envelopeId) => _db.delete(envelopeId);

  @override
  Future<Map<String, int>> countByStatus() => _db.countByStatus();
}
