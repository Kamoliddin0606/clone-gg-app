import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/visits/data/local/migrations/v6_to_v7.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('V6ToV7Migration', () {
    test('creates all six tables idempotently', () async {
      final db = await openDatabase(inMemoryDatabasePath);

      await V6ToV7Migration.apply(db);
      // Re-applying must not crash — the migration is `IF NOT EXISTS` so a
      // fresh install followed by an upgrade re-run won't double-create.
      await V6ToV7Migration.apply(db);

      final tables = (await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      ))
          .map((row) => row['name'] as String)
          .toSet();

      for (final expected in const [
        'outbox',
        'photo_uploads',
        'visits_v2',
        'visit_tasks_v2',
        'permissions_cache',
        'catalog_cache',
      ]) {
        expect(tables.contains(expected), isTrue,
            reason: 'missing table $expected');
      }

      await db.close();
    });

    test('outbox enforces unique idempotency_key', () async {
      final db = await openDatabase(inMemoryDatabasePath);
      await V6ToV7Migration.apply(db);

      final row = {
        'envelope_id': 'env-1',
        'endpoint': '/visits/finish/',
        'http_method': 'POST',
        'payload_json': '{}',
        'idempotency_key': 'idem-1',
        'client_uuid': 'cli-1',
        'status': 'pending',
        'next_attempt_at': 0,
        'created_at': 0,
        'updated_at': 0,
      };
      await db.insert('outbox', row);

      expect(
        () => db.insert('outbox', {...row, 'envelope_id': 'env-2'}),
        throwsA(isA<DatabaseException>()),
      );

      await db.close();
    });
  });
}
