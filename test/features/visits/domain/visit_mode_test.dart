import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/permissions.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/visit_mode.dart';

/// Scope-cascade rollout (2026-05-17) — passport § 6.
///
/// Locks the four-mode UX truth table so a future refactor of
/// [PermissionFlags] can't silently flip the rule that decides whether
/// a user sees a planned-only entry point, an unplanned-only entry
/// point, both, or a "configuration missing" screen.
void main() {
  group('VisitMode.fromFlags — truth table', () {
    test('blocked: unplannedOnlyMode && !allowUnplannedVisit', () {
      expect(
        VisitMode.fromFlags(
          unplannedOnlyMode: true,
          allowUnplannedVisit: false,
        ),
        VisitMode.blocked,
      );
    });

    test('plannedOnly: !unplannedOnlyMode && !allowUnplannedVisit', () {
      expect(
        VisitMode.fromFlags(
          unplannedOnlyMode: false,
          allowUnplannedVisit: false,
        ),
        VisitMode.plannedOnly,
      );
    });

    test('unplannedOnly: unplannedOnlyMode && allowUnplannedVisit', () {
      expect(
        VisitMode.fromFlags(
          unplannedOnlyMode: true,
          allowUnplannedVisit: true,
        ),
        VisitMode.unplannedOnly,
      );
    });

    test('both: !unplannedOnlyMode && allowUnplannedVisit', () {
      expect(
        VisitMode.fromFlags(
          unplannedOnlyMode: false,
          allowUnplannedVisit: true,
        ),
        VisitMode.both,
      );
    });
  });

  group('VisitMode accessors', () {
    test('canStartPlanned matches plannedOnly + both', () {
      expect(VisitMode.blocked.canStartPlanned, isFalse);
      expect(VisitMode.plannedOnly.canStartPlanned, isTrue);
      expect(VisitMode.unplannedOnly.canStartPlanned, isFalse);
      expect(VisitMode.both.canStartPlanned, isTrue);
    });

    test('canStartUnplanned matches unplannedOnly + both', () {
      expect(VisitMode.blocked.canStartUnplanned, isFalse);
      expect(VisitMode.plannedOnly.canStartUnplanned, isFalse);
      expect(VisitMode.unplannedOnly.canStartUnplanned, isTrue);
      expect(VisitMode.both.canStartUnplanned, isTrue);
    });

    test('canStartAnyVisit excludes blocked', () {
      expect(VisitMode.blocked.canStartAnyVisit, isFalse);
      expect(VisitMode.plannedOnly.canStartAnyVisit, isTrue);
      expect(VisitMode.unplannedOnly.canStartAnyVisit, isTrue);
      expect(VisitMode.both.canStartAnyVisit, isTrue);
    });
  });

  test('VisitMode.fromPermissions reads the two flag fields', () {
    final perms = VisitsPermissions(
      etag: '"abc"',
      userCode: 'u1',
      projectCode: 'p1',
      flags: PermissionFlags.fromJson({
        'visit_submission_path': 'rest_v2',
        'allow_unplanned_visit': true,
        'unplanned_only_mode': false,
      }),
      thresholds: PermissionThresholds.fromJson(const {}),
      enabledTasks: const ['PHOTO_BEFORE'],
      taskOrder: const ['PHOTO_BEFORE'],
      taskRequired: const {'PHOTO_BEFORE': true},
    );

    expect(VisitMode.fromPermissions(perms), VisitMode.both);
  });

  test('older backend (missing both flags) defaults to plannedOnly', () {
    // Backward-compat: response shape pre-2026-05-17. The parser fills
    // both new flag fields with false, which maps to plannedOnly — the
    // safest reading (existing planned-route flow keeps working).
    final flags = PermissionFlags.fromJson(const {
      'visit_submission_path': 'rest_v2',
    });
    expect(
      VisitMode.fromFlags(
        unplannedOnlyMode: flags.unplannedOnlyMode,
        allowUnplannedVisit: flags.allowUnplannedVisit,
      ),
      VisitMode.plannedOnly,
    );
  });
}
