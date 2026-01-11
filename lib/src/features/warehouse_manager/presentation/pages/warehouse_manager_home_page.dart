import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

class WarehouseManagerHomePage extends StatelessWidget {
  const WarehouseManagerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Show notifications
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
          _buildOverviewSection(theme),
          _buildQuickActions(context),
          Expanded(
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  const TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'Inventory', icon: Icon(Icons.inventory)),
                      Tab(text: 'Incoming', icon: Icon(Icons.arrow_downward)),
                      Tab(text: 'Outgoing', icon: Icon(Icons.arrow_upward)),
                      Tab(text: 'Reports', icon: Icon(Icons.analytics)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildInventoryTab(),
                        _buildIncomingTab(),
                        _buildOutgoingTab(),
                        _buildReportsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildCapacitySection(theme),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _OverviewItem(
            title: 'Total Items',
            value: '12,450',
            subtitle: 'In Stock',
            color: Colors.blue,
            icon: Icons.inventory,
          ),
          _OverviewItem(
            title: 'Capacity',
            value: '78%',
            subtitle: 'Used',
            color: Colors.orange,
            icon: Icons.storage,
          ),
          _OverviewItem(
            title: 'Low Stock',
            value: '23',
            subtitle: 'Items',
            color: Colors.red,
            icon: Icons.warning,
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
            icon: Icons.add_box,
            label: 'Receive\nGoods',
            color: Colors.green,
            onPressed: () {
              // TODO: Receive goods
            },
          ),
          _QuickActionButton(
            icon: Icons.remove_circle,
            label: 'Issue\nGoods',
            color: Colors.blue,
            onPressed: () {
              // TODO: Issue goods
            },
          ),
          _QuickActionButton(
            icon: Icons.search,
            label: 'Find\nItem',
            color: Colors.purple,
            onPressed: () {
              // TODO: Find item
            },
          ),
          _QuickActionButton(
            icon: Icons.qr_code_scanner,
            label: 'Scan\nBarcode',
            color: Colors.teal,
            onPressed: () {
              // TODO: Scan barcode
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: 15,
      itemBuilder: (context, index) {
        return _InventoryItem(index: index);
      },
    );
  }

  Widget _buildIncomingTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: 8,
      itemBuilder: (context, index) {
        return _IncomingItem(index: index);
      },
    );
  }

  Widget _buildOutgoingTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: 12,
      itemBuilder: (context, index) {
        return _OutgoingItem(index: index);
      },
    );
  }

  Widget _buildReportsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _ReportCard(
            title: 'Daily Movement Report',
            subtitle: 'Items in/out today',
            icon: Icons.trending_up,
            color: Colors.blue,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _ReportCard(
            title: 'Stock Level Report',
            subtitle: 'Current inventory status',
            icon: Icons.inventory_2,
            color: Colors.green,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _ReportCard(
            title: 'Low Stock Alert',
            subtitle: 'Items below minimum level',
            icon: Icons.warning,
            color: Colors.orange,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _ReportCard(
            title: 'Monthly Summary',
            subtitle: 'Performance overview',
            icon: Icons.analytics,
            color: Colors.purple,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCapacitySection(ThemeData theme) {
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
                'Warehouse Capacity: 78%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '7,800 m³ of 10,000 m³ used',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.8),
                ),
              ),
            ],
          ),
          CircularProgressIndicator(
            value: 0.78,
            backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.onPrimary,
            ),
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
          title: Text(AppLocalizations.of(context)?.logout ?? 'Chiqish'),
          content: Text(
            AppLocalizations.of(context)?.confirmLogout ??
                'Haqiqatan ham ilovadan chiqmoqchimisiz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)?.cancel ?? 'Bekor qilish',
              ),
            ),
            FilledButton(
              onPressed: () => _logout(context),
              child: Text(AppLocalizations.of(context)?.logout ?? 'Chiqish'),
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

class _OverviewItem extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _OverviewItem({
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

class _InventoryItem extends StatelessWidget {
  final int index;

  const _InventoryItem({required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowStock = index % 5 == 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLowStock ? Colors.red : Colors.green,
          child: Icon(
            isLowStock ? Icons.warning : Icons.inventory,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text('Product ${index + 1}'),
        subtitle: Text(
          'SKU: PRD${1000 + index} • Location: A${index % 10 + 1}-${index % 5 + 1}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${(index + 1) * 50} pcs',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isLowStock ? Colors.red : theme.colorScheme.primary,
              ),
            ),
            if (isLowStock)
              const Text(
                'Low Stock',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
        onTap: () {
          // TODO: Show item details
        },
      ),
    );
  }
}

class _IncomingItem extends StatelessWidget {
  final int index;

  const _IncomingItem({required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.arrow_downward, color: Colors.white, size: 20),
        ),
        title: Text('Incoming #IN${1000 + index}'),
        subtitle: Text(
          'Supplier: Supplier ${index + 1} • ETA: ${DateTime.now().add(Duration(days: index + 1)).day}/${DateTime.now().month}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${(index + 1) * 100} items',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              index % 2 == 0 ? 'Pending' : 'In Transit',
              style: TextStyle(
                color: index % 2 == 0 ? Colors.orange : Colors.blue,
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: Show incoming details
        },
      ),
    );
  }
}

class _OutgoingItem extends StatelessWidget {
  final int index;

  const _OutgoingItem({required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.arrow_upward, color: Colors.white, size: 20),
        ),
        title: Text('Outgoing #OUT${1000 + index}'),
        subtitle: Text(
          'Customer: Customer ${index + 1} • Due: ${DateTime.now().add(Duration(days: index + 1)).day}/${DateTime.now().month}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${(index + 1) * 25} items',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              index % 3 == 0
                  ? 'Ready'
                  : index % 3 == 1
                  ? 'Picking'
                  : 'Packed',
              style: TextStyle(
                color: index % 3 == 0
                    ? Colors.green
                    : index % 3 == 1
                    ? Colors.orange
                    : Colors.blue,
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: Show outgoing details
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ReportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
