/// ============================================================================
/// Client Balance Widget V2 - With Cubit State Management
/// ============================================================================
/// This widget displays client balance information.
/// State management is handled via ClientBalanceCubit.
/// 
/// Main features:
/// - Display balance status (debtor or overpayment)
/// - 10 second refresh cooldown with countdown
/// - Navigate to balance details page
/// - Shimmer loading effect
/// - Error handling and retry
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/core/services/client_balance_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/network/server_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/bloc/client_balance_cubit.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/bloc/client_balance_state.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/client_balance_details_page.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

/// ============================================================================
/// ClientBalanceWidgetV2 - Works with Cubit
/// ============================================================================
class ClientBalanceWidgetV2 extends StatelessWidget {
  /// Client data (for getting INN)
  final TradingPoint tradingPoint;

  const ClientBalanceWidgetV2({
    super.key,
    required this.tradingPoint,
  });

  @override
  Widget build(BuildContext context) {
    // Check INN
    if (tradingPoint.inn.isEmpty) {
      return _buildNoInnWidget(context);
    }

    // Create Cubit provider
    return BlocProvider(
      create: (context) => ClientBalanceCubit(
        balanceService: sl<ClientBalanceService>(),
        serverService: sl.isRegistered<ServerService>() ? sl<ServerService>() : null,
        inn: tradingPoint.inn,
        clientCode: tradingPoint.id,
      ),
      child: _ClientBalanceContent(tradingPoint: tradingPoint),
    );
  }

  /// INN yo'q bo'lganda
  Widget _buildNoInnWidget(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: cs.outline),
          const SizedBox(width: 8),
          Text(
            l10n?.clientInnNotFound ?? 'Mijoz INN raqami topilmadi',
            style: TextStyle(color: cs.outline, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// _ClientBalanceContent - Asosiy content widget
/// ============================================================================
class _ClientBalanceContent extends StatelessWidget {
  final TradingPoint tradingPoint;

  const _ClientBalanceContent({required this.tradingPoint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context, cs, l10n),
          const SizedBox(height: 8),
          // Content
          BlocBuilder<ClientBalanceCubit, ClientBalanceState>(
            builder: (context, state) {
              return _buildContent(context, state, theme, cs, l10n);
            },
          ),
        ],
      ),
    );
  }

