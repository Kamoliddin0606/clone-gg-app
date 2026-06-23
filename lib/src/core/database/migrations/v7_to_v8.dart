import 'package:sqflite/sqflite.dart';

/// Core DB — sqflite schema upgrade from v7 to v8.
///
/// Adds a single durable outbox table for the background **telemetry / location
/// ping** pipeline (`POST /api/mobile/v1/telemetry/pings/`). It mirrors the
/// shape of the visits `outbox` table (see
/// `lib/src/features/visits/data/local/migrations/v6_to_v7.dart`) so the same
/// durability guarantees — frozen payload, idempotency key, backoff metadata,
/// status state-machine — apply to high-volume location data.
///
/// Why a separate table from the visits `outbox`:
///   * Independent retention/eviction policy (telemetry is high-volume,
///     low-value-per-row; visits are low-volume, high-value).
///   * Batch send semantics (`{"pings": [...]}`) vs the visits one-row-per-POST.
///   * Decouples the two pipelines so a schema change to one never risks the
///     other.
///
/// `CREATE TABLE IF NOT EXISTS` is used because the upgrade may run on a
/// fresh asset-seeded DB whose `_onCreate` path was skipped.
class V7ToV8Migration {
  const V7ToV8Migration._();

  /// Applies the v8 schema. Safe to call inside `onUpgrade` and `onCreate`.
  static Future<void> apply(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS telemetry_outbox (
        ping_id          TEXT PRIMARY KEY,
        payload_json     TEXT NOT NULL,
        client_uuid      TEXT NOT NULL,
        idempotency_key  TEXT NOT NULL UNIQUE,
        status           TEXT NOT NULL,
        attempts         INTEGER NOT NULL DEFAULT 0,
        max_attempts     INTEGER NOT NULL DEFAULT 12,
        next_attempt_at  INTEGER NOT NULL,
        last_error       TEXT,
        last_http_status INTEGER,
        logged_at        INTEGER NOT NULL,
        created_at       INTEGER NOT NULL,
        updated_at       INTEGER NOT NULL
      )
    ''');
    // Drain order + retention sweeps both hit these.
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_telemetry_outbox_due ON telemetry_outbox(status, next_attempt_at)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_telemetry_outbox_created ON telemetry_outbox(created_at)');
  }
}
