import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';
import '../../../../Utility/formatter.dart';
import '../../data/models/order.dart';

/// Format number with spaces as thousand separators
String formatNumber(num number) {
  final formatter = NumberFormat('#,###', 'en_US');
  return formatter.format(number).replaceAll(',', ' ');
}

class OrderDetailPage extends StatefulWidget {
  final Order order;

  const OrderDetailPage({
    super.key,
    required this.order,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Buyurtma tafsilotlari',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrder,
            tooltip: 'Yangilash',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary.withOpacity(0.08),
              cs.primaryContainer.withOpacity(0.06),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header Card
              _buildOrderHeaderCard(context, theme, cs),

              const SizedBox(height: 16),

              // Client Information Card
              _buildClientInfoCard(context, theme, cs),

              const SizedBox(height: 16),

              // Order Details Card
              _buildOrderDetailsCard(context, theme, cs),

              const SizedBox(height: 16),

              // Status and Timeline Card
              _buildStatusCard(context, theme, cs),

              const SizedBox(height: 16),

              // Comments Section (if available)
              if (_hasComments(widget.order)) ...[
                _buildCommentsCard(context, theme, cs),
                const SizedBox(height: 16),
              ],

              // Action Buttons
              _buildActionButtons(context, theme, cs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeaderCard(BuildContext context, ThemeData theme, ColorScheme cs) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID and Status Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.order.numOrder,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                _buildStatusChip(widget.order.mainStatus, cs, theme),
              ],
            ),
            const SizedBox(height: 16),

            // Amount
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 24,
                    color: cs.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Umumiy summa',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                        Text(
                          '${formatNumber(widget.order.total)} UZS',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfoCard(BuildContext context, ThemeData theme, ColorScheme cs) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.business,
                  size: 20,
                  color: cs.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mijoz ma\'lumotlari',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInfoRow(
              context,
              'Mijoz nomi',
              widget.order.clientName,
              Icons.person,
              theme,
              cs,
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              context,
              'Mijoz kodi',
              widget.order.clientCode,
              Icons.tag,
              theme,
              cs,
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              context,
              'Tashkilot kodi',
              widget.order.codeOrg,
              Icons.business_center,
              theme,
              cs,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailsCard(BuildContext context, ThemeData theme, ColorScheme cs) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 20,
                  color: cs.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Buyurtma tafsilotlari',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInfoRow(
              context,
              'Buyurtma sanasi',
              DateFormat('dd.MM.yyyy HH:mm').format(widget.order.dateOrder),
              Icons.calendar_today,
              theme,
              cs,
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              context,
              'Sarlavha',
              widget.order.captionOrder,
              Icons.description,
              theme,
              cs,
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              context,
              'Narx turi',
              widget.order.typePriceCode,
              Icons.price_change,
              theme,
              cs,
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              context,
              'Status kodi',
              widget.order.status.toString(),
              Icons.info,
              theme,
              cs,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, ThemeData theme, ColorScheme cs) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  size: 20,
                  color: cs.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status va holat',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(widget.order.mainStatus, cs),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(widget.order.mainStatus),
                    size: 24,
                    color: _getStatusTextColor(widget.order.mainStatus, cs),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Joriy status',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _getStatusTextColor(widget.order.mainStatus, cs).withOpacity(0.8),
                          ),
                        ),
                        Text(
                          widget.order.mainStatus,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getStatusTextColor(widget.order.mainStatus, cs),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsCard(BuildContext context, ThemeData theme, ColorScheme cs) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.comment,
                  size: 20,
                  color: cs.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Izohlar',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (widget.order.commentSupervisor?.isNotEmpty ?? false) ...[
              _buildCommentRow(
                context,
                'Supervisor izohi',
                widget.order.commentSupervisor!,
                theme,
                cs,
              ),
              const SizedBox(height: 12),
            ],

            if (widget.order.commentForwarder?.isNotEmpty ?? false) ...[
              _buildCommentRow(
                context,
                'Forwarder izohi',
                widget.order.commentForwarder!,
                theme,
                cs,
              ),
              const SizedBox(height: 12),
            ],

            if (widget.order.commentAgent?.isNotEmpty ?? false) ...[
              _buildCommentRow(
                context,
                'Agent izohi',
                widget.order.commentAgent!,
                theme,
                cs,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme, ColorScheme cs) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Amallar',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareOrder(context),
                    icon: const Icon(Icons.share),
                    label: const Text('Ulashish'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _callClient(context),
                    icon: const Icon(Icons.phone),
                    label: const Text('Qo\'ng\'iroq'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    ThemeData theme,
    ColorScheme cs,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: cs.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentRow(
    BuildContext context,
    String label,
    String comment,
    ThemeData theme,
    ColorScheme cs,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            comment,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, ColorScheme cs, ThemeData theme) {
    final statusInfo = _getStatusInfo(status, cs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusInfo.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusInfo.borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        statusInfo.displayText,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: statusInfo.textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _refreshOrder() async {
    setState(() => _isRefreshing = true);

    try {
      // Get user code from shared preferences
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();
      final userCode = prefs.getUserCode();

      if (userCode == null || userCode.isEmpty) {
        throw Exception('User code not found. Please login again.');
      }

      final repository = sl<AgentRepository>();

      // Sync orders data
      await repository.syncAllData(
        userCode: userCode,
        password: prefs.getPassword() ?? '',
        codeProject: prefs.getCodeProject() ?? '',
        codeSklad: prefs.getWarehouseCode() ?? '',
      );

      // Get updated order
      final updatedOrders = await repository.getCachedOrders();
      final updatedOrder = updatedOrders.firstWhere(
        (o) => o.numOrder == widget.order.numOrder,
        orElse: () => widget.order,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Buyurtma ma\'lumotlari yangilandi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yangilanishda xatolik: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _shareOrder(BuildContext context) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Buyurtma ulashish: ${widget.order.numOrder}')),
    );
  }

  void _callClient(BuildContext context) {
    // TODO: Implement call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mijozga qo\'ng\'iroq qilish')),
    );
  }

  bool _hasComments(Order order) {
    return (order.commentSupervisor?.isNotEmpty ?? false) ||
           (order.commentForwarder?.isNotEmpty ?? false) ||
           (order.commentAgent?.isNotEmpty ?? false);
  }

  _StatusInfo _getStatusInfo(String status, ColorScheme cs) {
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

  Color _getStatusColor(String status, ColorScheme cs) {
    if (status.contains('Доставлено')) {
      return cs.primaryContainer;
    } else if (status.contains('возврат')) {
      return cs.errorContainer;
    } else if (status.contains('Оператор') || status.contains('комплектации')) {
      return cs.secondaryContainer;
    } else if (status.contains('истёк')) {
      return cs.tertiaryContainer;
    }
    return cs.surfaceContainerHighest;
  }

  Color _getStatusTextColor(String status, ColorScheme cs) {
    if (status.contains('Доставлено')) {
      return cs.onPrimaryContainer;
    } else if (status.contains('возврат')) {
      return cs.onErrorContainer;
    } else if (status.contains('Оператор') || status.contains('комплектации')) {
      return cs.onSecondaryContainer;
    } else if (status.contains('истёк')) {
      return cs.onTertiaryContainer;
    }
    return cs.onSurfaceVariant;
  }

  IconData _getStatusIcon(String status) {
    if (status.contains('Доставлено')) {
      return Icons.check_circle;
    } else if (status.contains('возврат')) {
      return Icons.undo;
    } else if (status.contains('Оператор') || status.contains('комплектации')) {
      return Icons.hourglass_top;
    } else if (status.contains('истёк')) {
      return Icons.schedule;
    }
    return Icons.info;
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