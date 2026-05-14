import 'dart:convert';

import 'device_binding.dart';

/// Per-organization customer pool scoping. Controls whether mobile must
/// send `X-Project-Id` on `/api/mobile/v2/customers/...` calls.
enum CustomerScope {
  /// All projects of the tenant share one customer pool. No header is sent.
  organization,

  /// Each project owns its own customer pool. `X-Project-Id` is required.
  project,
}

/// Envelope for `POST /api/auth/token/` (and `/refresh/`) responses.
///
/// Bundles the JWT access + refresh pair with the backend's `gates` block
/// so the mobile app can decide on cold start whether the cached session
/// is still valid without contacting the server (offline-friendly).
///
/// The backend recomputes `gates` on every refresh, so any successful
/// refresh MUST overwrite the cached envelope to propagate license
/// extensions or `user_active_end` changes within ~60 minutes.
class LoginGatesEnvelope {
  /// Bearer token sent on every authenticated request (`Authorization`).
  final String accessToken;

  /// Long-lived token used to obtain a new `access` via `/refresh/`.
  final String refreshToken;

  /// When this user's individual access window ends. `null` means no
  /// per-user limit is configured — license/seat gates still apply.
  final DateTime? userActiveEnd;

  /// When the organization's license expires. `null` for superusers
  /// (`bypass=true`) where `licenseValidTo` is intentionally absent.
  final DateTime? licenseValidTo;

  /// Tenant the user belongs to. `null` for platform admins (superusers)
  /// who are not scoped to a single organization.
  final String? organizationId;

  /// Server's UTC time at the moment of token issuance. Used by
  /// `AppStartGuard` as a clock-tampering sanity check (device clock
  /// must not be earlier than this).
  final DateTime serverTime;

  /// `true` for platform-admin (superuser) sessions. License and seat
  /// gates are skipped server-side; mobile must treat
  /// `licenseValidTo == null` as "no expiry" instead of "missing".
  final bool bypass;

  /// Echo of the server-side device binding for this session. `null`
  /// during Stage 1 of the binding rollout (record-only) when the
  /// backend may legitimately omit the block. Always non-null after
  /// Stage 2 once the strict mobile flow ships.
  final DeviceBinding? device;

  /// Dotted-codename permissions the user holds. Empty when the
  /// backend hasn't shipped the exposure yet — see
  /// [PermissionCheck.has] for the optimistic / pessimistic gate.
  final List<String> permissions;

  /// Whether the backend explicitly returned the `permissions` field
  /// (even as an empty array) vs. omitting it entirely. Distinguishes
  /// "rollout in progress, server doesn't ship the field yet" from
  /// "the user genuinely has no codenames". The mobile permission
  /// store reads this to decide whether to fall back to the
  /// optimistic-empty grant for empty payloads.
  final bool permissionsProvided;

  /// Customer pool scoping for the tenant. Drives whether `X-Project-Id`
  /// is required on `/api/mobile/v2/customers/...` calls.
  final CustomerScope customerScope;

  /// Backend-suggested default project (UUID) for `customer_scope=project`
  /// tenants. May be `null` — in that case the user picks from a list.
  final String? primaryProjectId;

  /// `true` when the server explicitly returned `customer_scope` in the
  /// gates block (even with value `organization`). Distinguishes a rolled-
  /// out tenant from an old session where the field was absent.
  final bool customerScopeProvided;

  const LoginGatesEnvelope({
    required this.accessToken,
    required this.refreshToken,
    required this.userActiveEnd,
    required this.licenseValidTo,
    required this.organizationId,
    required this.serverTime,
    required this.bypass,
    this.device,
    this.permissions = const <String>[],
    this.permissionsProvided = false,
    this.customerScope = CustomerScope.organization,
    this.primaryProjectId,
    this.customerScopeProvided = false,
  });

  /// Tolerates missing optional fields by defaulting to `null`/`false`.
  /// Throws [FormatException] only when required fields are absent.
  factory LoginGatesEnvelope.fromJson(Map<String, dynamic> json) {
    final access = json[_Keys.access];
    final refresh = json[_Keys.refresh];
    if (access is! String || access.isEmpty) {
      throw const FormatException('login envelope: missing "access"');
    }
    if (refresh is! String || refresh.isEmpty) {
      throw const FormatException('login envelope: missing "refresh"');
    }

    final gatesRaw = json[_Keys.gates];
    final Map<String, dynamic> gates = gatesRaw is Map<String, dynamic>
        ? gatesRaw
        : const <String, dynamic>{};

    final serverTimeRaw = gates[_Keys.serverTime];
    final DateTime serverTime;
    if (serverTimeRaw is String && serverTimeRaw.isNotEmpty) {
      serverTime = DateTime.parse(serverTimeRaw).toUtc();
    } else {
      // Fall back to "now" so the guard does not crash on partial payloads.
      serverTime = DateTime.now().toUtc();
    }

    // The `device` block lives at the SAME LEVEL as `access` / `refresh`
    // / `gates`, NOT inside `gates`. See backend contract.
    final deviceRaw = json[_Keys.device];
    final DeviceBinding? device = deviceRaw is Map<String, dynamic>
        ? DeviceBinding.fromJson(deviceRaw)
        : null;

    final permissionsRaw = gates[_Keys.permissions];
    // `permissionsProvided` is true whenever the server explicitly
    // included the field (List), regardless of how many entries it
    // holds. Missing / non-List → false (rollout window).
    final bool permissionsProvided = permissionsRaw is List;
    final List<String> permissions = permissionsRaw is List
        ? permissionsRaw.whereType<String>().toList(growable: false)
        : const <String>[];

    final scopeRaw = gates[_Keys.customerScope];
    final bool customerScopeProvided = scopeRaw is String && scopeRaw.isNotEmpty;
    final CustomerScope customerScope =
        scopeRaw == 'project' ? CustomerScope.project : CustomerScope.organization;
    final primaryProjectRaw = gates[_Keys.primaryProjectId];
    final String? primaryProjectId =
        primaryProjectRaw is String && primaryProjectRaw.isNotEmpty
            ? primaryProjectRaw
            : null;

    return LoginGatesEnvelope(
      accessToken: access,
      refreshToken: refresh,
      userActiveEnd: _parseUtc(gates[_Keys.userActiveEnd]),
      licenseValidTo: _parseUtc(gates[_Keys.licenseValidTo]),
      organizationId: gates[_Keys.organizationId] as String?,
      serverTime: serverTime,
      bypass: gates[_Keys.bypass] as bool? ?? false,
      device: device,
      permissions: permissions,
      permissionsProvided: permissionsProvided,
      customerScope: customerScope,
      primaryProjectId: primaryProjectId,
      customerScopeProvided: customerScopeProvided,
    );
  }

