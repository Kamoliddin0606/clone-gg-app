/// Customer-balance visual status used by the trading-points list/grid,
/// the customer detail sheet and the visit-steps "create order" tile.
///
/// The status is **pure** — given a balance and a project debt limit it
/// always returns the same value. The visual layer maps the status to a
/// background tint and an indicator dot.
///
/// See docs/customer-balance-mobile.md M12 (rebuilt) and Customer Balance
/// Passport §5 — the over-limit branch matches the gate's
/// `(balance > limit)` rule, so a customer that triggers a red card here
/// will also be blocked by [OrderBalanceGate.check].
enum CustomerBalanceStatus {
  /// No balance row for this customer yet — show no tint, no indicator.
  unknown,

  /// `balance <= 0` (overpayment or zero) **or** no project limit set →
  /// nothing to highlight.
  noDebt,

  /// Customer owes us money but is still within the project's debt limit.
  /// Surface as a soft amber tint + amber indicator.
  debtUnderLimit,

  /// Customer has exceeded the project's debt limit. Surface as a soft red
  /// tint + red indicator. Blocks the "create order" visit step.
  debtOverLimit,
}

/// Pure status calculation. [balance] is the cached `ClientBalance.balance`
/// for the customer (positive = debt, negative = overpayment per Passport
/// §2.2). [limit] is the active project's debt limit (`UserProject.debtLimit`
/// or the per-row `ClientBalance.debtLimit` if the backend echoed one).
///
/// Returns [CustomerBalanceStatus.unknown] only when `balance == null` —
/// the absence of a row in `client_balances` means we cannot compute.
CustomerBalanceStatus computeCustomerBalanceStatus({
  required double? balance,
  required double? limit,
}) {
  if (balance == null) return CustomerBalanceStatus.unknown;
  if (balance <= 0) return CustomerBalanceStatus.noDebt;
  if (limit == null) return CustomerBalanceStatus.noDebt;
  if (balance > limit) return CustomerBalanceStatus.debtOverLimit;
  return CustomerBalanceStatus.debtUnderLimit;
}
