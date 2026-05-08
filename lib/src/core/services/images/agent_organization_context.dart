import 'package:flutter/foundation.dart';

import '../../../features/auth/data/models/login_gates_envelope.dart';
import '../shared_preferences_service.dart';

/// Source of the agent's currently-active organisation id.
///
/// `ImageSourceResolver` keys its feature-flag check on the *target's*
/// organisation, not the agent's primary org — see the multi-org safety
/// notes in `mobile.md`. Today, however, every product / customer the
/// agent sees in the local catalog cache is owned by their primary org
/// (1C is single-tenant per agent), so passing the primary org id as
/// the `targetOrganizationId` is an acceptable default until the
/// catalog sync grows a per-row `organization_id` field.
///
/// Call sites SHOULD prefer the entity's own org id when one is
/// available; only fall back to [primaryOrganizationId] when the
/// catalog row is from the older sync schema. This pre-stages the
/// multi-org case without forcing every screen to thread an explicit
/// override today.
class AgentOrganizationContext {
  /// Reads the most recent login envelope. Function-shaped to keep the
  /// test surface narrow — production code passes
  /// [SharedPreferencesService.getCachedGates] verbatim, while tests
  /// can hand-build envelopes without standing up shared_preferences.
  final LoginGatesEnvelope? Function() _readGates;

  AgentOrganizationContext._({required LoginGatesEnvelope? Function() readGates})
      : _readGates = readGates;

  /// Production constructor wired against [SharedPreferencesService].
  factory AgentOrganizationContext({required SharedPreferencesService prefs}) {
    return AgentOrganizationContext._(readGates: prefs.getCachedGates);
  }

  /// Test constructor that lets the caller supply a gates source
  /// directly. Marked `@visibleForTesting` because production code
  /// has no business injecting a fake envelope reader.
  @visibleForTesting
  factory AgentOrganizationContext.forTest({
    required LoginGatesEnvelope? Function() readGates,
  }) {
    return AgentOrganizationContext._(readGates: readGates);
  }

  /// Returns the agent's primary organisation id, or `null` when no
  /// gates envelope is cached (cold start before login completes,
  /// platform-admin sessions where `organizationId == null`, etc.).
  ///
  /// `null` causes `ImageSourceResolver` to fall back to the legacy
  /// repo, which is the desired behaviour during pre-login bootstrap.
  String? get primaryOrganizationId {
    final cached = _readGates();
    if (cached == null) {
      if (kDebugMode) {
        debugPrint('AgentOrganizationContext: no cached gates envelope');
      }
      return null;
    }
    return cached.organizationId;
  }

  /// Convenience for widget call sites that want a non-null string —
  /// returns the primary org id, or empty string when the envelope is
  /// missing. The empty string is the documented "no opinion" value
  /// the resolver treats as `legacy fallback`.
  String resolveTargetOrgIdFor({String? entityOrganizationId}) {
    if (entityOrganizationId != null && entityOrganizationId.isNotEmpty) {
      return entityOrganizationId;
    }
    return primaryOrganizationId ?? '';
  }
}
