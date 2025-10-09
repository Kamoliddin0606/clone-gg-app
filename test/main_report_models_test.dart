import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/main_report.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/business_region_report.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/akb_by_category.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_plan.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/visit_plan_list.dart';

void main() {
  group('MainReport Model Tests', () {
    test('MainReport.fromMap creates correct instance', () {
      final map = {
        'id': 1,
        'user_code': '001',
        'date_start': '2025-10-01',
        'date_end': '2025-10-09',
        'count_akb': 79,
        'count_okb': 402,
        'cash': 29050010.0,
        'transfer': 27082530.0,
        'sum': 56132540.0,
        'count_visited': 93,
        'created_at': '2025-10-09T10:00:00.000Z',
        'updated_at': '2025-10-09T10:00:00.000Z',
      };

      final report = MainReport.fromMap(map);

      expect(report.id, 1);
      expect(report.userCode, '001');
      expect(report.dateStart, DateTime(2025, 10, 1));
      expect(report.dateEnd, DateTime(2025, 10, 9));
      expect(report.countAKB, 79);
      expect(report.countOKB, 402);
      expect(report.cash, 29050010.0);
      expect(report.transfer, 27082530.0);
      expect(report.sum, 56132540.0);
      expect(report.countVisited, 93);
      expect(report.createdAt, isNotNull);
      expect(report.updatedAt, isNotNull);
    });

    test('MainReport.toMap returns correct map', () {
      final report = MainReport(
        id: 1,
        userCode: '001',
        dateStart: DateTime(2025, 10, 1),
        dateEnd: DateTime(2025, 10, 9),
        countAKB: 79,
        countOKB: 402,
        cash: 29050010.0,
        transfer: 27082530.0,
        sum: 56132540.0,
        countVisited: 93,
        createdAt: DateTime.parse('2025-10-09T10:00:00.000Z'),
        updatedAt: DateTime.parse('2025-10-09T10:00:00.000Z'),
      );

      final map = report.toMap();

      expect(map['id'], 1);
      expect(map['user_code'], '001');
      expect(map['date_start'], '2025-10-01');
      expect(map['date_end'], '2025-10-09');
      expect(map['count_akb'], 79);
      expect(map['count_okb'], 402);
      expect(map['cash'], 29050010.0);
      expect(map['transfer'], 27082530.0);
      expect(map['sum'], 56132540.0);
      expect(map['count_visited'], 93);
      expect(map['created_at'], '2025-10-09T10:00:00.000Z');
      expect(map['updated_at'], '2025-10-09T10:00:00.000Z');
    });

    test('MainReport.copyWith creates modified copy', () {
      final original = MainReport(
        userCode: '001',
        dateStart: DateTime(2025, 10, 1),
        dateEnd: DateTime(2025, 10, 9),
        countAKB: 79,
        countOKB: 402,
        cash: 29050010.0,
        transfer: 27082530.0,
        sum: 56132540.0,
        countVisited: 93,
      );

      final copy = original.copyWith(countAKB: 100, cash: 30000000.0);

      expect(copy.userCode, '001');
      expect(copy.countAKB, 100);
      expect(copy.cash, 30000000.0);
      expect(copy.countOKB, 402); // unchanged
    });
  });

  group('BusinessRegionReport Model Tests', () {
    test('BusinessRegionReport.fromMap creates correct instance', () {
      final map = {
        'id': 1,
        'main_report_id': 1,
        'code': '00000000713',
        'name': 'Мирзо-Улугбекский район-1',
        'akb': 44,
        'created_at': '2025-10-09T10:00:00.000Z',
        'updated_at': '2025-10-09T10:00:00.000Z',
      };

      final report = BusinessRegionReport.fromMap(map);

      expect(report.id, 1);
      expect(report.mainReportId, 1);
      expect(report.code, '00000000713');
      expect(report.name, 'Мирзо-Улугбекский район-1');
      expect(report.akb, 44);
    });

    test('BusinessRegionReport.toMap returns correct map', () {
      final report = BusinessRegionReport(
        id: 1,
        mainReportId: 1,
        code: '00000000713',
        name: 'Мирзо-Улугбекский район-1',
        akb: 44,
        createdAt: DateTime.parse('2025-10-09T10:00:00.000Z'),
        updatedAt: DateTime.parse('2025-10-09T10:00:00.000Z'),
      );

      final map = report.toMap();

      expect(map['id'], 1);
      expect(map['main_report_id'], 1);
      expect(map['code'], '00000000713');
      expect(map['name'], 'Мирзо-Улугбекский район-1');
      expect(map['akb'], 44);
    });
  });

  group('AKBByCategory Model Tests', () {
    test('AKBByCategory.fromMap creates correct instance', () {
      final map = {
        'id': 1,
        'main_report_id': 1,
        'code': '00-00000003',
        'name': 'DURU SOAP',
        'akb': 56,
        'created_at': '2025-10-09T10:00:00.000Z',
        'updated_at': '2025-10-09T10:00:00.000Z',
      };

      final category = AKBByCategory.fromMap(map);

      expect(category.id, 1);
      expect(category.mainReportId, 1);
      expect(category.code, '00-00000003');
      expect(category.name, 'DURU SOAP');
      expect(category.akb, 56);
    });

    test('AKBByCategory.toMap returns correct map', () {
      final category = AKBByCategory(
        id: 1,
        mainReportId: 1,
        code: '00-00000003',
        name: 'DURU SOAP',
        akb: 56,
        createdAt: DateTime.parse('2025-10-09T10:00:00.000Z'),
        updatedAt: DateTime.parse('2025-10-09T10:00:00.000Z'),
      );

      final map = category.toMap();

      expect(map['id'], 1);
      expect(map['main_report_id'], 1);
      expect(map['code'], '00-00000003');
      expect(map['name'], 'DURU SOAP');
      expect(map['akb'], 56);
    });
  });

  group('VisitPlan Model Tests', () {
    test('VisitPlan.fromMap creates correct instance', () {
      final map = {
        'id': 1,
        'main_report_id': 1,
        'client_code': 'C001',
        'client_name': 'Test Client',
        'planned_date': '2025-10-10',
        'actual_visit_date': '2025-10-10',
        'is_completed': 1,
        'notes': 'Test visit',
        'created_at': '2025-10-09T10:00:00.000Z',
        'updated_at': '2025-10-09T10:00:00.000Z',
      };

      final plan = VisitPlan.fromMap(map);

      expect(plan.id, 1);
      expect(plan.mainReportId, 1);
      expect(plan.clientCode, 'C001');
      expect(plan.clientName, 'Test Client');
      expect(plan.plannedDate, '2025-10-10');
      expect(plan.actualVisitDate, '2025-10-10');
      expect(plan.isCompleted, true);
      expect(plan.notes, 'Test visit');
    });

    test('VisitPlan.toMap returns correct map', () {
      final plan = VisitPlan(
        id: 1,
        mainReportId: 1,
        clientCode: 'C001',
        clientName: 'Test Client',
        plannedDate: '2025-10-10',
        actualVisitDate: '2025-10-10',
        isCompleted: true,
        notes: 'Test visit',
        createdAt: DateTime.parse('2025-10-09T10:00:00.000Z'),
        updatedAt: DateTime.parse('2025-10-09T10:00:00.000Z'),
      );

      final map = plan.toMap();

      expect(map['id'], 1);
      expect(map['main_report_id'], 1);
      expect(map['client_code'], 'C001');
      expect(map['client_name'], 'Test Client');
      expect(map['planned_date'], '2025-10-10');
      expect(map['actual_visit_date'], '2025-10-10');
      expect(map['is_completed'], 1);
      expect(map['notes'], 'Test visit');
    });
  });

  group('VisitPlanList Model Tests', () {
    test('VisitPlanList.fromMap creates correct instance', () {
      final map = {
        'id': 1,
        'visit_plan_id': 1,
        'product_code': 'P001',
        'product_name': 'Test Product',
        'planned_quantity': 10,
        'actual_quantity': 8,
        'notes': 'Partial delivery',
        'created_at': '2025-10-09T10:00:00.000Z',
        'updated_at': '2025-10-09T10:00:00.000Z',
      };

      final list = VisitPlanList.fromMap(map);

      expect(list.id, 1);
      expect(list.visitPlanId, 1);
      expect(list.productCode, 'P001');
      expect(list.productName, 'Test Product');
      expect(list.plannedQuantity, 10);
      expect(list.actualQuantity, 8);
      expect(list.notes, 'Partial delivery');
    });

    test('VisitPlanList.toMap returns correct map', () {
      final list = VisitPlanList(
        id: 1,
        visitPlanId: 1,
        productCode: 'P001',
        productName: 'Test Product',
        plannedQuantity: 10,
        actualQuantity: 8,
        notes: 'Partial delivery',
        createdAt: DateTime.parse('2025-10-09T10:00:00.000Z'),
        updatedAt: DateTime.parse('2025-10-09T10:00:00.000Z'),
      );

      final map = list.toMap();

      expect(map['id'], 1);
      expect(map['visit_plan_id'], 1);
      expect(map['product_code'], 'P001');
      expect(map['product_name'], 'Test Product');
      expect(map['planned_quantity'], 10);
      expect(map['actual_quantity'], 8);
      expect(map['notes'], 'Partial delivery');
    });
  });

  group('Edge Cases', () {
    test('Models handle null values correctly', () {
      // Test MainReport with null id and timestamps
      final report = MainReport.fromMap({
        'user_code': '001',
        'date_start': '2025-10-01',
        'date_end': '2025-10-09',
        'count_akb': 0,
        'count_okb': 0,
        'cash': 0.0,
        'transfer': 0.0,
        'sum': 0.0,
        'count_visited': 0,
      });

      expect(report.id, null);
      expect(report.createdAt, null);
      expect(report.updatedAt, null);

      // Test VisitPlan with null actual_visit_date and notes
      final plan = VisitPlan.fromMap({
        'main_report_id': 1,
        'client_code': 'C001',
        'client_name': 'Test Client',
        'planned_date': '2025-10-10',
        'is_completed': 0,
      });

      expect(plan.actualVisitDate, null);
      expect(plan.notes, null);
    });

    test('Models handle empty strings', () {
      final category = AKBByCategory.fromMap({
        'main_report_id': 1,
        'code': '',
        'name': '',
        'akb': 0,
      });

      expect(category.code, '');
      expect(category.name, '');
    });
  });
}