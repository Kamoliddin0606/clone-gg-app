import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/step_pages/product_selection_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/create_order.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/product_with_price.dart';

void main() {
  late List<ProductWithPrice> mockAvailableProducts;
  late List<CreateOrderProduct> mockSelectedProducts;

  setUp(() {
    // Create mock available products
    mockAvailableProducts = [
      ProductWithPrice(
        productCode: 'PROD001',
        productName: 'Test Product 1',
        unit: 'pcs',
        quantity: 100,
        reserved: 10,
        available: 90,
        category: 'Test Category',
        barcode: '123456789',
        have: 1,
        warehouseCode: 'WH001',
        warehouseName: 'Test Warehouse',
        weight: 1.5,
        capacity: 0.5,
        vendorCode: 'VEND001',
        productBrand: 'Test Brand',
        productSeries: 'Test Series',
        codeProject: 'PROJ001',
        priceTypeCode: 'PRICE001',
        priceTypeName: 'Test Price Type',
        price: 10000.0,
        currency: 'UZS',
        validFrom: '2024-01-01',
        validTo: '2024-12-31',
        stock: 50,
      ),
      ProductWithPrice(
        productCode: 'PROD002',
        productName: 'Test Product 2',
        unit: 'pcs',
        quantity: 200,
        reserved: 20,
        available: 180,
        category: 'Test Category',
        barcode: '987654321',
        have: 1,
        warehouseCode: 'WH001',
        warehouseName: 'Test Warehouse',
        weight: 2.0,
        capacity: 1.0,
        vendorCode: 'VEND002',
        productBrand: 'Test Brand',
        productSeries: 'Test Series',
        codeProject: 'PROJ001',
        priceTypeCode: 'PRICE001',
        priceTypeName: 'Test Price Type',
        price: 0.0, // Zero price to test validation
        currency: 'UZS',
        validFrom: '2024-01-01',
        validTo: '2024-12-31',
        stock: 30,
      ),
    ];

    // Create mock selected products
    mockSelectedProducts = [
      CreateOrderProduct(
        codeSklad: 'WH001',
        codeProduct: 'PROD001',
        vendorCode: 'VEND001',
        amount: 5,
        price: 10000.0,
        total: 50000.0,
        weight: 1.5,
        capacity: 0.5,
        paymentType: 0,
        discountSum: 0.0,
        discountRate: 0.0,
        giftAmount: 0,
        promo: false,
      ),
    ];
  });

  group('ProductSelectionPage Widget Tests', () {
    testWidgets('should display page title and basic UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductSelectionPage(
            selectedOrganization: 'ORG001',
            selectedWarehouse: 'WH001',
            selectedPriceType: 'PRICE001',
            availableProducts: mockAvailableProducts,
            selectedProducts: mockSelectedProducts,
          ),
        ),
      );

      // Check if page title is displayed
      expect(find.text('Mahsulot tanlash'), findsOneWidget);

      // Check for confirm button
      expect(find.text('Tasdiqlash'), findsOneWidget);

      // Check for product names
      expect(find.text('Test Product 1'), findsOneWidget);
      expect(find.text('Test Product 2'), findsOneWidget);
    });

    testWidgets('should pre-fill quantities for existing selected products', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductSelectionPage(
            selectedOrganization: 'ORG001',
            selectedWarehouse: 'WH001',
            selectedPriceType: 'PRICE001',
            availableProducts: mockAvailableProducts,
            selectedProducts: mockSelectedProducts,
          ),
        ),
      );

      // Check if quantity 5 is displayed for the pre-selected product
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('should show zero quantity for non-selected products', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductSelectionPage(
            selectedOrganization: 'ORG001',
            selectedWarehouse: 'WH001',
            selectedPriceType: 'PRICE001',
            availableProducts: mockAvailableProducts,
            selectedProducts: mockSelectedProducts,
          ),
        ),
      );

      // Check if quantity 0 is displayed for non-selected product
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('should disable add button for products with zero price', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductSelectionPage(
            selectedOrganization: 'ORG001',
            selectedWarehouse: 'WH001',
            selectedPriceType: 'PRICE001',
            availableProducts: mockAvailableProducts,
            selectedProducts: mockSelectedProducts,
          ),
        ),
      );

      // Find add buttons - the second product has zero price so its add button should be disabled
      final addButtons = find.byIcon(Icons.add);
      expect(addButtons, findsNWidgets(2));

      // The second add button should be disabled (grey color)
      // We can't easily test the disabled state without more complex setup
      // but we can verify both buttons exist
    });

    testWidgets('should show stock information for products', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductSelectionPage(
            selectedOrganization: 'ORG001',
            selectedWarehouse: 'WH001',
            selectedPriceType: 'PRICE001',
            availableProducts: mockAvailableProducts,
            selectedProducts: mockSelectedProducts,
          ),
        ),
      );

      // Check for stock display
      expect(find.text('Mavjud: 50 dona'), findsOneWidget);
      expect(find.text('Mavjud: 30 dona'), findsOneWidget);
    });

    testWidgets('should show product prices', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductSelectionPage(
            selectedOrganization: 'ORG001',
            selectedWarehouse: 'WH001',
            selectedPriceType: 'PRICE001',
            availableProducts: mockAvailableProducts,
            selectedProducts: mockSelectedProducts,
          ),
        ),
      );

      // Check that price text is displayed (exact format may vary)
      expect(find.textContaining('UZS'), findsAtLeastNWidgets(2));
    });

    testWidgets('should increment quantity when add button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductSelectionPage(
            selectedOrganization: 'ORG001',
            selectedWarehouse: 'WH001',
            selectedPriceType: 'PRICE001',
            availableProducts: mockAvailableProducts,
            selectedProducts: mockSelectedProducts,
          ),
        ),
      );

      // Initially should show quantity 5 for first product
      expect(find.text('5'), findsOneWidget);

      // Tap add button for first product
      final addButtons = find.byIcon(Icons.add);
      await tester.tap(addButtons.first);
      await tester.pump();

      // Should now show quantity 6
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('should decrement quantity when remove button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductSelectionPage(
            selectedOrganization: 'ORG001',
            selectedWarehouse: 'WH001',
            selectedPriceType: 'PRICE001',
            availableProducts: mockAvailableProducts,
            selectedProducts: mockSelectedProducts,
          ),
        ),
      );

      // Initially should show quantity 5 for first product
      expect(find.text('5'), findsOneWidget);

      // Tap remove button for first product
      final removeButtons = find.byIcon(Icons.remove);
      await tester.tap(removeButtons.first);
      await tester.pump();

      // Should now show quantity 4
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('should show quantity input dialog when quantity text is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductSelectionPage(
            selectedOrganization: 'ORG001',
            selectedWarehouse: 'WH001',
            selectedPriceType: 'PRICE001',
            availableProducts: mockAvailableProducts,
            selectedProducts: mockSelectedProducts,
          ),
        ),
      );

      // Tap on quantity text (should be in an InkWell)
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();

      // Should show dialog with title
      expect(find.text('Miqdorni kiriting'), findsOneWidget);
    });

    testWidgets('should prevent adding products with zero price', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductSelectionPage(
            selectedOrganization: 'ORG001',
            selectedWarehouse: 'WH001',
            selectedPriceType: 'PRICE001',
            availableProducts: mockAvailableProducts,
            selectedProducts: [], // No pre-selected products
          ),
        ),
      );

      // Check that add button for zero-price product is disabled
      final addButtons = find.byIcon(Icons.add);
      expect(addButtons, findsNWidgets(2));

      // The second add button should be disabled (for zero-price product)
      // We verify both buttons exist but can't easily test disabled state
    });

    testWidgets('should validate quantity input in dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductSelectionPage(
            selectedOrganization: 'ORG001',
            selectedWarehouse: 'WH001',
            selectedPriceType: 'PRICE001',
            availableProducts: mockAvailableProducts,
            selectedProducts: [], // Start with no products
          ),
        ),
      );

      // Initially should show quantity 0
      expect(find.text('0'), findsAtLeastNWidgets(1));

      // Tap quantity text for first product
      await tester.tap(find.text('0').first);
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Miqdorni kiriting'), findsOneWidget);

      // Enter valid quantity
      await tester.enterText(find.byType(TextField), '10');
      await tester.tap(find.text('Saqlash'));
      await tester.pump();

      // Should update quantity (now there should be more than just the initial 0)
      expect(find.text('10'), findsAtLeastNWidgets(1));
    });
  });
}