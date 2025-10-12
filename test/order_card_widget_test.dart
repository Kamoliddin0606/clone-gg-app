import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/order.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/order_card_widget.dart';

void main() {
  late Order testOrder;

  setUp(() {
    testOrder = Order(
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
  });

  group('OrderCardWidget', () {
    testWidgets('displays order information correctly in list view', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: OrderCardWidget(
              order: testOrder,
              isGridView: false,
            ),
          ),
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

    testWidgets('displays order information correctly in grid view', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: OrderCardWidget(
              order: testOrder,
              isGridView: true,
            ),
          ),
        ),
      );

      // Check if order number is displayed
      expect(find.text('GL00-154855'), findsOneWidget);

      // Check if client name is displayed
      expect(find.text('OVAYXON OOO'), findsOneWidget);

      // Check if total amount is displayed
      expect(find.textContaining('785 200 UZS'), findsOneWidget);

      // Check if status is displayed
      expect(find.text('Доставлено'), findsOneWidget);
    });

    testWidgets('handles onTap callback', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: OrderCardWidget(
              order: testOrder,
              onTap: () => tapped = true,
              isGridView: false,
            ),
          ),
        ),
      );

      // Tap the card
      await tester.tap(find.byType(OrderCardWidget));
      await tester.pump();

      // Check if callback was called
      expect(tapped, true);
    });

    testWidgets('displays different status colors correctly', (WidgetTester tester) async {
      final testCases = [
        {'status': 'Доставлено и ожидает оплаты', 'expectedText': 'Доставлено'},
        {'status': 'Возврат одобрен', 'expectedText': 'Возврат'},
        {'status': 'Оператор подтвердил и в процессе комплектации', 'expectedText': 'В процессе'},
        {'status': 'Срок доставки истёк', 'expectedText': 'Истек'},
        {'status': 'Новый', 'expectedText': 'Новый'},
      ];

      for (final testCase in testCases) {
        final status = testCase['status'] as String;
        final expectedText = testCase['expectedText'] as String;
        final orderWithStatus = testOrder.copyWith(mainStatus: status);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: OrderCardWidget(
                order: orderWithStatus,
                isGridView: false,
              ),
            ),
          ),
        );

        // Check if status text is displayed
        expect(find.text(expectedText), findsOneWidget);

        // Reset for next test
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('displays price type when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: OrderCardWidget(
              order: testOrder,
              isGridView: false,
            ),
          ),
        ),
      );

      // Check if price type is displayed
      expect(find.text('Цена PS опт'), findsOneWidget);
    });

    testWidgets('handles empty price type gracefully', (WidgetTester tester) async {
      final orderWithoutPriceType = testOrder.copyWith(typePriceCode: '');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: OrderCardWidget(
              order: orderWithoutPriceType,
              isGridView: false,
            ),
          ),
        ),
      );

      // Should not crash and should not display price type section
      expect(find.text('Цена PS опт'), findsNothing);
    });

    testWidgets('formats numbers correctly', (WidgetTester tester) async {
      final largeAmountOrder = testOrder.copyWith(total: 1234567.89);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: OrderCardWidget(
              order: largeAmountOrder,
              isGridView: false,
            ),
          ),
        ),
      );

      // Check if large number is formatted with spaces
      expect(find.textContaining('1 234 568 UZS'), findsOneWidget);
    });
  });
}