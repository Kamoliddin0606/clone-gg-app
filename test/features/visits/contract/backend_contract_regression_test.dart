import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/catalog_task.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/permissions.dart';

/// Backend contract regression suite.
///
/// Source of truth: `SelUp_Backend/docs/api/openapi.yaml` (Phase 2 cut).
/// Every payload below mirrors a real OpenAPI example or the response
/// shape declared in `VisitPermissionsService.get_for_user` /
/// `CatalogView.get`. The tests freeze those shapes — a backend change
/// that drops a key or renames a field will fail here before it reaches
/// production, which is what makes the rollout safe to ship gradually.
void main() {
  group('Permissions contract', () {
    test('parses the canonical /visits/permissions/ body verbatim', () {
      // Lifted from VisitPermissionsService.get_for_user (passport § 11).
      final body = <String, dynamic>{
        'user_id': '00000000-0000-0000-0000-000000000001',
        'organization_id': '00000000-0000-0000-0000-000000000010',
        'project_id': '00000000-0000-0000-0000-000000000020',
        'flags': {
          'visit_submission_path': 'rest_v2',
        },
        'thresholds': {
          'client_zone_access_m': 100,
          'gps_accuracy_max_m': 30,
          'clock_drift_max_s': 300,
        },
        'enabled_tasks': ['PHOTO_BEFORE', 'AUDIT_OWN', 'ORDER_CREATE'],
        'task_order': ['PHOTO_BEFORE', 'AUDIT_OWN', 'ORDER_CREATE'],
        'task_required': {
          'PHOTO_BEFORE': true,
          'AUDIT_OWN': true,
          'ORDER_CREATE': false,
        },
        'etag': 'W/"abc123"',
      };

      final parsed = VisitsPermissions.fromJson(body, etag: 'W/"header"');

      expect(parsed.userCode, body['user_id']);
      expect(parsed.projectCode, body['project_id']);
      expect(parsed.flags.visitSubmissionPath, VisitSubmissionPath.restV2);
      expect(parsed.thresholds.clientZoneAccessM, 100);
      expect(parsed.thresholds.gpsAccuracyMaxM, 30);
      expect(parsed.thresholds.clockDriftMaxS, 300);
      // Backend doesn't emit these threshold keys — defaults must kick in.
      expect(parsed.thresholds.locationUpdateIntervalS, 30);
      expect(parsed.thresholds.maxPhotosPerTask, 10);
      expect(parsed.thresholds.minPhotosPerTask, isEmpty);
      expect(parsed.enabledTasks, body['enabled_tasks']);
      expect(parsed.isRequired('ORDER_CREATE'), isFalse);
      // Body's etag wins over header when present (Phase 2 backend emits both).
      expect(parsed.etag, 'W/"abc123"');
      // Scope-cascade fields default to false/null when the backend
      // omits them (older response shape) — see passport § 2.1.
      expect(parsed.flags.allowUnplannedVisit, isFalse);
      expect(parsed.flags.unplannedOnlyMode, isFalse);
      expect(parsed.resolvedScope, isNull);
    });

    test('parses scope-cascade fields when present (2026-05-17)', () {
      // Mirrors the post-rollout response: same shape plus the three
      // new fields shipped by the scope-cascade backend.
      final body = <String, dynamic>{
        'user_id': '00000000-0000-0000-0000-000000000001',
        'organization_id': '00000000-0000-0000-0000-000000000010',
        'project_id': '00000000-0000-0000-0000-000000000020',
        'flags': {
          'visit_submission_path': 'rest_v2',
          'allow_unplanned_visit': true,
          'unplanned_only_mode': false,
        },
        'thresholds': const <String, dynamic>{},
        'enabled_tasks': const <String>['PHOTO_BEFORE'],
        'task_order': const <String>['PHOTO_BEFORE'],
        'task_required': const <String, bool>{'PHOTO_BEFORE': true},
        'resolved_scope': 'project',
        'etag': 'W/"cascade-1"',
      };

      final parsed = VisitsPermissions.fromJson(body, etag: 'W/"hdr"');
      expect(parsed.flags.allowUnplannedVisit, isTrue);
      expect(parsed.flags.unplannedOnlyMode, isFalse);
      expect(parsed.resolvedScope, 'project');
    });

    test('parses unplanned-only mode (no tasks at any scope level)', () {
      final body = <String, dynamic>{
        'user_id': 'u1',
        'flags': {
          'visit_submission_path': 'rest_v2',
          'allow_unplanned_visit': true,
          'unplanned_only_mode': true,
        },
        'thresholds': const <String, dynamic>{},
        'enabled_tasks': const <String>[],
        'task_order': const <String>[],
        'task_required': const <String, bool>{},
        'resolved_scope': 'none',
      };
      final parsed = VisitsPermissions.fromJson(body, etag: 'W/"unplanned"');
      expect(parsed.enabledTasks, isEmpty);
      expect(parsed.flags.unplannedOnlyMode, isTrue);
      expect(parsed.flags.allowUnplannedVisit, isTrue);
      expect(parsed.resolvedScope, 'none');
    });

    test('falls back to header ETag when body omits one', () {
      final parsed = VisitsPermissions.fromJson(
        {
          'user_id': 'u',
          'flags': {'visit_submission_path': 'soap'},
          'thresholds': {},
          'enabled_tasks': const [],
          'task_order': const [],
          'task_required': const {},
        },
        etag: 'W/"header-only"',
      );
      expect(parsed.etag, 'W/"header-only"');
      expect(parsed.flags.visitSubmissionPath, VisitSubmissionPath.soap);
    });

    test('legacy user_code / project_code keys still parse', () {
      // Older builds shipped these names. Phase 2 rolls forward but the
      // parser keeps the back-compat path so a downgraded backend during
      // rollout doesn't brick the app.
      final parsed = VisitsPermissions.fromJson(
        {
          'user_code': 'U001',
          'project_code': 'evyap',
          'flags': {'visit_submission_path': 'soap'},
          'thresholds': const {},
          'enabled_tasks': const [],
          'task_order': const [],
          'task_required': const {},
        },
        etag: 'W/"legacy"',
      );
      expect(parsed.userCode, 'U001');
      expect(parsed.projectCode, 'evyap');
    });

    test('defaults to soap path when the flag is missing', () {
      final parsed = VisitsPermissions.fromJson(
        {
          'flags': const <String, dynamic>{},
          'thresholds': const <String, dynamic>{},
          'enabled_tasks': const [],
          'task_order': const [],
          'task_required': const {},
        },
        etag: 'W/"x"',
      );
      expect(parsed.flags.visitSubmissionPath, VisitSubmissionPath.soap);
    });
  });

  group('Catalog contract', () {
    test('parses the DRF-style {"results": [...]} envelope', () {
      final body = <String, dynamic>{
        'results': [
          {
            'task_code': 'PHOTO_BEFORE',
            'name_i18n': {'uz': 'Foto oldidan', 'en': 'Photo before'},
            'required': true,
            'display_order': 0,
            'payload_schema': {
              'type': 'object',
              'properties': {
                'photo_asset_ids': {'type': 'array', 'items': {'type': 'string'}},
              },
            },
            'payload_schema_version': 1,
            'config': {'min_count': 1, 'max_count': 5},
            'renderer_hint': 'custom',
          },
        ],
      };

      final parsed = VisitsCatalog.fromJson(body, etag: 'W/"abc"');
      expect(parsed.tasks, hasLength(1));
      expect(parsed.byCode('PHOTO_BEFORE')?.required, isTrue);
      expect(parsed.byCode('PHOTO_BEFORE')?.config['min_count'], 1);
      expect(
        parsed.byCode('PHOTO_BEFORE')?.displayName('uz'),
        'Foto oldidan',
      );
    });

    test('falls back to displayName(en) when locale missing', () {
      final body = {
        'results': [
          {
            'task_code': 'NPS',
            'name_i18n': {'en': 'NPS score'},
            'display_order': 1,
          }
        ]
      };
      final parsed = VisitsCatalog.fromJson(body, etag: '');
      expect(parsed.byCode('NPS')?.displayName('xx'), 'NPS score');
    });

    test('legacy {"tasks": [...]} key still parses (mixed-version rollout)',
        () {
      final body = {
        'tasks': [
          {
            'task_code': 'AUDIT_OWN',
            'name_i18n': {'uz': 'Polka', 'en': 'Shelf'},
            'required': true,
            'display_order': 2,
            'payload_schema': const {},
            'payload_schema_version': 1,
          },
        ],
      };
      final parsed = VisitsCatalog.fromJson(body, etag: 'W/"legacy"');
      expect(parsed.tasks, hasLength(1));
      expect(parsed.byCode('AUDIT_OWN')?.required, isTrue);
    });

    test('empty response yields empty catalog without crashing', () {
      final parsed = VisitsCatalog.fromJson(const {}, etag: 'W/"empty"');
      expect(parsed.tasks, isEmpty);
    });
  });
}
