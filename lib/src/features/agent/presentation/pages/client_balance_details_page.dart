/// ============================================================================
/// Client Balance Details Page
/// ============================================================================
/// Bu sahifa mijoz balansi haqida batafsil ma'lumotlarni ko'rsatadi.
/// 3 ta tabdan iborat:
/// 1. Umumiy balans holati - diagrammalar bilan
/// 2. Shartnomalar bo'yicha - grafikli va jadvalli
/// 3. Buyurtmalar bo'yicha - grafikli va jadvalli
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_balance.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/balance_charts.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/shared/formatters.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

/// ============================================================================
/// ClientBalanceDetailsPage - Balans detallari sahifasi
/// ============================================================================
class ClientBalanceDetailsPage extends StatefulWidget {
  /// Mijoz ma'lumotlari
  final TradingPoint tradingPoint;
  
  /// Balans ma'lumotlari
  final ClientBalance balance;

  const ClientBalanceDetailsPage({
    super.key,
    required this.tradingPoint,
    required this.balance,
  });

  @override
  State<ClientBalanceDetailsPage> createState() => _ClientBalanceDetailsPageState();
}

class _ClientBalanceDetailsPageState extends State<ClientBalanceDetailsPage>
    with SingleTickerProviderStateMixin {
  /// Tab controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Summa formatlash
  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'uz_UZ');
    return formatter.format(amount.abs());
  }

  /// Sana formatlash
  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final formatter = DateFormat('dd.MM.yyyy', 'uz_UZ');
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.balanceFor(widget.tradingPoint.name) ?? 'Balance: ${widget.tradingPoint.name}',
          style: const TextStyle(fontSize: 16),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context)?.overviewTabShort ?? 'Overview', icon: const Icon(Icons.pie_chart_outline, size: 18)),
            Tab(text: AppLocalizations.of(context)?.contractsTabShort ?? 'Contracts', icon: const Icon(Icons.description_outlined, size: 18)),
            Tab(text: AppLocalizations.of(context)?.ordersTabShort ?? 'Orders', icon: const Icon(Icons.list_alt_outlined, size: 18)),
          ],
          labelStyle: const TextStyle(fontSize: 12),
          indicatorWeight: 3,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Umumiy balans holati
          _buildOverviewTab(theme, cs),
          // Tab 2: Shartnomalar bo'yicha
          _buildContractsTab(theme, cs),
          // Tab 3: Buyurtmalar bo'yicha
          _buildOrdersTab(theme, cs),
        ],
      ),
    );
  }

  /// ============================================================================
  /// Tab 1: Umumiy balans holati
  /// ============================================================================
  Widget _buildOverviewTab(ThemeData theme, ColorScheme cs) {
    final balance = widget.balance;
    final isDebtor = balance.isDebtor;
    final hasOverpayment = balance.hasOverpayment;

    // Rang tanlash
    final balanceColor = isDebtor
        ? Colors.red
        : hasOverpayment
            ? Colors.green
            : cs.onSurface;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Asosiy balans kartasi
          _buildBalanceCard(theme, cs, balanceColor),

          const SizedBox(height: 24),

          // Balans holati diagrammasi
          _buildBalanceChart(theme, cs),

          const SizedBox(height: 24),

          // Buyurtma va qarzdorlik nisbati
          _buildRatioChart(theme, cs),

          const SizedBox(height: 24),

          // Statistik ma'lumotlar
          _buildStatisticsCard(theme, cs),
        ],
      ),
    );
  }

  /// Main balance card
  Widget _buildBalanceCard(ThemeData theme, ColorScheme cs, Color balanceColor) {
    final balance = widget.balance;
    final isDebtor = balance.isDebtor;
    final hasOverpayment = balance.hasOverpayment;
    final l10n = AppLocalizations.of(context);

    final formattedAmount = uzsFormat.format(balance.absoluteBalance);
    
    String statusText;
    if (isDebtor) {
      statusText = l10n?.clientIsDebtor(formattedAmount) ?? 'Client is debtor';
    } else if (hasOverpayment) {
      statusText = l10n?.clientHasOverpayment(formattedAmount) ?? 'Overpayment available';
    } else {
      statusText = l10n?.balanceIsZero ?? 'Balance is zero';
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Balans holati icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: balanceColor.withOpacity(0.1),
              ),
              child: Icon(
                isDebtor
                    ? Icons.trending_down
                    : hasOverpayment
                        ? Icons.trending_up
                        : Icons.horizontal_rule,
                size: 32,
                color: balanceColor,
              ),
            ),

            const SizedBox(height: 16),

            // Holat matni
            Text(
              statusText,
              style: theme.textTheme.titleMedium?.copyWith(
                color: balanceColor,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            // Summa
            Text(
              '${isDebtor ? '-' : hasOverpayment ? '+' : ''}${_formatCurrency(balance.absoluteBalance)} so\'m',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: balanceColor,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Yangilash vaqti
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.update, size: 16, color: cs.outline),
                const SizedBox(width: 4),
                Text(
                  l10n?.updatedAt(_formatDate(balance.lastUpdated), DateFormat.Hm().format(balance.lastUpdated)) ?? 'Updated: ${_formatDate(balance.lastUpdated)} ${DateFormat.Hm().format(balance.lastUpdated)}',
                  style: TextStyle(fontSize: 12, color: cs.outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Balans holati diagrammasi - fl_chart PieChart bilan
  Widget _buildBalanceChart(ThemeData theme, ColorScheme cs) {
    final balance = widget.balance;
    final totalDebt = balance.totalDebtAmount; // Faqat haqiqiy qarzdorlik (debtAmount > 0)
    final totalOverpayment = balance.totalOverpaymentAmount; // Faqat ortiqcha to'lov (debtAmount < 0)
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.debtAndOverpaymentRatio ?? 'Debt and Overpayment Ratio',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            // fl_chart PieChart - qarzdorlik vs ortiqcha to'lov
            BalancePieChart(
              totalPayment: totalOverpayment, // Ortiqcha to'lov (yashil)
              totalDebt: totalDebt, // Qarzdorlik (qizil)
              height: 180,
            ),

            const SizedBox(height: 12),

            // Progress bar (visual summary)
            BalanceProgressBar(
              payment: totalOverpayment, // Ortiqcha to'lov (yashil)
              debt: totalDebt, // Qarzdorlik (qizil)
              height: 20,
            ),
            
            // Qo'shimcha ma'lumot
            if (totalOverpayment > 0 || totalDebt > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildChartLegend(
                      color: Colors.green,
                      label: l10n?.overpayment ?? 'Overpayment',
                      amount: totalOverpayment,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildChartLegend(
                      color: Colors.red,
                      label: l10n?.debt ?? 'Debt',
                      amount: totalDebt,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildChartLegend({
    required Color color,
    required String label,
    required double amount,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11)),
              Text(
                '${_formatCurrency(amount)} so\'m',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Nisbat diagrammasi
  Widget _buildRatioChart(ThemeData theme, ColorScheme cs) {
    final balance = widget.balance;
    final totalOrders = balance.totalOrderAmount;
    final totalPayment = balance.totalPaymentAmount;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)?.orderAndPaymentRatio ?? 'Order and Payment Ratio',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                // Buyurtma summasi
                Expanded(
                  child: _buildAmountCard(
                    icon: Icons.shopping_cart_outlined,
                    label: AppLocalizations.of(context)?.totalOrdered ?? 'Total Orders',
                    amount: totalOrders,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 12),
                // To'lov summasi
                Expanded(
                  child: _buildAmountCard(
                    icon: Icons.payments_outlined,
                    label: AppLocalizations.of(context)?.totalPaid ?? 'Total Paid',
                    amount: totalPayment,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Statistik ma'lumotlar kartasi
  Widget _buildStatisticsCard(ThemeData theme, ColorScheme cs) {
    final balance = widget.balance;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)?.statistics ?? 'Statistics',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            _buildStatRow(
              icon: Icons.description_outlined,
              label: AppLocalizations.of(context)?.contractsCountLabel ?? 'Contracts Count',
              value: '${balance.contractBalances.length}',
              color: cs.primary,
            ),
            const Divider(height: 24),
            _buildStatRow(
              icon: Icons.receipt_long_outlined,
              label: AppLocalizations.of(context)?.ordersCountLabel ?? 'Orders Count',
              value: '${balance.orderBalances.length}',
              color: cs.secondary,
            ),
            const Divider(height: 24),
            _buildStatRow(
              icon: Icons.pending_outlined,
              label: AppLocalizations.of(context)?.unpaidOrdersLabel ?? 'Unpaid Orders',
              value: '${balance.unpaidOrdersCount}',
              color: Colors.orange,
            ),
            const Divider(height: 24),
            _buildStatRow(
              icon: Icons.timelapse_outlined,
              label: AppLocalizations.of(context)?.partiallyPaidLabel ?? 'Partially Paid',
              value: '${balance.partiallyPaidOrdersCount}',
              color: Colors.amber,
            ),
            const Divider(height: 24),
            _buildStatRow(
              icon: Icons.warning_amber_rounded,
              label: AppLocalizations.of(context)?.overdueLabel ?? 'Overdue',
              value: '${balance.overdueOrdersCount}',
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  /// ============================================================================
  /// Tab 2: Shartnomalar bo'yicha
  /// ============================================================================
  Widget _buildContractsTab(ThemeData theme, ColorScheme cs) {
    final contracts = widget.balance.contractBalances;
    final l10n = AppLocalizations.of(context);

    if (contracts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: cs.outline),
            const SizedBox(height: 16),
            Text(
              l10n?.noBalanceData ?? 'Shartnomalar topilmadi',
              style: TextStyle(color: cs.outline, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // Chart section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n?.contractsTab ?? "Shartnomalar"} (${contracts.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // fl_chart BarChart
                    ContractsBarChart(
                      contracts: contracts,
                      height: 220,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Contracts list
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final contract = contracts[index];
                return _buildContractCard(theme, cs, contract, index);
              },
              childCount: contracts.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }

  /// Contract card widget
  Widget _buildContractCard(
    ThemeData theme,
    ColorScheme cs,
    ClientBalanceByContract contract,
    int index,
  ) {
    // Business logic: debtAmount > 0 = debtor, debtAmount < 0 = overpayment
    final hasDebt = contract.hasDebt;
    final hasOverpayment = contract.hasOverpayment;
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: hasOverpayment 
                        ? Colors.green.withOpacity(0.2)
                        : hasDebt 
                            ? Colors.red.withOpacity(0.2)
                            : cs.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: hasOverpayment 
                            ? Colors.green
                            : hasDebt 
                                ? Colors.red
                                : cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.contractWithCode(contract.contractCode) ?? 'Contract: ${contract.contractCode}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        contract.projectName,
                        style: TextStyle(fontSize: 12, color: cs.outline),
                      ),
                    ],
                  ),
                ),
                // Status indicator
                if (hasDebt)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n?.debtor ?? 'Debtor',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else if (hasOverpayment)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n?.excess ?? 'Excess',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),

            const Divider(height: 24),

            // Amounts
            Row(
              children: [
                Expanded(
                  child: _buildContractAmount(
                    label: l10n?.paid ?? 'Paid',
                    amount: contract.paymentAmount,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildContractAmount(
                    label: hasOverpayment ? (l10n?.excess ?? 'Excess') : (l10n?.debt ?? 'Debt'),
                    amount: contract.absoluteDebtAmount,
                    color: hasOverpayment ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Shartnoma summasi
  Widget _buildContractAmount({
    required String label,
    required double amount,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          '${_formatCurrency(amount)} so\'m',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: amount > 0 ? color : Colors.grey,
          ),
        ),
      ],
    );
  }

  /// ============================================================================
  /// Tab 3: Buyurtmalar bo'yicha
  /// ============================================================================
  Widget _buildOrdersTab(ThemeData theme, ColorScheme cs) {
    final allOrders = widget.balance.orderBalances;
    final l10n = AppLocalizations.of(context);
    
    // Haqiqiy buyurtmalar (orderAmount > 0) va ortiqcha to'lovlar (orderAmount = 0)
    // Teskari tartibda ko'rsatish (oxirgi buyurtmalar birinchi)
    final actualOrders = allOrders.where((o) => o.orderAmount > 0).toList().reversed.toList();
    final overpaymentRows = allOrders.where((o) => o.isOverpayment).toList().reversed.toList();

    if (allOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt_outlined, size: 64, color: cs.outline),
            const SizedBox(height: 16),
            Text(
              l10n?.noBalanceData ?? 'Buyurtmalar topilmadi',
              style: TextStyle(color: cs.outline, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Orders status chart (faqat haqiqiy buyurtmalar uchun)
        if (actualOrders.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.ordersStatus ?? 'Orders Status',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // fl_chart PieChart for orders status (faqat haqiqiy buyurtmalar)
                    OrdersStatusChart(
                      orders: actualOrders,
                      height: 160,
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Summary header (faqat haqiqiy buyurtmalar soni)
        Container(
          padding: const EdgeInsets.all(16),
          color: cs.surfaceContainerHighest.withOpacity(0.5),
          child: Row(
            children: [
              _buildOrderSummaryItem(
                label: l10n?.totalSummary ?? 'Total',
                count: actualOrders.length,
                color: cs.primary,
              ),
              const SizedBox(width: 8),
              _buildOrderSummaryItem(
                label: l10n?.paidSummary ?? 'Paid',
                count: actualOrders.where((o) => o.isPaid).length,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              _buildOrderSummaryItem(
                label: l10n?.partialSummary ?? 'Partial',
                count: actualOrders.where((o) => o.isPartiallyPaid).length,
                color: Colors.amber,
              ),
              const SizedBox(width: 8),
              _buildOrderSummaryItem(
                label: l10n?.unpaidSummary ?? 'Unpaid',
                count: actualOrders.where((o) => o.isUnpaid).length,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              _buildOrderSummaryItem(
                label: l10n?.excessSummary ?? 'Excess',
                count: overpaymentRows.length,
                color: Colors.blue,
              ),
            ],
          ),
        ),

        // Orders list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Ortiqcha to'lovlar bo'limi
              if (overpaymentRows.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l10n?.overpaymentWithCount(overpaymentRows.length) ?? 'Overpayments (${overpaymentRows.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
                ...overpaymentRows.map((order) => _buildOrderCard(theme, cs, order)),
                const SizedBox(height: 16),
              ],
              // Haqiqiy buyurtmalar bo'limi
              if (actualOrders.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l10n?.ordersWithCount(actualOrders.length) ?? 'Orders (${actualOrders.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ...actualOrders.map((order) => _buildOrderCard(theme, cs, order)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Order summary item
  Widget _buildOrderSummaryItem({
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Order card widget
  Widget _buildOrderCard(
    ThemeData theme,
    ColorScheme cs,
    ClientBalanceByOrder order,
  ) {
    // Business logic: debtAmount < 0 and orderAmount = 0 = overpayment
    final isOverpayment = order.isOverpayment;
    final l10n = AppLocalizations.of(context);
    
    // Status color
    final statusColor = isOverpayment
        ? Colors.blue
        : order.isPaid
            ? Colors.green
            : order.isPartiallyPaid
                ? Colors.orange
                : Colors.red;

    // Status text
    final statusText = isOverpayment
        ? (l10n?.overpayment ?? 'Overpayment')
        : order.isPaid
            ? (l10n?.paid ?? 'Paid')
            : order.isPartiallyPaid
                ? (l10n?.partiallyPaid ?? 'Partial')
                : (l10n?.unpaid ?? 'Unpaid');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Order number
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.orderWithNumber(order.orderNumber) ?? 'Order: ${order.orderNumber}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(order.orderDate),
                        style: TextStyle(fontSize: 12, color: cs.outline),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Amounts grid
            Row(
              children: [
                Expanded(
                  child: _buildOrderAmountItem(
                    label: l10n?.orderAmountLabel ?? 'Order',
                    amount: order.orderAmount,
                    color: cs.primary,
                  ),
                ),
                Expanded(
                  child: _buildOrderAmountItem(
                    label: l10n?.paidAmountLabel ?? 'Paid',
                    amount: order.paymentAmount,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildOrderAmountItem(
                    label: isOverpayment ? (l10n?.excessLabel ?? 'Excess') : (l10n?.debtLabel ?? 'Debt'),
                    amount: order.absoluteDebtAmount,
                    color: isOverpayment ? Colors.blue : Colors.red,
                  ),
                ),
              ],
            ),

            // Overdue warning
            if (order.isOverdue) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      l10n?.overdueDays(order.overdueDays) ?? 'Overdue ${order.overdueDays} days',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Order amount item
  Widget _buildOrderAmountItem({
    required String label,
    required double amount,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
        const SizedBox(height: 2),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: amount > 0 ? color : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountCard({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatCurrency(amount)} so\'m',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
