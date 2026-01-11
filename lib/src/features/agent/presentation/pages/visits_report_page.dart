import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

class VisitsReportPage extends StatefulWidget {
  const VisitsReportPage({super.key});

  @override
  State<VisitsReportPage> createState() => _VisitsReportPageState();
}

class _VisitsReportPageState extends State<VisitsReportPage> {
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
              AppLocalizations.of(context)?.visitsReport ?? 'Vizitlar hisoboti',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            _buildStatCard(
              AppLocalizations.of(context)?.completedVisits ??
                  'Amalga oshirilgan vizitlar',
              '32',
              Icons.location_on,
              colorScheme.primary,
            ),
            const SizedBox(height: 12),

            _buildStatCard(
              AppLocalizations.of(context)?.plannedVisits ??
                  'Rejalashtirilgan vizitlar',
              '18',
              Icons.schedule,
              colorScheme.secondary,
            ),
            const SizedBox(height: 12),

            _buildStatCard(
              AppLocalizations.of(context)?.visitEfficiency ??
                  'Vizit samaradorligi',
              '78%',
              Icons.percent,
              colorScheme.tertiary,
            ),

            const SizedBox(height: 24),

            // Visits List
            Text(
              AppLocalizations.of(context)?.lastVisits ?? 'Oxirgi vizitlar',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            _buildVisitItem(
              'Magazin "Central"',
              'Bugun 14:30',
              'Muvaffaqiyatli',
              colorScheme.primary,
            ),
            const SizedBox(height: 8),
            _buildVisitItem(
              'Dokon "Yangi"',
              'Kecha 16:45',
              'Buyurtma berildi',
              colorScheme.secondary,
            ),
            const SizedBox(height: 8),
            _buildVisitItem(
              'Supermarket "Mega"',
              '2 kun oldin',
              'Rad etildi',
              colorScheme.error,
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

  Widget _buildVisitItem(
    String name,
    String time,
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
            Icon(Icons.store, color: theme.colorScheme.primary),
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
                    time,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
