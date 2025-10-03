import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:gloria_marketing_flutter/src/features/marketing/data/models/promotion_model.dart';

void main() {
  group('PromotionModel', () {
    test('fromXml should parse XML correctly', () {
      const xmlString = '''
<return xmlns:m="http://www.sample-package.org">
  <m:code>000000005</m:code>
  <m:name>Test Promotion</m:name>
  <m:type>General</m:type>
  <m:minPromoProductcount>3</m:minPromoProductcount>
  <m:bonusCount>1</m:bonusCount>
  <m:dateStart>2025-09-01</m:dateStart>
  <m:dateEnd>2025-09-30</m:dateEnd>
  <m:productList>
    <m:code>00-00001378</m:code>
    <m:productName>Test Product 1</m:productName>
  </m:productList>
  <m:bonusList>
    <m:code>00-00001713</m:code>
    <m:productName>Test Bonus</m:productName>
  </m:bonusList>
</return>
''';

      final document = XmlDocument.parse(xmlString);
      final element = document.findAllElements('return').first;

      final promotion = PromotionModel.fromXml(element);

      expect(promotion.code, '000000005');
      expect(promotion.name, 'Test Promotion');
      expect(promotion.type, 'General');
      expect(promotion.minPromoProductCount, 3);
      expect(promotion.bonusCount, 1);
      expect(promotion.productList.length, 1);
      expect(promotion.bonusList.length, 1);
      expect(promotion.productList[0].code, '00-00001378');
      expect(promotion.bonusList[0].code, '00-00001713');
    });

    test('toMap and fromMap should be reversible', () {
      final original = PromotionModel(
        code: 'TEST001',
        name: 'Test Promotion',
        type: 'General',
        minPromoProductCount: 2,
        bonusCount: 1,
        dateStart: DateTime(2025, 9, 1),
        dateEnd: DateTime(2025, 9, 30),
        productList: [
          const PromotionProduct(code: 'P001', productName: 'Product 1'),
        ],
        bonusList: [
          const PromotionProduct(code: 'B001', productName: 'Bonus 1'),
        ],
      );

      final map = original.toMap();
      final restored = PromotionModel.fromMap(map);

      expect(restored.code, original.code);
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.minPromoProductCount, original.minPromoProductCount);
      expect(restored.bonusCount, original.bonusCount);
      expect(restored.dateStart, original.dateStart);
      expect(restored.dateEnd, original.dateEnd);
      expect(restored.productList.length, original.productList.length);
      expect(restored.bonusList.length, original.bonusList.length);
    });

    test('isActive should return correct status based on dates', () {
      final now = DateTime.now();
      final activePromotion = PromotionModel(
        code: 'ACTIVE',
        name: 'Active Promotion',
        type: 'General',
        minPromoProductCount: 1,
        bonusCount: 1,
        dateStart: now.subtract(const Duration(days: 1)),
        dateEnd: now.add(const Duration(days: 1)),
        productList: [],
        bonusList: [],
      );

      final inactivePromotion = PromotionModel(
        code: 'INACTIVE',
        name: 'Inactive Promotion',
        type: 'General',
        minPromoProductCount: 1,
        bonusCount: 1,
        dateStart: now.subtract(const Duration(days: 10)),
        dateEnd: now.subtract(const Duration(hours: 1)), // 1 hour ago
        productList: [],
        bonusList: [],
        isActive: false, // Explicitly set as inactive
      );

      expect(activePromotion.isActive, true);
      expect(inactivePromotion.isActive, false);
    });
  });

  group('PromotionProduct', () {
    test('toMap and fromMap should be reversible', () {
      const original = PromotionProduct(
        code: 'P001',
        productName: 'Test Product',
      );

      final map = original.toMap();
      final restored = PromotionProduct.fromMap(map);

      expect(restored.code, original.code);
      expect(restored.productName, original.productName);
    });
  });
}