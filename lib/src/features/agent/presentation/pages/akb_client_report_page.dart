import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

class AkbClientReportPage extends StatefulWidget {
  const AkbClientReportPage({super.key});

  @override
  State<AkbClientReportPage> createState() => _AkbClientReportPageState();
}

class _AkbClientReportPageState extends State<AkbClientReportPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.08),
            colorScheme.primaryContainer.withOpacity(0.06),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)?.akbClientReport ??
                  'AKB mijozlari hisoboti',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            _buildStatCard(
              AppLocalizations.of(context)?.akbClients ?? 'AKB mijozlar',
              '28',
              Icons.people,
              colorScheme.primary,
            ),
            const SizedBox(height: 12),

            _buildStatCard(
              AppLocalizations.of(context)?.akbPercentage ?? 'AKB foizi',
              '62%',
              Icons.percent,
              colorScheme.secondary,
            ),

            const SizedBox(height: 24),

            // Client List
            Text(
              AppLocalizations.of(context)?.akbClientsList ??
                  'AKB mijozlar ro\'yxati',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            _buildClientItem(
              'OOO "Alpomish"',
              '15 000 000 UZS',
              'Aktiv',
              colorScheme.primary,
            ),
            const SizedBox(height: 8),
            _buildClientItem(
              'ChP "Zafar"',
              '8 500 000 UZS',
              'Aktiv',
              colorScheme.primary,
            ),
            const SizedBox(height: 8),
            _buildClientItem(
              'OOO "Mega Trade"',
              '12 200 000 UZS',
              'Aktiv',
              colorScheme.primary,
            ),
            const SizedBox(height: 8),
            _buildClientItem(
              'IP "Nodira"',
              '5 800 000 UZS',
              'Aktiv',
              colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
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

  Widget _buildClientItem(
    String name,
    String amount,
    String status,
    Color statusColor,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.business, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    amount,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
