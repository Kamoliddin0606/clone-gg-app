import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../services/shared_preferences_service.dart';
import 'permission_codenames.dart';

/// Outcome of the most recent [BackendPermissionStore] sync attempt —
/// surfaced to UI so the "Backend ruxsatlari" sync card in the
/// settings tab can render a meaningful status line.
enum BackendPermissionSyncStatus { idle, ok, failed }

/// Immutable snapshot of the store's observable state. Held by a
/// [ChangeNotifier] so widgets can rebuild on `replaceFromLogin` /
/// `clear` without polling.
@immutable
class BackendPermissionSyncEvent {
  final BackendPermissionSyncStatus status;
  final DateTime? timestamp;

  /// Human-readable detail line (count summary on success, error code
  /// on failure). UI renders this verbatim; never localised at this
  /// layer.
  final String? detail;

  const BackendPermissionSyncEvent({
    this.status = BackendPermissionSyncStatus.idle,
    this.timestamp,
    this.detail,
  });
}

/// Persists backend-sourced codenames separately from the SOAP
/// settings store. Survives app restarts. Replaced wholesale on every
/// successful login / refresh.
///
/// The SOAP settings pipeline keeps shipping its typed booleans
/// (`editClientCoordinates`, `visit`, etc.) into the legacy
/// `sales_req_permissions` row — those stay untouched. The codenames
/// in [PermissionCodenames.owned] are the new backend-served signal
/// and live here exclusively; the SOAP write boundary must never
/// persist any of those strings (the runbook calls this the "whitelist
/// filter"; assertion sits in
/// `test/features/settings/soap_store_filter_test.dart`).
///
/// **Read path is synchronous** — UI build methods can call [has]
/// directly. The in-memory cache is hydrated lazily on the first
/// access from the shared `SharedPreferences` payload [TokenService]
/// also uses, so cold-start renders return the same answer as a
/// freshly-logged-in session.
///
/// **Observable**: extends [ChangeNotifier] so UI can listen for the
/// "Backend ruxsatlari" sync card and the permissions tab to redraw
/// on login / refresh without manual setState pumps.
class BackendPermissionStore extends ChangeNotifier {
  /// SharedPreferences key. Versioned so a future schema change can
  /// invalidate the cache by bumping the suffix.
  static const String _prefsKey = 'backend_permissions_v1';

  /// Companion keys for the sync metadata. Kept separately so
  /// migrating the codename payload format (e.g. v2 list shape) does
  /// not require touching the metadata schema.
  static const String _prefsMetaTimestampKey = 'backend_permissions_v1_ts';
  static const String _prefsMetaStatusKey = 'backend_permissions_v1_status';
  static const String _prefsMetaDetailKey = 'backend_permissions_v1_detail';

  /// Sticky flag that flips `true` the first time the backend ships
  /// an explicit `gates.permissions` field (even an empty array).
  /// Used by [has] / [hasAny] to switch from optimistic-empty to
  /// pessimistic-empty after the rollout completes.
  static const String _prefsMetaProvidedKey =
      'backend_permissions_v1_provided';

  /// Defensive: while backend rollout is in progress, treat an empty
  /// stored list as "all granted" (optimistic). Flip to `false` once
  /// staging confirms `gates.permissions` is populated for every
  /// login. Document the flip in the PR description.
  static const bool _optimistic = true;

  /// Frozen list of codenames this store owns. The SOAP settings
  /// writer reads this set and skips any matching key on every write
  /// so the two stores never collide. Source of truth lives in
  /// [PermissionCodenames.owned]; mirrored here for ergonomic access.
  static const Set<String> ownedCodenames = PermissionCodenames.owned;

  final SharedPreferencesService _prefs;

  /// `null` until [_readAll] reads the persisted list at least once.
  /// After that, holds the current granted set in memory so build-
  /// time reads never block on disk I/O.
  Set<String>? _cache;

