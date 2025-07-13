import 'package:flutter/material.dart';

class AgentHomePage extends StatelessWidget {
  const AgentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildUserInfoCard(theme),
          const SizedBox(height: 16),
          _buildKpiSection(theme),
          const SizedBox(height: 16),
          _buildActionsGrid(context),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              // TODO: Add user image
              child: Icon(Icons.person, size: 30),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xalimov Axrorjon', // TODO: Get from user data
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  'Agent', // TODO: Get from user data
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiSection(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('KPI Overview', style: theme.textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // TODO: Implement KPI refresh logic
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _KpiItem(title: 'Plan', value: '100M'),
                _KpiItem(title: 'Fact', value: '75M'),
                _KpiItem(title: 'AKB', value: '85%'),
                _KpiItem(title: 'OKB', value: '92%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _ActionCard(
          title: 'Trading Points',
          icon: Icons.store,
          onTap: () {
            // TODO: Navigate to Trading Points page
          },
        ),
        _ActionCard(
          title: 'Create Order',
          icon: Icons.add_shopping_cart,
          onTap: () {
            // TODO: Navigate to Create Order page
          },
        ),
        _ActionCard(
          title: 'Order History',
          icon: Icons.history,
          onTap: () {
            // TODO: Navigate to Order History page
          },
        ),
        _ActionCard(
          title: 'Photo Report',
          icon: Icons.camera_alt,
          onTap: () {
            // TODO: Navigate to Photo Report page
          },
        ),
        _ActionCard(
          title: 'Contracts',
          icon: Icons.article,
          onTap: () {
            // TODO: Navigate to Contracts page
          },
        ),
        _ActionCard(
          title: 'Tasks',
          icon: Icons.task_alt,
          onTap: () {
            // TODO: Navigate to Tasks page
          },
        ),
      ],
    );
  }
}

class _KpiItem extends StatelessWidget {
  final String title;
  final String value;
  const _KpiItem({required this.title, required this.value});

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
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}