  /// Header qismi
  Widget _buildHeader(BuildContext context, ColorScheme cs, AppLocalizations? l10n) {
    return Row(
      children: [
        Icon(Icons.account_balance_wallet_outlined, size: 20, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          l10n?.clientBalance ?? 'Mijoz balansi',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        // Info icon
        BlocBuilder<ClientBalanceCubit, ClientBalanceState>(
          buildWhen: (prev, curr) => prev.balance != curr.balance,
          builder: (context, state) {
            return _buildInfoIcon(context, state, cs);
          },
        ),
        const Spacer(),
        // Refresh button
        BlocBuilder<ClientBalanceCubit, ClientBalanceState>(
          buildWhen: (prev, curr) => 
              prev.canRefresh != curr.canRefresh || 
              prev.remainingSeconds != curr.remainingSeconds ||
              prev.isLoading != curr.isLoading,
          builder: (context, state) {
            return _buildRefreshButton(context, state, cs);
          },
        ),
      ],
    );
  }

  /// Info icon
  Widget _buildInfoIcon(BuildContext context, ClientBalanceState state, ColorScheme cs) {
    final hasBalance = state.hasData;
    final isDebtor = state.balance?.isDebtor ?? false;

    return GestureDetector(
      onTap: hasBalance ? () => _showBalanceInfo(context, state) : null,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hasBalance
              ? (isDebtor ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1))
              : cs.surfaceContainerHighest,
        ),
        child: Icon(
          Icons.info_outline,
          size: 16,
          color: hasBalance ? (isDebtor ? Colors.red : Colors.green) : cs.outline,
        ),
      ),
    );
  }

  /// Refresh button
  Widget _buildRefreshButton(BuildContext context, ClientBalanceState state, ColorScheme cs) {
    final canRefresh = state.canRefresh && !state.isLoading;

    return InkWell(
      onTap: canRefresh 
          ? () => context.read<ClientBalanceCubit>().refreshBalance() 
          : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: canRefresh ? cs.primary : cs.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
              )
            else
              Icon(
                Icons.refresh,
                size: 16,
                color: canRefresh ? cs.primary : cs.outline,
              ),
            if (!state.canRefresh && !state.isLoading) ...[
              const SizedBox(width: 4),
              Text(
                '${state.remainingSeconds}s',
                style: TextStyle(fontSize: 12, color: cs.outline),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Content qismi
  Widget _buildContent(
    BuildContext context,
    ClientBalanceState state,
    ThemeData theme,
    ColorScheme cs,
    AppLocalizations? l10n,
  ) {
    switch (state.status) {
      case ClientBalanceStatus.initial:
      case ClientBalanceStatus.loading:
        return _buildShimmerLoading(cs);
      
      case ClientBalanceStatus.refreshing:
        // Mavjud ma'lumot bilan birga loading
        if (state.hasData) {
          return _buildBalanceContent(context, state, theme, cs, l10n);
        }
        return _buildShimmerLoading(cs);
      
      case ClientBalanceStatus.success:
        if (state.hasData) {
          return _buildBalanceContent(context, state, theme, cs, l10n);
        }
        return _buildNoDataWidget(cs, l10n);
      
      case ClientBalanceStatus.error:
        if (state.hasData) {
          // Xatolik bo'lsa ham mavjud ma'lumotni ko'rsatish
          return Column(
            children: [
              _buildBalanceContent(context, state, theme, cs, l10n),
              const SizedBox(height: 8),
              _buildErrorBanner(context, state, cs),
            ],
          );
        }
        return _buildErrorWidget(context, state, cs, l10n);
    }
  }

  /// Shimmer loading effect
  Widget _buildShimmerLoading(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shimmer for date
        Container(
          width: 120,
          height: 12,
          decoration: BoxDecoration(
            color: cs.outline.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 12),
        // Shimmer for status
        Container(
          width: 80,
          height: 14,
          decoration: BoxDecoration(
            color: cs.outline.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        // Shimmer for amount
        Container(
          width: 150,
          height: 24,
          decoration: BoxDecoration(
            color: cs.outline.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  /// Balans content
  Widget _buildBalanceContent(
    BuildContext context,
    ClientBalanceState state,
    ThemeData theme,
    ColorScheme cs,
    AppLocalizations? l10n,
  ) {
    final balance = state.balance!;
    final isDebtor = balance.isDebtor;
    final hasOverpayment = balance.hasOverpayment;

    final balanceColor = isDebtor
        ? Colors.red
        : hasOverpayment
            ? Colors.green
            : cs.onSurface;

    String statusText;
    if (isDebtor) {
      statusText = l10n?.clientIsDebtor as String? ?? 'Mijoz qarzdor';
    } else if (hasOverpayment) {
      statusText = l10n?.clientHasOverpayment as String? ?? 'Ortiqcha to\'lov';
    } else {
      statusText = l10n?.balanceIsZero ?? 'Balans nolda';
    }

    return InkWell(
      onTap: () => _openBalanceDetails(context, balance),
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yangilash vaqti
          Row(
            children: [
              Icon(Icons.update, size: 14, color: cs.outline),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${l10n?.balanceUpdated ?? "Yangilangan"}: ${_formatDateTime(balance.lastUpdated)}',
                  style: TextStyle(fontSize: 11, color: cs.outline),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Balans holati va summa
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 13,
                        color: balanceColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isDebtor ? '-' : hasOverpayment ? '+' : ''}${_formatCurrency(balance.absoluteBalance)} so\'m',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: balanceColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: cs.outline),
            ],
          ),
          // Qo'shimcha ma'lumotlar
          if (balance.unpaidOrdersCount > 0 || balance.overdueOrdersCount > 0) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (balance.unpaidOrdersCount > 0)
                  _buildInfoChip(
                    icon: Icons.pending_outlined,
                    label: '${balance.unpaidOrdersCount} ${l10n?.unpaidOrders ?? "to\'lanmagan"}',
                    color: Colors.orange,
                  ),
                if (balance.overdueOrdersCount > 0)
                  _buildInfoChip(
                    icon: Icons.warning_amber_rounded,
                    label: '${balance.overdueOrdersCount} ${l10n?.overdueOrders ?? "muddati o\'tgan"}',
                    color: Colors.red,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Info chip
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// No data widget
  Widget _buildNoDataWidget(ColorScheme cs, AppLocalizations? l10n) {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 20, color: cs.outline),
        const SizedBox(width: 8),
        Text(
          l10n?.noBalanceData ?? 'Balans ma\'lumotlari topilmadi',
          style: TextStyle(color: cs.outline, fontSize: 13),
        ),
      ],
    );
  }

  /// Error widget
  Widget _buildErrorWidget(
    BuildContext context,
    ClientBalanceState state,
    ColorScheme cs,
    AppLocalizations? l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.errorMessage ?? (l10n?.balanceLoadError ?? 'Xatolik yuz berdi'),
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
          if (state.errorType?.canRetry ?? false)
            TextButton(
              onPressed: () => context.read<ClientBalanceCubit>().forceRefreshBalance(),
              child: Text(l10n?.retry ?? 'Qayta urinish'),
            ),
        ],
      ),
    );
  }

  /// Error banner (ma'lumot bilan birga)
  Widget _buildErrorBanner(BuildContext context, ClientBalanceState state, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              state.errorMessage ?? 'Yangilashda xatolik',
              style: const TextStyle(fontSize: 11, color: Colors.orange),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Balance info dialog
  void _showBalanceInfo(BuildContext context, ClientBalanceState state) {
    final balance = state.balance;
    if (balance == null) return;

    final isDebtor = balance.isDebtor;
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isDebtor ? Icons.warning_amber_rounded : Icons.info_outline,
              color: isDebtor ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(l10n?.balanceStatus ?? 'Balans holati'),
          ],
        ),
        content: Text(
          isDebtor
              ? '${l10n?.clientIsDebtor ?? "Mijoz qarzdor"}. ${l10n?.totalDebt ?? "Jami qarzdorlik"}: ${_formatCurrency(balance.absoluteBalance)} so\'m'
              : balance.hasOverpayment
                  ? '${l10n?.clientHasOverpayment ?? "Ortiqcha to\'lov"}. ${_formatCurrency(balance.absoluteBalance)} so\'m'
                  : l10n?.balanceIsZero ?? 'Mijoz balansi nolda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.close ?? 'Yopish'),
          ),
        ],
      ),
    );
  }

  /// Balance details sahifasini ochish
  void _openBalanceDetails(BuildContext context, balance) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ClientBalanceDetailsPage(
          tradingPoint: tradingPoint,
          balance: balance,
        ),
      ),
    );
  }

  /// Summa formatlash
  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'uz_UZ');
    return formatter.format(amount.abs());
  }

  /// Sana formatlash
  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd.MM.yyyy HH:mm', 'uz_UZ');
    return formatter.format(dateTime);
  }
}