  /// In-memory cache of the latest sync event. Hydrated lazily from
  /// SharedPreferences via [_readEvent].
  BackendPermissionSyncEvent? _eventCache;

  /// In-memory mirror of the "backend explicitly shipped the
  /// permissions field" flag. Hydrated lazily on first read.
  bool? _providedCache;

  BackendPermissionStore({required SharedPreferencesService prefs})
      : _prefs = prefs;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Whether the optimistic-empty fallback is active. Exposed for UI
  /// so the permissions tab can disclose "rollout window" semantics
  /// to the user (the badge "Optimistic" instead of "0 / N").
  bool get isOptimistic => _optimistic;

  /// Overwrite the stored set with [permissions]. Idempotent — repeat
  /// calls with the same list are a no-op disk-wise (still emits a
  /// debug log + a fresh sync event so the UI redraws).
  ///
  /// [provided] indicates whether the backend explicitly returned
  /// the `gates.permissions` field (even as an empty array). When
  /// `true`, the empty case means "user has no codenames"
  /// (pessimistic). When `false`, the server is in a rollout window
  /// and the optimistic-empty fallback applies. The flag is sticky
  /// across calls — once `provided=true` lands, mobile no longer
  /// falls back to optimistic even if a later refresh somehow lacks
  /// the field.
  ///
  /// Codenames not in [ownedCodenames] are dropped silently: the
  /// backend ships a flat list including unrelated namespaces (
  /// `users.*`, `inventory.*`, ...); we only persist what this store
  /// is responsible for.
  Future<void> replaceFromLogin(
    List<String> permissions, {
    bool provided = true,
  }) async {
    final filtered = permissions
        .where((c) => ownedCodenames.contains(c))
        .toSet();
    _cache = filtered;
    await _prefs.preferences.setString(
      _prefsKey,
      jsonEncode(filtered.toList()..sort()),
    );
    if (provided) {
      _providedCache = true;
      await _prefs.preferences.setBool(_prefsMetaProvidedKey, true);
    }
    await _recordEvent(
      status: BackendPermissionSyncStatus.ok,
      detail: '${filtered.length}/${ownedCodenames.length}',
    );
    if (kDebugMode) {
      debugPrint(
        '[PERMISSIONS] 💾 replaceFromLogin → ${filtered.length} '
        'owned codename(s) (provided=$provided): '
        '${filtered.toList()..sort()}',
      );
    }
    notifyListeners();
  }

  /// Persist a sync failure (e.g. the token endpoint returned 200 but
  /// the `gates.permissions` field could not be parsed). Keeps the
  /// last-known granted set intact — UX rule: a failed refresh must
  /// never silently revoke permissions.
  Future<void> recordFailure(String code) async {
    await _recordEvent(
      status: BackendPermissionSyncStatus.failed,
      detail: code,
    );
    if (kDebugMode) {
      debugPrint('[PERMISSIONS] ⚠️  recordFailure → $code');
    }
    notifyListeners();
  }

  /// Clear every stored codename + metadata. Called on logout — pair
  /// with [TokenService.clearV2Tokens] + `clearCachedGates` for cache
  /// coherence (never leave one populated when the others are gone).
  Future<void> clear() async {
    _cache = <String>{};
    _eventCache = const BackendPermissionSyncEvent();
    _providedCache = false;
    await _prefs.preferences.remove(_prefsKey);
    await _prefs.preferences.remove(_prefsMetaTimestampKey);
    await _prefs.preferences.remove(_prefsMetaStatusKey);
    await _prefs.preferences.remove(_prefsMetaDetailKey);
    await _prefs.preferences.remove(_prefsMetaProvidedKey);
    if (kDebugMode) {
      debugPrint('[PERMISSIONS] 🗑️  clear → store emptied');
    }
    notifyListeners();
  }

