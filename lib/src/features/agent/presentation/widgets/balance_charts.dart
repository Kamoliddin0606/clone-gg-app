/// ============================================================================
/// Balance Charts - Balans diagrammalari
/// ============================================================================
/// fl_chart kutubxonasi yordamida balans ma'lumotlarini vizualizatsiya qilish.
/// 
/// Diagrammalar:
/// - BalancePieChart: To'lov va qarzdorlik nisbati
/// - ContractsBarChart: Shartnomalar bo'yicha balans
/// - OrdersStatusChart: Buyurtmalar holati bo'yicha
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_balance.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

/// ============================================================================
/// BalancePieChart - To'lov va qarzdorlik nisbati
/// ============================================================================
class BalancePieChart extends StatefulWidget {
  /// Jami to'lov summasi
  final double totalPayment;
  
  /// Jami qarzdorlik summasi
  final double totalDebt;
  
  /// Chart balandligi
  final double height;

  const BalancePieChart({
    super.key,
    required this.totalPayment,
    required this.totalDebt,
    this.height = 200,
  });

  @override
  State<BalancePieChart> createState() => _BalancePieChartState();
}

class _BalancePieChartState extends State<BalancePieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.totalPayment + widget.totalDebt;
    
    // Agar ma'lumot yo'q bo'lsa
    final l10n = AppLocalizations.of(context);
    if (total == 0) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(l10n?.noDataAvailable ?? 'No data available', style: const TextStyle(color: Colors.grey)),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Row(
        children: [
          // Pie Chart
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _buildSections(total),
              ),
            ),
          ),
          // Legend
          Expanded(
            flex: 1,
            child: _buildLegend(total),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(double total) {
    final paymentPercent = (widget.totalPayment / total * 100);
    final debtPercent = (widget.totalDebt / total * 100);

    return [
      // To'langan
      PieChartSectionData(
        color: Colors.green,
        value: widget.totalPayment,
        title: touchedIndex == 0 ? '${paymentPercent.toStringAsFixed(1)}%' : '',
        radius: touchedIndex == 0 ? 60 : 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: touchedIndex == 0 
            ? _buildBadge(Icons.check_circle, Colors.green)
            : null,
        badgePositionPercentageOffset: 1.2,
      ),
      // Qarzdorlik
      PieChartSectionData(
        color: Colors.red,
        value: widget.totalDebt,
        title: touchedIndex == 1 ? '${debtPercent.toStringAsFixed(1)}%' : '',
        radius: touchedIndex == 1 ? 60 : 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: touchedIndex == 1 
            ? _buildBadge(Icons.warning, Colors.red)
            : null,
        badgePositionPercentageOffset: 1.2,
      ),
    ];
  }

  Widget _buildBadge(IconData icon, Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildLegend(double total) {
    final formatter = NumberFormat('#,###', 'uz_UZ');
    final l10n = AppLocalizations.of(context);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LegendItem(
          color: Colors.green,
          label: l10n?.paidLabel ?? 'Paid',
          value: '${formatter.format(widget.totalPayment)} so\'m',
          isSelected: touchedIndex == 0,
        ),
        const SizedBox(height: 12),
        _LegendItem(
          color: Colors.red,
          label: l10n?.debtLabelChart ?? 'Debt',
          value: '${formatter.format(widget.totalDebt)} so\'m',
          isSelected: touchedIndex == 1,
        ),
      ],
    );
  }
}

/// ============================================================================
/// ContractsBarChart - Shartnomalar bo'yicha balans
/// ============================================================================
class ContractsBarChart extends StatefulWidget {
  /// Shartnomalar ro'yxati
  final List<ClientBalanceByContract> contracts;
  
  /// Chart balandligi
  final double height;

  const ContractsBarChart({
    super.key,
    required this.contracts,
    this.height = 250,
  });

  @override
  State<ContractsBarChart> createState() => _ContractsBarChartState();
}

