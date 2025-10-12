import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/order.dart';

void main() {
  group('Order Model Tests', () {
    test('Order.fromJson creates correct instance', () {
      final json = {
        'id': 1,
        'numOrder': 'GL00-154855',
        'dateOrder': '2025-10-01T10:52:10',
        'captionOrder': 'Заказ клиента GL00-154855 от 01.10.2025 10:52:10',
        'typePriceCode': 'Цена PS опт',
        'status': 2,
        'commentSupervisor': null,
        'commentForwarder': null,
        'commentAgent': null,
        'total': 785200.0,
        'clientCode': '00-00054499',
        'clientName': 'OVAYXON OOO',
        'codeOrg': '00000000001',
        'mainStatus': 'Доставлено и ожидает оплаты',
      };

      final order = Order.fromJson(json);

      expect(order.id, 1);
      expect(order.numOrder, 'GL00-154855');
      expect(order.dateOrder, DateTime.parse('2025-10-01T10:52:10'));
      expect(order.captionOrder, 'Заказ клиента GL00-154855 от 01.10.2025 10:52:10');
      expect(order.typePriceCode, 'Цена PS опт');
      expect(order.status, 2);
      expect(order.commentSupervisor, null);
      expect(order.total, 785200.0);
      expect(order.clientCode, '00-00054499');
      expect(order.clientName, 'OVAYXON OOO');
      expect(order.mainStatus, 'Доставлено и ожидает оплаты');
    });

    test('Order.toJson returns correct map', () {
      final order = Order(
        id: 1,
        numOrder: 'GL00-154855',
        dateOrder: DateTime.parse('2025-10-01T10:52:10'),
        captionOrder: 'Заказ клиента GL00-154855 от 01.10.2025 10:52:10',
        typePriceCode: 'Цена PS опт',
        status: 2,
        total: 785200.0,
        clientCode: '00-00054499',
        clientName: 'OVAYXON OOO',
        codeOrg: '00000000001',
        mainStatus: 'Доставлено и ожидает оплаты',
      );

      final json = order.toJson();

      expect(json['id'], 1);
      expect(json['numOrder'], 'GL00-154855');
      expect(json['dateOrder'], '2025-10-01T10:52:10.000');
      expect(json['total'], 785200.0);
      expect(json['mainStatus'], 'Доставлено и ожидает оплаты');
    });

    test('Order.copyWith returns correct instance', () {
      final original = Order(
        numOrder: 'GL00-154855',
        dateOrder: DateTime.now(),
        captionOrder: 'Test order',
        typePriceCode: 'Цена PS опт',
        status: 2,
        total: 785200.0,
        clientCode: '00-00054499',
        clientName: 'OVAYXON OOO',
        codeOrg: '00000000001',
        mainStatus: 'Доставлено и ожидает оплаты',
      );

      final copied = original.copyWith(
        total: 1000000.0,
        mainStatus: 'Доставлено и оплачено',
      );

      expect(copied.numOrder, original.numOrder);
      expect(copied.total, 1000000.0);
      expect(copied.mainStatus, 'Доставлено и оплачено');
    });

    test('Order equality works correctly', () {
      final order1 = Order(
        numOrder: 'GL00-154855',
        dateOrder: DateTime.now(),
        captionOrder: 'Test',
        typePriceCode: 'Цена PS опт',
        status: 2,
        total: 785200.0,
        clientCode: '00-00054499',
        clientName: 'OVAYXON OOO',
        codeOrg: '00000000001',
        mainStatus: 'Доставлено и ожидает оплаты',
      );

      final order2 = Order(
        numOrder: 'GL00-154855',
        dateOrder: order1.dateOrder,
        captionOrder: 'Test',
        typePriceCode: 'Цена PS опт',
        status: 2,
        total: 785200.0,
        clientCode: '00-00054499',
        clientName: 'OVAYXON OOO',
        codeOrg: '00000000001',
        mainStatus: 'Доставлено и ожидает оплаты',
      );

      expect(order1 == order2, true);
    });

    test('Order toString works correctly', () {
      final order = Order(
        numOrder: 'GL00-154855',
        dateOrder: DateTime.parse('2025-10-01T10:52:10'),
        captionOrder: 'Test',
        typePriceCode: 'Цена PS опт',
        status: 2,
        total: 785200.0,
        clientCode: '00-00054499',
        clientName: 'OVAYXON OOO',
        codeOrg: '00000000001',
        mainStatus: 'Доставлено и ожидает оплаты',
      );

      final toString = order.toString();
      expect(toString.contains('GL00-154855'), true);
      expect(toString.contains('785200.0'), true);
    });
  });
}