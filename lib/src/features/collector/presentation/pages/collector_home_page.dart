import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

class CollectorHomePage extends StatelessWidget {
  const CollectorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Show filter dialog
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
          _buildStatsSection(theme),
          _buildFilterSection(context),
          Expanded(
            child: ListView.builder(
              itemCount: 8, // Mock data
              itemBuilder: (context, index) {
                return _CollectionListItem(index: index);
              },
            ),
          ),
          _buildTotalSection(context),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add new collection
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            title: 'Today',
            value: '12',
            subtitle: 'Collections',
            color: Colors.green,
          ),
          _StatItem(
            title: 'Pending',
            value: '5',
            subtitle: 'Items',
            color: Colors.orange,
          ),
          _StatItem(
            title: 'Total',
            value: '\$2,450',
            subtitle: 'Amount',
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: ['All', 'Pending', 'Collected', 'Delivered']
                  .map((label) => DropdownMenuItem(
                        value: label,
                        child: Text(label),
                      ))
                  .toList(),
              onChanged: (value) {},
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Route',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: ['All Routes', 'Route A', 'Route B', 'Route C']
                  .map((label) => DropdownMenuItem(
                        value: label,
                        child: Text(label),
                      ))
                  .toList(),
              onChanged: (value) {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.primary,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Collected Today: \$2,450.00',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Icon(
            Icons.account_balance_wallet,
            color: theme.colorScheme.onPrimary,
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

class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StatItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
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

class _CollectionListItem extends StatelessWidget {
  final int index;
  const _CollectionListItem({required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCollected = index % 3 != 0;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isCollected ? Colors.green : Colors.orange,
          child: Icon(
            isCollected ? Icons.check : Icons.schedule,
            color: Colors.white,
          ),
        ),
        title: Text('Collection Point #${index + 1}'),
        subtitle: Text('Address: Street ${index + 1}, District ${(index % 5) + 1}'),
        trailing: Text(
          isCollected ? 'Collected' : 'Pending',
          style: TextStyle(
            color: isCollected ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Collection Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount:'),
                    Text('\$${(index + 1) * 150}.00'),
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
                    const Text('Time:'),
                    Text('${9 + (index % 8)}:${(index * 15) % 60} AM'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isCollected) ...[
                      TextButton(
                        onPressed: () {},
                        child: const Text('Skip'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {},
                        child: const Text('Mark Collected'),
                      ),
                    ] else ...[
                      TextButton(
                        onPressed: () {},
                        child: const Text('View Details'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {},
                        child: const Text('Print Receipt'),
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