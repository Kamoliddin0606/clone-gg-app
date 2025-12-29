/// ============================================================================
/// Client Balance Service Tests
/// ============================================================================
/// Bu fayl ClientBalanceService uchun unit va integration testlarni o'z ichiga oladi.
/// 
/// Test kategoriyalari:
/// 1. Model testlari - ClientBalance, ClientBalanceByContract, ClientBalanceByOrder
/// 2. State testlari - ClientBalanceState, ClientBalanceStatus
/// 3. Edge case testlari - network error, empty data, timeout
/// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_balance.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/bloc/client_balance_state.dart';

void main() {
  group('ClientBalance Model Tests', () {
    test('ClientBalance.empty should create empty balance with given INN', () {
      const testInn = '123456789';
      final balance = ClientBalance.empty(testInn);

      expect(balance.inn, testInn);
      expect(balance.balance, 0.0);
      expect(balance.contractBalances, isEmpty);
      expect(balance.orderBalances, isEmpty);
      expect(balance.isDebtor, false);
      expect(balance.hasOverpayment, false);
      expect(balance.isZeroBalance, true);
    });

    test('ClientBalance.isDebtor should return true for positive balance', () {
      // Biznes logika: musbat balance = mijoz qarzdor
      final balance = ClientBalance(
        inn: '123456789',
        balance: 1000.0, // Musbat = qarzdor
        contractBalances: [],
        orderBalances: [],
        lastUpdated: DateTime.now(),
        projectName: 'Test',
      );

      expect(balance.isDebtor, true);
      expect(balance.hasOverpayment, false);
      expect(balance.absoluteBalance, 1000.0);
    });

    test('ClientBalance.hasOverpayment should return true for negative balance', () {
      // Biznes logika: manfiy balance = ortiqcha to'lov
      final balance = ClientBalance(
        inn: '123456789',
        balance: -500.0, // Manfiy = ortiqcha to'lov
        contractBalances: [],
        orderBalances: [],
        lastUpdated: DateTime.now(),
        projectName: 'Test',
      );

      expect(balance.isDebtor, false);
      expect(balance.hasOverpayment, true);
      expect(balance.absoluteBalance, 500.0);
    });

    test('ClientBalance.fromJson should parse JSON correctly', () {
      final json = {
        'inn': '987654321',
        'balance': -2500.0,
        'contract_balances': [
          {
            'project_name': 'Evyap',
            'region': 'Tashkent',
            'tax_id': '987654321',
            'customer_name': 'Test Client',
            'contract_code': 'C001',
            'payment_amount': 1000.0,
            'debt_amount': 500.0,
            'contract_id': 'CT001',
          }
        ],
        'order_balances': [
          {
            'project_name': 'Evyap',
            'region': 'Tashkent',
            'tax_id': '987654321',
            'customer_name': 'Test Client',
            'contract_code': 'C001',
            'sales_channel': 'Direct',
            'order_number': 'O001',
            'order_date': '2024-01-15T00:00:00.000',
            'order_amount': 1500.0,
            'payment_amount': 1000.0,
            'debt_amount': 500.0,
            'status': 'Частично',
            'overdue_days': 5,
            'contract_id': 'CT001',
          }
        ],
        'last_updated': '2024-01-20T10:30:00.000',
        'project_name': 'Evyap',
      };

      final balance = ClientBalance.fromJson(json);

      expect(balance.inn, '987654321');
      expect(balance.balance, -2500.0);
      expect(balance.contractBalances.length, 1);
      expect(balance.orderBalances.length, 1);
      expect(balance.projectName, 'Evyap');
      // Biznes logika: manfiy balance = ortiqcha to'lov
      expect(balance.hasOverpayment, true);
      expect(balance.isDebtor, false);
    });

    test('ClientBalance.toJson should convert to JSON correctly', () {
      final balance = ClientBalance(
        inn: '111222333',
        balance: -1500.0,
        contractBalances: [],
        orderBalances: [],
        lastUpdated: DateTime(2024, 1, 20, 10, 30),
        projectName: 'Test Project',
      );

      final json = balance.toJson();

      expect(json['inn'], '111222333');
      expect(json['balance'], -1500.0);
      expect(json['project_name'], 'Test Project');
      expect(json['contract_balances'], isEmpty);
      expect(json['order_balances'], isEmpty);
    });

    test('ClientBalance statistics should calculate correctly', () {
      final orders = [
        ClientBalanceByOrder(
          projectName: 'Test',
          region: 'Tashkent',
          taxId: '123',
          customerName: 'Client',
          contractCode: 'C001',
          salesChannel: 'Direct',
          orderNumber: 'O001',
          orderDate: DateTime.now(),
          orderAmount: 1000.0,
          paymentAmount: 1000.0,
          debtAmount: 0.0,
          status: 'Оплачено',
          overdueDays: 0,
          contractId: 'CT001',
        ),
        ClientBalanceByOrder(
          projectName: 'Test',
          region: 'Tashkent',
          taxId: '123',
          customerName: 'Client',
          contractCode: 'C001',
          salesChannel: 'Direct',
          orderNumber: 'O002',
          orderDate: DateTime.now(),
          orderAmount: 2000.0,
          paymentAmount: 500.0,
          debtAmount: 1500.0,
          status: 'Частично',
          overdueDays: 10,
          contractId: 'CT001',
        ),
        ClientBalanceByOrder(
          projectName: 'Test',
          region: 'Tashkent',
          taxId: '123',
          customerName: 'Client',
          contractCode: 'C001',
          salesChannel: 'Direct',
          orderNumber: 'O003',
          orderDate: DateTime.now(),
          orderAmount: 500.0,
          paymentAmount: 0.0,
          debtAmount: 500.0,
          status: 'Неоплачен',
          overdueDays: 0,
          contractId: 'CT001',
        ),
      ];

      final balance = ClientBalance(
        inn: '123',
        balance: -2000.0,
        contractBalances: [],
        orderBalances: orders,
        lastUpdated: DateTime.now(),
        projectName: 'Test',
      );

      expect(balance.totalOrderAmount, 3500.0);
      expect(balance.totalPaymentAmount, 1500.0);
      expect(balance.totalDebtAmount, 2000.0);
      expect(balance.unpaidOrdersCount, 1); // Only Неоплачен
      expect(balance.partiallyPaidOrdersCount, 1); // Only Частично
      expect(balance.overdueOrdersCount, 1); // Only one with overdueDays > 0
    });
  });

  group('ClientBalanceByContract Tests', () {
    test('fromJson should parse correctly', () {
      final json = {
        'project_name': 'Evyap',
        'region': 'Samarkand',
        'tax_id': '555666777',
        'customer_name': 'Test Customer',
        'contract_code': 'CONTRACT001',
        'payment_amount': 5000.0,
        'debt_amount': 1000.0,
        'contract_id': 'CID001',
      };

      final contract = ClientBalanceByContract.fromJson(json);

      expect(contract.projectName, 'Evyap');
      expect(contract.region, 'Samarkand');
      expect(contract.taxId, '555666777');
      expect(contract.customerName, 'Test Customer');
      expect(contract.contractCode, 'CONTRACT001');
      expect(contract.paymentAmount, 5000.0);
      expect(contract.debtAmount, 1000.0);
      expect(contract.contractId, 'CID001');
    });

    test('toJson should convert correctly', () {
      final contract = ClientBalanceByContract(
        projectName: 'PPD',
        region: 'Bukhara',
        taxId: '888999000',
        customerName: 'Another Customer',
        contractCode: 'C002',
        paymentAmount: 3000.0,
        debtAmount: 500.0,
        contractId: 'CID002',
      );

      final json = contract.toJson();

      expect(json['project_name'], 'PPD');
      expect(json['region'], 'Bukhara');
      expect(json['payment_amount'], 3000.0);
      expect(json['debt_amount'], 500.0);
    });
  });

  group('ClientBalanceByOrder Tests', () {
    test('fromJson should parse correctly', () {
      final json = {
        'project_name': 'Garnier',
        'region': 'Fergana',
        'tax_id': '111222333',
        'customer_name': 'Order Customer',
        'contract_code': 'C003',
        'sales_channel': 'Retail',
        'order_number': 'ORD001',
        'order_date': '2024-02-01T00:00:00.000',
        'order_amount': 2500.0,
        'payment_amount': 1500.0,
        'debt_amount': 1000.0,
        'status': 'Частично',
        'overdue_days': 15,
        'contract_id': 'CID003',
      };

      final order = ClientBalanceByOrder.fromJson(json);

      expect(order.projectName, 'Garnier');
      expect(order.region, 'Fergana');
      expect(order.orderNumber, 'ORD001');
      expect(order.orderAmount, 2500.0);
      expect(order.paymentAmount, 1500.0);
      expect(order.debtAmount, 1000.0);
      expect(order.status, 'Частично');
      expect(order.overdueDays, 15);
      expect(order.isPartiallyPaid, true);
      expect(order.isPaid, false);
      expect(order.isUnpaid, false);
      expect(order.isOverdue, true);
    });

    test('status helpers should work correctly', () {
      final paidOrder = ClientBalanceByOrder(
        projectName: 'Test',
        region: 'Test',
        taxId: '123',
        customerName: 'Test',
        contractCode: 'C001',
        salesChannel: 'Direct',
        orderNumber: 'O001',
        orderAmount: 1000.0,
        paymentAmount: 1000.0,
        debtAmount: 0.0,
        status: 'Оплачено',
        overdueDays: 0,
        contractId: 'CT001',
      );

      expect(paidOrder.isPaid, true);
      expect(paidOrder.isPartiallyPaid, false);
      expect(paidOrder.isUnpaid, false);
      expect(paidOrder.isOverdue, false);

      final unpaidOrder = ClientBalanceByOrder(
        projectName: 'Test',
        region: 'Test',
        taxId: '123',
        customerName: 'Test',
        contractCode: 'C001',
        salesChannel: 'Direct',
        orderNumber: 'O002',
        orderAmount: 1000.0,
        paymentAmount: 0.0,
        debtAmount: 1000.0,
        status: 'Неоплачен',
        overdueDays: 5,
        contractId: 'CT001',
      );

      expect(unpaidOrder.isPaid, false);
      expect(unpaidOrder.isPartiallyPaid, false);
      expect(unpaidOrder.isUnpaid, true);
      expect(unpaidOrder.isOverdue, true);
    });
  });

  // ===========================================================================
  // ClientBalanceState Tests
  // ===========================================================================
  group('ClientBalanceState Tests', () {
    test('initial state should have correct defaults', () {
      final state = ClientBalanceState.initial();

      expect(state.status, ClientBalanceStatus.initial);
      expect(state.balance, isNull);
      expect(state.errorMessage, isNull);
      expect(state.canRefresh, true);
      expect(state.remainingSeconds, 0);
      expect(state.isLoading, false);
      expect(state.hasData, false);
      expect(state.hasError, false);
    });

    test('toLoading should update status correctly', () {
      final state = ClientBalanceState.initial().toLoading();

      expect(state.status, ClientBalanceStatus.loading);
      expect(state.isLoading, true);
      expect(state.errorMessage, isNull);
    });

    test('toSuccess should update state with balance', () {
      final balance = ClientBalance(
        inn: '123',
        balance: -1000.0,
        contractBalances: [],
        orderBalances: [],
        lastUpdated: DateTime.now(),
        projectName: 'Test',
      );

      final state = ClientBalanceState.initial().toSuccess(balance);

      expect(state.status, ClientBalanceStatus.success);
      expect(state.balance, balance);
      expect(state.hasData, true);
      expect(state.canRefresh, false);
      expect(state.lastFetchTime, isNotNull);
    });

    test('toError should set error message and type', () {
      final state = ClientBalanceState.initial().toError(
        'Network error',
        type: ClientBalanceErrorType.network,
      );

      expect(state.status, ClientBalanceStatus.error);
      expect(state.errorMessage, 'Network error');
      expect(state.errorType, ClientBalanceErrorType.network);
      expect(state.hasError, true);
    });

    test('toRefreshing should keep existing data', () {
      final balance = ClientBalance(
        inn: '123',
        balance: -500.0,
        contractBalances: [],
        orderBalances: [],
        lastUpdated: DateTime.now(),
        projectName: 'Test',
      );

      final state = ClientBalanceState.initial()
          .toSuccess(balance)
          .toRefreshing();

      expect(state.status, ClientBalanceStatus.refreshing);
      expect(state.balance, balance);
      expect(state.hasData, true);
      expect(state.isLoading, true);
    });

    test('updateCountdown should update remaining seconds', () {
      final state = ClientBalanceState.initial().updateCountdown(10);

      expect(state.remainingSeconds, 10);
      expect(state.canRefresh, false);

      final state2 = state.updateCountdown(0);
      expect(state2.remainingSeconds, 0);
      expect(state2.canRefresh, true);
    });

    test('copyWith should preserve unmodified fields', () {
      final balance = ClientBalance(
        inn: '123',
        balance: -1000.0,
        contractBalances: [],
        orderBalances: [],
        lastUpdated: DateTime.now(),
        projectName: 'Test',
      );

      final state = ClientBalanceState(
        status: ClientBalanceStatus.success,
        balance: balance,
        canRefresh: false,
        remainingSeconds: 5,
      );

      final newState = state.copyWith(remainingSeconds: 3);

      expect(newState.status, ClientBalanceStatus.success);
      expect(newState.balance, balance);
      expect(newState.canRefresh, false);
      expect(newState.remainingSeconds, 3);
    });
  });

  // ===========================================================================
  // ClientBalanceErrorType Tests
  // ===========================================================================
  group('ClientBalanceErrorType Tests', () {
    test('network error should be retryable', () {
      expect(ClientBalanceErrorType.network.canRetry, true);
      expect(ClientBalanceErrorType.network.userMessage, isNotEmpty);
    });

    test('server error should be retryable', () {
      expect(ClientBalanceErrorType.server.canRetry, true);
    });

    test('timeout error should be retryable', () {
      expect(ClientBalanceErrorType.timeout.canRetry, true);
    });

    test('notFound error should not be retryable', () {
      expect(ClientBalanceErrorType.notFound.canRetry, false);
    });

    test('invalidData error should not be retryable', () {
      expect(ClientBalanceErrorType.invalidData.canRetry, false);
    });

    test('unknown error should not be retryable', () {
      expect(ClientBalanceErrorType.unknown.canRetry, false);
    });

    test('all error types should have user messages', () {
      for (final errorType in ClientBalanceErrorType.values) {
        expect(errorType.userMessage, isNotEmpty);
      }
    });
  });

  // ===========================================================================
  // Edge Case Tests
  // ===========================================================================
  group('Edge Case Tests', () {
    test('ClientBalance with empty INN should handle gracefully', () {
      final balance = ClientBalance.empty('');

      expect(balance.inn, '');
      expect(balance.balance, 0.0);
      expect(balance.isZeroBalance, true);
    });

    test('ClientBalance with null values in JSON should use defaults', () {
      final json = <String, dynamic>{
        'inn': null,
        'balance': null,
        'contract_balances': null,
        'order_balances': null,
        'last_updated': null,
        'project_name': null,
      };

      final balance = ClientBalance.fromJson(json);

      expect(balance.inn, '');
      expect(balance.balance, 0.0);
      expect(balance.contractBalances, isEmpty);
      expect(balance.orderBalances, isEmpty);
      expect(balance.projectName, '');
    });

    test('ClientBalanceByOrder with extreme overdue days', () {
      final order = ClientBalanceByOrder(
        projectName: 'Test',
        region: 'Test',
        taxId: '123',
        customerName: 'Test',
        contractCode: 'C001',
        salesChannel: 'Direct',
        orderNumber: 'O001',
        orderAmount: 1000.0,
        paymentAmount: 0.0,
        debtAmount: 1000.0,
        status: 'Неоплачен',
        overdueDays: 365,
        contractId: 'CT001',
      );

      expect(order.isOverdue, true);
      expect(order.overdueDays, 365);
    });

    test('ClientBalance with very large amounts', () {
      // Biznes logika: musbat balance = qarzdor
      final balance = ClientBalance(
        inn: '123',
        balance: 999999999999.99, // Musbat = qarzdor
        contractBalances: [],
        orderBalances: [],
        lastUpdated: DateTime.now(),
        projectName: 'Test',
      );

      expect(balance.isDebtor, true);
      expect(balance.absoluteBalance, 999999999999.99);
    });

    test('ClientBalance with zero payment and debt', () {
      final balance = ClientBalance(
        inn: '123',
        balance: 0.0,
        contractBalances: [],
        orderBalances: [],
        lastUpdated: DateTime.now(),
        projectName: 'Test',
      );

      expect(balance.isZeroBalance, true);
      expect(balance.isDebtor, false);
      expect(balance.hasOverpayment, false);
      expect(balance.totalDebtAmount, 0.0);
      expect(balance.totalPaymentAmount, 0.0);
    });

    test('ClientBalanceState transitions should be consistent', () {
      // Initial -> Loading -> Success
      var state = ClientBalanceState.initial();
      expect(state.status, ClientBalanceStatus.initial);

      state = state.toLoading();
      expect(state.status, ClientBalanceStatus.loading);

      final balance = ClientBalance.empty('123');
      state = state.toSuccess(balance);
      expect(state.status, ClientBalanceStatus.success);

      // Success -> Refreshing -> Success
      state = state.toRefreshing();
      expect(state.status, ClientBalanceStatus.refreshing);
      expect(state.hasData, true);

      state = state.toSuccess(balance);
      expect(state.status, ClientBalanceStatus.success);

      // Success -> Error (with data preserved)
      state = state.copyWith(
        status: ClientBalanceStatus.error,
        errorMessage: 'Refresh failed',
      );
      expect(state.status, ClientBalanceStatus.error);
      expect(state.hasData, true); // Data preserved
    });
  });
}
