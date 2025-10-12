import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../Utility/formatter.dart';
import '../../data/models/order.dart';

/// Format number with spaces as thousand separators
String formatNumber(num number) {
  final formatter = NumberFormat('#,###', 'en_US');
  return formatter.format(number).replaceAll(',', ' ');
}

/// Modern Order Card Widget following Material Design 3 principles
/// Displays comprehensive order information with status-based color coding
class OrderCardWidget extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;
  final bool isGridView;

  const OrderCardWidget({
    super.key,
    required this.order,
    this.onTap,
    this.isGridView = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (isGridView) {
      return _buildGridCard(context, theme, cs);
    } else {
      return _buildListCard(context, theme, cs);
    }
  }

  Widget _buildListCard(BuildContext context, ThemeData theme, ColorScheme cs) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surface,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: cs.primary.withOpacity(0.08),
        highlightColor: cs.primary.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Order ID and Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.numOrder,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(order.mainStatus, cs, theme),
                ],
              ),
              const SizedBox(height: 12),

              // Client Information
              Row(
                children: [
                  Icon(
                    Icons.business,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.clientName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Client Code
              Row(
                children: [
                  Icon(
                    Icons.tag,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Kod: ${order.clientCode}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Date and Amount Row
              Row(
                children: [
                  // Date
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            DateFormat('dd.MM.yyyy HH:mm').format(order.dateOrder),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Amount
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 18,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${formatNumber(order.total)} UZS',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Price Type (if available)
              if (order.typePriceCode.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.price_change,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order.typePriceCode,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, ThemeData theme, ColorScheme cs) {
    return Card(
      elevation: 2,
      shadowColor: cs.shadow.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surface,
      margin: const EdgeInsets.all(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: cs.primary.withOpacity(0.08),
        highlightColor: cs.primary.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status at top
              Align(
                alignment: Alignment.topRight,
                child: _buildStatusChip(order.mainStatus, cs, theme, compact: true),
              ),

              // Order ID
              Text(
                order.numOrder,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Client Name
              Text(
                order.clientName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      DateFormat('dd.MM').format(order.dateOrder),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Amount
              Text(
                '${formatNumber(order.total)} UZS',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, ColorScheme cs, ThemeData theme, {bool compact = false}) {
    final statusInfo = _getStatusInfo(status, cs);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: statusInfo.backgroundColor,
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(
          color: statusInfo.borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        statusInfo.displayText,
        style: (compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)?.copyWith(
          color: statusInfo.textColor,
          fontWeight: FontWeight.w600,
          fontSize: compact ? 10 : 12,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  _StatusInfo _getStatusInfo(String status, ColorScheme cs) {
    // Normalize status text for comparison
    final normalizedStatus = status.toLowerCase();

    if (normalizedStatus.contains('доставлено') || normalizedStatus.contains('оплачено')) {
      return _StatusInfo(
        displayText: 'Доставлено',
        backgroundColor: cs.primaryContainer,
        textColor: cs.onPrimaryContainer,
        borderColor: cs.primary,
      );
    } else if (normalizedStatus.contains('возврат') || normalizedStatus.contains('отмена')) {
      return _StatusInfo(
        displayText: 'Возврат',
        backgroundColor: cs.errorContainer,
        textColor: cs.onErrorContainer,
        borderColor: cs.error,
      );
    } else if (normalizedStatus.contains('оператор') || normalizedStatus.contains('комплектации') || normalizedStatus.contains('в процессе')) {
      return _StatusInfo(
        displayText: 'В процессе',
        backgroundColor: cs.secondaryContainer,
        textColor: cs.onSecondaryContainer,
        borderColor: cs.secondary,
      );
    } else if (normalizedStatus.contains('истёк') || normalizedStatus.contains('просрочен')) {
      return _StatusInfo(
        displayText: 'Истек',
        backgroundColor: cs.tertiaryContainer,
        textColor: cs.onTertiaryContainer,
        borderColor: cs.tertiary,
      );
    } else if (normalizedStatus.contains('новый') || normalizedStatus.contains('ожидает')) {
      return _StatusInfo(
        displayText: 'Новый',
        backgroundColor: cs.surfaceContainerHighest,
        textColor: cs.onSurfaceVariant,
        borderColor: cs.outline,
      );
    } else {
      return _StatusInfo(
        displayText: status.length > 15 ? '${status.substring(0, 12)}...' : status,
        backgroundColor: cs.surfaceContainerHighest,
        textColor: cs.onSurfaceVariant,
        borderColor: cs.outline,
      );
    }
  }
}

class _StatusInfo {
  final String displayText;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  const _StatusInfo({
    required this.displayText,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });
}