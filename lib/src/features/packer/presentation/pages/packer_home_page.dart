import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

class PackerHomePage extends StatelessWidget {
  const PackerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Packing Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              // TODO: Open QR scanner
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _showExitDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWorkloadSection(theme),
          _buildQuickActions(context),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'To Pack', icon: Icon(Icons.inventory_2)),
                      Tab(text: 'In Progress', icon: Icon(Icons.work)),
                      Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildOrdersList('to_pack'),
                        _buildOrdersList('in_progress'),
                        _buildOrdersList('completed'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildProductivitySection(theme),
        ],
      ),
    );
  }

  Widget _buildWorkloadSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _WorkloadItem(
            title: 'Pending',
            value: '24',
            subtitle: 'Orders',
            color: Colors.orange,
            icon: Icons.pending_actions,
          ),
          _WorkloadItem(
            title: 'Packed',
            value: '156',
            subtitle: 'Today',
            color: Colors.green,
            icon: Icons.check_circle,
          ),
          _WorkloadItem(
            title: 'Target',
            value: '200',
            subtitle: 'Daily',
            color: Colors.blue,
            icon: Icons.flag,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _QuickActionButton(
            icon: Icons.qr_code_scanner,
            label: 'Scan QR',
            color: Colors.blue,
            onPressed: () {
              // TODO: Open QR scanner
            },
          ),
          _QuickActionButton(
            icon: Icons.print,
            label: 'Print Label',
            color: Colors.green,
            onPressed: () {
              // TODO: Print label
            },
          ),
          _QuickActionButton(
            icon: Icons.inventory,
            label: 'Check Stock',
            color: Colors.orange,
            onPressed: () {
              // TODO: Check stock
            },
          ),
          _QuickActionButton(
            icon: Icons.report_problem,
            label: 'Report Issue',
            color: Colors.red,
            onPressed: () {
              // TODO: Report issue
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(String status) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: status == 'completed' ? 5 : 8,
      itemBuilder: (context, index) {
        return _PackingOrderItem(
          index: index,
          status: status,
        );
      },
    );
  }

  Widget _buildProductivitySection(ThemeData theme) {
    return Container(
      width: double.infinity,
      color: theme.colorScheme.primary,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Today\'s Productivity: 78%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '156 of 200 orders packed',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.8),
                ),
              ),
            ],
          ),
          CircularProgressIndicator(
            value: 0.78,
            backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chiqish'),
          content: const Text('Haqiqatan ham ilovadan chiqmoqchimisiz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () => _logout(context),
              child: const Text('Chiqish'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();
      await prefs.clearCredentials();
    } catch (e) {
      // SharedPreferences not ready, continue with logout
    }
    
    if (context.mounted) {
      Navigator.of(context).pop(); // Close dialog
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.loginRoute,
        (route) => false,
      );
    }
  }
}

class _WorkloadItem extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _WorkloadItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          onPressed: onPressed,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PackingOrderItem extends StatelessWidget {
  final int index;
  final String status;

  const _PackingOrderItem({
    required this.index,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (status) {
      case 'to_pack':
        statusColor = Colors.orange;
        statusIcon = Icons.inventory_2;
        statusText = 'Ready to Pack';
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusIcon = Icons.work;
        statusText = 'Packing...';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Packed';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Unknown';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(statusIcon, color: Colors.white, size: 20),
        ),
        title: Text('Order #ORD${1000 + index}'),
        subtitle: Text('${(index + 1) * 3} items • Priority: ${index % 2 == 0 ? 'High' : 'Normal'}'),
        trailing: Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Order Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Customer:'),
                    Text('Customer ${index + 1}'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Items:'),
                    Text('${(index + 1) * 3} pieces'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Weight:'),
                    Text('${(index + 1) * 2.5} kg'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Deadline:'),
                    Text('${DateTime.now().add(Duration(days: index + 1)).day}/${DateTime.now().month}'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (status == 'to_pack') ...[
                      TextButton(
                        onPressed: () {},
                        child: const Text('View Items'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {},
                        child: const Text('Start Packing'),
                      ),
                    ] else if (status == 'in_progress') ...[
                      TextButton(
                        onPressed: () {},
                        child: const Text('Pause'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {},
                        child: const Text('Complete'),
                      ),
                    ] else ...[
                      TextButton(
                        onPressed: () {},
                        child: const Text('View Details'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {},
                        child: const Text('Print Label'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}