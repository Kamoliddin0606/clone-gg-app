import '../../domain/entities/local_visit_status.dart';
import '../../domain/entities/visit_session.dart';
import '../../domain/repositories/visit_repository.dart';
import '../local/visit_local_data_source.dart';

class VisitRepositoryImpl implements VisitRepository {
  VisitRepositoryImpl(this._db);

  final VisitLocalDataSource _db;

  @override
  Future<void> upsert(VisitSession session) => _db.upsert(session);

  @override
  Future<VisitSession?> findById(String visitId) => _db.findById(visitId);

  @override
  Future<List<VisitSession>> findByStatus(List<String> statuses) =>
      _db.findByStatus(statuses);

  @override
  Future<void> markSynced(String visitId) =>
      _db.updateStatus(visitId, LocalVisitStatus.synced);

  @override
  Future<void> markCancelled(String visitId) =>
      _db.updateStatus(visitId, LocalVisitStatus.cancelled);

  @override
  Future<int> purgeSyncedOlderThan(Duration age) =>
      _db.purgeSyncedOlderThan(age);
}
