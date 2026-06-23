import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gloria_marketing_flutter/src/core/database/migrations/v7_to_v8.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/outbox/telemetry_outbox_data_source.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/outbox/telemetry_outbox_entry.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/outbox/telemetry_outbox_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late TelemetryOutboxRepository repo;

  TelemetryOutboxEntry entry(String id, {DateTime? created}) {
    final now = created ?? DateTime.now();
    return TelemetryOutboxEntry(
      pingId: id,
      payloadJson: '{"latitude":"41.1","longitude":"69.2"}',
      clientUuid: 'client-uuid',
      idempotencyKey: id,
      status: TelemetryOutboxEntry.statusPending,
      attempts: 0,
      maxAttempts: 12,
      nextAttemptAt: now,
      loggedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await V7ToV8Migration.apply(db);
    repo = TelemetryOutboxRepositoryImpl(TelemetryOutboxDataSource(() async => db));
  });

  tearDown(() async {
    await db.close();
  });

  test('migration creates the telemetry_outbox table', () async {
    final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='telemetry_outbox'");
    expect(rows, hasLength(1));
  });

  test('enqueue + peekDueBatch returns due rows in FIFO order', () async {
    final t0 = DateTime.now().subtract(const Duration(minutes: 2));
    await repo.enqueue(entry('a', created: t0));
    await repo.enqueue(entry('b', created: t0.add(const Duration(seconds: 1))));

    final due = await repo.peekDueBatch(DateTime.now(), 10);
    expect(due.map((e) => e.pingId), ['a', 'b']);
  });

  test('enqueue is idempotent on ping_id (no duplicate, no throw)', () async {
    await repo.enqueue(entry('dup'));
    await repo.enqueue(entry('dup'));
    expect(await repo.count(), 1);
  });

  test('ackAndRemove deletes the acked rows', () async {
    await repo.enqueue(entry('a'));
    await repo.enqueue(entry('b'));
    await repo.ackAndRemove(['a']);
    expect(await repo.count(), 1);
    final due = await repo.peekDueBatch(DateTime.now(), 10);
    expect(due.single.pingId, 'b');
  });

  test('markRetrying bumps attempts and pushes next_attempt_at into the future',
      () async {
    await repo.enqueue(entry('a'));
    final batch = await repo.peekDueBatch(DateTime.now(), 10);
    final future = DateTime.now().add(const Duration(minutes: 5));
    await repo.markRetrying(batch, future, 'http_503');

    // Not due now.
    expect(await repo.peekDueBatch(DateTime.now(), 10), isEmpty);
    // Due once the backoff window passes.
    final later = await repo.peekDueBatch(
        DateTime.now().add(const Duration(minutes: 6)), 10);
    expect(later.single.attempts, 1);
    expect(later.single.lastError, 'http_503');
  });

  test('markDeadLetter removes rows from the due set', () async {
    await repo.enqueue(entry('a'));
    final batch = await repo.peekDueBatch(DateTime.now(), 10);
    await repo.markDeadLetter(batch, 'server_rejected', httpStatus: 422);

    expect(await repo.peekDueBatch(DateTime.now(), 10), isEmpty);
    final counts = await repo.countByStatus();
    expect(counts[TelemetryOutboxEntry.statusDeadLetter], 1);
  });

  test('requeueInFlight recovers rows stuck in_flight after a killed cycle',
      () async {
    await repo.enqueue(entry('a'));
    await repo.markInFlight(['a'], DateTime.now());
    // While in_flight it is NOT due.
    expect(await repo.peekDueBatch(DateTime.now(), 10), isEmpty);

    await repo.requeueInFlight();
    final due = await repo.peekDueBatch(DateTime.now(), 10);
    expect(due.single.pingId, 'a');
  });

  test('pruneToCap drops dead_letter rows before unsent ones', () async {
    final t0 = DateTime.now().subtract(const Duration(hours: 1));
    for (var i = 0; i < 5; i++) {
      await repo.enqueue(entry('p$i', created: t0.add(Duration(seconds: i))));
    }
    // Dead-letter two of them.
    final all = await repo.peekDueBatch(DateTime.now(), 10);
    await repo.markDeadLetter([all[0], all[1]], 'x');

    // Cap to 3: should reclaim the 2 dead_letter rows first → 0 UNSENT dropped.
    final droppedUnsent = await repo.pruneToCap(3);
    expect(droppedUnsent, 0);
    expect(await repo.count(), 3);
  });

  test('pruneToCap reports unsent rows dropped when terminal reclaim is not enough',
      () async {
    final t0 = DateTime.now().subtract(const Duration(hours: 1));
    for (var i = 0; i < 5; i++) {
      await repo.enqueue(entry('p$i', created: t0.add(Duration(seconds: i))));
    }
    // No dead_letter rows → capping to 2 must drop 3 UNSENT (oldest first).
    final droppedUnsent = await repo.pruneToCap(2);
    expect(droppedUnsent, 3);
    expect(await repo.count(), 2);
  });

  test('purgeAll wipes everything (logout hygiene)', () async {
    await repo.enqueue(entry('a'));
    await repo.enqueue(entry('b'));
    await repo.purgeAll();
    expect(await repo.count(), 0);
  });
}
