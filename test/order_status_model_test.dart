import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/order_status.dart';

void main() {
  group('OrderStatus Model Tests', () {
    test('OrderStatus.fromJson creates correct instance', () {
      final json = {
        'id': 1,
        'message': 'Новый',
      };

      final orderStatus = OrderStatus.fromJson(json);

      expect(orderStatus.id, 1);
      expect(orderStatus.message, 'Новый');
    });

    test('OrderStatus.toJson returns correct map', () {
      final orderStatus = OrderStatus(
        id: 1,
        message: 'Доставлено и оплачено',
      );

      final json = orderStatus.toJson();

      expect(json['id'], 1);
      expect(json['message'], 'Доставлено и оплачено');
    });

    test('OrderStatus.copyWith returns correct instance', () {
      final original = OrderStatus(
        id: 1,
        message: 'Новый',
      );

      final copied = original.copyWith(message: 'В обработке');

      expect(copied.id, 1);
      expect(copied.message, 'В обработке');
    });

    test('OrderStatus equality works correctly', () {
      final status1 = OrderStatus(id: 1, message: 'Новый');
      final status2 = OrderStatus(id: 1, message: 'Новый');
      final status3 = OrderStatus(id: 2, message: 'Новый');

      expect(status1 == status2, true);
      expect(status1 == status3, false);
    });

    test('OrderStatus hashCode works correctly', () {
      final status1 = OrderStatus(id: 1, message: 'Новый');
      final status2 = OrderStatus(id: 1, message: 'Новый');

      expect(status1.hashCode == status2.hashCode, true);
    });

    test('OrderStatus toString works correctly', () {
      final status = OrderStatus(id: 1, message: 'Новый');

      expect(status.toString(), 'OrderStatus(id: 1, message: Новый)');
    });
  });
}