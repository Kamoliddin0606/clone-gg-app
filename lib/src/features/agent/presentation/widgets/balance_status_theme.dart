import 'package:flutter/material.dart';

import 'package:gloria_marketing_flutter/src/features/agent/services/customer_balance_status.dart';

/// Visual mapping for [CustomerBalanceStatus] used by the trading-points
/// list/grid, the detail sheet header and the visit-step tile.
///
/// Kept in one place so the colour story stays consistent across surfaces.
/// Opacity is intentionally low (~10–15%) — the tint should hint at the
/// state without overwhelming card content or breaking dark-mode contrast.
/// See docs/customer-balance-mobile.md M12 (rebuilt).
class BalanceStatusTheme {
  BalanceStatusTheme._();

  /// Soft background tint composited over the card's surface. Returns
  /// `null` for [CustomerBalanceStatus.noDebt] / [CustomerBalanceStatus.unknown]
  /// — callers keep the original surface in those cases.
  static Color? cardTintFor(
    CustomerBalanceStatus status,
    ColorScheme cs,
  ) {
    switch (status) {
      case CustomerBalanceStatus.debtOverLimit:
        return cs.errorContainer.withValues(alpha: 0.18);
      case CustomerBalanceStatus.debtUnderLimit:
        // Theme-neutral amber works in both light and dark mode; the
        // colorScheme exposes no warning slot so we hard-code a soft amber.
        return Colors.amber.withValues(alpha: 0.12);
      case CustomerBalanceStatus.noDebt:
      case CustomerBalanceStatus.unknown:
        return null;
    }
  }

  /// Indicator dot colour. Returns `null` to mean "do not render".
  static Color? indicatorColorFor(
    CustomerBalanceStatus status,
    ColorScheme cs,
  ) {
    switch (status) {
      case CustomerBalanceStatus.debtOverLimit:
        return cs.error;
      case CustomerBalanceStatus.debtUnderLimit:
        return Colors.amber.shade700;
      case CustomerBalanceStatus.noDebt:
      case CustomerBalanceStatus.unknown:
        return null;
    }
  }

  /// Optional border tint matched to the card tint — used by surfaces that
  /// already render a coloured border (the trading-points list `Card`).
  static Color? borderTintFor(
    CustomerBalanceStatus status,
    ColorScheme cs,
  ) {
    switch (status) {
      case CustomerBalanceStatus.debtOverLimit:
        return cs.error.withValues(alpha: 0.55);
      case CustomerBalanceStatus.debtUnderLimit:
        return Colors.amber.shade700.withValues(alpha: 0.45);
      case CustomerBalanceStatus.noDebt:
      case CustomerBalanceStatus.unknown:
        return null;
    }
  }
}