class _ContractsBarChartState extends State<ContractsBarChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.contracts.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(l10n?.noContractsFound ?? 'No contracts found', style: const TextStyle(color: Colors.grey)),
        ),
      );
    }

    // Faqat birinchi 5 ta shartnomani ko'rsatish
    final displayContracts = widget.contracts.take(5).toList();

    return SizedBox(
      height: widget.height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(displayContracts),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.blueGrey.shade800,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final contract = displayContracts[group.x.toInt()];
                final formatter = NumberFormat('#,###', 'uz_UZ');
                return BarTooltipItem(
                  '${contract.contractCode}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: rodIndex == 0
                          ? (l10n?.paymentAmount(formatter.format(contract.paymentAmount)) ?? 'Payment: ${formatter.format(contract.paymentAmount)}')
                          : (l10n?.debtAmount(formatter.format(contract.debtAmount)) ?? 'Debt: ${formatter.format(contract.debtAmount)}'),
                      style: TextStyle(
                        color: rodIndex == 0 ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              },
            ),
            touchCallback: (FlTouchEvent event, barTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    barTouchResponse == null ||
                    barTouchResponse.spot == null) {
                  touchedIndex = -1;
                  return;
                }
                touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
              });
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= displayContracts.length) {
                    return const SizedBox.shrink();
                  }
                  final contract = displayContracts[value.toInt()];
                  return GestureDetector(
                    onTap: () => _showContractNameDialog(context, contract),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        contract.contractCode.length > 8
                            ? '${contract.contractCode.substring(0, 8)}...'
                            : contract.contractCode,
                        style: TextStyle(
                          fontSize: 10,
                          color: touchedIndex == value.toInt()
                              ? Colors.blue
                              : Colors.grey,
                          fontWeight: touchedIndex == value.toInt()
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
                reservedSize: 32,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatShortNumber(value),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _buildBarGroups(displayContracts),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _getMaxY(displayContracts) / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
        ),
      ),
    );
  }

  double _getMaxY(List<ClientBalanceByContract> contracts) {
    double maxVal = 0;
    for (final c in contracts) {
      if (c.paymentAmount > maxVal) maxVal = c.paymentAmount;
      if (c.debtAmount > maxVal) maxVal = c.debtAmount;
    }
    return maxVal * 1.2; // 20% margin
  }

  List<BarChartGroupData> _buildBarGroups(List<ClientBalanceByContract> contracts) {
    return contracts.asMap().entries.map((entry) {
      final index = entry.key;
      final contract = entry.value;
      final isTouched = index == touchedIndex;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: contract.paymentAmount,
            color: isTouched ? Colors.green : Colors.green.withOpacity(0.7),
            width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: contract.debtAmount,
            color: isTouched ? Colors.red : Colors.red.withOpacity(0.7),
            width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
  }

  String _formatShortNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  void _showContractNameDialog(BuildContext context, ClientBalanceByContract contract) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.contractDialog ?? 'Contract'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.codeLabel(contract.contractCode) ?? 'Code: ${contract.contractCode}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(l10n?.idLabel(contract.contractId.toString()) ?? 'ID: ${contract.contractId}'),
            const SizedBox(height: 4),
            Text(l10n?.projectLabel(contract.projectName) ?? 'Project: ${contract.projectName}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.closeButton ?? 'Close'),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// OrdersStatusChart - Buyurtmalar holati bo'yicha
/// ============================================================================
class OrdersStatusChart extends StatefulWidget {
  /// Buyurtmalar ro'yxati
  final List<ClientBalanceByOrder> orders;
  
  /// Chart balandligi
  final double height;

  const OrdersStatusChart({
    super.key,
    required this.orders,
    this.height = 200,
  });

  @override
  State<OrdersStatusChart> createState() => _OrdersStatusChartState();
}

class _OrdersStatusChartState extends State<OrdersStatusChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.orders.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(l10n?.noOrdersFound ?? 'No orders found', style: const TextStyle(color: Colors.grey)),
        ),
      );
    }

    // Statuslar bo'yicha guruhlash
    final paidCount = widget.orders.where((o) => o.isPaid).length;
    final partialCount = widget.orders.where((o) => o.isPartiallyPaid).length;
    final unpaidCount = widget.orders.where((o) => o.isUnpaid).length;
    final total = widget.orders.length;

    return SizedBox(
      height: widget.height,
      child: Row(
        children: [
          // Pie Chart
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 35,
                centerSpaceColor: Colors.white,
                sections: _buildSections(paidCount, partialCount, unpaidCount, total),
              ),
            ),
          ),
          // Legend
          Expanded(
            flex: 1,
            child: _buildLegend(paidCount, partialCount, unpaidCount),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    int paid, int partial, int unpaid, int total,
  ) {
    final sections = <PieChartSectionData>[];
    
    if (paid > 0) {
      sections.add(PieChartSectionData(
        color: Colors.green,
        value: paid.toDouble(),
        title: touchedIndex == 0 ? '$paid' : '',
        radius: touchedIndex == 0 ? 55 : 45,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }
    
    if (partial > 0) {
      sections.add(PieChartSectionData(
        color: Colors.orange,
        value: partial.toDouble(),
        title: touchedIndex == (paid > 0 ? 1 : 0) ? '$partial' : '',
        radius: touchedIndex == (paid > 0 ? 1 : 0) ? 55 : 45,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }
    
    if (unpaid > 0) {
      int idx = 0;
      if (paid > 0) idx++;
      if (partial > 0) idx++;
      
      sections.add(PieChartSectionData(
        color: Colors.red,
        value: unpaid.toDouble(),
        title: touchedIndex == idx ? '$unpaid' : '',
        radius: touchedIndex == idx ? 55 : 45,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }

    return sections;
  }

  Widget _buildLegend(int paid, int partial, int unpaid) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (paid > 0)
          _LegendItem(
            color: Colors.green,
            label: l10n?.paidLabel ?? 'Paid',
            value: l10n?.countItems(paid) ?? '$paid items',
            isSelected: touchedIndex == 0,
          ),
        if (paid > 0) const SizedBox(height: 8),
        if (partial > 0)
          _LegendItem(
            color: Colors.orange,
            label: l10n?.partialLabel ?? 'Partial',
            value: l10n?.countItems(partial) ?? '$partial items',
            isSelected: touchedIndex == (paid > 0 ? 1 : 0),
          ),
        if (partial > 0) const SizedBox(height: 8),
        if (unpaid > 0)
          _LegendItem(
            color: Colors.red,
            label: l10n?.unpaidLabel ?? 'Unpaid',
            value: l10n?.countItems(unpaid) ?? '$unpaid items',
            isSelected: touchedIndex == (paid > 0 ? 1 : 0) + (partial > 0 ? 1 : 0),
          ),
      ],
    );
  }
}

/// ============================================================================
/// _LegendItem - Legend elementi
/// ============================================================================
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final bool isSelected;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)]
                  : null,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? color : Colors.grey[600],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[500],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// BalanceProgressBar - Balans progress bar
/// ============================================================================
class BalanceProgressBar extends StatelessWidget {
  final double payment;
  final double debt;
  final double height;

  const BalanceProgressBar({
    super.key,
    required this.payment,
    required this.debt,
    this.height = 24,
  });

  @override
  Widget build(BuildContext context) {
    final total = payment + debt;
    if (total == 0) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(height / 2),
        ),
      );
    }

    final paymentRatio = payment / total;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        color: Colors.red.withOpacity(0.3),
      ),
      child: Stack(
        children: [
          // Payment (green)
          FractionallySizedBox(
            widthFactor: paymentRatio,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height / 2),
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.lightGreen],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
            ),
          ),
          // Percentage labels
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      '${(paymentRatio * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: paymentRatio > 0.3 ? Colors.white : Colors.green,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${((1 - paymentRatio) * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: paymentRatio < 0.7 ? Colors.white : Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
