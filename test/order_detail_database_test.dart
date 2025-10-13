import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/order_detail.dart';

void main() {
  // Initialize sqflite_common_ffi for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late ApiDatabaseService dbService;

  setUp(() async {
    dbService = ApiDatabaseService();
    // Clear all data before each test
    await dbService.clearAllData();
  });

  tearDown(() async {
    // Clean up after each test
    await dbService.clearAllData();
  });

  group('OrderDetail Database Tests', () {
    test('saveOrderDetails and getOrderDetails work correctly', () async {
      // Create test order details
      final orderDetail = OrderDetail(
        numOrder: 'TS00-020980',
        credit: false,
        codePrice: '00000000003',
        dateOrder: DateTime.parse('2025-10-13T13:35:20'),
        codeSklad: '00000000015',
        commentSupervisor: null,
        commentForwarder: null,
        commentAgent: null,
        shippingDate: '2025-10-14T00:00:00',
        orderType: 3,
        codeOrg: '00000000002',
        productRows: [
          OrderDetailProduct(
            codeProduct: '00-00000648',
            nameProduct: 'Туалетное Мыло Duru Fresh Sen Ocean Bre. Pvc 100Gr*4*16',
            amount: 4,
            price: 25495,
            total: 101980,
            discountRate: 0,
            weight: 1.8,
            capacity: 0.0048,
          ),
          OrderDetailProduct(
            codeProduct: '00-00000647',
            nameProduct: 'Детские подгузники Evy Baby Junior Jumbo 46*4 EXP21 №5',
            amount: 2,
            price: 115000,
            total: 230000,
            discountRate: 0,
            weight: 3.31,
            capacity: 0.0246,
          ),
        ],
        creditDetailsList: [
          OrderPayment(
            dateOfPayment: '20251014000000',
            total: 331980,
          ),
        ],
      );

      // Save order details
      await dbService.saveOrderDetails([orderDetail]);

      // Retrieve order details
      final retrievedOrderDetails = await dbService.getOrderDetails();

      // Verify the data
      expect(retrievedOrderDetails.length, 1);
      final retrieved = retrievedOrderDetails.first;

      expect(retrieved.numOrder, 'TS00-020980');
      expect(retrieved.credit, false);
      expect(retrieved.codePrice, '00000000003');
      expect(retrieved.codeSklad, '00000000015');
      expect(retrieved.orderType, 3);
      expect(retrieved.codeOrg, '00000000002');

      // Verify product rows
      expect(retrieved.productRows.length, 2);
      final firstProduct = retrieved.productRows[0];
      expect(firstProduct.codeProduct, '00-00000648');
      expect(firstProduct.nameProduct, 'Туалетное Мыло Duru Fresh Sen Ocean Bre. Pvc 100Gr*4*16');
      expect(firstProduct.amount, 4);
      expect(firstProduct.price, 25495);
      expect(firstProduct.total, 101980);

      final secondProduct = retrieved.productRows[1];
      expect(secondProduct.codeProduct, '00-00000647');
      expect(secondProduct.nameProduct, 'Детские подгузники Evy Baby Junior Jumbo 46*4 EXP21 №5');
      expect(secondProduct.amount, 2);
      expect(secondProduct.price, 115000);
      expect(secondProduct.total, 230000);

      // Verify payment details
      expect(retrieved.creditDetailsList.length, 1);
      final payment = retrieved.creditDetailsList[0];
      expect(payment.dateOfPayment, '20251014000000');
      expect(payment.total, 331980);
    });

    test('getOrderDetailByNumOrder returns correct order detail', () async {
      // Create and save test order detail
      final orderDetail = OrderDetail(
        numOrder: 'TS00-020980',
        credit: false,
        codePrice: '00000000003',
        dateOrder: DateTime.parse('2025-10-13T13:35:20'),
        codeSklad: '00000000015',
        commentSupervisor: null,
        commentForwarder: null,
        commentAgent: null,
        shippingDate: '2025-10-14T00:00:00',
        orderType: 3,
        codeOrg: '00000000002',
        productRows: [
          OrderDetailProduct(
            codeProduct: '00-00000648',
            nameProduct: 'Test Product',
            amount: 1,
            price: 10000,
            total: 10000,
            discountRate: 0,
            weight: 1.0,
            capacity: 0.001,
          ),
        ],
        creditDetailsList: [],
      );

      await dbService.saveOrderDetail(orderDetail);

      // Retrieve by num order
      final retrieved = await dbService.getOrderDetailByNumOrder('TS00-020980');

      // Verify the data
      expect(retrieved, isNotNull);
      expect(retrieved!.numOrder, 'TS00-020980');
      expect(retrieved.productRows.length, 1);
      expect(retrieved.productRows[0].codeProduct, '00-00000648');
    });

    test('getOrderDetailByNumOrder returns null for non-existent order', () async {
      final retrieved = await dbService.getOrderDetailByNumOrder('NON-EXISTENT');
      expect(retrieved, isNull);
    });

    test('saveOrderDetail works correctly', () async {
      final orderDetail = OrderDetail(
        numOrder: 'TS00-020980',
        credit: true,
        codePrice: '00000000003',
        dateOrder: DateTime.parse('2025-10-13T13:35:20'),
        codeSklad: '00000000015',
        commentSupervisor: 'Supervisor comment',
        commentForwarder: 'Forwarder comment',
        commentAgent: 'Agent comment',
        shippingDate: '2025-10-14T00:00:00',
        orderType: 3,
        codeOrg: '00000000002',
        productRows: [
          OrderDetailProduct(
            codeProduct: '00-00000648',
            nameProduct: 'Test Product',
            amount: 2,
            price: 50000,
            total: 100000,
            discountRate: 10,
            weight: 2.5,
            capacity: 0.005,
          ),
        ],
        creditDetailsList: [
          OrderPayment(
            dateOfPayment: '20251015000000',
            total: 90000,
          ),
        ],
      );

      await dbService.saveOrderDetail(orderDetail);

      final retrieved = await dbService.getOrderDetailByNumOrder('TS00-020980');
      expect(retrieved, isNotNull);
      expect(retrieved!.credit, true);
      expect(retrieved.commentSupervisor, 'Supervisor comment');
      expect(retrieved.commentForwarder, 'Forwarder comment');
      expect(retrieved.commentAgent, 'Agent comment');
      expect(retrieved.productRows[0].discountRate, 10);
      expect(retrieved.creditDetailsList[0].total, 90000);
    });

    test('updateOrderDetail works correctly', () async {
      // Create initial order detail
      final initialOrderDetail = OrderDetail(
        numOrder: 'TS00-020980',
        credit: false,
        codePrice: '00000000003',
        dateOrder: DateTime.parse('2025-10-13T13:35:20'),
        codeSklad: '00000000015',
        commentSupervisor: null,
        commentForwarder: null,
        commentAgent: null,
        shippingDate: '2025-10-14T00:00:00',
        orderType: 3,
        codeOrg: '00000000002',
        productRows: [
          OrderDetailProduct(
            codeProduct: '00-00000648',
            nameProduct: 'Initial Product',
            amount: 1,
            price: 10000,
            total: 10000,
            discountRate: 0,
            weight: 1.0,
            capacity: 0.001,
          ),
        ],
        creditDetailsList: [],
      );

      await dbService.saveOrderDetail(initialOrderDetail);

      // Update the order detail
      final updatedOrderDetail = OrderDetail(
        numOrder: 'TS00-020980',
        credit: true,
        codePrice: '00000000004',
        dateOrder: DateTime.parse('2025-10-14T14:35:20'),
        codeSklad: '00000000016',
        commentSupervisor: 'Updated supervisor comment',
        commentForwarder: 'Updated forwarder comment',
        commentAgent: 'Updated agent comment',
        shippingDate: '2025-10-15T00:00:00',
        orderType: 4,
        codeOrg: '00000000003',
        productRows: [
          OrderDetailProduct(
            codeProduct: '00-00000649',
            nameProduct: 'Updated Product',
            amount: 3,
            price: 20000,
            total: 60000,
            discountRate: 5,
            weight: 3.0,
            capacity: 0.006,
          ),
        ],
        creditDetailsList: [
          OrderPayment(
            dateOfPayment: '20251016000000',
            total: 57000,
          ),
        ],
      );

      await dbService.updateOrderDetail('TS00-020980', updatedOrderDetail);

      // Verify the update
      final retrieved = await dbService.getOrderDetailByNumOrder('TS00-020980');
      expect(retrieved, isNotNull);
      expect(retrieved!.credit, true);
      expect(retrieved.codePrice, '00000000004');
      expect(retrieved.codeSklad, '00000000016');
      expect(retrieved.commentSupervisor, 'Updated supervisor comment');
      expect(retrieved.commentForwarder, 'Updated forwarder comment');
      expect(retrieved.commentAgent, 'Updated agent comment');
      expect(retrieved.orderType, 4);
      expect(retrieved.codeOrg, '00000000003');

      expect(retrieved.productRows.length, 1);
      expect(retrieved.productRows[0].codeProduct, '00-00000649');
      expect(retrieved.productRows[0].nameProduct, 'Updated Product');
      expect(retrieved.productRows[0].amount, 3);
      expect(retrieved.productRows[0].price, 20000);
      expect(retrieved.productRows[0].total, 60000);
      expect(retrieved.productRows[0].discountRate, 5);

      expect(retrieved.creditDetailsList.length, 1);
      expect(retrieved.creditDetailsList[0].dateOfPayment, '20251016000000');
      expect(retrieved.creditDetailsList[0].total, 57000);
    });

    test('deleteOrderDetail works correctly', () async {
      // Create and save order detail
      final orderDetail = OrderDetail(
        numOrder: 'TS00-020980',
        credit: false,
        codePrice: '00000000003',
        dateOrder: DateTime.parse('2025-10-13T13:35:20'),
        codeSklad: '00000000015',
        commentSupervisor: null,
        commentForwarder: null,
        commentAgent: null,
        shippingDate: '2025-10-14T00:00:00',
        orderType: 3,
        codeOrg: '00000000002',
        productRows: [
          OrderDetailProduct(
            codeProduct: '00-00000648',
            nameProduct: 'Test Product',
            amount: 1,
            price: 10000,
            total: 10000,
            discountRate: 0,
            weight: 1.0,
            capacity: 0.001,
          ),
        ],
        creditDetailsList: [],
      );

      await dbService.saveOrderDetail(orderDetail);

      // Verify it exists
      var retrieved = await dbService.getOrderDetailByNumOrder('TS00-020980');
      expect(retrieved, isNotNull);

      // Delete the order detail
      await dbService.deleteOrderDetail('TS00-020980');

      // Verify it's deleted
      retrieved = await dbService.getOrderDetailByNumOrder('TS00-020980');
      expect(retrieved, isNull);
    });
  });
}