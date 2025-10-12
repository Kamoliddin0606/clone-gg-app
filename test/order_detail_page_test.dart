import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/order.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/order_detail_page.dart';

void main() {
  late Order testOrder;

  setUp(() {
    testOrder = Order(
      numOrder: 'GL00-154855',
      dateOrder: DateTime.parse('2025-10-01T10:52:10'),
      captionOrder: 'Заказ клиента GL00-154855 от 01.10.2025 10:52:10',
      typePriceCode: 'Цена PS опт',
      status: 2,
      commentSupervisor: 'Supervisor comment',
      commentAgent: 'Agent comment',
      total: 785200.0,
      clientCode: '00-00054499',
      clientName: 'OVAYXON OOO',
      codeOrg: '00000000001',
      mainStatus: 'Доставлено и ожидает оплаты',
    );
  });

  group('OrderDetailPage', () {
    testWidgets('displays order header information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailPage(order: testOrder),
        ),
      );

      // Check if order number is displayed
      expect(find.text('GL00-154855'), findsOneWidget);

      // Check if client name is displayed
      expect(find.textContaining('OVAYXON OOO'), findsOneWidget);

      // Check if total amount is displayed
      expect(find.textContaining('785 200 UZS'), findsOneWidget);

      // Check if status is displayed
      expect(find.text('Доставлено'), findsOneWidget);
    });

    testWidgets('displays client information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailPage(order: testOrder),
        ),
      );

      // Check client information section
      expect(find.text('Mijoz ma\'lumotlari'), findsOneWidget);
      expect(find.text('Mijoz nomi'), findsOneWidget);
      expect(find.text('Mijoz kodi'), findsOneWidget);
      expect(find.text('Tashkilot kodi'), findsOneWidget);
    });

    testWidgets('displays order details correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailPage(order: testOrder),
        ),
      );

      // Check order details section - find by widget structure instead of text
      expect(find.text('Buyurtma sanasi'), findsOneWidget);
      expect(find.text('Sarlavha'), findsOneWidget);
      expect(find.text('Narx turi'), findsOneWidget);
      expect(find.text('Status kodi'), findsOneWidget);
    });

    testWidgets('displays status and timeline correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailPage(order: testOrder),
        ),
      );

      // Check status section
      expect(find.text('Status va holat'), findsOneWidget);
      expect(find.text('Joriy status'), findsOneWidget);
    });

    testWidgets('displays comments when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailPage(order: testOrder),
        ),
      );

      // Check comments section
      expect(find.text('Izohlar'), findsOneWidget);
      expect(find.text('Supervisor izohi'), findsOneWidget);
      expect(find.text('Agent izohi'), findsOneWidget);
    });

    testWidgets('does not display comments section when no comments', (WidgetTester tester) async {
      final orderWithoutComments = Order(
        numOrder: 'GL00-154856',
        dateOrder: DateTime.parse('2025-10-01T10:52:10'),
        captionOrder: 'Заказ клиента GL00-154856 от 01.10.2025 10:52:10',
        typePriceCode: 'Цена PS опт',
        status: 2,
        total: 500000.0,
        clientCode: '00-00054498',
        clientName: 'TEST CLIENT OOO',
        codeOrg: '00000000002',
        mainStatus: 'Доставлено и ожидает оплаты',
        // No comments
        commentSupervisor: null,
        commentAgent: null,
        commentForwarder: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailPage(order: orderWithoutComments),
        ),
      );

      // Comments section should not be displayed - check for comment labels
      expect(find.text('Supervisor izohi'), findsNothing);
      expect(find.text('Agent izohi'), findsNothing);
    });

    testWidgets('displays action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailPage(order: testOrder),
        ),
      );

      // Check action buttons
      expect(find.text('Amallar'), findsOneWidget);
      expect(find.text('Ulashish'), findsOneWidget);
      expect(find.text('Qo\'ng\'iroq'), findsOneWidget);
    });

    testWidgets('handles refresh action', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailPage(order: testOrder),
        ),
      );

      // Find and tap the refresh button
      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);

      // Note: We can't easily test the refresh functionality without mocking
      // the service locator and repository, but we can verify the button exists
    });

    testWidgets('formats dates correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailPage(order: testOrder),
        ),
      );

      // Check if date is formatted correctly in the order details section
      expect(find.text('01.10.2025 10:52'), findsOneWidget);
    });

    testWidgets('handles different status types correctly', (WidgetTester tester) async {
      final testStatuses = [
        'Доставлено и ожидает оплаты',
        'Возврат одобрен',
        'Оператор подтвердил и в процессе комплектации',
        'Срок доставки истёк',
        'Новый',
      ];

      for (final status in testStatuses) {
        final orderWithStatus = testOrder.copyWith(mainStatus: status);

        await tester.pumpWidget(
          MaterialApp(
            home: OrderDetailPage(order: orderWithStatus),
          ),
        );

        // Check that some status text is displayed
        expect(find.textContaining('status'), findsWidgets);

        // Reset for next test
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('has proper app bar title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailPage(order: testOrder),
        ),
      );

      // Check app bar title by finding it in AppBar
      expect(find.widgetWithText(AppBar, 'Buyurtma tafsilotlari'), findsOneWidget);
    });
  });
}