import 'package:flutter_test/flutter_test.dart';

import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_project.dart';

/// Unit tests for the [UserProject.headerValue] resolution order used
/// by `ProjectContext` to build the `X-Project-Id` header.
///
/// Preference order (from the backend hand-off):
///   1. `idUuid`  — V2 backend Project.id (preferred, immutable).
///   2. `id1c`    — 1C numeric ref (accepted fallback).
///   3. `code`    — SOAP `GetProjectsUser` legacy code (last resort).
void main() {
  group('UserProject.headerValue resolution', () {
    test('prefers idUuid when present', () {
      final project = UserProject(
        userCode: 'u',
        code: 'PRJ-A',
        name: 'Project A',
        idUuid: 'uuid-1',
        id1c: '00-0001',
      );

      expect(project.headerValue, 'uuid-1');
    });

    test('falls back to id1c when idUuid missing', () {
      final project = UserProject(
        userCode: 'u',
        code: 'PRJ-A',
        name: 'Project A',
        id1c: '00-0001',
      );

      expect(project.headerValue, '00-0001');
    });

    test('falls back to code when idUuid + id1c missing', () {
      final project = UserProject(
        userCode: 'u',
        code: 'PRJ-A',
        name: 'Project A',
      );

      expect(project.headerValue, 'PRJ-A');
    });

    test('empty idUuid is skipped (treated as missing)', () {
      final project = UserProject(
        userCode: 'u',
        code: 'PRJ-A',
        name: 'Project A',
        idUuid: '',
        id1c: '00-0001',
      );

      expect(project.headerValue, '00-0001');
    });

    test('empty id1c skipped — falls through to code', () {
      final project = UserProject(
        userCode: 'u',
        code: 'PRJ-A',
        name: 'Project A',
        idUuid: '',
        id1c: '',
      );

      expect(project.headerValue, 'PRJ-A');
    });

    test('returns null when every identifier is empty', () {
      final project = UserProject(
        userCode: 'u',
        code: '',
        name: 'broken',
      );

      expect(project.headerValue, isNull);
    });

    test('fromMap reads new id_uuid / id_1c columns', () {
      final project = UserProject.fromMap(<String, dynamic>{
        'id': 1,
        'user_code': 'u',
        'code': 'PRJ',
        'name': 'P',
        'id_uuid': 'uuid-x',
        'id_1c': '00-0042',
        'created_at': '2026-05-14T00:00:00Z',
        'updated_at': '2026-05-14T00:00:00Z',
      });

      expect(project.idUuid, 'uuid-x');
      expect(project.id1c, '00-0042');
    });

    test('toMap writes new id_uuid / id_1c columns', () {
      final project = UserProject(
        userCode: 'u',
        code: 'PRJ',
        name: 'P',
        idUuid: 'uuid-y',
        id1c: '00-0099',
      );

      final map = project.toMap();

      expect(map['id_uuid'], 'uuid-y');
      expect(map['id_1c'], '00-0099');
    });

    test('copyWith preserves untouched header identifiers', () {
      final project = UserProject(
        userCode: 'u',
        code: 'PRJ',
        name: 'P',
        idUuid: 'uuid-z',
        id1c: '00-0100',
      );

      final copy = project.copyWith(name: 'New Name');

      expect(copy.name, 'New Name');
      expect(copy.idUuid, 'uuid-z');
      expect(copy.id1c, '00-0100');
    });
  });
}
