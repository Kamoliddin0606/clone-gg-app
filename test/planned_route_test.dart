import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/planned_route.dart';

void main() {
  group('PlannedRoute Model Tests', () {
    test('PlannedRoute.fromMap should create correct object', () {
      final map = {
        'id': 1,
        'user_code': '000000109',
        'code_weekday': 1,
        'week_day': 'Понедельник',
        'code_client': '00-00024433',
        'client_name': 'NOMOZOVA GULSHOD TOSHPULATOVNA YaTT',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final route = PlannedRoute.fromMap(map);

      expect(route.id, 1);
      expect(route.userCode, '000000109');
      expect(route.codeWeekday, 1);
      expect(route.weekDay, 'Понедельник');
      expect(route.codeClient, '00-00024433');
      expect(route.clientName, 'NOMOZOVA GULSHOD TOSHPULATOVNA YaTT');
      expect(route.createdAt, isA<DateTime>());
      expect(route.updatedAt, isA<DateTime>());
    });

    test('PlannedRoute.toMap should return correct map', () {
      final route = PlannedRoute(
        id: 1,
        userCode: '000000109',
        codeWeekday: 1,
        weekDay: 'Понедельник',
        codeClient: '00-00024433',
        clientName: 'NOMOZOVA GULSHOD TOSHPULATOVNA YaTT',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final map = route.toMap();

      expect(map['id'], 1);
      expect(map['user_code'], '000000109');
      expect(map['code_weekday'], 1);
      expect(map['week_day'], 'Понедельник');
      expect(map['code_client'], '00-00024433');
      expect(map['client_name'], 'NOMOZOVA GULSHOD TOSHPULATOVNA YaTT');
      expect(map['created_at'], '2024-01-01T00:00:00.000Z');
      expect(map['updated_at'], '2024-01-01T00:00:00.000Z');
    });

    test('PlannedRoute constructor should require all parameters', () {
      expect(
        () => PlannedRoute(
          id: 1,
          userCode: 'test',
          codeWeekday: 1,
          weekDay: 'Monday',
          codeClient: 'client1',
          clientName: 'Client Name',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        returnsNormally,
      );
    });

    test('PlannedRoute copyWith should work correctly', () {
      final original = PlannedRoute(
        id: 1,
        userCode: '000000109',
        codeWeekday: 1,
        weekDay: 'Понедельник',
        codeClient: '00-00024433',
        clientName: 'NOMOZOVA GULSHOD TOSHPULATOVNA YaTT',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final copied = original.copyWith(
        clientName: 'Updated Name',
        codeWeekday: 2,
      );

      expect(copied.id, original.id);
      expect(copied.userCode, original.userCode);
      expect(copied.codeWeekday, 2);
      expect(copied.weekDay, original.weekDay);
      expect(copied.codeClient, original.codeClient);
      expect(copied.clientName, 'Updated Name');
      expect(copied.createdAt, original.createdAt);
      expect(copied.updatedAt, original.updatedAt);
    });
  });
}