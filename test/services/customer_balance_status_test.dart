// Pure-function tests for the M12 (rebuilt) status calculator. The
// calculator is the single source of truth for the visual state shared by
// the trading-points list/grid, the detail sheet header and the visit-step
// "create order" tile.

import 'package:flutter_test/flutter_test.dart';

import 'package:gloria_marketing_flutter/src/features/agent/services/customer_balance_status.dart';

void main() {
  group('computeCustomerBalanceStatus', () {
    test('null balance → unknown', () {
      expect(
        computeCustomerBalanceStatus(balance: null, limit: 5000000),
        CustomerBalanceStatus.unknown,
      );
    });

    test('zero balance → noDebt regardless of limit', () {
      expect(
        computeCustomerBalanceStatus(balance: 0, limit: 5000000),
        CustomerBalanceStatus.noDebt,
      );
      expect(
        computeCustomerBalanceStatus(balance: 0, limit: null),
        CustomerBalanceStatus.noDebt,
      );
    });

    test('overpayment (negative balance) → noDebt', () {
      expect(
        computeCustomerBalanceStatus(balance: -2250, limit: 5000000),
        CustomerBalanceStatus.noDebt,
      );
    });

    test('positive balance with no limit set → noDebt', () {
      // Passport §5: limit absent ⇒ blocked = false. Mirror it visually.
      expect(
        computeCustomerBalanceStatus(balance: 1000000, limit: null),
        CustomerBalanceStatus.noDebt,
      );
    });

    test('balance under limit → debtUnderLimit (amber)', () {
      expect(
        computeCustomerBalanceStatus(balance: 1000000, limit: 5000000),
        CustomerBalanceStatus.debtUnderLimit,
      );
    });

    test('balance equal to limit → debtUnderLimit (boundary)', () {
      // Passport formula is `balance > limit` — equality is NOT over.
      expect(
        computeCustomerBalanceStatus(balance: 5000000, limit: 5000000),
        CustomerBalanceStatus.debtUnderLimit,
      );
    });

    test('balance just over limit → debtOverLimit (red)', () {
      expect(
        computeCustomerBalanceStatus(balance: 5000001, limit: 5000000),
        CustomerBalanceStatus.debtOverLimit,
      );
    });

    test('balance well over limit → debtOverLimit', () {
      expect(
        computeCustomerBalanceStatus(balance: 12000000, limit: 5000000),
        CustomerBalanceStatus.debtOverLimit,
      );
    });
  });
}
