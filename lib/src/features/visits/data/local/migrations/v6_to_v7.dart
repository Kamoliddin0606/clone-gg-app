import 'package:sqflite/sqflite.dart';

/// Visits v2 — sqflite schema upgrade from v6 to v7.
///
/// Adds six tables that power the REST v2 visit pipeline:
///   * `outbox`            — durable envelope queue with backoff metadata.
///   * `photo_uploads`     — per-photo capture record + S3-bound upload state.
///   * `visits_v2`         — local visit aggregate (offline buffer + recovery).
///   * `visit_tasks_v2`    — per-task payload + timing.
///   * `permissions_cache` — ETag-keyed user permissions snapshot.
///   * `catalog_cache`     — ETag-keyed task catalog (JSON Schema bundle).
///
/// Existing tables (`visit_steps_data`, `create_order`,
/// `create_order_products`, etc.) are left untouched so the legacy SOAP path
/// keeps working under the feature flag. Phase 4 of the rollout deprecates
/// them; Phase 6 removes them in a later migration.
class V6ToV7Migration {
  const V6ToV7Migration._();

  /// Applies the v7 schema. Safe to call inside `onUpgrade`.
  ///
  /// All `CREATE TABLE` statements use `IF NOT EXISTS` because the upgrade
  /// may run on a fresh asset-seeded DB whose `_onCreate` path was skipped.
  static Future<void> apply(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS outbox (
        envelope_id      TEXT PRIMARY KEY,
        visit_id         TEXT,
        endpoint         TEXT NOT NULL,
        http_method      TEXT NOT NULL,
        payload_json     TEXT NOT NULL,
        idempotency_key  TEXT NOT NULL UNIQUE,
        client_uuid      TEXT NOT NULL,
        status           TEXT NOT NULL,
        attempts         INTEGER NOT NULL DEFAULT 0,
        max_attempts     INTEGER NOT NULL DEFAULT 10,
        next_attempt_at  INTEGER NOT NULL,
        last_error       TEXT,
        last_http_status INTEGER,
        created_at       INTEGER NOT NULL,
        updated_at       INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_outbox_due ON outbox(status, next_attempt_at)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_outbox_visit ON outbox(visit_id)');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS photo_uploads (
        asset_id         TEXT PRIMARY KEY,
        visit_id         TEXT NOT NULL,
        task_id          TEXT,
        task_code        TEXT NOT NULL,
        local_path       TEXT NOT NULL,
        thumbnail_path   TEXT,
        sha256           TEXT NOT NULL,
        size_bytes       INTEGER NOT NULL,
        width            INTEGER,
        height           INTEGER,
        captured_at      INTEGER NOT NULL,
        lat              REAL,
        lng              REAL,
        accuracy_m       REAL,
        status           TEXT NOT NULL,
        remote_asset_id  TEXT,
        attempts         INTEGER NOT NULL DEFAULT 0,
        last_error       TEXT,
        idempotency_key  TEXT NOT NULL UNIQUE,
        created_at       INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_photos_visit ON photo_uploads(visit_id, status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_photos_status ON photo_uploads(status)');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS visits_v2 (
        visit_id             TEXT PRIMARY KEY,
        customer_id          TEXT NOT NULL,
        planned_flag         INTEGER NOT NULL,
        status               TEXT NOT NULL,
        started_at           INTEGER NOT NULL,
        finished_at          INTEGER,
        envelope_id          TEXT,
        app_version          TEXT,
        start_location_json  TEXT,
        finish_location_json TEXT,
        device_info_json     TEXT,
        network_flags_json   TEXT,
        created_at           INTEGER NOT NULL,
        updated_at           INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_visits_v2_status ON visits_v2(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_visits_v2_customer ON visits_v2(customer_id, started_at DESC)');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS visit_tasks_v2 (
        task_id                TEXT PRIMARY KEY,
        visit_id               TEXT NOT NULL,
        task_code              TEXT NOT NULL,
        display_order          INTEGER NOT NULL,
        started_at             INTEGER,
        ended_at               INTEGER,
        duration_ms            INTEGER,
        status                 TEXT NOT NULL,
        payload_json           TEXT NOT NULL,
        payload_schema_version INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY(visit_id) REFERENCES visits_v2(visit_id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_visit_tasks_v2_visit ON visit_tasks_v2(visit_id, display_order)');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS permissions_cache (
        user_code     TEXT NOT NULL,
        project_code  TEXT NOT NULL,
        etag          TEXT NOT NULL,
        json          TEXT NOT NULL,
        fetched_at    INTEGER NOT NULL,
        PRIMARY KEY (user_code, project_code)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS catalog_cache (
        project_code  TEXT PRIMARY KEY,
        etag          TEXT NOT NULL,
        json          TEXT NOT NULL,
        fetched_at    INTEGER NOT NULL
      )
    ''');
  }
}
