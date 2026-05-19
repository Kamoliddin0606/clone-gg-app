import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/create_order.dart';
import 'package:gloria_marketing_flutter/src/features/visits/legacy/order_create_payload_adapter.dart';

CreateOrder _draft({List<CreateOrderProduct>? products}) => CreateOrder(
      codeAgent: 'U001',
      codeClient: 'TP-1',
      codePrice: 'PR-1',
      payment: 'cash',
      shippingDate: DateTime.utc(2026, 5, 18),
      createDate: DateTime.utc(2026, 5, 16, 12, 30),
      longitude: 69.27,
      latitude: 41.31,
      weight: 12.5,
      capacity: 0.05,
      credit: false,
      codeProject: 'evyap',
      orderType: 1,
      codeOrg: 'ORG-1',
      codeSklad: 'SK-1',
      codeContract: null,
      hasPromo: false,
      isSynced: false,
      products: products ??
          const [
            CreateOrderProduct(
              codeSklad: 'SK-1',
              codeProduct: 'P-100',
              vendorCode: 'V-100',
              amount: 4,
              price: 25000,
              total: 100000,
              weight: 5,
              capacity: 0.02,
              paymentType: 1,
              discountSum: 0,
              discountRate: 0,
              giftAmount: 0,
              promo: false,
            ),
            CreateOrderProduct(
              codeSklad: 'SK-1',
              codeProduct: 'P-200',
              vendorCode: 'V-200',
              amount: 2,
              price: 50000,
              total: 100000,
              weight: 7.5,
              capacity: 0.03,
              paymentType: 1,
              discountSum: 0,
              discountRate: 0,
              giftAmount: 0,
              promo: false,
            ),
          ],
      competitiveIntelligence: const [],
      creditDetails: const [],
    );

void main() {
  group('OrderCreatePayloadAdapter', () {
    test('empty payload when draft is null', () {
      final payload = OrderCreatePayloadAdapter.fromCreateOrder(null);
      expect(payload['products'], isEmpty);
      expect(payload['total_uzs'], 0);
      expect(payload['total_weight_kg'], 0);
    });

    test('maps SOAP field names to v2 schema keys', () {
      final payload = OrderCreatePayloadAdapter.fromCreateOrder(_draft());
      expect(payload['code_price'], 'PR-1');
      expect(payload['code_sklad'], 'SK-1');
      expect(payload['payment'], 'cash');
      expect(payload['credit'], false);
      expect(payload['shipping_date'], '2026-05-18');
    });

    test('computes total_uzs from the product list', () {
      final payload = OrderCreatePayloadAdapter.fromCreateOrder(_draft());
      expect(payload['total_uzs'], 200000.0);
    });

    test('flattens product rows to product_code_1c / quantity / price_uzs',
        () {
      final payload = OrderCreatePayloadAdapter.fromCreateOrder(_draft());
      final products = payload['products'] as List;
      expect(products.length, 2);
      final first = products.first as Map<String, dynamic>;
      expect(first['product_code_1c'], 'P-100');
      expect(first['quantity'], 4);
      expect(first['price_uzs'], 25000);
      expect(first['total_uzs'], 100000);
    });

    test('omits optional comments when null', () {
      final payload = OrderCreatePayloadAdapter.fromCreateOrder(_draft());
      expect(payload.containsKey('comment'), isFalse);
      expect(payload.containsKey('code_contract'), isTrue); // null-allowed key kept
      expect(payload['code_contract'], isNull);
    });
  });
}
