import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/agent_organization_context.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/login_gates_envelope.dart';

LoginGatesEnvelope _envelope({String? organizationId}) {
  return LoginGatesEnvelope(
    accessToken: 'access',
    refreshToken: 'refresh',
    userActiveEnd: null,
    licenseValidTo: null,
    organizationId: organizationId,
    serverTime: DateTime.parse('2026-05-08T00:00:00Z'),
    bypass: false,
  );
}

void main() {
  group('AgentOrganizationContext.primaryOrganizationId', () {
    test('returns the org id when an envelope is cached', () {
      final ctx = AgentOrganizationContext.forTest(
        readGates: () => _envelope(organizationId: 'org-A'),
      );
      expect(ctx.primaryOrganizationId, 'org-A');
    });

    test('returns null when no envelope is cached', () {
      final ctx = AgentOrganizationContext.forTest(readGates: () => null);
      expect(ctx.primaryOrganizationId, isNull);
    });

    test('returns null when envelope has no org id (superuser)', () {
      final ctx = AgentOrganizationContext.forTest(
        readGates: () => _envelope(organizationId: null),
      );
      expect(ctx.primaryOrganizationId, isNull);
    });
  });

  group('AgentOrganizationContext.resolveTargetOrgIdFor', () {
    test('entity org id wins when present', () {
      final ctx = AgentOrganizationContext.forTest(
        readGates: () => _envelope(organizationId: 'agent-primary'),
      );
      expect(
        ctx.resolveTargetOrgIdFor(entityOrganizationId: 'entity-org'),
        'entity-org',
      );
    });

    test('falls back to primary org when entity has no org id', () {
      final ctx = AgentOrganizationContext.forTest(
        readGates: () => _envelope(organizationId: 'agent-primary'),
      );
      expect(
        ctx.resolveTargetOrgIdFor(entityOrganizationId: null),
        'agent-primary',
      );
    });

    test('returns empty string when both sources are missing', () {
      final ctx = AgentOrganizationContext.forTest(readGates: () => null);
      expect(
        ctx.resolveTargetOrgIdFor(entityOrganizationId: null),
        '',
      );
    });

    test('treats empty entity org id the same as null', () {
      final ctx = AgentOrganizationContext.forTest(
        readGates: () => _envelope(organizationId: 'agent-primary'),
      );
      expect(
        ctx.resolveTargetOrgIdFor(entityOrganizationId: ''),
        'agent-primary',
      );
    });
  });
}