  /// Synchronous check used from build methods. Always returns a
  /// stable answer for the lifetime of a single frame.
  ///
  /// Empty-store semantics:
  /// - Backend has explicitly shipped `gates.permissions` at least
  ///   once (`_readProvided() == true`) → empty means "no codenames
  ///   granted" → returns `false`.
  /// - Backend has never shipped the field (rollout window) AND the
  ///   class-level [_optimistic] flag is on → returns `true` so
  ///   existing roles do not regress while the server side is
  ///   catching up.
  bool has(String codename) {
    final stored = _readAll();
    if (stored.isEmpty) {
      if (_readProvided()) return false;
      if (_optimistic) return true;
    }
    return stored.contains(codename);
  }

  /// True when at least one of [codenames] is granted. Same
  /// optimistic / pessimistic rules as [has].
  bool hasAny(Iterable<String> codenames) {
    final stored = _readAll();
    if (stored.isEmpty) {
      if (_readProvided()) return false;
      if (_optimistic) return true;
    }
    for (final c in codenames) {
      if (stored.contains(c)) return true;
    }
    return false;
  }

  /// Snapshot of the current granted set. Use sparingly — prefer the
  /// targeted [has] / [hasAny] checks at gate sites.
  Set<String> get all => Set<String>.unmodifiable(_readAll());

  /// Most recent sync event — used by the settings tabs to render
  /// status / timestamp / detail. Always non-null (returns a fresh
  /// `idle` snapshot when no sync has happened yet).
  BackendPermissionSyncEvent get lastEvent => _readEvent();

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Set<String> _readAll() {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = _prefs.preferences.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      _cache = <String>{};
      return _cache!;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _cache = decoded.whereType<String>().toSet();
        return _cache!;
      }
    } catch (_) {
      // Corrupt entry — treat as empty so [_optimistic] still applies.
    }
    _cache = <String>{};
    return _cache!;
  }

  /// Synchronous read of the "backend has shipped permissions
  /// field" flag. Hydrated lazily from SharedPreferences on first
  /// access so build-time gates do not block on disk I/O.
  bool _readProvided() {
    final cached = _providedCache;
    if (cached != null) return cached;
    final fromDisk =
        _prefs.preferences.getBool(_prefsMetaProvidedKey) ?? false;
    _providedCache = fromDisk;
    return fromDisk;
  }

  BackendPermissionSyncEvent _readEvent() {
    final cached = _eventCache;
    if (cached != null) return cached;

    final tsRaw = _prefs.preferences.getInt(_prefsMetaTimestampKey);
    final statusRaw = _prefs.preferences.getString(_prefsMetaStatusKey);
    final detail = _prefs.preferences.getString(_prefsMetaDetailKey);
    if (tsRaw == null || statusRaw == null) {
      _eventCache = const BackendPermissionSyncEvent();
      return _eventCache!;
    }
    final status = BackendPermissionSyncStatus.values.firstWhere(
      (s) => s.name == statusRaw,
      orElse: () => BackendPermissionSyncStatus.idle,
    );
    _eventCache = BackendPermissionSyncEvent(
      status: status,
      timestamp: DateTime.fromMillisecondsSinceEpoch(tsRaw),
      detail: detail,
    );
    return _eventCache!;
  }

  Future<void> _recordEvent({
    required BackendPermissionSyncStatus status,
    String? detail,
  }) async {
    final now = DateTime.now();
    _eventCache = BackendPermissionSyncEvent(
      status: status,
      timestamp: now,
      detail: detail,
    );
    await _prefs.preferences
        .setInt(_prefsMetaTimestampKey, now.millisecondsSinceEpoch);
    await _prefs.preferences.setString(_prefsMetaStatusKey, status.name);
    if (detail != null) {
      await _prefs.preferences.setString(_prefsMetaDetailKey, detail);
    } else {
      await _prefs.preferences.remove(_prefsMetaDetailKey);
    }
  }

  /// Drop the in-memory cache. Visible for tests that mutate the
  /// underlying `SharedPreferences` directly and need a fresh read.
  @visibleForTesting
  void invalidateCache() {
    _cache = null;
    _eventCache = null;
    _providedCache = null;
  }
}