  Map<String, dynamic> toJson() {
    final gates = <String, dynamic>{
      _Keys.userActiveEnd: userActiveEnd?.toUtc().toIso8601String(),
      _Keys.licenseValidTo: licenseValidTo?.toUtc().toIso8601String(),
      _Keys.organizationId: organizationId,
      _Keys.serverTime: serverTime.toUtc().toIso8601String(),
      _Keys.bypass: bypass,
      _Keys.permissions: permissions,
    };
    if (customerScopeProvided) {
      gates[_Keys.customerScope] =
          customerScope == CustomerScope.project ? 'project' : 'organization';
      gates[_Keys.primaryProjectId] = primaryProjectId;
    }
    final map = <String, dynamic>{
      _Keys.access: accessToken,
      _Keys.refresh: refreshToken,
      _Keys.gates: gates,
    };
    if (device != null) {
      map[_Keys.device] = device!.toJson();
    }
    return map;
  }

  /// Compact JSON representation for SharedPreferences storage.
  String encode() => jsonEncode(toJson());

  /// Inverse of [encode]. Returns `null` when [raw] is empty/invalid so
  /// callers can treat "no cache" and "corrupt cache" identically.
  static LoginGatesEnvelope? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return LoginGatesEnvelope.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  LoginGatesEnvelope copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? userActiveEnd,
    DateTime? licenseValidTo,
    String? organizationId,
    DateTime? serverTime,
    bool? bypass,
    DeviceBinding? device,
    List<String>? permissions,
    bool? permissionsProvided,
    CustomerScope? customerScope,
    String? primaryProjectId,
    bool? customerScopeProvided,
  }) {
    return LoginGatesEnvelope(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      userActiveEnd: userActiveEnd ?? this.userActiveEnd,
      licenseValidTo: licenseValidTo ?? this.licenseValidTo,
      organizationId: organizationId ?? this.organizationId,
      serverTime: serverTime ?? this.serverTime,
      bypass: bypass ?? this.bypass,
      device: device ?? this.device,
      permissions: permissions ?? this.permissions,
      permissionsProvided:
          permissionsProvided ?? this.permissionsProvided,
      customerScope: customerScope ?? this.customerScope,
      primaryProjectId: primaryProjectId ?? this.primaryProjectId,
      customerScopeProvided:
          customerScopeProvided ?? this.customerScopeProvided,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginGatesEnvelope &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken &&
        other.userActiveEnd == userActiveEnd &&
        other.licenseValidTo == licenseValidTo &&
        other.organizationId == organizationId &&
        other.serverTime == serverTime &&
        other.bypass == bypass &&
        other.device == device &&
        other.customerScope == customerScope &&
        other.primaryProjectId == primaryProjectId &&
        other.customerScopeProvided == customerScopeProvided &&
        _listEq(other.permissions, permissions);
  }

  @override
  int get hashCode => Object.hash(
        accessToken,
        refreshToken,
        userActiveEnd,
        licenseValidTo,
        organizationId,
        serverTime,
        bypass,
        device,
        Object.hashAll(permissions),
        customerScope,
        primaryProjectId,
      );

  static bool _listEq(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static DateTime? _parseUtc(Object? value) {
    if (value is! String || value.isEmpty) return null;
    try {
      return DateTime.parse(value).toUtc();
    } catch (_) {
      return null;
    }
  }
}

/// Centralized JSON-key constants — the same names appear in
/// `toJson` and `fromJson`, no string duplication.
class _Keys {
  static const String access = 'access';
  static const String refresh = 'refresh';
  static const String gates = 'gates';
  static const String device = 'device';
  static const String userActiveEnd = 'user_active_end';
  static const String licenseValidTo = 'license_valid_to';
  static const String organizationId = 'organization_id';
  static const String serverTime = 'server_time';
  static const String bypass = 'bypass';
  static const String permissions = 'permissions';
  static const String customerScope = 'customer_scope';
  static const String primaryProjectId = 'primary_project_id';
}
